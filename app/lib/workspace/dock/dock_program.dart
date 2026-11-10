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
import 'package:motolii/skin/window_tokens.dart';

import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/shelf/copies_tiles.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/workspace/dock/dock_folder_row.dart';
import 'package:motolii/workspace/dock/dock_widgets.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';
import 'package:motolii/workspace/shelf/program_tiles.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/widgets/menu.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';
import 'package:motolii/workspace/shelf/program_code.dart';

/// One program on the shelf: its file, what it was written for, and the hash that tells it from the others of those.
class Program {
  Program(this.file, {this.recipe, this.kind});
  final String file;

  /// [recipe] is the name of a closed pack from the library: a whole Cavalry script or a p5.js sketch as it came
  /// (CREATE_PROGRAM.md). It is created by that name, as Create does (doc_make).
  ///
  /// [kind] is what the program was written for, as the engine reports it. A pack's file is never overwritten.
  final String? recipe, kind;
  String get stem => file.substring(file.lastIndexOf('/') + 1, file.lastIndexOf('.'));
  String get form => kind ?? (stem.contains('-') ? stem.substring(0, stem.lastIndexOf('-')) : stem);
  String get tail => stem.contains('-') ? stem.substring(stem.lastIndexOf('-') + 1) : '';

  /// The name used when none is set: what it was written for, then its hash.
  String get plain => '$form $tail'.trim();

  /// The display name: the user's own name if set, otherwise what the file says about itself.
  ///
  /// That is the site title adapter_net.h wrote at the head of the file, or the description of a multi-tab file.
  String get name {
    if (recipe case final r?) return r;
    try {
      if (shelfSidecar(file).existsSync()) return shelfSidecar(file).readAsStringSync().trim();
      final lines = File(file).readAsLinesSync();
      final kept = RegExp(r'^/\*\{.*"DESCRIPTION":"([^"]*)"').firstMatch(lines.first)?[1];
      if (kept != null && kept != 'Shadertoy') return kept;
      return [for (final l in lines.take(8)) RegExp(r'^// (.+) by [^,]+, [^,]+, openprocessing\.org/sketch/\d+').firstMatch(l)?[1]].nonNulls.firstOrNull ??
          plain;
    } catch (_) {
      return plain;
    }
  }

  /// Sets the name to [to]. An empty name removes the sidecar, so [name] falls back to [plain].
  void rename(String to) {
    if (to.trim().isNotEmpty) return shelfSidecar(file).writeAsStringSync(to.trim());
    if (shelfSidecar(file).existsSync()) shelfSidecar(file).deleteSync();
  }

  /// The first line of the file that says something.
  String get first {
    try {
      final kept = RegExp(r'^/\*\{.*"DESCRIPTION":"([^"]*)"(?:,"CREDIT":"([^"]*)")?')
          // A multi-tab file describes itself in its first line.
          .firstMatch(File(file).readAsLinesSync().first);
      if (kept != null && kept[1] != 'Shadertoy') return kept[2] == null ? kept[1]! : '${kept[1]} · ${kept[2]}';
      return File(file)
          .readAsLinesSync()
          .map((l) => l.trim())
          .firstWhere((l) => l.isNotEmpty && !l.startsWith('//') && !l.startsWith('#') && !l.startsWith('/*'), orElse: () => '');
    } catch (_) {
      return '';
    }
  }
}

/// The user's programs, most recently written first.
///
/// A Hydra or p5 source is hidden when the shader it became sits beside it, because that shader stands for it.
List<Program> programs() {
  final dir = Directory('${EffectTiles.own}/programs');
  if (!dir.existsSync()) return const [];
  final all = dir.listSync().whereType<File>().where((f) => RegExp(r'\.(js|fs|hydra)$').hasMatch(f.path)).toList();
  final made = {
    for (final f in all)
      if (RegExp(r'\.(hydra|js)$').hasMatch(f.path)) f.path.replaceFirst(RegExp(r'\.(hydra|js)$'), '.fs'),
  };
  final kept = all.where((f) => !made.contains(f.path)).toList()..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  return [for (final f in kept) Program(f.path)];
}

/// The user's programs, then the library's packs that are not among them.
///
/// A pack that was also put in from the web and kept appears only once.
List<Program> programsAndPacks(Motolii? m) {
  final own = programs(), stems = {for (final p in own) p.stem}, kinds = {for (final (name, kind) in m?.packKinds ?? const <(String, String)>[]) name: kind};
  return [
    ...own,
    for (final (name, file) in m?.packs ?? const <(String, String)>[])
      if (!stems.contains(name)) Program(file, recipe: name, kind: kinds[name]),
  ];
}

class ProgramShelf extends StatefulWidget {
  const ProgramShelf(this.c, {super.key});
  final DockCtx c;
  @override
  State<ProgramShelf> createState() => _ProgramShelfState();
}

class _ProgramShelfState extends State<ProgramShelf> {
  DockCtx get c => widget.c;
  void _told(Program p, bool done, String why) => c.set(() => done ? c.mem.trouble.remove(p.file) : c.mem.trouble[p.file] = why);
  final _menu = GlobalKey<WsMenuState>();

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

