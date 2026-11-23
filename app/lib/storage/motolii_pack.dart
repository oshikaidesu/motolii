// Export and import of `.motoliipack` (ZIP) sharing bundles for effects, expressions, .ui.js cards, and custom JS panels.
// 詳細: docs/design/motoliipack.md
import 'dart:convert';
import 'dart:io';

import 'package:motolii/storage/host_platform.dart' show hostIsWindows, slashed;
import 'package:motolii/storage/panel_presets_file.dart'
    show mergePanelPresets, readPanelPresets;
import 'package:motolii/storage/shelf_meta.dart' show shelfMetaOfFile;

const _packVersion = 1;
const _packExtension = '.motoliipack';
const _vismExtension = '.vism';
const _cardExtension = '.motolii-card';
const _allowedRoots = {'effects', 'expressions', 'panels', 'create'};
const _companionSuffixes = [
  '.vs',
  '.ui.js',
  '.png',
  '.webp',
  '.jpg',
  '.glb',
  '.obj',
  '.frag',
];

/// Result of exporting a `.vism` / `.motoliipack` archive.
typedef PackExportResult = ({String path, String name, int fileCount});

/// Result of importing a `.vism` / `.motoliipack` archive or 1-folder Vism bundle into the user's shelf folder.
typedef PackImportResult = ({
  String name,
  String kind,
  List<String> installedPaths,
});

/// True if [path] is a `.vism` / `.motoliipack` / `.motolii-card` archive, OR a dropped
/// 1-folder Vism bundle containing `motoliipack.json` or a `*.ui.js` file.
bool isMotoliiPackPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith(_vismExtension) ||
      lower.endsWith(_packExtension) ||
      lower.endsWith(_cardExtension)) {
    return true;
  }
  try {
    final dir = Directory(path);
    if (!dir.existsSync()) return false;
    if (File('${dir.path}/motoliipack.json').existsSync()) return true;
    for (final e in dir.listSync()) {
      if (e is File && e.path.toLowerCase().endsWith('.ui.js')) return true;
    }
  } catch (_) {}
  return false;
}

/// Ensures IDE TypeScript IntelliSense (`motolii-ui.d.ts` + `jsconfig.json`) exists in [ownFolder]
/// and scaffolds a ready-to-run starter Vism panel under `ownFolder/panels/`.
/// Returns `(name, path)` of the newly created `.js` file.
({String name, String path}) createVismPanelStarter({
  required String ownFolder,
  String shelvesFolder = '',
}) {
  final panelsDir = Directory('$ownFolder/panels')..createSync(recursive: true);
  // Copy `motolii-ui.d.ts` and write `jsconfig.json` once so VS Code / Cursor autocomplete works immediately.
  if (shelvesFolder.isNotEmpty) {
    final srcDts = File('$shelvesFolder/motolii-ui.d.ts');
    final dstDts = File('$ownFolder/motolii-ui.d.ts');
    if (srcDts.existsSync()) {
      try {
        srcDts.copySync(dstDts.path);
      } catch (_) {}
    }
  }
  final jsconfig = File('$ownFolder/jsconfig.json');
  if (!jsconfig.existsSync()) {
    jsconfig.writeAsStringSync(
      '{\n  "compilerOptions": { "checkJs": false },\n  "include": ["**/*.js", "motolii-ui.d.ts"]\n}\n',
    );
  }

  var index = 1;
  var name = 'My Vism';
  var target = File('${panelsDir.path}/$name.js');
  while (target.existsSync()) {
    index++;
    name = 'My Vism $index';
    target = File('${panelsDir.path}/$name.js');
  }
  target.writeAsStringSync(_vismStarterTemplate(name));
  return (name: name, path: slashed(target.path));
}

