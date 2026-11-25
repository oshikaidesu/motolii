// Engine bridge for JS custom panels: lists panels, evaluates QuickJS render/action,
// and applies returned document ops in one undo step.
// 詳細: docs/design/custom_panels.md
import 'dart:convert';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/inspector/card_actions.dart' show CardCustomUi;
import 'package:motolii/storage/panel_presets_file.dart';
import 'package:motolii/storage/shelf_disk.dart' show makeFolder, writeText;
import 'package:motolii/storage/shelf_meta.dart' show clearShelfMetaCache;
import 'package:motolii/widgets/custom_ui/panel_node.dart'
    show PanelOp, panelThemeHexMap, panelToneColor, parsePanelList;
import 'package:motolii/workspace/state/art_scene.dart' show ArtGeometry;
import 'package:motolii/workspace/state/layers/layer_edits.dart'
    show groupBegin, groupEnd;
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/state/tiles/effect_code_cards.dart'
    show codeOfCard, codeSource;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/tool_panel/custom_panel/js_panel_tool.dart'
    show JsPanelTool;

/// One document mutation produced by a custom panel's `onAction` or an ACP agent.
typedef PanelDocOp = ({
  String op,
  int layer,
  String name,
  String word,
  String kind,
  String file,
  String ease,
  String mode,
  double? value,
  double? at,
  double? x,
  double? y,
  List<int> layers,
});

PanelDocOp panelDocOpOf(PanelOp o) => (
  op: o.op,
  layer: o.layer,
  name: o.name,
  word: o.word,
  kind: o.kind,
  file: o.file,
  ease: o.ease,
  mode: o.mode,
  value: o.value,
  at: o.at,
  x: o.x,
  y: o.y,
  layers: o.layers,
);

/// True when the engine handle is open and can evaluate QuickJS panels.
bool customPanelsReady(WorkspaceController ws) => ws.inside != null;

/// Writes the full scene JSON (`scene.json`) and current stage still (`stage.png`)
/// into [folder] for ACP agents.
({String? sceneJson, String? stagePng}) writeAgentSceneSnapshot(
  WorkspaceController ws,
  String folder,
) {
  final m = ws.inside;
  if (m == null) return (sceneJson: null, stagePng: null);
  try {
    makeFolder(folder);
    final scenePath = '$folder/scene.json';
    writeText(scenePath, customPanelCtxJson(ws, const {}));
    final stagePath = '$folder/stage.png';
    final ok = m.still(stagePath);
    return (sceneJson: scenePath, stagePng: ok ? stagePath : null);
  } catch (_) {
    return (sceneJson: null, stagePng: null);
  }
}

/// Lists discovered custom panels from `shelves/panels/` and user `panels/`.
String customPanelListRaw(WorkspaceController ws) =>
    ws.inside?.panelListRaw() ?? '';

