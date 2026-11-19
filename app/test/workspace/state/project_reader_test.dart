// ProjectReader makes again only the layers a read brought parts of (docs/app/BRIDGE.md). Here a document is
// edited at random and handed over as the engine hands it (only the parts that differ); after every step the
// window's layers must be what a reader that has just opened the same document reads, and the window must be
// told of the list exactly when it differs.
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' show Utf8;
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_bindings.dart' as c;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

class _Bindings implements c.MotoliiBindings {
  @override
  // ignore: non_constant_identifier_names
  int motolii_rate(Pointer<c.Motolii> m) => 60;

  @override
  // ignore: non_constant_identifier_names
  int motolii_later(
    Pointer<c.Motolii> m,
    Pointer<Utf8> call,
    int layer,
    Pointer<Utf8> name,
    Pointer<Utf8> word,
    double number,
  ) => 0;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// An engine that is only its snapshots: what the app holds of them, and the document they are made from.
class _Engine implements Motolii {
  @override
  Map<String, dynamic> documentSnapshot = const {};
  @override
  final layerSnapshots = <int, Map<String, dynamic>>{};
  @override
  bool structureTaken = false;
  @override
  final layersTaken = <int>{};
  @override
  bool layerListTaken = false;
  @override
  final shownOf = <String, Shown?>{};
  @override
  final kindProperties = <String, Set<String>>{};
  @override
  final asked = <int, Set<String>>{};
  @override
  Map<String, dynamic> momentSnapshot = const {'layer': {}};
  @override
  Float64List timeLayout = Float64List(0);
  @override
  final Set<String> shaping = const {};
  @override
  Set<int> watched = const {};
  @override
  void Function({
    required bool document,
    required bool moment,
    required bool cache,
  })?
  listener;
  @override
  final bindings = _Bindings();
  @override
  EngineHandle get handle => nullptr;
  @override
  List<int> get layers =>
      ((documentSnapshot['layers'] as List<dynamic>?) ?? const []).cast<int>();
  @override
  String whole(String file) => file;

  // The parts as last handed over, each as its JSON text.
  final _handed = <String, Map<String, String>>{};

