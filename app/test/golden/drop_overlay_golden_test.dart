// Golden: drop overlay active state.
// Run with:
//   flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes --update-goldens test/golden/
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/drop_overlay.dart';

import '../main_tests_only.dart';

void main() {
  if (skipUnlessEveryTest()) return;

  testWidgets('drop overlay — active', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 800,
          height: 500,
          child: Stack(
            children: [
              ColoredBox(
                color: const Color(0xFF1E1E1E),
                child: const SizedBox.expand(),
              ),
              Positioned.fill(child: DropOverlay(active: true)),
            ],
          ),
        ),
      ),
    );
    await tester.pump(); // settle AnimatedOpacity
    await expectLater(
      find.byType(DropOverlay),
      matchesGoldenFile('goldens/drop_overlay_active.png'),
    );
  });

  testWidgets('drop overlay — inactive (invisible)', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 800,
          height: 500,
          child: Stack(
            children: [
              ColoredBox(
                color: const Color(0xFF1E1E1E),
                child: const SizedBox.expand(),
              ),
              Positioned.fill(child: DropOverlay(active: false)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(DropOverlay),
      matchesGoldenFile('goldens/drop_overlay_inactive.png'),
    );
  });
}
