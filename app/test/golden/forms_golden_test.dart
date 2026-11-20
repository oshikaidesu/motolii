// Golden: composed form primitives — ModalCard, ChipGroup, Segmented.
// These are the building blocks of dialogs and tool panels.
// Run with:
//   flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes --update-goldens test/golden/
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, Segmented;
import 'package:motolii/widgets/modal_card.dart';

import '../main_tests_only.dart';

void main() {
  if (skipUnlessEveryTest()) return;

  testWidgets('forms — modal card with chip groups and segmented', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: DarkGrey.g07,
          child: SizedBox(
            width: 500,
            height: 600,
            child: ModalCard(
              title: 'Settings',
              onClose: () {},
              across: CrossAxisAlignment.stretch,
              children: [
                ChipGroup('Format', [
                  Chip(label: 'MP4', on: true, onTap: null),
                  Chip(label: 'GIF', on: false, onTap: null),
                  Chip(label: 'PNG', on: false, onTap: null),
                  Chip(label: 'JPEG', on: false, onTap: null),
                ]),
                SizedBox(height: Shape.s(10)),
                ChipGroup('Quality', [
                  Chip(label: 'Auto', on: true, onTap: null),
                  Chip(label: 'Low', on: false, onTap: null),
                  Chip(label: 'High', on: false, onTap: null),
                ]),
                SizedBox(height: Shape.s(14)),
                Text('Dimension', style: TextStyles.label(Grey.g56)),
                SizedBox(height: Shape.s(6)),
                SizedBox(
                  width: 240,
                  child: Segmented(
                    items: const ['2D', '2.5D', '3D'],
                    index: 0,
                    onChanged: (_) {},
                  ),
                ),
                SizedBox(height: Shape.s(14)),
                // A well-styled text field stub
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Shape.s(10),
                    vertical: Shape.s(8),
                  ),
                  decoration: BoxDecoration(
                    color: WindowTokens.well,
                    borderRadius: Shape.round(5),
                    border: Border.all(color: WindowTokens.line),
                  ),
                  child: Text('output.mp4', style: TextStyles.value(Grey.g95)),
                ),
                SizedBox(height: Shape.s(16)),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    height: Shape.z(38),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: WindowTokens.accent,
                      borderRadius: Shape.round(6),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyles.name(WindowTokens.onAccent)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ModalCard),
      matchesGoldenFile('goldens/forms_modal.png'),
    );
  });
}
