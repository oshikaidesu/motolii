// Reads an effect's WGSL uniform struct and says, field by field, what kind of value each one is, from what the field declares
// (`@ui`, `@range`, `@unit`...), its type and the shape of its range. Pure Dart: no Flutter.
import 'dart:math' as math;

enum WgslType { f32, i32, u32, boolean, vec2, vec3, vec4 }

/// How a value is shown and handled. Each look is a different picture of the value, not a different number box.
enum ParameterLook {
  /// No range known: a number you drag.
  scrub,

  /// A range: a number with a fill along its bottom.
  bar,

  /// A range that straddles zero: the fill grows out from the centre.
  bipolar,

  /// A share of a whole (0–100 %), drawn as a pie.
  percent,

  /// A direction or turn, drawn as a dial you turn.
  angle,

  /// A horizontal amount: dragged sideways.
  horizontal,

  /// A vertical amount: pictured as a level (the number still scrubs sideways like every other).
  vertical,

  /// A point (vec2): a pad you place it on, X dragged sideways, Y up and down.
  point,

  /// A size (vec2): width dragged sideways, height up and down, linkable.
  size,

  /// A small whole number: minus, the count, plus.
  stepper,

  /// One of a few named options.
  choice,

  /// On or off.
  toggle,

  /// A colour (vec3 / vec4).
  color,

  /// A random seed: a number with a re-roll.
  seed,
}

/// One field of the struct as written, with the attributes found on it.
class FieldDeclaration {
  const FieldDeclaration(
    this.name,
    this.type, {
    this.attrs = const {},
    this.advanced = false,
    this.fold,
  });
  final String name;
  final WgslType type;
  final Map<String, List<String>> attrs;
  final bool advanced;
  final String? fold;
}

/// What the Inspector needs to draw one parameter. Values are kept in display units (degrees, percent).
class Parameter {
  const Parameter({
    required this.id,
    required this.label,
    required this.look,
    this.min,
    this.max,
    this.def = 0,
    this.defY = 0,
    this.unit = '',
    this.dec = 0,
    this.options = const [],
    this.advanced = false,
    this.fold,
    this.open = false,
    this.validMin,
    this.validMax,
    this.weight,
  });
  final String id, label, unit;
  final ParameterLook look;
  final double? min, max;
  final double def, defY;
  final int dec;
  final List<String> options;
  final bool advanced;

  /// The name of the fold the field sits in, from `// @advanced(Name)`. Null means an unnamed fold, shown as Advanced.
  final String? fold;

  /// Whether [min] and [max] limit only scrubbing. The user can still type a value outside them.
  final bool open;

  /// How strongly this parameter alone changes the result, 0 to 10, from `@weight(7)`. Null means not weighted.
  final double? weight;

  /// The limits of a typed value, from `@valid(lo, hi)`, where they are wider than [min] and [max].
  /// They correspond to valid_min and valid_max of After Effects' PF_FloatSliderDef.
  final double? validMin, validMax;

  /// Where a typed, stepped or turned number may go, after After Effects' PF_FloatSliderDef (valid_min and valid_max, apart
  /// from the slider's ends) and Houdini's non-strict range (`@open`: free, except below a minimum of zero or more).
  /// Every control that sets this parameter ends here, so none keeps a limit of its own.
  double get typedMin => open && (min ?? 0) < 0
      ? double.negativeInfinity
      : validMin ?? min ?? double.negativeInfinity;
  double get typedMax =>
      open ? double.infinity : validMax ?? max ?? double.infinity;
  double typed(double v) => math.min(typedMax, math.max(typedMin, v));

  /// A dragged number: it stops at the slider's ends, or where it already is when it lies beyond them. [past] (the card's
  /// "go past range ends", or Option held) and an angle drag as far as a typed number may go.
  double scrubbed(double v, double start, {required bool past}) =>
      look == ParameterLook.angle ||
          past ||
          (!open && validMin == null && validMax == null)
      ? typed(v)
      : math.min(
          math.max(max ?? double.infinity, start),
          math.max(math.min(min ?? double.negativeInfinity, start), v),
        );

  bool get bounded => min != null && max != null;
  double get step => dec == 0 ? 1 : math.pow(10, -dec).toDouble();
  double get perPx =>
      bounded ? (max! - min!) / 200 : (dec == 0 ? 1 : step * 10);
}

