// The contents of the open folder in the Media shelf: tiles or rows, the in-use mark and the footer for the selected file.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart' show Motolii, MotoliiDocument, MotoliiWrites, mediaInfoOf, mediaSecondsOf;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook, Hov;
import 'package:motolii/widgets/media.dart' show MiniSlider;
import 'package:motolii/workspace/dock/dock_files.dart';
import 'package:motolii/workspace/dock/dock_files_browser.dart';
import 'package:motolii/workspace/dock/dock_files_used.dart';
import 'package:motolii/workspace/dock/dock_folder_row.dart';
import 'package:motolii/workspace/dock/dock_tags.dart';
import 'package:motolii/workspace/dock/dock_widgets.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';
import 'package:motolii/workspace/state/workspace_state.dart';

class FolderContents extends StatelessWidget {
  const FolderContents(this.c, {super.key});
  final DockCtx c;
  @override
  Widget build(BuildContext context) {
    final path = folderPathOf(c, c.mem.folder), here = path.last;
    final root = here.disk ? here : path.first; // On the disk a search stays within the open folder.
    final searching = c.query.isNotEmpty;
    final List<FileNode> items;
    if (searching) {
      final found = <FileNode>[];
      void walk(FileNode n, int depth) {
        for (final k in n.kids) {
          if (k.folder) {
            if (depth < 4) walk(k, depth + 1);
          } else if (DockTags.hit(
            c.query,
            k.name,
            DockTags.of('Media', k.id, {_kindOf(k).toLowerCase(), if (k.id.contains('.')) k.id.split('.').last.toLowerCase()}),
          )) {
            found.add(k);
          }
        }
      }

      walk(root, 0);
      items = {for (final n in found) n.id: n}.values.toList(); // A file in use appears twice, so keep one per id.
    } else {
      if (c.mem.mediaDeep) {
        // Lists the files of the folder and of every folder below it together.
        final all = <FileNode>[];
        void below(FileNode f, int depth) {
          if (f.disk && !f.listed && depth > 0) readFolder(f.id);
          for (final k in f.kids) {
            if (k.folder) {
              if (depth < 4) below(k, depth + 1);
            } else {
              all.add(k);
            }
          }
        }

        below(here, 0);
        items = [...here.kids.where((k) => k.folder), ...all];
      } else {
        items = [...here.kids.where((k) => k.folder), ...here.kids.where((k) => !k.folder)];
      }
    }
    final kinds = <String, int>{};
    for (final n in items) {
      kinds.update(_kindOf(n), (v) => v + 1, ifAbsent: () => 1);
    }
    final chip = kinds.containsKey(c.chip) ? c.chip : 'All';
    final shown = chip == 'All' ? items : items.where((n) => _kindOf(n) == chip).toList();
    final sel = c.foot(shown.where((n) => n.id == c.sel && !n.folder).firstOrNull);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FolderCrumbs(path, c, searching: searching),
        DockChips([('All', items.length), for (final e in kinds.entries) (e.key, e.value)], active: chip, onPick: c.pickChip),
        Expanded(
          child: shown.isEmpty
              ? DockEmpty(c.query)
              : ShelfGrid(
                  shelfLooks['Media']!,
                  list: c.mem.mediaList,
                  count: shown.length,
                  tile: (i) => _Tile(shown[i], c, list: c.mem.mediaList, where: searching ? (shown[i].disk ? basename(dirname(shown[i].id)) : '') : null),
                ),
        ),
        if (sel != null) _Footer(sel, c),
      ],
    );
  }
}

String _kindOf(FileNode n) => switch (n.g) {
  DockG.folder => 'Folders',
  DockG.comp => 'Comps',
  DockG.video => 'Video',
  DockG.image => 'Images',
  DockG.light => 'HDR',
  DockG.audio => 'Audio',
  DockG.font => 'Fonts',
  DockG.shape => '3D',
  _ => 'Docs',
};

MediaType? _typeOf(DockG g) => switch (g) {
  DockG.video => MediaType.video,
  DockG.image => MediaType.image,
  DockG.light => MediaType.hdr,
  DockG.audio => MediaType.audio,
  _ => null,
};

