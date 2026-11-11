// What the window reads from the engine's document (ProjectReader): the layers as rows, the marks, the guides and the
// tempo, and the requests still on their way to the engine.
import 'dart:developer' show Timeline, TimelineTask;
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart' show ValueNotifier, VoidCallback;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_watch.dart';
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/workspace/state/beats.dart';
import 'package:motolii/workspace/state/composition_settings.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/playhead.dart';

/// Reads the engine's document for the window: its layers as rows, its marks, guides and tempo.
///
/// It also counts the requests sent to the engine that are not answered yet.
class ProjectReader {
  /// Creates a reader that is connected to no engine: [layers] is then whatever the caller puts in it.
  ///
  /// [onLayersRead] is called each time the layers were read again, before [onChanged]. [onChanged] is called when
  /// the panels should look at the document again. [onStageTextureChanged] is called when [stageTexture] changes.
  ProjectReader({
    required this._composition,
    required this._playhead,
    required this._onLayersRead,
    required this._onChanged,
    required this._onStageTextureChanged,
  });

  final CompositionSettings _composition;
  final Playhead _playhead;
  final VoidCallback _onLayersRead, _onChanged, _onStageTextureChanged;

  int get _frameRate => _composition.frameRate;

  /// Whether layer [t] is a sound: a video layer whose file has no image, hidden and only heard (see doc_add).
  /// Like Alight Motion's audio layer (docs/design/alight_motion_ui.md).
  static bool isSound(Motolii m, int t) =>
      m.word(t, 'kind') == 'film' && m.kindOf(m.word(t, 'file')) == 'sound';

  /// The document's layers as rows, the topmost first.
  final layers = <Layer>[];

  /// The engine this window is connected to (see motolii.dart), or null for the sample document.
  /// When connected, the layers are the document's layers, a change is a call to the engine, and the playhead is its time.
  Motolii? _inside;

  /// The engine this window is connected to, or null for the sample document.
  Motolii? get inside => _inside;

