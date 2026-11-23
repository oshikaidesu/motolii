// The colour theme: a flat list of roles in skins/<name>/theme.xml, each a colour, number or word.
// A role the file does not set keeps the built-in value.
// A `Font...File` role is loaded under the family its `Font...` role names.
import 'dart:async';
import 'dart:typed_data' show ByteData;

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/widgets.dart';

import 'package:motolii/storage/disk.dart' show existsFile;
import 'package:motolii/storage/font_bytes.dart' show readFontBytes;
import 'package:motolii/storage/host_platform.dart' show homeFolder, isRooted;
import 'package:motolii/storage/parent_folder.dart' show parentFolderOf;
import 'package:motolii/storage/skin_folders.dart';
import 'package:motolii/storage/text_file.dart' show readTextNow;
import 'package:motolii/storage/window_settings.dart' show WindowFile;
import 'package:motolii/skin/hex_color.dart' show colorOfHex;

/// The colour roles and number/word roles read from the current skin's theme file.
abstract final class ColorTheme {
  /// Empty means the built-in colours; the app is rebuilt when they change.
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
  static String get skins => '$_skinsOwn/skins';

  static String _skinsShelves = '', _skinsOwn = '';

  /// Set once at launch.
  static void setSkinRoots({required String shelves, required String own}) {
    _skinsShelves = shelves;
    _skinsOwn = own;
  }

  static List<String> skinNames() =>
      skinFoldersByName(shelves: _skinsShelves, own: _skinsOwn).keys.toList()
        ..sort();

  static String? get skin => switch (WindowFile.get('Skin')) {
    final s? when s.isNotEmpty => s,
    _ => null,
  };

  static String get _worn =>
      at ??
      (skin == null
          ? ''
          : '${skinFoldersByName(shelves: _skinsShelves, own: _skinsOwn)[skin] ?? '$skins/$skin'}/theme.xml');

  /// Switches to the skin [name], or to the built-in look when null.
  static void wear(String? name) {
    WindowFile.set('Skin', name);
    if (_changed case final c?) watch(c);
    _changed?.call();
  }

  /// When false, `.ui.js` cards strip custom VST faceplates (`surface` / `style`)
  /// and fall back to Motolii's uniform skin while keeping all controls functional.
  static final ValueNotifier<bool> customCardSkins = ValueNotifier<bool>(
    (WindowFile.get('CustomCardSkins') ?? 'true') != 'false',
  );

  static void setCustomCardSkins(bool enabled) {
    customCardSkins.value = enabled;
    WindowFile.set('CustomCardSkins', '$enabled');
  }

  static void Function()? _changed;

  /// Reads the theme file at [path]. Missing or unreadable → built-in colours.
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

  /// The folder of the theme file read last. Role paths are relative to it.
  static String folder = '';
  static String place(String w) => w.isEmpty || isRooted(w)
      ? w
      : (w.startsWith('~/') ? '$homeFolder${w.substring(1)}' : '$folder/$w');

  /// Whether the theme asks for the light shade, or null when it does not say and the app's own switch decides.
  static final shadeSaid = ValueNotifier<bool?>(null);

  /// Loads each `Font...File` role's font file.
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

  /// Reads the theme file and re-reads it whenever it is written.
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

  /// Parses colour roles from XML.
  static Map<String, Color> parse(String xml) => {
    for (final m in RegExp(
      r'<(\w+)\s+Value="(#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?)"\s*/>',
    ).allMatches(xml))
      m.group(1)!: colorOfHex(m.group(2)!)!,
  };
}
