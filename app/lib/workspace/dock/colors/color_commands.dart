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

/// What the Colors shelf asks the engine to do: color the selected layer, some letters of a text or the next layer
/// drawn, and say what is being colored now. Every call to the engine the shelf makes is a method here.
class ColorCommands {
  /// [c] is the shelf as it is built now, and [colors] what the shelf keeps between builds.
  ColorCommands(this.c, this.colors);

  /// The shelf's context: the project, the shelf's memory and a way to rebuild the shelf.
  final ShelfContext c;

  /// The color on the picker, the stop it edits and the user's saved colors.
  final ColorsController colors;

  /// The letters selected in the selected text layer's text, or null.
  ({int start, int count})? lettersPicked(int? t) {
    if (t == null || wordOf(c.ws, t, 'kind') != 'text') return null;
    return pickedLetters(wordOf(c.ws, t, 'text'), wordsPicked.value);
  }

  /// Colors some letters of a text layer and leaves the rest alone, as Figma, Canva, PowerPoint, Keynote
  /// and After Effects' Character panel do for selected characters: one range of the layer's text_styles
  /// sets their CSS color (see inspector/text/text_ranges.dart).
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

  /// Sets the fill of the selected layer to [word] (six hex digits or a material name). On failure the shelf footer shows why.
  /// During a drag on the wheel each colour is a step of [WorkspaceController.live]: the stage and the panels follow it.
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
          (valueOf(c.ws, t, 'stroke_width', 0) ?? 0) <= 0;
      if (edged) groupBegin(c.ws);
      final said = sayWord(c.ws, t ?? 0, aim, word);
      if (edged) setNumber(c.ws, t, 'stroke_width', 6);
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
      // No layer is selected: set the drawing tools' ink, which fills the next layer drawn.
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

  /// The layer the shelf colors: the selected one. A sound has nothing to color, so it counts as no selection (the next layer drawn).
  int? get colored => switch (int.tryParse(c.ws.selected ?? '')) {
    final t? when soundLayer(c.ws, t) => null,
    final t => t,
  };

  /// The current value of the target: the selected layer's property (its fill, unless a link or the tool strip chose another),
  /// else the stage's, else the ink or edge of the next layer drawn.
  String get paintNow {
    final t = colored, aim = c.ws.aim ?? 'fill';
    if (t != null) return wordOf(c.ws, t, aim);
    if (aim == 'fill' || aim == 'stroke') {
      return aim == 'stroke' ? c.ws.edge : c.ws.ink;
    }
    return wordOf(c.ws, 0, aim);
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
    final t = colored;
    final word = at != null && at.length == cs.length
        ? wordOfStops([for (var i = 0; i < cs.length; i++) (cs[i], at[i])])
        : [for (final k in cs) hexOfColor(k).substring(1).toLowerCase()]
              .join(' ');
    if (t == null || (c.ws.aim ?? 'fill') != 'fill') {
      c.ws.inkBlend = blend;
      return fill(word);
    }
    groupBegin(c.ws);
    fill(word);
    sayWord(c.ws, t, 'gradient_blend', blend);
    c.ws.after(groupEnd(c.ws));
  }

  /// How the gradient being edited is mixed: the picked layer's gradient_blend, or the ink's. Unset means 'rgb'.
  String get blendNow {
    final t = colored,
        w = t != null && (c.ws.aim ?? 'fill') == 'fill'
            ? wordOf(c.ws, t, 'gradient_blend')
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

  // Whether a drag on the wheel or a gradient stop is in progress.
  bool _dragged = false;

  /// Starts a drag: the colours [fill] is given until [endUndoStep] are shown as they come and undone together.
  void beginUndoStep() => _dragged = true;

  /// Ends the drag [beginUndoStep] started, as one undo step.
  void endUndoStep() {
    _dragged = false;
    c.ws.live.done();
  }

  /// Sets how the gradient being edited is mixed to [blend]: on the picked layer when its fill ([name] is 'fill') is
  /// the target, otherwise on the ink of the next layer drawn.
  void setBlend(String name, String blend) {
    final t = colored;
    t != null && name == 'fill'
        ? c.ws.after(sayWord(c.ws, t, 'gradient_blend', blend))
        : c.set(() => c.ws.inkBlend = blend);
  }
}
