// Golden: top bar's Saved / progress indicator in its three states.
// Run with:
//   flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes --update-goldens test/golden/
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/top_bar/saved_display.dart';

import '../main_tests_only.dart';

Widget _around(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Container(
    color: const Color(0xFF1E1E1E),
    padding: const EdgeInsets.all(24),
    child: child,
  ),
);

void main() {
  if (skipUnlessEveryTest()) return;

  testWidgets('saved — idle (no notice)', (tester) async {
    await tester.pumpWidget(_around(const SavedDisplay(label: 'Saved 14:30')));
    await expectLater(
      find.byType(SavedDisplay),
      matchesGoldenFile('goldens/saved_idle.png'),
    );
  });

  testWidgets('saved — rendering with progress bar at 48%', (tester) async {
    await tester.pumpWidget(
      _around(
        SavedDisplay(
          label: 'Writing film.mp4 · 48%  ·  Cancel',
          progress: 0.48,
          onGo: () {},
        ),
      ),
    );
    await expectLater(
      find.byType(SavedDisplay),
      matchesGoldenFile('goldens/saved_rendering.png'),
    );
  });

  testWidgets('saved — written (notice, no progress)', (tester) async {
    await tester.pumpWidget(
      _around(const SavedDisplay(label: 'Written: film.mp4')),
    );
    await expectLater(
      find.byType(SavedDisplay),
      matchesGoldenFile('goldens/saved_written.png'),
    );
  });
}
