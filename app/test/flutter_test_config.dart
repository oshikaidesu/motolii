import 'dart:async';

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
  });
  await testMain();
}
