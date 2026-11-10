// The Fonts shelf: each font is shown set in its own face.
import 'package:motolii/workspace/shelf/shelf_looks.dart';

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/dock/common/empty_shelf.dart';
import 'package:motolii/workspace/dock/common/filter_chips.dart';
import 'package:motolii/workspace/dock/common/shelf_footer.dart';
import 'package:motolii/workspace/dock/common/shelf_tags.dart';
import 'package:motolii/workspace/dock/fonts/font_commands.dart';
import 'package:motolii/workspace/dock/fonts/font_dot.dart';
import 'package:motolii/workspace/dock/fonts/font_file.dart';
import 'package:motolii/workspace/dock/fonts/font_map.dart';
import 'package:motolii/workspace/dock/fonts/font_roles.dart';
import 'package:motolii/workspace/dock/fonts/font_tile.dart';
import 'package:motolii/workspace/dock/fonts/fonts_controller.dart';
import 'package:motolii/workspace/dock/map/image_features.dart';
import 'package:motolii/workspace/dock/map/shelf_map_view.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';

/// The Fonts shelf: a grid, list or map of the available fonts, with the title and body roles above.
class FontsShelf extends StatelessWidget {
  const FontsShelf(this.c, this.controller, {super.key});
  final ShelfContext c;

  /// What the shelf keeps between builds: the font files read, the fonts used lately, the dots of the map.
  final FontsController controller;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: controller.reads,
    builder: (context, _, _) => _shelf(context),
  );

  Widget _shelf(BuildContext context) {
    final m = c.ws.inside;
    if (m == null) return const SizedBox.shrink();
    final fonts = controller.fontsOf(c.ws);
    final commands = FontCommands(c, controller);
    // Maps each font file to the text layer that uses it.
    final setIn = {
      for (final l in c.ws.layers)
        if (m.word(int.parse(l.id), 'kind') == 'text')
          m.whole(m.word(int.parse(l.id), 'file')): l,
    };
    bool used(FontFile f) => setIn.containsKey(f.path);
    Set<String> tagsOf(FontFile f) => controller.tags.of(
      'Fonts',
      f.family,
      f.path == null
          ? const <String>{}
          : (c.ws.inside?.fontTags(f.path!) ?? const <String>{}),
    );
    var hits = fonts
        .where((f) => ShelfTags.hit(c.query, f.family, tagsOf(f)))
        .toList();
    if (hits.isEmpty && c.query.trim().isNotEmpty) {
      // Nothing matches the query as typed, so show the five nearest fonts.
      final near = c.near([
        for (final f in fonts)
          (f.family, '${f.family} ${tagsOf(f).join(' ')}', ''),
      ]);
      hits = [
        for (final id in near) ...fonts.where((f) => f.family == id).take(1),
      ];
    }
    final vocab = <String, int>{};
    for (final f in hits) {
      for (final t in tagsOf(f)) {
        vocab[t] = (vocab[t] ?? 0) + 1;
      }
    }
    final top = vocab.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    bool keep(FontFile f) => switch (c.chip) {
      'All' => true,
      'Used' => used(f),
      'Recent' => controller.recent.contains(f.family),
      'Starred' => c.starred(f.family),
      // A tag chip: the fonts that have the tag.
      final tag => tagsOf(f).contains(tag),
    };
    final list = hits.where(keep).toList();
    // Newest first.
    if (c.chip == 'Recent') {
      list.sort(
        (a, b) => controller.recent
            .indexOf(a.family)
            .compareTo(controller.recent.indexOf(b.family)),
      );
    }
    final sel = fonts.where((f) => f.family == c.sel).firstOrNull;
    final picked = sel == null ? null : setIn[sel.path],
        onText = picked != null && picked.id == c.ws.selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FontRoles(c, controller, fonts),
        FilterChips(
          [
            ('All', hits.length),
            ('Used', hits.where(used).length),
            (
              'Recent',
              hits.where((f) => controller.recent.contains(f.family)).length,
            ),
            ('Starred', hits.where((f) => c.starred(f.family)).length),
            // All tags, most common first. The chip row scrolls.
            for (final t in top) (t.key, t.value),
          ],
          active: c.chip,
          onPick: c.pickChip,
        ),
        Expanded(
          child: list.isEmpty
              ? EmptyShelf(c.query)
              : LayoutBuilder(
                  builder: (context, box) {
                    String? usedBy(FontFile f) => setIn[f.path]?.name;
                    if (c.mem.mapped.contains('Fonts')) {
                      // Map view: each font is placed by how its letters look when drawn by ThorVG.
                      final map = controller.map,
                          files = [for (final f in fonts) ?f.path];
                      controller.drawDots(m, files);
                      // Place fonts by how FontCLIP sees them once the model is available, otherwise by a small drawing of the sample.
                      final clip = likenessModel('fontclip_b32');
                      map.need(m, [for (final f in files) (f, f)], (
                        from,
                      ) async {
                        // Keyed by file, because two files can share one family name.
                        final List<Float32List?> look;
                        if (clip != null) {
                          look = await byFontClip(
                            m,
                            clip,
                            from,
                            controller.wordOf,
                          );
                        } else {
                          await controller.drawDots(m, files);
                          look = [
                            for (final f in from)
                              if (controller.dotsDrawn[f] case final g?)
                                halvedDot(g)
                              else
                                null,
                          ];
                        }
                        final kinds = [for (final f in from) fontKindOf(m, f)],
                            all = kinds.toSet().toList();
                        return joinFeatures(
                          [
                            look,
                            [
                              for (final k in kinds)
                                Float32List(all.length)..[all.indexOf(k)] = 1,
                            ],
                          ],
                          const [1, 0.5],
                        ); // The font style is blended in at half weight so fonts of the same style group together.
                      }, also: '${clip ?? ''} kinds');
                      final byPath = {for (final f in list) ?f.path: f};
                      return ShelfMapView(
                        map,
                        [
                          for (final MapEntry(key: p, value: f)
                              in byPath.entries)
                            (p, FontDot(f, c, controller, map: map)),
                        ],
                        aspect: fontDotSize.$1 / fontDotSize.$2,
                        picked: list
                            .where((f) => f.family == c.sel)
                            .firstOrNull
                            ?.path,
                        press: (p) {
                          if (byPath[p] case final f?) {
                            // One click, as elsewhere on the map: it sets the role's font when no text layer is selected.
                            c.pick(f.family);
                            commands.toRole(f);
                          }
                        },
                      );
                    }
                    final notHere =
                        c.chip == 'All' &&
                            c.query.trim().isEmpty &&
                            controller.unoffered > 0
                        ? Padding(
                            // Explains why some fonts are missing instead of hiding them silently.
                            key: const ValueKey('ws-fonts-unoffered'),
                            padding: EdgeInsets.fromLTRB(
                              WindowTokens.inset,
                              Shape.s(8),
                              WindowTokens.inset,
                              Shape.s(8),
                            ),
                            child: Text(
                              '${controller.unoffered} fonts here are not offered: they have no letters of any language (symbols, maths, emoji), or ThorVG cannot read them',
                              style: TextStyles.label(Grey.g56),
                            ),
                          )
                        : null;
                    return ShelfGrid(
                      // Only visible tiles are built, so only their font files are read (see _own).
                      shelfLooks['Fonts']!,
                      list: box.maxWidth < 440,
                      count: list.length,
                      footer: notHere,
                      tile: (i) => fontTile(
                        list[i],
                        c,
                        controller,
                        list: box.maxWidth < 440,
                        usedBy: usedBy(list[i]),
                      ),
                    );
                  },
                ),
        ),
        if (sel != null)
          ShelfFooter(
            preview: Container(
              color: WindowTokens.toneText,
              alignment: Alignment.center,
              child: Text(
                'Aa',
                style: fontFaceStyle(sel, 15, WindowTokens.onAccent),
              ),
            ),
            title: sel.family,
            meta:
                c.mem.trouble[sel.family] ??
                '${sel.path!.split('.').last.toUpperCase()} · ${File(sel.path!).parent.path.split('/').last}',
            // Applies to the selected text layer, or places a new text layer when none is selected.
            action:
                m.word(int.tryParse(c.ws.selected ?? '') ?? 0, 'kind') != 'text'
                ? 'Place'
                : 'Apply',
            done: onText,
            doneLabel: 'In use',
            // True when no text layer is selected, so the action creates a new one.
            fresh:
                m.word(int.tryParse(c.ws.selected ?? '') ?? 0, 'kind') !=
                'text',
            onAction: () => commands.setFont(sel),
          ),
      ],
    );
  }
}
