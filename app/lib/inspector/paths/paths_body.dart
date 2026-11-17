// The Paths card's inside: a sample shape showing what the active operators do, a reorderable stack of those operators,
// and a picker grouped by kind to add more. The stack's order is display only; the engine applies them in its own
// fixed order. Points and inner are on the Shape card, not here.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/paths/paths_picker.dart';
import 'package:motolii/inspector/paths/paths_preview.dart';
import 'package:motolii/inspector/paths/paths_stack.dart';
import 'package:motolii/skin/tokens.dart';

/// The Paths card's inside (see host_cards.dart).
class PathsBody extends StatefulWidget {
  const PathsBody(this.card, {super.key});
  final CardDeclaration card;

  static const Set<String> drawn = {
    'round',
    'bloat',
    'offset',
    'zigzag',
    'zigzag_ridges',
    'zigzag_smooth',
    'rough',
    'rough_detail',
    'resample',
    'fill_rule',
    'morph',
    'morph_to',
    'morph_steps',
    'trail',
    'trail_length',
    'trim',
    'trim_offset',
  };

  // Default value set when the user adds an operator, chosen so the effect is visible immediately.
  static const _defaults = <String, double>{
    'round': 0.15,
    'bloat': 0.3,
    'offset': 3.0,
    'zigzag': 2.0,
    'zigzag_ridges': 8.0,
    'zigzag_smooth': 0.5,
    'rough': 0.1,
    'rough_detail': 0.1,
    'resample': 100.0,
    'fill_rule': 1.0,
    'morph': 0.5,
    'morph_to': 1.0,
    'morph_steps': 10.0,
    'trail': 1.0,
    'trail_length': 1.0,
    'trim': 0.8,
    'trim_offset': 0.0,
  };

  // Functional dependencies: a value the engine only reads when its owner is on
  // (an `if` guard in evaluate_shape.cpp), so on its own it does nothing. The
  // engine does not fold these (Parameter.fold is null), so they are named here.
  // Morph and Trail reach for another layer, so they are kept off the picker
  // entirely (not in _groups); they still fold their own subs when already set.
  static const _funcDeps = <String, List<String>>{
    'rough': ['rough_detail'],
    'trim': ['trim_offset'],
    'morph': ['morph_to', 'morph_steps'],
    'trail': ['trail_length'],
  };
  static final _funcSubs = {for (final subs in _funcDeps.values) ...subs};

  // All stackable operators in their default order.
  static const _stackable = [
    'round',
    'bloat',
    'offset',
    'zigzag',
    'zigzag_ridges',
    'zigzag_smooth',
    'rough',
    'rough_detail',
    'resample',
    'fill_rule',
    'morph',
    'morph_to',
    'morph_steps',
    'trail',
    'trail_length',
    'trim',
    'trim_offset',
  ];

  @override
  State<PathsBody> createState() => _PathsBodyState();
}

class _PathsBodyState extends State<PathsBody> {
  // The parents and standalone operators on the stack, in order. Each parent's
  // subs come with it; they are not held here.
  List<String> _order = [];
  bool _initialized = false;

  Map<String, Parameter> get _params => {
    for (final p in widget.card.params) p.id: p,
  };

  // The subs shown under [id]: those the engine folds under it (Parameter.fold ==
  // its label, e.g. Zig zag's Ridges/Smooth) plus its functional dependents.
  // Empty for an operator that stands on its own.
  List<String> _subsOf(String id) {
    final label = _params[id]?.label;
    final byFold = label == null
        ? const <String>[]
        : [
            for (final p in widget.card.params)
              if (p.fold == label) p.id,
          ];
    return [...byFold, ...?PathsBody._funcDeps[id]];
  }

  // A sub rides under another operator — folded by the engine or depending on it
  // — so it never sits on the stack or shows in the picker on its own.
  bool _isSub(String id) =>
      _params[id]?.fold != null || PathsBody._funcSubs.contains(id);

  void _init(InspectorValues doc) {
    if (_initialized) return;
    _initialized = true;
    // Only parents and standalone operators sit on the stack; a sub shows under
    // its parent, so an orphan sub left in the document is ignored here.
    _order = [
      for (final id in PathsBody._stackable)
        if (!_isSub(id) && (doc.get('v_$id') ?? 0) != 0.0) id,
    ];
  }

  // Adding an operator turns on its folded subs too, each at its default, as one
  // gesture (only Zig zag has any; everything else adds just itself).
  void _add(InspectorValues doc, String id) {
    doc.beginGesture();
    for (final x in [id, ..._subsOf(id)]) {
      doc.set('v_$x', PathsBody._defaults[x] ?? 1.0);
    }
    doc.endGesture();
    setState(() {
      _order = [..._order, id];
    });
  }

  // Removing an operator by index. The engine value is zeroed only when this is
  // the last instance of that operator on the stack.
  void _removeAt(InspectorValues doc, int index, String id) {
    final remaining = [..._order]..removeAt(index);
    if (!remaining.contains(id)) {
      doc.beginGesture();
      for (final x in [id, ..._subsOf(id)]) {
        doc.set('v_$x', 0.0);
      }
      doc.endGesture();
    }
    setState(() => _order = remaining);
  }

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    _init(doc);
    final params = _params;
    final listenables = [
      for (final id in PathsBody._stackable) doc.watch('v_$id'),
      doc.watch('v_points'),
      doc.watch('v_inner'),
    ];
    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final round = doc.get('v_round') ?? 0;
        final points = (doc.get('v_points') ?? 4).round();
        final inner = doc.get('v_inner') ?? 0;
        final shape = doc.strings['shape'] ?? '';
        final svgPath = doc.actions.shapeSvg?.call() ?? '';
        return Padding(
          padding: EdgeInsets.only(bottom: Shape.s(6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PathsPreview(
                round: round,
                points: points,
                inner: inner,
                shape: shape,
                svgPath: svgPath,
              ),
              SizedBox(height: Shape.s(8)),
              if (_order.isNotEmpty)
                PathsStack(
                  order: _order,
                  params: params,
                  doc: doc,
                  subsOf: _subsOf,
                  onRemoveAt: (i, id) => _removeAt(doc, i, id),
                  onReorder: (from, to) {
                    setState(() {
                      final item = _order.removeAt(from);
                      _order.insert(to, item);
                    });
                  },
                ),
              PathsPicker(isSub: _isSub, onAdd: (id) => _add(doc, id)),
            ],
          ),
        );
      },
    );
  }
}