/// Builds the JSON context object passed to `render(ctx)` and `onAction(action, ctx)`.
String customPanelCtxJson(
  WorkspaceController ws,
  Map<String, Object?> state, {
  Map<String, Object?> presets = const {},
}) {
  final m = ws.inside;
  final fps = WorkspaceController.fps;
  final at = ws.frame / (fps > 0 ? fps : 60.0);
  final selected = ws.many.isNotEmpty ? ws.many.toList() : [?ws.selected];
  final selSet = selected.toSet();
  final pt = m?.point ?? 1.0;
  final layers = [
    for (final l in ws.layers)
      () {
        final b = m?.bounds(l.id);
        final engineKind = m?.word(l.id, 'kind') ?? '';
        return {
          'id': l.id,
          'name': l.name,
          'kind': engineKind.isNotEmpty ? engineKind : l.kind.name,
          'shape': m?.word(l.id, 'shape') ?? '',
          'selected': selSet.contains(l.id),
          'parent': m?.parentOf(l.id) ?? 0,
          'order': m?.value(l.id, 'order', 0) ?? 0.0,
          'visible': (m?.value(l.id, 'visible', at) ?? 1.0) > 0.5,
          'clip': (m?.value(l.id, 'clip', at) ?? 0.0) > 0.5,
          'fx': m?.word(l.id, 'fx') ?? '',
          'start': m?.value(l.id, 'start', 0) ?? 0.0,
          'duration': m?.value(l.id, 'duration', 0) ?? -1.0,
          'x': m?.value(l.id, 'x', at) ?? 0.0,
          'y': m?.value(l.id, 'y', at) ?? 0.0,
          'z': m?.value(l.id, 'z', at) ?? 0.0,
          'rotate': m?.value(l.id, 'rotate', at) ?? 0.0,
          'scale_x': m?.value(l.id, 'scale_x', at) ?? 1.0,
          'scale_y': m?.value(l.id, 'scale_y', at) ?? 1.0,
          'anchor_x': m?.value(l.id, 'anchor_x', at) ?? 0.0,
          'anchor_y': m?.value(l.id, 'anchor_y', at) ?? 0.0,
          'opacity': m?.value(l.id, 'opacity', at) ?? 1.0,
          'fill': m?.word(l.id, 'fill') ?? '',
          'text': m?.word(l.id, 'text') ?? '',
          'split': m?.word(l.id, 'split') ?? '',
          'space': m?.word(l.id, 'space') ?? '',
          'font': m?.word(l.id, 'file') ?? '',
          'size': m?.value(l.id, 'size', at) ?? 1.0,
          'width': b != null && b.length >= 4 && pt > 0 ? b[2] / pt : 0.0,
          'height': b != null && b.length >= 4 && pt > 0 ? b[3] / pt : 0.0,
        };
      }(),
  ];
  return jsonEncode({
    'time': at,
    'frame': ws.frame,
    'fps': fps,
    'duration': WorkspaceController.duration,
    'bpm': m?.value(0, 'bpm', 0) ?? 0.0,
    'marks': [
      for (final (markAt, name) in m?.marks ?? const <(double, String)>[])
        {'time': markAt, 'name': name},
    ],
    'comp': {
      'width': ArtGeometry.comp.width,
      'height': ArtGeometry.comp.height,
      'point': pt,
    },
    'selected': selected,
    'isolated_group': ws.isolatedGroup ?? 0,
    'layers': layers,
    'state': state,
    'presets': presets,
    'theme': panelThemeHexMap(),
    'audio': m?.soundSpectrum(at) ?? const <double>[],
    'waveform': _waveformFor(ws, at),
    'strikes': [for (final f in ws.strikes) f / (fps > 0 ? fps : 60.0)],
  });
}

List<double> _waveformFor(WorkspaceController ws, double at) {
  final m = ws.inside;
  if (m == null) return const [];
  for (final l in ws.layers) {
    final samples = m.soundWaveform(at, layer: l.id);
    if (samples.isNotEmpty) return samples;
  }
  return m.soundWaveform(at);
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

final _cardUiCache = <String, bool>{};

/// Clears cached `.ui.js` detection results (called when packs are imported or folders reload).
void clearCustomCardUiCache() => _cardUiCache.clear();

/// True when [effectPath] has a sidecar `<stem>.ui.js` or co-located `renderCard(ctx)`.
bool hasCustomCardUi(WorkspaceController ws, String effectPath) {
  if (effectPath.isEmpty || ws.inside == null) return false;
  return _cardUiCache.putIfAbsent(
    effectPath,
    () => ws.inside!.cardUiFile(effectPath).isNotEmpty,
  );
}

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
  final presetBucket = 'card_$title';
  Map<String, Object?> layerMap(int id) {
    final fps = WorkspaceController.fps;
    final at = ws.frame / (fps > 0 ? fps : 60.0);
    final pt = m.point;
    final b = m.bounds(id);
    final l = ws.layers.where((e) => e.id == id).firstOrNull;
    return {
      'id': id,
      'name': l?.name ?? m.word(id, 'name'),
      'kind': l?.kind.name ?? m.word(id, 'kind'),
      'parent': m.parentOf(id),
      'order': m.value(id, 'order', 0) ?? 0.0,
      'visible': (m.value(id, 'visible', at) ?? 1.0) > 0.5,
      'clip': (m.value(id, 'clip', at) ?? 0.0) > 0.5,
      'fx': m.word(id, 'fx'),
      'start': m.value(id, 'start', 0) ?? 0.0,
      'duration': m.value(id, 'duration', 0) ?? -1.0,
      'x': m.value(id, 'x', at) ?? 0.0,
      'y': m.value(id, 'y', at) ?? 0.0,
      'z': m.value(id, 'z', at) ?? 0.0,
      'rotate': m.value(id, 'rotate', at) ?? 0.0,
      'scale_x': m.value(id, 'scale_x', at) ?? 1.0,
      'scale_y': m.value(id, 'scale_y', at) ?? 1.0,
      'opacity': m.value(id, 'opacity', at) ?? 1.0,
      'fill': m.word(id, 'fill'),
      'text': m.word(id, 'text'),
      'split': m.word(id, 'split'),
      'space': m.word(id, 'space'),
      'size': m.value(id, 'size', at) ?? 1.0,
      'width': b != null && b.length >= 4 && pt > 0 ? b[2] / pt : 0.0,
      'height': b != null && b.length >= 4 && pt > 0 ? b[3] / pt : 0.0,
    };
  }

  return (
    uiFile: uiFile,
    render: (ctxJson) => m.cardUiRender(uiFile, ctxJson),
    action: (actionJson, ctxJson) =>
        m.cardUiAction(uiFile, actionJson, ctxJson),
    liveSignal: () {
      final fps = WorkspaceController.fps > 0
          ? WorkspaceController.fps.toDouble()
          : 60.0;
      final at = ws.frame / fps;
      return (
        time: at,
        fps: fps,
        audio: m.soundSpectrum(at),
        waveform: _waveformFor(ws, at),
        strikes: [for (final f in ws.strikes) f / fps],
      );
    },
    contextExtra: () => {
      'layer': layerMap(thing),
      'layers': [for (final l in ws.layers) layerMap(l.id)],
      'duration': WorkspaceController.duration,
      'bpm': m.value(0, 'bpm', 0) ?? 0.0,
      'marks': [
        for (final (at, name) in m.marks) {'time': at, 'name': name},
      ],
      'presets': readPanelPresets(presetBucket),
      'comp': {
        'width': ArtGeometry.comp.width,
        'height': ArtGeometry.comp.height,
        'point': m.point,
      },
    },
    applyOps: (List<PanelOp> ops, String? notice) {
      if (notice != null && notice.isNotEmpty) ws.notice = notice;
      final presets = Map<String, Object?>.of(readPanelPresets(presetBucket));
      var presetsChanged = false;
      for (final o in ops) {
        if (o.op == 'preset_save' && o.name.isNotEmpty) {
          try {
            presets[o.name] = jsonDecode(o.word);
          } catch (_) {
            presets[o.name] = o.word;
          }
          presetsChanged = true;
        } else if (o.op == 'preset_delete' && o.name.isNotEmpty) {
          presets.remove(o.name);
          presetsChanged = true;
        }
      }
      if (presetsChanged) writePanelPresets(presetBucket, presets);
      if (ops.isNotEmpty) {
        applyCustomPanelOps(ws, [for (final o in ops) panelDocOpOf(o)]);
      }
    },
  );
}

