// A file or folder as the Media shelf shows it, and the words the shelf uses for the kinds of media.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';

/// A file or folder in the Media shelf's tree.
class FileNode {
  const FileNode(
    this.id,
    this.name,
    this.g, {
    this.meta = '',
    this.fixedKids = const [],
  });
  final String id, name, meta;
  final AppGlyphs g;

  /// The entries of a node that is not on the disk, such as Project. A folder on the disk is listed by the shelf's
  /// controller when it is first opened.
  final List<FileNode> fixedKids;
  bool get folder => g == AppGlyphs.folder;

  /// A file or folder on disk: its id is its full path.
  bool get disk => id.startsWith('/');
}

/// The last part of [path]: a file's or folder's own name.
String basename(String path) => path.substring(path.lastIndexOf('/') + 1);

/// The folder [path] is in.
String dirname(String path) =>
    path.lastIndexOf('/') <= 0 ? '/' : path.substring(0, path.lastIndexOf('/'));

/// The chip a file or folder is counted under, by its mark.
String kindLabelOf(FileNode n) => switch (n.g) {
  AppGlyphs.folder => 'Folders',
  AppGlyphs.comp => 'Comps',
  AppGlyphs.video => 'Video',
  AppGlyphs.image => 'Images',
  AppGlyphs.light => 'HDR',
  AppGlyphs.audio => 'Audio',
  AppGlyphs.font => 'Fonts',
  AppGlyphs.shape => '3D',
  _ => 'Docs',
};

/// The kind of media a mark stands for, or null when it is not media.
MediaType? mediaTypeOf(AppGlyphs g) => switch (g) {
  AppGlyphs.video => MediaType.video,
  AppGlyphs.image => MediaType.image,
  AppGlyphs.light => MediaType.hdr,
  AppGlyphs.audio => MediaType.audio,
  _ => null,
};

/// The kinds of media a file is, by the shelf's mark: a tag and a hue.
enum MediaType {
  video('Video', 'VID', AppGlyphs.video),
  image('Images', 'IMG', AppGlyphs.image),
  hdr('HDR', 'HDR', AppGlyphs.light),
  audio('Audio', 'AUD', AppGlyphs.audio);

  const MediaType(this.label, this.badge, this.glyph);
  final String label, badge;
  final AppGlyphs glyph;
  Color get hue => switch (this) {
    video => InspectorSkin.toneTime,
    image => WindowTokens.toneImage,
    hdr => InspectorSkin.toneTextAnim,
    audio => WindowTokens.toneAudio,
  };
}
