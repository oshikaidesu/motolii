// The making shelves: Colors (pop palettes, a swatch field, saved gradients) and Create (tiles for every new layer, shape and copier).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import '../../bridge/motolii.dart' show motoliiShelves;
import '../../inspector/inspector_parts.dart' show Pop;
import '../../widgets/text_gestures.dart' show TextGestures, wordsPicked;
import '../../widgets/media.dart' show MiniSlider;
import '../../skin/tokens.dart';
import 'dock_glyphs.dart';
import 'dock_widgets.dart';
import '../../skin/theme.dart' show ColorTheme;
import 'dock_color_wheel.dart';
import '../commands/context_menu.dart';
import '../shelf/copies_tiles.dart';
import '../shelf/material_tiles.dart';
import '../shelf/create_preview.dart';
import '../shelf/effect_tiles.dart' show EffectTiles;
import '../shelf/empty_fx.dart';
import '../shelf/shelf_add.dart';
import '../shelf/shelf_tile.dart';
import '../state/state.dart';
part 'dock_make_colors.dart';
part 'dock_make_create.dart';
part 'dock_make_expressions.dart';
part 'dock_make_palettes.dart';

// ---------------------------------------------------------------- colors

// The colour on the picker, and the ink, edge or value it last followed.
HSVColor _wheel = const HSVColor.fromAHSV(1, 0, .8, .9);
String _wheelFrom = '';

/// Joined: the picked thing's fill told to the document (a colour as six digits, or a material's name). Not done: the foot says why.
/// The letters picked in the picked text's words, when they are still its words and on one line (a text is split into
/// its letters one line only: golf_noise.md ⑭); in letters, as the inside counts them (one however many bytes).
(int, int)? _lettersPicked(DockCtx c, int? t) {
  final m = c.ws.inside, p = wordsPicked.value;
  if (m == null || t == null || p == null || m.word(t, 'kind') != 'text' || m.word(t, 'text') != p.text || p.text.contains('\n')) return null;
  return (p.text.substring(0, p.start).runes.length, p.text.substring(0, p.end).runes.length);
}

/// Some letters of a text coloured and the rest left as they are: Figma's and Canva's colour on the letters picked in a
/// text, PowerPoint's and Keynote's on selected text, After Effects' Character panel on the selected characters (P13:
/// one word of a title). The inside colours a text split into its letters one by one: split letters, copy_fill one
/// colour each in turn (its copy's wash is the colour itself: flat.mat).
void _fillLetters(DockCtx c, int t, (int, int) at, String word) {
  final m = c.ws.inside!, n = m.word(t, 'text').runes.length;
  final had = m.word(t, 'copy_fill').split(' ').where((w) => w.isNotEmpty).toList();
  final base = m.word(t, 'fill').split(' ').first.split('@').first;
  final each = [
    for (var i = 0; i < n; i++)
      i >= at.$1 && i < at.$2
          ? word
          : had.length == n
          ? had[i]
          : (base.isEmpty || base == 'none' ? 'ffffff' : base),
  ];
  m.later('together', number: 1); // (one step)
  if (m.word(t, 'split') != 'letters') m.later('say', layer: t, name: 'split', word: 'letters');
  m.later('say', layer: t, name: 'copy_fill', word: each.join(' '));
  m.later('say', layer: t, name: 'copy_fill_way', word: 'cycle');
  c.ws.after(m.later('together'), (done, why) => c.set(() => done ? c.mem.trouble.remove('fill') : c.mem.trouble['fill'] = why));
}

