// The preview of the chosen project: its name, facts, picture with selection handles, and the empty state.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/disk.dart' show imageFile;
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/workspace/window/home_card.dart';
import 'package:motolii/workspace/window/home_project.dart';

/// The preview of the chosen project: on one side its name set very large over a strip of its facts, on the other its
/// picture, shown as a design tool shows a selected layer.
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.d,
    required this.index,
    required this.note,
    required this.action,
    required this.onOpen,
  });
  final HomeProject d;
  final int index;
  final String note, action;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final f = d.facts;
    final facts = [
      ('EDITED', homeAge(d.changed)),
      if (f != null && f.seconds > 0) ('LENGTH', homeLength(f.seconds)),
      if (f != null) ('FRAME', '${f.wide}×${f.high}'),
      if (f != null && f.rate > 0)
        (
          'RATE',
          '${f.rate == f.rate.roundToDouble() ? f.rate.round() : f.rate} fps',
        ),
      ('FILE', homeBytes(d.bytes)),
    ];
    return Container(
      decoration: BoxDecoration(color: Grey.g07, borderRadius: Shape.round(20)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: Container(
              decoration: homeSheen(homeTones()[index % homeTones().length]),
              padding: EdgeInsets.all(Shape.s(26)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  homeTag(note, WindowTokens.usuki),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        d.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.name(
                          Grey.g100,
                          34,
                          FontWeight.w800,
                        ).copyWith(letterSpacing: -1.2),
                      ),
                    ),
                  ),
                  SizedBox(height: Shape.s(16)),
                  Container(height: 1, color: Grey.g63),
                  SizedBox(height: Shape.s(10)),
                  Wrap(
                    spacing: Shape.s(22),
                    runSpacing: Shape.s(10),
                    children: [
                      for (final (label, value) in facts)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label, style: homeCaps(Grey.g56)),
                            SizedBox(height: Shape.s(5)),
                            Text(
                              value,
                              style: TextStyles.name(
                                Grey.g95,
                                12,
                                FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: Shape.s(18)),
                  Pressable(
                    key: const ValueKey('home-hero-open'),
                    onTap: onOpen,
                    builder: (context, hot) => AnimatedContainer(
                      duration: Motion.dur,
                      padding: EdgeInsets.symmetric(
                        horizontal: Shape.s(16),
                        vertical: Shape.s(11),
                      ),
                      decoration: BoxDecoration(
                        color: hot
                            ? WindowTokens.accentHot
                            : WindowTokens.accent,
                        borderRadius: Shape.round(100),
                      ),
                      child: Text(
                        action,
                        style: homeCaps(WindowTokens.onAccent, 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, color: Grey.g100.withValues(alpha: .07)),
          Expanded(
            flex: 8,
            child: d.picture == null
                ? HomeLetter(name: d.name, index: index)
                : CustomPaint(
                    painter: HomeDotGrid(Grey.g26),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        Shape.s(24),
                        Shape.s(20),
                        Shape.s(24),
                        Shape.s(32),
                      ),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: f != null && f.wide > 0 && f.high > 0
                              ? f.wide / f.high
                              : 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.none,
                            children: [
                              Image(
                                image: imageFile(d.picture!),
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: WindowTokens.accent,
                                    width: homeEdge,
                                  ),
                                ),
                              ),
                              ...homeHandles(),
                              // The layer's size, hung under its box as a design tool hangs it.
                              if (f != null)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: -Shape.s(30),
                                  child: Center(
                                    child: homeTag(
                                      '${f.wide} × ${f.high}',
                                      WindowTokens.accent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A canvas's grid of dots.
class HomeDotGrid extends CustomPainter {
  HomeDotGrid(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = ink;
    for (var y = 12.0; y < size.height; y += 20) {
      for (var x = 12.0; x < size.width; x += 20) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1.5, 1.5), dot);
      }
    }
  }

  @override
  bool shouldRepaint(HomeDotGrid old) => old.ink != ink;
}

/// Shown in the preview's place when there is no project to preview.
class HomeEmpty extends StatelessWidget {
  const HomeEmpty({super.key, required this.searching});
  final bool searching;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(Shape.s(24)),
    decoration: BoxDecoration(color: Grey.g07, borderRadius: Shape.round(20)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          searching ? 'No matches' : 'No projects yet',
          style: TextStyles.name(
            Grey.g100,
            34,
            FontWeight.w800,
          ).copyWith(letterSpacing: -1.2),
        ),
        SizedBox(height: Shape.s(14)),
        Text(
          searching ? 'Try a different search.' : 'Create one to get started.',
          style: TextStyles.label(Grey.g76),
        ),
      ],
    ),
  );
}
