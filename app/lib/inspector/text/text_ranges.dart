// A text layer's styles (`text_styles` value):
// - Positional ranges: "start count declarations" (Unicode rune indices, matching
//   After Effects' style.setFontSize(value, startIndex, numOfCharacters)).
// - Composite character-class rules: "@class declarations" (e.g. "@hiragana font-size: 88%"),
//   expanded by the engine (engine/community/css/text.rs) for both horizontal and vertical text.
// Class rules apply first; explicit positional ranges override them when they overlap.

/// Supported composite-font character classes (matching engine/community/css/text.rs).
const textCharClasses = <({String id, String label, String tip})>[
  (id: 'kanji', label: '漢字', tip: 'Kanji (漢字)'),
  (id: 'hiragana', label: 'かな', tip: 'Hiragana (ひらがな)'),
  (id: 'katakana', label: 'カナ', tip: 'Katakana (カタカナ)'),
  (id: 'upper', label: 'ABC', tip: 'Uppercase Latin (大文字)'),
  (id: 'lower', label: 'abc', tip: 'Lowercase Latin (小文字)'),
  (id: 'digit', label: '123', tip: 'Digits (数字)'),
  (id: 'punct', label: '、。', tip: 'Punctuation (約物・句読点)'),
];

/// Whether Unicode scalar value [u] belongs to character class [cls].
bool charMatchesClass(int u, String cls) {
  switch (cls) {
    case 'kanji':
      return (u >= 0x4E00 && u <= 0x9FFF) ||
          (u >= 0x3400 && u <= 0x4DBF) ||
          (u >= 0xF900 && u <= 0xFAFF) ||
          u == 0x3005 ||
          (u >= 0x20000 && u <= 0x2A6DF);
    case 'hiragana':
      return u >= 0x3040 && u <= 0x309F;
    case 'katakana':
      return (u >= 0x30A0 && u <= 0x30FF) ||
          (u >= 0x31F0 && u <= 0x31FF) ||
          (u >= 0xFF66 && u <= 0xFF9F);
    case 'upper':
      return (u >= 0x41 && u <= 0x5A) ||
          (u >= 0xFF21 && u <= 0xFF3A) ||
          (u >= 0xC0 && u <= 0xDE && u != 0xD7);
    case 'lower':
      return (u >= 0x61 && u <= 0x7A) ||
          (u >= 0xFF41 && u <= 0xFF5A) ||
          (u >= 0xDF && u <= 0xFF && u != 0xF7);
    case 'latin':
      return charMatchesClass(u, 'upper') || charMatchesClass(u, 'lower');
    case 'digit':
      return (u >= 0x30 && u <= 0x39) || (u >= 0xFF10 && u <= 0xFF19);
    case 'punct':
      const puncts = '、。，．！？「」『』（）【】・…ー〜～：；!?,.:;()[]{}-—"\'';
      return puncts.runes.contains(u);
    default:
      return false;
  }
}

/// The letters selected in [text], as the start and count text_styles takes, or null when nothing is selected or
/// the selection [picked] was made in another text. Text fields count UTF-16 units; text_styles counts characters.
({int start, int count})? pickedLetters(
  String text,
  ({String text, int start, int end})? picked,
) => picked == null || picked.text != text || picked.start >= picked.end
    ? null
    : (
        start: text.substring(0, picked.start).runes.length,
        count: text.substring(picked.start, picked.end).runes.length,
      );

/// The font file a CSS font-family names first, as ranges name a font file (`'/path/font.ttf'`), or null.
String? fontFileOf(String? fontFamily) {
  final f = fontFamily?.split(',').first.trim().replaceAll(RegExp('[\'"]'), '');
  return f == null || f.isEmpty ? null : f;
}

/// One positional line of `text_styles`.
typedef TextRange = ({int start, int count, Map<String, String> sets});

/// One character-class rule line of `text_styles` (`@hiragana font-size: 88%`).
typedef TextClassRule = ({String name, Map<String, String> sets});

Map<String, String> _parseDecls(String raw) => {
  for (final d in raw.split(';'))
    if (d.indexOf(':') case final colon when colon > 0)
      d.substring(0, colon).trim(): d.substring(colon + 1).trim(),
};

String _formatDecls(Map<String, String> sets) =>
    [for (final e in sets.entries) '${e.key}: ${e.value}'].join('; ');

/// Reads `@class declarations` lines from `text_styles`.
List<TextClassRule> readClassRules(String styles) => [
  for (final line in styles.split('\n'))
    if (RegExp(r'^\s*@([a-z_]+)\s+(.+)$').firstMatch(line) case final m?)
      if (_parseDecls(m[2]!) case final sets when sets.isNotEmpty)
        (name: m[1]!, sets: sets),
];

