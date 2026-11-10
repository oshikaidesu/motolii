// The Colors shelf (pop palettes, a swatch field, saved gradients) and the Create shelf (tiles for every new layer, shape and copier).
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import 'package:motolii/bridge/engine_paths.dart' show motoliiShelves;
import 'package:motolii/widgets/dice_paint.dart';
import 'package:motolii/widgets/text_gestures.dart' show TypedField, wordsPicked;
import 'package:motolii/widgets/media.dart' show MiniSlider, glyph;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/hex_color.dart' show colorOfHex;
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/storage/kept_file.dart' show fileJson, fileKeep;
import 'package:motolii/workspace/dock/dock_widgets.dart';
import 'package:motolii/skin/theme.dart' show ColorTheme;
import 'package:motolii/workspace/dock/dock_color_wheel.dart';
import 'package:motolii/widgets/menu.dart';
import 'package:motolii/workspace/shelf/copies_tiles.dart';
import 'package:motolii/workspace/shelf/material_tiles.dart';
import 'package:motolii/workspace/shelf/create_preview.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart' show EffectTiles;
import 'package:motolii/workspace/shelf/empty_fx.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/state/state.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/bridge/motolii.dart';
part 'dock_make_colors.dart';
part 'dock_make_create.dart';
part 'dock_make_expressions.dart';
part 'dock_make_palettes.dart';

// ---------------------------------------------------------------- colors

// The color shown on the picker, and the property value it last followed.
HSVColor _wheel = const HSVColor.fromAHSV(1, 0, .8, .9);
String _wheelFrom = '';

/// The range of letters selected in the selected text layer, as letter indexes, or null.
/// It is null unless the selection still matches the layer's text and the text is a single line,
/// because splitting a text into letters works on one line only. Indexes count characters, not bytes.
(int, int)? _lettersPicked(DockCtx c, int? t) {
  final m = c.ws.inside, p = wordsPicked.value;
  if (m == null || t == null || p == null || m.word(t, 'kind') != 'text' || m.word(t, 'text') != p.text || p.text.contains('\n')) return null;
  return (p.text.substring(0, p.start).runes.length, p.text.substring(0, p.end).runes.length);
}

/// Colors some letters of a text layer and leaves the rest alone, as Figma, Canva, PowerPoint, Keynote
/// and After Effects' Character panel do for selected characters.
/// The engine does it by splitting the text into letters and giving each one a color in turn with copy_fill
/// (each copy's wash is the color itself, see engine/materials/flat.mat).
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
  m.later('together', number: 1); // One undo step.
  if (m.word(t, 'split') != 'letters') m.later('say', layer: t, name: 'split', word: 'letters');
  m.later('say', layer: t, name: 'copy_fill', word: each.join(' '));
  m.later('say', layer: t, name: 'copy_fill_way', word: 'cycle');
  c.ws.after(m.later('together'), (done, why) => c.set(() => done ? c.mem.trouble.remove('fill') : c.mem.trouble['fill'] = why));
}

/// Sets the fill of the selected layer to [word] (six hex digits or a material name). On failure the shelf footer shows why.
void _fill(DockCtx c, String word) {
  final m = c.ws.inside!, t = _colored(c);
  if ((c.ws.aim == null || c.ws.aim == 'fill') && RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(word)) {
    if (_lettersPicked(c, t) case final at?) return _fillLetters(c, t!, at, word.toLowerCase());
  }
  // A color given to a layer also becomes the color of the next layer drawn: the fill becomes the ink, the stroke the edge.
  // CLIP STUDIO PAINT likewise keeps one drawing color, the last one chosen, for every tool.
  void keep(String name) {
    if (name == 'fill') c.ws.ink = word;
    if (name == 'stroke') c.ws.edge = word;
  }

  if (t == null && (c.ws.aim == 'fill' || c.ws.aim == 'stroke')) {
    // The target is the tool strip's ink or edge and no layer is selected: set the color of the next layer drawn (_Swatches in stage.dart).
    c.set(() {
      c.mem.trouble.remove('fill');
      keep(c.ws.aim!);
    });
    c.ws.reread();
    return;
  }
  if (c.ws.aim case final aim?) {
    // The target is a card's color link: set that property of the selected layer, or of the stage.
    // A stroke colored while it has no width gets width 6, as Alight Motion does when it adds a border
    // and as the drawing tools do (wsInked). All of it is one undo step.
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
    ); // Does not wait for the result.
    return;
  }
  if (t == null) {
    // No layer is selected: set the drawing tools' ink, which fills the next layer drawn.
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
  ); // Does not wait for the result.
}

