// The home screen's project card, drawn flat: a picture that fills whatever cell the bento gives it, a label on a solid
// block, and, when it is the one previewed, a design tool's bounding box with its four handles.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/disk.dart' show imageFile;
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook, Pressable;
import 'package:motolii/workspace/window/home_project.dart';

/// The width of every outline on the home screen.
const homeEdge = 1.5;

/// How far a chosen card's handles reach outside it. A list of cards leaves this much room around itself.
const homeReach = 5.0;

Widget homeButton(String key, String text, bool on, VoidCallback tap) =>
    Padding(
      padding: EdgeInsets.only(left: Shape.s(4)),
      child: Chip(
        key: ValueKey(key),
        label: text,
        on: on,
        onTap: tap,
        look: ChipLook(
          fill: WindowTokens.card,
          onFill: WindowTokens.accent,
          ink: Grey.g91,
          onInk: WindowTokens.onAccent,
          padX: 8,
          padY: 4,
          radius: WindowTokens.radius,
          text: (c) => TextStyles.label(c),
        ),
      ),
    );

/// Capital letters set wide and heavy, for a tag or a small heading.
TextStyle homeCaps(Color c, [double size = 10]) =>
    TextStyles.name(c, size, FontWeight.w800).copyWith(letterSpacing: 1);

/// A flat tag, like the name a design tool hangs beside a cursor: [text] in dark ink on a block of [tone].
Widget homeTag(String text, Color tone) => Container(
  padding: EdgeInsets.symmetric(horizontal: Shape.s(7), vertical: Shape.s(4)),
  color: tone,
  child: Text(text, style: homeCaps(WindowTokens.onAccent)),
);

/// The five flat colours the home screen draws with: the brand's three, then two of the layer tones.
List<Color> homeTones() => [
  WindowTokens.usuki,
  WindowTokens.nadeshiko,
  WindowTokens.seiji,
  WindowTokens.toneShape,
  WindowTokens.toneGroup,
];

/// The four handles of a design tool's bounding box, for a `Stack` that does not clip: one on each corner, reaching
/// [homeReach] outside it.
List<Widget> homeHandles() => [
  for (final (right, bottom) in const [
    (false, false),
    (true, false),
    (false, true),
    (true, true),
  ])
    Positioned(
      left: right ? null : -homeReach + 1,
      right: right ? -homeReach + 1 : null,
      top: bottom ? null : -homeReach + 1,
      bottom: bottom ? -homeReach + 1 : null,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: Grey.g95,
          border: Border.all(color: WindowTokens.accent, width: homeEdge),
        ),
      ),
    ),
];

/// What stands in for a project that saved no picture, as a small poster: one flat shape, and over it the project's
/// first letter, very large and cut off by the frame.
class HomeLetter extends StatelessWidget {
  const HomeLetter({super.key, required this.name, required this.index});
  final String name;