void _fill(DockCtx c, String word) {
  final m = c.ws.inside!, t = _colored(c);
  if ((c.ws.aim == null || c.ws.aim == 'fill') && RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(word)) {
    if (_lettersPicked(c, t) case final at?) return _fillLetters(c, t!, at, word.toLowerCase());
  }
  // (a colour given to a thing is also what the next thing drawn comes in: its fill the ink, its outline the edge, as
  //  CLIP STUDIO PAINT has one drawing colour that every tool draws in, its text too, the last one chosen)
  void keep(String name) {
    if (name == 'fill') c.ws.ink = word;
    if (name == 'stroke') c.ws.edge = word;
  }

  if (t == null && (c.ws.aim == 'fill' || c.ws.aim == 'stroke')) {
    // (the tool strip's ink or edge aimed it, nothing picked: what a thing drawn next comes in, stage.dart _Swatches)
    c.set(() {
      c.mem.trouble.remove('fill');
      keep(c.ws.aim!);
    });
    c.ws.reread();
    return;
  }
  if (c.ws.aim case final aim?) {
    // (a card's colour link aimed it: said to that value, of the picked thing or of the stage)
    // (an outline coloured while it has no width comes 6 wide, as Alight Motion's border is added (AbsentMotion
    //  Styling.kt withBorderAdded, BorderSize 6) and as the drawing tools give their edge (wsInked): one step; golf (89))
    final edged = aim == 'stroke' && t != null && word != 'none' && (m.value(t, 'stroke_width', 0) ?? 0) <= 0;
    if (edged) m.later('together', number: 1);
    final said = m.later('say', layer: t ?? 0, name: aim, word: word);
    if (edged) m.later('set', layer: t, name: 'stroke_width', number: 6);
    c.ws.after(
      edged ? m.later('together') : said,
      (done, why) => c.set(() {
        if (done && t != null) keep(aim);
        done ? c.mem.trouble.remove('fill') : c.mem.trouble['fill'] = why;
      }),
    ); // (without waiting)
    return;
  }
  if (t == null) {
    // (nothing picked: the drawing tools' ink, what a thing drawn next is filled with)
    c.set(() => (c.ws.ink = word, c.mem.trouble.remove('fill')));
    c.ws.reread();
    return;
  }
  c.ws.after(
    m.later('say', layer: t, name: 'fill', word: word),
    (done, why) => c.set(() {
      if (done) keep('fill');
      done ? c.mem.trouble.remove('fill') : c.mem.trouble['fill'] = why;
    }),
  ); // (without waiting)
}

/// The colours of the things, each by the thing's name: what the document's things are filled with (a ramp by its first).
Map<String, Color> usedColors(Ws ws) {
  final m = ws.inside;
  if (m == null) return const {};
  return {
    for (final l in ws.layers)
      if (m.word(int.parse(l.id), 'fill').split(' ').first.split('@').first case final f when f.length == 6)
        if (int.tryParse(f, radix: 16) case final v?) l.name: Color(0xFF000000 | v),
  };
}

/// The palette whose details the shelf's foot tells: the one the hand is on, else the one last pressed.
final _named = ValueNotifier<String?>(null);
String? _pressed;
bool _wheelHeld = false; // (a hand on the wheel: it follows the hand)

/// The Colors shelf, laid out to stay small however much is kept in it, and to colour in one press: what is coloured,
/// in one line; the colour now, its square and hue full width (flutter_colorpicker's own, as Figma's picker) and its
/// code; then every palette as one small card of its colours in stripes, side by side in rows (Coolors', Adobe
/// Color's and Canva's palette cards: a press on a stripe takes that colour), and the gradients as small tiles. A
/// press colours at once, as in the best-selling editors.
class ColorsShelf extends StatelessWidget {
  const ColorsShelf(this.c, {super.key});
  final DockCtx c;

  /// The thing a colour goes to now and its value's name (null: the next thing drawn).
  (int?, String) _target() {
    final t = _colored(c), aim = c.ws.aim ?? 'fill';
    return (t ?? (aim == 'fill' || aim == 'stroke' ? null : 0), aim);
  }

