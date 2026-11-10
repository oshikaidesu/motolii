// The footer of the Media shelf for the picked file: what it is, how much of it is placed, and its one action.
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart'
    show Motolii, mediaInfoOf, mediaSecondsOf;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/media.dart' show MiniSlider;
import 'package:motolii/workspace/dock/common/shelf_footer.dart';
import 'package:motolii/workspace/dock/media/file_node.dart';
import 'package:motolii/workspace/dock/media/file_tile.dart';
import 'package:motolii/workspace/dock/media/media_commands.dart';
import 'package:motolii/workspace/dock/media/media_controller.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

/// Every layer that shows [file] (whole path), with the property that says so: its own file or a shape filled with it.
List<(int, String)> _showing(Motolii m, String file) => [
  for (final t in m.layers)
    for (final w in const ['file', 'fill_media'])
      if (m.word(t, w) case final f when f.isNotEmpty && m.whole(f) == file)
        (t, w),
];

/// The footer for the selected file: a file the engine can show is placed, a folder is opened.
class FileFooter extends StatelessWidget {
  const FileFooter(this.n, this.c, this.media, {super.key});
  final FileNode n;
  final ShelfContext c;

  /// What the shelf keeps between builds: the files picked, and the length and range chosen for the next file.
  final MediaController media;
  @override
  Widget build(BuildContext context) {
    final commands = MediaCommands(c, media);
    // A file the engine can show can be placed any number of times, each as a new layer starting at the current time.
    if (media.picked.length > 1) {
      // Several files are selected: they are placed together.
      return ShelfFooter(
        title: '${media.picked.length} files',
        meta: 'Placed one after another, in the order picked',
        action: 'Place ${media.picked.length}',
        fresh: true,
        onAction: () => commands.placeFiles(media.picked.toList()),
      );
    }
    final layer = media.filesUsed[n.id],
        can = media.kindOf(n.id).isNotEmpty,
        m = c.ws.inside;
    // With a shape layer selected, an image file fills the shape, as in Alight Motion's Fill > Media.
    final shape = int.tryParse(c.ws.selected ?? ''),
        fills =
            m != null &&
            shape != null &&
            media.kindOf(n.id) == 'picture' &&
            m.word(shape, 'kind') == 'shape' &&
            m.word(shape, 'shape') != 'null';
    // An image or video layer is selected and a file of the same kind chosen: the layer shows that file instead and keeps
    // its position, size, keyframes and effects. This is After Effects' Replace Layer Source and Premiere Pro's Replace With Clip.
    final swaps =
        m != null &&
        shape != null &&
        !fills &&
        layer != '$shape' &&
        const {'picture', 'film'}.contains(m.word(shape, 'kind')) &&
        media.kindOf(n.id) == m.word(shape, 'kind');
    // The other layers that show the same file, which MediaCommands.replaceAll replaces together with this one.
    final all = swaps
        ? _showing(m, m.whole(m.word(shape, 'file')))
        : const <(int, String)>[];
    return FutureBuilder<String>(
      // The description comes from GStreamer's discoverer, like Alight Motion's Media Info. The key gives each file its own state.
      key: ValueKey(n.id),
      future: can && m != null ? mediaInfoOf(m.libPath, n.id) : null,
      builder: (context, info) => ShelfFooter(
        preview:
            n.disk &&
                (n.g == AppGlyphs.audio ||
                    n.g == AppGlyphs.video &&
                        (info.data ?? '×').isNotEmpty &&
                        !(info.data ?? '×').contains('×'))
            ? _Listen(n, media)
            : FileArt(n, media),
        title: n.name,
        meta:
            c.mem.trouble[n.id] ??
            [
              if (layer != null) 'In use',
              if (info.data case final i? when i.isNotEmpty) i,
              media.metaOf(n),
            ].join(' · '),
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
                onTap: () => commands.replaceAll(all, n.id),
                builder: (context, h) => Container(
                  height: Shape.z(24),
                  margin: EdgeInsets.only(right: Shape.s(6)),
                  padding: EdgeInsets.symmetric(horizontal: Shape.s(10)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: WindowTokens.raised,
                    borderRadius: BorderRadius.all(
                      Shape.r(WindowTokens.radius),
                    ),
                    border: Border.all(
                      color: h ? Grey.g95 : const Color(0x00000000),
                    ),
                  ),
                  child: Text(
                    'All ${all.length}',
                    style: TextStyles.name(Grey.g91)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              )
            : null,
        lasts: fills || swaps
            ? null
            : switch (media.kindOf(n.id)) {
                'picture' => _StillSeconds(c, media),
                'film' || 'sound' when m != null => _FilmRange(
                  c,
                  media,
                  n.id,
                  mediaSecondsOf(m.libPath, n.id),
                ),
                _ => null,
              },
        onAction: () => fills
            ? commands.fillShape(shape, n.id)
            : swaps
            ? commands.replaceSource(shape, n.id)
            : can
            ? commands.placeFile(n)
            : c.ws.select(layer),
      ),
    );
  }
}

/// Chooses how long a still image lasts before it is placed, like the ruler under a photo in Alight Motion.
/// The default is 2 seconds, and End lasts to the end of the project. The choice is remembered for the next still image.
class _StillSeconds extends StatelessWidget {
  const _StillSeconds(this.c, this.media);
  final ShelfContext c;
  final MediaController media;
  @override
  Widget build(BuildContext context) {
    final at = _stillSteps.indexOf(media.stillSeconds), s = media.stillSeconds;
    Widget step(String word, int by) => DockHover(
      key: ValueKey('media-still-$word'),
      onTap: at + by < 0 || at + by >= _stillSteps.length
          ? null
          : () => c.set(() => media.stillSeconds = _stillSteps[at + by]),
      builder: (_, h) => Padding(
        padding: EdgeInsets.symmetric(horizontal: Shape.s(3)),
        child: Text(
          word == 'less' ? '−' : '+',
          style: TextStyles.label(h ? Grey.g95 : Grey.g63),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('for', style: TextStyles.label(Grey.g56)),
        step('less', -1),
        Text(
          s == 0 ? 'End' : '${s % 1 == 0 ? s.round() : s} s',
          key: const ValueKey('media-still-seconds'),
          style: TextStyles.label(Grey.g91),
        ),
        step('more', 1),
      ],
    );
  }
}

/// Chooses which part of a video is used before it is placed, like the band under a video in Alight Motion.
/// The label shows the range in minutes and seconds. It is remembered for that file while the shelf is open.
class _FilmRange extends StatelessWidget {
  const _FilmRange(this.c, this.media, this.file, this.seconds);
  final ShelfContext c;
  final MediaController media;
  final String file;
  final Future<double> seconds;
  @override
  Widget build(BuildContext context) => FutureBuilder<double>(
    future: seconds,
    builder: (context, got) {
      final len = got.data ?? 0;
      if (len <= 0) return const SizedBox.shrink(); // Without a known length the whole video is used.
      final (a, b) = media.filmRanges[file] ?? (0.0, 1.0);
      final w = Shape.z(84);
      String t(double f) =>
          '${(f * len ~/ 60)}:${(f * len % 60).toStringAsFixed(1).padLeft(4, '0')}';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('use', style: TextStyles.label(Grey.g56)),
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
            fill: WindowTokens.accent,
            thumb: const Size(3, 10),
            thumbRadius: 1,
            inset: 0,
            cursor: MouseCursor.defer,
            onChanged: (v) =>
                c.set(() => media.filmRanges[file] = (v[0], v[1])),
          ),
          SizedBox(width: Shape.s(4)),
          Text(
            '${t(a)}–${t(b)}',
            key: const ValueKey('media-film-said'),
            style: TextStyles.label(Grey.g91),
          ),
        ],
      );
    },
  );
}

const _stillSteps = [
  0.5,
  1.0,
  2.0,
  3.0,
  5.0,
  10.0,
  0.0,
]; // Seconds. 0 means until the end of the project.

/// Plays a sound file before it is placed, as Alight Motion does before adding a song. Clicking plays it with macOS's
/// afplay. Clicking again, or selecting another file, stops it.
class _Listen extends StatefulWidget {
  const _Listen(this.n, this.media);
  final FileNode n;
  final MediaController media;
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
    p.exitCode.then(
      (_) => mounted && identical(_playing, p)
          ? setState(() => _playing = null)
          : null,
    );
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
        FileArt(widget.n, widget.media),
        Center(
          child: Text(
            _playing == null ? '▶' : '■',
            style: TextStyles.name(Grey.g95),
          ),
        ),
      ],
    ),
  );
}
