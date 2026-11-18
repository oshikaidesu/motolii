// The app's colour theme, in the manner of Ableton Live's .ask files: a flat list of roles, each a colour.
//   <Motolii><Theme>
//     <ChosenDefault Value="#b3c66b"/>
//     <Grey07 Value="#131313"/>
//   </Theme></Motolii>
// The file is skins/<name>/theme.xml of the current skin, found in the user's own skins folder or in shelves/.
// The skin name is stored in window.xml.
// A role the file does not set keeps the built-in value, as in VS Code.
// - The meaning roles keep Ableton's names: ChosenDefault, ChosenPlay, ChosenRecord, Alert, SelectionBackground,
//   ControlOnForeground, Clip1-16. The keyframe mark is named after Blender's (Keyframe).
// - The grey ramp keeps the app's own step names, Grey00 to Grey100. Each step has a role in both shades:
//   ground, body, card, well, raised, lines, quiet text, text, strong text.
// - A role may also be a number or a word, as in AviUtl2's style.conf and Obsidian's variables. These set the skin's shapes and type:
//     <Shade Value="light"/>  <Corner Value="3"/>  <TextScale Value="1.1"/>  <FontSans Value="Space Grotesk"/>
//     <FontSansFile Value="~/.motolii/fonts/SpaceGrotesk.ttf"/>
// A `Font...File` role is loaded as a font under the family name given by the matching `Font...` role when the theme is read.
import 'dart:async';
import 'dart:typed_data' show ByteData;

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/widgets.dart';

import 'package:motolii/storage/disk.dart' show existsFile;
import 'package:motolii/storage/font_bytes.dart' show readFontBytes;
import 'package:motolii/storage/host_platform.dart' show homeFolder;
import 'package:motolii/storage/parent_folder.dart' show parentFolderOf;
import 'package:motolii/storage/skin_folders.dart';
import 'package:motolii/storage/text_file.dart' show readTextNow;
import 'package:motolii/storage/window_settings.dart' show WindowFile;
import 'package:motolii/skin/hex_color.dart' show colorOfHex;

/// The colour roles and number/word roles read from the current skin's theme file.
abstract final class ColorTheme {
  /// The colour roles the theme file sets. Empty means the built-in colours; the app is rebuilt when they change.
  static final roles = ValueNotifier<Map<String, Color>>(const {});

  /// The roles that are numbers or words, such as shapes and type: every `<Name Value="..."/>` that is not a colour.
  static final words = ValueNotifier<Map<String, String>>(const {});

  /// The theme file to read instead of the current skin's.
  /// Null means the skin's own file. A test sets it so that the skin the developer wears does not change the test.
  static String? at;

  /// The colour of [role] in the theme, else [usual].
  static Color of(String role, Color usual) => roles.value[role] ?? usual;

  /// The number of [role] in the theme, else [usual].
  static double number(String role, double usual) =>
      switch (double.tryParse(words.value[role] ?? '')) {
        final n? when n.isFinite => n,
        _ => usual,
      }; // NaN and Infinity fall back to [usual].

  /// The text of [role] in the theme, else [usual].
  static String word(String role, String usual) => words.value[role] ?? usual;

  /// The user's own skins folder.
  /// Each skin is a folder in it, like every shelf (doc_folders), with its theme.xml beside the pictures and fonts it brings.
  static String get skins => '$_skinsOwn/skins';

  static String _skinsShelves = '', _skinsOwn = '';

  /// Where the app's own skins are read from: the engine's shelves and the user's own folder. Set once at launch.
  static void setSkinRoots({required String shelves, required String own}) {
    _skinsShelves = shelves;
    _skinsOwn = own;
  }

  /// The names of the available skins, sorted.
  static List<String> skinNames() =>
      skinFoldersByName(shelves: _skinsShelves, own: _skinsOwn).keys.toList()
        ..sort();

  /// The name of the skin in use, or null for the built-in look.
  static String? get skin => switch (WindowFile.get('Skin')) {
    final s? when s.isNotEmpty => s,
    _ => null,
  };

  static String get _worn =>
      at ??
      (skin == null
          ? ''
          : '${skinFoldersByName(shelves: _skinsShelves, own: _skinsOwn)[skin] ?? '$skins/$skin'}/theme.xml');

  /// Switches to the skin [name], or to the built-in look when null, and stores the choice for the next launch.
  static void wear(String? name) {
    WindowFile.set('Skin', name);
    if (_changed case final c?) watch(c);
    _changed?.call();
  }

  static void Function()? _changed;

  /// Reads the theme file at [path].
  /// If it is missing or unreadable, the built-in colours and shapes are used.
  static void load(String path) {
    try {
      folder = parentFolderOf(path);
      final xml = readTextNow(path);
      roles.value = parse(xml);
      words.value = {
        for (final m in RegExp(
          r'<(\w+)\s+Value="([^"#][^"]*)"\s*/>',
        ).allMatches(xml))
          m.group(1)!: m.group(2)!,
      };
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
    }; // Without a `Shade` role, a light `Background` makes a light skin.
  }

  /// The folder of the theme file read last.
  /// A path named by a role is relative to this folder unless it is absolute (`/...`) or starts at home (`~/...`).
  static String folder = '';
  static String place(String w) => w.isEmpty || w.startsWith('/')
      ? w
      : (w.startsWith('~/') ? '$homeFolder${w.substring(1)}' : '$folder/$w');

  /// Whether the theme asks for the light shade, or null when it does not say and the app's own switch decides.
  static final shadeSaid = ValueNotifier<bool?>(null);

  /// Loads each `Font...File` role's font file under the family its `Font...` role names.
  static void _fonts() {
    for (final e in words.value.entries.where(
      (e) => e.key.startsWith('Font') && e.key.endsWith('File'),
    )) {
      final family = words.value[e.key.substring(0, e.key.length - 4)];
      final path = place(e.value);
      if (family == null || !existsFile(path)) continue;
      FontLoader(family)
        ..addFont(readFontBytes(path).then((b) => ByteData.sublistView(b)))
        ..load();
    }
  }

  static StreamSubscription<dynamic>? _watching;

  /// Reads the theme file now and again whenever it is written, then calls [changed] so the app can rebuild in place.
  static void watch(void Function() changed) {
    _changed = changed;
    final path = _worn;
    load(path);
    _watching?.cancel();
    // The built-in look has no file to watch.
    if (path.isEmpty) return;
    _watching = watchFile(path, () {
      load(path);
      changed();
    });
  }

  /// The colour roles of a theme file: every `<Name Value="#rrggbb"/>` or `"#rrggbbaa"`.
  static Map<String, Color> parse(String xml) => {
    for (final m in RegExp(
      r'<(\w+)\s+Value="(#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?)"\s*/>',
    ).allMatches(xml))
      m.group(1)!: colorOfHex(m.group(2)!)!,
  };
}
