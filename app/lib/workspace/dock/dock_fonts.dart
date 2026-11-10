// The Fonts shelf: each font is shown set in its own face.
// Effects are in dock_effects.dart, files and media in dock_files.dart.
import 'package:motolii/skin/window_tokens.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart' show Motolii, MotoliiDocument, MotoliiWrites, MotoliiQuestions, MotoliiShelves;
import 'package:motolii/bridge/engine_paths.dart' show motoliiDir;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/workspace/dock/dock_files.dart' show dockRead;
import 'package:motolii/workspace/dock/dock_map.dart';
import 'package:motolii/storage/kept_file.dart' show fileKeep, fileList;
import 'package:motolii/workspace/dock/dock_widgets.dart';
import 'package:motolii/workspace/dock/dock_tags.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart' show EffectTiles;
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/state/workspace_state.dart';

part 'dock_font_map.dart';

/// A font file offered on the shelf.
class _Font {
  const _Font(this.family, {this.path, this.script, this.sample});
  final String family;

  /// The font file.
  final String? path;

  /// For a font without Latin letters: its script, and a sample text in that script (from samples.json).
  final String? script, sample;
}

final _fontFile = RegExp(r'\.(ttf|otf|ttc|otc)$', caseSensitive: false);

/// The font files of this machine and of the project folder that the engine can set text in.
/// They are read once, in the background. A font is named after its file; a collection (.ttc) is one row
/// and only its first face is used, because ThorVG sets no other (see thorvg_ttc.patch).
List<_Font>? _disk;
Future<void>? _reading;
List<_Font> _diskFonts(Ws ws) {
  fontsRead(ws);
  return _disk ?? const [];
}

/// How many fonts the shelf offers, once the files are read.
int? get fontsOffered => _disk?.length;

/// How many font files the shelf does not offer: they have no letters of any language the engine can set
/// (symbols, maths, emoji), or ThorVG cannot read them.
int fontsUnoffered = 0;

/// Reads the font files once, on the root zone so a test can wait for it.
/// A font that can set the shelf's sample line is offered with that line. A font with other letters is offered
/// with a sample in its own script, as fonts.google.com does (samples.json, from Google Fonts' gflanguages),
/// so the user never sees missing-glyph boxes. The bundled fonts and the user's own are offered as well.
Future<void> fontsRead(Ws ws) => _reading ??= Zone.root.run<Future<void>>(() async {
  final files = <String>[];
  for (final dir in [
    '/System/Library/Fonts',
    '/System/Library/Fonts/Supplemental',
    '/Library/Fonts',
    '${Platform.environment['HOME']}/Library/Fonts',
    // The bundled fallback font the engine draws with.
    '$motoliiDir/third_party/noto_sans_jp',
    '${EffectTiles.own}/fonts',
    ?ws.documentFolder,
  ]) {
    try {
      for (final e in await Directory(dir).list().toList()) {
        if (e is File && _fontFile.hasMatch(e.path)) files.add(e.path);
      }
    } on FileSystemException catch (_) {
      // A folder that is missing or unreadable has no fonts to offer.
    }
  }
  var scripts = const <(String, String)>[];
  try {
    scripts = [
      for (final s in jsonDecode(File('$motoliiDir/third_party/gflanguages/samples.json').readAsStringSync()) as List)
        for (final w in [s['sample'], s['letters']])
          // The sample text, or else the first letters of the alphabet for a script that has no sample.
          if (w is String && w.isNotEmpty) ('${s['script']}', w),
    ];
  } catch (_) {
    // Without samples.json only fonts with Latin letters are offered.
  }
  final first = await ws.inside!.settingFirst(files, [_sample, for (final (_, w) in scripts) w]);
  _disk = [
    for (final (i, f) in files.indexed)
      if (first[i] >= 0)
        _Font(
          f.split('/').last.substring(0, f.split('/').last.length - 4),
          path: f,
          script: first[i] == 0 ? null : scripts[first[i] - 1].$1,
          sample: first[i] == 0 ? null : scripts[first[i] - 1].$2,
        ),
  ]..sort((a, b) => a.family.toLowerCase().compareTo(b.family.toLowerCase()));
  fontsUnoffered = first.where((k) => k < 0).length;
  _ownWords = {
    for (final f in _disk!)
      if ((f.path, f.sample) case (final p?, final w?)) p: w,
  };
  dockRead.value++;
});

/// The file that stores the eight most recently used fonts, newest first. A test points it elsewhere with
/// [fontRecentAt]. The Ease tool panel stores its recent easings the same way (ease_stars.json).
File _recentFile = File('${Platform.environment['HOME']}/.motolii/font_recent.json');
List<String>? _recent;
void fontRecentAt(File f) => (_recentFile = f, _recent = null);
List<String> fontRecent() => _recent ??= [for (final s in fileList(_recentFile)) '$s'];
void _used(String family) {
  final r = fontRecent()
    ..remove(family)
    ..insert(0, family);
  if (r.length > 8) r.removeRange(8, r.length);
  // If the write fails, the list is still correct while the app is open.
  fileKeep(_recentFile, jsonEncode(r));
}

