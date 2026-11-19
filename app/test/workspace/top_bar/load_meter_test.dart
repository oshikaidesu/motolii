// LoadBar (workspace/top_bar/load_meter.dart): one load as a name, a bar and a number. The expected values follow
// the contract written there: the bar fills to the per cent, stays inside itself over 100, and marks the most.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/top_bar/load_meter.dart';

void main() {
  Future<void> show(WidgetTester tester, Widget bar) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: bar),
    ),
  );

  // The boxes of the bar by colour: the track, the fill, the tick.
  Iterable<Size> boxes(WidgetTester tester, Color color) => tester
      .widgetList<ColoredBox>(find.byType(ColoredBox))
      .where((b) => b.color == color)
      .map((b) => tester.getSize(find.byWidget(b)));

  testWidgets('the name, the number, and a bar filled to the per cent', (
    tester,
  ) async {
    await show(tester, const LoadBar(label: 'CPU', percent: 25));
    expect(find.text('CPU'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    final track = boxes(tester, Grey.g26).single,
        fill = boxes(tester, Grey.g63).single;
    expect(fill.width, closeTo(track.width * .25, .01));
    expect(fill.height, track.height);
  });

  testWidgets('over 100 the bar stays full and turns to the alert colour', (
    tester,
  ) async {
    await show(tester, const LoadBar(label: 'GPU', percent: 140));
    final alert = WindowTokens.alert;
    expect(find.text('140%'), findsOneWidget);
    expect(
      boxes(tester, alert).single.width,
      boxes(tester, Grey.g26).single.width,
    );
    expect(
      tester.widget<Text>(find.text('140%')).style!.color,
      isNot(tester.widget<Text>(find.text('GPU')).style!.color),
    );
  });

  testWidgets('the most is marked only when it is over the mean', (
    tester,
  ) async {
    await show(tester, const LoadBar(label: 'CPU', percent: 30, most: 80));
    expect(boxes(tester, Grey.g91).single.width, 1);
    await show(tester, const LoadBar(label: 'CPU', percent: 30, most: 30));
    expect(boxes(tester, Grey.g91), isEmpty);
  });

  testWidgets('the number changing does not move the bar', (tester) async {
    await show(tester, const LoadBar(label: 'CPU', percent: 5));
    final was = tester.getSize(find.byType(LoadBar));
    await show(tester, const LoadBar(label: 'CPU', percent: 100));
    expect(tester.getSize(find.byType(LoadBar)), was);
  });

  testWidgets('three digits fit the number\'s place', (tester) async {
    await show(tester, const LoadBar(label: 'CPU', percent: 888));
    final written = TextPainter(
      text: TextSpan(
        text: '888%',
        style: tester.widget<Text>(find.text('888%')).style,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(written.width, lessThanOrEqualTo(LoadBar.numberWide));
  });

  testWidgets('read aloud as its name and number', (tester) async {
    final handle = tester.ensureSemantics();
    await show(tester, const LoadBar(label: 'GPU', percent: 42));
    expect(find.bySemanticsLabel('GPU 42%'), findsOneWidget);
    handle.dispose();
  });
}
