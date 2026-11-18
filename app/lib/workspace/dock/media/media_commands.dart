// What the Media shelf asks the engine to do: place files, levels and timesheets on the canvas, and replace what a layer shows.
import 'dart:async';

import 'package:motolii/storage/text_file.dart' show readTextOrEmpty;
import 'package:motolii/workspace/dock/media/file_node.dart';
import 'package:motolii/workspace/dock/media/media_controller.dart';
import 'package:motolii/workspace/dock/media/timesheet.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/media/media_service.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// What the Media shelf asks the engine to do: place files on the canvas as new layers, and replace the file a layer
/// shows. The engine calls are in state (media_service.dart).
class MediaCommands {
  /// [c] is the shelf as it is built now, and [media] what the shelf keeps between builds.
  MediaCommands(this.c, this.media);

  /// The shelf's context: the project, the shelf's memory and a way to rebuild the shelf.
  final ShelfContext c;

  /// The files picked, and the length and range chosen for the next file.
  final MediaController media;

  /// Places the selected [files] on the canvas, each as a new layer starting at the current time, and selects the new layers.
  /// A video lasts as long as it plays, using the length from the discoverer. A video of unknown length lasts to the
  /// end of the project. A still image lasts as long as chosen under it, and End stacks the stills together.
  /// If every file has a length, the layers are laid one after another in the order selected with the engine's
  /// Stagger
  Future<void> placeFiles(List<String> files) async {
    if (levelOf(files, media.kindOf) case final drawings?) {
      return _placeLevel(drawings);
    }
    final lengths = [
      for (final (i, s) in (await mediaLengthsOf(c.ws, files)).indexed)
        media.kindOf(files[i]) == 'picture' ? media.stillSeconds : s,
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

  /// Places a level, OpenToonz's term and CLIP STUDIO's animation folder, on the canvas as one layer.
  /// The lowest drawing is the layer's file and is fitted to the canvas. The layer's Drawing property gets one hold
  /// keyframe per drawing, valued with the drawing's own number rather than its position, so a drawing added in between
  /// or a gap does not move the others. A hold lasts until the next keyframe, as in a timesheet (XDTS frames, read by
  /// OpenToonz's xdtsio.cpp). Each keyframe sits at 24 frames per second from the lowest number, as DiTiS reads a
  /// timesheet. Drawings numbered 1, 3, 5 are therefore held across the gaps, which After Effects users ask for on the
  /// forum and After Effects lacks. The timing can then be changed by moving the keyframes.
  void _placeLevel(List<(int, String)> drawings) {
    placeLevel(
      c.ws,
      drawings,
      c.ws.frame / WorkspaceController.fps,
      refused: (f, why) => c.set(() => c.mem.trouble[f] = why),
    );
    media.picked.clear();
  }

  /// Whether [file] is fitted inside the canvas and centred
  /// videoLayer in AbsentMotion's editor/EditorActions.kt and VideoActions.kt). Vector images such as Lottie and SVG
  /// are placed as they are.
  bool _fitted(String file) =>
      media.kindOf(file) == 'film' ||
      media.kindOf(file) == 'picture' &&
          RegExp(
            r'\.(jpe?g|png|webp|bmp|heic)$',
            caseSensitive: false,
          ).hasMatch(file);

  /// Places the file [n] on the canvas as a new layer and selects it. If it fails, the footer of the shelf says why.
  void placeFile(FileNode n) {
    if (media.kindOf(n.id) == 'timesheet') return unawaited(placeSheet(n.id));
    if (!media.placing.add(n.id)) {
      // Reading a song takes the engine a moment, so a second click in that moment counts as the same click.
      return;
    }
    final still = media.kindOf(n.id) == 'picture' && media.stillSeconds > 0,
        cut = const ['film', 'sound'].contains(media.kindOf(n.id))
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

  /// Places the timesheet [file] on the canvas, starting at the current time.
  /// Each column becomes a level as [_placeLevel] makes one, named after the column as OpenToonz does, and as long as
  /// the sheet. Each change gets a hold keyframe on the level's Drawing property at 24 frames per second, as DiTiS reads
  /// a sheet. The bottom column comes first, everything is one undo step, and the new layers are selected.
  /// Missing drawings and unsupported values are reported in the notice.
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

  /// Replaces what every entry of [all] shows with [file], in one undo step.
  /// Alight Motion's Media Info does the same for the whole scene (replaceMedia in AbsentMotion's model/Media.kt,
  /// which changes the file's uri and every fill of it). After Effects and Premiere Pro call it Replace Footage.
  void replaceAll(List<(int, String)> all, String file) => replaceSourcesIn(
    c.ws,
    all,
    file,
    refused: (why) => c.ws.notice = 'Not replaced: $why',
  );

  /// Fills the shape layer [shape] with the image [file]
  void fillShape(int shape, String file) => fillShapeWith(c.ws, shape, file);

  /// Makes the image or video layer [layer] show [file] instead, keeping its position, size, keyframes and effects.
  void replaceSource(int layer, String file) => replaceLayerSource(
    c.ws,
    layer,
    file,
    refused: (why) => c.ws.notice = 'Not replaced: $why',
  );
}