  void _put(Program p) {
    final m = c.ws.inside!;
    if (p.recipe case final r?) {
      return c.ws.after(
        m.later('create', word: r),
        (done, why) => _told(p, done, why),
        (made) => c.ws.select('$made'),
        // Created as Create's tile does it (see _make in dock_make_colors.dart).
      );
    }
    c.ws.after(m.later('adapter', layer: int.tryParse(c.ws.selected ?? '') ?? 0, word: p.file), (done, why) => _told(p, done, why), (made) {
      if (made <= 0) return;
      if (p.name != p.plain) c.ws.after(m.later('say', layer: made, name: 'name', word: p.name));
      c.ws.select('$made');
    });
  }

  void _rename(Program p) => setState(() => _renaming = p.file);

  void _menuOn(Program p, Offset at) {
    c.pick(p.file);
    final box = _menu.currentContext?.findRenderObject() as RenderBox?;
    _menu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, [
      WsMenuItem('Create', () => _put(p)),
      if (p.recipe == null) WsMenuItem('Rename…', () => _rename(p)),
      const WsMenuItem.rule(),
      WsMenuItem(
        Platform.isWindows ? 'Show in Explorer' : 'Show in Finder',
        () => Platform.isWindows ? Process.run('explorer', ['/select,${p.file.replaceAll('/', r'\')}']) : Process.run('open', ['-R', p.file]),
      ),
    ]);
  }

  /// Applies the saved code: the layer made from it follows, and so do its parameters in the inspector.
  ///
  /// If the code does not run, the reason is shown under the code.
  void _saved(Program p) {
    final m = c.ws.inside;
    if (m == null) return;
    c.ws.after(m.later('code', word: p.file), (done, why) {
      _told(p, done, why);
      c.ws.reread();
    });
  }

  /// The program the selected layer was made from, whose code is the one shown. Godot likewise opens a node's script from the node.
  Program? _stood(List<Program> all) {
    final m = c.ws.inside, t = int.tryParse(c.ws.selected ?? '');
    if (m == null || t == null) return null;
    final said = '${m.word(t, 'file')} ${m.word(t, 'script')} ${m.word(t, 'fx')}';
    return all.where((p) => said.contains(p.file) || said.contains(p.file.replaceFirst(RegExp(r'\.(hydra|js)$'), '.fs'))).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final all = programsAndPacks(c.ws.inside);
    final forms = <String, int>{};
    for (final p in all) {
      forms[p.form] = (forms[p.form] ?? 0) + 1;
    }
    final shown = all.where((p) => (c.chip == 'All' || c.chip == p.form) && (c.hit(p.name) || c.hit(p.stem) || c.hit(p.first))).toList();
    final sel = c.foot((c.mem.programCode ? _stood(all) : null) ?? all.where((p) => p.file == c.sel).firstOrNull);
    if (all.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(Shape.s(24)),
        child: Text('Copy code from the web, then Paste', textAlign: TextAlign.center, style: T.label(Grey.g63)),
      );
    }
    if (!c.mem.programCode) {
      ProgramTiles.ask(all.where((p) => p.recipe == null).map((p) => p.file), () {
        if (mounted) setState(() {});
      });
    }
    // A pack's tile is drawn by its name, as Create's expressions are.
    String tile(Program p) => switch (p.recipe) {
      final r? => CopiesTiles.of(p.file, make: r),
      _ => File(ProgramTiles.home(p.file)).existsSync() ? ProgramTiles.home(p.file) : '',
    };
    return WsMenu(
      key: _menu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!c.mem.programCode) DockChips([('All', all.length), for (final e in forms.entries) (e.key, e.value)], active: c.chip, onPick: c.pickChip),
          Expanded(
            child:
                c.mem.programCode &&
                    sel != null &&
                    // A pack's file belongs to the library and is never written over here.
                    sel.recipe == null
                ? ProgramCode(sel.file, (text) {
                    File(sel.file).writeAsStringSync(text);
                    _saved(sel);
                  }, key: ValueKey(sel.file))
                : shown.isEmpty
                ? DockEmpty(c.query)
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
                        key: ValueKey('ws-program-${p.stem}-${tile(p).isEmpty ? 0 : File(tile(p)).lastModifiedSync().millisecondsSinceEpoch}'),
                        onTap: () => c.pick(p.file),
                        onApply: () => _put(p),
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
          if (sel != null && !c.mem.programCode && tile(sel).isNotEmpty) SizedBox(height: Shape.z(140), child: TileMoving(tile(sel), playing: true)),
          if (sel != null)
            DockFooter(
              preview: dockBadge(DockG.program, WsT.toneText, size: Shape.z(34)),
              title: sel.name,
              meta: c.mem.trouble[sel.file]?.replaceAll('the script ${sel.file}: ', '') ?? sel.first,
              action: 'Create',
              fresh: true,
              onAction: () => _put(sel),
            ),
        ],
      ),
    );
  }
}
