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

/// A seeded gradient for cards with no thumbnail, based on the project name's hash.
Color seedColor(String name) {
  final h = name.hashCode;
  final hue = (h % 360).abs().toDouble();
  return HSLColor.fromAHSL(1, hue, .35, .18).toColor();
}

Color seedColorLight(String name) {
  final h = name.hashCode;
  final hue = (h % 360).abs().toDouble();
  return HSLColor.fromAHSL(1, hue, .4, .28).toColor();
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
                      borderRadius: Shape.round(8),
                      boxShadow: [
                        BoxShadow(
                          color: Grey.g00.withValues(alpha: h ? .25 : 0),
                          blurRadius: h ? 16 : 0,
                          offset: Offset(0, h ? 6 : 0),
                        ),
                      ],
                      border: Border.all(
                        color: widget.open
                            ? WindowTokens.accent.withValues(alpha: .5)
                            : Grey.g20.withValues(alpha: h ? .5 : .3),
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
                if (homeFacts(d).isNotEmpty)
                  AnimatedDefaultTextStyle(
                    duration: Motion.dur,
                    style: TextStyles.micro(h ? Grey.g56 : Grey.g38),
                    child: Text(
                      homeFacts(d).join(' · '),
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
