// What the Media shelf asks the engine to do: place files, levels and timesheets on the canvas, and replace what a layer shows.
import 'dart:async';
import 'dart:io';

import 'package:motolii/bridge/motolii.dart' show mediaSecondsOf;
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/dock/media/file_node.dart';
import 'package:motolii/workspace/dock/media/media_controller.dart';
import 'package:motolii/workspace/dock/media/timesheet.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// What the Media shelf asks the engine to do: place files on the canvas as new layers, and replace the file a layer
/// shows. Every call to the engine the shelf makes is a method here.
class MediaCommands {
  /// [c] is the shelf as it is built now, and [media] what the shelf keeps between builds.
  MediaCommands(this.c, this.media);

  /// The shelf's context: the project, the shelf's memory and a way to rebuild the shelf.
  final ShelfContext c;

  /// The files picked, and the length and range chosen for the next file.
  final MediaController media;

  /// Places the selected [files] on the canvas, each as a new layer starting at the current time, and selects the new layers.
  ///
  /// A video lasts as long as it plays, using the length from the discoverer. A video of unknown length lasts to the
  /// end of the project. A still image lasts as long as chosen under it, and End stacks the stills together.
  /// If every file has a length, the layers are laid one after another in the order selected with the engine's
  /// Stagger, as Alight Motion does when adding several files.
  Future<void> placeFiles(List<String> files) async {
    if (levelOf(files, media.kindOf) case final drawings?) {
      return _placeLevel(drawings);
    }
    final m = c.ws.inside!;
    final lengths = [
      for (final (i, s) in (await Future.wait([
        for (final f in files) mediaSecondsOf(m.libPath, f),
      ])).indexed)
        media.kindOf(files[i]) == 'picture' ? media.stillSeconds : s,
    ]; // A still image lasts as long as chosen.
    m.later('together', number: 1);
    final made = <Future<int>>[];
    for (final (i, f) in files.indexed) {
      final asked = Completer<int>();
      c.ws.after(m.later('add', word: f), (done, why) {
        if (done) return;
        c.set(() => c.mem.trouble[f] = why);
        asked.complete(0);
      }, asked.complete);
      if (_fitted(f)) m.later('fit', layer: -1, word: 'fit');
      if (lengths[i] > 0) {
        m.later(
          'set',
          layer: -1,
          name: 'duration',
          number: lengths[i],
        ); // Applies to the layer just added.
      }
      made.add(asked.future);
    }
    c.ws.after(m.later('together'));
    Future.wait(made).then((ids) {
      final all = [
        for (final i in ids)
          if (i > 0) i,
      ];
      if (all.length > 1 && lengths.every((s) => s > 0)) {
        c.ws.after(
          m.later('time_align', word: 'stagger ${all.join(' ')}'),
          (_, _) => c.ws.reread(),
        );
      }
      c.ws.pickMany([for (final i in all) '$i']);
      media.picked.clear();
    });
  }

  /// Places a level, OpenToonz's term and CLIP STUDIO's animation folder, on the canvas as one layer.
  ///
  /// The lowest drawing is the layer's file and is fitted to the canvas. The layer's Drawing property gets one hold
  /// keyframe per drawing, valued with the drawing's own number rather than its position, so a drawing added in between
  /// or a gap does not move the others. A hold lasts until the next keyframe, as in a timesheet (XDTS frames, read by
  /// OpenToonz's xdtsio.cpp). Each keyframe sits at 24 frames per second from the lowest number, as DiTiS reads a
  /// timesheet. Drawings numbered 1, 3, 5 are therefore held across the gaps, which After Effects users ask for on the
  /// forum and After Effects lacks. The timing can then be changed by moving the keyframes.
  void _placeLevel(List<(int, String)> drawings) {
    final m = c.ws.inside!,
        from = c.ws.frame / WorkspaceController.fps,
        first = drawings.first.$1;
    m.later('together', number: 1);
    c.ws.after(m.later('add', word: drawings.first.$2), (done, why) {
      if (!done) c.set(() => c.mem.trouble[drawings.first.$2] = why);
    }, (made) => c.ws.select('$made'));
    m.later('fit', layer: -1, word: 'fit');
    m.later(
      'set',
      layer: -1,
      name: 'duration',
      number: (drawings.last.$1 - first + 1) / 24,
    );
    for (final (n, _) in drawings) {
      final at = '${from + (n - first) / 24}';
      m.later('key', layer: -1, name: 'cel', word: at, number: n.toDouble());
      m.later(
        'easing',
        layer: -1,
        name: 'cel',
        number: double.parse(at),
        word: 'hold',
      );
    }
    c.ws.after(m.later('together'), (_, _) => c.ws.reread());
    media.picked.clear();
  }

