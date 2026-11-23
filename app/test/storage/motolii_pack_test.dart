// Phase 3 tests: `.motoliipack` export (with companion .ui.js/.vs/credits), clean import, and path-traversal rejection.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/storage/motolii_pack.dart';
import 'package:motolii/storage/panel_presets_file.dart';

void main() {
  test('exports effect with .ui.js companion and imports cleanly into fresh ownFolder', () {
    final tmp = Directory.systemTemp.createTempSync('motolii_pack_test_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final srcDir = Directory('${tmp.path}/src/effects')
      ..createSync(recursive: true);
    final fsFile = File('${srcDir.path}/NeonPulse.fs')
      ..writeAsStringSync('/* ISF shader */ void main() {}');
    File('${srcDir.path}/NeonPulse.ui.js').writeAsStringSync(
      'export function renderCard(ctx) { return {type:"column", children:[]}; }',
    );
    File('${srcDir.path}/NeonPulse.vs').writeAsStringSync('// vertex shader');

    final packOut = '${tmp.path}/out/NeonPulse.motoliipack';
    final exported = exportMotoliiPack(
      sourceFile: fsFile.path,
      kind: 'effect',
      outPath: packOut,
      name: 'Neon Pulse',
      author: 'Tester',
      license: 'MIT',
      source: 'https://example.com/neon',
    );
    expect(File(exported.path).existsSync(), isTrue);
    expect(exported.fileCount, 3);

    final cleanOwn = '${tmp.path}/clean_user_own';
    final imported = importMotoliiPack(exported.path, ownFolder: cleanOwn);
    expect(imported.name, 'Neon Pulse');
    expect(imported.kind, 'effect');
    expect(imported.installedPaths.length, 3);
    expect(File('$cleanOwn/effects/NeonPulse.fs').existsSync(), isTrue);
    expect(File('$cleanOwn/effects/NeonPulse.ui.js').existsSync(), isTrue);
    expect(File('$cleanOwn/effects/NeonPulse.vs').existsSync(), isTrue);
    final meta = File('$cleanOwn/effects/meta.yaml').readAsStringSync();
    expect(meta, contains('Neon Pulse'));
    expect(meta, contains('Tester'));
    expect(meta, contains('MIT'));
  });

  test('exports and imports a real bundled effect with .ui.js (Diagonal Blur)', () {
    final tmp = Directory.systemTemp.createTempSync('motolii_pack_real_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final blurFs =
        '${Directory.current.parent.path}/shelves/effects/blur/Diagonal Blur.fs';
    expect(File(blurFs).existsSync(), isTrue);

    final exported = exportMotoliiPack(
      sourceFile: blurFs,
      kind: 'effect',
      outPath: '${tmp.path}/DiagonalBlur',
      name: 'Diagonal Blur',
    );
    expect(exported.path, endsWith('.motoliipack'));
    expect(exported.fileCount, greaterThanOrEqualTo(2));

    final cleanOwn = '${tmp.path}/clean_own';
    final imported = importMotoliiPack(exported.path, ownFolder: cleanOwn);
    expect(File('$cleanOwn/effects/Diagonal Blur.fs').existsSync(), isTrue);
    expect(File('$cleanOwn/effects/Diagonal Blur.ui.js').existsSync(), isTrue);
    expect(imported.installedPaths.length, exported.fileCount);
  });

  test('exports and imports a Tool Panel QuickJS script into panels/', () {
    final tmp = Directory.systemTemp.createTempSync('motolii_pack_panel_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final panelJs = File('${tmp.path}/grid_align.js')
      ..writeAsStringSync('export const meta = { name: "Grid Align" };');
    final exported = exportMotoliiPack(
      sourceFile: panelJs.path,
      kind: 'panel',
      outPath: '${tmp.path}/GridAlign.motoliipack',
      name: 'Grid Align',
    );
    final cleanOwn = '${tmp.path}/clean_own';
    final imported = importMotoliiPack(exported.path, ownFolder: cleanOwn);
    expect(imported.kind, 'panel');
    expect(File('$cleanOwn/panels/grid_align.js').existsSync(), isTrue);
  });

  test('rejects path traversal in manifest on import', () {
    final tmp = Directory.systemTemp.createTempSync('motolii_pack_evil_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final stage = Directory('${tmp.path}/stage')..createSync();
    File('${stage.path}/motoliipack.json').writeAsStringSync(
      jsonEncode({
        'version': 1,
        'kind': 'effect',
        'name': 'Evil',
        'files': ['effects/../../pwned.txt'],
      }),
    );
    final evilZip = '${tmp.path}/evil.motoliipack';
    final r = Process.runSync('zip', [
      '-rq',
      evilZip,
      '.',
    ], workingDirectory: stage.path);
    expect(r.exitCode, 0);

    expect(
      () => importMotoliiPack(evilZip, ownFolder: '${tmp.path}/own'),
      throwsA(isA<FormatException>()),
    );
  });

  test('bundles and restores Vism presets in .vism packages', () {
    final tmp = Directory.systemTemp.createTempSync('vism_preset_pack_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    const testName = 'VismPresetBundleTest_Unique';
    writePanelPresets(testName, {
      'Punchy': {'amount': 0.88, 'mode': 'POP'},
    });
    addTearDown(() => writePanelPresets(testName, const {}));

    final panelJs = File('${tmp.path}/vism_test.js')
      ..writeAsStringSync(
        '// --title: $testName\nfunction render(){return ui.text("ok");}',
      );
    final exported = exportMotoliiPack(
      sourceFile: panelJs.path,
      kind: 'panel',
      outPath: '${tmp.path}/$testName.vism',
      name: testName,
    );
    expect(exported.path, endsWith('.vism'));

    // Clear local presets before importing to verify restore from archive.
    writePanelPresets(testName, const {});
    expect(readPanelPresets(testName), isEmpty);

    importMotoliiPack(exported.path, ownFolder: '${tmp.path}/own');
    final restored = readPanelPresets(testName);
    expect(restored['Punchy'], {'amount': 0.88, 'mode': 'POP'});
  });
}
