// The Fonts shelf: each row set in its own face. Effects live in dock_effects.dart, files and media in dock_files.dart.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/widgets.dart';

import '../motolii.dart' show Motolii, MotoliiQuestions;
import '../tokens.dart';
import 'desk_kit.dart' show DeskChip;
import 'dock_files.dart' show dockRead;
import 'dock_map.dart';
import 'dock_parts.dart';
import 'dock_tags.dart';
import 'ws.dart';

// ---------------------------------------------------------------- fonts

class _Font {
  const _Font(this.family, {this.path});
  final String family;
  final String? path; // (the font's file)
}


final _fontFile = RegExp(r'\.(ttf|otf|ttc|otc)$', caseSensitive: false);

/// Joined: the font files of this machine that the inside sets words in, and those beside the document: read once,
/// without waiting. A font is called by its file's name; a collection (.ttc) is one row, its first face (ThorVG sets no
/// other: thorvg_ttc.patch).
List<_Font>? _disk;
Future<void>? _reading;
List<_Font> _diskFonts(Ws ws) {
  fontsRead(ws);
  return _disk ?? const [];
}

/// How many fonts the shelf offers, once they are read (joined).
int? get fontsOffered => _disk?.length;

/// The reading itself: once, on the program's own clock (a test may wait for it). Only the fonts the inside sets the
/// shelf's own line in are offered (a font of other letters, or one ThorVG cannot read, is not).
Future<void> fontsRead(Ws ws) => _reading ??= Zone.root.run<Future<void>>(() async {
  final files = <String>[];
  for (final dir in ['/System/Library/Fonts', '/System/Library/Fonts/Supplemental', '/Library/Fonts', '${Platform.environment['HOME']}/Library/Fonts', ?ws.documentFolder]) {
    try {
      for (final e in await Directory(dir).list().toList()) {
        if (e is File && _fontFile.hasMatch(e.path)) files.add(e.path);
      }
    } on FileSystemException catch (_) {} // (a folder that is not there, or may not be read: it has no fonts to offer)
  }
  final sets = await ws.inside!.setting(files, _sample);
  _disk = [
    for (final f in sets) _Font(f.split('/').last.substring(0, f.split('/').last.length - 4), path: f),
  ]..sort((a, b) => a.family.toLowerCase().compareTo(b.family.toLowerCase()));
  dockRead.value++;
});

/// Where the fonts set lately are kept, the newest first, eight (a test points it elsewhere: [fontRecentAt]), as the
/// Ease desk keeps its recent ways (ease_stars.json).
File _recentFile = File('${Platform.environment['HOME']}/.motolii/font_recent.json');
List<String>? _recent;
void fontRecentAt(File f) => (_recentFile = f, _recent = null);
List<String> fontRecent() => _recent ??= () {
  try {
    return [for (final s in jsonDecode(_recentFile.readAsStringSync()) as List) '$s'];
  } catch (_) {
    return <String>[];
  }
}();
void _used(String family) {
  final r = fontRecent()
    ..remove(family)
    ..insert(0, family);
  if (r.length > 8) r.removeRange(8, r.length);
  try {
    _recentFile.parent.createSync(recursive: true);
    _recentFile.writeAsStringSync(jsonEncode(r));
  } catch (_) {}   // (not kept: known while the window is open)
}

/// Joined: the font given to the picked text; with no text picked, a new text set in it.
void _setFont(DockCtx c, _Font f) {
  _used(f.family);
  final m = c.ws.inside!, t = int.tryParse(c.ws.selected ?? '');
  void told(bool done, String why) => c.set(() => done ? c.mem.trouble.remove(f.family) : c.mem.trouble[f.family] = why);
  if (t != null && m.word(t, 'kind') == 'text') return c.ws.after(m.later('say', thing: t, name: 'file', word: f.path!), told);   // (without waiting)
  m.later('together', number: 1);   // (one step: the text and its inks)
  c.ws.after(m.later('add', name: 'text', word: f.path!), null, (made) => c.ws.select('$made'));
  wsInked(c.ws, 'text', '');
  c.ws.after(m.later('together'), told);
}