  /// Connects to the engine [inside], takes the composition's settings and the playhead from it, and reads its document.
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
    // The timeline counts frames at the document's rate, as the exported video does.
    _composition.frameRate = _frameRateOf(inside);
    _composition.size = Size(
      inside.size.$1.toDouble(),
      inside.size.$2.toDouble(),
    );
    // The playhead starts at the engine's time.
    _playhead.moment.value = (inside.now * _frameRate).round();
    reread();
  }

  /// Reopens the document when it no longer has the size it was opened at. Set by the host.
  VoidCallback? refit;

  /// How many times the document has been read again.
  int rev = 0;

  /// Like [rev] but without drags. Things built from the document's structure, such as the cards, rebuild when it changes.
  int reads = 0;

  // A layer that lasts forever (negative [lasts]) runs to the document's end.
  int _outF(int from, double lasts) => lasts < 0
      ? _composition.duration
      : (from + (lasts * _frameRate).round()).clamp(
          from + 1,
          _composition.duration,
        );

  /// Reads layer [id]'s bar from the engine again, for example during a drag, so the drawn bar matches the engine.
  void respan(String id) {
    final m = _inside,
        l = layers.where((l) => l.id == id).firstOrNull,
        t = int.tryParse(id);
    if (m == null || l == null || t == null) return;
    l.inF = ((m.value(t, 'start', 0) ?? 0) * _frameRate).round();
    l.outF = _outF(l.inF, m.lasts(t));
    shown();
  }

  bool _gone = false;

  /// A counter that goes up whenever the engine has a new snapshot of the current time.
  final seen = ValueNotifier<int>(0);

  /// The frame ranges cached on disk for playback. The timeline marks them like After Effects' green line.
  final kept = ValueNotifier<List<(int, int)>>(const []);

  /// Stops answering the engine's snapshots and releases the two notifiers.
  void dispose() {
    _gone = true;
    seen.dispose();
    kept.dispose();
  }

  /// Tells the panels to look again after the engine's view changed without the document changing, such as during a drag.
  void shown() {
    lastChange = null; // This is not an undo step, so what changed is unknown.
    rev++;
    _onChanged();
  }

  /// The document's tempo in beats per minute (0 for none).
  double get bpm => _inside?.value(0, 'bpm', 0) ?? 0;

  /// The document's beat grid, or null when it has no tempo.
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

  /// Reads the document again after any change, so the panels list what the document holds.
  void reread() => Timeline.timeSync('ws reread', _reread);
  void _reread() {
    final m = _inside;
    if (m == null) return;
    // The document now has another size, from an edit or an undo. The host reopens it, which reads it again.
    if (!m.fits && refit != null) return refit!();
    lastChange = m.changes();
    if (_frameRateOf(m) != _frameRate) {
      // The frame rate changed. Keep the playhead at the same time.
      final at = _playhead.moment.value / _frameRate;
      _composition.frameRate = _frameRateOf(m);
      _playhead.moment.value = (at * _frameRate).round();
    }
    rev++;
    reads++;
    _composition.duration = Timeline.timeSync(
      'MARK seconds',
      () => (m.seconds * _frameRate).round().clamp(1, 1 << 20),
    );
    chosenLabelColors
      ..clear()
      ..addAll({
        for (final t in m.layers)
          if (m.words(t, 'label').indexOf(m.word(t, 'label')) case final i
              when i > 0)
            '$t': i - 1,
      });
    final tl = TimelineTask()..start('MARK layers');
    final holding = {
      for (final t in m.layers) m.parentOf(t),
    }; // The ids of layers that are parents.
    layers
      ..clear()
      ..addAll([
        for (final t
            in m
                .layers
                .reversed) // The topmost layer comes first, as in the sample.
          () {
            final kind = m.word(t, 'kind'),
                from = ((m.value(t, 'start', 0) ?? 0) * _frameRate).round(),
                lasts = m.lasts(t);
            final name = m.word(t, 'name');
            // A keyframe on any animatable property shows as a keyframe on the bar. The engine says which properties those are.
            final keys = <int>{
              for (final s in m.layerKeyTimes(t)) (s * _frameRate).round(),
            }.toList()..sort();
            return Layer(
              '$t',
              name,
              switch (kind) {
                'text' => LayerKind.text,
                'camera' => LayerKind.camera,
                'film' when isSound(m, t) => LayerKind.audio,
                'film' || 'picture' => LayerKind.image,
                'shape'
                    when m.word(t, 'shape') == 'null' && holding.contains(t) =>
                  LayerKind.group,
                _ => LayerKind.shape,
              },
              from,
              _outF(from, lasts),
              keys,
              parent: switch (m.parentOf(t)) {
                > 0 && final p => '$p',
                _ => null,
              },
              lined:
                  (kind == 'picture' || kind == 'solid') &&
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
            );
          }(),
      ]);
    _onLayersRead();
    tl.finish();
    _onChanged();
  }

  int? _stageTexture;

  /// The engine's preview as a Flutter texture id, when connected. Null means the stand-in artwork.
  int? get stageTexture => _stageTexture;
  set stageTexture(int? id) {
    if (id == _stageTexture) return;
    _stageTexture = id;
    _onStageTextureChanged();
  }

  /// The shelf effects on layer [id]: those whose card the engine shows. An effect's card shows while the effect is on.
  List<String> fxOf(String? id) {
    final m = _inside, t = int.tryParse(id ?? '');
    if (m == null || t == null) return const [];
    final shown = {for (final (title, _) in m.cards(t)) title};
    return [
      for (final (name, _) in m.layerEffects)
        if (shown.contains(name)) name,
    ];
  }

  /// The work area in seconds: the range that loops on playback and is exported. Only when connected.
  (double, double) get work => _inside!.work;

  /// The document's markers, each a time in seconds and a name, in time order. Only when connected.
  List<(double, String)> get marks => _inside!.marks;

  /// The frames that dragging snaps to and that J and K jump to, like Alight Motion's snapTargets: the marks, the
  /// other layers' ends and keyframes, and a sound's strikes (the beat marks CapCut's bars snap to).
  Set<int> stops({Set<String> skip = const {}}) => {
    for (final (at, _) in marks) (at * _frameRate).round(),
    for (final l in layers)
      if (!skip.contains(l.id)) ...[l.inF, l.outF, ...l.keys],
    ..._playhead.strikes,
  };

  /// The markers that have a colour: each marker's time mapped to its label colour. Only when connected.
  Map<double, int> get markColors => _inside!.markColors;

  /// The guides: 'x' for vertical and 'y' for horizontal, each with its distance in points from the canvas's left
  /// or top edge. Only when connected.
  List<(String, double)> get guides => _inside!.guides;

  /// The ids of everything a group holds, however deep. Empty for other layers (see doc_under).
  List<String> under(String id) {
    final of = {for (final l in layers) l.id: l};
    if (of[id]?.kind != LayerKind.group) return const [];
    return [
      for (final l in layers)
        if (l.ancestors(of).any((p) => p.id == id)) l.id,
    ];
  }

  /// How many groups contain layer [l]. Its row is indented by that many levels.
  int depth(Layer l) => l
      .ancestors({for (final x in layers) x.id: x})
      .where((p) => p.kind == LayerKind.group)
      .length;

  /// What the undo steps changed since the last read (null when unknown, as after a drag).
  /// A panel showing only some properties rebuilds only when they are among these.
  ({bool layers, Set<(int, String)> values})? lastChange;

  // Requests still pending. The document is read again once, when the last one finishes.
  int _afters = 0;

  /// Whether requests sent to the engine are still pending. The window shows them before the document has them.
  bool get waiting => _afters > 0;

  /// Waits without blocking for a request made with [Motolii.later], then reads the document again and calls
  /// [then] with whether it succeeded and why not. [got] receives the answer, such as the id of a new layer.
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