/// The palette whose details the shelf footer shows: the one under the pointer, else the one pressed last.
final _named = ValueNotifier<String?>(null);
String? _pressed;
bool _wheelHeld = false; // True while the user drags the wheel; it then follows the pointer.

/// The Colors shelf. It stays small however many colors are saved, and one press applies a color. From the top it shows:
/// - the target in one line;
/// - the current color with its square, a full-width hue bar and its hex code, as in Figma's picker;
/// - every palette as a small card of stripes, side by side in rows, where a press on a stripe takes that color
///   (as the palette cards of Coolors, Adobe Color and Canva);
/// - the gradients as small tiles.
class ColorsShelf extends StatelessWidget {
  const ColorsShelf(this.c, {super.key});
  final DockCtx c;

  /// The layer a color goes to and the name of the property. The layer is null for the next layer drawn.
  (int?, String) _target() {
    final t = _colored(c), aim = c.ws.aim ?? 'fill';
    return (t ?? (aim == 'fill' || aim == 'stroke' ? null : 0), aim);
  }

  @override
  Widget build(BuildContext context) {
    WsScope.of(context, {WsAspect.picked, WsAspect.document}); // Rebuilds when the target or the selection changes.
    _readMine();
    final m = c.ws.inside!, usedCount = <Color, int>{};
    for (final col in usedColors(c.ws).values) {
      usedCount[col] = (usedCount[col] ?? 0) + 1; // Layers using this color: roughly how much of the picture it covers.
    }
    final used = usedCount.keys.toList();
    final (t, name) = _target();
    final word = t == null ? (name == 'stroke' ? c.ws.edge : c.ws.ink) : m.word(t, name);
    final stops = _stopsIn(word), gradient = stops.length > 1, none = name == 'stroke' ? word.isEmpty : word == 'none';
    if (_stop >= stops.length) _stop = 0;
    // The picker shows the color of the target, or of the selected gradient stop, as CLIP STUDIO PAINT's wheel shows the main or sub color.
    if (word != _wheelFrom) {
      _wheelFrom = word;
      if (_wheelHeld) {
        // While the user drags the wheel it keeps the dragged hue, which a gray written as hex would lose.
      } else if (gradient) {
        _wheel = HSVColor.fromColor(stops[_stop].$1.withValues(alpha: 1));
      } else if (colorOfHex(word.split(' ').first.split('@').first) case final col?) {
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
      // The square or the hue moved: update the color, or the selected stop's color.
      _wheel = v;
      if (!gradient) return _fill(c, hexOf(v.toColor()));
      final next = [...stops];
      next[_stop] = (v.toColor().withValues(alpha: stops[_stop].$1.a), stops[_stop].$2);
      _fill(c, _wordOfStops(next));
    }

    // The paint type, as in Alight Motion's tabs and Figma. Switching a color to a gradient fades it to clear, as Figma does.
    // Switching a gradient to a color keeps the selected stop's color.
    Widget kind(String label, bool on, VoidCallback go) => Chip(key: ValueKey('colour-kind-$label'), label: label, on: on, onTap: on ? null : go);
    // Two blocks. The top stays in place: the target, the paint type and the wheel. Only the saved colors below scroll,
    // so + and the dice stay within reach. Saved colors sit under the picker, as in Procreate's Color Panel and in Figma.
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
                  // When letters are selected in the text, only those are colored.
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
              ), // Samples a color from anywhere on the screen with the Mac's eyedropper.
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
              // How colors blend between stops, as in CSS Color 4's color-interpolation-method and Blender's Constant interpolation. Saved with the gradient.
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
            // As in CLIP STUDIO PAINT's color wheel, everything done between pressing and releasing is one undo step.
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
          // Fourteen sample colors as in Alight Motion, white and black included, one press each.
          // White needs a swatch because it is hard to hit in the square's corner.
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
                // Shrinks in a narrow shelf so it never pushes the row out.
                child: LayoutBuilder(
                  builder: (context, b) => MiniSlider(
                    // The box size can be any value. It is saved once the user stops dragging, not on every frame.
                    key: const ValueKey('colour-size'),
                    values: [_tile],
                    min: _tileLeast,
                    max: _tileMost,
                    width: math.min(Shape.z(64), b.maxWidth),
                    onChanged: (v) {
                      c.set(() => _tile = v.first);
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
              ), // Saves the current color, or the whole gradient, as the user's own, like CLIP STUDIO PAINT's Add Color.
              SizedBox(width: Shape.s(4)),
              Chip(
                key: const ValueKey('colour-keep'),
                label: 'Keep',
                onTap: used.isEmpty
                    ? null
                    : () => c.set(() {
                        // Saves the project's colors as a palette of the user's own.
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
                        // Takes the palette from the photo selected in Media.
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
              _colourDice(() => c.set(() => _dice++)),
            ],
          ),
        ],
      ),
    );
    final list = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(WsT.inset, Shape.s(6), WsT.inset, WsT.inset),
      child: _Bento([
        // The newest additions come first: the user's own colors, then the user's own gradients.
        // No other app does this: Procreate fills the next empty slot and Canva sorts by hue.
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
          // Details of the palette under the pointer or pressed last: its photo, name and owner.
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
                // Removes the user's palette from the shelf and updates its saved file.
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

/// The layer the shelf colors: the selected one. A sound has nothing to color, so it counts as no selection (the next layer drawn).
int? _colored(DockCtx c) => switch (int.tryParse(c.ws.selected ?? '')) {
  final t? when wsSound(c.ws.inside!, t) => null,
  final t => t,
};

/// The current value of the target: the selected layer's property (its fill, unless a link or the tool strip chose another),
/// else the stage's, else the ink or edge of the next layer drawn.
String _paintNow(DockCtx c) {
  final t = _colored(c), aim = c.ws.aim ?? 'fill', m = c.ws.inside!;
  if (t != null) return m.word(t, aim);
  if (aim == 'fill' || aim == 'stroke') return aim == 'stroke' ? c.ws.edge : c.ws.ink;
  return m.word(0, aim);
}

/// Applies a color from a swatch or the eyedropper to the target, or to the selected stop while the target is a gradient.
/// Figma and Canva swatches also color the stop being edited.
void _take(DockCtx c, Color col) {
  final stops = _stopsIn(_paintNow(c));
  if (stops.length < 2) return _fill(c, _hex(col).substring(1).toLowerCase());
  final next = [...stops];
  next[_stop.clamp(0, stops.length - 1)] = (col, stops[_stop.clamp(0, stops.length - 1)].$2);
  _wheelFrom = '';
  _fill(c, _wordOfStops(next));
}

/// The Mac's eyedropper (NSColorSampler, used in MainFlutterWindow.swift). The sampled color is applied to the target at once,
/// as Keynote's eyedropper does.
Future<void> _sample(DockCtx c) async {
  final hex = await const MethodChannel('motolii/sampler').invokeMethod<String>('sample');
  if (hex == null || int.tryParse(hex, radix: 16) == null) return;
  c.set(() => _wheel = HSVColor.fromColor(Color(0xFF000000 | int.parse(hex, radix: 16))));
  _take(c, Color(0xFF000000 | int.parse(hex, radix: 16)));
}
