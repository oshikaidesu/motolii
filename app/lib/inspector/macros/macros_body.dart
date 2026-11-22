// Ableton Live Audio Effect Rack-inspired Macros card:
// 4–8 rotary macro knobs, Map mode (click any parameter below + click Map on a
// knob), Rand (randomize mapped knobs), Macro Variations snapshots, and live
// Mappings table with Min / Max / Invert / Remove.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/well_pill.dart' show maybeTip;
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/macros/macro_knob.dart';
import 'package:motolii/inspector/macros/macro_model.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/text_gestures.dart' show TypedField;

/// Dedicated host card for layer Macros (`hostCards['Macros']`).
class MacrosBody extends StatefulWidget {
  const MacrosBody(this.card, {super.key});
  final CardDeclaration card;

  static const drawn = <String>{
    'macro_1',
    'macro_2',
    'macro_3',
    'macro_4',
    'macro_5',
    'macro_6',
    'macro_7',
    'macro_8',
    'macro_map',
    'macro_names',
    'macro_vars',
  };

  @override
  State<MacrosBody> createState() => _MacrosBodyState();
}

class _MacrosBodyState extends State<MacrosBody> {
  final _rng = math.Random();
  bool _showAllEight = false;

  void _randomize(InspectorValues doc, List<MacroBinding> bindings) {
    final mappedSlots = {for (final b in bindings) b.slot};
    final targets = mappedSlots.isEmpty ? {1, 2, 3, 4} : mappedSlots;
    doc.setMany({
      for (final s in targets)
        'v_macro_$s': () {
          final prev = (doc.get('v_macro_$s') ?? 0.0).round();
          var v = _rng.nextInt(101);
          if (v == prev) v = (v + 37) % 101;
          return v.toDouble();
        }(),
    });
  }

  void _saveVariation(InspectorValues doc) {
    final vars = parseMacroVars(doc.strings['v_macro_vars'] ?? '');
    final name = 'Var ${vars.length + 1}';
    final vals = [
      for (var s = 1; s <= macroSlotCount; s++)
        (doc.get('v_macro_$s') ?? 0.0).clamp(0.0, 100.0),
    ];
    doc.str(
      'v_macro_vars',
      writeMacroVars([...vars, (name: name, values: vals)]),
    );
  }

  void _recallVariation(InspectorValues doc, MacroVariation v) {
    doc.setMany({
      for (var s = 1; s <= macroSlotCount; s++)
        'v_macro_$s': v.values[s - 1].clamp(0.0, 100.0),
    });
  }

  void _deleteVariation(InspectorValues doc, int index) {
    final vars = parseMacroVars(doc.strings['v_macro_vars'] ?? '');
    if (index < 0 || index >= vars.length) return;
    vars.removeAt(index);
    doc.str('v_macro_vars', writeMacroVars(vars));
  }

  void _bindPicked(InspectorValues doc, int slot) {
    final prop = doc.strings['macros.pick'];
    if (prop == null || prop.isEmpty) return;
    final (lo, hi) = defaultMacroRange(doc, prop);
    final raw = doc.strings['v_macro_map'] ?? '';
    doc.str(
      'v_macro_map',
      upsertMacroBinding(raw, (slot: slot, prop: prop, min: lo, max: hi)),
    );
    doc.str('macros.pick', '');
  }

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final rawMap = doc.strings['v_macro_map'] ?? '';
    final bindings = parseMacroMap(rawMap);
    final names = parseMacroNames(doc.strings['v_macro_names'] ?? '');
    final vars = parseMacroVars(doc.strings['v_macro_vars'] ?? '');
    final mapMode = doc.flags['macros.map'] ?? false;
    final showVars = doc.flags['macros.vars'] ?? vars.isNotEmpty;
    final picked = doc.strings['macros.pick'];
    final pickedProp = (picked != null && picked.isNotEmpty) ? picked : null;

