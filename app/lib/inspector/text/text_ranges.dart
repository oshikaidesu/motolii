// A text layer's ranges (its `text_styles` value): one range a line, "start count declarations", where start and
// count are Unicode characters, as After Effects' sourceText style.setFontSize(value, startIndex, numOfCharacters)
// counts them, and the declarations are CSS ones, which the engine hands to Blitz (engine/community/css/text.rs).
// A later line wins where ranges overlap, as a later CSS rule does.

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

/// One line of `text_styles`: the characters from [start], [count] of them, and their CSS declarations by property.
typedef TextRange = ({int start, int count, Map<String, String> sets});

/// Reads `text_styles`. A line that does not start with two whole numbers is skipped.
List<TextRange> readRanges(String styles) => [
  for (final line in styles.split('\n'))
    if (RegExp(r'^\s*(\d+)\s+(\d+)\s*(.*)$').firstMatch(line) case final m?)
      (
        start: int.parse(m[1]!),
        count: int.parse(m[2]!),
        sets: {
          for (final d in m[3]!.split(';'))
            if (d.indexOf(':') case final colon when colon > 0)
              d.substring(0, colon).trim(): d.substring(colon + 1).trim(),
        },
      ),
];

/// Writes ranges back as `text_styles`, leaving out ranges that set nothing.
String writeRanges(List<TextRange> ranges) => [
  for (final r in ranges)
    if (r.count > 0 && r.sets.isNotEmpty)
      '${r.start} ${r.count} ${[for (final e in r.sets.entries) '${e.key}: ${e.value}'].join('; ')}',
].join('\n');

/// Sets CSS [property] to [value] for the characters from [start], [count] of them, or takes it off them when [value]
/// is null. Earlier ranges lying wholly inside lose the property, since the new line would hide it there anyway; a
/// range of exactly these characters keeps its other declarations and takes the new one.
String styleRange(
  String styles,
  int start,
  int count,
  String property,
  String? value,
) {
  final end = start + count;
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
  return writeRanges(kept);
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

/// Moves the ranges after an edit of the text that replaced [removed] characters at [at] with [inserted] ones, so
/// each range keeps its letters, as a rich text box does. Letters typed in place of others take the ranges of the
/// first letter replaced, as Word's typing over a selection does; letters typed where none were removed join a range
/// that starts or ends there. A range whose letters were all removed goes.
String shiftRanges(String styles, int at, int removed, int inserted) {
  int moved(int i, {required bool end}) => i < at
      ? i
      : i == at
      ? (end && removed == 0 ? at + inserted : at)
      : i < at + removed
      ? at + inserted
      : i - removed + inserted;
  return writeRanges([
    for (final r in readRanges(styles))
      if (moved(r.start, end: false) case final a)
        (
          start: a,
          count: moved(r.start + r.count, end: true) - a,
          sets: r.sets,
        ),
  ]);
}
