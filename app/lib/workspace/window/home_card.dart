// The home screen's project card: a thumbnail that fills the card, name below.
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
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final f = d.facts;
    final h = _h || widget.menu;
    return GestureDetector(
      onSecondaryTapDown: (_) => widget.onMore(),
      child: NakedButton(
        enableFeedback: false,
        key: ValueKey('home-doc:${d.path}'),
        onPressed: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => setState(() => _h = true),
          onExit: (_) => setState(() => _h = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: AnimatedContainer(
                  duration: Motion.dur,
                  curve: Motion.ease,
                  decoration: BoxDecoration(
                    color: Grey.g13,
                    borderRadius: Shape.round(8),
                    border: Border.all(
                      color: widget.open
                          ? WindowTokens.accent
                          : h
                          ? Grey.g26
                          : Grey.g15,
                    ),
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
                      if (d.picture != null)
                        Image(image: imageFile(d.picture!), fit: BoxFit.cover)
                      else
                        _Placeholder(name: d.name),
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: Shape.s(6)),
                child: Text(
                  d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.name(h ? Grey.g91 : Grey.g76),
                ),
              ),
              Text(
                [
                  homeAge(d.changed),
                  if (f != null && f.seconds > 0) homeLength(f.seconds),
                  ...homeFacts(d),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.micro(Grey.g38),
              ),
              if (widget.menu)
                Padding(
                  padding: EdgeInsets.only(top: Shape.s(6)),
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
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: Grey.g10),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w200,
          color: Grey.g26,
        ),
      ),
    ),
  );
}
