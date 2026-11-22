// Universal Signal Macros card: 4–8 signal channels (Knob / Audio / MIDI / Layer / Wave).
// 詳細: docs/design/macros.md
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_actions.dart';
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
    'macro_sources',
    'macro_names',
    'macro_vars',
  };

  @override
  State<MacrosBody> createState() => _MacrosBodyState();
}

class _MacrosBodyState extends State<MacrosBody> {
  final _rng = math.Random();
  bool _showAllEight = false;
  int? _configSlot;

  void _randomize(
    InspectorValues doc,
    List<MacroBinding> bindings,
    Map<int, MacroSource> sources,
  ) {
    bool isKnob(int s) =>
        (sources[s]?.kind ?? MacroSourceKind.knob) == MacroSourceKind.knob;
    final mappedKnobs = {
      for (final b in bindings)
        if (isKnob(b.slot)) b.slot,
    };
    final targets = mappedKnobs.isNotEmpty
        ? mappedKnobs
        : {
            for (var s = 1; s <= 4; s++)
              if (isKnob(s)) s,
          };
    if (targets.isEmpty) return;
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

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final rawMap = doc.strings['v_macro_map'] ?? '';
    final rawSources = doc.strings['v_macro_sources'] ?? '';
    final bindings = parseMacroMap(rawMap);
    final sources = parseMacroSources(rawSources);
    final names = parseMacroNames(doc.strings['v_macro_names'] ?? '');
    final vars = parseMacroVars(doc.strings['v_macro_vars'] ?? '');
    final layers =
        doc.actions.layerChoices?.call() ?? const <MacroLayerChoice>[];
    final mapMode = doc.flags['macros.map'] ?? false;
    final showVars = doc.flags['macros.vars'] ?? vars.isNotEmpty;
    final showRanges = doc.flags['macros.ranges'] ?? false;

    final usesUpperHalf =
        bindings.any((b) => b.slot > 4) ||
        sources.keys.any((s) => s > 4) ||
        names.keys.any((s) => s > 4) ||
        List.generate(
          4,
          (i) => doc.get('v_macro_${i + 5}') ?? 0.0,
        ).any((v) => v > 0.01);
    final count = (_showAllEight || usesUpperHalf) ? 8 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top action strip: Map | Rand | Vars | Ranges (N) | + 8.
        Row(
          children: [
            _ActionPill(
              key: const ValueKey('macros:map'),
              label: 'Map',
              tip: mapMode ? 'Exit Map mode' : 'Enter Map mode — scroll through stacked effects and click parameters to bind',
              active: mapMode,
              onTap: () {
                if (mapMode) {
                  doc.macroDrag.value = null;
                  doc.flag('macros.map', false);
                } else {
                  doc.macroDrag.value ??= nextFreeMacroSlot(rawMap);
                  doc.flag('macros.map', true);
                }
              },
            ),
            SizedBox(width: Shape.s(4)),
            _ActionPill(
              key: const ValueKey('macros:rand'),
              label: 'Rand',
              tip: 'Randomize knob macros (one undo step)',
              active: false,
              onTap: () => _randomize(doc, bindings, sources),
            ),
            SizedBox(width: Shape.s(4)),
            _ActionPill(
              key: const ValueKey('macros:vars'),
              label: vars.isEmpty ? 'Vars' : 'Vars (${vars.length})',
              tip: 'Macro Variations — save and recall knob snapshots',
              active: showVars && vars.isNotEmpty,
              onTap: () => doc.flag('macros.vars', !showVars),
            ),
            if (bindings.isNotEmpty && !mapMode) ...[
              SizedBox(width: Shape.s(4)),
              _ActionPill(
                key: const ValueKey('macros:ranges'),
                label: 'Ranges (${bindings.length})',
                tip: 'Edit exact Min / Max / Invert for mapped parameters',
                active: showRanges,
                onTap: () => doc.flag('macros.ranges', !showRanges),
              ),
            ],
            const Spacer(),
            maybeTip(
              context,
              count == 4 ? 'Show 8 channels' : 'Show 4 channels',
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

        // Compact Map mode strip: switch active slot and scroll freely to bind hidden FX.
        if (mapMode) ...[
          SizedBox(height: Shape.s(5)),
          ValueListenableBuilder<int?>(
            valueListenable: doc.macroDrag,
            builder: (context, active, _) {
              final slot = active ?? 1;
              final tone = macroSlotColor(slot);
              final slotName = names[slot] ?? 'Macro $slot';
              return Container(
                key: const ValueKey('macros:map-banner'),
                padding: EdgeInsets.symmetric(
                  horizontal: Shape.s(6),
                  vertical: Shape.s(4),
                ),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: Shape.round(4),
                  border: Border.all(color: tone.withValues(alpha: 0.40)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tone,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: Shape.s(5)),
                    Expanded(
                      child: Text(
                        'Mapping M$slot ($slotName) — click any param below',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.micro(tone),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],

        // Signal channel grid (4 across, 1 or 2 rows).
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
                    source: sources[s] ?? const MacroSource.knob(),
                    layers: layers,
                    mappedCount: bindings.where((b) => b.slot == s).length,
                    configOpen: _configSlot == s,
                    onToggleConfig: () => setState(
                      () => _configSlot = _configSlot == s ? null : s,
                    ),
                    onRename: (newName) {
                      final next = Map.of(names);
                      if (newName.isEmpty || newName == 'Macro $s') {
                        next.remove(s);
                      } else {
                        next[s] = newName;
                      }
                      doc.str('v_macro_names', writeMacroNames(next));
                    },
                  ),
                ),
              ],
            ],
          ),
        ],

        // Inline signal source configuration tray for the selected channel.
        if (_configSlot case final slot?) ...[
          SizedBox(height: Shape.s(5)),
          _SourceConfigTray(
            slot: slot,
            label: names[slot] ?? 'Macro $slot',
            source: sources[slot] ?? const MacroSource.knob(),
            layers: layers,
            onChange: (next) => doc.str(
              'v_macro_sources',
              setMacroSource(rawSources, slot, next),
            ),
            onClose: () => setState(() => _configSlot = null),
          ),
        ],

        // Macro Variations strip (snapshots).
        if (showVars) ...[
          SizedBox(height: Shape.s(5)),
          _VariationsStrip(
            vars: vars,
            onNew: () => _saveVariation(doc),
            onRecall: (v) => _recallVariation(doc, v),
            onDelete: (i) => _deleteVariation(doc, i),
          ),
        ],

        // Min / Max / Invert / Remove table (auto-shown in Map mode, or toggled via Ranges).
        if (bindings.isNotEmpty && (mapMode || showRanges)) ...[
          SizedBox(height: Shape.s(5)),
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

class _SourceConfigTray extends StatelessWidget {
  const _SourceConfigTray({
    required this.slot,
    required this.label,
    required this.source,
    required this.layers,
    required this.onChange,
    required this.onClose,
  });

  final int slot;
  final String label;
  final MacroSource source;
  final List<MacroLayerChoice> layers;
  final ValueChanged<MacroSource> onChange;
  final VoidCallback onClose;

  static const _kinds = [
    (MacroSourceKind.knob, 'Knob'),
    (MacroSourceKind.audio, 'Audio'),
    (MacroSourceKind.midi, 'MIDI'),
    (MacroSourceKind.layer, 'Layer'),
    (MacroSourceKind.wave, 'Wave'),
  ];

  static const _waves = [
    ('sine', 'Sine'),
    ('tri', 'Tri'),
    ('saw', 'Saw'),
    ('square', 'Sq'),
    ('noise', 'Noise'),
  ];

  static const _midiModes = [
    ('vel', 'Vel'),
    ('pitch', 'Pitch'),
    ('gate', 'Gate'),
  ];

  static const _layerProps = [
    ('x', 'X'),
    ('y', 'Y'),
    ('rotate', 'Rot'),
    ('scale_x', 'Scale'),
    ('opacity', 'Opac'),
  ];

  void _selectKind(MacroSourceKind kind) {
    if (kind == source.kind) return;
    final firstAudio = layers.where((l) => l.hasAudio).firstOrNull?.id ?? 0;
    final firstLayer = layers.firstOrNull?.id ?? 0;
    onChange(switch (kind) {
      MacroSourceKind.knob => const MacroSource.knob(),
      MacroSourceKind.wave => const MacroSource.wave(),
      MacroSourceKind.audio => MacroSource.audio(layerId: firstAudio),
      MacroSourceKind.midi => const MacroSource.midi(),
      MacroSourceKind.layer => MacroSource.layer(layerId: firstLayer),
    });
  }

  @override
  Widget build(BuildContext context) {
    final tone = macroSlotColor(slot);
    final audioLayers = layers.where((l) => l.hasAudio).toList();

    return Container(
      key: ValueKey('macros:tray:$slot'),
      padding: EdgeInsets.all(Shape.s(6)),
      decoration: BoxDecoration(
        color: InspectorSkin.well,
        borderRadius: Shape.round(6),
        border: Border.all(color: tone.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
              ),
              SizedBox(width: Shape.s(5)),
              Text('$label · Source', style: TextStyles.micro(Grey.g91)),
              const Spacer(),
              Pressable(
                key: ValueKey('macros:tray:close:$slot'),
                onTap: onClose,
                builder: (_, hot) => Text(
                  '×',
                  style: TextStyles.micro(hot ? Grey.g95 : Grey.g44),
                ),
              ),
            ],
          ),
          SizedBox(height: Shape.s(5)),
          // Source kind segmented chips.
          Row(
            children: [
              for (final (i, (k, name)) in _kinds.indexed) ...[
                if (i > 0) SizedBox(width: Shape.s(3)),
                Expanded(
                  child: Pressable(
                    key: ValueKey('macros:kind:${k.name}'),
                    onTap: () => _selectKind(k),
                    builder: (_, hot) => Container(
                      height: Shape.z(19),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: source.kind == k
                            ? tone.withValues(alpha: 0.22)
                            : (hot ? Grey.g26 : Grey.g15),
                        borderRadius: Shape.round(4),
                        border: Border.all(
                          color: source.kind == k
                              ? tone.withValues(alpha: 0.70)
                              : Grey.g26,
                        ),
                      ),
                      child: Text(
                        name,
                        style: TextStyles.micro(
                          source.kind == k ? tone : (hot ? Grey.g95 : Grey.g76),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: Shape.s(5)),
          // Source-specific parameters.
          switch (source.kind) {
            MacroSourceKind.knob => Text(
              'Drag the dial or keyframe it. Drag ○ onto any parameter below to connect.',
              style: TextStyles.micro(Grey.g56),
            ),
            MacroSourceKind.wave => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (final (i, (id, name)) in _waves.indexed) ...[
                      if (i > 0) SizedBox(width: Shape.s(3)),
                      Expanded(
                        child: _TinyToggle(
                          key: ValueKey('macros:wave:$id'),
                          label: name,
                          active:
                              (source.sub.isEmpty ? 'sine' : source.sub) == id,
                          tone: tone,
                          onTap: () => onChange(source.copyWith(sub: id)),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: Shape.s(4)),
                Row(
                  children: [
                    Text('Rate (Hz)', style: TextStyles.micro(Grey.g56)),
                    SizedBox(width: Shape.s(5)),
                    _RangeBox(
                      key: const ValueKey('macros:wave:hz'),
                      value: source.a,
                      onDone: (v) =>
                          onChange(source.copyWith(a: v.clamp(0.01, 60.0))),
                    ),
                    const Spacer(),
                    Text('Phase', style: TextStyles.micro(Grey.g56)),
                    SizedBox(width: Shape.s(5)),
                    _RangeBox(
                      key: const ValueKey('macros:wave:phase'),
                      value: source.b,
                      onDone: (v) => onChange(source.copyWith(b: v)),
                    ),
                  ],
                ),
              ],
            ),
            MacroSourceKind.audio => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TinyToggle(
                        key: const ValueKey('macros:audio:layer:0'),
                        label: 'Mix (All)',
                        active: source.ref <= 0,
                        tone: tone,
                        onTap: () => onChange(source.copyWith(ref: 0)),
                      ),
                      for (final l in audioLayers) ...[
                        SizedBox(width: Shape.s(3)),
                        _TinyToggle(
                          key: ValueKey('macros:audio:layer:${l.id}'),
                          label: l.name,
                          active: source.ref == l.id,
                          tone: tone,
                          onTap: () => onChange(source.copyWith(ref: l.id)),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: Shape.s(4)),
                Row(
                  children: [
                    Text('Gain', style: TextStyles.micro(Grey.g56)),
                    SizedBox(width: Shape.s(5)),
                    _RangeBox(
                      key: const ValueKey('macros:audio:gain'),
                      value: source.a,
                      onDone: (v) =>
                          onChange(source.copyWith(a: v.clamp(0.0, 20.0))),
                    ),
                    const Spacer(),
                    Text('Smooth (s)', style: TextStyles.micro(Grey.g56)),
                    SizedBox(width: Shape.s(5)),
                    _RangeBox(
                      key: const ValueKey('macros:audio:smooth'),
                      value: source.b,
                      onDone: (v) =>
                          onChange(source.copyWith(b: v.clamp(0.01, 0.5))),
                    ),
                  ],
                ),
              ],
            ),
            MacroSourceKind.midi => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (final (i, (id, name)) in _midiModes.indexed) ...[
                      if (i > 0) SizedBox(width: Shape.s(3)),
                      Expanded(
                        child: _TinyToggle(
                          key: ValueKey('macros:midi:$id'),
                          label: name,
                          active:
                              (source.sub.isEmpty ? 'vel' : source.sub) == id,
                          tone: tone,
                          onTap: () => onChange(source.copyWith(sub: id)),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: Shape.s(4)),
                Row(
                  children: [
                    Text('File', style: TextStyles.micro(Grey.g56)),
                    SizedBox(width: Shape.s(5)),
                    Expanded(
                      child: Container(
                        height: Shape.z(18),
                        padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: Grey.g15,
                          borderRadius: Shape.round(3),
                          border: Border.all(color: Grey.g26),
                        ),
                        child: TypedField(
                          key: const ValueKey('macros:midi:path'),
                          text: source.path,
                          standing: true,
                          escapes: true,
                          style: TextStyles.micro(Grey.g91),
                          cursor: Grey.g95,
                          backgroundCursor: Grey.g20,
                          selection: Role.selected.withValues(alpha: 0.4),
                          onDone: (said) {
                            if (said != null) {
                              onChange(source.copyWith(path: said.trim()));
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            MacroSourceKind.layer => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (layers.isEmpty)
                  Text(
                    'Add another layer to read its value.',
                    style: TextStyles.micro(Grey.g56),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final (i, l) in layers.indexed) ...[
                          if (i > 0) SizedBox(width: Shape.s(3)),
                          _TinyToggle(
                            key: ValueKey('macros:layer:${l.id}'),
                            label: l.name,
                            active: source.ref == l.id,
                            tone: tone,
                            onTap: () => onChange(source.copyWith(ref: l.id)),
                          ),
                        ],
                      ],
                    ),
                  ),
                SizedBox(height: Shape.s(4)),
                Row(
                  children: [
                    for (final (i, (prop, name)) in _layerProps.indexed) ...[
                      if (i > 0) SizedBox(width: Shape.s(3)),
                      Expanded(
                        child: _TinyToggle(
                          key: ValueKey('macros:lprop:$prop'),
                          label: name,
                          active: source.sub == prop,
                          tone: tone,
                          onTap: () => onChange(source.copyWith(sub: prop)),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: Shape.s(4)),
                Row(
                  children: [
                    Text('In Min', style: TextStyles.micro(Grey.g56)),
                    SizedBox(width: Shape.s(4)),
                    _RangeBox(
                      key: const ValueKey('macros:layer:min'),
                      value: source.a,
                      onDone: (v) => onChange(source.copyWith(a: v)),
                    ),
                    const Spacer(),
                    Text('In Max', style: TextStyles.micro(Grey.g56)),
                    SizedBox(width: Shape.s(4)),
                    _RangeBox(
                      key: const ValueKey('macros:layer:max'),
                      value: source.b,
                      onDone: (v) => onChange(source.copyWith(b: v)),
                    ),
                  ],
                ),
              ],
            ),
          },
        ],
      ),
    );
  }
}

class _TinyToggle extends StatelessWidget {
  const _TinyToggle({
    required this.label,
    required this.active,
    required this.tone,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool active;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (_, hot) => Container(
      height: Shape.z(18),
      padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? tone.withValues(alpha: 0.22)
            : (hot ? Grey.g26 : Grey.g15),
        borderRadius: Shape.round(3),
        border: Border.all(
          color: active ? tone.withValues(alpha: 0.65) : Grey.g26,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyles.micro(active ? tone : (hot ? Grey.g95 : Grey.g76)),
      ),
    ),
  );
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
        : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
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
