// The disk as the shelves' tiles and items reach it, by path: the files a tile is drawn into and read from, the folders
// they are made in, the JSON the decks and stars are kept in, and the tools (ffmpeg, sips) that draw the pictures.
// Panels and state import this instead of dart:io.
import 'dart:convert';
import 'dart:io';

/// The environment variable [name], or null when it is not set.
String? envVar(String name) => Platform.environment[name];

/// Makes a new folder in the system's temporary folder, named from [prefix]. Returns its path.
String makeTempFolder(String prefix) =>
    Directory.systemTemp.createTempSync(prefix).path;

/// Creates the folder [path] and any folder above it. Throws if that fails.
void makeFolder(String path) => Directory(path).createSync(recursive: true);

/// Creates the folder that the file [filePath] is in. Throws if that fails.
void makeFolderOf(String filePath) =>
    Directory(File(filePath).parent.path).createSync(recursive: true);

/// The folder above [folder], as an absolute path.
String folderAbove(String folder) => Directory(folder).absolute.parent.path;

/// Removes the folder [path] and everything in it.
void removeFolder(String path) => Directory(path).deleteSync(recursive: true);

/// Makes an empty file at [path], and the folders it is in.
void makeFile(String path) => File(path).createSync(recursive: true);

void deleteFile(String path) => File(path).deleteSync();

void writeText(String path, String text) => File(path).writeAsStringSync(text);

void appendText(String path, String text) =>
    File(path).writeAsStringSync(text, mode: FileMode.append);

void copyFile(String from, String to) => File(from).copySync(to);

void moveFile(String from, String to) => File(from).renameSync(to);

/// The text of the file [path], or null when it cannot be read.
String? readTextIfThere(String path) {
  try {
    return File(path).readAsStringSync();
  } on FileSystemException {
    return null;
  }
}

/// The bytes of the file [path]. Throws if it cannot be read.
List<int> readBytes(String path) => File(path).readAsBytesSync();

/// [count] bytes of the file [path], from byte [at]. Null when the file cannot be opened.
List<int>? readBytesAt(String path, int at, int count) {
  try {
    final f = File(path).openSync()..setPositionSync(at);
    final got = f.readSync(count);
    f.closeSync();
    return got;
  } on FileSystemException {
    return null;
  }
}

/// The JSON in the file [path], or null when it is missing or is not JSON.
Object? readJsonFile(String path) {
  try {
    return jsonDecode(File(path).readAsStringSync());
  } catch (_) {
    return null;
  }
}

/// The list in the JSON file [path], or an empty list when the file is missing or does not hold a list.
List readJsonList(String path) => switch (readJsonFile(path)) {
  final List l => l,
  _ => const [],
};

/// Writes [text] to [path], making its folder first. Any error is ignored, so nothing is saved.
void keepText(String path, String text) {
  try {
    makeFolderOf(path);
    writeText(path, text);
  } catch (_) {}
}

/// Every change under [folder], down into its subfolders, as the path it happened to. Listening starts the watch.
Stream<String> watchFolder(String folder) =>
    Directory(folder).watch(recursive: true).map((e) => e.path);

/// What a tool printed, and how it ended. [text] is its stdout as text, and [bytes] the raw stdout when it was asked for
/// raw. The other one is empty.
class ToolRun {
  const ToolRun(this.exitCode, this.text, this.bytes);
  final int exitCode;
  final String text;
  final List<int> bytes;
}

/// Runs [program] with [args] and waits for it. Throws if it cannot be started.
ToolRun runTool(String program, List<String> args, {bool raw = false}) {
  final r = Process.runSync(
    program,
    args,
    stdoutEncoding: raw ? null : systemEncoding,
  );
  return ToolRun(
    r.exitCode,
    raw ? '' : '${r.stdout}',
    raw ? r.stdout as List<int> : const [],
  );
}

/// As [runTool], but null when [program] cannot be started.
ToolRun? runToolIfThere(String program, List<String> args, {bool raw = false}) {
  try {
    return runTool(program, args, raw: raw);
  } on ProcessException {
    return null;
  }
}

/// Stops the calling thread for [d].
void pauseFor(Duration d) => sleep(d);

/// [data] compressed with gzip, and back again.
List<int> gzipBytes(List<int> data) => gzip.encode(data);
List<int> gunzipBytes(List<int> data) => gzip.decode(data);
