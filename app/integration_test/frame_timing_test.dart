// External requirement: the window's timeline scrolled with a mouse wheel stays inside Flutter's frame budget
// (about 16 ms a frame, 60 fps). Pattern: https://docs.flutter.dev/cookbook/testing/integration/profiling
// The app is the Workspace window of lib/main.dart, over a document of 40 shapes.
//   cd app && FLUTTER_TEST_OUTPUTS_DIR=build/test_output flutter drive --profile -d macos --driver=test_driver/frame_timing_driver.dart --target=integration_test/frame_timing_test.dart
import 'dart:io';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:motolii/workspace/timeline/timeline.dart';
import 'package:motolii/workspace/workspace.dart' show Workspace;
import 'package:motolii/workspace/ws.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('scrolling the timeline keeps the frame budget', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.menu, (_) async => null);
    final doc = '${Directory.systemTemp.createTempSync('frame_timing').path}/frame_timing.motolii';
    await tester.pumpWidget(WidgetsApp(color: const Color(0xFF000000), builder: (c, _) => Workspace(document: doc)));
    await tester.pumpAndSettle();

    // a document with enough tracks that the timeline has something to scroll
    final ws = WsScope.read(tester.element(find.byType(WsTimeline)));
    for (var i = 0; i < 40; i++) {
      ws.inside!.add('shape', i.isEven ? 'rect' : 'circle');
    }
    ws.reread();
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));   // (what the window reads as it opens finishes before the hand moves)

    final wheel = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(wheel.hover(tester.getCenter(find.byType(WsTimeline))));
    await binding.traceAction(() async {
      for (var i = 0; i < 120; i++) {   // down, up, and sideways: one wheel notch a frame, about two seconds
        final dy = (i ~/ 30).isEven ? 40.0 : -40.0;
        await tester.sendEventToBinding(wheel.scroll(i % 4 == 3 ? Offset(dy, 0) : Offset(0, dy)));
        await tester.pump();
      }
    }, reportKey: 'frame_timing');
  });
}
