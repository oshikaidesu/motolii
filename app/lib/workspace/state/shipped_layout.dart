// The window layouts that ship with Motolii: each workspace's file in shelves/workspaces/, as docking writes it.
import 'package:motolii/storage/disk.dart' show existsFile;
import 'package:motolii/storage/text_file.dart' show readTextNow;
import 'package:motolii/workspace/state/engine_access.dart' show shelvesFolder;

/// The layout that the workspace [name] ships as, trimmed, or null when it ships none.
String? shippedLayoutOf(String name) {
  final file = '${shelvesFolder()}/workspaces/${name.toLowerCase()}.layout';
  return existsFile(file) ? readTextNow(file).trim() : null;
}
