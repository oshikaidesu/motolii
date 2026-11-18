// What the Media shelf asks of the engine: what a file makes, the files the layers use, a file's length and info, and
// placing files, levels and timesheets as layers, and replacing what a layer shows.
import 'dart:async';

import 'package:motolii/bridge/motolii.dart' show mediaInfoOf, mediaSecondsOf;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

typedef SheetColumn = ({
  String name,
  List<(int, int)> keys,
  List<(int, String)>? drawings,
});

String mediaKindOf(WorkspaceController ws, String file) =>
    ws.inside!.kindOf(file);

Future<String?> mediaThumbnail(
  WorkspaceController ws,
  String film,
  int step,
  int steps,
) => ws.inside!.thumbnailAt(film, step, steps);

Future<String> mediaInfoFor(WorkspaceController ws, String file) =>
    mediaInfoOf(ws.inside!.libPath, file);

Future<double> mediaLengthOf(WorkspaceController ws, String file) =>
    mediaSecondsOf(ws.inside!.libPath, file);

Future<List<double>> mediaLengthsOf(
  WorkspaceController ws,
  List<String> files,
) => Future.wait([for (final f in files) mediaLengthOf(ws, f)]);

Map<String, int> filesOfLayers(WorkspaceController ws) {
  final m = ws.inside!;
  return {
    for (final l in ws.layers.reversed)
      if (m.word(l.id, 'file') case final f
          when f.isNotEmpty &&
              !const {
                'behaviour',
                'camera',
                'light',
              }.contains(m.word(l.id, 'kind')))
        m.whole(f): l.id,
  };
}

List<(int, String)> layersShowingFileOf(WorkspaceController ws, int shape) {
  final m = ws.inside!, file = m.whole(m.word(shape, 'file'));
  return [
    for (final t in m.layers)
      for (final w in const ['file', 'fill_media'])
        if (m.word(t, w) case final f when f.isNotEmpty && m.whole(f) == file)
          (t, w),
  ];
}

void layFilesInOrder(
  WorkspaceController ws,
  List<String> files,
  List<double> lengths,
  List<bool> fits, {
  required void Function(String file, String why) refused,
  required void Function(List<int> placed) placed,
}) {
  final m = ws.inside!;
  m.later('together', number: 1);
  final made = <Future<int>>[];
  for (final (i, f) in files.indexed) {
    final asked = Completer<int>();
    ws.after(m.later('add', word: f), (done, why) {
      if (done) return;
      refused(f, why);
      asked.complete(0);
    }, asked.complete);
    if (fits[i]) m.later('fit', layer: -1, word: 'fit');
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
  ws.after(m.later('together'));
  Future.wait(made).then((ids) {
    final all = [
      for (final i in ids)
        if (i > 0) i,
    ];
    if (all.length > 1 && lengths.every((s) => s > 0)) {
      ws.after(
        m.later('time_align', word: 'stagger ${all.join(' ')}'),
        (_, _) => ws.reread(),
      );
    }
    placed(all);
  });
}

void placeLevel(
  WorkspaceController ws,
  List<(int, String)> drawings,
  double from, {
  required void Function(String file, String why) refused,
}) {
  final m = ws.inside!, first = drawings.first.$1;
  m.later('together', number: 1);
  ws.after(m.later('add', word: drawings.first.$2), (done, why) {
    if (!done) refused(drawings.first.$2, why);
  }, (made) => ws.select(made));
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
  ws.after(m.later('together'), (_, _) => ws.reread());
}

void placeFileLayer(
  WorkspaceController ws, {
  required String file,
  required String verb,
  required bool fit,
  required double? stillSeconds,
  required (double, double)? cut,
  required void Function(bool done, String why) settled,
}) {
  final m = ws.inside!, still = stillSeconds != null;
  if (still || cut != null || fit) {
    m.later(
      'together',
      number: 1,
    ); // Adding, fitting and setting the length are one undo step.
  }
  ws.after(m.later(verb, word: file), settled, (made) => ws.select(made));
  if (fit) m.later('fit', layer: -1, word: 'fit');
  if (stillSeconds case final seconds?) {
    m.later(
      'set',
      layer: -1,
      name: 'duration',
      number: seconds,
    ); // Applies to the layer just added.
  }
  if (cut case (final a, final b)) {
    mediaSecondsOf(m.libPath, file).then((len) {
      // The length is already known because the range band drew it. The begin time is where the band's left end is in the video.
      m.later('set', layer: -1, name: 'begin', number: a * len);
      m.later('set', layer: -1, name: 'duration', number: (b - a) * len);
      ws.after(m.later('together'), (_, _) => ws.reread());
    });
  } else if (still || fit) {
    ws.after(m.later('together'), (_, _) => ws.reread());
  }
}

Future<List<int>> layOutSheet(
  WorkspaceController ws, {
  required double from,
  required int frames,
  required List<SheetColumn> columns,
}) async {
  final m = ws.inside!, made = <Future<int>>[];
  m.later('together', number: 1);
  for (final column in columns) {
    if (column.drawings case final drawings?) {
      final asked = Completer<int>();
      ws.after(m.later('add', word: drawings.first.$2), (done, why) {
        if (!done) asked.complete(0);
      }, asked.complete);
      m.later('fit', layer: -1, word: 'fit');
      m.later('say', layer: -1, name: 'name', word: column.name);
      m.later('set', layer: -1, name: 'duration', number: frames / 24);
      for (final (f, n) in column.keys) {
        final at = '${from + f / 24}';
        m.later('key', layer: -1, name: 'cel', word: at, number: n.toDouble());
        m.later(
          'easing',
          layer: -1,
          name: 'cel',
          number: double.parse(at),
          word: 'hold',
        );
      }
      made.add(asked.future);
    }
  }
  ws.after(m.later('together'), (_, _) => ws.reread());
  return [
    for (final i in await Future.wait(made))
      if (i > 0) i,
  ];
}

void replaceSourcesIn(
  WorkspaceController ws,
  List<(int, String)> all,
  String file, {
  required void Function(String why) refused,
}) {
  final m = ws.inside!;
  m.later('together', number: 1);
  for (final (t, w) in all) {
    ws.after(m.later('say', layer: t, name: w, word: file), (done, why) {
      if (!done) refused(why);
    });
  }
  ws.after(m.later('together'), (_, _) => ws.reread());
}

void fillShapeWith(WorkspaceController ws, int shape, String file) => ws.after(
  ws.inside!.later('say', layer: shape, name: 'fill_media', word: file),
);

void replaceLayerSource(
  WorkspaceController ws,
  int layer,
  String file, {
  required void Function(String why) refused,
}) => ws.after(
  ws.inside!.later('say', layer: layer, name: 'file', word: file),
  (done, why) {
    if (done) {
      ws.reread();
    } else {
      refused(why);
    }
  },
);