String _vismStarterTemplate(String title) =>
    '''
// --title: $title
// --about: Custom Vism panel starter — edit & save for instant hot reload!
// --acts: Selection
// --tone: accent

// Full API & IntelliSense: see motolii-ui.d.ts (or docs/VISM_QUICKSTART.ja.md).
function render(ctx) {
  const s = ctx.state || {};
  const yaw = Number(s.yaw ?? 0.6);
  const pitch = Number(s.pitch ?? 0.35);
  const amount = Number(s.amount ?? 0.65);
  const pulse = Number(s.pulse ?? 0.45);
  const selected = (ctx.selected || []).length;

  return ui.box([
    ui.row([
      ui.badge("VISM STARTER", {
        style: {
          bg: "#FF3B7F",
          fg: "#FFFFFF",
          border: "#141414",
          borderWidth: 2,
          radius: 99,
          shadow: { x: 2, y: 2, blur: 0, color: "#141414" },
        },
      }),
      ui.spacer(),
      ui.text(selected + " selected", {
        bold: true,
        style: { fg: "#141414", fontSize: 9.5 },
      }),
    ]),
    ui.scene3d(118, {
      id: "orbit",
      shape: "cube",
      look: "toon",
      yaw: yaw,
      pitch: pitch,
      color: "#00D4FF",
      color2: "#B8FF2C",
      outline: "#141414",
      outlineWidth: 2.2,
      bg: "#FFFFFF",
      grid: true,
      style: {
        border: "#141414",
        borderWidth: 2.2,
        radius: 10,
        shadow: { x: 3, y: 3, blur: 0, color: "#141414" },
      },
    }),
    ui.row([
      ui.knob("AMOUNT", amount, {
        id: "amount",
        min: 0,
        max: 1,
        def: 0.65,
        look: "pop",
        size: 44,
        color: "#FF3B7F",
        capColor: "#FFFFFF",
        borderColor: "#141414",
      }),
      ui.knob("PULSE", pulse, {
        id: "pulse",
        min: 0,
        max: 1,
        def: 0.45,
        look: "pop",
        size: 44,
        color: "#00D4FF",
        capColor: "#FFFFFF",
        borderColor: "#141414",
      }),
    ]),
    ui.button("Apply Scale to Selection", "apply", {
      accent: true,
      style: {
        bg: "#FFE600",
        fg: "#141414",
        border: "#141414",
        borderWidth: 2,
        radius: 8,
        height: 26,
        shadow: { x: 2, y: 2, blur: 0, color: "#141414" },
      },
    }),
  ], {
    bg: "#FFF4C4",
    fg: "#141414",
    muted: "#473F22",
    accent: "#FF3B7F",
    border: "#141414",
    borderWidth: 2.4,
    radius: 14,
    pad: 12,
    gap: 8,
    shadow: { x: 4, y: 4, blur: 0, color: "#141414" },
  });
}

function onAction(action, ctx) {
  if (action.id === "orbit" && action.value) {
    return {
      state: { yaw: Number(action.value.yaw), pitch: Number(action.value.pitch) },
    };
  }
  if (action.id === "amount" || action.id === "pulse") {
    return { state: { [action.id]: Number(action.value) } };
  }
  if (action.id === "apply") {
    const scale = 0.5 + Number((ctx.state && ctx.state.amount) ?? 0.65);
    const ops = [];
    for (const id of ctx.selected || []) {
      ops.push({ op: "set", layer: id, name: "scale_x", value: scale });
      ops.push({ op: "set", layer: id, name: "scale_y", value: scale });
    }
    return {
      ops: ops,
      notice: ops.length ? "Applied scale " + scale.toFixed(2) : "Select a layer first",
    };
  }
  return {};
}
''';

/// Target shelf subfolder for a pack [kind].
String _rootForKind(String kind) => switch (kind) {
  'panel' => 'panels',
  'expression' => 'expressions',
  'create' => 'create',
  _ => 'effects',
};

/// Companion sidecar files beside [mainFile] (same stem: `.vs`, `.ui.js`, `.png`, `.webp`, `.jpg`, `.glb`, `.obj`, `.frag`).
List<File> companionFilesOf(String mainFile) {
  final file = File(mainFile);
  final dir = file.parent;
  final base = slashed(mainFile).split('/').last;
  final dot = base.lastIndexOf('.');
  final stem = dot > 0 ? base.substring(0, dot) : base;
  final companions = <File>[];
  for (final suffix in _companionSuffixes) {
    final candidate = File('${dir.path}/$stem$suffix');
    if (candidate.existsSync() &&
        slashed(candidate.path) != slashed(mainFile)) {
      companions.add(candidate);
    }
  }
  return companions;
}

/// Validates a relative path from a pack manifest (rejects traversal or unknown roots).
bool _isSafePackRelPath(String rel) {
  final norm = slashed(rel);
  if (norm.isEmpty || norm.startsWith('/') || norm.contains(':')) return false;
  final parts = norm.split('/');
  if (parts.length < 2) return false;
  if (!_allowedRoots.contains(parts.first)) return false;
  for (final seg in parts) {
    if (seg.isEmpty || seg == '.' || seg == '..') return false;
  }
  return true;
}

