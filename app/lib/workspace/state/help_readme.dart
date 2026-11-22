// Help menu targets: README path, crash logs folder, and issue tracker URL.
import 'package:motolii/storage/host_platform.dart'
    show homeFolder, hostIsMacOS;
import 'package:motolii/storage/parent_folder.dart' show parentFolderOf;
import 'package:motolii/workspace/state/engine_access.dart' show engineFolder;

/// The path of README.md, one folder above the engine's folder.
String helpReadmePath() => '${parentFolderOf(engineFolder())}/README.md';

/// Folder where engine crash reports and diagnostic logs are stored.
String crashLogsFolder() => hostIsMacOS
    ? '$homeFolder/Library/Caches/Motolii'
    : '$homeFolder/.motolii/logs';

/// Public issue tracker URL for beta bug reports.
const String issueReportUrl =
    'https://github.com/oshikaidesu/motolii/issues/new';
