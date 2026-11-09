// The window's colour theme in Ableton Live's manner (its .ask files): a flat list of roles, each a colour,
//   <Motolii><Theme>
//     <ChosenDefault Value="#b3c66b"/>
//     <Grey07 Value="#131313"/>
//   </Theme></Motolii>
// read from the skin the window wears (skins/<name>/theme.xml, the maker's own folder's or shelves/', the name kept in window.xml); a role the file does not say is the window's own (VS Code's manner). The meaning
// roles keep Ableton's names (ChosenDefault, ChosenPlay, ChosenRecord, Alert, SelectionBackground, ControlOnForeground,
// Clip1-16), the key mark Blender's (Keyframe); the grey ramp keeps the window's own step names (Grey00 ... Grey100),
// each step a role in both shades (ground, body, card, well, raised, lines, quiet text, text, strong text).
// A role may also be a number or a word (AviUtl2's style.conf, Obsidian's variables): the skin's shapes and type,
//     <Shade Value="light"/>  <Corner Value="3"/>  <TextScale Value="1.1"/>  <FontSans Value="Space Grotesk"/>
//     <FontSansFile Value="~/.motolii/fonts/SpaceGrotesk.ttf"/>
// a file named for a font is loaded under that name when the theme is read.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data' show ByteData;

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/widgets.dart';

import '../bridge/motolii.dart' show motoliiOwn, motoliiShelves;
import '../workspace/window/settings_file.dart';

abstract final class ColorTheme {
  /// The roles the theme file says (none: the window's own colours). The window is built again when they change.
  static final roles = ValueNotifier<Map<String, Color>>(const {});

  /// The roles that are numbers or words (the skin's shapes and type): every `<Name Value="..."/>` that is not a colour.
  static final words = ValueNotifier<Map<String, String>>(const {});

  /// The theme file the window reads unless told another (none: the home folder's; a test's window sets one of its own, so
  /// what the person who runs it wears does not move the test).
  static String? at;

  /// A role's colour: the theme's, else [usual].
  static Color of(String role, Color usual) => roles.value[role] ?? usual;

  /// A role's number: the theme's, else [usual].
  static double number(String role, double usual) => switch (double.tryParse(words.value[role] ?? '')) {
    final n? when n.isFinite => n,
    _ => usual,
  }; // (NaN or Infinity said: the usual)

  /// A role's word: the theme's, else [usual].
  static String word(String role, String usual) => words.value[role] ?? usual;

  /// The maker's skins: each a folder in skins/ of their own folder (as every shelf: doc_folders), its theme.xml beside
  /// what it brings (pictures, fonts).
  static String get skins => '$motoliiOwn/skins';

  /// Where skins are read, the maker's of a name standing over the library's (shelves/skins). ~/.motolii/skins: where a
  /// skin was put before 2026-11-09 (the guide said so), read so one worn there is not lost.
  static List<String> get _skinFolders => ['$motoliiShelves/skins', '${Platform.environment['HOME']}/.motolii/skins', skins];

  /// Each skin there, by name: its folder.
  static Map<String, String> _skinsByName() {
    final by = <String, String>{};
    for (final at in _skinFolders) {
      try {
        for (final d in Directory(at).listSync().whereType<Directory>()) {
          if (File('${d.path}/theme.xml').existsSync()) by[d.uri.pathSegments[d.uri.pathSegments.length - 2]] = d.path;
        }
      } catch (_) {} // (a folder not there: none from it)
    }
    return by;
  }

  /// The skins there, by name.
  static List<String> skinNames() => _skinsByName().keys.toList()..sort();

  /// The skin worn (none: the window's own).
  static String? get skin => switch (WindowFile.get('Skin')) {
    final s? when s.isNotEmpty => s,
    _ => null,
  };

  static String get _worn => at ?? (skin == null ? '' : '${_skinsByName()[skin] ?? '$skins/$skin'}/theme.xml');

  /// Another skin worn (none: the window's own), kept for the next time.
  static void wear(String? name) {
    WindowFile.set('Skin', name);
    if (_changed case final c?) watch(c);
    _changed?.call();
  }

  static void Function()? _changed;

  /// The theme file read (not there, or not readable: the window's own colours and shapes).
  static void load([String? path]) {
    try {
      final file = File(path ?? _worn);
      folder = file.parent.path;
      final xml = file.readAsStringSync();
      roles.value = parse(xml);
      words.value = {for (final m in RegExp(r'<(\w+)\s+Value="([^"#][^"]*)"\s*/>').allMatches(xml)) m.group(1)!: m.group(2)!};
    } catch (_) {
      roles.value = const {};
      words.value = const {};
    }
    _fonts();
    shadeSaid.value = switch (words.value['Shade']) {
      'light' => true,
      'dark' => false,
      _ => switch (roles.value['Background']) {
        final b? => b.computeLuminance() > .18,
        _ => null,
      },
    }; // (unsaid: a light background is a light skin)
  }

  /// The folder of the theme file read last: a place a role names is read from here unless it is whole (`/...`) or from home (`~/...`).
  static String folder = '';
  static String place(String w) =>
      w.isEmpty || w.startsWith('/') ? w : (w.startsWith('~/') ? '${Platform.environment['HOME']}${w.substring(1)}' : '$folder/$w');

  /// The shade the theme asks for (null: it says none; the window's own switch decides).
  static final shadeSaid = ValueNotifier<bool?>(null);

  /// Each `Font...File` role: the font file loaded under the family its `Font...` role names.
  static void _fonts() {
    for (final e in words.value.entries.where((e) => e.key.startsWith('Font') && e.key.endsWith('File'))) {
      final family = words.value[e.key.substring(0, e.key.length - 4)];
      final path = place(e.value);
      if (family == null || !File(path).existsSync()) continue;
      FontLoader(family)
        ..addFont(File(path).readAsBytes().then((b) => ByteData.sublistView(b)))
        ..load();
    }
  }

  /// The theme file read now, and again whenever it is written ([changed]: the window built again in place).
  static StreamSubscription<FileSystemEvent>? _watching;
  static void watch(void Function() changed, [String? path]) {
    _changed = changed;
    final file = File(path ?? _worn);
    load(file.path);
    _watching?.cancel();
    if (file.path.isEmpty) return; // (the window's own: nothing to watch)
    try {
      file.parent.createSync(recursive: true);
      _watching = file.parent.watch().where((e) => e.path == file.path).listen((_) {
        load(file.path);
        changed();
      });
    } catch (_) {} // (a folder that cannot be watched: read once)
  }

  /// The roles of a theme file: every `<Name Value="#rrggbb"/>` or `"#rrggbbaa"`.
  static Map<String, Color> parse(String xml) => {
    for (final m in RegExp(r'<(\w+)\s+Value="#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?"\s*/>').allMatches(xml))
      m.group(1)!: Color(int.parse('${m.group(3) ?? 'ff'}${m.group(2)}', radix: 16)),
  };
}
