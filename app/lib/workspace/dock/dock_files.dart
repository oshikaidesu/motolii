// The Media shelf, in the style of AEViewer 2: one browser for the project's files and media.
// A folder tree (locations, then folders only) sits beside or above the open folder's contents, shown as thumbnails or a list.
// Wide: tree | contents. Narrow: the tree band (its height set by dragging) over the contents.
//
// Reads folders from the disk, once each and off the UI thread, and describes a file: its name, folder, size, kind and media type.
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';

/// A file or folder in the Media shelf's tree.
class FileNode {
  // ignore: prefer_initializing_formals
  const FileNode(this.id, this.name, this.g, {this.meta = '', List<FileNode> kids = const []}) : _kids = kids;
  final String id, name, meta;
  final DockG g;
  final List<FileNode> _kids;
  bool get folder => g == DockG.folder;

  /// A file or folder on disk: its id is its full path. A folder's contents are read when it is first opened (see [listed]).
  bool get disk => id.startsWith('/');
  bool get listed => !disk || _lists.containsKey(id);
  List<FileNode> get kids => disk && folder ? _listed(id) : _kids;
}

// Files on disk.

/// The kind of layer a file makes, as the engine says it. An empty string means none, so the file is not shown.
/// The shelf chooses the icon for each kind.
String Function(String file) kindOfFile = (_) => '';
Future<String?> Function(String film, int step, int steps)? thumbnailAtOf;
DockG? glyphOf(String file) => switch (kindOfFile(file)) {
  'film' => DockG.video,
  // Songs have a tab of their own, as in Alight Motion's Add, where Audio is apart from Media (docs/internal/reports/alight_motion/alight_ui.md).
  'sound' => DockG.audio,
  'picture' => DockG.image,
  'solid' => DockG.shape,
  'text' => DockG.font,
  'timesheet' => DockG.comp, // Its columns are put together by placeSheet.
  _ => null,
};

String basename(String path) => path.substring(path.lastIndexOf('/') + 1);

String dirname(String path) => path.lastIndexOf('/') <= 0 ? '/' : path.substring(0, path.lastIndexOf('/'));

String _size(int bytes) => bytes >= 1 << 20 ? '${(bytes / (1 << 20)).toStringAsFixed(1)} MB' : '${(bytes / 1024).ceil()} KB';

final _lists = <String, List<FileNode>>{};

final _reading = <String>{};

/// Goes up each time a folder of the disk has been read: the shelf then looks again.
final dockRead = ValueNotifier<int>(0);

/// Returns the entries of the folder [path] as last read and starts reading it if needed, without waiting for the disk.
/// A folder the system asks permission for is empty until the user grants it.
List<FileNode> _listed(String path) {
  if (!_lists.containsKey(path)) readFolder(path);
  return _lists[path] ?? const [];
}

void readFolder(String path) {
  if (!_reading.add(path)) return;
  _lists.putIfAbsent(path, () => const []);
  () async {
    final out = <FileNode>[];
    try {
      await for (final e in Directory(path).list()) {
        final name = basename(e.path);
        if (name.startsWith('.')) continue;
        if (e is Directory) {
          out.add(FileNode(e.path, name, DockG.folder));
        } else if (glyphOf(name) case final g?) {
          out.add(FileNode(e.path, name, g, meta: '${name.substring(name.lastIndexOf('.') + 1).toUpperCase()} · ${_size((await e.stat()).size)}'));
        }
      }
    } on FileSystemException {
      out.clear();
    }
    _lists[path] = out..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _reading.remove(path);
    dockRead.value++;
  }();
}

/// The kinds of media a file is, by the shelf's mark: a tag and a hue.
enum MediaType {
  video('Video', 'VID', DockG.video),
  image('Images', 'IMG', DockG.image),
  hdr('HDR', 'HDR', DockG.light),
  audio('Audio', 'AUD', DockG.audio);

  const MediaType(this.label, this.badge, this.glyph);
  final String label, badge;
  final DockG glyph;
  Color get hue => switch (this) {
    video => Pop.toneTime,
    image => WsT.toneImage,
    hdr => Pop.toneTextAnim,
    audio => WsT.toneAudio,
  };
}