/// With no text picked, a font pressed is the font of the role the shelf sets now (one press, as a colour pressed
/// colours on the Colors shelf); a picked text's own font is set as before, by two presses or Apply.
void _toRole(DockCtx c, _Font f) {
  final m = c.ws.inside, t = int.tryParse(c.ws.selected ?? '');
  if (m == null || f.path == null || (t != null && m.word(t, 'kind') == 'text')) return;
  _used(f.family);
  c.set(() => c.ws.fontRole == 'body' ? c.ws.bodyFont = f.path! : c.ws.titleFont = f.path!);
}

/// A new text in a role's font, at the playhead, in the inks, picked: Canva's Add a heading, Add a little bit of body text.
void _addIn(DockCtx c, String font) {
  final m = c.ws.inside!;
  m.later('together', number: 1);   // (one step: the text and its inks)
  c.ws.after(m.later('add', name: 'text', word: font), null, (made) => c.ws.select('$made'));
  wsInked(c.ws, 'text', '');
  c.ws.after(m.later('together'), (done, why) => c.set(() => done ? c.mem.trouble.remove('role') : c.mem.trouble['role'] = why));
}

/// The two fonts a title and a body text are set in, first on the shelf as PowerPoint's Headings and Body theme fonts are
/// first in its list of fonts (and as Canva's brand fonts, a heading's and a body's): with no text picked, a press on one
/// says which role a font pressed now is for; with a text picked, it puts that role's font on it (Canva's brand text
/// styles); its + adds a text in it (golf_noise.md ㉚, P04).
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
          onTap: () => onText ? c.ws.after(m.later('say', thing: t, name: 'file', word: face)) : c.set(() => c.ws.fontRole = r),
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
                DeskChip(key: ValueKey('font-add-$r'), label: '+', onTap: () => _addIn(c, face)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: WsT.gutter),
      child: Row(children: [role('title', 'Title', c.ws.titleFace), SizedBox(width: WsT.gutter), role('body', 'Body', c.ws.bodyFace)]),
    );
  }
}

const _sample = 'Motion for more relations';

class FontsShelf extends StatelessWidget {
  const FontsShelf(this.c, {super.key});
  final DockCtx c;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(valueListenable: dockRead, builder: (context, _, _) => _shelf(context));

