// Golden: code editor with syntax-highlighted JavaScript.
// Run with:
//   flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes --update-goldens test/golden/code_field_golden_test.dart
import 'dart:io' show Directory, File;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/shelf/code_field.dart';

import '../main_tests_only.dart';

void main() {
  if (skipUnlessEveryTest()) return;

  late String jsPath;
  setUp(() {
    final dir = Directory.systemTemp.createTempSync('code_field_test_');
    final f = File('${dir.path}/test.js');
    f.writeAsStringSync(
      '// Each copy: position by index, fade with time.\n'
      'function each(index, count, time, value) {\n'
      '  return {\n'
      '    x: index * 120,\n'
      '    y: Math.sin(time + index) * 40,\n'
      '    opacity: 1.0 - time * 0.1,\n'
      '  };\n'
      '}\n',
    );
    jsPath = f.path;
  });

  testWidgets('code editor — JavaScript expression (600×300)', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 600,
          height: 300,
          child: ColoredBox(
            color: WindowTokens.well,
            child: CodeField(jsPath, (_) {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(
      find.byType(CodeField),
      matchesGoldenFile('goldens/code_field_js.png'),
    );
  });
}
