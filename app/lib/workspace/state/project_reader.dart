// Reads the engine's document for the window: layers, marks, guides, tempo.
import 'dart:developer' show Timeline, TimelineTask;
import 'dart:math' as math;
import 'dart:ui' show Color, Size;

import 'package:flutter/foundation.dart'
    show ValueNotifier, VoidCallback, listEquals, mapEquals, setEquals;

import 'package:motolii/panel.dart';
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/workspace/state/beats.dart';
import 'package:motolii/workspace/state/composition_settings.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/playhead.dart';
import 'package:motolii/workspace/timeline/frame_snap.dart'
    show SnapKind, SnapTarget;

typedef _Listed = ({
  List<(double, String)> marks,
  (double, double) work,
  Map<double, int> markColors,
  double bpm,
  int duration,
  int frameRate,
  int labels,
});

class ProjectReader {
  ProjectReader({
    required this._composition,
    required this._playhead,
    required this._onLayersRead,
    required this._onChanged,
    required this._onStructure,
    required this._onListed,
    required this._onStageTextureChanged,
  });

  final CompositionSettings _composition;
  final Playhead _playhead;
  final VoidCallback _onLayersRead,
      _onChanged,
      _onStructure,
      _onListed,
      _onStageTextureChanged;

  int get _frameRate => _composition.frameRate;

  static bool _isVideoKind(String kind) => kind == 'video' || kind == 'film';
  static bool _isImageKind(String kind) => kind == 'image' || kind == 'picture';

  /// Whether layer [t] is a sound-only video layer (audio file or extracted sound track).
  static bool isSound(Motolii m, int t) {
    if (!_isVideoKind(m.word(t, 'kind'))) return false;
    if (m.kindOf(m.word(t, 'file')) == 'sound') return true;
    return (m.value(t, 'visible', 0) ?? 1) < .5 &&
        m.word(t, 'name').endsWith(' (sound)');
  }

  final layers = <Layer>[];

  Motolii? _inside;

  Motolii? get inside => _inside;

  /// Clears the open engine reference before closing it so no widget reads freed native buffers.
  void detach() {
    _inside?.listener = null;
    _inside = null;
    stageTexture = null;
  }

  void join(Motolii inside) {
    _inside = inside;
    inside.shaping; // Read once at opening: it decides how cards are built.
    inside.listener = ({required document, required moment, required cache}) {
      // The engine has a new snapshot, see docs/app/BRIDGE.md.
      if (_gone) return;
      if (cache) kept.value = inside.cache;
      if (document) reread();
      if (moment) seen.value++;
    };
    _composition.frameRate = _frameRateOf(inside);
    _composition.size = Size(
      inside.size.$1.toDouble(),
      inside.size.$2.toDouble(),
    );
    _playhead.moment.value = (inside.now * _frameRate).round();
    reread();
  }

  VoidCallback? refit;

  int rev = 0;

  /// Like [rev] but without drags. Structure-dependent panels rebuild on this.
  int reads = 0;

  // Negative lasts = runs to the document's end.
  int _outF(int from, double lasts) => lasts < 0
      ? _composition.duration
      : (from + (lasts * _frameRate).round()).clamp(
          from + 1,
          _composition.duration,
        );

  /// Re-reads layer [id]'s span from the engine (e.g. during a drag).
  void respan(int id) {
    final m = _inside, l = layers.where((l) => l.id == id).firstOrNull;
    if (m == null || l == null) return;
    l.inF = ((m.value(id, 'start', 0) ?? 0) * _frameRate).round();
    l.outF = _outF(l.inF, m.lasts(id));
    shown();
  }

  bool _gone = false;

  final seen = ValueNotifier<int>(0);

  /// Frame ranges cached on disk for playback.
  final kept = ValueNotifier<List<(int, int)>>(const []);

  void dispose() {
    _gone = true;
    seen.dispose();
    kept.dispose();
  }

  /// Notifies panels after a visual change that is not an undo step (e.g. a drag).
  void shown() {
    lastChange = null; // This is not an undo step, so what changed is unknown.
    rev++;
    _onListed();
    _onChanged();
  }

  double get bpm => _inside?.value(0, 'bpm', 0) ?? 0;

  Beats? get beats => bpm > 0
      ? Beats(
          (_inside?.value(0, 'bpm_from', 0) ?? 0) * _frameRate,
          60 / bpm * _frameRate,
        )
      : null;

  static int _frameRateOf(Motolii m) =>
      switch ((m.value(0, 'frame_rate', 0) ?? 0).round()) {
        > 0 && final r => r,
        _ => m.rate,
      };