  /// Hands over the parts of [document] that differ from what was handed before, as the engine does: a part
  /// that is gone as null, a layer that is gone not at all.
  void hand(Map<String, Map<String, dynamic>> document) {
    Map<String, dynamic> newer(String of, Map<String, dynamic> parts) {
      final had = _handed[of] ??= {};
      final out = <String, dynamic>{
        for (final e in parts.entries)
          if (had[e.key] != jsonEncode(e.value)) e.key: e.value,
        for (final gone in had.keys.where((k) => !parts.containsKey(k)))
          gone: null,
      };
      _handed[of] = {for (final e in parts.entries) e.key: jsonEncode(e.value)};
      return out;
    }

    _handed.removeWhere((of, _) => !document.containsKey(of));
    // Through JSON, as the app is handed it: nothing of the document is shared with what the app holds.
    put(
      jsonDecode(
        jsonEncode({
          'document': newer('document', document['document']!),
          'layer': {
            for (final of in document.keys)
              if (of != 'document')
                if (newer(of, document[of]!) case final parts
                    when parts.isNotEmpty)
                  of: parts,
          },
        }),
      ) as Map<String, dynamic>,
    );
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Map<String, dynamic> _layer(int id) => {
  'word': {
    'kind': 'shape',
    'name': 'Layer $id',
    'shape': 'rect',
    'fill': 'ff0000',
    'label': 'none',
  },
  'words': {'label': 'none red blue green'},
  'value': {'start': 0, 'parent': 0, 'visible': 1, 'x': 0},
  'values': 'x start parent visible',
  'moving': 'x',
  'lasts': 2,
  'keys': <double>[],
  'keyTimes': <String, dynamic>{},
  'keyValues': <String, dynamic>{},
  'keyEasings': <String, dynamic>{},
};

Map<String, Map<String, dynamic>> _document(int layers) => {
  'document': {
    'layers': [for (var t = 1; t <= layers; t++) t],
    'seconds': 4,
    'fits': true,
    'marks': '',
    'work': [0, 4],
    'changes': '',
  },
  '0': {
    'value': {'frame_rate': 60, 'bpm': 0},
  },
  for (var t = 1; t <= layers; t++) '$t': _layer(t),
};

/// One edit at random. What it is called, for the failure's message.
String _edit(Map<String, Map<String, dynamic>> d, Random r, int step) {
  final ids = (d['document']!['layers'] as List<dynamic>).cast<int>();
  final t = ids[r.nextInt(ids.length)];
  final l = d['$t']!;
  Map<String, dynamic> part(String name) =>
      l[name] = Map<String, dynamic>.of(l[name] as Map<String, dynamic>);
  switch (r.nextInt(11)) {
    case 0 || 1 || 2:
      part('value')['x'] = r.nextInt(1000);
      return 'x of $t';
    case 3:
      part('value')['visible'] = r.nextInt(2);
      return 'visible of $t';
    case 4:
      part('word')['name'] = 'Named $step';
      return 'name of $t';
    case 5:
      part('word')['label'] = const [
        'none',
        'red',
        'blue',
        'green',
      ][r.nextInt(4)];
      return 'label of $t';
    case 6:
      final at = r.nextInt(8) / 2;
      l['keys'] = {...l['keys'] as List<dynamic>, at}.toList()..sort();
      part('keyTimes')['x'] = l['keys'];
      part('keyValues')['x'] = [
        for (final _ in l['keys'] as List<dynamic>) step,
      ];
      part('keyEasings')['x'] = [
        for (final _ in l['keys'] as List<dynamic>) '',
      ];
      return 'key of $t at $at';
    case 7:
      final to = ids[r.nextInt(ids.length)];
      part('value')['parent'] = to == t ? 0 : to;
      part('word')['shape'] = r.nextBool() ? 'null' : 'rect';
      return 'parent of $t to $to';
    case 8:
      final id = step + 1000;
      d['document']!['layers'] = [...ids, id];
      d['$id'] = _layer(id);
      return 'add $id';
    case 9:
      if (ids.length < 3) return 'nothing';
      d['document']!['layers'] = [...ids]..remove(t);
      d.remove('$t');
      return 'remove $t';
    default:
      d['document']!['marks'] = '${r.nextInt(4)} Mark';
      return 'mark';
  }
}

void main() {
  WorkspaceController opened(_Engine m) {
    final ws = WorkspaceController();
    addTearDown(ws.dispose);
    ws.project.join(m);
    return ws;
  }

  // What a reader that has just opened [d] reads, and the label colours it chose.
  (List<Layer>, Map<int, int>) fresh(Map<String, Map<String, dynamic>> d) {
    final ws = opened(_Engine()..hand(d));
    return (List.of(ws.layers), Map.of(chosenLabelColors));
  }

  bool sameLayers(List<Layer> a, List<Layer> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i].same(b[i])].every((s) => s);

  for (final seed in [1, 2, 3, 4, 5]) {
    test(
      'edits at random, seed $seed: the layers are what a new reader reads',
      () {
        final r = Random(seed), d = _document(12), m = _Engine()..hand(d);
        final ws = opened(m);
        var (was, wasLabels) = fresh(d);
        for (var step = 0; step < 300; step++) {
          final marks = d['document']!['marks'];
          final did = _edit(d, r, step);
          final told = ws.on[WorkspaceAspect.layers]!.value;
          final held = List.of(ws.layers), came = <int>{};
          m.hand(d);
          came.addAll(m.layersTaken);
          final listCame = m.layerListTaken;
          ws.project.reread();
          final labels = Map.of(chosenLabelColors);
          final (now, nowLabels) = fresh(d);
          final why = 'seed $seed step $step: $did';
          expect(sameLayers(ws.layers, now), isTrue, reason: why);
          expect(labels, nowLabels, reason: why);
          final of = {for (final l in now) l.id: l};
          expect(
            [for (final l in ws.layers) ws.depth(l)],
            [
              for (final l in now)
                l.ancestors(of).where((p) => p.kind == LayerKind.group).length,
            ],
            reason: why,
          );
          expect(
            ws.on[WorkspaceAspect.layers]!.value > told,
            !sameLayers(was, now) ||
                !mapEquals(wasLabels, nowLabels) ||
                d['document']!['marks'] != marks,
            reason: why,
          );
          if (!listCame && did.startsWith('x of')) {
            // A number set anew makes that layer again and no other.
            expect(
              [
                for (var i = 0; i < held.length; i++)
                  if (!identical(held[i], ws.layers[i])) held[i].id,
              ],
              came.where((t) => t != 0),
              reason: why,
            );
          }
          (was, wasLabels) = (now, nowLabels);
        }
      },
    );
  }
}

bool mapEquals(Map<int, int> a, Map<int, int> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