String _metaOf(FileNode n) {
  return n.folder ? (n.listed ? '${n.kids.length} items' : 'Folder') : n.meta;
}

/// The id of the layer that uses [n], or null.
String? _layerOf(FileNode n, DockCtx c) => filesUsed(c.ws)[n.id];

bool _inUse(FileNode n, DockCtx c) => _layerOf(n, c) != null;

/// A file's thumbnail if it is media, otherwise a flat tile with its kind's mark.
class _Art extends StatelessWidget {
  const _Art(this.n, {this.step = 0});
  final FileNode n;

  /// For a video, which of eight thumbnails to show.
  final int step;
  @override
  Widget build(BuildContext context) {
    if (n.disk && (n.g == DockG.video || n.g == DockG.image)) {
      // A video shows a thumbnail made by the engine and a photo is read by Flutter. Other files get a flat tile.
      final flat = Container(
        color: WsT.well,
        alignment: Alignment.center,
        child: dockBadge(n.g, Grey.g63, size: Shape.z(26)),
      );
      if (n.g == DockG.video) {
        return FutureBuilder<String?>(
          future: thumbnailAtOf?.call(n.id, step, 8),
          builder: (context, made) => made.data == null
              ? flat
              : ColoredBox(
                  color: WsT.well,
                  child: Image.file(File(made.data!), fit: BoxFit.contain, gaplessPlayback: true),
                ),
        );
      }
      final photo = RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false).hasMatch(n.id);
      return photo
          ? ColoredBox(
              color: WsT.well,
              child: Image.file(File(n.id), fit: BoxFit.contain, cacheWidth: 240, errorBuilder: (_, _, _) => flat),
            )
          : flat;
    }
    return switch (n.g) {
      DockG.font => Container(
        color: WsT.toneText,
        alignment: Alignment.center,
        child: Text(
          'Aa',
          style: T.title(WsT.onAccent).copyWith(fontSize: T.px(18), fontWeight: FontWeight.w700),
        ),
      ),
      DockG.folder => Container(
        color: WsT.well,
        alignment: Alignment.center,
        child: Glyph(DockG.folder, size: Shape.z(26), color: WsT.accentInk),
      ),
      _ => Container(
        color: WsT.well,
        alignment: Alignment.center,
        child: dockBadge(n.g, n.g == DockG.comp ? WsT.accent : Grey.g63, size: Shape.z(26)),
      ),
    };
  }
}

class _Tile extends StatefulWidget {
  const _Tile(this.n, this.c, {this.list = false, this.where});
  final FileNode n;
  final DockCtx c;
  final bool list;

  /// The folder a search result sits in.
  final String? where;
  @override
  State<_Tile> createState() => _TileState();
}

/// Holds the state of a video tile. Moving the pointer across the tile scrubs through eight thumbnails, and the button in
/// its corner plays them in a loop. The tile itself is a ShelfTile. A small tag with the file's kind shows only while the
/// pointer is over the tile or the file is selected.
class _TileState extends State<_Tile> {
  int _step = 0;
  bool _playing = false;
  Timer? _clock;

  FileNode get n => widget.n;
  bool get _film => n.disk && n.g == DockG.video;