  // Kept between reads: each layer's snapshot as it was read, where each layer is in [layers], and the layers
  // that are parents.
  final _lastSnap = <int, Map<String, dynamic>>{};
  final _place = <int, int>{};
  Set<int> _holding = const {};
  // Counts the reads that changed a layer's label colour.
  int _labels = 0;

  static int? _labelOf(Motolii m, int t) =>
      switch (m.words(t, 'label').indexOf(m.word(t, 'label'))) {
        > 0 && final i => i - 1,
        _ => null,
      };

  void reread() => Timeline.timeSync('ws reread', _reread);
  void _reread() {
    final m = _inside;
    if (m == null) return;
    // Size changed: the host reopens the document.
    if (!m.fits && refit != null) return refit!();
    lastChange = m.changes();
    var frameRateChanged = false;
    if (_frameRateOf(m) != _frameRate) {
      frameRateChanged = true;
      // Keep the playhead at the same time.
      final at = _playhead.moment.value / _frameRate;
      _composition.frameRate = _frameRateOf(m);
      _playhead.moment.value = (at * _frameRate).round();
    }
    rev++;
    reads++;
    final wasListed = _listed;
    final oldDuration = _composition.duration;
    _composition.duration = Timeline.timeSync(
      'MARK seconds',
      () => (m.seconds * _frameRate).round().clamp(1, 1 << 20),
    );
    final tl = TimelineTask()..start('MARK layers');
    final timesKept = !frameRateChanged && _composition.duration == oldDuration;
    // With the list of layers and their parents as they were, only the layers that came are made again: a read
    // costs what changed, not how many layers there are.
    final same =
        wasListed != null &&
            timesKept &&
            !m.layerListTaken &&
            m.layersTaken.every(
              (t) =>
                  t == 0 ||
                  _place[t] != null &&
                      layers[_place[t]!].parent == _parentOf(m, t),
            )
        ? _rereadTaken(m)
        : _rereadAll(m, timesKept);
    m.layersTaken.clear();
    m.layerListTaken = false;
    _listed = (
      marks: m.marks,
      work: m.work,
      markColors: m.markColors,
      bpm: bpm,
      duration: _composition.duration,
      frameRate: _frameRate,
      labels: _labels,
    );
    _onLayersRead();
    tl.finish();
    if (!same || !_sameListed(wasListed, _listed)) _onListed();
    if (m.structureTaken) {
      m.structureTaken = false;
      _onStructure();
    }
    _onChanged();
  }

  // Makes again the layers that came. Whether each is as it was.
  bool _rereadTaken(Motolii m) {
    var same = true;
    for (final t in m.layersTaken) {
      if (t == 0) continue;
      final i = _place[t]!, l = _layerOf(m, t);
      same &= layers[i].same(l);
      layers[i] = l;
      _byId[t] = l;
      final label = _labelOf(m, t);
      if (label != chosenLabelColors[t]) {
        _labels++;
        label == null
            ? chosenLabelColors.remove(t)
            : chosenLabelColors[t] = label;
      }
    }
    return same;
  }

  // Makes the list again, each layer whose snapshot is the one last read kept. Whether the list is as it was.
  bool _rereadAll(Motolii m, bool timesKept) {
    final was = List.of(layers);
    final labels = <int, int>{for (final t in m.layers) t: ?_labelOf(m, t)};
    if (!mapEquals(labels, chosenLabelColors)) {
      _labels++;
      chosenLabelColors
        ..clear()
        ..addAll(labels);
    }
    final holding = {for (final t in m.layers) m.parentOf(t)};
    final canReuse = timesKept && setEquals(holding, _holding);
    _holding = holding;
    final wasById = canReuse
        ? <int, Layer>{for (final l in was) l.id: l}
        : const <int, Layer>{};
    layers
      ..clear()
      ..addAll([
        for (final t
            in m
                .layers
                .reversed) // The topmost layer comes first, as in the sample.
          if (identical(m.layerSnapshot(t), _lastSnap[t]) &&
              wasById.containsKey(t))
            wasById[t]!
          else
            _layerOf(m, t),
      ]);
    _place
      ..clear()
      ..addAll({for (final (i, l) in layers.indexed) l.id: i});
    _byId.clear();
    _lastSnap.removeWhere((t, _) => !_place.containsKey(t));
    return was.length == layers.length &&
        [for (var i = 0; i < was.length; i++) was[i].same(layers[i])]
            .every((same) => same);
  }