/// Sets the font on the selected text layer. With no text layer selected, adds a new text layer in that font.
void _setFont(DockCtx c, _Font f) {
  _used(f.family);
  final m = c.ws.inside!, t = int.tryParse(c.ws.selected ?? '');
  void told(bool done, String why) => c.set(() => done ? c.mem.trouble.remove(f.family) : c.mem.trouble[f.family] = why);
  if (t != null && m.word(t, 'kind') == 'text') return c.ws.after(m.later('say', layer: t, name: 'file', word: f.path!), told);
  // The new text layer and its colors form one undo step.
  m.later('together', number: 1);
  c.ws.after(m.later('add', name: 'text', word: f.path!), null, (made) => c.ws.select('$made'));
  wsInked(c.ws, 'text', '');
  c.ws.after(m.later('together'), told);
}

/// With no text layer selected, a click on a font sets the font of the current role, like a color click on the
/// Colors shelf. With a text layer selected nothing happens here: its font is set by a double-click or Apply.
void _toRole(DockCtx c, _Font f) {
  final m = c.ws.inside, t = int.tryParse(c.ws.selected ?? '');
  if (m == null || f.path == null || (t != null && m.word(t, 'kind') == 'text')) return;
  _used(f.family);
  c.set(() => c.ws.fontRole == 'body' ? c.ws.bodyFont = f.path! : c.ws.titleFont = f.path!);
}

/// Adds a text layer in the given font at the playhead, with the current colors, and selects it.
/// Like Canva's "Add a heading" and "Add a little bit of body text".
void _addIn(DockCtx c, String font) {
  final m = c.ws.inside!;
  // The new text layer and its colors form one undo step.
  m.later('together', number: 1);
  c.ws.after(m.later('add', name: 'text', word: font), null, (made) => c.ws.select('$made'));
  wsInked(c.ws, 'text', '');
  c.ws.after(m.later('together'), (done, why) => c.set(() => done ? c.mem.trouble.remove('role') : c.mem.trouble['role'] = why));
}

/// The title and body fonts, shown first on the shelf like PowerPoint's Headings and Body theme fonts
/// and Canva's brand fonts.
///
/// With no text layer selected, clicking a role chooses which role the next clicked font is for.
/// With a text layer selected, clicking a role applies that role's font to it. The + button adds a new text in that font.
class _Roles extends StatelessWidget {
  const _Roles(this.c, this.fonts);
  final DockCtx c;
  final List<_Font> fonts;
  @override
  Widget build(BuildContext context) {
    final m = c.ws.inside!, t = int.tryParse(c.ws.selected ?? ''), onText = t != null && m.word(t, 'kind') == 'text';
    Widget role(String r, String label, String face) {
      final f = fonts.where((f) => f.path == face).firstOrNull ?? _Font(face.split('/').last.replaceFirst(RegExp(r'\.[^.]*$'), ''), path: face);
      final on = !onText && c.ws.fontRole == r;
      return Expanded(
        child: DockHover(
          key: ValueKey('font-role-$r'),
          onTap: () => onText ? c.ws.after(m.later('say', layer: t, name: 'file', word: face)) : c.set(() => c.ws.fontRole = r),
          builder: (context, h) => Container(
            height: Shape.z(46),
            padding: EdgeInsets.only(left: Shape.s(8), right: Shape.s(4)),
            color: dockFill(on, h, WsT.card),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: T.label(dockInk(on, Grey.g63))),
                      SizedBox(height: Shape.s(2)),
                      Text(f.family, maxLines: 1, overflow: TextOverflow.ellipsis, style: _face(f, 14, dockInk(on, Grey.g95))),
                    ],
                  ),
                ),
                Chip(key: ValueKey('font-add-$r'), label: '+', onTap: () => _addIn(c, face)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: WsT.gutter),
      child: Row(
        children: [
          role('title', 'Title', c.ws.titleFace),
          SizedBox(width: WsT.gutter),
          role('body', 'Body', c.ws.bodyFace),
        ],
      ),
    );
  }
}

/// The sample line each font is shown with.
const _sample = 'Motion for more relations';

/// The badge shown for a font without Latin letters. Latin text set in it is drawn in the fallback font
/// (see type_fallback), and the inspector says so.
const _noLatin = 'NO LATIN';

/// The Fonts shelf: a grid, list or map of the available fonts, with the title and body roles above.
class FontsShelf extends StatelessWidget {
  const FontsShelf(this.c, {super.key});
  final DockCtx c;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(valueListenable: dockRead, builder: (context, _, _) => _shelf(context));

