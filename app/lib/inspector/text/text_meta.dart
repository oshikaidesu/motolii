// OpenType metadata parser and feature-tag utilities for the Text card.
import 'package:motolii/widgets/font_files.dart' show FontAxis;

/// Parsed result of `motolii_font_meta`: supported GSUB/GPOS tags and visible fvar axes.
typedef FontMeta = ({Set<String> features, List<FontAxis> axes});

const FontMeta emptyFontMeta = (features: <String>{}, axes: <FontAxis>[]);

/// Parses the plain-text report emitted by `motolii_font_meta` (see engine/community/css/text.rs).
FontMeta parseFontMeta(String raw) {
  if (raw.isEmpty) return emptyFontMeta;
  final features = <String>{};
  final axes = <FontAxis>[];
  for (final line in raw.split('\n')) {
    if (line.startsWith('features:')) {
      for (final tag in line.substring(9).trim().split(RegExp(r'\s+'))) {
        if (tag.length == 4) features.add(tag);
      }
    } else if (line.startsWith('axis:')) {
      final parts = line.substring(5).trim().split('\t');
      if (parts.length >= 5) {
        final min = double.tryParse(parts[2]);
        final def = double.tryParse(parts[3]);
        final max = double.tryParse(parts[4]);
        if (min != null && def != null && max != null) {
          axes.add((
            tag: parts[0],
            name: parts[1].isEmpty ? parts[0] : parts[1],
            min: min,
            def: def,
            max: max,
          ));
        }
      }
    }
  }
  return (features: features, axes: axes);
}

/// Metadata for a curated OpenType feature: human label, specimen text, and
/// contrasting off-state tag so users can visually compare OFF vs ON in the
/// active font without memorizing 4-letter codes.
typedef OtFeatureSpec = ({String name, String sample, String? contrastOff});

/// Curated OpenType features shown with live before/after glyph comparison when
/// the font supports them. Metrics features (`palt`, `vpal`, `halt`, `vhal`,
/// `kern`, `vkrn`, `vert`, `vrt2`) are driven by the notebook paper/ruler above.
const otFeatureSpecs = <String, OtFeatureSpec>{
  'liga': (name: 'Ligatures', sample: 'fi', contrastOff: null),
  'dlig': (name: 'Discretionary lig.', sample: 'st', contrastOff: null),
  'tnum': (name: 'Tabular figures', sample: '10', contrastOff: 'pnum'),
  'pnum': (name: 'Proportional figures', sample: '10', contrastOff: 'tnum'),
  'onum': (name: 'Oldstyle figures', sample: '123', contrastOff: 'lnum'),
  'zero': (name: 'Slashed zero', sample: '0', contrastOff: null),
  'smcp': (name: 'Small caps', sample: 'Aa', contrastOff: null),
  'swsh': (name: 'Swash', sample: 'Q', contrastOff: null),
  'fwid': (name: 'Full-width', sample: 'A1', contrastOff: 'hwid'),
  'hwid': (name: 'Half-width', sample: 'A1', contrastOff: 'fwid'),
  'jp04': (name: 'JIS2004 forms', sample: '辻', contrastOff: 'jp90'),
  'jp90': (name: 'JIS90 forms', sample: '辻', contrastOff: 'jp04'),
  'ruby': (name: 'Ruby forms', sample: 'あ', contrastOff: null),
  'ss01': (name: 'Style set 1', sample: 'Aa1', contrastOff: null),
  'ss02': (name: 'Style set 2', sample: 'Aa1', contrastOff: null),
  'ss03': (name: 'Style set 3', sample: 'Aa1', contrastOff: null),
  'ss04': (name: 'Style set 4', sample: 'Aa1', contrastOff: null),
};

/// Parses a `v_font_features` string (space/comma separated tokens or CSS `'tag' 1`) into
/// an ordered list of normalized entries (`tag`, `-tag`, or `tag=N`).
List<String> parseFeatureTokens(String raw) {
  final out = <String>[];
  final seen = <String>{};
  for (final part in raw.split(',')) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    final cssMatch = RegExp(
      r"""^['"]([A-Za-z0-9]{4})['"]\s*(?:(\d+|on|off))?$""",
    ).firstMatch(trimmed);
    if (cssMatch != null) {
      final tag = cssMatch[1]!;
      final val = cssMatch[2] ?? '1';
      final token = (val == '0' || val == 'off')
          ? '-$tag'
          : (val == '1' || val == 'on' ? tag : '$tag=$val');
      if (seen.add(tag)) out.add(token);
      continue;
    }
    for (final tok in trimmed.split(RegExp(r'\s+'))) {
      final clean = tok.replaceAll(RegExp(r'''['"]'''), '').trim();
      if (clean.isEmpty) continue;
      final key = featureTagOf(clean);
      if (key.length == 4 && seen.add(key)) out.add(clean);
    }
  }
  return out;
}

/// Extracts the 4-character OpenType tag from a normalized token (`tnum`, `-liga`, `ss01=2`).
String featureTagOf(String token) {
  var s = token;
  if (s.startsWith('-') || s.startsWith('+')) s = s.substring(1);
  final eq = s.indexOf('=');
  if (eq > 0) s = s.substring(0, eq);
  return s;
}

/// Toggles [tag] in [raw] while preserving all other user-supplied tokens.
String toggleFeatureToken(String raw, String tag) {
  final tokens = parseFeatureTokens(raw);
  final idx = tokens.indexWhere((t) => featureTagOf(t) == tag);
  if (idx >= 0) {
    tokens.removeAt(idx);
  } else {
    tokens.add(tag);
  }
  return tokens.join(' ');
}

/// Adds or replaces a user-entered feature token (`ss08`, `-kern`, `cv01=2`) in [raw].
String addFeatureToken(String raw, String entry) {
  final parsed = parseFeatureTokens(entry);
  if (parsed.isEmpty) return raw;
  final tokens = parseFeatureTokens(raw);
  for (final p in parsed) {
    final tag = featureTagOf(p);
    tokens.removeWhere((t) => featureTagOf(t) == tag);
    tokens.add(p);
  }
  return tokens.join(' ');
}