  Widget _shelf(BuildContext context) {
    final m = c.ws.inside;
    if (m == null) return const SizedBox.shrink();
    final fonts = _diskFonts(c.ws);
    // (which text of the document is set in which font file)
    final setIn = {
      for (final l in c.ws.layers)
        if (m.word(int.parse(l.id), 'kind') == 'text') m.whole(m.word(int.parse(l.id), 'file')): l,
    };
    bool used(_Font f) => setIn.containsKey(f.path);
    Set<String> tagsOf(_Font f) => DockTags.of('Fonts', f.family, f.path == null ? const <String>{} : (c.ws.inside?.fontTags(f.path!) ?? const <String>{}));
    var hits = fonts.where((f) => DockTags.hit(c.query, f.family, tagsOf(f))).toList();
    if (hits.isEmpty && c.query.trim().isNotEmpty) {   // (nothing has the words as typed: the nearest five, golf (97))
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
      final tag => tagsOf(f).contains(tag),   // (a tag chip: the families with it)
    };
    final list = hits.where(keep).toList();
    if (c.chip == 'Recent') list.sort((a, b) => fontRecent().indexOf(a.family).compareTo(fontRecent().indexOf(b.family)));   // (the newest first)
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
            for (final t in top) (t.key, t.value),   // (all, the most first: the row slides, Usual.chips)
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
                    if (c.mem.mapped.contains('Fonts')) {   // (as a map: each told by its letters as the stage sets them, ThorVG's)
                      final map = dockMap('Fonts'), files = [for (final f in fonts) ?f.path];
                      _drawAll(m, files);
                      final clip = dockModel('fontclip_b32');   // (by how FontCLIP sees each, once it is made; else by its word drawn small)
                      map.need(m, [for (final f in files) (f, f)], (from) async {   // (each by its file: two files may have one name, Arial Unicode's)
                        if (clip != null) return _byFontClip(m, clip, from);
                        await _drawAll(m, files);
                        return [for (final f in from) if (_drawn[f] case final g?) _halved(g) else null];
                      }, also: clip ?? '');
                      final byPath = {for (final f in list) ?f.path: f};
                      return DockMap(map, [for (final MapEntry(key: p, value: f) in byPath.entries) (p, _FontDot(f, c))], cell: 48, aspect: _dot.$1 / _dot.$2, picked: list.where((f) => f.family == c.sel).firstOrNull?.path, press: (p) {
                        if (byPath[p] case final f?) {
                          c.pick(f.family);   // (one press, as on the map: XO's hot swap, the role's font when no text is picked)
                          _toRole(c, f);
                        }
                      });
                    }
                    if (box.maxWidth < 440) {
                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [for (final f in list) _FontRow(f, c, usedBy: usedBy(f))],
                      );
                    }
                    final cols = wsCols(box.maxWidth, 200), w = wsCell(box.maxWidth, cols);
                    final rows = (list.length / cols).ceil();
                    return ListView.builder(   // (a row at a time: only what is shown has its file read, _own)
                      padding: EdgeInsets.zero,
                      itemCount: rows,
                      itemBuilder: (context, i) => Padding(
                        padding: EdgeInsets.only(bottom: i == rows - 1 ? 0 : WsT.gutter),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: WsT.gutter,
                          children: [
                            for (final f in list.skip(i * cols).take(cols))
                              SizedBox(
                                width: w,
                                child: _FontCard(f, c, usedBy: usedBy(f)),
                              ),
                          ],
                        ),
                      ),
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
            // (the picked text is set in it; with no text picked, a new text is)
            action: m.word(int.tryParse(c.ws.selected ?? '') ?? 0, 'kind') != 'text' ? 'Place' : 'Apply',
            done: onText,
            doneLabel: 'In use',
            fresh: m.word(int.tryParse(c.ws.selected ?? '') ?? 0, 'kind') != 'text', // (no text picked: a new text)
            onAction: () => _setFont(c, sel),
          ),
      ],
    );
  }
}

/// The family a shelf row is set in: its file's own bytes, read once the row is shown (FontLoader, Flutter's door for a
/// font that is not in the program). The file's name is often not the family's (Songti.ttc's is Songti SC, a
/// ~/Library/Fonts file's is its PostScript name), and a family's regular is not the face ThorVG will set: the row shows
/// what the stage will (golf_noise.md (117)). The name stays behind it for the moment before they are read.
final _read = <String>{};
String _own(_Font f) {
  final p = f.path;
  if (p == null) return f.family;
  if (_read.add(p)) {
    Zone.root.run(() => (FontLoader(p)..addFont(File(p).readAsBytes().then(ByteData.sublistView))).load().catchError((Object _) {}));   // (a file gone since: the row stays in the name's face)
  }
  return p;
}

TextStyle _face(_Font f, double size, Color c) => TextStyle(
  fontFamily: _own(f),
  fontFamilyFallback: [f.family, '.AppleSystemUIFont'],
  fontSize: size,
  color: T.ink(c),
  height: 1.1,
  decoration: TextDecoration.none,
);

