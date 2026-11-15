// The user's keybindings file, ~/.motolii/keybindings.json. Panels import this instead of dart:io.
import 'dart:io';

import 'package:motolii/storage/host_platform.dart' show homeFolder;

/// The text of ~/.motolii/keybindings.json. Throws when there is no such file.
String readKeybindingsText() =>
    File('$homeFolder/.motolii/keybindings.json').readAsStringSync();