final _structRe = RegExp(r'struct\s+\w+\s*\{([\s\S]*?)\}');
final _fieldRe = RegExp(
  r'^\s*(?:@\w+(?:\([^)]*\))?\s*)*(\w+)\s*:\s*([\w<>]+)\s*,?\s*(?://(.*))?$',
);
final _attrRe = RegExp(r'@(\w+)(?:\(([^)]*)\))?');

WgslType? _type(String t) => switch (t) {
  'f32' || 'f16' => WgslType.f32,
  'i32' => WgslType.i32,
  'u32' => WgslType.u32,
  'bool' => WgslType.boolean,
  'vec2f' || 'vec2<f32>' || 'vec2h' => WgslType.vec2,
  'vec3f' || 'vec3<f32>' || 'vec3h' => WgslType.vec3,
  'vec4f' || 'vec4<f32>' || 'vec4h' => WgslType.vec4,
  _ => null,
};

/// The first struct in [src], one [FieldDeclaration] per field. Attributes come from `///` lines above a field and `//` after it,
/// e.g. `@range(0, 200) @unit(px) @enum(Low, Med, High) @default(12) @toggle`. A `// @advanced` line marks every field after it;
/// `// @advanced(Each copy)` names that fold by what it holds.
List<FieldDeclaration> parseWgsl(String src) {
  final body = _structRe.firstMatch(src)?.group(1);
  if (body == null) return const [];
  final out = <FieldDeclaration>[];
  var pending = <String, List<String>>{};
  var advanced = false;
  String? fold;
  Map<String, List<String>> attrs(String s) => {
    for (final m in _attrRe.allMatches(s))
      m.group(1)!: (m.group(2) ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
  };
  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('//')) {
      final a = attrs(line);
      if (a.containsKey('advanced') &&
          a.length == 1 &&
          !line.startsWith('///')) {
        advanced = true;
        fold = a['advanced']!.firstOrNull;
      } else {
        pending.addAll(a);
      }
      continue;
    }
    final m = _fieldRe.firstMatch(line);
    final t = m == null ? null : _type(m.group(2)!);
    if (m == null || t == null) continue;
    final all = {...pending, ...attrs(line), ...attrs(m.group(3) ?? '')};
    out.add(
      FieldDeclaration(
        m.group(1)!,
        t,
        attrs: all,
        advanced: advanced || all.containsKey('advanced'),
        fold: fold,
      ),
    );
    pending = {};
  }
  return out;
}

/// `blurRadius`, `blur_radius` → [blur, radius]; short forms spelled out.
List<String> paramWords(String name) {
  final spaced = name.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (m) => '${m[1]}_${m[2]}',
  );
  return [
    for (final w
        in spaced
            .toLowerCase()
            .split(RegExp(r'[_\s]+'))
            .where((w) => w.isNotEmpty))
      ...(_long[w] ?? [w]),
  ];
}

const _long = {
  'thr': ['threshold'],
  'amt': ['amount'],
  'freq': ['frequency'],
  'oct': ['octaves'],
  'lac': ['lacunarity'],
  'exp': ['exposure'],
  'con': ['contrast'],
  'sat': ['saturation'],
  'temp': ['temperature'],
  'gam': ['gamma'],
  'rad': ['radius'],
  'str': ['strength'],
  'col': ['colour'],
  'color': ['colour'],
  'pos': ['position'],
  'rot': ['rotation'],
  'dx': ['offset', 'x'],
  'dy': ['offset', 'y'],
  'tintc': ['tint'],
  'clampc': ['clamp'],
  'rough': ['roughness'],
  'pin': ['pin', 'edges'],
  'add': ['additive'],
};