  void _play() {
    setState(() => _playing = !_playing);
    _clock?.cancel();
    if (_playing) _clock = Timer.periodic(const Duration(milliseconds: 280), (_) => mounted ? setState(() => _step = (_step + 1) % 8) : null);
    if (!_playing) setState(() => _step = 0);
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  // A vector image is named by its file extension, so a .json file is a Lottie.
  String _badge(MediaType t) {
    if (t != MediaType.image || !n.disk || RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false).hasMatch(n.id)) return t.badge;
    final end = n.id.split('.').last.toLowerCase();
    return end == 'json' ? 'LOTTIE' : end.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c, list = widget.list, sel = c.sel == n.id || (list ? false : filesPicked.contains(n.id)), t = _typeOf(n.g);
    final can = kindOfFile(n.id).isNotEmpty, meta = widget.where == null ? _metaOf(n) : '${widget.where} · ${_metaOf(n)}';
    return ShelfTile(
      ShelfItem(n.id, n.name, label: _kindOf(n), about: meta),
      shelfLooks['Media']!,
      key: ValueKey('browser:file:${n.id}'),
      list: list,
      picked: sel,
      bold: sel || n.folder,
      ink: list ? null : (n.folder ? Grey.g91 : Grey.g76),
      says: meta,
      onTap: () => openNode(n, c),
      onApply: !list && can && !n.folder ? () => placeFile(c, n) : null, // Double-click or drag to the canvas places the file.
      onMove: _film && !_playing
          ? (at) {
              final w = (context.size?.width ?? 1) * 1.0, k = (at.dx / math.max(1, w) * 8).floor().clamp(0, 7);
              if (k != _step) setState(() => _step = k);
            }
          : null,
      onHover: (h) => h || !_film || _playing || _step == 0 ? null : setState(() => _step = 0),
      art: (_) => _Art(n, step: _step),
      over: (h) => [
        if (_film)
          Positioned(
            left: 4,
            top: 4,
            child: Hov(
              onTap: _play,
              builder: (_, _) => Container(
                width: Shape.z(16),
                height: Shape.z(16),
                decoration: BoxDecoration(color: const Color(0xAA000000), borderRadius: BorderRadius.all(Shape.r(8))),
                child: Center(
                  child: Text(
                    _playing ? '■' : '▶',
                    style: TextStyle(fontSize: Shape.z(8), height: 1, color: const Color(0xFFFFFFFF)),
                  ),
                ),
              ),
            ),
          )
        else if (t != null && (h || sel))
          Positioned(
            left: 3,
            top: 3,
            child: Chip(label: _badge(t), look: ChipLook.tag(t.hue, edge: true)),
          ),
        if (_film && (h || sel) && t != null)
          Positioned(
            right: 3,
            top: 3,
            child: Chip(label: _badge(t), look: ChipLook.tag(t.hue, edge: true)),
          ),
        if (n.folder && n.listed)
          Positioned(
            right: 4,
            bottom: 3,
            child: Text('${n.kids.length}', style: T.value(Grey.g63).copyWith(fontSize: T.px(10))),
          ),
        if (_inUse(n, c)) Positioned(right: 3, bottom: 3, child: dockBadge(DockG.link, WsT.accent, size: Shape.z(14))),
      ],
      after: (_) => [
        if (_inUse(n, c)) ...[dockBadge(DockG.link, WsT.accent, size: Shape.z(14)), SizedBox(width: Shape.s(6))],
      ],
    );
  }
}

/// Every layer that shows [file] (whole path), with the property that says so: its own file or a shape filled with it.
List<(int, String)> _showing(Motolii m, String file) => [
  for (final t in m.layers)
    for (final w in const ['file', 'fill_media'])
      if (m.word(t, w) case final f when f.isNotEmpty && m.whole(f) == file) (t, w),
];

/// Replaces what every entry of [all] shows with [file], in one undo step.
///
/// Alight Motion's Media Info does the same for the whole scene (replaceMedia in AbsentMotion's model/Media.kt,
/// which changes the file's uri and every fill of it). After Effects and Premiere Pro call it Replace Footage.
void _replaceAll(DockCtx c, List<(int, String)> all, String file) {
  final m = c.ws.inside!;
  m.later('together', number: 1);
  for (final (t, w) in all) {
    c.ws.after(m.later('say', layer: t, name: w, word: file), (done, why) {
      if (!done) c.ws.notice = 'Not replaced: $why';
    });
  }
  c.ws.after(m.later('together'), (_, _) => c.ws.reread());
}

