// Universal Signal Macro data model: parses and serializes `macro_map`,
// `macro_sources`, `macro_names`, and `macro_vars` stored in the document.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';

/// Maximum number of signal macro channels on a layer.
const int macroSlotCount = 8;

/// Input source driving a macro channel's normalized `0..1` signal.
enum MacroSourceKind { knob, audio, midi, layer, wave }

/// Parsed descriptor for one channel in `macro_sources`.
class MacroSource {
  const MacroSource({
    this.kind = MacroSourceKind.knob,
    this.sub = '',
    this.path = '',
    this.ref = 0,
    this.a = 1.0,
    this.b = 0.0,
  });

  const MacroSource.knob() : this(kind: MacroSourceKind.knob);

  const MacroSource.wave({
    String shape = 'sine',
    double hz = 1.0,
    double phase = 0.0,
  }) : this(kind: MacroSourceKind.wave, sub: shape, a: hz, b: phase);

  const MacroSource.audio({
    int layerId = 0,
    double gain = 1.5,
    double smooth = 0.05,
  }) : this(kind: MacroSourceKind.audio, ref: layerId, a: gain, b: smooth);

  const MacroSource.midi({
    String mode = 'vel',
    int channel = -1,
    String file = '',
  }) : this(kind: MacroSourceKind.midi, sub: mode, ref: channel, path: file);

  const MacroSource.layer({
    int layerId = 0,
    String prop = 'rotate',
    double inMin = -180.0,
    double inMax = 180.0,
  }) : this(
         kind: MacroSourceKind.layer,
         ref: layerId,
         sub: prop,
         a: inMin,
         b: inMax,
       );

  final MacroSourceKind kind;
  final String sub;
  final String path;
  final int ref;
  final double a;
  final double b;

  MacroSource copyWith({
    MacroSourceKind? kind,
    String? sub,
    String? path,
    int? ref,
    double? a,
    double? b,
  }) => MacroSource(
    kind: kind ?? this.kind,
    sub: sub ?? this.sub,
    path: path ?? this.path,
    ref: ref ?? this.ref,
    a: a ?? this.a,
    b: b ?? this.b,
  );

  String get badgeLabel => switch (kind) {
    MacroSourceKind.knob => 'Knob',
    MacroSourceKind.audio => 'Audio',
    MacroSourceKind.midi => 'MIDI',
    MacroSourceKind.layer => 'Layer',
    MacroSourceKind.wave => 'Wave',
  };

  /// Compact 1-line description shown under the live meter on non-knob slots.
  String shortSummary(List<MacroLayerChoice> layers) => switch (kind) {
    MacroSourceKind.knob => '',
    MacroSourceKind.wave => '${_waveName(sub)} ${_fmt(a)}Hz',
    MacroSourceKind.audio =>
      ref <= 0 ? 'Mix ×${_fmt(a)}' : '${_layerLabel(layers, ref)} ×${_fmt(a)}',
    MacroSourceKind.midi => switch (sub) {
      'pitch' => 'Pitch',
      'gate' => 'Gate',
      _ => 'Vel',
    },
    MacroSourceKind.layer =>
      ref <= 0 ? sub : '${_layerLabel(layers, ref)} · $sub',
  };
}

String _waveName(String shape) => switch (shape) {
  'tri' => 'Tri',
  'saw' => 'Saw',
  'square' => 'Sq',
  'noise' => 'Noise',
  _ => 'Sine',
};

String _layerLabel(List<MacroLayerChoice> layers, int id) {
  for (final l in layers) {
    if (l.id == id) return l.name;
  }
  return 'L$id';
}

/// Parses `macro_sources` into per-slot source descriptors (omitted slots default to `knob`).
Map<int, MacroSource> parseMacroSources(String raw) {
  if (raw.isEmpty) return const {};
  final out = <int, MacroSource>{};
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 2) continue;
    final slot = int.tryParse(parts[0]);
    if (slot == null || slot < 1 || slot > macroSlotCount) continue;
    switch (parts[1]) {
      case 'wave':
        final shape = parts.length > 2 ? parts[2] : 'sine';
        final hz = parts.length > 3 ? (double.tryParse(parts[3]) ?? 1.0) : 1.0;
        final phase = parts.length > 4
            ? (double.tryParse(parts[4]) ?? 0.0)
            : 0.0;
        out[slot] = MacroSource.wave(shape: shape, hz: hz, phase: phase);
      case 'audio':
        final ref = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
        final gain = parts.length > 3
            ? (double.tryParse(parts[3]) ?? 1.5)
            : 1.5;
        final smooth = parts.length > 4
            ? (double.tryParse(parts[4]) ?? 0.05)
            : 0.05;
        out[slot] = MacroSource.audio(layerId: ref, gain: gain, smooth: smooth);
      case 'midi':
        final mode = parts.length > 2 ? parts[2] : 'vel';
        final ch = parts.length > 3 ? (int.tryParse(parts[3]) ?? -1) : -1;
        // Preserve spaces in the trailing file path after the 4th token.
        var path = '';
        if (parts.length > 4) {
          final m = RegExp(r'^\S+\s+\S+\s+\S+\s+\S+\s+(.*)$')
              .firstMatch(trimmed);
          path = m?.group(1)?.trim() ?? parts.sublist(4).join(' ');
        }
        out[slot] = MacroSource.midi(mode: mode, channel: ch, file: path);
      case 'layer':
        final ref = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
        final prop = parts.length > 3 ? parts[3] : 'rotate';
        final lo = parts.length > 4 ? (double.tryParse(parts[4]) ?? 0.0) : 0.0;
        final hi = parts.length > 5 ? (double.tryParse(parts[5]) ?? 1.0) : 1.0;
        out[slot] = MacroSource.layer(
          layerId: ref,
          prop: prop,
          inMin: lo,
          inMax: hi,
        );
      default:
        out.remove(slot);
    }
  }
  return out;
}

