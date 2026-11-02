// What the hand keeps of the Effects shelf: the effects put on lately, and what was typed and where as each went on.
import 'dart:convert';
import 'dart:io';

/// Where the effects put on lately are kept, the newest first, forty, as Alight Motion's effect browser keeps them
/// (EffectBrowser.kt:117), in the Fonts shelf's way (font_recent.json; a test points it elsewhere: [effectRecentAt]).
File _recentFile = File('${Platform.environment['HOME']}/.motolii/effect_recent.json');
List<String>? _recent;
void effectRecentAt(File f) => (_recentFile = f, _recent = null);
List<String> effectRecent() => _recent ??= () {
  try {
    return [for (final s in jsonDecode(_recentFile.readAsStringSync()) as List) '$s'];
  } catch (_) {
    return <String>[];
  }
}();

/// An effect went on: it comes first among the recent, and a line is added to effect_used.jsonl beside them (one JSON
/// object a line, JSON Lines' way of a log that only grows): when, which, the words typed and the table it was picked
/// from, so what was looked over and what was searched for can be counted.
void effectUsed(String id, {required String words, required String chip}) {
  final r = effectRecent()
    ..remove(id)
    ..insert(0, id);
  if (r.length > 40) r.removeRange(40, r.length);
  try {
    _recentFile.parent.createSync(recursive: true);
    _recentFile.writeAsStringSync(jsonEncode(r));
    File('${_recentFile.parent.path}/effect_used.jsonl').writeAsStringSync('${jsonEncode({'at': DateTime.now().toIso8601String(), 'id': id, 'words': words, 'chip': chip})}\n', mode: FileMode.append);
  } catch (_) {}   // (not kept: known while the window is open)
}
