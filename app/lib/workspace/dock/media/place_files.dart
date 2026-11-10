// Which files the project uses and by which layer, and placing files on the canvas.
import 'dart:async';

import 'package:motolii/bridge/motolii.dart' show mediaSecondsOf;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/dock/media/file_node.dart';
import 'package:motolii/workspace/dock/media/timesheet.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

var _usedNow = <String, String>{};

int? _usedRev;

/// Maps each file the project uses, by whole path, to the layer that uses it. If several layers use a file, the front one wins.
Map<String, String> filesUsed(WorkspaceController ws) {
  if (_usedRev == ws.rev) return _usedNow;
  final m = ws.inside!;
  _usedRev = ws.rev;
  return _usedNow = {
    // The front layer is the first row, so going in reverse makes it the last entry and therefore the one kept.
    for (final l in ws.layers.reversed)
      if (m.word(int.parse(l.id), 'file') case final f
          when f.isNotEmpty &&
              !const {
                'behaviour',
                'camera',
                'light',
              }.contains(m.word(int.parse(l.id), 'kind')))
        // Behaviour, camera and light layers hold a kind name instead of a file.
        m.whole(f): l.id,
  };
}

/// The files selected together with Cmd and click, as Finder adds to a selection. They are placed together.
final filesPicked = <String>{};

final filmRanges = <String, (double, double)>{};

var stillSeconds = 2.0;

/// Places the selected [files] on the canvas, each as a new layer starting at the current time, and selects the new layers.
///
/// A video lasts as long as it plays, using the length from the discoverer. A video of unknown length lasts to the
/// end of the project. A still image lasts as long as chosen under it, and End stacks the stills together.
/// If every file has a length, the layers are laid one after another in the order selected with the engine's
/// Stagger, as Alight Motion does when adding several files.
Future<void> placeFiles(ShelfContext c, List<String> files) async {
  if (levelOf(files) case final drawings?) return _placeLevel(c, drawings);
  final m = c.ws.inside!;
  final lengths = [
    for (final (i, s) in (await Future.wait([
      for (final f in files) mediaSecondsOf(m.libPath, f),
    ])).indexed)
      kindOfFile(files[i]) == 'picture' ? stillSeconds : s,
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
    filesPicked.clear();
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
void _placeLevel(ShelfContext c, List<(int, String)> drawings) {
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
  filesPicked.clear();
}

/// Whether [file] is fitted inside the canvas and centred, as Alight Motion places photos and videos (imageLayer and
/// videoLayer in AbsentMotion's editor/EditorActions.kt and VideoActions.kt). Vector images such as Lottie and SVG
/// are placed as they are.
bool _fitted(String file) =>
    kindOfFile(file) == 'film' ||
    kindOfFile(file) == 'picture' &&
        RegExp(
          r'\.(jpe?g|png|webp|bmp|heic)$',
          caseSensitive: false,
        ).hasMatch(file);

final _placing = <String>{};

/// Places the file [n] on the canvas as a new layer and selects it. If it fails, the footer of the shelf says why.
void placeFile(ShelfContext c, FileNode n) {
  if (kindOfFile(n.id) == 'timesheet') return unawaited(placeSheet(c, n.id));
  if (!_placing.add(n.id)) {
    // Reading a song takes the engine a moment, so a second click in that moment counts as the same click.
    return;
  }
  final m = c.ws.inside!,
      still = kindOfFile(n.id) == 'picture' && stillSeconds > 0,
      cut = const ['film', 'sound'].contains(kindOfFile(n.id))
          ? filmRanges[n.id]
          : null,
      fit = _fitted(n.id); // The engine works out what the file is without waiting, and the layer is selected once made.
  if (still || cut != null || fit) {
    m.later(
      'together',
      number: 1,
    ); // Adding, fitting and setting the length are one undo step.
  }
  c.ws.after(m.later('add', word: n.id), (done, why) {
    _placing.remove(n.id);
    c.set(() => done ? c.mem.trouble.remove(n.id) : c.mem.trouble[n.id] = why);
  }, (made) => c.ws.select('$made'));
  if (fit) m.later('fit', layer: -1, word: 'fit');
  if (still) {
    m.later(
      'set',
      layer: -1,
      name: 'duration',
      number: stillSeconds,
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