/// Serializes non-default macro sources back to `macro_sources` format.
String writeMacroSources(Map<int, MacroSource> sources) => [
  for (var s = 1; s <= macroSlotCount; s++)
    if (sources[s] case final src? when src.kind != MacroSourceKind.knob)
      switch (src.kind) {
        MacroSourceKind.wave =>
          '$s wave ${src.sub.isEmpty ? 'sine' : src.sub} ${_fmt(src.a)} ${_fmt(src.b)}',
        MacroSourceKind.audio =>
          '$s audio ${src.ref} ${_fmt(src.a)} ${_fmt(src.b)}',
        MacroSourceKind.midi =>
          '$s midi ${src.sub.isEmpty ? 'vel' : src.sub} ${src.ref}'
              '${src.path.trim().isEmpty ? '' : ' ${src.path.trim()}'}',
        MacroSourceKind.layer =>
          '$s layer ${src.ref} ${src.sub.isEmpty ? 'rotate' : src.sub} ${_fmt(src.a)} ${_fmt(src.b)}',
        MacroSourceKind.knob => '',
      },
].where((l) => l.isNotEmpty).join('\n');

/// Updates one channel's signal source in `macro_sources`.
String setMacroSource(String raw, int slot, MacroSource source) {
  final next = Map<int, MacroSource>.of(parseMacroSources(raw));
  if (source.kind == MacroSourceKind.knob) {
    next.remove(slot);
  } else {
    next[slot] = source;
  }
  return writeMacroSources(next);
}

/// One binding in `macro_map`: macro [slot] (1..8) drives document property [prop]
/// linearly from [min] (at 0%) to [max] (at 100%) in document units.
typedef MacroBinding = ({int slot, String prop, double min, double max});

/// One saved snapshot of all macro knob values (0..100 display percent),
/// matching Ableton Live's Macro Variations.
typedef MacroVariation = ({String name, List<double> values});

/// Parses `macro_map` ("slot prop min max" per line).
List<MacroBinding> parseMacroMap(String raw) {
  if (raw.isEmpty) return const [];
  final out = <MacroBinding>[];
  final seen = <String>{};
  for (final line in raw.split('\n')) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 4) continue;
    final slot = int.tryParse(parts[0]);
    final prop = parts[1];
    final min = double.tryParse(parts[2]);
    final max = double.tryParse(parts[3]);
    if (slot == null || slot < 1 || slot > macroSlotCount) continue;
    if (prop.isEmpty || prop.startsWith('macro_')) continue;
    if (min == null || max == null) continue;
    if (seen.add(prop)) {
      out.add((slot: slot, prop: prop, min: min, max: max));
    }
  }
  return out;
}

/// Serializes macro bindings back into `macro_map` format.
String writeMacroMap(List<MacroBinding> bindings) => [
  for (final b in bindings) '${b.slot} ${b.prop} ${_fmt(b.min)} ${_fmt(b.max)}',
].join('\n');

/// Adds or replaces the macro binding for [prop] (one macro drives each property).
String upsertMacroBinding(String raw, MacroBinding binding) {
  final list = parseMacroMap(raw).where((b) => b.prop != binding.prop).toList()
    ..add(binding);
  return writeMacroMap(list);
}

/// Removes any macro binding for [prop].
String removeMacroBinding(String raw, String prop) =>
    writeMacroMap(parseMacroMap(raw).where((b) => b.prop != prop).toList());

/// Swaps min and max of [prop]'s binding (Invert Range).
String invertMacroBinding(String raw, String prop) => writeMacroMap([
  for (final b in parseMacroMap(raw))
    b.prop == prop ? (slot: b.slot, prop: b.prop, min: b.max, max: b.min) : b,
]);

/// Updates min/max of [prop]'s binding.
String updateMacroRange(String raw, String prop, double min, double max) =>
    writeMacroMap([
      for (final b in parseMacroMap(raw))
        b.prop == prop ? (slot: b.slot, prop: b.prop, min: min, max: max) : b,
    ]);

/// Finds the binding driving document property [prop], or null.
MacroBinding? macroBindingOf(String raw, String prop) {
  for (final b in parseMacroMap(raw)) {
    if (b.prop == prop) return b;
  }
  return null;
}

