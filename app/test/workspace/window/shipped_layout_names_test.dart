// A shipped workspace layout names its panes; a pane renamed in code but not in the file stops the workspace opening.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/bridge/engine_paths.dart' show motoliiShelves;
import 'package:motolii/workspace/workspace_panes.dart' show workspacePanes;

void main() {
  final panes = {for (final p in workspacePanes) p.name};
  final files = Directory('$motoliiShelves/workspaces')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.layout'));

  test('there is a shipped layout to check', () => expect(files, isNotEmpty));

  for (final file in files) {
    test('${file.uri.pathSegments.last} names only panes that exist', () {
      // docking writes a pane as `(I;<length>;<name>;...)`.
      final named = RegExp(r'\(I;\d+;([^;]*);')
          .allMatches(file.readAsStringSync())
          .map((m) => m[1]!)
          .toList();
      expect(named, isNotEmpty);
      expect(panes, containsAll(named));
    });
  }
}
