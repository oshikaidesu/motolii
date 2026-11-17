// The bento layout and the grid header with its sort toggle and action cards.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/workspace/window/home_card.dart'
    show homeButton, homeCaps;

/// Lays [cards] out as bento blocks of up to six: a tall card beside two rows of unequal ones.
///
/// Every other block is mirrored. A card fills whatever cell it gets, so its picture is cropped, not stretched.
/// Each block carries the gap below it.
List<Widget> homeBento(List<Widget> cards, double rowTall, double gap) {
  Widget across(List<(int, Widget)> parts) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, (flex, child)) in parts.indexed) ...[
        if (i > 0) SizedBox(width: gap),
        Expanded(flex: flex, child: child),
      ],
    ],
  );
  Widget down(Widget a, Widget b) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: a),
      SizedBox(height: gap),
      Expanded(child: b),
    ],
  );

  final blocks = <Widget>[];
  for (var at = 0, n = 0; at < cards.length; n++) {
    final c = cards.sublist(at, math.min(at + 6, cards.length));
    at += c.length;
    List<(int, Widget)> side(List<(int, Widget)> parts) =>
        n.isOdd ? parts.reversed.toList() : parts;
    final (rows, body) = switch (c.length) {
      1 => (1, across([(4, c[0]), (6, const SizedBox())])),
      2 => (1, across(side([(6, c[0]), (4, c[1])]))),
      3 => (2, across(side([(4, c[0]), (6, down(c[1], c[2]))]))),
      4 => (
        2,
        across(
          side([
            (3, c[0]),
            (7, down(across([(1, c[1]), (1, c[2])]), c[3])),
          ]),
        ),
      ),
      5 => (
        2,
        across(
          side([
            (3, c[0]),
            (
              7,
              down(
                across([(4, c[1]), (6, c[2])]),
                across([(6, c[3]), (4, c[4])]),
              ),
            ),
          ]),
        ),
      ),
      _ => (
        2,
        across(
          side([
            (6, c[0]),
            (
              13,
              down(
                across([(1, c[1]), (1, c[2])]),
                across([(4, c[3]), (6, c[4])]),
              ),
            ),
            (5, c[5]),
          ]),
        ),
      ),
    };
    blocks.add(
      Padding(
        padding: EdgeInsets.only(bottom: gap),
        child: SizedBox(height: rowTall * rows + gap * (rows - 1), child: body),
      ),
    );
  }
  return blocks;
}

/// The heading of the bento under a heavy rule: its title set large, the count, the sort order, and what is picked.
class HomeGridHeader extends StatelessWidget {
  const HomeGridHeader({
    super.key,
    required this.count,
    required this.byName,
    required this.picked,
    required this.onByDate,
    required this.onByName,
    required this.onExport,
    required this.onUnpick,
  });
  final int count, picked;
  final bool byName;
  final VoidCallback onByDate, onByName, onExport, onUnpick;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(height: 1, color: Grey.g38),
      SizedBox(height: Shape.s(14)),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Projects',
            style: TextStyles.name(
              Grey.g100,
              28,
              FontWeight.w800,
            ).copyWith(letterSpacing: -1),
          ),
          SizedBox(width: Shape.s(8)),
          Padding(
            padding: EdgeInsets.only(bottom: Shape.s(5)),
            child: Text(
              '$count',
              style: TextStyles.name(Grey.g63, 14, FontWeight.w700),
            ),
          ),
          const Spacer(),
          if (picked > 0) ...[
            homeButton('home-export', 'Export $picked', true, onExport),
            homeButton('home-unpick', 'Cancel', false, onUnpick),
            SizedBox(width: Shape.s(16)),
          ],
          Padding(
            padding: EdgeInsets.only(right: Shape.s(10), bottom: Shape.s(10)),
            child: Text('SORT', style: homeCaps(Grey.g56)),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Grey.g07,
              borderRadius: Shape.round(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HomeToggle(
                  key: const ValueKey('home-by-date'),
                  text: 'DATE',
                  on: !byName,
                  onTap: onByDate,
                ),
                HomeToggle(
                  key: const ValueKey('home-by-name'),
                  text: 'NAME',
                  on: byName,
                  onTap: onByName,
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

/// One of a row of choices: a pill, inverted when it is the chosen one.
class HomeToggle extends StatelessWidget {
  const HomeToggle({
    super.key,
    required this.text,
    required this.on,
    required this.onTap,
  });
  final String text;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (context, hot) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: Shape.s(10),
        vertical: Shape.s(6),
      ),
      decoration: BoxDecoration(
        color: on
            ? Grey.g95
            : hot
            ? Grey.g20
            : Grey.g07,
        borderRadius: Shape.round(100),
      ),
      child: Text(text, style: homeCaps(on ? Grey.g00 : Grey.g76)),
    ),
  );
}

/// One of the two buttons beside the preview: its label at the top, its glyph large in the far corner.
///
/// [solid] draws it as a block of colour; otherwise it is an outline.
class HomeActionCard extends StatelessWidget {
  const HomeActionCard({
    super.key,
    required this.glyph,
    required this.label,
    required this.solid,
    required this.onTap,
  });
  final AppGlyphs glyph;
  final String label;
  final bool solid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (context, hot) {
      final tone = WindowTokens.seiji;
      final ink = solid
          ? WindowTokens.onAccent
          : hot
          ? Grey.g100
          : Grey.g91;
      return SizedBox.expand(
        child: AnimatedContainer(
          duration: Motion.dur,
          padding: EdgeInsets.all(Shape.s(16)),
          decoration: BoxDecoration(
            borderRadius: Shape.round(20),
            // A light from the top-left corner on both; the solid one keeps its colour under it.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: solid
                  ? [
                      Color.lerp(tone, Grey.g100, hot ? .38 : .2)!,
                      Color.lerp(tone, Grey.g00, hot ? 0 : .12)!,
                    ]
                  : [hot ? Grey.g20 : Grey.g13, Grey.g07],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: homeCaps(ink)),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Glyph(glyph, size: Shape.z(34), color: ink),
              ),
            ],
          ),
        ),
      );
    },
  );
}
