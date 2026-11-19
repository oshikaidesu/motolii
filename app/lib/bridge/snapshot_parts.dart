// How the app reads the engine's snapshots (docs/app/BRIDGE.md): the bytes decoded as they are, the parts the engine
// hands over put into what is held, and each part parsed once.
import 'dart:convert';
import 'dart:typed_data';

final _bytesToJson = const Utf8Decoder().fuse(const JsonDecoder());

/// A snapshot from the engine's UTF-8 bytes. Fused, so no String of the whole text is made on the way.
Map<String, dynamic> snapshotOf(Uint8List bytes) =>
    _bytesToJson.convert(bytes) as Map<String, dynamic>;

// For each snapshot, by part and then by form, what was parsed from it.
final _parsed = Expando<Map<String, Map<String, Object>>>();

/// The [part] of [snapshot] in the form its readers want, parsed on the first read and kept with the snapshot.
/// [as] names the form when a part is read in more than one.
///
/// A snapshot is never changed, only replaced, so what was parsed from it stays true for as long as it is held.
T parsedOnce<T extends Object>(
  Map<String, dynamic> snapshot,
  String part,
  T Function() parse, {
  String as = '',
}) => (((_parsed[snapshot] ??= {})[part] ??= {})[as] ??= parse()) as T;

/// [held] with the [parts] the engine handed over put in; a part that is null is gone. [held] itself when there
/// are none, so readers that compare with `identical` see that nothing changed.
///
/// The engine hands over only the parts that differ, so what was parsed from the others is carried along.
Map<String, dynamic> merged(
  Map<String, dynamic> held,
  Map<String, dynamic> parts,
) {
  if (parts.isEmpty) return held;
  final next = <String, dynamic>{...held, ...parts}
    ..removeWhere((_, part) => part == null);
  if (_parsed[held] case final kept?) {
    _parsed[next] = {
      for (final e in kept.entries)
        if (!parts.containsKey(e.key)) e.key: e.value,
    };
  }
  return next;
}

/// The parts of a layer's snapshot that a number set anew or a keyframe moved can change (the engine's
/// snapshot_layer makes these alone then). Any other part, or a part of the document's own but what it says
/// of the change itself, is its structure: names, words, cards, ranges, sizes.
const numberParts = {
  'lasts',
  'stretches',
  'keys',
  'value',
  'keyTimes',
  'keyValues',
  'keyEasings',
};

/// Whether [parts] of a layer's snapshot hold more than its numbers.
bool hasStructure(Map<String, dynamic> parts) =>
    parts.keys.any((part) => !numberParts.contains(part));

/// Whether [parts] of the document's own snapshot hold more than its account of the change (what changed, the
/// time spent editing).
bool hasDocumentStructure(Map<String, dynamic> parts) =>
    parts.keys.any((part) => part != 'changes' && part != 'edited');

/// The words of a space-separated list.
List<String> spaced(Object? said) => List.unmodifiable([
  for (final w in ((said as String?) ?? '').split(' '))
    if (w.isNotEmpty) w,
]);

/// The numbers of a JSON array.
List<double> numbers(Object? said) => List.unmodifiable([
  for (final n in (said as List<dynamic>?) ?? const []) (n as num).toDouble(),
]);

/// Each line as what is before its first space and what is after. A line without both is left out.
List<(String, String)> named(Object? said) => List.unmodifiable([
  for (final l in ((said as String?) ?? '').split('\n'))
    if (l.indexOf(' ') case final i when i > 0)
      (l.substring(0, i), l.substring(i + 1)),
]);

/// Cards written as "Title: name name; Title: name": each a title and its property names.
List<(String, List<String>)> cardsIn(Object? said) => List.unmodifiable([
  for (final c in ((said as String?) ?? '').split('; '))
    if (c.indexOf(': ') case final at when at > 0)
      (c.substring(0, at), spaced(c.substring(at + 2))), // An effect with no parameters gives a card with none (see doc_cards_of).
]);