/// Clears shelf and custom-card caches, notifies the engine that shelf files changed,
/// and triggers a workspace reread.
void reloadAgentShelves(WorkspaceController ws) {
  clearShelfMetaCache();
  clearCustomCardUiCache();
  ws.inside?.forgetFolders();
  ws.reread();
}

/// Reloads shelves/panel caches and opens a discovered Vism panel by [path] or [name]
/// as a live docking tab. Returns the opened panel name, or null if not found.
String? openVismPanelInDock(
  WorkspaceController ws, {
  String? path,
  String? name,
}) {
  clearShelfMetaCache();
  clearCustomCardUiCache();
  ws.inside?.forgetFolders();
  final panels = parsePanelList(customPanelListRaw(ws));
  final wantPath = path?.trim() ?? '';
  final wantName = name?.trim().toLowerCase() ?? '';
  final hit = panels
      .where(
        (d) =>
            (wantPath.isNotEmpty && d.path == wantPath) ||
            (wantName.isNotEmpty && d.name.toLowerCase() == wantName),
      )
      .firstOrNull;
  if (hit == null) return null;
  ws.openDockTab(
    Pane(
      hit.name,
      null,
      () => JsPanelTool(hit),
      at: PaneStrip.catalog,
      tone: panelToneColor(hit.tone),
      acts: hit.acts,
    ),
  );
  return hit.name;
}

const _colorWordProps = {
  'fill',
  'stroke',
  'background',
  'bevel_color',
  'side_color',
  'back_color',
  'copy_fill',
};

/// Strips leading `#` from 6-digit hex colors so `#ff3366` from scripts/agents
/// matches the engine's bare `rrggbb` format without rolling back an undo group.
String normalizePanelColorWord(String name, String word) {
  final isColor = _colorWordProps.contains(name) || name.endsWith(':stroke');
  if (!isColor || !word.contains('#')) return word;
  return word.replaceAllMapped(
    RegExp(r'#([0-9a-fA-F]{6})\b'),
    (m) => m.group(1)!,
  );
}