class _FontRow extends StatelessWidget {
  const _FontRow(this.f, this.c, {this.usedBy});
  final _Font f;
  final DockCtx c;
  final String? usedBy;
  @override
  Widget build(BuildContext context) {
    final sel = c.sel == f.family, star = c.starred(f.family);
    return DockHover(
      onTap: () {
        c.pick(f.family);
        _toRole(c, f);
      },
      onDoubleTap: () => _setFont(c, f),   // (two presses set it; carried to the stage it does the same)
      builder: (context, h) => AnimatedContainer(
        duration: Mo.dur,
        curve: Mo.ease,
        height: Shape.z(46),
        margin: EdgeInsets.only(bottom: WsT.gutter),
        padding: EdgeInsets.only(left: WsT.inset, right: Shape.s(4)),
        color: dockFill(sel, h, WsT.card),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(_sample, maxLines: 1, style: _face(f, 17, dockInk(sel, Grey.g95)))),
                  SizedBox(height: Shape.s(5)),
                  Row(
                    children: [
                      Flexible(
                        child: Text('${f.family}  ·  ${DockTags.of('Fonts', f.family, f.path == null ? const <String>{} : (c.ws.inside?.fontTags(f.path!) ?? const <String>{})).take(2).join(' ')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(dockInk(sel, Grey.g76))),
                      ),
                      if (usedBy case final u?) ...[SizedBox(width: Shape.s(6)), DockTag(u, hue: sel ? null : WsT.toneText)],
                    ],
                  ),
                ],
              ),
            ),
            if (star || h || sel) DockStar(on: star, ink: sel ? WsT.onAccent : null, onTap: () => c.star(f.family)) else SizedBox(width: Shape.s(20)),
          ],
        ),
      ),
    );
  }
}

/// On the map: a family's word as the stage sets it (drawn by the inside, [_drawn]: no face of all of them loaded here),
/// [_dot] points; its numbers are it made half as large, a point the four under it.
const _dot = (96, 32);
final _drawn = <String, Uint8List?>{}, _seen = <String, ui.Image>{}, _making = <String>{};
Future<void>? _drawing;
Future<void> _drawAll(Motolii m, List<String> files) => _drawing ??= Zone.root.run<Future<void>>(() async {   // (once, as fontsRead)
  final drawn = await m.typePictures(files, 'Motion', _dot.$1, _dot.$2);
  for (final (i, f) in files.indexed) {
    _drawn[f] = drawn[i];
  }
  dockRead.value++;
});
/// Each font as FontCLIP ([model]) sees its specimen drawn as FontMap draws it for FontCLIP (tfrere/fontmap,
/// pipeline/render/2-generate-svgs.mjs, generateEmbeddingSVG): "Hamburge" over "fonstiv" in a 224 square, 12 round it,
/// each line in its half no wider than 200 nor taller than 85, set at 75 and never larger, its middle at its line's;
/// black on white. 32 told at a time. null: not drawn.
Future<List<Float32List?>> _byFontClip(Motolii m, String model, List<String> files) async {
  final lines = [for (final w in const ['Hamburge', 'fonstiv']) await m.typePictures(files, w, 202, 87, most: 75)];
  final out = <Float32List?>[];
  for (var i = 0; i < files.length; i += 32) {
    final some = [for (var k = i; k < files.length && k < i + 32; k++) k], drawn = [for (final k in some) if (lines[0][k] != null && lines[1][k] != null) k];
    final told = drawn.isEmpty ? null : await m.likeness(model, [for (final k in drawn) _specimen(lines[0][k]!, lines[1][k]!)]);
    final by = {for (final (j, k) in drawn.indexed) k: told?[j]};
    out.addAll([for (final k in some) by[k]]);
  }
  return out;
}
Uint8List _specimen(Uint8List top, Uint8List bottom) {
  final px = Uint8List(224 * 224 * 4)..fillRange(0, 224 * 224 * 4, 255);
  for (final (line, g) in [top, bottom].indexed) {
    final y0 = 12 + 100 * line + 50 - 87 ~/ 2, x0 = 112 - 202 ~/ 2;   // (its middle at its line's)
    for (var y = 0; y < 87; y++) {
      for (var x = 0; x < 202; x++) {
        final at = ((y0 + y) * 224 + x0 + x) * 4;
        px[at] = px[at + 1] = px[at + 2] = 255 - g[y * 202 + x];
      }
    }
  }
  return px;
}

