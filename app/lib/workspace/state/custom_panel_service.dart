// Engine bridge for JS custom panels: lists panels, evaluates QuickJS render/action,
// and applies returned document ops in one undo step.
// 詳細: docs/design/custom_panels.md
import 'dart:convert';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/inspector/card_actions.dart' show CardCustomUi;
import 'package:motolii/widgets/custom_ui/panel_node.dart'
    show panelThemeHexMap;
import 'package:motolii/workspace/state/art_scene.dart' show ArtGeometry;
import 'package:motolii/workspace/state/layers/layer_edits.dart'
    show groupBegin, groupEnd;
import 'package:motolii/workspace/state/tiles/effect_code_cards.dart'
    show codeOfCard, codeSource;
import 'package:motolii/workspace/state/workspace_controller.dart';

/// One document mutation produced by a custom panel's `onAction`.
typedef PanelDocOp = ({
  String op,
  int layer,
  String name,
  String word,
  String kind,
  String file,
  double? value,
  double? at,
  List<int> layers,
});

/// True when the engine handle is open and can evaluate QuickJS panels.
bool customPanelsReady(WorkspaceController ws) => ws.inside != null;

/// Lists discovered custom panels from `shelves/panels/` and user `panels/`.
String customPanelListRaw(WorkspaceController ws) =>
    ws.inside?.panelListRaw() ?? '';

/// Builds the JSON context object passed to `render(ctx)` and `onAction(action, ctx)`.
String customPanelCtxJson(WorkspaceController ws, Map<String, Object?> state) {
  final m = ws.inside;
  final fps = WorkspaceController.fps;
  final at = ws.frame / (fps > 0 ? fps : 60.0);
  final selected = ws.many.isNotEmpty ? ws.many.toList() : [?ws.selected];
  final layers = [
    for (final l in ws.layers)
      {
        'id': l.id,
        'name': l.name,
        'kind': l.kind.name,
        'start': m?.value(l.id, 'start', 0) ?? 0.0,
        'duration': m?.value(l.id, 'duration', 0) ?? -1.0,
        'x': m?.value(l.id, 'x', at) ?? 0.0,
        'y': m?.value(l.id, 'y', at) ?? 0.0,
        'rotate': m?.value(l.id, 'rotate', at) ?? 0.0,
        'scale_x': m?.value(l.id, 'scale_x', at) ?? 1.0,
        'scale_y': m?.value(l.id, 'scale_y', at) ?? 1.0,
        'anchor_x': m?.value(l.id, 'anchor_x', at) ?? 0.0,
        'anchor_y': m?.value(l.id, 'anchor_y', at) ?? 0.0,
        'opacity': m?.value(l.id, 'opacity', at) ?? 1.0,
        'fill': m?.word(l.id, 'fill') ?? '',
      },
  ];
  return jsonEncode({
    'time': at,
    'frame': ws.frame,
    'fps': fps,
    'duration': WorkspaceController.duration,
    'comp': {
      'width': ArtGeometry.comp.width,
      'height': ArtGeometry.comp.height,
    },
    'selected': selected,
    'layers': layers,
    'state': state,
    'theme': panelThemeHexMap(),
  });
}

/// Evaluates `render(ctx)` in [path] via QuickJS.
String customPanelRender(WorkspaceController ws, String path, String ctxJson) =>
    ws.inside?.panelRender(path, ctxJson) ??
    '{"ok":false,"error":"No open project"}';

/// Evaluates `onAction(action, ctx)` in [path] via QuickJS.
String customPanelAction(
  WorkspaceController ws,
  String path,
  String actionJson,
  String ctxJson,
) =>
    ws.inside?.panelAction(path, actionJson, ctxJson) ??
    '{"ok":false,"error":"No open project"}';

/// Resolves a custom Inspector card UI (`<effect>.ui.js` sidecar or co-located `renderCard`)
/// for card [title] on layer [thing], or returns null when the card uses the default grid.
CardCustomUi? cardCustomUiOf(
  WorkspaceController ws,
  int thing,
  String title,
  List<String> names,
) {
  final m = ws.inside;
  if (m == null) return null;
  final code = codeOfCard(ws, thing, title, names);
  if (code == null) return null;
  final uiFile = m.cardUiFile(codeSource(code.word));
  if (uiFile.isEmpty) return null;
  return (
    uiFile: uiFile,
    render: (ctxJson) => m.cardUiRender(uiFile, ctxJson),
    action: (actionJson, ctxJson) =>
        m.cardUiAction(uiFile, actionJson, ctxJson),
  );
}

/// Executes [ops] returned by `onAction` in a single undo step.
void applyCustomPanelOps(WorkspaceController ws, List<PanelDocOp> ops) {
  final m = ws.inside;
  if (m == null) return;
  final docOps = ops.where((o) => o.op != 'select' && o.op != 'time');
  if (docOps.isNotEmpty) {
    groupBegin(ws);
    for (final o in docOps) {
      switch (o.op) {
        case 'set':
          if (o.layer > 0 && o.name.isNotEmpty && o.value != null) {
            m.later('set', layer: o.layer, name: o.name, number: o.value!);
          }
        case 'say':
          if (o.layer > 0 && o.name.isNotEmpty) {
            m.later('say', layer: o.layer, name: o.name, word: o.word);
          }
        case 'key':
          if (o.layer > 0 &&
              o.name.isNotEmpty &&
              o.at != null &&
              o.value != null) {
            m.key(o.layer, o.name, o.at!, o.value!);
          }
        case 'add':
          if (o.kind.isNotEmpty || o.file.isNotEmpty) {
            m.later('add', name: o.kind, word: o.file);
          }
        case 'remove':
          if (o.layer > 0) m.later('remove', layer: o.layer);
        case 'fx':
          if (o.layer > 0 && o.file.isNotEmpty) {
            final cur = m.word(o.layer, 'fx');
            final next = cur.isEmpty ? o.file : '$cur ${o.file}';
            m.later('say', layer: o.layer, name: 'fx', word: next);
          }
      }
    }
    ws.after(groupEnd(ws));
  }
  for (final o in ops) {
    if (o.op == 'select') {
      if (o.layers.isEmpty) {
        ws.select(null);
      } else if (o.layers.length == 1) {
        ws.select(o.layers.first);
      } else {
        ws.pickMany(o.layers);
      }
    } else if (o.op == 'time' && o.at != null) {
      ws.frame = (o.at! * WorkspaceController.fps).round();
    }
  }
}