  Widget _shelf(BuildContext context) {
    final m = c.ws.inside;
    if (m == null) return const SizedBox.shrink();
    final fonts = _diskFonts(c.ws);
    // Maps each font file to the text layer that uses it.
    final setIn = {
      for (final l in c.ws.layers)
        if (m.word(int.parse(l.id), 'kind') == 'text') m.whole(m.word(int.parse(l.id), 'file')): l,
    };
    bool used(_Font f) => setIn.containsKey(f.path);
    Set<String> tagsOf(_Font f) => DockTags.of('Fonts', f.family, f.path == null ? const <String>{} : (c.ws.inside?.fontTags(f.path!) ?? const <String>{}));
    var hits = fonts.where((f) => DockTags.hit(c.query, f.family, tagsOf(f))).toList();
    if (hits.isEmpty && c.query.trim().isNotEmpty) {
      // Nothing matches the query as typed, so show the five nearest fonts.
      final near = c.near([for (final f in fonts) (f.family, '${f.family} ${tagsOf(f).join(' ')}', '')]);
      hits = [for (final id in near) ...fonts.where((f) => f.family == id).take(1)];
    }
    final vocab = <String, int>{};
    for (final f in hits) {
      for (final t in tagsOf(f)) {
        vocab[t] = (vocab[t] ?? 0) + 1;
      }
    }
    final top = vocab.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    bool keep(_Font f) => switch (c.chip) {
      'All' => true,
      'Used' => used(f),
      'Recent' => fontRecent().contains(f.family),
      'Starred' => c.starred(f.family),
      // A tag chip: the fonts that have the tag.
      final tag => tagsOf(f).contains(tag),
    };
    final list = hits.where(keep).toList();
    // Newest first.
    if (c.chip == 'Recent') list.sort((a, b) => fontRecent().indexOf(a.family).compareTo(fontRecent().indexOf(b.family)));
    final sel = fonts.where((f) => f.family == c.sel).firstOrNull;
    final picked = sel == null ? null : setIn[sel.path], onText = picked != null && picked.id == c.ws.selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Roles(c, fonts),
        DockChips(
          [
            ('All', hits.length),
            ('Used', hits.where(used).length),
            ('Recent', hits.where((f) => fontRecent().contains(f.family)).length),
            ('Starred', hits.where((f) => c.starred(f.family)).length),
            // All tags, most common first. The chip row scrolls.
            for (final t in top) (t.key, t.value),
          ],
          active: c.chip,
          onPick: c.pickChip,
        ),
        Expanded(
          child: list.isEmpty
              ? DockEmpty(c.query)
              : LayoutBuilder(
                  builder: (context, box) {
                    String? usedBy(_Font f) => setIn[f.path]?.name;
                    if (c.mem.mapped.contains('Fonts')) {
                      // Map view: each font is placed by how its letters look when drawn by ThorVG.
                      final map = dockMap('Fonts'), files = [for (final f in fonts) ?f.path];
                      _drawAll(m, files);
                      // Place fonts by how FontCLIP sees them once the model is available, otherwise by a small drawing of the sample.
                      final clip = dockModel('fontclip_b32');
                      map.need(m, [for (final f in files) (f, f)], (from) async {
                        // Keyed by file, because two files can share one family name.
                        final List<Float32List?> look;
                        if (clip != null) {
                          look = await _byFontClip(m, clip, from);
                        } else {
                          await _drawAll(m, files);
                          look = [
                            for (final f in from)
                              if (_drawn[f] case final g?) _halved(g) else null,
                          ];
                        }
                        final kinds = [for (final f in from) _kindOf(m, f)], all = kinds.toSet().toList();
                        return dockTogether(
                          [
                            look,
                            [for (final k in kinds) Float32List(all.length)..[all.indexOf(k)] = 1],
                          ],
                          const [1, 0.5],
                        ); // The font style is blended in at half weight so fonts of the same style group together.
                      }, also: '${clip ?? ''} kinds');
                      final byPath = {for (final f in list) ?f.path: f};
                      return DockMap(
                        map,
                        [for (final MapEntry(key: p, value: f) in byPath.entries) (p, _FontDot(f, c, map: map))],
                        aspect: _dot.$1 / _dot.$2,
                        picked: list.where((f) => f.family == c.sel).firstOrNull?.path,
                        press: (p) {
                          if (byPath[p] case final f?) {
                            // One click, as elsewhere on the map: it sets the role's font when no text layer is selected.
                            c.pick(f.family);
                            _toRole(c, f);
                          }
                        },
                      );
                    }
                    final notHere = c.chip == 'All' && c.query.trim().isEmpty && fontsUnoffered > 0
                        ? Padding(
                            // Explains why some fonts are missing instead of hiding them silently.
                            key: const ValueKey('ws-fonts-unoffered'),
                            padding: EdgeInsets.fromLTRB(WsT.inset, Shape.s(8), WsT.inset, Shape.s(8)),
                            child: Text(
                              '$fontsUnoffered fonts here are not offered: they have no letters of any language (symbols, maths, emoji), or ThorVG cannot read them',
                              style: T.label(Grey.g56),
                            ),
                          )
                        : null;
                    return ShelfGrid(
                      // Only visible tiles are built, so only their font files are read (see _own).
                      shelfLooks['Fonts']!,
                      list: box.maxWidth < 440,
                      count: list.length,
                      footer: notHere,
                      tile: (i) => _fontTile(list[i], c, list: box.maxWidth < 440, usedBy: usedBy(list[i])),
                    );
                  },
                ),
        ),
        if (sel != null)
          DockFooter(
            preview: Container(
              color: WsT.toneText,
              alignment: Alignment.center,
              child: Text('Aa', style: _face(sel, 15, WsT.onAccent)),
            ),
            title: sel.family,
            meta: c.mem.trouble[sel.family] ?? '${sel.path!.split('.').last.toUpperCase()} · ${File(sel.path!).parent.path.split('/').last}',
            // Applies to the selected text layer, or places a new text layer when none is selected.
            action: m.word(int.tryParse(c.ws.selected ?? '') ?? 0, 'kind') != 'text' ? 'Place' : 'Apply',
            done: onText,
            doneLabel: 'In use',
            // True when no text layer is selected, so the action creates a new one.
            fresh: m.word(int.tryParse(c.ws.selected ?? '') ?? 0, 'kind') != 'text',
            onAction: () => _setFont(c, sel),
          ),
      ],
    );
  }
}

