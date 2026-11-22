// Phase 2 onboarding tests: bundled starter samples discovery/copying and Agent starter prompts.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/storage/project_files.dart';
import 'package:motolii/workspace/agent/agent_pane.dart';
import 'package:motolii/workspace/window/home_project.dart';

void main() {
  test('sampleProjectsIn lists bundled starter samples in sorted order', () {
    final samplesDir = '${Directory.current.parent.path}/shelves/samples';
    final found = sampleProjectsIn(samplesDir);
    expect(found.length, 3);
    expect(found[0].path, endsWith('01_Japanese_Typography.motolii'));
    expect(found[1].path, endsWith('02_Motion_Shapes.motolii'));
    expect(found[2].path, endsWith('03_Custom_Card_Playground.motolii'));
  });

  test('sampleTitle strips numeric prefix and underscores', () {
    final p = HomeProject(
      '/tmp/01_Japanese_Typography.motolii',
      DateTime(2026),
      100,
    );
    expect(sampleTitle(p), 'Japanese Typography');
  });

  test(
    'copySampleProject copies without mutating source and avoids collisions',
    () {
      final tmp = Directory.systemTemp.createTempSync('motolii_sample_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final srcFile = File('${tmp.path}/01_Japanese_Typography.motolii')
        ..writeAsStringSync('sample-bytes');
      final destDir = Directory('${tmp.path}/projects')..createSync();
      final sample = HomeProject(srcFile.path, DateTime(2026), 12);

      final first = copySampleProject(destDir.path, sample);
      expect(first, '${destDir.path}/Japanese Typography.motolii');
      expect(File(first).readAsStringSync(), 'sample-bytes');

      final second = copySampleProject(destDir.path, sample);
      expect(second, '${destDir.path}/Japanese Typography 2.motolii');
      expect(File(second).readAsStringSync(), 'sample-bytes');
      expect(srcFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'AgentStarterPrompts renders all 4 prompts and fires onPick on tap',
    (tester) async {
      String? picked;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            child: AgentStarterPrompts(onPick: (p) => picked = p),
          ),
        ),
      );

      expect(find.text('TRY ASKING'), findsOneWidget);
      for (final s in agentStarterPrompts) {
        expect(find.byKey(ValueKey('agent-starter-${s.id}')), findsOneWidget);
        expect(find.text(s.title), findsOneWidget);
      }

      await tester.tap(find.byKey(const ValueKey('agent-starter-jp-wave')));
      await tester.pump();
      expect(picked, agentStarterPrompts.first.prompt);
    },
  );
}
