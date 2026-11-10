// The Media shelf, in the style of AEViewer 2: one browser for the project's files and media.
// A folder tree (locations, then folders only) sits beside or above the open folder's contents, shown as thumbnails or a list.
// Wide: tree | contents. Narrow: the tree band (its height set by dragging) over the contents.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../bridge/motolii.dart' show Motolii, mediaInfoOf, mediaSecondsOf;
import '../../inspector/inspector_parts.dart' show Pop;
import '../../skin/tokens.dart';
import 'dock_resizable.dart';
import 'dock_glyphs.dart';
import 'dock_widgets.dart';
import 'dock_tags.dart';
import '../shelf/shelf_tile.dart';
import '../state/state.dart';
import '../../widgets/controls.dart' show Chip, ChipLook, Hov;
import '../../widgets/media.dart' show MiniSlider;
part 'dock_files_read.dart';
part 'dock_files_used.dart';
part 'dock_files_sheet.dart';
part 'dock_files_browser.dart';
part 'dock_files_contents.dart';

/// The tree band's height when the shelf is narrow. A double-click on its grip resets to this.
const dockTreeHeight = 132.0;

/// From this shelf width the tree stands beside the contents instead of above them.
const _wide = 440.0;

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
String Function(String file) _kindOfFile = (_) => '';
Future<String?> Function(String film, int step, int steps)? _thumbnailAtOf;
DockG? _glyphOf(String file) => switch (_kindOfFile(file)) {
  'film' => DockG.video,
  // Songs have a tab of their own, as in Alight Motion's Add, where Audio is apart from Media (docs/internal/reports/alight_motion/alight_ui.md).
  'sound' => DockG.audio,
  'picture' => DockG.image,
  'solid' => DockG.shape,
  'text' => DockG.font,
  'timesheet' => DockG.comp, // Its columns are put together by _placeSheet.
  _ => null,
};