/// Returns the font family a shelf row is set in, by loading the font file's bytes the first time the row is shown.
/// FontLoader is Flutter's way to use a font that is not bundled with the app.
///
/// The file name is often not the family name (Songti.ttc is "Songti SC", and a file in ~/Library/Fonts may use its
/// PostScript name), and the regular face of a family is not always the face ThorVG sets. Loading the file shows
/// the row in the same face the preview will use. The family name serves as a fallback until the file is read.
final _read = <String>{};
String _own(_Font f) {
  final p = f.path;
  if (p == null) return f.family;
  if (_read.add(p)) {
    Zone.root.run(
      () => (FontLoader(p)..addFont(File(p).readAsBytes().then(ByteData.sublistView))).load().catchError((Object _) {}),
    ); // If the file has gone since, the row stays in the family name's face.
  }
  return p;
}

/// The text style that sets text in the font [f].
TextStyle _face(_Font f, double size, Color c) => TextStyle(
  fontFamily: _own(f),
  fontFamilyFallback: [f.family, '.AppleSystemUIFont'],
  fontSize: size,
  color: T.ink(c),
  height: 1.1,
  decoration: TextDecoration.none,
);

/// One font as a tile of the Fonts shelf: a row (narrow) or a card (wide), its sample set in its own face.
Widget _fontTile(_Font f, DockCtx c, {required bool list, String? usedBy}) {
  final sel = c.sel == f.family, star = c.starred(f.family);
  final tags =
      f.script ?? DockTags.of('Fonts', f.family, f.path == null ? const <String>{} : (c.ws.inside?.fontTags(f.path!) ?? const <String>{})).take(2).join(' ');
  return ShelfTile(
    ShelfItem(f.family, f.family, label: f.script ?? '', about: f.sample ?? ''),
    shelfLooks['Fonts']!,
    list: list,
    picked: sel,
    picks: false,
    onTap: () {
      c.pick(f.family);
      _toRole(c, f);
    },
    // A double-click sets the font. Dragging the tile into the preview does the same.
    onApply: () => _setFont(c, f),
    art: (_) => list
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(f.sample ?? _sample, maxLines: 1, style: _face(f, 17, dockInk(sel, Grey.g95))),
          )
        : Text(f.sample ?? 'Motion', maxLines: 1, softWrap: false, overflow: TextOverflow.fade, style: _face(f, 28, dockInk(sel, Grey.g95))),
    says: '${f.family}  ·  $tags',
    marks: [
      if (f.script != null) ...[SizedBox(width: Shape.s(6)), Chip(label: _noLatin, look: ChipLook.tag(null))],
      if (usedBy case final u?) ...[SizedBox(width: Shape.s(6)), Chip(label: u, look: ChipLook.tag(sel ? null : WsT.toneText))],
    ],
    after: (h) => [
      if (star || h || sel)
        DockStar(on: star, ink: sel ? WsT.onAccent : null, onTap: () => c.star(f.family))
      else
        SizedBox(width: list ? Shape.s(20) : null, height: list ? null : Shape.s(20)),
    ],
  );
}
