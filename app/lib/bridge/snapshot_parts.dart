// How the app reads the engine's snapshots (docs/app/BRIDGE.md): the bytes decoded as they are, and each part parsed once.
import 'dart:convert';
import 'dart:typed_data';

final _bytesToJson = const Utf8Decoder().fuse(const JsonDecoder());

/// A snapshot from the engine's UTF-8 bytes. Fused, so no String of the whole text is made on the way.
Map<String, dynamic> snapshotOf(Uint8List bytes) =>
    _bytesToJson.convert(bytes) as Map<String, dynamic>;

final _parsed = Expando<Map<String, Object>>();

/// A part of [snapshot] in the form its readers want, parsed on the first read and kept with the snapshot.
///
/// A snapshot is never changed, only replaced, so what was parsed from it stays true for as long as it is held.
T parsedOnce<T extends Object>(
  Map<String, dynamic> snapshot,
  String what,
  T Function() parse,
) => ((_parsed[snapshot] ??= {})[what] ??= parse()) as T;

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