Float32List _halved(Uint8List g) {
  final (w, h) = (_dot.$1 ~/ 2, _dot.$2 ~/ 2);
  final out = Float32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      out[y * w + x] = (g[2 * y * _dot.$1 + 2 * x] + g[2 * y * _dot.$1 + 2 * x + 1] + g[(2 * y + 1) * _dot.$1 + 2 * x] + g[(2 * y + 1) * _dot.$1 + 2 * x + 1]) / 1020;
    }
  }
  return out;
}

class _FontDot extends StatefulWidget {
  const _FontDot(this.f, this.c);
  final _Font f;
  final DockCtx c;
  @override
  State<_FontDot> createState() => _FontDotState();
}

class _FontDotState extends State<_FontDot> {
  void _make(String p, Uint8List g) {
    final rgba = Uint8List(g.length * 4);
    for (var i = 0; i < g.length; i++) {
      rgba.setRange(i * 4, i * 4 + 4, [g[i], g[i], g[i], g[i]]);   // (white, its colours already by how much is covered: Flutter takes them so, seen white boxes otherwise)
    }
    ui.decodeImageFromPixels(rgba, _dot.$1, _dot.$2, ui.PixelFormat.rgba8888, (image) {   // (Flutter's own: the bytes as a picture)
      _seen[p] = image;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.f, c = widget.c, sel = c.sel == f.family;
    if ((f.path, _drawn[f.path]) case (final p?, final g?) when _making.add(p)) _make(p, g);
    return DockHover(
      onTap: () {
        c.pick(f.family);
        _toRole(c, f);
      },
      onDoubleTap: () => _setFont(c, f),
      builder: (context, h) => Container(
        color: dockFill(sel, h, WsT.card),
        child: RawImage(image: _seen[f.path], color: T.ink(dockInk(sel, Grey.g95)), colorBlendMode: BlendMode.modulate, fit: BoxFit.contain),
      ),
    );
  }
}

/// The wide form: a card per family with the sample large enough to judge the face, its facts under it.
class _FontCard extends StatelessWidget {
  const _FontCard(this.f, this.c, {this.usedBy});
  final _Font f;
  final DockCtx c;
  final String? usedBy;
  @override
  Widget build(BuildContext context) {
    final sel = c.sel == f.family, star = c.starred(f.family);
    return DockHover(
      onTap: () {
        c.pick(f.family);
        _toRole(c, f);
      },
      onDoubleTap: () => _setFont(c, f),
      builder: (context, h) => AnimatedContainer(
        duration: Mo.dur,
        curve: Mo.ease,
        height: Shape.z(96),
        padding: EdgeInsets.fromLTRB(WsT.inset, Shape.s(8), Shape.s(4), Shape.s(8)),
        color: dockFill(sel, h, WsT.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                if (star || h || sel) DockStar(on: star, ink: sel ? WsT.onAccent : null, onTap: () => c.star(f.family)) else SizedBox(height: Shape.s(20)),
              ],
            ),
            const Spacer(),
            Text('Motion', maxLines: 1, softWrap: false, overflow: TextOverflow.fade, style: _face(f, 28, dockInk(sel, Grey.g95))),
            const Spacer(),
            Row(
              children: [
                Flexible(
                  child: Text('${f.family}  ·  ${DockTags.of('Fonts', f.family, f.path == null ? const <String>{} : (c.ws.inside?.fontTags(f.path!) ?? const <String>{})).take(2).join(' ')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(dockInk(sel, Grey.g76))),
                ),
                if (usedBy case final u?) ...[SizedBox(width: Shape.s(6)), DockTag(u, hue: sel ? null : WsT.toneText)],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
