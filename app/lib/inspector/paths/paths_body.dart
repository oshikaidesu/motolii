// The Paths card's inside: top row pairing the live outline preview (with
// in-well Fill rule toggle) beside shape-geometry tiles (Points / Inner) when
// present, followed by a real ordered & repeatable operator stack persisted to
// the engine via `v_path_ops`.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/controls/parameter_tile.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/paths/paths_picker.dart';
import 'package:motolii/inspector/paths/paths_preview.dart';
import 'package:motolii/inspector/paths/paths_stack.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';

/// The Paths card's inside (see host_cards.dart).
class PathsBody extends StatefulWidget {
  const PathsBody(this.card, {super.key});
  final CardDeclaration card;

  static const Set<String> drawn = {
    'points',
    'inner',
    'path_ops',
    'path_smooth',
    'path_falloff',
    'round',
    'bloat',
    'offset',
    'zigzag',
    'zigzag_ridges',
    'zigzag_smooth',
    'rough',
    'rough_detail',
    'resample',
    'voxel',
    'fill_rule',
    'morph',
    'morph_to',
    'morph_steps',
    'trail',
    'trail_length',
    'trim',
    'trim_begin',
    'trim_offset',
  };

  // Default value set when adding an operator so its effect is visible immediately.
  // Kept inside engine/document/values.h ranges (normalized shape units for
  // offset/zigzag; inspector display percentages for share params like round).
  static const _defaults = <String, double>{
    'path_smooth': 35.0,
    'round': 15.0,
    'bloat': 0.25,
    'offset': 0.05,
    'zigzag': 0.04,
    'zigzag_ridges': 8.0,
    'zigzag_smooth': 0.0,
    'rough': 5.0,
    'rough_detail': 5.0,
    'resample': 24.0,
    'voxel': 5.0,
    'morph': 50.0,
    'morph_to': 1.0,
    'morph_steps': 10.0,
    'trail': 1.0,
    'trail_length': 1.0,
    'trim': 80.0,
    'trim_begin': 0.0,
    'trim_offset': 0.0,
  };

  static const _funcDeps = <String, List<String>>{
    'rough': ['rough_detail'],
    'trim': ['trim_begin', 'trim_offset'],
    'morph': ['morph_to', 'morph_steps'],
    'trail': ['trail_length'],
  };
  static final _funcSubs = {for (final subs in _funcDeps.values) ...subs};

  // Stackable top-level operators in legacy default order.
  static const _stackable = [
    'path_smooth',
    'round',
    'bloat',
    'offset',
    'zigzag',
    'rough',
    'resample',
    'voxel',
    'morph',
    'trail',
    'trim',
  ];

  @override
  State<PathsBody> createState() => _PathsBodyState();
}

class _PathsBodyState extends State<PathsBody> {
  final _rng = math.Random();

  Map<String, Parameter> get _params => {
    for (final p in widget.card.params) p.id: p,
  };

  List<String> _subsOf(String entry) {
    final (prefix, base) = splitPathOpId(entry);
    final label = _params[base]?.label;
    final byFold = label == null
        ? const <String>[]
        : [
            for (final p in widget.card.params)
              if (p.fold == label && !p.id.contains(':')) p.id,
          ];
    final baseSubs = [...byFold, ...?PathsBody._funcDeps[base]];
    return [for (final s in baseSubs) '$prefix$s'];
  }

  bool _isSub(String id) {
    final (_, base) = splitPathOpId(id);
    return _params[base]?.fold != null || PathsBody._funcSubs.contains(base);
  }

  /// Reads the active operator order from `v_path_ops`, falling back to active
  /// non-zero legacy single properties when `v_path_ops` has no valid entries.
  List<String> _orderOf(InspectorValues doc) {
    final raw = (doc.strings['v_path_ops'] ?? '').trim();
    if (raw.isNotEmpty) {
      final parsed = [
        for (final tok in raw.split(RegExp(r'\s+')))
          if (tok.isNotEmpty &&
              !_isSub(tok) &&
              PathsBody._stackable.contains(splitPathOpId(tok).$2))
            tok,
      ];
      if (parsed.isNotEmpty) return parsed;
    }
    return [
      for (final id in PathsBody._stackable)
        if (!_isSub(id) && (doc.get('v_$id') ?? 0) != 0.0) id,
    ];
  }

  String _freshEntry(String kind, List<String> existing) {
    final usedBase = existing.any((e) => e == kind);
    if (!usedBase) return kind;
    final usedIds = {
      for (final e in existing)
        if (splitPathOpId(e).$1.isNotEmpty) splitPathOpId(e).$1.substring(0, 6),
    };
    while (true) {
      final hex = _rng.nextInt(0x1000000).toRadixString(16).padLeft(6, '0');
      if (!usedIds.contains(hex)) return '$hex:$kind';
    }
  }

