// OpenType metadata parser and feature-tag utilities for the Text card.
import 'package:motolii/widgets/font_files.dart' show FontAxis;

/// Parsed result of `motolii_font_meta`: supported GSUB/GPOS tags, optional font-provided
/// UI names (`StylisticSet`/`CharacterVariant`), and visible fvar axes.
typedef FontMeta = ({
  Set<String> features,
  Map<String, String> featureNames,
  List<FontAxis> axes,
});

const FontMeta emptyFontMeta = (
  features: <String>{},
  featureNames: <String, String>{},
  axes: <FontAxis>[],
);

/// Parses the plain-text report emitted by `motolii_font_meta` (see engine/community/css/text.rs).
FontMeta parseFontMeta(String raw) {
  if (raw.isEmpty) return emptyFontMeta;
  final features = <String>{};
  final featureNames = <String, String>{};
  final axes = <FontAxis>[];
  for (final line in raw.split('\n')) {
    if (line.startsWith('features:')) {
      for (final tag in line.substring(9).trim().split(RegExp(r'\s+'))) {
        if (tag.length == 4) features.add(tag);
      }
    } else if (line.startsWith('feature:')) {
      final parts = line.substring(8).trim().split('\t');
      if (parts.length >= 2 && parts[0].length == 4 && parts[1].isNotEmpty) {
        features.add(parts[0]);
        featureNames[parts[0]] = parts[1];
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
  return (features: features, featureNames: featureNames, axes: axes);
}

/// Metadata for an OpenType feature: human label, specimen text, and optional
/// contrasting off-state tag for live OFF → ON glyph comparison.
typedef OtFeatureSpec = ({String name, String sample, String? contrastOff});

/// Internal shaping tags and metrics/orientation tags already driven by the
/// notebook paper & ruler above (still enterable manually via `+ Add tag`).
const otInternalFeatures = <String>{
  'aalt',
  'abvf',
  'abvm',
  'abvs',
  'akhn',
  'blwf',
  'blwm',
  'blws',
  'ccmp',
  'cfar',
  'cjct',
  'curs',
  'dist',
  'dtls',
  'fin2',
  'fin3',
  'fina',
  'flac',
  'half',
  'haln',
  'halt',
  'init',
  'isol',
  'kern',
  'ljmo',
  'locl',
  'ltra',
  'ltrm',
  'mark',
  'med2',
  'medi',
  'mkmk',
  'nukt',
  'palt',
  'pref',
  'pres',
  'pstf',
  'psts',
  'rclt',
  'rkrf',
  'rlig',
  'rphf',
  'rtla',
  'rtlm',
  'rvrn',
  'size',
  'ssty',
  'tjmo',
  'vert',
  'vhal',
  'vjmo',
  'vkrn',
  'vpal',
  'vrt2',
  'vrtr',
};

/// Curated specimens & readable names for well-known OpenType tags. Every other
/// non-internal feature a font declares is still exposed dynamically below.
const otFeatureSpecs = <String, OtFeatureSpec>{
  'liga': (name: 'Ligatures', sample: 'fi', contrastOff: null),
  'dlig': (name: 'Discretionary lig.', sample: 'st', contrastOff: null),
  'calt': (name: 'Contextual alt.', sample: '->/', contrastOff: null),
  'salt': (name: 'Stylistic alt.', sample: 'Aa', contrastOff: null),
  'tnum': (name: 'Tabular figures', sample: '10', contrastOff: 'pnum'),
  'pnum': (name: 'Proportional figures', sample: '10', contrastOff: 'tnum'),
  'lnum': (name: 'Lining figures', sample: '123', contrastOff: 'onum'),
  'onum': (name: 'Oldstyle figures', sample: '123', contrastOff: 'lnum'),
  'zero': (name: 'Slashed zero', sample: '0', contrastOff: null),
  'frac': (name: 'Fractions', sample: '1/2', contrastOff: null),
  'sups': (name: 'Superscript', sample: 'x2', contrastOff: null),
  'subs': (name: 'Subscript', sample: 'H2', contrastOff: null),
  'ordn': (name: 'Ordinals', sample: '1a', contrastOff: null),
  'smcp': (name: 'Small caps', sample: 'Aa', contrastOff: null),
  'c2sc': (name: 'Caps to small caps', sample: 'AB', contrastOff: null),
  'pcap': (name: 'Petite caps', sample: 'Aa', contrastOff: null),
  'case': (name: 'Case-sensitive', sample: '(A)', contrastOff: null),
  'titl': (name: 'Titling', sample: 'Ab', contrastOff: null),
  'swsh': (name: 'Swash', sample: 'Q', contrastOff: null),
  'hist': (name: 'Historical forms', sample: 'st', contrastOff: null),
  'fwid': (name: 'Full-width', sample: 'A1', contrastOff: 'hwid'),
  'hwid': (name: 'Half-width', sample: 'A1', contrastOff: 'fwid'),
  'qwid': (name: 'Quarter-width', sample: '12', contrastOff: null),
  'twid': (name: 'Third-width', sample: '12', contrastOff: null),
  'pwid': (name: 'Proportional width', sample: 'A1', contrastOff: 'fwid'),
  'jp04': (name: 'JIS2004 forms', sample: '辻', contrastOff: 'jp90'),
  'jp90': (name: 'JIS90 forms', sample: '辻', contrastOff: 'jp04'),
  'jp83': (name: 'JIS83 forms', sample: '辻', contrastOff: 'jp04'),
  'jp78': (name: 'JIS78 forms', sample: '辻', contrastOff: 'jp04'),
  'trad': (name: 'Traditional forms', sample: '国', contrastOff: null),
  'nlck': (name: 'NLC Kanji forms', sample: '辻', contrastOff: null),
  'hkna': (name: 'Horizontal kana', sample: 'あい', contrastOff: null),
  'pkna': (name: 'Proportional kana', sample: 'あい', contrastOff: null),
  'vkna': (name: 'Vertical kana', sample: 'あい', contrastOff: null),
  'ruby': (name: 'Ruby forms', sample: 'あ', contrastOff: null),
};

/// Returns every non-internal OpenType feature tag the font supports:
/// curated well-known tags first, followed by all remaining font tags (such as
/// `ss01`–`ss20`, `cv01`–`cv99`, and font-specific tags) in sorted order.
List<String> exposedOpenTypeTags(Set<String> supported) {
  final out = <String>[
    for (final tag in otFeatureSpecs.keys)
      if (supported.contains(tag)) tag,
  ];
  final seen = out.toSet();
  final rest = [
    for (final tag in supported)
      if (!seen.contains(tag) && !otInternalFeatures.contains(tag)) tag,
  ]..sort();
  out.addAll(rest);
  return out;
}

/// Resolves display metadata for [tag], preferring any UI label stored in the
/// font's own OpenType `FeatureParams` (`GSUB`/`GPOS`), then curated specs,
/// then dynamic formatting for `ss01`–`ss20`, `cv01`–`cv99`, or arbitrary tags.
OtFeatureSpec resolveOtFeatureSpec(String tag, Map<String, String> fontNames) {
  final fontName = fontNames[tag];
  if (otFeatureSpecs[tag] case final known?) {
    return (
      name: fontName ?? known.name,
      sample: known.sample,
      contrastOff: known.contrastOff,
    );
  }
  if (fontName != null) {
    return (name: fontName, sample: 'Aa1', contrastOff: null);
  }
  if (RegExp(r'^ss(\d{2})$').firstMatch(tag) case final m?) {
    return (
      name: 'Stylistic set ${int.parse(m[1]!)}',
      sample: 'Aa1',
      contrastOff: null,
    );
  }
  if (RegExp(r'^cv(\d{2})$').firstMatch(tag) case final m?) {
    return (
      name: 'Char variant ${int.parse(m[1]!)}',
      sample: 'Aa1',
      contrastOff: null,
    );
  }
  return (name: tag, sample: 'Aa1', contrastOff: null);
}

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