/// The footer for the selected file: a file the engine can show is placed, a folder is opened.
class _Footer extends StatelessWidget {
  const _Footer(this.n, this.c);
  final FileNode n;
  final DockCtx c;
  @override
  Widget build(BuildContext context) {
    // A file the engine can show can be placed any number of times, each as a new layer starting at the current time.
    if (filesPicked.length > 1) {
      // Several files are selected: they are placed together.
      return DockFooter(
        title: '${filesPicked.length} files',
        meta: 'Placed one after another, in the order picked',
        action: 'Place ${filesPicked.length}',
        fresh: true,
        onAction: () => placeFiles(c, filesPicked.toList()),
      );
    }
    final layer = _layerOf(n, c), can = kindOfFile(n.id).isNotEmpty, m = c.ws.inside;
    // With a shape layer selected, an image file fills the shape, as in Alight Motion's Fill > Media.
    final shape = int.tryParse(c.ws.selected ?? ''),
        fills = m != null && shape != null && kindOfFile(n.id) == 'picture' && m.word(shape, 'kind') == 'shape' && m.word(shape, 'shape') != 'null';
    // An image or video layer is selected and a file of the same kind chosen: the layer shows that file instead and keeps
    // its position, size, keyframes and effects. This is After Effects' Replace Layer Source and Premiere Pro's Replace With Clip.
    final swaps =
        m != null &&
        shape != null &&
        !fills &&
        layer != '$shape' &&
        const {'picture', 'film'}.contains(m.word(shape, 'kind')) &&
        kindOfFile(n.id) == m.word(shape, 'kind');
    // The other layers that show the same file, which _replaceAll replaces together with this one.
    final all = swaps ? _showing(m, m.whole(m.word(shape, 'file'))) : const <(int, String)>[];
    return FutureBuilder<String>(
      // The description comes from GStreamer's discoverer, like Alight Motion's Media Info. The key gives each file its own state.
      key: ValueKey(n.id),
      future: can && m != null ? mediaInfoOf(m.libPath, n.id) : null,
      builder: (context, info) => DockFooter(
        preview: n.disk && (n.g == DockG.audio || n.g == DockG.video && (info.data ?? '×').isNotEmpty && !(info.data ?? '×').contains('×'))
            ? _Listen(n)
            : _Art(n),
        title: n.name,
        meta: c.mem.trouble[n.id] ?? [if (layer != null) 'In use', if (info.data case final i? when i.isNotEmpty) i, _metaOf(n)].join(' · '),
        action: fills
            ? 'Fill shape'
            : swaps
            ? 'Replace'
            : can
            ? 'Place'
            : 'Select',
        done: !can && layer == null,
        doneLabel: 'Folder', // Only folders and placeable files are listed, so what cannot be placed is a folder.
        fresh: can && !fills && !swaps, // Placing creates a new layer, filling or replacing acts on the selected one.
        more: all.length > 1
            ? DockHover(
                key: const ValueKey('files-replace-all'),
                onTap: () => _replaceAll(c, all, n.id),
                builder: (context, h) => Container(
                  height: Shape.z(24),
                  margin: EdgeInsets.only(right: Shape.s(6)),
                  padding: EdgeInsets.symmetric(horizontal: Shape.s(10)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: WsT.raised,
                    borderRadius: BorderRadius.all(Shape.r(WsT.radius)),
                    border: Border.all(color: h ? Grey.g95 : const Color(0x00000000)),
                  ),
                  child: Text('All ${all.length}', style: T.name(Grey.g91).copyWith(fontWeight: FontWeight.w700)),
                ),
              )
            : null,
        lasts: fills || swaps
            ? null
            : switch (kindOfFile(n.id)) {
                'picture' => _StillSeconds(c),
                'film' || 'sound' when m != null => _FilmRange(c, n.id, mediaSecondsOf(m.libPath, n.id)),
                _ => null,
              },
        onAction: () => fills
            ? c.ws.after(m.later('say', layer: shape, name: 'fill_media', word: n.id))
            : swaps
            ? c.ws.after(m.later('say', layer: shape, name: 'file', word: n.id), (done, why) => done ? c.ws.reread() : c.ws.notice = 'Not replaced: $why')
            : can
            ? placeFile(c, n)
            : c.ws.select(layer),
      ),
    );
  }
}