  static int? _parentOf(Motolii m, int t) => switch (m.parentOf(t)) {
    > 0 && final p => p,
    _ => null,
  };

  Layer _layerOf(Motolii m, int t) {
    _lastSnap[t] = m.layerSnapshot(t);
    final kind = m.word(t, 'kind'),
        from = ((m.value(t, 'start', 0) ?? 0) * _frameRate).round(),
        lasts = m.lasts(t);
    final keys = <int>{
      for (final s in m.layerKeyTimes(t)) (s * _frameRate).round(),
    }.toList()..sort();
    return Layer(
      t,
      m.word(t, 'name'),
      switch (kind) {
        'text' => LayerKind.text,
        'camera' => LayerKind.camera,
        'environment' => LayerKind.environment,
        'video' || 'film' when isSound(m, t) => LayerKind.audio,
        'video' || 'film' || 'image' || 'picture' => LayerKind.image,
        'shape' when m.word(t, 'shape') == 'null' && _holding.contains(t) =>
          LayerKind.group,
        _ => LayerKind.shape,
      },
      from,
      _outF(from, lasts),
      keys,
      parent: _parentOf(m, t),
      lined:
          (_isImageKind(kind) || kind == 'solid') &&
          m.values(t).any((n) => n.startsWith('js_line_')),
      hidden: (m.value(t, 'visible', 0) ?? 1) < .5,
      solo: (m.value(t, 'solo', 0) ?? 0) > .5,
      locked: (m.value(t, 'lock', 0) ?? 0) > .5,
      clipped: (m.value(t, 'clip', 0) ?? 0) > .5,
      stretches: [
        for (final (a, b, way) in m.layerStretches(t))
          (
            from: (a * _frameRate).round(),
            to: (b * _frameRate).round(),
            way: way,
            shape: easeCurve(way, m),
          ),
      ],
      form: _formOf(m, t),
      members: _membersOf(m, t),
      links: _linksOf(m, t),
      lanes: _lanesOf(m, t),
      retimed: [
        for (final n in const ['retime_in', 'retime_out'])
          if ((m.value(t, n, 0) ?? 0) > 0)
            (((m.value(t, 'start', 0) ?? 0) + m.value(t, n, 0)!) * _frameRate)
                .round(),
      ],
      media: switch (kind) {
        'video' || 'film' => (
          file: m.whole(m.word(t, 'file')),
          begin: m.value(t, 'begin', 0) ?? 0,
          speed: m.value(t, 'speed', 0) ?? 1,
          still: false,
        ),
        'image' || 'picture' => (
          file: m.whole(m.word(t, 'file')),
          begin: 0.0,
          speed: 1.0,
          still: true,
        ),
        _ => null,
      },
    );
  }

  _Listed? _listed;
  static bool _sameListed(_Listed? a, _Listed? b) =>
      a != null &&
      b != null &&
      listEquals(a.marks, b.marks) &&
      a.work == b.work &&
      mapEquals(a.markColors, b.markColors) &&
      a.bpm == b.bpm &&
      a.duration == b.duration &&
      a.frameRate == b.frameRate &&
      a.labels == b.labels;

  static ({String shape, Color? colour, bool outline})? _formOf(
    Motolii m,
    int t,
  ) {
    if (m.word(t, 'kind') != 'shape') return null;
    Color? colour(String hex) => hex.length == 6 ? colorOfHex(hex) : null;
    final outline = m.word(t, 'fill') == 'none';
    return (
      shape: m.word(t, 'shape'),
      colour: colour(m.word(t, outline ? 'stroke' : 'fill')),
      outline: outline,
    );
  }

  static List<int>? _membersOf(Motolii m, int t) =>
      m.word(t, 'kind') == 'behaviour' &&
          relationKinds.contains(m.word(t, 'file'))
      ? [
          for (final s in m.word(t, 'members').split(' '))
            if (s.isNotEmpty && s != '_') ?int.tryParse(s),
        ]
      : null;

  static List<(String, int)> _linksOf(Motolii m, int t) => [
    for (final n in m.values(t))
      if (m.shown(n) case final s? when s.look == 'thing')
        if ((m.value(t, n, 0) ?? 0).round() case final o when m.has(o))
          (s.label, o),
    for (final o in _membersOf(m, t) ?? const <int>[])
      if (m.has(o)) ('Moves', o),
  ];

