// The "+ Operator" button and grouped picker on the Paths card.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;

/// The "+ Operator" button and the grouped picker that appears below it.
class PathsPicker extends StatefulWidget {
  const PathsPicker({required this.isSub, required this.onAdd, super.key});

  final bool Function(String id) isSub;
  final void Function(String id) onAdd;

  // Grouped path operators; fill_rule lives inside PathsPreview, and
  // Morph/Trail need another layer so they stay off the picker.
  static const _groups = [
    ('Deform', ['round', 'bloat', 'offset', 'zigzag']),
    ('Texture', ['rough', 'resample', 'voxel']),
    ('Animate', ['trim']),
  ];

  static const _labels = <String, String>{
    'round': 'Round',
    'bloat': 'Bloat',
    'offset': 'Offset',
    'zigzag': 'Zig zag',
    'rough': 'Rough',
    'resample': 'Points',
    'voxel': 'Squares',
    'trim': 'Trim',
  };

  @override
  State<PathsPicker> createState() => _PathsPickerState();
}

class _PathsPickerState extends State<PathsPicker> {
  bool _picking = false;

  void _add(String id) {
    widget.onAdd(id);
    setState(() => _picking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pressable(
          key: const ValueKey('paths-add-operator'),
          onTap: () => setState(() => _picking = !_picking),
          builder: (_, hot) => Container(
            height: Shape.z(28),
            decoration: BoxDecoration(
              color: hot ? Grey.g15 : Grey.g13,
              borderRadius: Shape.round(6),
              border: Border.all(
                color: _picking ? Grey.g38 : Grey.g20,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '+ Operator',
              style: TextStyles.label(_picking || hot ? Grey.g76 : Grey.g44),
            ),
          ),
        ),
        if (_picking) _buildPicker(),
      ],
    );
  }

  Widget _buildPicker() {
    return Container(
      margin: EdgeInsets.only(top: Shape.s(2)),
      padding: EdgeInsets.all(Shape.s(4)),
      decoration: BoxDecoration(
        color: Grey.g10,
        borderRadius: Shape.round(8),
        border: Border.all(color: Grey.g20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (group, ids) in PathsPicker._groups)
            ..._buildGroup(group, ids),
        ],
      ),
    );
  }

  List<Widget> _buildGroup(String group, List<String> ids) {
    final available = [
      for (final id in ids)
        if (!widget.isSub(id)) id,
    ];
    if (available.isEmpty) return [];
    return [
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(6),
          vertical: Shape.s(3),
        ),
        child: Text(group, style: TextStyles.label(Grey.g44)),
      ),
      for (final id in available)
        Pressable(
          key: ValueKey('paths-pick:$id'),
          onTap: () => _add(id),
          builder: (_, hot) => Container(
            height: Shape.z(26),
            padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
            decoration: BoxDecoration(
              color: hot ? Grey.g20 : Grey.g10,
              borderRadius: Shape.round(5),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              PathsPicker._labels[id] ?? id.replaceAll('_', ' '),
              style: TextStyles.name(hot ? Grey.g91 : Grey.g76),
            ),
          ),
        ),
    ];
  }
}