String paramLabel(List<String> w) {
  final s = w.map((e) => e.length == 1 ? e.toUpperCase() : e).join(' ');
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

bool _any(List<String> w, Set<String> set) => w.any(set.contains);

const _angleW = {
  'angle',
  'rotation',
  'hue',
  'phase',
  'heading',
  'direction',
  'twist',
  'spin',
  'theta',
  'turn',
};

/// Whether a parameter's label names an angle.
///
/// It accepts the words [infer] treats as angles plus the ones AviUtl scripts use (角度, 回転).
/// A label for how fast something turns, such as 回転速度 or spin speed, is not an angle: it is a slider, as in After Effects.
bool angleLabel(String label) =>
    (_any(paramWords(label), _angleW) ||
        RegExp('角度|回転|色相|向き|方向').hasMatch(label)) &&
    !RegExp('速|speed|rate', caseSensitive: false).hasMatch(label);

double? _num(String? s) => s == null ? null : double.tryParse(s);

/// What one field is. Explicit attributes win; then the type; then the unit; then the shape of the range. A name decides nothing
/// but the label.
Parameter infer(FieldDeclaration d) {
  final w = paramWords(d.name), a = d.attrs;
  final range = a['range'];
  var min = _num(range?.elementAtOrNull(0)),
      max = _num(range?.elementAtOrNull(1));
  var unit = a['unit']?.firstOrNull ?? '';
  final def = a['default'];
  var d0 = _num(def?.elementAtOrNull(0)) ?? 0,
      d1 = _num(def?.elementAtOrNull(1)) ?? d0;
  final lab = a['label']?.join(', ') ?? paramLabel(w);
  final ui = a['ui']?.firstOrNull;
  final whole = d.type == WgslType.i32 || d.type == WgslType.u32;
  int dec(double? lo, double? hi) {
    if (whole) return 0;
    if (a['step']?.firstOrNull case final s?) {
      return s.contains('.') ? s.split('.').last.length : 0;
    }
    // Fixed decimal places per unit: seconds and multipliers get one, pixels and degrees get none.
    if (unit == 's' || unit == '×') return 1;
    if (unit == 'px' || unit == '°') return 0;
    final span = lo != null && hi != null ? hi - lo : 100;
    return span <= 4 ? 2 : (span <= 40 ? 1 : 0);
  }

  Parameter p(
    ParameterLook look, {
    double? lo,
    double? hi,
    double scale = 1,
    String? u,
    List<String> opts = const [],
  }) {
    final l = lo ?? min, h = hi ?? max;
    return Parameter(
      id: d.name,
      label: lab,
      look: look,
      min: l,
      max: h,
      def: d0 / scale,
      defY: d1 / scale,
      unit: u ?? unit,
      dec: scale == 1
          ? dec(l, h)
          : (look == ParameterLook.percent || look == ParameterLook.angle
                ? 0
                : 1),
      options: opts,
      advanced: d.advanced,
      open: a.containsKey('open'),
      validMin: _num(a['valid']?.elementAtOrNull(0)),
      validMax: _num(a['valid']?.elementAtOrNull(1)),
      fold: d.fold,
      weight: _num(a['weight']?.firstOrNull),
    );
  }

  if (a['enum'] case final o? when o.isNotEmpty) {
    return p(ParameterLook.choice, lo: 0, hi: o.length - 1.0, opts: o);
  }
  if (ui != null) {
    final look = ParameterLook.values.where((l) => l.name == ui).firstOrNull;
    if (look != null) return p(look);
  }
  if (d.type == WgslType.boolean || a.containsKey('toggle')) {
    return p(ParameterLook.toggle, lo: 0, hi: 1);
  }
  if (d.type == WgslType.vec3 || d.type == WgslType.vec4) {
    return p(ParameterLook.color);
  }
  if (d.type == WgslType.vec2) {
    return p(ParameterLook.point, lo: min ?? -1, hi: max ?? 1);
  }
  final rad =
      unit == 'rad' ||
      (min != null &&
          max != null &&
          (max - math.pi).abs() < .01 &&
          (min + math.pi).abs() < .01);
  if (unit == '°' || unit == 'deg' || rad) {
    final s = rad ? math.pi / 180 : 1.0;
    return p(
      ParameterLook.angle,
      lo: min == null ? -180 : min / s,
      hi: max == null ? 180 : max / s,
      scale: s,
      u: '°',
    );
  }
  if (unit == '%') {
    return p(ParameterLook.percent, lo: min ?? 0, hi: max ?? 100);
  }
  if (whole && min != null && max != null && max - min <= 12) {
    return p(ParameterLook.stepper);
  }
  if (min != null && max != null) {
    if (min < 0 && max > 0 && (min.abs() - max).abs() <= max * .5) {
      return p(ParameterLook.bipolar);
    }
    return p(ParameterLook.bar);
  }
  return p(ParameterLook.scrub);
}