/// Chooses how long a still image lasts before it is placed, like the ruler under a photo in Alight Motion.
/// The default is 2 seconds, and End lasts to the end of the project. The choice is remembered for the next still image.
class _StillSeconds extends StatelessWidget {
  const _StillSeconds(this.c);
  final DockCtx c;
  @override
  Widget build(BuildContext context) {
    final at = _stillSteps.indexOf(stillSeconds), s = stillSeconds;
    Widget step(String word, int by) => DockHover(
      key: ValueKey('media-still-$word'),
      onTap: at + by < 0 || at + by >= _stillSteps.length ? null : () => c.set(() => stillSeconds = _stillSteps[at + by]),
      builder: (_, h) => Padding(
        padding: EdgeInsets.symmetric(horizontal: Shape.s(3)),
        child: Text(word == 'less' ? '−' : '+', style: T.label(h ? Grey.g95 : Grey.g63)),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('for', style: T.label(Grey.g56)),
        step('less', -1),
        Text(s == 0 ? 'End' : '${s % 1 == 0 ? s.round() : s} s', key: const ValueKey('media-still-seconds'), style: T.label(Grey.g91)),
        step('more', 1),
      ],
    );
  }
}

/// Chooses which part of a video is used before it is placed, like the band under a video in Alight Motion.
/// The label shows the range in minutes and seconds. It is remembered for that file while the shelf is open.
class _FilmRange extends StatelessWidget {
  const _FilmRange(this.c, this.file, this.seconds);
  final DockCtx c;
  final String file;
  final Future<double> seconds;
  @override
  Widget build(BuildContext context) => FutureBuilder<double>(
    future: seconds,
    builder: (context, got) {
      final len = got.data ?? 0;
      if (len <= 0) return const SizedBox.shrink(); // Without a known length the whole video is used.
      final (a, b) = filmRanges[file] ?? (0.0, 1.0);
      final w = Shape.z(84);
      String t(double f) => '${(f * len ~/ 60)}:${(f * len % 60).toStringAsFixed(1).padLeft(4, '0')}';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('use', style: T.label(Grey.g56)),
          SizedBox(width: Shape.s(4)),
          MiniSlider(
            // The whole video is a dim track, and the part used is bright between the two handles.
            key: const ValueKey('media-film-range'),
            values: [a, b],
            width: w,
            step: .001,
            gap: .01,
            height: 10,
            groove: 4,
            fill: WsT.accent,
            thumb: const Size(3, 10),
            thumbRadius: 1,
            inset: 0,
            cursor: MouseCursor.defer,
            onChanged: (v) => c.set(() => filmRanges[file] = (v[0], v[1])),
          ),
          SizedBox(width: Shape.s(4)),
          Text('${t(a)}–${t(b)}', key: const ValueKey('media-film-said'), style: T.label(Grey.g91)),
        ],
      );
    },
  );
}

const _stillSteps = [0.5, 1.0, 2.0, 3.0, 5.0, 10.0, 0.0]; // Seconds. 0 means until the end of the project.

/// Plays a sound file before it is placed, as Alight Motion does before adding a song. Clicking plays it with macOS's
/// afplay. Clicking again, or selecting another file, stops it.
class _Listen extends StatefulWidget {
  const _Listen(this.n);
  final FileNode n;
  @override
  State<_Listen> createState() => _ListenState();
}

class _ListenState extends State<_Listen> {
  Process? _playing;

  Future<void> _toggle() async {
    if (_playing case final p?) {
      p.kill();
      return setState(() => _playing = null);
    }
    final p = await Process.start('afplay', [widget.n.id]);
    if (!mounted) {
      p.kill();
      return;
    }
    setState(() => _playing = p);
    p.exitCode.then((_) => mounted && identical(_playing, p) ? setState(() => _playing = null) : null);
  }

  @override
  void didUpdateWidget(_Listen old) {
    super.didUpdateWidget(old);
    if (old.n.id != widget.n.id) _playing?.kill();
  }

  @override
  void dispose() {
    _playing?.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('media-listen'),
    onTap: _toggle,
    child: Stack(
      fit: StackFit.expand,
      children: [
        _Art(widget.n),
        Center(child: Text(_playing == null ? '▶' : '■', style: T.name(Grey.g95))),
      ],
    ),
  );
}
