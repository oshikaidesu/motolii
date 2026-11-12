// What the Colors shelf asks the engine to do: give a layer, some letters or the next layer drawn a color or a gradient.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/inspector/text/text_ranges.dart';
import 'package:motolii/widgets/text_gestures.dart' show wordsPicked;
import 'package:motolii/workspace/dock/colors/color_palette.dart';
import 'package:motolii/workspace/dock/colors/colors_controller.dart';
import 'package:motolii/workspace/dock/colors/gradient_stops.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// What the Colors shelf asks the engine to do: color the selected layer, some letters of a text or the next layer
/// drawn, and say what is being colored now. Every call to the engine the shelf makes is a method here.
class ColorCommands {
  /// [c] is the shelf as it is built now, and [colors] what the shelf keeps between builds.
  ColorCommands(this.c, this.colors);

  /// The shelf's context: the project, the shelf's memory and a way to rebuild the shelf.
  final ShelfContext c;

  /// The color on the picker, the stop it edits and the user's saved colors.
  final ColorsController colors;

  /// The range of letters selected in the selected text layer, as letter indexes, or null.
  /// It is null unless the selection still matches the layer's text. Indexes count characters, not bytes.
  (int, int)? lettersPicked(int? t) {
    final m = c.ws.inside, p = wordsPicked.value;
    if (m == null ||
        t == null ||
        p == null ||
        m.word(t, 'kind') != 'text' ||
        m.word(t, 'text') != p.text) {
      return null;
    }
    return (
      p.text.substring(0, p.start).runes.length,
      p.text.substring(0, p.end).runes.length,
    );
  }

  /// Colors some letters of a text layer and leaves the rest alone, as Figma, Canva, PowerPoint, Keynote
  /// and After Effects' Character panel do for selected characters: one range of the layer's text_styles
  /// sets their CSS color (see inspector/text/text_ranges.dart).
  void _fillLetters(int t, (int, int) at, String word) {
    final m = c.ws.inside!;
    final styles = styleRange(
      m.word(t, 'text_styles'),
      at.$1,
      at.$2 - at.$1,
      'color',
      '#$word',
    );
    c.ws.after(
      m.later('say', layer: t, name: 'text_styles', word: styles),
      (done, why) => c.set(
        () => done ? c.mem.trouble.remove('fill') : c.mem.trouble['fill'] = why,
      ),
    );
  }

  /// Sets the fill of the selected layer to [word] (six hex digits or a material name). On failure the shelf footer shows why.
  void fill(String word) {
    final m = c.ws.inside!, t = colored;
    if ((c.ws.aim == null || c.ws.aim == 'fill') &&
        RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(word)) {
      if (lettersPicked(t) case final at?) {
        return _fillLetters(t!, at, word.toLowerCase());
      }
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
      // and as the drawing tools do (applyChosenInks). All of it is one undo step.
      final edged =
          aim == 'stroke' &&
          t != null &&
          word != 'none' &&
          (m.value(t, 'stroke_width', 0) ?? 0) <= 0;
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

  /// The layer the shelf colors: the selected one. A sound has nothing to color, so it counts as no selection (the next layer drawn).
  int? get colored => switch (int.tryParse(c.ws.selected ?? '')) {
    final t? when isSoundLayer(c.ws.inside!, t) => null,
    final t => t,
  };

  /// The current value of the target: the selected layer's property (its fill, unless a link or the tool strip chose another),
  /// else the stage's, else the ink or edge of the next layer drawn.
  String get paintNow {
    final t = colored, aim = c.ws.aim ?? 'fill', m = c.ws.inside!;
    if (t != null) return m.word(t, aim);
    if (aim == 'fill' || aim == 'stroke') {
      return aim == 'stroke' ? c.ws.edge : c.ws.ink;
    }
    return m.word(0, aim);
  }

  /// Applies a color from a swatch or the eyedropper to the target, or to the selected stop while the target is a gradient.
  /// Figma and Canva swatches also color the stop being edited.
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

  /// The Mac's eyedropper (NSColorSampler, used in MainFlutterWindow.swift). The sampled color is applied to the target at once,
  /// as Keynote's eyedropper does.
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

  /// Puts a gradient on what is being colored: its colors, and how they are mixed. That is the picked layer's gradient_blend,
  /// or the ink's for the next layer drawn. It is one undo step.
  void putGradient(List<Color> cs, String blend, [List<double>? at]) {
    final m = c.ws.inside!, t = colored;
    final word = at != null && at.length == cs.length
        ? wordOfStops([for (var i = 0; i < cs.length; i++) (cs[i], at[i])])
        : [for (final k in cs) hexOfColor(k).substring(1).toLowerCase()]
              .join(' ');
    if (t == null || (c.ws.aim ?? 'fill') != 'fill') {
      c.ws.inkBlend = blend;
      return fill(word);
    }
    m.later('together', number: 1);
    fill(word);
    m.later('say', layer: t, name: 'gradient_blend', word: blend);
    c.ws.after(m.later('together'));
  }

  /// How the gradient being edited is mixed: the picked layer's gradient_blend, or the ink's. Unset means 'rgb'.
  String get blendNow {
    final t = colored,
        w = t != null && (c.ws.aim ?? 'fill') == 'fill'
            ? c.ws.inside!.word(t, 'gradient_blend')
            : c.ws.inkBlend;
    return w.isEmpty ? 'rgb' : w;
  }

  /// Saves the current color as the user's own, like Add Color in CLIP STUDIO PAINT's color set.
  /// If the target is a gradient, the whole gradient is saved with its stop positions and blend.
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

  /// Starts one undo step: what is changed until [endUndoStep] is undone together, as a drag on the wheel is.
  void beginUndoStep() => c.ws.inside!.later('together', number: 1);

  /// Ends the undo step [beginUndoStep] started.
  void endUndoStep() => c.ws.after(c.ws.inside!.later('together'));

  /// Sets how the gradient being edited is mixed to [blend]: on the picked layer when its fill ([name] is 'fill') is
  /// the target, otherwise on the ink of the next layer drawn.
  void setBlend(String name, String blend) {
    final t = colored;
    t != null && name == 'fill'
        ? c.ws.after(
            c.ws.inside!.later(
              'say',
              layer: t,
              name: 'gradient_blend',
              word: blend,
            ),
          )
        : c.set(() => c.ws.inkBlend = blend);
  }
}
