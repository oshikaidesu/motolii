// Window settings that persist between runs (the zoom and the skin), stored in ~/.motolii/window.xml like this:
//   <Motolii><Window><Zoom Value="1.17"/><Skin Value="labs"/></Window></Motolii>
import 'dart:convert';
import 'dart:io';

/// Writes text or bytes to [f], creating its folder first. Any error is ignored, so nothing is saved.
void fileKeep(File f, Object data) {
  try {
    f.parent.createSync(recursive: true);
    data is String ? f.writeAsStringSync(data) : f.writeAsBytesSync(data as List<int>);
  } catch (_) {}
}

/// The JSON decoded from [f], or null if the file is missing or is not JSON.
Object? fileJson(File f) {
  try {
    return jsonDecode(f.readAsStringSync());
  } catch (_) {
    return null;
  }
}

/// The list stored in [f] as JSON, or an empty list if the file is missing or does not hold a list.
List fileList(File f) => switch (fileJson(f)) {
  final List l => l,
  _ => const [],
};

/// Returns [name], or else the first of at(2), at(3), ... that is not [taken], as the Finder names copies.
String firstFree(String name, bool Function(String) taken, String Function(int n) at) {
  for (var n = 2; taken(name); n++) {
    name = at(n);
  }
  return name;
}

/// Reads and writes the window settings file.
abstract final class WindowFile {
  static File get _file => File('${Platform.environment['HOME']}/.motolii/window.xml');

  static Map<String, String> _all() {
    try {
      return {for (final m in RegExp(r'<(\w+)\s+Value="([^"]*)"\s*/>').allMatches(_file.readAsStringSync())) m.group(1)!: m.group(2)!};
    } catch (_) {
      return {};
    }
  }

  /// The saved value for [name], or null if none is saved.
  static String? get(String name) => _all()[name];

  /// Saves [value] for [name] and leaves the other settings as they were. A null [value] removes the setting.
  static void set(String name, String? value) {
    final all = _all();
    value == null ? all.remove(name) : all[name] = value;
    fileKeep(
      _file,
      '<?xml version="1.0" encoding="UTF-8"?>\n<Motolii>\n\t<Window>\n${[for (final e in all.entries) '\t\t<${e.key} Value="${e.value}"/>'].join('\n')}\n\t</Window>\n</Motolii>\n',
    );
  }
}