/// Creates a `.motoliipack` ZIP archive from [sourceFile] plus companion `.vs`/`.ui.js`/`.png` files and credits.
PackExportResult exportMotoliiPack({
  required String sourceFile,
  required String kind,
  required String outPath,
  String? name,
  String? author,
  String? license,
  String? source,
}) {
  final main = File(sourceFile);
  if (!main.existsSync()) {
    throw FileSystemException('Source file not found', sourceFile);
  }
  final destPath = isMotoliiPackPath(outPath)
      ? outPath
      : '$outPath$_packExtension';
  final root = _rootForKind(kind);
  final mainBase = slashed(main.path).split('/').last;
  final stem = mainBase.contains('.')
      ? mainBase.substring(0, mainBase.lastIndexOf('.'))
      : mainBase;
  final packName = (name != null && name.trim().isNotEmpty)
      ? name.trim()
      : stem;
  final meta = shelfMetaOfFile(sourceFile);

  final stage = Directory.systemTemp.createTempSync('motolii_pack_out_');
  try {
    final targetDir = Directory('${stage.path}/$root')
      ..createSync(recursive: true);
    final relFiles = <String>[];
    for (final f in [main, ...companionFilesOf(sourceFile)]) {
      final fname = slashed(f.path).split('/').last;
      f.copySync('${targetDir.path}/$fname');
      relFiles.add('$root/$fname');
    }
    final presets = readPanelPresets(packName);
    if (presets.isNotEmpty) {
      File(
        '${stage.path}/presets.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(presets));
    }
    final manifest = <String, Object?>{
      'version': _packVersion,
      'kind': kind,
      'name': packName,
      'author': author ?? meta?.author ?? '',
      'license': license ?? meta?.license ?? '',
      'source': source ?? meta?.source ?? '',
      'files': relFiles,
      if (presets.isNotEmpty) 'hasPresets': true,
    };
    File(
      '${stage.path}/motoliipack.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));

    final destFile = File(destPath);
    destFile.parent.createSync(recursive: true);
    if (destFile.existsSync()) destFile.deleteSync();
    _zipDirectory(stage.path, destFile.path);
    return (
      path: slashed(destFile.path),
      name: packName,
      fileCount: relFiles.length,
    );
  } finally {
    try {
      stage.deleteSync(recursive: true);
    } catch (_) {}
  }
}

/// Imports a `.motoliipack` / `.motolii-card` archive or a dropped 1-folder VST bundle
/// into [ownFolder] (`effects/`, `expressions/`, `panels/`, `create/`).
PackImportResult importMotoliiPack(
  String packPath, {
  required String ownFolder,
}) {
  final asDir = Directory(packPath);
  if (asDir.existsSync()) {
    return _importFolderBundle(asDir, ownFolder: ownFolder);
  }
  final packFile = File(packPath);
  if (!packFile.existsSync()) {
    throw FileSystemException('Pack file not found', packPath);
  }
  final stage = Directory.systemTemp.createTempSync('motolii_pack_in_');
  try {
    _unzipArchive(packFile.path, stage.path);
    return _importFolderBundle(
      stage,
      ownFolder: ownFolder,
      fallbackName: packPath,
    );
  } finally {
    try {
      stage.deleteSync(recursive: true);
    } catch (_) {}
  }
}

PackImportResult _importFolderBundle(
  Directory stage, {
  required String ownFolder,
  String? fallbackName,
}) {
  final manifestFile = File('${stage.path}/motoliipack.json');
  if (!manifestFile.existsSync()) {
    // Plain 1-folder VST drop: infer kind and copy all bundled code + assets together.
    final entries = [
      for (final e in stage.listSync(recursive: true).whereType<File>())
        if (!slashed(e.path).split('/').last.startsWith('.')) e,
    ];
    if (entries.isEmpty) {
      throw const FormatException('Invalid bundle folder: empty');
    }
    final hasShader = entries.any(
      (f) => f.path.endsWith('.fs') || f.path.endsWith('.wgsl'),
    );
    final hasUiCard = entries.any((f) => f.path.endsWith('.ui.js'));
    final kind = hasShader ? 'effect' : (hasUiCard ? 'expression' : 'panel');
    final root = _rootForKind(kind);
    final bundleName = slashed(fallbackName ?? stage.path).split('/').last;
    final prefix = slashed(stage.path);
    final installed = <String>[];
    for (final f in entries) {
      final rel = slashed(f.path).substring(prefix.length + 1);
      if (rel.contains('..')) continue;
      final dest = File('$ownFolder/$root/$rel');
      dest.parent.createSync(recursive: true);
      f.copySync(dest.path);
      installed.add(slashed(dest.path));
    }
    return (name: bundleName, kind: kind, installedPaths: installed);
  }
  final decoded = jsonDecode(manifestFile.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Invalid pack: manifest is not an object');
  }
  final version = decoded['version'];
  if (version is! int || version > _packVersion) {
    throw FormatException('Unsupported pack version: $version');
  }
  final rawFiles = decoded['files'];
  if (rawFiles is! List || rawFiles.isEmpty) {
    throw const FormatException('Invalid pack: no files listed');
  }
  final kind = '${decoded['kind'] ?? 'effect'}';
  final name = '${decoded['name'] ?? ''}'.trim();
  final installed = <String>[];
  String? creditRoot;
  for (final entry in rawFiles) {
    final rel = '$entry';
    if (!_isSafePackRelPath(rel)) {
      throw FormatException('Unsafe path in pack: $rel');
    }
    final src = File('${stage.path}/$rel');
    if (!src.existsSync()) {
      throw FormatException('Missing file in pack: $rel');
    }
    final dest = File('$ownFolder/$rel');
    dest.parent.createSync(recursive: true);
    src.copySync(dest.path);
    installed.add(slashed(dest.path));
    creditRoot ??= rel.split('/').first;
  }

  final author = '${decoded['author'] ?? ''}'.trim();
  final license = '${decoded['license'] ?? ''}'.trim();
  final source = '${decoded['source'] ?? ''}'.trim();
  if (creditRoot != null &&
      (author.isNotEmpty || license.isNotEmpty || source.isNotEmpty)) {
    _appendMetaCredit(
      '$ownFolder/$creditRoot/meta.yaml',
      name: name.isEmpty ? 'Pack' : name,
      author: author,
      license: license,
      source: source,
    );
  }
  final presetsFile = File('${stage.path}/presets.json');
  final resolvedName = name.isEmpty
      ? slashed(fallbackName ?? stage.path).split('/').last
      : name;
  if (presetsFile.existsSync()) {
    try {
      final rawPresets = jsonDecode(presetsFile.readAsStringSync());
      if (rawPresets is Map) {
        mergePanelPresets(resolvedName, {
          for (final e in rawPresets.entries) e.key.toString(): e.value,
        });
      }
    } catch (_) {}
  }
  return (name: resolvedName, kind: kind, installedPaths: installed);
}

void _appendMetaCredit(
  String metaPath, {
  required String name,
  required String author,
  required String license,
  required String source,
}) {
  final file = File(metaPath);
  final existing = file.existsSync() ? file.readAsStringSync() : '';
  final key = '${_yamlQuote(name)}:';
  if (existing.contains(key)) return;
  final buf = StringBuffer(existing);
  if (existing.isNotEmpty && !existing.endsWith('\n')) buf.writeln();
  buf.writeln(key);
  if (author.isNotEmpty) buf.writeln('  author: ${_yamlQuote(author)}');
  if (license.isNotEmpty) buf.writeln('  license: ${_yamlQuote(license)}');
  if (source.isNotEmpty) buf.writeln('  source: ${_yamlQuote(source)}');
  buf.writeln('  origin: community');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(buf.toString());
}

String _yamlQuote(String s) =>
    '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

void _zipDirectory(String sourceDir, String zipPath) {
  final res = hostIsWindows
      ? Process.runSync('powershell', [
          '-NoProfile',
          '-Command',
          "Compress-Archive -Path '${sourceDir.replaceAll("'", "''")}\\*' -DestinationPath '${zipPath.replaceAll("'", "''")}' -Force",
        ])
      : Process.runSync('zip', [
          '-rq',
          zipPath,
          '.',
        ], workingDirectory: sourceDir);
  if (res.exitCode != 0) {
    throw ProcessException(
      hostIsWindows ? 'powershell' : 'zip',
      [zipPath],
      '${res.stderr}'.trim(),
      res.exitCode,
    );
  }
}

void _unzipArchive(String zipPath, String destDir) {
  final res = hostIsWindows
      ? Process.runSync('powershell', [
          '-NoProfile',
          '-Command',
          "Expand-Archive -Path '${zipPath.replaceAll("'", "''")}' -DestinationPath '${destDir.replaceAll("'", "''")}' -Force",
        ])
      : Process.runSync('unzip', ['-qo', zipPath, '-d', destDir]);
  if (res.exitCode != 0) {
    throw ProcessException(
      hostIsWindows ? 'powershell' : 'unzip',
      [zipPath],
      '${res.stderr}'.trim(),
      res.exitCode,
    );
  }
}
