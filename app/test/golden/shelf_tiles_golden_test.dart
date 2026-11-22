// Golden: shelf tile and number field contact sheet.
// Covers the shelf tabs (Effects/Create/Media tile form, Fonts word form,
// list rows, empty state) and the inspector's numeric tiles.
// Uses the real widgets with mock data — no layout duplication.
// Run with:
//   flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes --update-goldens test/golden/
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/number_field.dart';
import 'package:motolii/widgets/number_field_look.dart';
import 'package:motolii/workspace/dock/common/empty_shelf.dart';
import 'package:motolii/workspace/shelf/shelf_looks.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';

import '../main_tests_only.dart';

void main() {
  if (skipUnlessEveryTest()) return;

  testWidgets('shelf tiles contact sheet', (tester) async {
    final under = shelfLooks['Effects']!;
    final words = shelfLooks['Fonts']!;

    final effects = [
      ShelfItem('1', 'Gaussian Blur', tags: {'Blur'}),
      ShelfItem('2', 'Drop Shadow', tags: {'Color'}),
      ShelfItem('3', 'Glow', tags: {'Color'}),
      ShelfItem('4', 'Noise', tags: {'Generate'}),
      ShelfItem('5', 'Wave Warp', tags: {'Distort'}),
      ShelfItem('6', 'Repeater', tags: {'Layout'}),
    ];

    final fonts = [
      ShelfItem('f1', 'Inter', label: 'Sans-serif'),
      ShelfItem('f2', 'Menlo', label: 'Monospace'),
      ShelfItem('f3', 'Noto Sans JP', label: 'Japanese'),
    ];

    const tileW = 130.0;
    final tileH = tileW / under.aspect + Shape.z(ShelfTile.bar);

    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: WindowTokens.body,
          child: SizedBox(
            width: 700,
            height: 900,
            child: Padding(
              padding: EdgeInsets.all(Shape.s(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Under form (Effects/Create/Media/Looks) ---
                  _label('Tile — under (Effects, Create, Media)'),
                  Wrap(
                    spacing: WindowTokens.gutter,
                    runSpacing: WindowTokens.gutter,
                    children: [
                      for (final item in effects)
                        SizedBox(
                          width: tileW,
                          height: tileH,
                          child: ShelfTile(item, under),
                        ),
                    ],
                  ),
                  SizedBox(height: Shape.s(10)),

                  // --- Under: picked + lit ---
                  _label('Tile — picked / lit'),
                  Wrap(
                    spacing: WindowTokens.gutter,
                    children: [
                      SizedBox(
                        width: tileW,
                        height: tileH,
                        child: ShelfTile(effects[0], under, picked: true),
                      ),
                      SizedBox(
                        width: tileW,
                        height: tileH,
                        child: ShelfTile(effects[1], under, lit: true),
                      ),
                    ],
                  ),
                  SizedBox(height: Shape.s(10)),

                  // --- Words form (Fonts) ---
                  _label('Tile — words (Fonts)'),
                  Wrap(
                    spacing: WindowTokens.gutter,
                    children: [
                      for (final item in fonts)
                        SizedBox(
                          width: 180,
                          height: Shape.z(words.height!),
                          child: ShelfTile(item, words, says: item.label),
                        ),
                    ],
                  ),
                  SizedBox(height: Shape.s(10)),

                  // --- Row form ---
                  _label('Tile — row (list)'),
                  ...effects
                      .take(3)
                      .map(
                        (item) => SizedBox(
                          width: 400,
                          height: Shape.z(under.row),
                          child: ShelfTile(
                            item,
                            under,
                            list: true,
                            says: 'Blur · 2 parameters',
                          ),
                        ),
                      ),
                  SizedBox(height: Shape.s(10)),

                  // --- Number fields (inspector values) ---
                  _label('NumberField — inspector tiles'),
                  Wrap(
                    spacing: WindowTokens.gutter,
                    runSpacing: WindowTokens.gutter,
                    children: [
                      _numTile('Position', 1454, 'px'),
                      _numTile('Scale', 100, '%'),
                      _numTile('Rotation', 0, '°'),
                      _numTile(
                        'Opacity',
                        100,
                        '%',
                        min: 0,
                        max: 100,
                        fill: 1.0,
                      ),
                      _numTile(
                        'Blur',
                        12,
                        'px',
                        min: 0,
                        max: 100,
                        fill: 0.12,
                        keyDot: Accent.key,
                      ),
                    ],
                  ),
                  SizedBox(height: Shape.s(10)),

                  // --- Empty shelf ---
                  _label('EmptyShelf'),
                  SizedBox(width: 300, child: EmptyShelf('shimmer')),
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
      matchesGoldenFile('goldens/shelf_tiles.png'),
    );
  });
}

Widget _label(String s) => Padding(
  padding: EdgeInsets.only(bottom: Shape.s(4)),
  child: Text(s, style: TextStyles.label(Grey.g56)),
);

Widget _numTile(
  String caption,
  double val,
  String unit, {
  double? min,
  double? max,
  double? fill,
  Color? keyDot,
}) {
  const w = 120.0;
  final h = Shape.z(42.0);
  return SizedBox(
    width: w,
    height: h,
    child: usualNumber(
      _dummyContext,
      NumberSpec(
        value: Text(
          '${val.toStringAsFixed(val == val.roundToDouble() ? 0 : 1)}$unit',
          style: blockValue(Grey.g91),
        ),
        width: w,
        height: h,
        fillColor: WindowTokens.well,
        borderColor: WindowTokens.line,
        rangeColor: WindowTokens.accent,
        caption: caption,
        fill: fill,
        keyDot: keyDot,
      ),
    ),
  );
}

// usualNumber needs a BuildContext but only passes it through — a dummy works.
final _dummyContext = _DummyBuildContext();

class _DummyBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}
