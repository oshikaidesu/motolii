// The files a window keeps beside its project: the untitled project it opens without one, the project picture of this run,
// the clipboard between windows and the untitled names beside a project. Panels import this instead of dart:io.
import 'dart:io';

import 'package:motolii/storage/host_platform.dart' show homeFolder;

/// A new untitled project in a new temporary folder, for a window opened without a project.
String untitledProjectPath() =>
    '${Directory.systemTemp.createTempSync('motolii').path}/Untitled.motolii';

/// Where the project picture of this run is written.
String posterPath() => '${Directory.systemTemp.path}/motolii_poster_$pid.png';

/// The file where a copied layer or preset ([what]: `thing`, `style` or `card`) is kept between windows (the engine's own
/// format: document/edit/presets.h). Its folder is made if it is not there.
String clipboardFile(String what) {
  final dir = Directory('$homeFolder/Library/Caches/Motolii')
    ..createSync(recursive: true);
  return '${dir.path}/clipboard_$what.motolii';
}

/// Whether the clipboard file for [what] is there, so a paste has something to take.
bool clipboardFileThere(String what) => File(clipboardFile(what)).existsSync();

/// A name for an untitled project in [folder] that is not taken yet: untitled_1.motolii, untitled_2.motolii and so on.
String freeUntitledPath(String folder) {
  for (var n = 1; ; n++) {
    if (!File('$folder/untitled_$n.motolii').existsSync()) {
      return '$folder/untitled_$n.motolii';
    }
  }
}