  // Properties with keyframes (and a sketch's lines), in the layer's own order.
  static List<Lane> _lanesOf(Motolii m, int t) {
    final moving = m.moving(t).toSet();
    final names = [
      for (final n in m.values(t))
        if (n.startsWith('js_line_') ||
            moving.contains(n) && m.keyTimes(t, n).isNotEmpty)
          n,
    ];
    if (names.isEmpty) return const [];
    final cards = m.cards(t);
    return [
      for (final n in names)
        () {
          final at = m.keyTimes(t, n),
              vs = m.keyValues(t, n),
              k = math.min(at.length, vs.length);
          return Lane(
            name: n,
            label: m.shown(n)?.label ?? n,
            card: [
              for (final (title, held) in cards)
                if (held.contains(n)) title,
            ].firstOrNull,
            at: at.take(k).toList(),
            values: vs.take(k).toList(),
            curves: [
              for (var i = 0; i + 1 < k; i++)
                switch (m.easingOf(t, n, at[i])) {
                  '' => const [0.0, 1.0],
                  final way => easeCurve(way, m),
                },
            ],
          );
        }(),
    ];
  }

  int? _stageTexture;

  int? get stageTexture => _stageTexture;
  set stageTexture(int? id) {
    if (id == _stageTexture) return;
    _stageTexture = id;
    _onStageTextureChanged();
  }

  /// Active shelf effects on layer [id].
  List<String> fxOf(int? id) {
    final m = _inside, t = id;
    if (m == null || t == null) return const [];
    final shown = {for (final (title, _) in m.cards(t)) title};
    return [
      for (final (name, _) in m.layerEffects)
        if (shown.contains(name)) name,
    ];
  }

  (double, double) get work => _inside!.work;

  List<(double, String)> get marks => _inside!.marks;

  /// Frames that J and K jump to.
  Set<int> stops({Set<int> skip = const {}}) => {
    for (final (at, _) in marks) (at * _frameRate).round(),
    for (final l in layers)
      if (!skip.contains(l.id)) ...[l.inF, l.outF, ...l.keys],
    ..._playhead.strikes,
  };

  /// Snap targets for drags.
  List<SnapTarget> snapTargets({Set<int> skip = const {}}) => [
    SnapTarget(_playhead.moment.value, SnapKind.playhead),
    for (final (at, _) in marks)
      SnapTarget((at * _frameRate).round(), SnapKind.marker),
    for (final l in layers)
      if (!skip.contains(l.id)) ...[
        SnapTarget(l.inF, SnapKind.layerIn),
        SnapTarget(l.outF, SnapKind.layerOut),
        for (final k in l.keys) SnapTarget(k, SnapKind.keyframe),
      ],
    for (final s in _playhead.strikes) SnapTarget(s, SnapKind.beat),
    if (_inside != null) ...[
      SnapTarget((_inside!.work.$1 * _frameRate).round(), SnapKind.workArea),
      SnapTarget((_inside!.work.$2 * _frameRate).round(), SnapKind.workArea),
    ],
  ];

  Map<double, int> get markColors => _inside?.markColors ?? const {};

  List<(String, double)> get guides => _inside?.guides ?? const [];

  final _byId = <int, Layer>{};

  /// Each layer by its id. A read keeps it; it is made here only for a list filled without one.
  Map<int, Layer> get byId {
    if (_byId.length != layers.length) {
      _byId
        ..clear()
        ..addAll({for (final l in layers) l.id: l});
    }
    return _byId;
  }

  /// All descendant layer ids of a group, however deep.
  List<int> under(int id) {
    final of = byId;
    if (of[id]?.kind != LayerKind.group) return const [];
    return [
      for (final l in layers)
        if (l.ancestors(of).any((p) => p.id == id)) l.id,
    ];
  }

  /// Nesting depth (indent level) of layer [l].
  int depth(Layer l) =>
      l.ancestors(byId).where((p) => p.kind == LayerKind.group).length;

  /// What the undo steps changed (null after a drag). Panels use this to skip rebuilds.
  ({bool layers, Set<(int, String)> values})? lastChange;

  int _afters = 0;

  bool get waiting => _afters > 0;

  /// Awaits the engine's answer to [ticket]. [got] receives the answer (e.g. new layer id).
  void after(
    int ticket, [
    void Function(bool done, String why)? then,
    void Function(int answer)? got,
  ]) {
    final m = _inside;
    if (m == null) return;
    _afters++;
    m.answered(ticket).then((r) {
      final (a, why) = r;
      then?.call(a >= 1, why);
      if (a >= 1) got?.call(a);
      _afters--; // What it changed arrives with the engine's next snapshot.
    });
  }
}
