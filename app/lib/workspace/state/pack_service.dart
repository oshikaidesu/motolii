// Workspace actions for exporting and importing `.motoliipack` / `.motolii-card` / 1-folder VST bundles
// with automatic shelf hot-reload and immediate open/apply.
// 詳細: docs/design/motoliipack.md
import 'package:motolii/storage/motolii_pack.dart';
import 'package:motolii/storage/open_in_host.dart' show pickFile, saveFile;
import 'package:motolii/storage/shelf_meta.dart' show clearShelfMetaCache;
import 'package:motolii/widgets/custom_ui/panel_node.dart'
    show panelToneColor, parsePanelList;
import 'package:motolii/workspace/state/custom_panel_service.dart'
    show clearCustomCardUiCache, customPanelListRaw;
import 'package:motolii/workspace/state/engine_access.dart' show ownFolder;
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/state/tiles/effect_put.dart'
    show putEffectFile;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/tool_panel/custom_panel/js_panel_tool.dart'
    show JsPanelTool;

/// Exports an effect, expression, or custom panel [sourceFile] as a `.motoliipack` via save dialog (or [outPath]).
Future<PackExportResult?> exportPackFromWorkspace(
  WorkspaceController ws, {
  required String sourceFile,
  required String kind,
  String? name,
  String? outPath,
}) async {
  final suggested =
      '${(name ?? 'pack').replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.motoliipack';
  final dest =
      outPath ??
      await saveFile(prompt: 'Export Motolii Pack', defaultName: suggested);
  if (dest == null || dest.isEmpty) return null;
  try {
    final res = exportMotoliiPack(
      sourceFile: sourceFile,
      kind: kind,
      outPath: dest,
      name: name,
    );
    ws.notice =
        'Exported ${res.name}.motoliipack (${res.fileCount} ${res.fileCount == 1 ? 'file' : 'files'})';
    return res;
  } catch (e) {
    ws.notice = 'Not exported: $e';
    return null;
  }
}

/// Imports one or more `.motoliipack` files into the user's shelf folder and hot-reloads the engine & shelves.
List<PackImportResult> importPacksIntoWorkspace(
  WorkspaceController ws,
  List<String> packPaths, {
  String? targetOwnFolder,
}) {
  final own = targetOwnFolder ?? ownFolder();
  final results = <PackImportResult>[];
  for (final p in packPaths) {
    try {
      results.add(importMotoliiPack(p, ownFolder: own));
    } catch (e) {
      ws.notice = 'Not imported: $e';
    }
  }
  if (results.isNotEmpty) {
    clearShelfMetaCache();
    clearCustomCardUiCache();
    ws.inside?.forgetFolders();
    ws.reread();
    for (final r in results) {
      _activateInstalledBundle(ws, r);
    }
    final names = results.map((r) => r.name).join(', ');
    final total = results.fold<int>(0, (n, r) => n + r.installedPaths.length);
    ws.notice =
        'Installed pack: $names ($total ${total == 1 ? 'file' : 'files'})';
  }
  return results;
}

/// Immediately opens an installed custom panel as a docking tab, or applies an installed
/// effect/expression to the active layer and fronts Inspector so the VST card shows at once.
void _activateInstalledBundle(WorkspaceController ws, PackImportResult res) {
  if (res.kind == 'panel') {
    final panels = parsePanelList(customPanelListRaw(ws));
    final hit = panels
        .where(
          (d) =>
              res.installedPaths.any((p) => p == d.path) ||
              d.name.toLowerCase() == res.name.toLowerCase(),
        )
        .firstOrNull;
    if (hit != null) {
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
    }
    return;
  }
  if (ws.inside == null) return;
  if (res.kind == 'effect' || res.kind == 'expression') {
    final mainFile = res.installedPaths.where((p) {
      final low = p.toLowerCase();
      if (low.endsWith('.ui.js')) return false;
      return low.endsWith('.fs') ||
          low.endsWith('.wgsl') ||
          low.endsWith('.js') ||
          low.endsWith('.mjs');
    }).firstOrNull;
    if (mainFile != null) {
      putEffectFile(
        ws,
        mainFile,
        expression: res.kind == 'expression',
        told: (_) {},
      );
      ws.front('Inspector');
    }
  }
}

/// Prompts the user for a `.motoliipack` / `.motolii-card` file and installs it with hot-reload.
Future<void> importPackFromDialog(WorkspaceController ws) async {
  final picked = await pickFile(
    prompt: 'Import Motolii Pack (.motoliipack / .motolii-card)',
    extensions: const ['motoliipack', 'motolii-card', 'zip'],
  );
  if (picked == null || picked.isEmpty) return;
  importPacksIntoWorkspace(ws, [picked]);
}
