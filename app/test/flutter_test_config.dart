import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('fonts/Inter-Variable.ttf'))).load();
    await (FontLoader(
      'Noto Sans JP',
    )..addFont(rootBundle.load('fonts/NotoSansJP-Regular.otf'))).load();
    await _loadSystemFont('Menlo', '/System/Library/Fonts/Menlo.ttc');
  });
  await testMain();
}

Future<void> _loadSystemFont(String family, String path) async {
  final file = File(path);
  if (!file.existsSync()) return;
  final bytes = file.readAsBytesSync();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}
