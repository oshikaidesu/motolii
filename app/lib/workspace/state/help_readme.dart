// The README that the Help menu opens: it sits beside the engine's folder, in the root of the project.
import 'package:motolii/storage/parent_folder.dart' show parentFolderOf;
import 'package:motolii/workspace/state/engine_access.dart' show engineFolder;

/// The path of README.md, one folder above the engine's folder.
String helpReadmePath() => '${parentFolderOf(engineFolder())}/README.md';
