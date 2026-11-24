// What the Media shelf keeps while the window is open: the folders it has read, what the project uses, and what is picked.
import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:motolii/storage/folder_entries.dart' show entriesKept;
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/workspace/dock/common/shelf_tags.dart';
import 'package:motolii/workspace/dock/media/file_node.dart';
import 'package:motolii/workspace/state/media/media_service.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// What the Media shelf keeps while the window is open: the folders read from the disk, the files the project uses,
/// the files picked together, and how much of the next file is placed.
/// Folders are read once each and off the UI thread.
class MediaController {
  /// [reads] is the counter the shelves listen to; it goes up each time a folder has been read. [tags] is the
  /// window's tags, which a search of the shelf matches.
  MediaController(this._ws, this.reads, this.tags);
  final WorkspaceController _ws;

  /// Goes up each time a folder of the disk has been read: the shelf then looks again.
  final ValueNotifier<int> reads;

  /// The tags of the files, which a search matches beside their names.
  final ShelfTags tags;

  /// The kind of layer a file makes, as the engine says it. An empty string means none, so the file is not shown.
  /// The shelf chooses the icon for each kind.
  String kindOf(String file) =>
      // CLIP STUDIO's and OpenToonz's timesheet is not a layer kind in the engine, but its columns are.
      file.toLowerCase().endsWith('.xdts')
      ? 'timesheet'
      : mediaKindOf(_ws, file);

  /// The file of thumbnail [step] of [steps] of the video [film], made by the engine.
  Future<String?> thumbnailAt(String film, int step, int steps) =>
      mediaThumbnail(_ws, film, step, steps);

  /// The mark of the kind of layer [file] makes, or null when it makes none.
  AppGlyphs? glyphOf(String file) => switch (kindOf(file)) {
    'video' || 'film' => AppGlyphs.video,
    // Songs have a tab of their own Add, where Audio is apart from Media (docs/design/alight_motion_ui.md).
    'sound' => AppGlyphs.audio,
    'image' || 'picture' => AppGlyphs.image,
    'solid' => AppGlyphs.shape,
    'text' => AppGlyphs.font,
    // Its columns are put together by MediaCommands.placeSheet.
    'timesheet' => AppGlyphs.comp,
    _ => null,
  };

  // Files on disk.

  final _lists = <String, List<FileNode>>{};

  final _reading = <String>{};

  /// Whether the entries of [n] are known. A folder on disk is listed once it has been read (see [kidsOf]).
  bool listed(FileNode n) => !n.disk || _lists.containsKey(n.id);

  /// The entries of [n]. A folder's contents are read when it is first opened (see [listed]).
  List<FileNode> kidsOf(FileNode n) =>
      n.disk && n.folder ? _listed(n.id) : n.fixedKids;

  /// Returns the entries of the folder [path] as last read and starts reading it if needed, without waiting for the disk.
  /// A folder the system asks permission for is empty until the user grants it.
  List<FileNode> _listed(String path) {
    if (!_lists.containsKey(path)) readFolder(path);
    return _lists[path] ?? const [];
  }

  /// Reads the folder [path] off the UI thread, unless it is being read already, and tells [reads] when it is done.
  void readFolder(String path) {
    if (!_reading.add(path)) return;
    _lists.putIfAbsent(path, () => const []);
    () async {
      final out = await entriesKept<FileNode>(path, (e, size) async {
        final name = basename(e.path);
        if (name.startsWith('.')) return null;
        if (e.folder) return FileNode(e.path, name, AppGlyphs.folder);
        if (glyphOf(name) case final g?) {
          return FileNode(
            e.path,
            name,
            g,
            meta:
                '${name.substring(name.lastIndexOf('.') + 1).toUpperCase()} · ${_size(await size())}',
          );
        }
        return null;
      });
      _lists[path] = out
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _reading.remove(path);
      reads.value++;
    }();
  }

  /// The line of facts under a file or folder: a folder's item count, a file's type and size.
  String metaOf(FileNode n) {
    return n.folder
        ? (listed(n) ? '${kidsOf(n).length} items' : 'Folder')
        : n.meta;
  }

  var _usedNow = <String, int>{};

  int? _usedRev;

  /// Maps each file the project uses, by whole path, to the layer that uses it. If several layers use a file, the front one wins.
  Map<String, int> get filesUsed {
    final ws = _ws;
    if (_usedRev == ws.rev) return _usedNow;
    _usedRev = ws.rev;
    return _usedNow = filesOfLayers(ws);
  }

  /// The files selected together with Cmd and click, as Finder adds to a selection. They are placed together.
  final picked = <String>{};

  /// The part of each film or sound that is placed, by file: the fractions of its length where it begins and ends.
  final filmRanges = <String, (double, double)>{};

  /// How many seconds a still image lasts when it is placed. 0 lasts to the end of the project.
  var stillSeconds = 2.0;

  /// The files being placed whose layer the engine has not made yet.
  final placing = <String>{};

  /// The SVG files the viewer switched to come in as a picture. An SVG not in
  /// the set comes in as editable path shapes, the default, so its points can
  /// be moved and an expression can drive them. The file tile shows which it is
  /// and switches it (file_tile.dart); MediaCommands.placeFile reads it.
  final svgAsPicture = <String>{};

  /// Whether [file] is an SVG, so it can come in as path shapes or a picture.
  static bool isSvg(String file) => file.toLowerCase().endsWith('.svg');
}

String _size(int bytes) => bytes >= 1 << 20
    ? '${(bytes / (1 << 20)).toStringAsFixed(1)} MB'
    : '${(bytes / 1024).ceil()} KB';