/// Executes [ops] returned by `onAction` or an ACP agent in a single undo step.
/// Layer 0 (stage/composition properties) and raw engine `later` calls are permitted.
/// When [onDone] is given, reports the engine's actual commit result `(done, why)`.
void applyCustomPanelOps(
  WorkspaceController ws,
  List<PanelDocOp> ops, {
  void Function(bool done, String why)? onDone,
}) {
  final m = ws.inside;
  if (m == null) {
    onDone?.call(false, 'No open project');
    return;
  }
  const nonDocOps = {
    'select',
    'time',
    'play',
    'open_panel',
    'reload_shelves',
    'preset_save',
    'preset_delete',
  };
  final docOps = ops.where((o) => !nonDocOps.contains(o.op)).toList();
  if (docOps.isNotEmpty) {
    groupBegin(ws);
    for (final o in docOps) {
      switch (o.op) {
        case 'set':
          if (o.name.isNotEmpty && (o.value != null || o.word.isNotEmpty)) {
            m.later(
              'set',
              layer: o.layer,
              name: o.name,
              number: o.value ?? 0,
              word: normalizePanelColorWord(o.name, o.word),
            );
          }
        case 'say':
          if (o.name.isNotEmpty) {
            m.later(
              'say',
              layer: o.layer,
              name: o.name,
              word: normalizePanelColorWord(o.name, o.word),
            );
          }
        case 'key':
          if (o.name.isNotEmpty && o.at != null && o.value != null) {
            m.later(
              'key',
              layer: o.layer,
              name: o.name,
              word: '${o.at!}',
              number: o.value!,
            );
            if (o.ease.isNotEmpty) {
              m.later(
                'easing',
                layer: o.layer,
                name: o.name,
                number: o.at!,
                word: o.ease,
              );
            }
          }
        case 'add':
          if (o.kind.isNotEmpty || o.file.isNotEmpty) {
            m.later('add', name: o.kind, word: o.file);
          }
        case 'create':
          final recipe = o.word.isNotEmpty ? o.word : o.name;
          if (recipe.isNotEmpty) m.later('create', word: recipe);
        case 'psd':
          if (o.file.isNotEmpty) m.later('psd', word: o.file);
        case 'pivot':
          if (o.layer != 0) {
            m.later(
              'pivot',
              layer: o.layer,
              word: '${o.x ?? 0.0} ${o.y ?? 0.0}',
            );
          }
        case 'explode':
          if (o.layer > 0) {
            m.later(
              'text_explode',
              layer: o.layer,
              word: o.mode.isEmpty ? 'letters' : o.mode,
            );
          }
        case 'outline':
          if (o.layer > 0) m.later('outline', layer: o.layer);
        case 'remove':
          if (o.layer > 0) m.later('remove', layer: o.layer);
        case 'fx':
          if (o.file.isNotEmpty) {
            final cur = o.layer >= 0 ? m.word(o.layer, 'fx') : '';
            final next = cur.isEmpty ? o.file : '$cur ${o.file}';
            m.later('say', layer: o.layer, name: 'fx', word: next);
          }
        case 'undo':
          m.later('undo');
        case 'redo':
          m.later('redo');
        case 'later':
          // Escape hatch for any engine motolii_later verb (mark, guide, split,
          // brush, fx_move, isolate, ...), keeping the core unconstrained.
          if (o.name.isNotEmpty) {
            m.later(
              o.name,
              layer: o.layer,
              name: o.mode,
              word: o.word.isNotEmpty ? o.word : o.file,
              number: o.value ?? o.at ?? 0,
            );
          }
      }
    }
    ws.after(groupEnd(ws), onDone);
  } else {
    onDone?.call(true, '');
  }
  for (final o in ops) {
    switch (o.op) {
      case 'select':
        if (o.layers.isEmpty) {
          ws.select(null);
        } else if (o.layers.length == 1) {
          ws.select(o.layers.first);
        } else {
          ws.pickMany(o.layers);
        }
      case 'time' when o.at != null:
        ws.frame = (o.at! * WorkspaceController.fps).round();
      case 'play':
        ws.playing = (o.value ?? 1) > 0.5;
      case 'reload_shelves':
        clearShelfMetaCache();
        clearCustomCardUiCache();
        m.forgetFolders();
        ws.reread();
      case 'open_panel':
        openVismPanelInDock(
          ws,
          path: o.file.isNotEmpty ? o.file : null,
          name: o.name.isNotEmpty
              ? o.name
              : (o.word.isNotEmpty ? o.word : null),
        );
    }
  }
}