/// Reads positional `start count declarations` lines from `text_styles`.
List<TextRange> readRanges(String styles) => [
  for (final line in styles.split('\n'))
    if (RegExp(r'^\s*(\d+)\s+(\d+)\s*(.*)$').firstMatch(line) case final m?)
      (
        start: int.parse(m[1]!),
        count: int.parse(m[2]!),
        sets: _parseDecls(m[3]!),
      ),
];

/// Writes class rules and positional ranges back as `text_styles`, dropping empty entries.
String writeStyles(List<TextClassRule> classes, List<TextRange> ranges) => [
  for (final c in classes)
    if (c.sets.isNotEmpty) '@${c.name} ${_formatDecls(c.sets)}',
  for (final r in ranges)
    if (r.count > 0 && r.sets.isNotEmpty)
      '${r.start} ${r.count} ${_formatDecls(r.sets)}',
].join('\n');

/// Writes positional ranges alone as `text_styles`.
String writeRanges(List<TextRange> ranges) => writeStyles(const [], ranges);

/// Sets CSS [property] to [value] for character class [className] (or removes it when [value] is null),
/// preserving all other class rules and positional ranges.
String styleClass(
  String styles,
  String className,
  String property,
  String? value,
) {
  final classes = readClassRules(styles);
  final ranges = readRanges(styles);
  final idx = classes.lastIndexWhere((c) => c.name == className);
  if (idx >= 0) {
    final c = classes.removeAt(idx);
    final sets = {...c.sets}..remove(property);
    if (value != null) sets[property] = value;
    if (sets.isNotEmpty) classes.add((name: className, sets: sets));
  } else if (value != null) {
    classes.add((name: className, sets: {property: value}));
  }
  return writeStyles(classes, ranges);
}

/// Reads CSS [property] configured for character class [className], or [otherwise].
String? classValue(
  String styles,
  String className,
  String property, {
  String? otherwise,
}) {
  String? v = otherwise;
  for (final c in readClassRules(styles)) {
    if (c.name == className && c.sets.containsKey(property)) {
      v = c.sets[property];
    }
  }
  return v;
}

/// Set of character class names that currently carry at least one style declaration.
Set<String> styledClasses(String styles) => {
  for (final c in readClassRules(styles))
    if (c.sets.isNotEmpty) c.name,
};

/// Sets CSS [property] to [value] for the characters from [start], [count] of them, or takes it off them when [value]
/// is null. Preserves all `@class` rules untouched.
String styleRange(
  String styles,
  int start,
  int count,
  String property,
  String? value,
) {
  final end = start + count;
  final classes = readClassRules(styles);
  final ranges = readRanges(styles);
  final kept = <TextRange>[
    for (final r in ranges)
      r.start >= start &&
              r.start + r.count <= end &&
              !(r.start == start && r.count == count)
          ? (
              start: r.start,
              count: r.count,
              sets: {...r.sets}..remove(property),
            )
          : r,
  ];
  final same = kept.lastIndexWhere((r) => r.start == start && r.count == count);
  if (same >= 0) {
    final r = kept.removeAt(same);
    final sets = {...r.sets}..remove(property);
    kept.add((start: start, count: count, sets: {...sets, property: ?value}));
  } else if (value != null) {
    kept.add((start: start, count: count, sets: {property: value}));
  }
  return writeStyles(classes, kept);
}

/// The value CSS [property] has for every character from [start], [count] of them, as the last range covering each
/// sets it, or [otherwise] for a character no range sets it on: null where the characters disagree, or where one has
/// no value at all.
String? rangeValue(
  String styles,
  int start,
  int count,
  String property, {
  String? otherwise,
}) {
  final ranges = readRanges(styles);
  String? seen;
  for (var i = start; i < start + count; i++) {
    String? v = otherwise;
    for (final r in ranges) {
      if (i >= r.start && i < r.start + r.count) v = r.sets[property] ?? v;
    }
    if (v == null || (seen != null && v != seen)) return null;
    seen = v;
  }
  return seen;
}

/// Moves positional ranges after a text edit while preserving all `@class` composite rules unchanged.
String shiftRanges(String styles, int at, int removed, int inserted) {
  int moved(int i, {required bool end}) => i < at
      ? i
      : i == at
      ? (end && removed == 0 ? at + inserted : at)
      : i < at + removed
      ? at + inserted
      : i - removed + inserted;
  return writeStyles(readClassRules(styles), [
    for (final r in readRanges(styles))
      if (moved(r.start, end: false) case final a)
        (
          start: a,
          count: moved(r.start + r.count, end: true) - a,
          sets: r.sets,
        ),
  ]);
}
