// The Looks shelf: saved looks (presets) and elements, applied by double-click.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/workspace/dock/common/empty_shelf.dart';
import 'package:motolii/workspace/dock/common/filter_chips.dart';
import 'package:motolii/workspace/dock/common/shelf_footer.dart';
import 'package:motolii/workspace/dock/common/shelf_section.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/shelf_looks.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';
import 'package:motolii/workspace/state/effects.dart';
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/media/shelf_reads.dart';

/// The Looks shelf: saved looks and elements as tiles.
class LooksShelf extends StatefulWidget {
  const LooksShelf(this.c, {super.key});
  final ShelfContext c;
  @override
  State<LooksShelf> createState() => _LooksShelfState();
}

class _LooksShelfState extends State<LooksShelf> {
  final _menu = GlobalKey<ContextMenuState>();
  ShelfContext get c => widget.c;

  @override
  Widget build(BuildContext context) {
    final ws = c.ws;
    if (!projectOpen(ws)) return EmptyShelf(c.query);
    final look = shelfLooks['Looks']!;
    final looks = presetsOf(ws);
    final elements = elementsOf(ws);
    if (looks.isEmpty && elements.isEmpty) {
      return EmptyShelf(
        c.query,
        said: 'No looks yet. Use Edit > Save Look to save one here.',
      );
    }
    final all = <(String, String, String)>[
      for (final (name, file) in looks) (file, name, 'Looks'),
      for (final (name, file) in elements) (file, name, 'Elements'),
    ];
    var filtered = [
      if (looks.isNotEmpty)
        (
          'Looks',
          [
            for (final (name, file) in looks)
              if (c.hit(name)) (name, file),
          ],
        ),
      if (elements.isNotEmpty)
        (
          'Elements',
          [
            for (final (name, file) in elements)
              if (c.hit(name)) (name, file),
          ],
        ),
    ].where((e) => e.$2.isNotEmpty).toList();
    // Fuzzy search when the exact match finds nothing.
    if (filtered.isEmpty && c.query.trim().isNotEmpty) {
      final near = c.near(all);
      filtered = [
        (
          'Looks',
          [for (final id in near) ...looks.where((e) => e.$2 == id).take(1)],
        ),
        (
          'Elements',
          [for (final id in near) ...elements.where((e) => e.$2 == id).take(1)],
        ),
      ].where((e) => e.$2.isNotEmpty).toList();
    }
    // Filter by chip.
    if (c.chip != 'All') {
      filtered = filtered.where((e) => e.$1 == c.chip).toList();
    }
    if (filtered.isEmpty) return EmptyShelf(c.query);
    final sel = c.foot(
      filtered.expand((e) => e.$2).where((e) => e.$2 == c.sel).firstOrNull,
    );
    return ContextMenu(
      key: _menu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterChips(
            [
              ('All', looks.length + elements.length),
              if (looks.isNotEmpty) ('Looks', looks.length),
              if (elements.isNotEmpty) ('Elements', elements.length),
            ],
            active: c.chip,
            onPick: c.pickChip,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final (group, items) in filtered)
                  Padding(
                    padding: EdgeInsets.only(bottom: WindowTokens.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ShelfSection(
                          group,
                          count: items.length,
                          hue: group == 'Looks'
                              ? InspectorSkin.tonePlace
                              : Grey.g76,
                        ),
                        const SizedBox(height: WindowTokens.gutter),
                        ShelfGrid(
                          look,
                          shrinkWrap: true,
                          count: items.length,
                          tile: (i) {
                            final (name, file) = items[i];
                            final item =
                                itemOf(ws, file) ?? ShelfItem(file, name);
                            return ShelfTile(
                              item,
                              look,
                              picked: c.sel == file,
                              onTap: () => c.pick(file),
                              onApply: () => ws.lookPut(file),
                              onMenu: (at) {
                                final box =
                                    _menu.currentContext?.findRenderObject()
                                        as RenderBox?;
                                _menu.currentState?.show(
                                  box?.globalToLocal(at) ?? Offset.zero,
                                  [
                                    ContextMenuItem(
                                      'Apply',
                                      () => ws.lookPut(file),
                                    ),
                                    ContextMenuItem('Apply to New Layer', () {
                                      final was = ws.selected;
                                      ws.select(null);
                                      ws.lookPut(file);
                                      if (was != null) ws.select(was);
                                    }),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (sel != null)
            ShelfFooter(
              preview: dockBadge(AppGlyphs.files, Grey.g76, size: Shape.z(34)),
              title: sel.$1,
              meta: sel.$1 == sel.$2 ? 'Look' : sel.$2,
              action: 'Apply',
              onAction: () => ws.lookPut(sel.$2),
            ),
        ],
      ),
    );
  }
}
