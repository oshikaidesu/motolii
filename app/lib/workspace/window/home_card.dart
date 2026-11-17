// The home screen's project card: a 16:9 thumbnail, name as caption, hover to reveal details and menu.
import 'package:motolii/skin/window_tokens.dart';

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/storage/disk.dart' show imageFile;
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/workspace/window/home_project.dart';

const homeTile = 240.0;

/// The brand triad from the website: seiji (青磁), nadeshiko (撫子), usuki (浅黄).
List<(Color, Color)> get _triad => [
  (WindowTokens.seiji, WindowTokens.seijiInk),
  (WindowTokens.nadeshiko, WindowTokens.nadeshikoInk),
  (WindowTokens.usuki, WindowTokens.usukiInk),
];

/// Which triad color a project uses, cycled by the name's hash.
(Color, Color) triadOf(int index) => _triad[index % _triad.length];

/// A seeded gradient for cards with no thumbnail, based on the triad.
Color seedColor(String name) {
  final (c, _) = triadOf(name.hashCode.abs());
  return HSLColor.fromColor(c).withLightness(.18).withSaturation(.4).toColor();
}

Color seedColorLight(String name) {
  final (c, _) = triadOf(name.hashCode.abs());
  return HSLColor.fromColor(c).withLightness(.28).withSaturation(.35).toColor();
}

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

/// One project card: a 16:9 thumbnail with hover reveal of details and the menu.
class HomeCard extends StatefulWidget {
  const HomeCard(
    this.d, {
    super.key,
    this.index = 0,
    required this.open,
    required this.picked,
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
  final bool open, picked, menu, asking;
  final VoidCallback onTap, onMore, onOpen, onSelect, onExport;
  final VoidCallback onDuplicate, onAskTrash, onTrash, onKeep;

  @override
  State<HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<HomeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final f = d.facts;
    final h = _hovered || widget.menu;
    return GestureDetector(
      onSecondaryTapDown: (_) => widget.onMore(),
      child: NakedButton(
        enableFeedback: false,
        key: ValueKey('home-doc:${d.path}'),
        onPressed: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedScale(
            scale: h ? 1.03 : 1.0,
            duration: Motion.dur,
            curve: Motion.ease,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 16:9 thumbnail area.
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AnimatedContainer(
                    duration: Motion.dur,
                    curve: Motion.ease,
                    decoration: BoxDecoration(
                      color: Grey.g15,
                      borderRadius: Shape.round(12),
                      boxShadow: [
                        BoxShadow(
                          color: Grey.g00.withValues(alpha: h ? .4 : .1),
                          blurRadius: h ? 24 : 4,
                          offset: Offset(0, h ? 8 : 2),
                        ),
                        BoxShadow(
                          color: triadOf(widget.index).$1
                              .withValues(alpha: h ? .15 : 0),
                          blurRadius: h ? 32 : 0,
                        ),
                      ],
                      border: Border.all(
                        color: widget.open
                            ? WindowTokens.accent.withValues(alpha: .5)
                            : h
                            ? Grey.g56.withValues(alpha: .4)
                            : Grey.g20.withValues(alpha: .15),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail or gradient placeholder.
                        if (d.picture != null)
                          Image(image: imageFile(d.picture!), fit: BoxFit.cover)
                        else
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  seedColor(d.name),
                                  seedColorLight(d.name),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                d.name.isNotEmpty
                                    ? d.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w200,
                                  color: Grey.g38,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ),
                        // Subtle bottom vignette for visual cohesion.
                        if (d.picture != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 40,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Grey.g00.withValues(alpha: 0),
                                    Grey.g00.withValues(alpha: .15),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Index + triad color tag.
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Padding(
                            padding: EdgeInsets.all(Shape.s(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 3,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: triadOf(widget.index).$1,
                                    borderRadius: Shape.round(2),
                                  ),
                                ),
                                SizedBox(width: Shape.s(5)),
                                Text(
                                  '${widget.index + 1}'.padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Grey.g56.withValues(
                                      alpha: h ? .9 : .5,
                                    ),
                                    letterSpacing: .5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Picked mark.
                        if (widget.picked)
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              margin: EdgeInsets.all(Shape.s(8)),
                              width: Shape.z(20),
                              height: Shape.z(20),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: WindowTokens.accent,
                                shape: BoxShape.circle,
                              ),
                              child: Glyph(
                                AppGlyphs.check,
                                size: Shape.z(12),
                                color: WindowTokens.onAccent,
                              ),
                            ),
                          ),
                        // ⋯ button: visible only on hover.
                        if (h)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: NakedButton(
                              enableFeedback: false,
                              onPressed: widget.onMore,
                              child: Container(
                                margin: EdgeInsets.all(Shape.s(8)),
                                width: Shape.z(24),
                                height: Shape.z(24),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Grey.g00.withValues(alpha: .6),
                                  shape: BoxShape.circle,
                                ),
                                child: Glyph(
                                  AppGlyphs.more,
                                  size: Shape.z(12),
                                  color: Grey.g91,
                                ),
                              ),
                            ),
                          ),
                        // Bottom fade with metadata on hover.
                        if (h && f != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Grey.g00.withValues(alpha: 0),
                                    Grey.g00.withValues(alpha: .8),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  Shape.s(10),
                                  Shape.s(16),
                                  Shape.s(10),
                                  Shape.s(6),
                                ),
                                child: Text(
                                  [
                                    homeBytes(d.bytes),
                                    if (f.seconds > 0) homeLength(f.seconds),
                                    ...homeFacts(d),
                                  ].join(' · '),
                                  style: TextStyles.value(Grey.g76),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Shape.s(8)),
                // Project name as a quiet caption.
                AnimatedDefaultTextStyle(
                  duration: Motion.dur,
                  style: TextStyles.name(h ? Grey.g91 : Grey.g56)
                      .copyWith(letterSpacing: .3),
                  child: Text(
                    d.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedDefaultTextStyle(
                  duration: Motion.dur,
                  style: TextStyles.micro(h ? Grey.g56 : Grey.g38),
                  child: Text(
                    [homeAge(d.changed), ...homeFacts(d)].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Menu row.
                if (widget.menu)
                  Padding(
                    padding: EdgeInsets.only(top: Shape.s(8)),
                    child: Wrap(
                      spacing: Shape.s(4),
                      runSpacing: Shape.s(4),
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: widget.asking
                          ? [
                              Text(
                                'Move to the Trash?',
                                style: TextStyles.label(Grey.g91),
                              ),
                              homeButton(
                                'home-trash-yes:${d.path}',
                                'Move to Trash',
                                true,
                                widget.onTrash,
                              ),
                              homeButton(
                                'home-trash-no:${d.path}',
                                'Cancel',
                                false,
                                widget.onKeep,
                              ),
                            ]
                          : [
                              homeButton(
                                'home-open:${d.path}',
                                'Open',
                                false,
                                widget.onOpen,
                              ),
                              homeButton(
                                'home-select:${d.path}',
                                'Select',
                                false,
                                widget.onSelect,
                              ),
                              homeButton(
                                'home-export:${d.path}',
                                'Export…',
                                false,
                                widget.onExport,
                              ),
                              homeButton(
                                'home-duplicate:${d.path}',
                                'Duplicate',
                                false,
                                widget.onDuplicate,
                              ),
                              if (!widget.open)
                                homeButton(
                                  'home-trash:${d.path}',
                                  'Move to Trash',
                                  false,
                                  widget.onAskTrash,
                                ),
                            ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