  @override
  Widget build(BuildContext context) {
    WsScope.of(context, {
      WsAspect.picked,
      WsAspect.document,
    }); // (what it colours is said at its top: built again when a link or the tool strip aims it, or a thing is picked)
    _readMine();
    final m = c.ws.inside!, usedCount = <Color, int>{};
    for (final col in usedColors(c.ws).values) {
      usedCount[col] = (usedCount[col] ?? 0) + 1; // (how many things are of it: how much of the picture, roughly)
    }
    final used = usedCount.keys.toList();
    final (t, name) = _target();
    final word = t == null ? (name == 'stroke' ? c.ws.edge : c.ws.ink) : m.word(t, name);
    final stops = _stopsIn(word), gradient = stops.length > 1, none = name == 'stroke' ? word.isEmpty : word == 'none';
    if (_stop >= stops.length) _stop = 0;
    // (the picker shows the colour of what is coloured now, or of the stop picked, as CLIP STUDIO PAINT's wheel shows
    //  the main or sub colour)
    if (word != _wheelFrom) {
      _wheelFrom = word;
      if (_wheelHeld) {
        // (a hand on the wheel: it keeps the hue the hand gave, which a grey written as hex would lose)
      } else if (gradient) {
        _wheel = HSVColor.fromColor(stops[_stop].$1.withValues(alpha: 1));
      } else if (_colorOf(word.split(' ').first.split('@').first) case final col?) {
        _wheel = HSVColor.fromColor(col);
      }
    }
    String hexOf(Color col) => _hex(col).substring(1).toLowerCase();
    final whom = t == null
        ? 'the next thing drawn'
        : t == 0
        ? 'the stage'
        : (c.ws.layer?.name ?? 'the picked thing');
    final q = c.query.toLowerCase();
    final pals = [
      for (final p in _pals)
        if (q.isEmpty || p.name.toLowerCase().contains(q)) p,
    ];
    final grads = [
      for (final (i, g) in _grads.indexed)
        if (q.isEmpty || g.name.toLowerCase().contains(q)) (i, g),
    ];
    final photo = _pickedPhoto(c);
    void to(HSVColor v) {
      // (the square or the hue moved: the colour, or the picked stop's)
      _wheel = v;
      if (!gradient) return _fill(c, hexOf(v.toColor()));
      final next = [...stops];
      next[_stop] = (v.toColor().withValues(alpha: stops[_stop].$1.a), stops[_stop].$2);
      _fill(c, _wordOfStops(next));
    }

    // (what it is painted with: Alight Motion's four tabs, Figma's paint type; a press each. A colour to a gradient
    //  fades to clear, as Figma's first gradient does; a gradient to a colour keeps the stop picked)
    Widget kind(String label, bool on, VoidCallback go) => Chip(key: ValueKey('colour-kind-$label'), label: label, on: on, onTap: on ? null : go);
    // (two blocks, the user's: the top stays where it is, what is coloured, how, the wheel; only the colours below
    //  scroll, so + and the dice, at the head of them, are always at hand. The picker above, the kept colours under it:
    //  Procreate's Color Panel, its palette at the bottom of the Disc and Classic tabs; Figma's picker, the document's
    //  colours below the picker and its hex)
    final top = Padding(
      padding: EdgeInsets.fromLTRB(WsT.inset, Shape.s(6), WsT.inset, Shape.s(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder(
                  // (the letters picked in the text's words, when they are: those alone are coloured)
                  valueListenable: wordsPicked,
                  builder: (context, _, _) {
                    final at = name == 'fill' ? _lettersPicked(c, t) : null;
                    final who = at == null ? whom : '“${String.fromCharCodes(m.word(t!, 'text').runes.toList().sublist(at.$1, at.$2))}” in $whom';
                    return Text(
                      '${name == 'fill'
                          ? 'Fill'
                          : name == 'stroke'
                          ? 'Stroke'
                          : name[0].toUpperCase() + name.substring(1)} of $who',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: T.name(Grey.g91).copyWith(fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
              SizedBox(width: Shape.s(6)),
              Chip(
                key: const ValueKey('colour-sample'),
                label: 'Sample',
                onTap: () => _sample(c),
              ), // (a colour from anywhere on the screen: the Mac's own eyedropper)
            ],
          ),
          if (c.mem.trouble['fill'] case final why?)
            Padding(
              padding: EdgeInsets.only(top: Shape.s(4)),
              child: Text(why, style: T.label(ColorTheme.of('Alert', const Color(0xFFE5484D)))),
            ),
          SizedBox(height: Shape.s(6)),
          Row(
            children: [
              kind('Solid', !gradient && !none, () => _fill(c, hexOf(gradient ? stops[_stop].$1 : _wheel.toColor()))),
              if (name == 'fill') ...[
                SizedBox(width: Shape.s(4)),
                kind('Gradient', gradient, () => _fill(c, _wordOfStops([(_wheel.toColor(), 0), (_wheel.toColor().withValues(alpha: 0), 1)]))),
              ],
              SizedBox(width: Shape.s(4)),
              kind('None', none, () => _fill(c, name == 'stroke' ? '' : 'none')),
              const Spacer(),
              if (gradient && stops.length > 2)
                Chip(key: const ValueKey('colour-stop-remove'), label: 'Remove stop', onTap: () => _fill(c, _wordOfStops([...stops]..removeAt(_stop)))),
            ],
          ),
          SizedBox(height: Shape.s(8)),
          if (gradient) ...[
            _Stops(
              stops,
              (next) => _fill(c, _wordOfStops(next)),
              (i) => c.set(() {
                _stop = i;
                _wheelFrom = ''; // (the picker shows the stop picked)
              }),
              onDrag: (down) => down ? m.later('together', number: 1) : c.ws.after(m.later('together')),
            ),
            SizedBox(height: Shape.s(6)),
            Wrap(
              // (how its colours are mixed between: CSS Color 4's color-interpolation-method, Blender's Constant; kept with it)
              spacing: Shape.s(4),
              children: [
                for (final MapEntry(key: b, value: label) in _blends.entries)
                  Chip(
                    key: ValueKey('colour-blend-$b'),
                    label: label,
                    on: _blendNow(c) == b,
                    onTap: () {
                      final t = _colored(c);
                      t != null && name == 'fill' ? c.ws.after(m.later('say', layer: t, name: 'gradient_blend', word: b)) : c.set(() => c.ws.inkBlend = b);
                    },
                  ),
              ],
            ),
            SizedBox(height: Shape.s(8)),
          ],
          Center(
            // (CLIP STUDIO PAINT's colour wheel: a hand on it, what it does till it lets go is one step)
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Shape.z(170)),
              child: AspectRatio(
                aspectRatio: 1,
                child: WsColorWheel(
                  key: const ValueKey('colour-square'),
                  color: _wheel,
                  onChanged: to,
                  onStart: () {
                    _wheelHeld = true;
                    m.later('together', number: 1);
                  },
                  onEnd: () {
                    _wheelHeld = false;
                    c.ws.after(m.later('together'));
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: Shape.s(6)),
          Row(
            children: [
              Container(
                width: Shape.z(22),
                height: Shape.z(22),
                decoration: BoxDecoration(
                  color: _wheel.toColor(),
                  borderRadius: BorderRadius.all(Shape.r(4)),
                  border: Border.all(color: Grey.g26),
                ),
              ),
              SizedBox(width: Shape.s(8)),
              Expanded(child: _HexField(_hex(_wheel.toColor()), (col) => to(HSVColor.fromColor(col)))),
            ],
          ),
          SizedBox(height: Shape.s(6)),
          // (Alight Motion's fourteen samples under its colour, white and black among them, one press each: AbsentMotion's
          //  EffectSettings.kt 195 has them; golf_noise.md (80): white took the square's corner, and a miss on the ring)
          for (final row in const [
            [0xFF4444, 0xF4B446, 0xFAE965, 0x1ED91E, 0x17E1E1, 0x3D4CF5, 0xDD44DD],
            [0xFFFFFF, 0xBEBEBE, 0x888888, 0x444444, 0x000000, 0x5EB7D9, 0x98C99C],
          ])
            Padding(
              padding: EdgeInsets.only(bottom: Shape.s(3)),
              child: Row(
                children: [
                  for (final (i, rgb) in row.indexed) ...[
                    if (i > 0) SizedBox(width: Shape.s(3)),
                    Expanded(
                      child: DockHover(
                        key: ValueKey('colour-sample-${rgb.toRadixString(16).padLeft(6, '0')}'),
                        onTap: () => _take(c, Color(0xFF000000 | rgb)),
                        builder: (context, h) => Container(
                          height: Shape.z(18),
                          decoration: BoxDecoration(
                            color: Color(0xFF000000 | rgb),
                            borderRadius: BorderRadius.all(Shape.r(3)),
                            border: Border.all(color: h ? Grey.g95 : Grey.g26),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          SizedBox(height: Shape.s(10)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Colours',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.label(Grey.g76).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text('size', style: T.label(Grey.g76)),
              SizedBox(width: Shape.s(4)),
              Flexible(
                // (shorter in a narrow shelf, never pushing the row out)
                child: LayoutBuilder(
                  builder: (context, b) => MiniSlider(
                    // (the boxes' size, any the maker likes; kept once the hand rests, not written every frame)
                    key: const ValueKey('colour-size'),
                    value: _tile,
                    min: _tileLeast,
                    max: _tileMost,
                    width: math.min(Shape.z(64), b.maxWidth),
                    onChanged: (v) {
                      c.set(() => _tile = v);
                      _tileKept?.cancel();
                      _tileKept = Timer(const Duration(milliseconds: 400), _keepMine);
                    },
                  ),
                ),
              ),
              SizedBox(width: Shape.s(6)),
              Chip(
                key: const ValueKey('colour-add'),
                label: '+',
                onTap: () => c.set(() => _keepNow(c)),
              ), // (the colour now kept as one's own, or the gradient whole: CLIP STUDIO PAINT's Add Color)
              SizedBox(width: Shape.s(4)),
              Chip(
                key: const ValueKey('colour-keep'),
                label: 'Keep',
                onTap: used.isEmpty
                    ? null
                    : () => c.set(() {
                        // (the document's colours kept as a palette of one's own)
                        _minePals.insert(0, _Pal('mine${_minePals.length}', 'Used ${_minePals.length + 1}', used, saved: true));
                        _keepMine();
                      }),
              ),
              SizedBox(width: Shape.s(4)),
              Chip(
                key: const ValueKey('colour-photo'),
                label: 'Photo',
                onTap: photo == null
                    ? null
                    : () async {
                        // (taken from the photo picked in Media)
                        final p = await _paletteFrom(photo);
                        if (p != null) {
                          c.set(() {
                            _minePals.insert(0, p);
                            _keepMine();
                          });
                        }
                      },
              ),
              SizedBox(width: Shape.s(6)),
              _Dice(() => c.set(() => _dice++)),
            ],
          ),
        ],
      ),
    );
    final list = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(WsT.inset, Shape.s(6), WsT.inset, WsT.inset),
      child: _Bento([
        // (what was added last at the top: one's own colours, one's own gradients, newest first; the user, "追加はいつも上から"; no app found doing so: Procreate fills the next empty slot, Canva sorts by hue)
        if (q.isEmpty)
          for (final (i, col) in _mineColors.indexed) _Box('mine', i, 1, colour: col),
        for (final (i, g) in grads)
          if (g.saved) _Box('grads', i, 1, grad: g),
        if (q.isEmpty)
          for (final (i, col) in used.indexed) _Box('used', i, usedCount[col]! * used.length / usedCount.values.fold(0, (a, b) => a + b), colour: col),
        for (final p in pals)
          for (final (i, col) in p.colors.indexed) _Box(p.id, i, (p.shares?[i] ?? 1 / p.colors.length) * p.colors.length, colour: col),
        for (final (i, g) in grads)
          if (!g.saved) _Box('grads', i, 1, grad: g),
      ], c),
    );
    return Column(
      children: [
        top,
        Container(height: 1, color: WsT.line),
        Expanded(child: list),
        ValueListenableBuilder<String?>(
          // (the details of the palette under the hand or last pressed: its photo, its name, whose it is)
          valueListenable: _named,
          builder: (context, id, _) {
            final p = _pals.where((p) => p.id == id).firstOrNull;
            if (p == null) return const SizedBox.shrink();
            final photo = p.reference != null && File(p.reference!).existsSync() ? p.reference : null;
            final whose = photo != null
                ? 'From ${photo.split('/').last.replaceFirst(RegExp(r'^[0-9]+_'), '')}'
                : p.saved
                ? 'Yours'
                : 'Starter';
            return DockFooter(
              key: const ValueKey('colour-details'),
              preview: photo != null
                  ? Image.file(File(photo), fit: BoxFit.cover, cacheWidth: 96)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [for (final col in p.colors) Expanded(child: ColoredBox(color: col))],
                    ),
              title: p.name,
              meta: '$whose · ${p.colors.length} colours',
              action: 'Remove',
              done: !p.saved,
              doneLabel: 'Starter',
              onAction: () => c.set(() {
                // (one's own taken off the shelf, its file kept in step)
                _minePals.remove(p);
                _named.value = _pressed = null;
                _keepMine();
              }),
            );
          },
        ),
      ],
    );
  }
}

/// The thing the shelf colours: the one picked (a sound has nothing to colour: the next thing drawn, then, as with none).
int? _colored(DockCtx c) => switch (int.tryParse(c.ws.selected ?? '')) {
  final t? when wsSound(c.ws.inside!, t) => null,
  final t => t,
};

/// What is coloured now, as the document or the inks say it: the picked thing's value aimed at (its fill, unless a
/// link or the tool strip aimed another), else the stage's, else the ink or edge of the next thing drawn.
String _paintNow(DockCtx c) {
  final t = _colored(c), aim = c.ws.aim ?? 'fill', m = c.ws.inside!;
  if (t != null) return m.word(t, aim);
  if (aim == 'fill' || aim == 'stroke') return aim == 'stroke' ? c.ws.edge : c.ws.ink;
  return m.word(0, aim);
}

/// A colour taken from a swatch or the eyedropper: given to what is coloured; while that is a gradient, to the stop
/// picked (Figma's and Canva's swatches colour the stop being edited).
void _take(DockCtx c, Color col) {
  final stops = _stopsIn(_paintNow(c));
  if (stops.length < 2) return _fill(c, _hex(col).substring(1).toLowerCase());
  final next = [...stops];
  next[_stop.clamp(0, stops.length - 1)] = (col, stops[_stop.clamp(0, stops.length - 1)].$2);
  _wheelFrom = '';
  _fill(c, _wordOfStops(next));
}

/// The Mac's eyedropper (NSColorSampler, MainFlutterWindow.swift): the colour taken is given at once to what is
/// coloured, as Keynote's eyedropper gives it.
Future<void> _sample(DockCtx c) async {
  final hex = await const MethodChannel('motolii/sampler').invokeMethod<String>('sample');
  if (hex == null || int.tryParse(hex, radix: 16) == null) return;
  c.set(() => _wheel = HSVColor.fromColor(Color(0xFF000000 | int.parse(hex, radix: 16))));
  _take(c, Color(0xFF000000 | int.parse(hex, radix: 16)));
}
