// Shows a file in the system's file manager (the Finder on a Mac, Explorer on Windows). Panels import this instead of
// dart:io.
import 'dart:io';

import 'package:motolii/storage/host_platform.dart' show hostIsWindows;

/// The menu entry that shows a file in the system's file manager.
String get revealLabel => hostIsWindows ? 'Show in Explorer' : 'Show in Finder';

/// Shows [path] in the system's file manager.
Future<ProcessResult> revealFile(String path) => hostIsWindows
    ? Process.run('explorer', ['/select,${path.replaceAll('/', r'\')}'])
    : Process.run('open', ['-R', path]);
