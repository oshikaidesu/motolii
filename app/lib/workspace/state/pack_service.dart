// Workspace actions for exporting and importing `.motoliipack` bundles with automatic shelf hot-reload.
// 詳細: docs/design/motoliipack.md
import 'package:motolii/storage/motolii_pack.dart';
import 'package:motolii/storage/open_in_host.dart' show pickFile, saveFile;
import 'package:motolii/storage/shelf_meta.dart' show clearShelfMetaCache;
import 'package:motolii/workspace/state/engine_access.dart' show ownFolder;
import 'package:motolii/workspace/state/workspace_controller.dart';

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
    ws.inside?.forgetFolders();
    ws.reread();
    final names = results.map((r) => r.name).join(', ');
    final total = results.fold<int>(0, (n, r) => n + r.installedPaths.length);
    ws.notice =
        'Installed pack: $names ($total ${total == 1 ? 'file' : 'files'})';
  }
  return results;
}

/// Prompts the user for a `.motoliipack` file and installs it with hot-reload.
Future<void> importPackFromDialog(WorkspaceController ws) async {
  final picked = await pickFile(
    prompt: 'Import Motolii Pack (.motoliipack)',
    extensions: const ['motoliipack', 'zip'],
  );
  if (picked == null || picked.isEmpty) return;
  importPacksIntoWorkspace(ws, [picked]);
}
