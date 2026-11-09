// External requirement: Flutter's own frame budget (about 16 ms a frame, 60 fps) while the timeline is scrolled.
// Pattern from https://docs.flutter.dev/cookbook/testing/integration/profiling (Measure performance with an integration test).
//   cd app && FLUTTER_TEST_OUTPUTS_DIR=build/test_output flutter drive --profile -d macos --driver=test_driver/frame_timing_driver.dart --target=integration_test/frame_timing_test.dart
// The timeline and its summary go to build/test_output/frame_timing.timeline.json and frame_timing.timeline_summary.json;
// FLUTTER_TEST_OUTPUTS_DIR (flutter_driver's own setting) puts the driver's command log there too, instead of in build/.
import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      final timeline = driver.Timeline.fromJson(data['frame_timing'] as Map<String, dynamic>);
      final summary = driver.TimelineSummary.summarize(timeline);
      // (chrome://tracing opens the full timeline; the summary has the budget counts)
      await summary.writeTimelineToFile('frame_timing', pretty: true, includeSummary: true, destinationDirectory: 'build/test_output');
      final s = summary.summaryJson;
      final frames = s['frame_count'] as int;
      final build = s['missed_frame_build_budget_count'] as int;
      final raster = s['missed_frame_rasterizer_budget_count'] as int;
      // ignore: avoid_print
      print(
        'frames $frames, missed build budget $build (worst ${s['worst_frame_build_time_millis']} ms), '
        'missed raster budget $raster (worst ${s['worst_frame_rasterizer_time_millis']} ms)',
      );
      if (frames == 0) throw StateError('no frames were recorded: the interaction drew nothing');
      if (build + raster > 0) throw StateError('$build build and $raster raster frames missed the 16 ms budget');
    },
  );
}