  void _add(InspectorValues doc, String kind) {
    final current = _orderOf(doc);
    final entry = _freshEntry(kind, current);
    final next = [...current, entry];
    doc.beginGesture();
    for (final x in [entry, ..._subsOf(entry)]) {
      final (_, base) = splitPathOpId(x);
      final raw = PathsBody._defaults[base] ?? 1.0;
      final p = _params[base];
      final val = (p != null && p.min != null && p.max != null)
          ? raw.clamp(p.min!, p.max!).toDouble()
          : raw;
      doc.set('v_$x', val);
    }
    doc.str('v_path_ops', next.join(' '));
    doc.endGesture();
  }

  void _removeAt(InspectorValues doc, int index, String entry) {
    final current = _orderOf(doc);
    if (index < 0 || index >= current.length) return;
    final next = [...current]..removeAt(index);
    doc.beginGesture();
    for (final x in [entry, ..._subsOf(entry)]) {
      doc.set('v_$x', 0.0);
    }
    doc.str('v_path_ops', next.join(' '));
    doc.endGesture();
  }

  void _reorder(InspectorValues doc, int from, int to) {
    final current = _orderOf(doc);
    if (from < 0 || from >= current.length || to < 0 || to >= current.length) {
      return;
    }
    final next = [...current];
    final item = next.removeAt(from);
    next.insert(to, item);
    doc
      ..beginGesture()
      ..str('v_path_ops', next.join(' '))
      ..endGesture();
  }

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final params = _params;
    final pointsP = params['points'];
    final innerP = params['inner'];
    final falloffP = params['path_falloff'];
    final fillRuleP = params['fill_rule'];

    final listenables = <Listenable>[
      doc,
      for (final p in widget.card.params) doc.watch('v_${p.id}'),
    ];

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final order = _orderOf(doc);
        final round = doc.get('v_round') ?? 0;
        final points = (doc.get('v_points') ?? 4).round();
        final inner = doc.get('v_inner') ?? 0;
        final shape = doc.strings['shape'] ?? '';
        final svgPath = doc.actions.shapeSvg?.call() ?? '';

        final fillRuleOpts = fillRuleP?.options ?? const <String>[];
        final fillRuleIdx = fillRuleP == null || fillRuleOpts.isEmpty
            ? 0
            : (doc.get('v_fill_rule') ?? fillRuleP.def).round().clamp(
                0,
                fillRuleOpts.length - 1,
              );
        final evenOdd = fillRuleP != null && fillRuleOpts.length >= 2
            ? fillRuleOpts[fillRuleIdx].toLowerCase() == 'evenodd'
            : null;
        void toggleFillRule() {
          if (fillRuleP == null || fillRuleOpts.length < 2) return;
          final next = (fillRuleIdx + 1) % fillRuleOpts.length;
          doc
            ..beginGesture()
            ..set('v_fill_rule', next.toDouble())
            ..endGesture();
        }

        final hasGeom =
            pointsP != null ||
            innerP != null ||
            (shape == 'path' && falloffP != null);

        return Padding(
          padding: EdgeInsets.only(bottom: Shape.s(6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasGeom)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: Shape.z(104),
                      child: PathsPreview(
                        round: round,
                        points: points,
                        inner: inner,
                        shape: shape,
                        svgPath: svgPath,
                        height: InspectorSkin.tile,
                        compact: true,
                        evenOdd: evenOdd,
                        onToggleFillRule: toggleFillRule,
                      ),
                    ),
                    if (shape == 'path' && falloffP != null) ...[
                      SizedBox(width: InspectorSkin.tileGap),
                      Expanded(child: ParameterTile(falloffP)),
                    ] else ...[
                      if (pointsP != null) ...[
                        SizedBox(width: InspectorSkin.tileGap),
                        Expanded(child: ParameterTile(pointsP)),
                      ],
                      if (innerP != null) ...[
                        SizedBox(width: InspectorSkin.tileGap),
                        Expanded(child: ParameterTile(innerP)),
                      ],
                    ],
                  ],
                )
              else
                PathsPreview(
                  round: round,
                  points: points,
                  inner: inner,
                  shape: shape,
                  svgPath: svgPath,
                  height: Shape.z(52),
                  compact: false,
                  evenOdd: evenOdd,
                  onToggleFillRule: toggleFillRule,
                ),
              SizedBox(height: Shape.s(6)),
              if (order.isNotEmpty)
                PathsStack(
                  order: order,
                  params: params,
                  doc: doc,
                  subsOf: _subsOf,
                  onRemoveAt: (i, entry) => _removeAt(doc, i, entry),
                  onReorder: (from, to) => _reorder(doc, from, to),
                ),
              PathsPicker(isSub: _isSub, onAdd: (kind) => _add(doc, kind)),
            ],
          ),
        );
      },
    );
  }
}
