// Golden: render dialog header and format tabs.
// Shows the visual anchor of the render panel (comp thumbnail + size, work area, format row).
// The full dialog needs WorkspaceController; this golden covers the parts that need no engine.
// Run with:
//   flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes --update-goldens test/golden/
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip;
import 'package:motolii/widgets/modal_card.dart';
import 'package:motolii/workspace/top_bar/render_button.dart' show RenderHeader;

import '../main_tests_only.dart';

void main() {
  if (skipUnlessEveryTest()) return;

  testWidgets('render dialog — header and format tabs (1920 × 1080, 5 s)', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 600,
          height: 700,
          child: ModalCard(
            title: 'Render',
            onClose: () {},
            across: CrossAxisAlignment.stretch,
            children: [
              RenderHeader(w: 1920, h: 1080, from: 0, to: 5, frames: 150),
              SizedBox(height: Shape.s(14)),
              // Format tabs row (static, MP4 on)
              Wrap(
                spacing: Shape.s(4),
                children: [
                  for (final (label, on) in const [
                    ('MP4', true),
                    ('HEVC', false),
                    ('GIF', false),
                    ('PNG', false),
                    ('JPEG', false),
                  ])
                    _FormatChip(label: label, on: on),
                ],
              ),
              SizedBox(height: Shape.s(6)),
              Text(
                "H.264, with the films' sound",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.label(Grey.g76),
              ),
              SizedBox(height: Shape.s(14)),
              // File name stub
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
                child: Text('film.mp4', style: TextStyles.value(Grey.g95)),
              ),
              SizedBox(height: Shape.s(14)),
              ChipGroup('Resolution', [
                Chip(label: 'Full', on: true, onTap: null),
                Chip(label: '1080p', on: false, onTap: null),
                Chip(label: '720p', on: false, onTap: null),
              ]),
              SizedBox(height: Shape.s(10)),
              ChipGroup('Quality', [
                Chip(label: 'Auto', on: true, onTap: null),
                Chip(label: '8 Mbps', on: false, onTap: null),
                Chip(label: '16 Mbps', on: false, onTap: null),
              ]),
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
                    'Render',
                    style: TextStyles.name(WindowTokens.onAccent)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(ModalCard),
      matchesGoldenFile('goldens/render_dialog.png'),
    );
  });
}

/// A simple format pill for the golden snapshot (mimics _FormatTab visually without needing WorkspaceController).
class _FormatChip extends StatelessWidget {
  const _FormatChip({required this.label, required this.on});
  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: Shape.s(14),
      vertical: Shape.s(7),
    ),
    decoration: BoxDecoration(
      color: on ? WindowTokens.accent : WindowTokens.well,
      borderRadius: Shape.round(5),
      border: Border.all(color: on ? WindowTokens.accent : WindowTokens.line),
    ),
    child: Text(
      label,
      style: (on ? TextStyles.value(Accent.on) : TextStyles.value(Grey.g91))
          .copyWith(fontWeight: FontWeight.w700),
    ),
  );
}
