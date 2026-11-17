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
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/timeline.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/workspace.dart' show Workspace;
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('scrolling the timeline keeps the frame budget', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.menu,
      (_) async => null,
    );
    final doc =
        '${Directory.systemTemp.createTempSync('frame_timing').path}/frame_timing.motolii';
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (c, _) => Workspace(document: doc),
      ),
    );
    await tester.pumpAndSettle();

    // a document with enough tracks that the timeline has something to scroll
    final ws = WorkspaceScope.read(tester.element(find.byType(TimelinePane)));
    for (var i = 0; i < 40; i++) {
      ws.inside!.add('shape', i.isEven ? 'rect' : 'circle');
    }
    ws.reread();
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    ); // (what the window reads as it opens finishes before the hand moves)

    final wheel = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      wheel.hover(tester.getCenter(find.byType(TimelinePane))),
    );
    await binding.traceAction(() async {
      for (var i = 0; i < 120; i++) {
        // down, up, and sideways: one wheel notch a frame, about two seconds
        final dy = (i ~/ 30).isEven ? 40.0 : -40.0;
        await tester.sendEventToBinding(
          wheel.scroll(i % 4 == 3 ? Offset(dy, 0) : Offset(0, dy)),
        );
        await tester.pump();
      }
    }, reportKey: 'frame_timing');
  });

  testWidgets('dragging a bar keeps the frame budget', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.menu,
      (_) async => null,
    );
    final doc =
        '${Directory.systemTemp.createTempSync('frame_bar').path}/frame_bar.motolii';
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (c, _) => Workspace(document: doc),
      ),
    );
    await tester.pumpAndSettle();

    final ws = WorkspaceScope.read(tester.element(find.byType(TimelinePane)));
    for (var i = 0; i < 40; i++) {
      ws.inside!.add('shape', i.isEven ? 'rect' : 'circle');
    }
    ws.reread();
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );

    // The bar of the first visible layer: row centre, horizontally within the bar.
    final top = tester.getTopLeft(find.byKey(const ValueKey('ws-tl-tracks')));
    final size = tester.getSize(find.byKey(const ValueKey('ws-tl-tracks')));
    final barCenter = top + Offset(size.width / 2, TimelineMetrics.row / 2);

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.down(barCenter));
    await tester.pump();
    // exceed pan-recognition slop
    await tester.sendEventToBinding(
      pointer.move(barCenter + const Offset(20, 0)),
    );
    await tester.pump();

    await binding.traceAction(() async {
      for (var i = 0; i < 60; i++) {
        await tester.sendEventToBinding(
          pointer.move(barCenter + Offset(20.0 + i * 3.0, 0)),
        );
        await tester.pump();
      }
    }, reportKey: 'bar_drag');

    await tester.sendEventToBinding(pointer.up());
    await tester.pumpAndSettle();
  });

  testWidgets('sliding keyframes keeps the frame budget', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.menu,
      (_) async => null,
    );
    final doc =
        '${Directory.systemTemp.createTempSync('frame_key').path}/frame_key.motolii';
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (c, _) => Workspace(document: doc),
      ),
    );
    await tester.pumpAndSettle();

    final ws = WorkspaceScope.read(tester.element(find.byType(TimelinePane)));
    final m = ws.inside!;
    for (var i = 0; i < 40; i++) {
      m.add('shape', i.isEven ? 'rect' : 'circle');
    }
    ws.reread();
    await tester.pumpAndSettle();

    // Add a keyframe on each layer's first keyable property at the project midpoint.
    final mid = WorkspaceController.duration ~/ 2;
    for (final l in ws.layers) {
      final t = int.parse(l.id);
      final props = m.moving(t);
      if (props.isNotEmpty) {
        m.later(
          'key_here',
          layer: t,
          name: props.first,
          number: mid / WorkspaceController.fps,
        );
      }
    }
    await tester.pumpAndSettle();
    ws.reread();
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );

    // Target the keyframe diamond at the midpoint of the first layer's row.
    final top = tester.getTopLeft(find.byKey(const ValueKey('ws-tl-tracks')));
    final size = tester.getSize(find.byKey(const ValueKey('ws-tl-tracks')));
    final ppf =
        (size.width - TimelineMetrics.padL - TimelineMetrics.padR) /
        WorkspaceController.duration;
    final keyX = top.dx + TimelineMetrics.padL + mid * ppf;
    final keyY = top.dy + TimelineMetrics.row / 2;
    final keyCenter = Offset(keyX, keyY);

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.down(keyCenter));
    await tester.pump();
    await tester.sendEventToBinding(
      pointer.move(keyCenter + const Offset(20, 0)),
    );
    await tester.pump();

    await binding.traceAction(() async {
      for (var i = 0; i < 60; i++) {
        await tester.sendEventToBinding(
          pointer.move(keyCenter + Offset(20.0 + i * 3.0, 0)),
        );
        await tester.pump();
      }
    }, reportKey: 'keyframe_slide');

    await tester.sendEventToBinding(pointer.up());
    await tester.pumpAndSettle();
  });
}
