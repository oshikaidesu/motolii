// Golden: core control primitives contact sheet.
// Chip (tool/readout/tag/relate looks, on/off), PopSwitch, DisclosureTriangle,
// PanelHeader, Badge — everything that needs no engine.
// Run with:
//   flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes --update-goldens test/golden/
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Badge, Chip, ChipLook;
import 'package:motolii/widgets/disclosure_triangle.dart';
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/widgets/switch_track.dart';

import '../main_tests_only.dart';

void main() {
  if (skipUnlessEveryTest()) return;

  testWidgets('controls contact sheet', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: DarkGrey.g13,
          child: SizedBox(
            width: 500,
            height: 700,
            child: Padding(
              padding: EdgeInsets.all(Shape.s(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Chips: tool look ---
                  _label('Chip — tool'),
                  Wrap(
                    spacing: Shape.s(4),
                    runSpacing: Shape.s(4),
                    children: [
                      Chip(label: 'Off', on: false, onTap: null),
                      Chip(label: 'On', on: true, onTap: null),
                      Chip(
                        label: 'Dot',
                        dot: Accent.fill,
                        on: false,
                        onTap: null,
                      ),
                      Chip(
                        label: 'Dot on',
                        dot: Accent.fill,
                        on: true,
                        onTap: null,
                      ),
                    ],
                  ),
                  SizedBox(height: Shape.s(10)),

                  // --- Chips: readout ---
                  _label('Chip — readout'),
                  Row(
                    children: [
                      _intrinsic(
                        Chip(
                          label: '24.00 fps',
                          look: ChipLook.readout(ink: Grey.g76),
                        ),
                      ),
                      SizedBox(width: Shape.s(4)),
                      _intrinsic(
                        Chip(
                          label: '1920 × 1080',
                          look: ChipLook.readout(ink: Grey.g91),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Shape.s(10)),

                  // --- Chips: tag ---
                  _label('Chip — tag'),
                  Row(
                    children: [
                      _intrinsic(
                        Chip(label: 'Color', look: ChipLook.tag(null)),
                      ),
                      SizedBox(width: Shape.s(4)),
                      _intrinsic(
                        Chip(
                          label: 'Blur',
                          look: ChipLook.tag(const Color(0xFF69B0AC)),
                        ),
                      ),
                      SizedBox(width: Shape.s(4)),
                      _intrinsic(
                        Chip(
                          label: 'Edge',
                          look: ChipLook.tag(
                            const Color(0xFFDC9FB4),
                            edge: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Shape.s(10)),

                  // --- Chips: relate ---
                  _label('Chip — relate'),
                  Wrap(
                    spacing: Shape.s(4),
                    children: [
                      Chip(label: 'Group', on: false, look: ChipLook.relate),
                      Chip(label: 'Group', on: true, look: ChipLook.relate),
                    ],
                  ),
                  SizedBox(height: Shape.s(14)),

                  // --- PopSwitch ---
                  _label('PopSwitch'),
                  Row(
                    children: [
                      const PopSwitch(on: false),
                      SizedBox(width: Shape.s(8)),
                      const PopSwitch(on: true),
                    ],
                  ),
                  SizedBox(height: Shape.s(14)),

                  // --- DisclosureTriangle ---
                  _label('DisclosureTriangle'),
                  Row(
                    children: [
                      const DisclosureTriangle(open: false, hot: false),
                      SizedBox(width: Shape.s(6)),
                      const DisclosureTriangle(open: false, hot: true),
                      SizedBox(width: Shape.s(6)),
                      const DisclosureTriangle(open: true, hot: false),
                      SizedBox(width: Shape.s(6)),
                      const DisclosureTriangle(open: true, hot: true),
                    ],
                  ),
                  SizedBox(height: Shape.s(14)),

                  // --- Badge ---
                  _label('Badge'),
                  Row(
                    children: [
                      Badge(WindowTokens.accent, size: 20),
                      SizedBox(width: Shape.s(4)),
                      Badge(Grey.g38, size: 20),
                      SizedBox(width: Shape.s(4)),
                      Badge(const Color(0xFF69B0AC), size: 20),
                    ],
                  ),
                  SizedBox(height: Shape.s(14)),

                  // --- PanelHeader ---
                  _label('PanelHeader'),
                  SizedBox(width: 460, child: PanelHeader('Inspector')),
                  SizedBox(height: Shape.s(4)),
                  SizedBox(
                    width: 460,
                    child: PanelHeader(
                      'Timeline',
                      trailing: [
                        Chip(
                          label: '24 fps',
                          look: ChipLook.readout(ink: Grey.g76),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ColoredBox).first,
      matchesGoldenFile('goldens/controls_contact.png'),
    );
  });
}

Widget _label(String s) => Padding(
  padding: EdgeInsets.only(bottom: Shape.s(4)),
  child: Text(s, style: TextStyles.label(Grey.g56)),
);

Widget _intrinsic(Widget child) => IntrinsicWidth(child: child);
