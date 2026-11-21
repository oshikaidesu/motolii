// What the Colors shelf asks the engine to do: give a layer, some letters or the next layer drawn a color or a gradient.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/text/text_ranges.dart';
import 'package:motolii/widgets/text_gestures.dart' show wordsPicked;
import 'package:motolii/workspace/dock/colors/color_palette.dart';
import 'package:motolii/workspace/dock/colors/colors_controller.dart';
import 'package:motolii/workspace/dock/colors/gradient_stops.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/layers/layer_edits.dart';

class ColorCommands {
  ColorCommands(this.c, this.colors);

  final ShelfContext c;
  final ColorsController colors;

  /// The selected letters in the text layer, or null.
  ({int start, int count})? lettersPicked(int? t) {
    if (t == null || wordOf(c.ws, t, 'kind') != 'text') return null;
    return pickedLetters(wordOf(c.ws, t, 'text'), wordsPicked.value);
  }

  /// Colors selected letters via text_styles CSS color.
  void _fillLetters(int t, ({int start, int count}) at, String word) {
    final styles = styleRange(
      wordOf(c.ws, t, 'text_styles'),
      at.start,
      at.count,
      'color',
      '#$word',
    );
    c.ws.after(
      sayWord(c.ws, t, 'text_styles', styles),
      (done, why) => c.set(
        () => done ? c.mem.trouble.remove('fill') : c.mem.trouble['fill'] = why,
      ),
    );
  }

  /// Sets the fill to [word]. During a wheel drag, each colour is a live step.
  void fill(String word) => _dragged
      ? c.ws.live.move((_) {
          _fillNow(word);
          return [colored ?? 0];
        })
      : _fillNow(word);

  void _fillNow(String word) {
    final t = colored;
    if ((c.ws.aim == null || c.ws.aim == 'fill') &&
        RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(word)) {
      if (lettersPicked(t) case final at?) {
        return _fillLetters(t!, at, word.toLowerCase());
      }
    }
    // A color given to a layer also becomes the ink/edge of the next layer drawn.
    void keep(String name) {
      if (name == 'fill') c.ws.ink = word;
      if (name == 'stroke') c.ws.edge = word;
    }

    if (t == null && (c.ws.aim == 'fill' || c.ws.aim == 'stroke')) {
      // No layer selected: set the drawing tools' ink/edge.
      c.set(() {
        c.mem.trouble.remove('fill');
        keep(c.ws.aim!);
      });
      c.ws.reread();
      return;
    }
    if (c.ws.aim case final aim?) {
      // A stroke colored while width is 0 gets width 6 (one undo step).
      final isStroke = aim == 'stroke' || aim.endsWith(':stroke');
      final widthProp = aim == 'stroke'
          ? 'stroke_width'
          : '${aim.substring(0, aim.length - 6)}stroke_width';
      final edged =
          isStroke &&
          t != null &&
          word.isNotEmpty &&
          word != 'none' &&
          (valueOf(c.ws, t, widthProp, 0) ?? 0) <= 0;
      if (edged) groupBegin(c.ws);
      final said = sayWord(c.ws, t ?? 0, aim, word);
      if (edged) setNumber(c.ws, t, widthProp, 6);
      c.ws.after(
        edged ? groupEnd(c.ws) : said,
        (done, why) => c.set(() {
          if (done && t != null) keep(aim);
          done ? c.mem.trouble.remove('fill') : c.mem.trouble['fill'] = why;
        }),
      ); // Does not wait for the result.
      return;
    }
    if (t == null) {
      c.set(() => (c.ws.ink = word, c.mem.trouble.remove('fill')));
      c.ws.reread();
      return;
    }
    c.ws.after(
      sayWord(c.ws, t, 'fill', word),
      (done, why) => c.set(() {
        if (done) keep('fill');
        done ? c.mem.trouble.remove('fill') : c.mem.trouble['fill'] = why;
      }),
    ); // Does not wait for the result.
  }

