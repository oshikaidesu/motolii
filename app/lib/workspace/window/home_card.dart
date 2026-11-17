// The home screen's project card: a thumbnail that fills the card, name overlaid.
import 'package:motolii/skin/window_tokens.dart';

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/storage/disk.dart' show imageFile;
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/workspace/window/home_project.dart';

const homeTile = 240.0;

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

class HomeCard extends StatefulWidget {
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
    this.onDoubleTap,
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
  final bool open, picked, selected, menu, asking;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback onMore, onOpen, onSelect, onExport;
  final VoidCallback onDuplicate, onAskTrash, onTrash, onKeep;

  @override
  State<HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<HomeCard> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final h = _h || widget.menu;
    final borderColor = widget.selected
        ? WindowTokens.accent
        : widget.open
        ? WindowTokens.accent.withValues(alpha: .5)
        : h
        ? Grey.g26
        : Grey.g15;

    return GestureDetector(
      onSecondaryTapDown: (_) => widget.onMore(),
      onDoubleTap: widget.onDoubleTap,
      child: NakedButton(
        enableFeedback: false,
        key: ValueKey('home-doc:${d.path}'),
        onPressed: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => setState(() => _h = true),
          onExit: (_) => setState(() => _h = false),
          child: AnimatedContainer(
            duration: Motion.dur,
            curve: Motion.ease,
            decoration: BoxDecoration(
              color: Grey.g13,
              borderRadius: Shape.round(8),
              border: Border.all(color: borderColor),
              boxShadow: h
                  ? [
                      BoxShadow(
                        color: Grey.g00.withValues(alpha: .3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail fills the whole card
                if (d.picture != null)
                  Image(image: imageFile(d.picture!), fit: BoxFit.cover)
                else
                  _Placeholder(name: d.name, index: widget.index),

                // Gradient at the bottom for the name
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Grey.g00.withValues(alpha: 0),
                          Grey.g00.withValues(alpha: .65),
                        ],
                      ),
                    ),
                  ),
                ),

                // Name overlaid at bottom-left
                Positioned(
                  left: Shape.s(8),
                  bottom: Shape.s(6),
                  right: Shape.s(8),
                  child: Text(
                    d.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.label(Grey.g91).copyWith(
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(
                          blurRadius: 8,
                          color: Grey.g00.withValues(alpha: .67),
                        ),
                      ],
                    ),
                  ),
                ),

                // Selection badge
                if (widget.picked)
                  Positioned(
                    left: Shape.s(8),
                    top: Shape.s(8),
                    child: Container(
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

                // More button on hover
                if (h)
                  Positioned(
                    right: Shape.s(6),
                    top: Shape.s(6),
                    child: NakedButton(
                      enableFeedback: false,
                      onPressed: widget.onMore,
                      child: Container(
                        width: Shape.z(24),
                        height: Shape.z(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Grey.g00.withValues(alpha: .5),
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

                // Context menu
                if (widget.menu)
                  Positioned(
                    left: Shape.s(6),
                    bottom: Shape.s(28),
                    right: Shape.s(6),
                    child: Wrap(
                      spacing: Shape.s(4),
                      runSpacing: Shape.s(4),
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: widget.asking
                          ? [
                              Text('Trash?', style: TextStyles.label(Grey.g91)),
                              homeButton(
                                'home-trash-yes:${d.path}',
                                'Trash',
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
                                  'Trash',
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

/// Placeholder with a coloured gradient that cycles through the brand triad.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.name, required this.index});
  final String name;
  final int index;
  @override
  Widget build(BuildContext context) {
    final colors = [
      (WindowTokens.seiji, WindowTokens.nadeshiko),
      (WindowTokens.nadeshiko, WindowTokens.usuki),
      (WindowTokens.usuki, WindowTokens.seiji),
    ];
    final (a, b) = colors[index % colors.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [a.withValues(alpha: .15), Grey.g10, b.withValues(alpha: .1)],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w200,
            color: a.withValues(alpha: .3),
          ),
        ),
      ),
    );
  }
}