  /// The project's place in the list, which picks the shape's colour.
  final int index;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final tones = homeTones(), tall = box.maxHeight;
      final letter = name.isNotEmpty ? name.characters.first : '?';
      return ColoredBox(
        color: Grey.g10,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PosterShape(
                  // The shape follows the name, not the place, so the same colour does not always bring the same shape.
                  (name.length + letter.codeUnitAt(0)) % 5,
                  tones[index % tones.length],
                ),
              ),
            ),
            Positioned(
              right: tall * .06,
              bottom: -tall * .2,
              child: Text(
                letter.toUpperCase(),
                style: TextStyles.name(
                  Grey.g95,
                  tall * .92,
                  FontWeight.w900,
                ).copyWith(letterSpacing: 0),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// One of five flat shapes, sized by the frame's height and set toward its right side.
class _PosterShape extends CustomPainter {
  _PosterShape(this.kind, this.tone);
  final int kind;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, m = size.height, fill = Paint()..color = tone;
    switch (kind) {
      case 0:
        canvas.drawCircle(Offset(w - .5 * m, .58 * m), .48 * m, fill);
      case 1:
        canvas.drawPath(
          Path()
            ..moveTo(w - 1.05 * m, 1.05 * m)
            ..lineTo(w - .02 * m, 1.05 * m)
            ..lineTo(w - .54 * m, .1 * m)
            ..close(),
          fill,
        );
      case 2:
        canvas.drawCircle(Offset(w, m), .96 * m, fill);
      case 3:
        final mid = Offset(w - .52 * m, .54 * m), burst = Path();
        for (var i = 0; i < 20; i++) {
          final a = i * math.pi / 10 - math.pi / 2;
          final o =
              mid +
              Offset(math.cos(a), math.sin(a)) * (i.isEven ? .56 : .42) * m;
          i == 0 ? burst.moveTo(o.dx, o.dy) : burst.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(burst..close(), fill);
      default:
        canvas.save();
        canvas.translate(w - .52 * m, .52 * m);
        canvas.rotate(.22);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: .7 * m, height: .7 * m),
          fill,
        );
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PosterShape old) => old.kind != kind || old.tone != tone;
}

class HomeCard extends StatelessWidget {
  const HomeCard(
    this.d, {
    super.key,
    this.index = 0,
    required this.open,
    required this.picked,
    this.selected = false,
    required this.menu,
    required this.asking,
    required this.onTap,
    required this.onMore,
    required this.onOpen,
    required this.onSelect,
    required this.onExport,
    required this.onDuplicate,
    required this.onAskTrash,
    required this.onTrash,
    required this.onKeep,
  });
  final HomeProject d;
  final int index;

  /// [open] is the project in the editor now; [selected] is the one the home screen previews.
  final bool open, picked, selected, menu, asking;
  final VoidCallback onTap, onMore, onOpen, onSelect, onExport;
  final VoidCallback onDuplicate, onAskTrash, onTrash, onKeep;

  @override
  Widget build(BuildContext context) {
    final f = d.facts;
    return GestureDetector(
      onSecondaryTapDown: (_) => onMore(),
      child: Pressable(
        key: ValueKey('home-doc:${d.path}'),
        onTap: onTap,
        builder: (context, hot) {
          final h = hot || menu;
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: Motion.dur,
                curve: Motion.ease,
                decoration: BoxDecoration(
                  color: Grey.g13,
                  borderRadius: Shape.round(4),
                  border: Border.all(
                    width: homeEdge,
                    color: selected
                        ? WindowTokens.accent
                        : h
                        ? Grey.g100
                        : Grey.g63,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (d.picture != null)
                      Image(image: imageFile(d.picture!), fit: BoxFit.cover)
                    else
                      HomeLetter(name: d.name, index: index),

                    // The name and what is known of it, on a solid block in the corner.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          color: Grey.g07,
                          padding: EdgeInsets.fromLTRB(
                            Shape.s(10),
                            Shape.s(8),
                            Shape.s(12),
                            Shape.s(9),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                d.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyles.name(
                                  Grey.g95,
                                  12,
                                  FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: Shape.s(5)),
                              Text(
                                [
                                  homeAge(d.changed),
                                  if (f != null && f.seconds > 0)
                                    homeLength(f.seconds),
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyles.micro(Grey.g63),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (open)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: homeTag('OPEN', WindowTokens.usuki),
                      ),

                    if (picked)
                      Positioned(
                        left: Shape.s(8),
                        top: Shape.s(open ? 30 : 8),
                        child: Container(
                          width: Shape.z(20),
                          height: Shape.z(20),
                          alignment: Alignment.center,
                          color: WindowTokens.accent,
                          child: Glyph(
                            AppGlyphs.check,
                            size: Shape.z(12),
                            color: WindowTokens.onAccent,
                          ),
                        ),
                      ),

                    if (h)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Pressable(
                          onTap: onMore,
                          builder: (context, _) => Container(
                            width: Shape.z(26),
                            height: Shape.z(26),
                            alignment: Alignment.center,
                            color: Grey.g07,
                            child: Glyph(
                              AppGlyphs.more,
                              size: Shape.z(12),
                              color: Grey.g91,
                            ),
                          ),
                        ),
                      ),

                    if (menu)
                      Positioned(
                        left: Shape.s(6),
                        right: Shape.s(6),
                        bottom: Shape.s(56),
                        child: Wrap(
                          spacing: Shape.s(4),
                          runSpacing: Shape.s(4),
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: asking
                              ? [
                                  Text(
                                    'Trash?',
                                    style: TextStyles.label(Grey.g91),
                                  ),
                                  homeButton(
                                    'home-trash-yes:${d.path}',
                                    'Trash',
                                    true,
                                    onTrash,
                                  ),
                                  homeButton(
                                    'home-trash-no:${d.path}',
                                    'Cancel',
                                    false,
                                    onKeep,
                                  ),
                                ]
                              : [
                                  homeButton(
                                    'home-open:${d.path}',
                                    'Open',
                                    false,
                                    onOpen,
                                  ),
                                  homeButton(
                                    'home-select:${d.path}',
                                    'Select',
                                    false,
                                    onSelect,
                                  ),
                                  homeButton(
                                    'home-export:${d.path}',
                                    'Export…',
                                    false,
                                    onExport,
                                  ),
                                  homeButton(
                                    'home-duplicate:${d.path}',
                                    'Duplicate',
                                    false,
                                    onDuplicate,
                                  ),
                                  if (!open)
                                    homeButton(
                                      'home-trash:${d.path}',
                                      'Trash',
                                      false,
                                      onAskTrash,
                                    ),
                                ],
                        ),
                      ),
                  ],
                ),
              ),

              // The bounding box's handles, which sit on the corners and reach outside the card.
              if (selected) ...homeHandles(),
            ],
          );
        },
      ),
    );
  }
}
