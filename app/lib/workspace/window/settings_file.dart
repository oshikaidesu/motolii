// What the window keeps for the next time (its zoom, the skin it wears), in ~/.motolii/window.xml in the theme's form:
//   <Motolii><Window><Zoom Value="1.17"/><Skin Value="labs"/></Window></Motolii>
import 'dart:convert';
import 'dart:io';

/// Text or bytes kept in a file, its folder made first; any error is swallowed (not kept).
void fileKeep(File f, Object data) {
  try {
    f.parent.createSync(recursive: true);
    data is String ? f.writeAsStringSync(data) : f.writeAsBytesSync(data as List<int>);
  } catch (_) {}
}

/// The JSON a file holds (null: no file, or not JSON).
Object? fileJson(File f) {
  try {
    return jsonDecode(f.readAsStringSync());
  } catch (_) {
    return null;
  }
}

/// The list a file holds (empty: no file, or not a list).
List fileList(File f) => switch (fileJson(f)) {
  final List l => l,
  _ => const [],
};

/// [name], or the first of at(2), at(3)... that is not [taken]: as Finder names a copy.
String firstFree(String name, bool Function(String) taken, String Function(int n) at) {
  for (var n = 2; taken(name); n++) {
    name = at(n);
  }
  return name;
}

abstract final class WindowFile {
  static File get _file => File('${Platform.environment['HOME']}/.motolii/window.xml');

  static Map<String, String> _all() {
    try {
      return {for (final m in RegExp(r'<(\w+)\s+Value="([^"]*)"\s*/>').allMatches(_file.readAsStringSync())) m.group(1)!: m.group(2)!};
    } catch (_) {
      return {};
    }
  }

  /// A value kept (none: not kept).
  static String? get(String name) => _all()[name];

  /// A value kept, the others as they were (null: no longer kept).
  static void set(String name, String? value) {
    final all = _all();
    value == null ? all.remove(name) : all[name] = value;
    fileKeep(
      _file,
      '<?xml version="1.0" encoding="UTF-8"?>\n<Motolii>\n\t<Window>\n${[for (final e in all.entries) '\t\t<${e.key} Value="${e.value}"/>'].join('\n')}\n\t</Window>\n</Motolii>\n',
    );
  }
}
