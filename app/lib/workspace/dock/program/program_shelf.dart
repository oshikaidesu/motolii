// The Program shelf: code that came from outside, kept as written and listed by what it was written for.
//
// A program is neither an effect, nor something to create, nor a preset.
// - The shelf shows a list, or the picked program's code. Typed code is saved as it is typed, and the layer it made and
//   its parameters in the inspector follow (doc_script_of reads a file that changed).
// - Godot and Unity also keep scripts as files on a shelf with their parameters in the inspector. They edit the code
//   elsewhere. It is edited here so the canvas stays in sight.
// - The code view is re_editor's CodeEditor (MIT), coloured by re_highlight (highlight.js rules and themes).
// - The tiles are in program_tiles.dart.
// - A program's name is stored in a sidecar file next to it, not inside it. Documents refer to the file by its own name,
//   and the parameters are named by its lines.
// - Right-clicking a tile opens a context menu with Rename, as Live's browser does (Live 12 manual, 4.2.1 and 4.5),
//   and shows the file in Finder or Explorer (4.7.7).
//
// The code arrives through engine/community/sites/adapter.h.
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/workspace/dock/common/empty_shelf.dart';
import 'package:motolii/workspace/dock/common/filter_chips.dart';
import 'package:motolii/workspace/dock/common/shelf_footer.dart';
import 'package:motolii/workspace/dock/program/program.dart';
import 'package:motolii/workspace/dock/program/program_commands.dart';
import 'package:motolii/workspace/shelf/copies_tiles.dart';
import 'package:motolii/workspace/shelf/program_code.dart';
import 'package:motolii/workspace/shelf/program_tiles.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';

/// The Program shelf: the programs as tiles, or the code of the picked one.
class ProgramShelf extends StatefulWidget {
  const ProgramShelf(this.c, {super.key});
  final ShelfContext c;
  @override
  State<ProgramShelf> createState() => _ProgramShelfState();
}

class _ProgramShelfState extends State<ProgramShelf> {
  ShelfContext get c => widget.c;
  final _menu = GlobalKey<ContextMenuState>();

  /// The file whose name is being edited, if any.
  String? _renaming;

  void _drawn() => setState(() {});

  @override
  void initState() {
    super.initState();
    // Show a pack's tile as soon as it has been drawn.
    CopiesTiles.drawn.addListener(_drawn);
  }

  @override
  void dispose() {
    CopiesTiles.drawn.removeListener(_drawn);
    super.dispose();
  }

  void _rename(Program p) => setState(() => _renaming = p.file);

  void _menuOn(Program p, Offset at) {
    c.pick(p.file);
    final box = _menu.currentContext?.findRenderObject() as RenderBox?;
    _menu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, [
      ContextMenuItem('Create', () => ProgramCommands(c).put(p)),
      if (p.recipe == null) ContextMenuItem('Rename…', () => _rename(p)),
      const ContextMenuItem.rule(),
      ContextMenuItem(
        Platform.isWindows ? 'Show in Explorer' : 'Show in Finder',
        () => Platform.isWindows
            ? Process.run('explorer', [
                '/select,${p.file.replaceAll('/', r'\')}',
              ])
            : Process.run('open', ['-R', p.file]),
      ),
    ]);
  }

  /// The program the selected layer was made from, whose code is the one shown. Godot likewise opens a node's script from the node.
  Program? _stood(List<Program> all) {
    final m = c.ws.inside, t = int.tryParse(c.ws.selected ?? '');
    if (m == null || t == null) return null;
    final said =
        '${m.word(t, 'file')} ${m.word(t, 'script')} ${m.word(t, 'fx')}';
    return all
        .where(
          (p) =>
              said.contains(p.file) ||
              said.contains(
                p.file.replaceFirst(RegExp(r'\.(hydra|js)$'), '.fs'),
              ),
        )
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final all = programsAndPacks(c.ws.inside);
    final forms = <String, int>{};
    for (final p in all) {
      forms[p.form] = (forms[p.form] ?? 0) + 1;
    }
    final shown = all
        .where(
          (p) =>
              (c.chip == 'All' || c.chip == p.form) &&
              (c.hit(p.name) || c.hit(p.stem) || c.hit(p.first)),
        )
        .toList();
    final sel = c.foot(
      (c.mem.programCode ? _stood(all) : null) ??
          all.where((p) => p.file == c.sel).firstOrNull,
    );
    if (all.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(Shape.s(24)),
        child: Text(
          'Copy code from the web, then Paste',
          textAlign: TextAlign.center,
          style: TextStyles.label(Grey.g63),
        ),
      );
    }
    if (!c.mem.programCode) {
      ProgramTiles.ask(
        all.where((p) => p.recipe == null).map((p) => p.file),
        () {
          if (mounted) setState(() {});
        },
      );
    }
    // A pack's tile is drawn by its name, as Create's expressions are.
    String tile(Program p) => switch (p.recipe) {
      final r? => CopiesTiles.of(p.file, make: r),
      _ =>
        File(ProgramTiles.home(p.file)).existsSync()
            ? ProgramTiles.home(p.file)
            : '',
    };
    return ContextMenu(
      key: _menu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!c.mem.programCode)
            FilterChips(
              [
                ('All', all.length),
                for (final e in forms.entries) (e.key, e.value),
              ],
              active: c.chip,
              onPick: c.pickChip,
            ),
          Expanded(
            child:
                c.mem.programCode &&
                    sel != null &&
                    // A pack's file belongs to the library and is never written over here.
                    sel.recipe == null
                ? ProgramCode(sel.file, (text) {
                    File(sel.file).writeAsStringSync(text);
                    ProgramCommands(c).saved(sel);
                  }, key: ValueKey(sel.file))
                : shown.isEmpty
                ? EmptyShelf(c.query)
                : ShelfGrid(
                    shelfLooks['Program']!,
                    count: shown.length,
                    tile: (i) {
                      final p = shown[i];
                      // Two presses create it, as on Create. The key includes the tile's modification time. Otherwise an
                      // Image with the same file would keep showing the old picture after the tile is drawn again.
                      return ShelfTile(
                        ShelfItem(p.file, p.name, picture: tile(p)),
                        shelfLooks['Program']!,
                        key: ValueKey(
                          'ws-program-${p.stem}-${tile(p).isEmpty ? 0 : File(tile(p)).lastModifiedSync().millisecondsSinceEpoch}',
                        ),
                        onTap: () => c.pick(p.file),
                        onApply: () => ProgramCommands(c).put(p),
                        onMenu: (at) => _menuOn(p, at),
                        picked: c.sel == p.file,
                        naming: _renaming == p.file
                            ? ShelfNameField(p.name, (to) {
                                if (to != null) p.rename(to);
                                setState(() => _renaming = null);
                              })
                            : null,
                      );
                    },
                  ),
          ),
          // Large, as on the Effects shelf.
          if (sel != null && !c.mem.programCode && tile(sel).isNotEmpty)
            SizedBox(
              height: Shape.z(140),
              child: TileMoving(tile(sel), playing: true),
            ),
          if (sel != null)
            ShelfFooter(
              preview: dockBadge(
                AppGlyphs.program,
                WindowTokens.toneText,
                size: Shape.z(34),
              ),
              title: sel.name,
              meta:
                  c.mem.trouble[sel.file]?.replaceAll(
                    'the script ${sel.file}: ',
                    '',
                  ) ??
                  sel.first,
              action: 'Create',
              fresh: true,
              onAction: () => ProgramCommands(c).put(sel),
            ),
        ],
      ),
    );
  }
}
