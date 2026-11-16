// The home screen's parts: the small button, and one project's card.
import 'package:motolii/skin/window_tokens.dart';

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/storage/disk.dart' show imageFile;
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/workspace/window/home_project.dart';

// A square thumbnail above the name, as in CapCut's desktop grid.
const homeTile = 150.0;

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

/// One project's card: its picture, name and facts, the mark when it is picked, and the menu under it when it is open.
class HomeCard extends StatelessWidget {
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

  /// Whether this is the project that is open now (it cannot be trashed), picked, whether its menu is open, and whether it asks to be trashed.
  final bool open, picked, menu, asking;
  final VoidCallback onTap, onMore, onOpen, onSelect, onExport;
  final VoidCallback onDuplicate, onAskTrash, onTrash, onKeep;

  @override
  Widget build(BuildContext context) {
    final f = d.facts;
    return SizedBox(
      width: homeTile,
      child: NakedButton(
        enableFeedback: false,
        key: ValueKey('home-doc:${d.path}'),
        onPressed: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: homeTile,
              decoration: BoxDecoration(
                color: WindowTokens.card,
                borderRadius: Shape.round(8),
                border: open ? WindowTokens.chosen : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (d.picture != null)
                    Image(image: imageFile(d.picture!), fit: BoxFit.cover),
                  // A round accent pill with a check glyph when the card is picked, mirroring Finder's selection dot.
                  if (picked)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        key: ValueKey('home-picked:${d.path}'),
                        margin: EdgeInsets.all(Shape.s(8)),
                        width: Shape.z(20),
                        height: Shape.z(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: WindowTokens.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '✓',
                          style: TextStyles.label(WindowTokens.onAccent)
                              .copyWith(fontSize: TextStyles.px(11), height: 1),
                        ),
                      ),
                    ),
                  // The "•••" more button uses the shared more glyph, in a round pill, so it reads with the rest of the app.
                  Positioned(
                    right: 0,
                    top: 0,
                    child: NakedButton(
                      enableFeedback: false,
                      key: ValueKey('home-more:${d.path}'),
                      onPressed: onMore,
                      child: Container(
                        margin: EdgeInsets.all(Shape.s(8)),
                        width: Shape.z(24),
                        height: Shape.z(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: WindowTokens.ground,
                          shape: BoxShape.circle,
                        ),
                        child: Glyph(
                          AppGlyphs.more,
                          size: Shape.z(12),
                          color: Grey.g76,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Shape.s(10)),
            Text(
              d.name,
              style: TextStyles.name(Grey.g91).bold,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: Shape.s(3)),
            // File size and duration on one line, separated by a dot (CapCut uses "254.3M | 02:13"; a dot reads lighter and
            // matches the facts line below so the typography stays consistent).
            Text(
              [
                homeBytes(d.bytes),
                if (f != null) homeLength(f.seconds),
              ].join(' · '),
              style: TextStyles.value(Grey.g63),
              maxLines: 1,
            ),
            Text(
              homeFacts(d).join(' · '),
              key: ValueKey('home-facts:${d.path}'),
              style: TextStyles.value(Grey.g56),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (menu)
              Padding(
                padding: EdgeInsets.only(top: Shape.s(8)),
                child: Wrap(
                  spacing: Shape.s(4),
                  runSpacing: Shape.s(4),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: asking
                      ? [
                          Text(
                            'Move to the Trash?',
                            style: TextStyles.label(Grey.g91),
                          ),
                          homeButton(
                            'home-trash-yes:${d.path}',
                            'Move to Trash',
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
                              'Move to Trash',
                              false,
                              onAskTrash,
                            ),
                        ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