  /// The selected layer, or null for a sound (nothing to color).
  int? get colored => switch (c.ws.selected) {
    final t? when soundLayer(c.ws, t) => null,
    final t => t,
  };

  /// Current value of the target property.
  String get paintNow {
    final t = colored, aim = c.ws.aim ?? 'fill';
    if (t != null) return wordOf(c.ws, t, aim);
    if (aim == 'fill' || aim == 'stroke') {
      return aim == 'stroke' ? c.ws.edge : c.ws.ink;
    }
    return wordOf(c.ws, 0, aim);
  }

  /// Applies a color to the target, or to the selected gradient stop.
  void takeColor(Color col) {
    final stops = stopsIn(paintNow);
    if (stops.length < 2) {
      return fill(hexOfColor(col).substring(1).toLowerCase());
    }
    final next = [...stops];
    next[colors.stop.clamp(0, stops.length - 1)] = (
      col,
      stops[colors.stop.clamp(0, stops.length - 1)].$2,
    );
    colors.wheelFrom = '';
    fill(wordOfStops(next));
  }

  /// The Mac's eyedropper (NSColorSampler).
  Future<void> sample() async {
    final hex = await const MethodChannel('motolii/sampler')
        .invokeMethod<String>('sample');
    if (hex == null || int.tryParse(hex, radix: 16) == null) return;
    c.set(
      () => colors.wheelColor = HSVColor.fromColor(
        Color(0xFF000000 | int.parse(hex, radix: 16)),
      ),
    );
    takeColor(Color(0xFF000000 | int.parse(hex, radix: 16)));
  }

  static bool _usesGradientBlend(String name) =>
      name == 'fill' || name == 'stroke' || name.endsWith(':stroke');

  /// Puts a gradient on the target. One undo step.
  void putGradient(List<Color> cs, String blend, [List<double>? at]) {
    final t = colored;
    final word = at != null && at.length == cs.length
        ? wordOfStops([for (var i = 0; i < cs.length; i++) (cs[i], at[i])])
        : [for (final k in cs) hexOfColor(k).substring(1).toLowerCase()]
              .join(' ');
    if (t == null || !_usesGradientBlend(c.ws.aim ?? 'fill')) {
      c.ws.inkBlend = blend;
      return fill(word);
    }
    groupBegin(c.ws);
    fill(word);
    sayWord(c.ws, t, 'gradient_blend', blend);
    c.ws.after(groupEnd(c.ws));
  }

  /// Current gradient_blend. Unset = 'rgb'.
  String get blendNow {
    final t = colored,
        w = t != null && _usesGradientBlend(c.ws.aim ?? 'fill')
            ? wordOf(c.ws, t, 'gradient_blend')
            : c.ws.inkBlend;
    return w.isEmpty ? 'rgb' : w;
  }

  /// Saves the current color (or gradient) to the user's palette.
  void keepNow() {
    final stops = stopsIn(paintNow);
    stops.length > 1
        ? colors.saved.gradients.insert(
            0,
            ShelfGradient(
              'Gradient ${colors.saved.gradients.length + 1}',
              [for (final s in stops) s.$1],
              at: [for (final s in stops) s.$2],
              blend: blendNow,
              saved: true,
            ),
          )
        : colors.saved.colors.insert(
            0,
            colors.wheelColor.toColor(),
          ); // At the top, as the newest.
    colors.saved.keep();
  }

  // Whether a drag on the wheel or a gradient stop is in progress.
  bool _dragged = false;

  /// Starts a live-drag. Colours until [endUndoStep] are one undo step.
  void beginUndoStep() => _dragged = true;

  /// Ends the live-drag.
  void endUndoStep() {
    _dragged = false;
    c.ws.live.done();
  }

  /// Sets the gradient blend mode.
  void setBlend(String name, String blend) {
    final t = colored;
    t != null && _usesGradientBlend(name)
        ? c.ws.after(sayWord(c.ws, t, 'gradient_blend', blend))
        : c.set(() => c.ws.inkBlend = blend);
  }
}