    final usesUpperHalf =
        bindings.any((b) => b.slot > 4) ||
        names.keys.any((s) => s > 4) ||
        List.generate(
          4,
          (i) => doc.get('v_macro_${i + 5}') ?? 0.0,
        ).any((v) => v > 0.01);
    final count = (_showAllEight || usesUpperHalf) ? 8 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ableton-style top action strip: Map | Rand | 4/8 | Vars.
        Row(
          children: [
            _ActionPill(
              key: const ValueKey('macros:map'),
              label: 'Map',
              tip: mapMode ? 'Exit Macro Map mode' : 'Enter Macro Map mode — click any parameter below, then click Map on a knob',
              active: mapMode,
              onTap: () {
                if (mapMode) doc.str('macros.pick', '');
                doc.flag('macros.map', !mapMode);
              },
            ),
            SizedBox(width: Shape.s(4)),
            _ActionPill(
              key: const ValueKey('macros:rand'),
              label: 'Rand',
              tip: 'Randomize mapped macro knobs (one undo step)',
              active: false,
              onTap: () => _randomize(doc, bindings),
            ),
            SizedBox(width: Shape.s(4)),
            _ActionPill(
              key: const ValueKey('macros:vars'),
              label: vars.isEmpty ? 'Vars' : 'Vars (${vars.length})',
              tip: 'Macro Variations — save and recall knob snapshots',
              active: showVars && vars.isNotEmpty,
              onTap: () => doc.flag('macros.vars', !showVars),
            ),
            const Spacer(),
            maybeTip(
              context,
              count == 4 ? 'Show 8 macros' : 'Show 4 macros',
              Pressable(
                key: const ValueKey('macros:count'),
                onTap: () => setState(() => _showAllEight = count == 4),
                builder: (_, hot) => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Shape.s(4),
                    vertical: Shape.s(2),
                  ),
                  child: Text(
                    count == 4 ? '+ 8' : '− 4',
                    style: TextStyles.micro(hot ? Grey.g95 : Grey.g56),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Map mode hint banner showing the currently armed target parameter.
        if (mapMode) ...[
          SizedBox(height: Shape.s(5)),
          Container(
            key: const ValueKey('macros:map-banner'),
            padding: EdgeInsets.symmetric(
              horizontal: Shape.s(7),
              vertical: Shape.s(4),
            ),
            decoration: BoxDecoration(
              color: Accent.fill.withValues(alpha: 0.10),
              borderRadius: Shape.round(4),
              border: Border.all(color: Accent.fill.withValues(alpha: 0.35)),
            ),
            child: Text(
              pickedProp == null
                  ? 'Click any parameter below, then click Map on a knob'
                  : 'Ready: ${_labelOf(doc, pickedProp)} — click Map on a knob',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.micro(Accent.fill),
            ),
          ),
        ],

        // Rotary knob grid (4 across, 1 or 2 rows).
        SizedBox(height: Shape.s(5)),
        for (var rowStart = 1; rowStart <= count; rowStart += 4) ...[
          if (rowStart > 1) SizedBox(height: InspectorSkin.tileGap),
          Row(
            children: [
              for (var s = rowStart; s < rowStart + 4; s++) ...[
                if (s > rowStart) SizedBox(width: InspectorSkin.tileGap),
                Expanded(
                  child: MacroKnob(
                    doc: doc,
                    slot: s,
                    label: names[s] ?? 'Macro $s',
                    mappedCount: bindings.where((b) => b.slot == s).length,
                    mapMode: mapMode,
                    pickedProp: pickedProp,
                    onRename: (newName) {
                      final next = Map.of(names);
                      if (newName.isEmpty || newName == 'Macro $s') {
                        next.remove(s);
                      } else {
                        next[s] = newName;
                      }
                      doc.str('v_macro_names', writeMacroNames(next));
                    },
                    onBindPicked: () => _bindPicked(doc, s),
                  ),
                ),
              ],
            ],
          ),
        ],

        // Macro Variations strip (Ableton Live 11 snapshots).
        if (showVars) ...[
          SizedBox(height: Shape.s(5)),
          _VariationsStrip(
            vars: vars,
            onNew: () => _saveVariation(doc),
            onRecall: (v) => _recallVariation(doc, v),
            onDelete: (i) => _deleteVariation(doc, i),
          ),
        ],

        // Macro Mappings table (Min / Max / Invert / Remove) when in Map mode
        // or whenever bindings exist and Map mode is open.
        if (bindings.isNotEmpty && mapMode) ...[
          SizedBox(height: Shape.s(6)),
          _MappingsTable(
            doc: doc,
            bindings: bindings,
            rawMap: rawMap,
            labelOf: (prop) => _labelOf(doc, prop),
          ),
        ],
      ],
    );
  }

  String _labelOf(InspectorValues doc, String prop) {
    final found = findCardParam(doc, prop);
    if (found == null) return prop;
    return '${found.card.name} · ${found.param.label}';
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.tip,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String label;
  final String tip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => maybeTip(
    context,
    tip,
    Pressable(
      onTap: onTap,
      builder: (_, hot) => Container(
        height: Shape.z(20),
        padding: EdgeInsets.symmetric(horizontal: Shape.s(7)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? Accent.fill.withValues(alpha: hot ? 0.28 : 0.20)
              : (hot ? Grey.g26 : InspectorSkin.well),
          borderRadius: Shape.round(4),
          border: Border.all(
            color: active ? Accent.fill.withValues(alpha: 0.65) : Grey.g26,
          ),
        ),
        child: Text(
          label,
          style: TextStyles.micro(
            active ? Accent.fill : (hot ? Grey.g95 : Grey.g76),
          ),
        ),
      ),
    ),
  );
}

class _VariationsStrip extends StatelessWidget {
  const _VariationsStrip({
    required this.vars,
    required this.onNew,
    required this.onRecall,
    required this.onDelete,
  });

  final List<MacroVariation> vars;
  final VoidCallback onNew;
  final ValueChanged<MacroVariation> onRecall;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: Shape.s(6), vertical: Shape.s(4)),
    decoration: BoxDecoration(
      color: InspectorSkin.well,
      borderRadius: Shape.round(5),
      border: Border.all(color: Grey.g20),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Pressable(
            key: const ValueKey('macros:var:new'),
            onTap: onNew,
            builder: (_, hot) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: Shape.s(6),
                vertical: Shape.s(2),
              ),
              decoration: BoxDecoration(
                color: hot ? Grey.g26 : Grey.g20,
                borderRadius: Shape.round(3),
              ),
              child: Text(
                '+ New',
                style: TextStyles.micro(hot ? Grey.g95 : Grey.g76),
              ),
            ),
          ),
          for (var i = 0; i < vars.length; i++) ...[
            SizedBox(width: Shape.s(4)),
            Container(
              padding: EdgeInsets.only(left: Shape.s(6), right: Shape.s(3)),
              height: Shape.z(18),
              decoration: BoxDecoration(
                color: Grey.g15,
                borderRadius: Shape.round(3),
                border: Border.all(color: Grey.g26),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Pressable(
                    key: ValueKey('macros:var:$i'),
                    onTap: () => onRecall(vars[i]),
                    builder: (_, hot) => Text(
                      vars[i].name,
                      style: TextStyles.micro(hot ? Accent.fill : Grey.g91),
                    ),
                  ),
                  SizedBox(width: Shape.s(4)),
                  Pressable(
                    key: ValueKey('macros:var:del:$i'),
                    onTap: () => onDelete(i),
                    builder: (_, hot) => Text(
                      '×',
                      style: TextStyles.micro(hot ? Grey.g95 : Grey.g44),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _MappingsTable extends StatelessWidget {
  const _MappingsTable({
    required this.doc,
    required this.bindings,
    required this.rawMap,
    required this.labelOf,
  });

  final InspectorValues doc;
  final List<MacroBinding> bindings;
  final String rawMap;
  final String Function(String prop) labelOf;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(Shape.s(6)),
    decoration: BoxDecoration(
      color: InspectorSkin.well,
      borderRadius: Shape.round(6),
      border: Border.all(color: Grey.g20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Mappings', style: TextStyles.micro(Grey.g56)),
            ),
            SizedBox(
              width: Shape.z(48),
              child: Text(
                'Min',
                textAlign: TextAlign.right,
                style: TextStyles.micro(Grey.g56),
              ),
            ),
            SizedBox(width: Shape.z(18)),
            SizedBox(
              width: Shape.z(48),
              child: Text(
                'Max',
                textAlign: TextAlign.right,
                style: TextStyles.micro(Grey.g56),
              ),
            ),
            SizedBox(width: Shape.z(16)),
          ],
        ),
        SizedBox(height: Shape.s(3)),
        for (final b in bindings)
          _MappingRow(
            doc: doc,
            binding: b,
            label: labelOf(b.prop),
            onRange: (lo, hi) => doc.str(
              'v_macro_map',
              updateMacroRange(rawMap, b.prop, lo, hi),
            ),
            onInvert: () =>
                doc.str('v_macro_map', invertMacroBinding(rawMap, b.prop)),
            onRemove: () =>
                doc.str('v_macro_map', removeMacroBinding(rawMap, b.prop)),
          ),
      ],
    ),
  );
}

class _MappingRow extends StatelessWidget {
  const _MappingRow({
    required this.doc,
    required this.binding,
    required this.label,
    required this.onRange,
    required this.onInvert,
    required this.onRemove,
  });

  final InspectorValues doc;
  final MacroBinding binding;
  final String label;
  final void Function(double docMin, double docMax) onRange;
  final VoidCallback onInvert;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tone = macroSlotColor(binding.slot);
    final shownMin = macroToShown(doc, binding.prop, binding.min);
    final shownMax = macroToShown(doc, binding.prop, binding.max);

    return Padding(
      padding: EdgeInsets.only(top: Shape.s(3)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Shape.s(4),
              vertical: Shape.s(1),
            ),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.18),
              borderRadius: Shape.round(3),
            ),
            child: Text('M${binding.slot}', style: TextStyles.micro(tone)),
          ),
          SizedBox(width: Shape.s(5)),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.micro(Grey.g91),
            ),
          ),
          _RangeBox(
            key: ValueKey('macros:min:${binding.prop}'),
            value: shownMin,
            onDone: (v) =>
                onRange(macroToDoc(doc, binding.prop, v), binding.max),
          ),
          SizedBox(
            width: Shape.z(18),
            child: Center(
              child: maybeTip(
                context,
                'Invert range (swap Min / Max)',
                Pressable(
                  key: ValueKey('macros:invert:${binding.prop}'),
                  onTap: onInvert,
                  builder: (_, hot) => Text(
                    '⇄',
                    style: TextStyles.micro(hot ? Accent.fill : Grey.g56),
                  ),
                ),
              ),
            ),
          ),
          _RangeBox(
            key: ValueKey('macros:max:${binding.prop}'),
            value: shownMax,
            onDone: (v) =>
                onRange(binding.min, macroToDoc(doc, binding.prop, v)),
          ),
          SizedBox(
            width: Shape.z(16),
            child: Center(
              child: Pressable(
                key: ValueKey('macros:unmap:${binding.prop}'),
                onTap: onRemove,
                builder: (_, hot) => Text(
                  '×',
                  style: TextStyles.micro(hot ? Grey.g95 : Grey.g44),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeBox extends StatelessWidget {
  const _RangeBox({required this.value, required this.onDone, super.key});

  final double value;
  final ValueChanged<double> onDone;

  @override
  Widget build(BuildContext context) {
    final text = value == value.roundToDouble()
        ? '${value.round()}'
        : value.toStringAsFixed(1);
    return Container(
      width: Shape.z(48),
      height: Shape.z(18),
      padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: Grey.g15,
        borderRadius: Shape.round(3),
        border: Border.all(color: Grey.g26),
      ),
      child: TypedField(
        text: text,
        standing: true,
        escapes: true,
        align: TextAlign.right,
        style: TextStyles.micro(Grey.g91),
        cursor: Grey.g95,
        backgroundCursor: Grey.g20,
        selection: Role.selected.withValues(alpha: 0.4),
        onDone: (said) {
          if (said == null) return;
          final parsed = double.tryParse(said.trim());
          if (parsed != null) onDone(parsed);
        },
      ),
    );
  }
}
