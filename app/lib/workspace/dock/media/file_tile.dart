// One file or folder in the Media shelf's contents: its picture and its tile.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook, Pressable;
import 'package:motolii/workspace/dock/media/file_node.dart';
import 'package:motolii/workspace/dock/media/folder_navigation.dart';
import 'package:motolii/workspace/dock/media/media_commands.dart';
import 'package:motolii/workspace/dock/media/media_controller.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';

/// A file's thumbnail if it is media, otherwise a flat tile with its kind's mark.
class FileArt extends StatelessWidget {
  const FileArt(this.n, this.media, {super.key, this.step = 0});
  final FileNode n;

  /// Asks the engine for a video's thumbnails.
  final MediaController media;

  /// For a video, which of eight thumbnails to show.
  final int step;
  @override
  Widget build(BuildContext context) {
    if (n.disk && (n.g == AppGlyphs.video || n.g == AppGlyphs.image)) {
      // A video shows a thumbnail made by the engine and a photo is read by Flutter. Other files get a flat tile.
      final flat = Container(
        color: WindowTokens.well,
        alignment: Alignment.center,
        child: dockBadge(n.g, Grey.g63, size: Shape.z(26)),
      );
      if (n.g == AppGlyphs.video) {
        return FutureBuilder<String?>(
          future: media.thumbnailAt(n.id, step, 8),
          builder: (context, made) => made.data == null
              ? flat
              : ColoredBox(
                  color: WindowTokens.well,
                  child: Image.file(
                    File(made.data!),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
        );
      }
      final photo = RegExp(
        r'\.(png|jpe?g|webp)$',
        caseSensitive: false,
      ).hasMatch(n.id);
      return photo
          ? ColoredBox(
              color: WindowTokens.well,
              child: Image.file(
                File(n.id),
                fit: BoxFit.contain,
                cacheWidth: 240,
                errorBuilder: (_, _, _) => flat,
              ),
            )
          : flat;
    }
    return switch (n.g) {
      AppGlyphs.font => Container(
        color: WindowTokens.toneText,
        alignment: Alignment.center,
        child: Text(
          'Aa',
          style: TextStyles.title(
            WindowTokens.onAccent,
          ).copyWith(fontSize: TextStyles.px(18), fontWeight: FontWeight.w700),
        ),
      ),
      AppGlyphs.folder => Container(
        color: WindowTokens.well,
        alignment: Alignment.center,
        child: Glyph(
          AppGlyphs.folder,
          size: Shape.z(26),
          color: WindowTokens.accentInk,
        ),
      ),
      _ => Container(
        color: WindowTokens.well,
        alignment: Alignment.center,
        child: dockBadge(
          n.g,
          n.g == AppGlyphs.comp ? WindowTokens.accent : Grey.g63,
          size: Shape.z(26),
        ),
      ),
    };
  }
}

/// One file or folder of the open folder, as a tile or as a row of the list.
class FileTile extends StatefulWidget {
  const FileTile(
    this.n,
    this.c,
    this.media, {
    super.key,
    this.list = false,
    this.where,
  });
  final FileNode n;
  final ShelfContext c;

  /// What the shelf keeps between builds: the files picked, the folders read.
  final MediaController media;
  final bool list;

  /// The folder a search result sits in.
  final String? where;
  @override
  State<FileTile> createState() => _FileTileState();
}

/// Holds the state of a video tile. Moving the pointer across the tile scrubs through eight thumbnails, and the button in
/// its corner plays them in a loop. The tile itself is a ShelfTile. A small tag with the file's kind shows only while the
/// pointer is over the tile or the file is selected.
class _FileTileState extends State<FileTile> {
  int _step = 0;
  bool _playing = false;
  Timer? _clock;

  FileNode get n => widget.n;
  bool get _film => n.disk && n.g == AppGlyphs.video;

  void _play() {
    setState(() => _playing = !_playing);
    _clock?.cancel();
    if (_playing) {
      _clock = Timer.periodic(
        const Duration(milliseconds: 280),
        (_) => mounted ? setState(() => _step = (_step + 1) % 8) : null,
      );
    }
    if (!_playing) setState(() => _step = 0);
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  // A vector image is named by its file extension, so a .json file is a Lottie.
  String _badge(MediaType t) {
    if (t != MediaType.image ||
        !n.disk ||
        RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false).hasMatch(n.id)) {
      return t.badge;
    }
    final end = n.id.split('.').last.toLowerCase();
    return end == 'json' ? 'LOTTIE' : end.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c,
        media = widget.media,
        list = widget.list,
        sel = c.sel == n.id || (list ? false : media.picked.contains(n.id)),
        t = mediaTypeOf(n.g);
    final can = media.kindOf(n.id).isNotEmpty,
        meta = widget.where == null
            ? media.metaOf(n)
            : '${widget.where} · ${media.metaOf(n)}';
    return ShelfTile(
      ShelfItem(n.id, n.name, label: kindLabelOf(n), about: meta),
      shelfLooks['Media']!,
      key: ValueKey('browser:file:${n.id}'),
      list: list,
      picked: sel,
      bold: sel || n.folder,
      ink: list ? null : (n.folder ? Grey.g91 : Grey.g76),
      says: meta,
      onTap: () => openNode(n, c, media),
      onApply: !list && can && !n.folder
          ? () => MediaCommands(c, media).placeFile(n)
          : null, // Double-click or drag to the canvas places the file.
      onMove: _film && !_playing
          ? (at) {
              final w = (context.size?.width ?? 1) * 1.0,
                  k = (at.dx / math.max(1, w) * 8).floor().clamp(0, 7);
              if (k != _step) setState(() => _step = k);
            }
          : null,
      onHover: (h) => h || !_film || _playing || _step == 0
          ? null
          : setState(() => _step = 0),
      art: (_) => FileArt(n, media, step: _step),
      over: (h) => [
        if (_film)
          Positioned(
            left: 4,
            top: 4,
            child: Pressable(
              onTap: _play,
              builder: (_, _) => Container(
                width: Shape.z(16),
                height: Shape.z(16),
                decoration: BoxDecoration(
                  color: const Color(0xAA000000),
                  borderRadius: BorderRadius.all(Shape.r(8)),
                ),
                child: Center(
                  child: Text(
                    _playing ? '■' : '▶',
                    style: TextStyle(
                      fontSize: Shape.z(8),
                      height: 1,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            ),
          )
        else if (t != null && (h || sel))
          Positioned(
            left: 3,
            top: 3,
            child: Chip(
              label: _badge(t),
              look: ChipLook.tag(t.hue, edge: true),
            ),
          ),
        if (_film && (h || sel) && t != null)
          Positioned(
            right: 3,
            top: 3,
            child: Chip(
              label: _badge(t),
              look: ChipLook.tag(t.hue, edge: true),
            ),
          ),
        if (n.folder && media.listed(n))
          Positioned(
            right: 4,
            bottom: 3,
            child: Text(
              '${media.kidsOf(n).length}',
              style: TextStyles.value(Grey.g63)
                  .copyWith(fontSize: TextStyles.px(10)),
            ),
          ),
        if (media.filesUsed[n.id] != null)
          Positioned(
            right: 3,
            bottom: 3,
            child: dockBadge(
              AppGlyphs.link,
              WindowTokens.accent,
              size: Shape.z(14),
            ),
          ),
      ],
      after: (_) => [
        if (media.filesUsed[n.id] != null) ...[
          dockBadge(AppGlyphs.link, WindowTokens.accent, size: Shape.z(14)),
          SizedBox(width: Shape.s(6)),
        ],
      ],
    );
  }
}