  /// Whether [file] is fitted inside the canvas and centred, as Alight Motion places photos and videos (imageLayer and
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
    final m = c.ws.inside!,
        still = media.kindOf(n.id) == 'picture' && media.stillSeconds > 0,
        cut = const ['film', 'sound'].contains(media.kindOf(n.id))
            ? media.filmRanges[n.id]
            : null,
        fit = _fitted(n.id); // The engine works out what the file is without waiting, and the layer is selected once made.
    if (still || cut != null || fit) {
      m.later(
        'together',
        number: 1,
      ); // Adding, fitting and setting the length are one undo step.
    }
    c.ws.after(m.later('add', word: n.id), (done, why) {
      media.placing.remove(n.id);
      c.set(
        () => done ? c.mem.trouble.remove(n.id) : c.mem.trouble[n.id] = why,
      );
    }, (made) => c.ws.select('$made'));
    if (fit) m.later('fit', layer: -1, word: 'fit');
    if (still) {
      m.later(
        'set',
        layer: -1,
        name: 'duration',
        number: media.stillSeconds,
      ); // Applies to the layer just added.
    }
    if (cut case (final a, final b)) {
      mediaSecondsOf(m.libPath, n.id).then((len) {
        // The length is already known because the range band drew it. The begin time is where the band's left end is in the video.
        m.later('set', layer: -1, name: 'begin', number: a * len);
        m.later('set', layer: -1, name: 'duration', number: (b - a) * len);
        c.ws.after(m.later('together'), (_, _) => c.ws.reread());
      });
    } else if (still || fit) {
      c.ws.after(m.later('together'), (_, _) => c.ws.reread());
    }
  }

  /// Places the timesheet [file] on the canvas, starting at the current time.
  ///
  /// Each column becomes a level as [_placeLevel] makes one, named after the column as OpenToonz does, and as long as
  /// the sheet. Each change gets a hold keyframe on the level's Drawing property at 24 frames per second, as DiTiS reads
  /// a sheet. The bottom column comes first, everything is one undo step, and the new layers are selected.
  /// Missing drawings and unsupported values are reported in the notice.
  Future<void> placeSheet(String file) async {
    final sheet = sheetOf(
      await File(file).readAsString().catchError((_) => ''),
    );
    if (sheet == null) {
      c.ws.notice = 'Not a timesheet: ${basename(file)}';
      return;
    }
    final m = c.ws.inside!,
        from = c.ws.frame / WorkspaceController.fps,
        missing = <String>[],
        made = <Future<int>>[];
    m.later('together', number: 1);
    for (final (name, keys) in sheet.columns) {
      if (levelNamed(file, name, media.kindOf) case final drawings?) {
        final asked = Completer<int>();
        c.ws.after(m.later('add', word: drawings.first.$2), (done, why) {
          if (!done) asked.complete(0);
        }, asked.complete);
        m.later('fit', layer: -1, word: 'fit');
        m.later('say', layer: -1, name: 'name', word: name);
        m.later('set', layer: -1, name: 'duration', number: sheet.frames / 24);
        for (final (f, n) in keys) {
          final at = '${from + f / 24}';
          m.later(
            'key',
            layer: -1,
            name: 'cel',
            word: at,
            number: n.toDouble(),
          );
          m.later(
            'easing',
            layer: -1,
            name: 'cel',
            number: double.parse(at),
            word: 'hold',
          );
        }
        made.add(asked.future);
      } else {
        missing.add(name);
      }
    }
    c.ws.after(m.later('together'), (_, _) => c.ws.reread());
    final ids = [
      for (final i in await Future.wait(made))
        if (i > 0) '$i',
    ];
    c.ws.pickMany(ids);
    final told = [
      if (missing.isNotEmpty)
        'no drawings named ${missing.join(', ')} beside it',
      if (sheet.unread.isNotEmpty) 'not read: ${sheet.unread.join(', ')}',
    ];
    c.ws.notice =
        'Placed ${ids.length} of ${sheet.columns.length} columns of ${basename(file)}${told.isEmpty ? '' : ': ${told.join('; ')}'}';
  }

  /// Replaces what every entry of [all] shows with [file], in one undo step.
  ///
  /// Alight Motion's Media Info does the same for the whole scene (replaceMedia in AbsentMotion's model/Media.kt,
  /// which changes the file's uri and every fill of it). After Effects and Premiere Pro call it Replace Footage.
  void replaceAll(List<(int, String)> all, String file) {
    final m = c.ws.inside!;
    m.later('together', number: 1);
    for (final (t, w) in all) {
      c.ws.after(m.later('say', layer: t, name: w, word: file), (done, why) {
        if (!done) c.ws.notice = 'Not replaced: $why';
      });
    }
    c.ws.after(m.later('together'), (_, _) => c.ws.reread());
  }

  /// Fills the shape layer [shape] with the image [file], as in Alight Motion's Fill > Media.
  void fillShape(int shape, String file) => c.ws.after(
    c.ws.inside!.later('say', layer: shape, name: 'fill_media', word: file),
  );

  /// Makes the image or video layer [layer] show [file] instead, keeping its position, size, keyframes and effects.
  void replaceSource(int layer, String file) => c.ws.after(
    c.ws.inside!.later('say', layer: layer, name: 'file', word: file),
    (done, why) => done ? c.ws.reread() : c.ws.notice = 'Not replaced: $why',
  );
}