/// Picks the first unused slot (1..8), or 1 when all 8 already have mappings.
int nextFreeMacroSlot(String raw) {
  final used = {for (final b in parseMacroMap(raw)) b.slot};
  for (var s = 1; s <= macroSlotCount; s++) {
    if (!used.contains(s)) return s;
  }
  return 1;
}

/// Parses custom macro channel names (`slot\tname` per line).
Map<int, String> parseMacroNames(String raw) {
  final out = <int, String>{};
  for (final line in raw.split('\n')) {
    final tab = line.indexOf('\t');
    if (tab <= 0) continue;
    final slot = int.tryParse(line.substring(0, tab).trim());
    final name = line.substring(tab + 1).trim();
    if (slot != null &&
        slot >= 1 &&
        slot <= macroSlotCount &&
        name.isNotEmpty) {
      out[slot] = name;
    }
  }
  return out;
}

/// Serializes custom macro channel names back to `macro_names`.
String writeMacroNames(Map<int, String> names) => [
  for (var s = 1; s <= macroSlotCount; s++)
    if (names[s] case final n? when n.trim().isNotEmpty)
      '$s\t${n.trim().replaceAll(RegExp(r'[\t\r\n]+'), ' ')}',
].join('\n');

/// Parses saved Macro Variations (`name\tv1,v2,...,v8` per line, values in 0..100).
List<MacroVariation> parseMacroVars(String raw) {
  if (raw.isEmpty) return const [];
  final out = <MacroVariation>[];
  for (final line in raw.split('\n')) {
    final tab = line.indexOf('\t');
    if (tab <= 0) continue;
    final name = line.substring(0, tab).trim();
    if (name.isEmpty) continue;
    final vals = [
      for (final tok in line.substring(tab + 1).split(','))
        (double.tryParse(tok.trim()) ?? 0.0).clamp(0.0, 100.0),
    ];
    while (vals.length < macroSlotCount) {
      vals.add(0.0);
    }
    out.add((name: name, values: vals.sublist(0, macroSlotCount)));
  }
  return out;
}

/// Serializes Macro Variations back to `macro_vars`.
String writeMacroVars(List<MacroVariation> vars) => [
  for (final v in vars)
    '${v.name.replaceAll(RegExp(r'[\t\r\n]+'), ' ')}\t'
        '${[for (var i = 0; i < macroSlotCount; i++) _fmt(i < v.values.length ? v.values[i] : 0.0)].join(',')}',
].join('\n');

/// Converts document-unit value [docVal] to inspector display value using [doc]'s scale action.
double macroToShown(InspectorValues doc, String prop, double docVal) {
  final (k, f) = doc.actions.propScale?.call(prop) ?? (1.0, 0.0);
  return docVal * k + f;
}

/// Converts inspector display value [shownVal] to document-unit value using [doc]'s scale action.
double macroToDoc(InspectorValues doc, String prop, double shownVal) {
  final (k, f) = doc.actions.propScale?.call(prop) ?? (1.0, 0.0);
  return k == 0 ? shownVal : (shownVal - f) / k;
}

/// Evaluates the live displayed value of a macro-bound parameter from its signal (0..100%).
double evaluateBoundShown(InspectorValues doc, MacroBinding binding) {
  final m = ((doc.get('v_macro_${binding.slot}') ?? 0.0) / 100.0).clamp(
    0.0,
    1.0,
  );
  final docVal = binding.min + (binding.max - binding.min) * m;
  return macroToShown(doc, binding.prop, docVal);
}

/// Looks up the declaring card and [Parameter] for document property [prop], or null.
({CardDeclaration card, Parameter param})? findCardParam(
  InspectorValues doc,
  String prop,
) {
  for (final c in doc.cards) {
    for (final p in c.params) {
      if (p.id == prop) return (card: c, param: p);
    }
  }
  return null;
}

/// Default document-unit `(min, max)` when mapping [prop] onto a macro channel.
(double, double) defaultMacroRange(InspectorValues doc, String prop) {
  final found = findCardParam(doc, prop);
  final p = found?.param;
  if (p != null && p.min != null && p.max != null && p.max! > p.min!) {
    return (macroToDoc(doc, prop, p.min!), macroToDoc(doc, prop, p.max!));
  }
  final cur = doc.get('v_$prop') ?? p?.def ?? 0.0;
  final span = cur.abs() > 1 ? cur.abs() : 100.0;
  return (macroToDoc(doc, prop, cur - span), macroToDoc(doc, prop, cur + span));
}

/// Distinct semantic tint per macro slot, derived exclusively from skin tokens.
Color macroSlotColor(int slot) => switch ((slot - 1) % 4) {
  0 => Accent.fill,
  1 => InspectorSkin.toneBlend,
  2 => InspectorSkin.tonePlace,
  _ => InspectorSkin.toneLayout,
};

String _fmt(double v) {
  if (v == v.roundToDouble() && v.abs() < 1e9) return '${v.round()}';
  return v.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
}
