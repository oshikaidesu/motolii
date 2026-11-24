// What the Media shelf asks the engine to do: place files, levels and timesheets on the canvas, and replace what a layer shows.
import 'dart:async';

import 'package:motolii/storage/text_file.dart' show readTextOrEmpty;
import 'package:motolii/workspace/dock/media/file_node.dart';
import 'package:motolii/workspace/dock/media/media_controller.dart';
import 'package:motolii/workspace/dock/media/timesheet.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/media/media_service.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

class MediaCommands {
  MediaCommands(this.c, this.media);

  final ShelfContext c;
  final MediaController media;

  /// Places [files] on the canvas as layers at the current time.
  Future<void> placeFiles(List<String> files) async {
    if (levelOf(files, media.kindOf) case final drawings?) {
      return _placeLevel(drawings);
    }
    final lengths = [
      for (final (i, s) in (await mediaLengthsOf(c.ws, files)).indexed)
        const {'image', 'picture'}.contains(media.kindOf(files[i]))
            ? media.stillSeconds
            : s,
    ]; // A still image lasts as long as chosen.
    layFilesInOrder(
      c.ws,
      files,
      lengths,
      [for (final f in files) _fitted(f)],
      refused: (f, why) => c.set(() => c.mem.trouble[f] = why),
      placed: (ids) {
        c.ws.pickMany(ids);
        media.picked.clear();
      },
    );
  }

  /// Places a numbered-drawing level as one layer. Each drawing gets a hold
  /// keyframe valued by its number (not position), so gaps don't shift others.
  void _placeLevel(List<(int, String)> drawings) {
    placeLevel(
      c.ws,
      drawings,
      c.ws.frame / WorkspaceController.fps,
      refused: (f, why) => c.set(() => c.mem.trouble[f] = why),
    );
    media.picked.clear();
  }

  /// Whether [file] is fitted to the canvas. Vector images (Lottie, SVG) are not.
  bool _fitted(String file) =>
      const {'video', 'film'}.contains(media.kindOf(file)) ||
      const {'image', 'picture'}.contains(media.kindOf(file)) &&
          RegExp(
            r'\.(jpe?g|png|webp|bmp|heic)$',
            caseSensitive: false,
          ).hasMatch(file);

  /// Places [n] on the canvas as a new layer.
  void placeFile(FileNode n) {
    if (media.kindOf(n.id) == 'timesheet') return unawaited(placeSheet(n.id));
    if (!media.placing.add(n.id)) {
      // Reading a song takes the engine a moment, so a second click in that moment counts as the same click.
      return;
    }
    final kind = media.kindOf(n.id);
    final still =
            const {'image', 'picture'}.contains(kind) && media.stillSeconds > 0,
        cut = const ['video', 'film', 'sound'].contains(kind)
            ? media.filmRanges[n.id]
            : null,
        fit = _fitted(n.id); // The engine works out what the file is without waiting, and the layer is selected once made.
    // An SVG comes in as editable path shapes ("vector") by default, or as a
    // picture ("add") when the viewer switched it (file_tile.dart). Everything
    // else is placed as a layer of its own kind.
    final verb =
        MediaController.isSvg(n.id) && !media.svgAsPicture.contains(n.id)
        ? 'vector'
        : 'add';
    placeFileLayer(
      c.ws,
      file: n.id,
      verb: verb,
      fit: fit,
      stillSeconds: still ? media.stillSeconds : null,
      cut: cut,
      settled: (done, why) {
        media.placing.remove(n.id);
        c.set(
          () => done ? c.mem.trouble.remove(n.id) : c.mem.trouble[n.id] = why,
        );
      },
    );
  }

  /// Places a timesheet: each column becomes a level, bottom first, as one undo step.
  Future<void> placeSheet(String file) async {
    final sheet = sheetOf(await readTextOrEmpty(file));
    if (sheet == null) {
      c.ws.notice = 'Not a timesheet: ${basename(file)}';
      return;
    }
    final columns = [
      for (final (name, keys) in sheet.columns)
        (
          name: name,
          keys: keys,
          drawings: levelNamed(file, name, media.kindOf),
        ),
    ];
    final ids = await layOutSheet(
      c.ws,
      from: c.ws.frame / WorkspaceController.fps,
      frames: sheet.frames,
      columns: columns,
    );
    c.ws.pickMany(ids);
    final missing = [
      for (final column in columns)
        if (column.drawings == null) column.name,
    ];
    final told = [
      if (missing.isNotEmpty)
        'no drawings named ${missing.join(', ')} beside it',
      if (sheet.unread.isNotEmpty) 'not read: ${sheet.unread.join(', ')}',
    ];
    c.ws.notice =
        'Placed ${ids.length} of ${sheet.columns.length} columns of ${basename(file)}${told.isEmpty ? '' : ': ${told.join('; ')}'}';
  }

  /// Replaces every entry in [all] with [file], in one undo step.
  void replaceAll(List<(int, String)> all, String file) => replaceSourcesIn(
    c.ws,
    all,
    file,
    refused: (why) => c.ws.notice = 'Not replaced: $why',
  );

  void fillShape(int shape, String file) => fillShapeWith(c.ws, shape, file);

  /// Replaces [layer]'s source file, keeping position, keyframes and effects.
  void replaceSource(int layer, String file) => replaceLayerSource(
    c.ws,
    layer,
    file,
    refused: (why) => c.ws.notice = 'Not replaced: $why',
  );
}
