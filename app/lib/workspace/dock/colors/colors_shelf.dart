// The Colors shelf (pop palettes, a swatch field, saved gradients).
import 'package:motolii/workspace/dock/colors/color_saved_bar.dart';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/skin/hex_color.dart' show colorOfHex;
import 'package:motolii/skin/theme.dart' show ColorTheme;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip;
import 'package:motolii/widgets/text_gestures.dart' show wordsPicked;
import 'package:motolii/workspace/dock/colors/color_bento.dart';
import 'package:motolii/workspace/dock/colors/color_commands.dart';
import 'package:motolii/workspace/dock/colors/color_palette.dart';
import 'package:motolii/workspace/dock/colors/color_wheel.dart';
import 'package:motolii/workspace/dock/colors/colors_controller.dart';
import 'package:motolii/workspace/dock/colors/gradient_stops.dart';
import 'package:motolii/workspace/dock/colors/hex_field.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The Colors shelf. It stays small however many colors are saved, and one press applies a color. From the top it shows:
/// - the target in one line;
/// - the current color with its square, a full-width hue bar and its hex code, as in Figma's picker;
/// - every palette as a small card of stripes, side by side in rows, where a press on a stripe takes that color
///   (as the palette cards of Coolors, Adobe Color and Canva);
/// - the gradients as small tiles.
class ColorsShelf extends StatelessWidget {
  const ColorsShelf(this.c, this.colors, {super.key});
  final ShelfContext c;

  /// What the shelf keeps between builds: the color on the picker, the stop it edits, the user's saved colors.
  final ColorsController colors;

  /// The layer a color goes to and the name of the property. The layer is null for the next layer drawn.
  (int?, String) _target(ColorCommands commands) {
    final t = commands.colored, aim = c.ws.aim ?? 'fill';
    return (t ?? (aim == 'fill' || aim == 'stroke' ? null : 0), aim);
  }

  @override
  Widget build(BuildContext context) {
    WorkspaceScope.of(context, {
      WorkspaceAspect.picked,
      WorkspaceAspect.document,
    }); // Rebuilds when the target or the selection changes.
    colors.saved.read();
    final commands = ColorCommands(c, colors);
    final m = c.ws.inside!, usedCount = <Color, int>{};
    for (final col in usedColors(c.ws).values) {
      usedCount[col] = (usedCount[col] ?? 0) + 1; // Layers using this color: roughly how much of the picture it covers.
    }
    final used = usedCount.keys.toList();
    final (t, name) = _target(commands);
    final word = t == null
        ? (name == 'stroke' ? c.ws.edge : c.ws.ink)
        : m.word(t, name);
    final stops = stopsIn(word),
        gradient = stops.length > 1,
        none = name == 'stroke' ? word.isEmpty : word == 'none';
    if (colors.stop >= stops.length) colors.stop = 0;
    // The picker shows the color of the target, or of the selected gradient stop, as CLIP STUDIO PAINT's wheel shows the main or sub color.
    if (word != colors.wheelFrom) {
      colors.wheelFrom = word;
      if (colors.wheelHeld) {
        // While the user drags the wheel it keeps the dragged hue, which a gray written as hex would lose.
      } else if (gradient) {
        colors.wheelColor = HSVColor.fromColor(
          stops[colors.stop].$1.withValues(alpha: 1),
        );
      } else if (colorOfHex(word.split(' ').first.split('@').first)
          case final col?) {
        colors.wheelColor = HSVColor.fromColor(col);
      }
    }
    String hexOf(Color col) => hexOfColor(col).substring(1).toLowerCase();
    final whom = t == null
        ? 'the next thing drawn'
        : t == 0
        ? 'the stage'
        : (c.ws.layer?.name ?? 'the picked thing');
    final q = c.query.toLowerCase();
    final pals = [
      for (final p in colors.saved.allPalettes)
        if (q.isEmpty || p.name.toLowerCase().contains(q)) p,
    ];
    final grads = [
      for (final (i, g) in colors.saved.allGradients.indexed)
        if (q.isEmpty || g.name.toLowerCase().contains(q)) (i, g),
    ];
    final photo = _pickedPhoto(c);
    void to(HSVColor v) {
      // The square or the hue moved: update the color, or the selected stop's color.
      colors.wheelColor = v;
      if (!gradient) return commands.fill(hexOf(v.toColor()));
      final next = [...stops];
      next[colors.stop] = (
        v.toColor().withValues(alpha: stops[colors.stop].$1.a),
        stops[colors.stop].$2,
      );
      commands.fill(wordOfStops(next));
    }

    // The paint type, as in Alight Motion's tabs and Figma. Switching a color to a gradient fades it to clear, as Figma does.
    // Switching a gradient to a color keeps the selected stop's color.
    Widget kind(String label, bool on, VoidCallback go) => Chip(
      key: ValueKey('colour-kind-$label'),
      label: label,
      on: on,
      onTap: on ? null : go,
    );
    // Two blocks. The top stays in place: the target, the paint type and the wheel. Only the saved colors below scroll,
    // so + and the dice stay within reach. Saved colors sit under the picker, as in Procreate's Color Panel and in Figma.
    final top = Padding(
      padding: EdgeInsets.fromLTRB(
        WindowTokens.inset,
        Shape.s(6),
        WindowTokens.inset,
        Shape.s(6),
      ),
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
                    final at = name == 'fill'
                        ? commands.lettersPicked(t)
                        : null;
                    final who = at == null
                        ? whom
                        : '“${String.fromCharCodes(m.word(t!, 'text').runes.toList().sublist(at.$1, at.$2))}” in $whom';
                    return Text(
                      '${name == 'fill'
                          ? 'Fill'
                          : name == 'stroke'
                          ? 'Stroke'
                          : name[0].toUpperCase() + name.substring(1)} of $who',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.name(Grey.g91)
                          .copyWith(fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
              SizedBox(width: Shape.s(6)),
              Chip(
                key: const ValueKey('colour-sample'),
                label: 'Sample',
                onTap: () => commands.sample(),
              ), // Samples a color from anywhere on the screen with the Mac's eyedropper.
            ],
          ),
          if (c.mem.trouble['fill'] case final why?)
            Padding(
              padding: EdgeInsets.only(top: Shape.s(4)),
              child: Text(
                why,
                style: TextStyles.label(
                  ColorTheme.of('Alert', const Color(0xFFE5484D)),
                ),
              ),
            ),
          SizedBox(height: Shape.s(6)),
          Row(
            children: [
              kind(
                'Solid',
                !gradient && !none,
                () => commands.fill(
                  hexOf(
                    gradient
                        ? stops[colors.stop].$1
                        : colors.wheelColor.toColor(),
                  ),
                ),
              ),
              if (name == 'fill') ...[
                SizedBox(width: Shape.s(4)),
                kind(
                  'Gradient',
                  gradient,
                  () => commands.fill(
                    wordOfStops([
                      (colors.wheelColor.toColor(), 0),
                      (colors.wheelColor.toColor().withValues(alpha: 0), 1),
                    ]),
                  ),
                ),
              ],
              SizedBox(width: Shape.s(4)),
              kind(
                'None',
                none,
                () => commands.fill(name == 'stroke' ? '' : 'none'),
              ),
              const Spacer(),
              if (gradient && stops.length > 2)
                Chip(
                  key: const ValueKey('colour-stop-remove'),
                  label: 'Remove stop',
                  onTap: () => commands.fill(
                    wordOfStops([...stops]..removeAt(colors.stop)),
                  ),
                ),
            ],
          ),
          SizedBox(height: Shape.s(8)),
          if (gradient) ...[
            GradientStops(
              colors,
              stops,
              (next) => commands.fill(wordOfStops(next)),
              (i) => c.set(() {
                colors.stop = i;
                colors.wheelFrom = ''; // (the picker shows the stop picked)
              }),
              onDrag: (down) =>
                  down ? commands.beginUndoStep() : commands.endUndoStep(),
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
                    on: commands.blendNow == b,
                    onTap: () => commands.setBlend(name, b),
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
                child: ColorWheel(
                  key: const ValueKey('colour-square'),
                  color: colors.wheelColor,
                  onChanged: to,
                  onStart: () {
                    colors.wheelHeld = true;
                    commands.beginUndoStep();
                  },
                  onEnd: () {
                    colors.wheelHeld = false;
                    commands.endUndoStep();
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
                  color: colors.wheelColor.toColor(),
                  borderRadius: BorderRadius.all(Shape.r(4)),
                  border: Border.all(color: Grey.g26),
                ),
              ),
              SizedBox(width: Shape.s(8)),
              Expanded(
                child: HexField(
                  hexOfColor(colors.wheelColor.toColor()),
                  (col) => to(HSVColor.fromColor(col)),
                ),
              ),
            ],
          ),
          SizedBox(height: Shape.s(6)),
          ColorSamples(commands),
          SizedBox(height: Shape.s(10)),
          ColorSavedBar(
            c: c,
            colors: colors,
            commands: commands,
            used: used,
            photo: photo,
          ),
        ],
      ),
    );
    final list = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        WindowTokens.inset,
        Shape.s(6),
        WindowTokens.inset,
        WindowTokens.inset,
      ),
      child: Bento(
        [
          // The newest additions come first: the user's own colors, then the user's own gradients.
          // No other app does this: Procreate fills the next empty slot and Canva sorts by hue.
          if (q.isEmpty)
            for (final (i, col) in colors.saved.colors.indexed)
              BentoBox('mine', i, 1, colour: col),
          for (final (i, g) in grads)
            if (g.saved) BentoBox('grads', i, 1, grad: g),
          if (q.isEmpty)
            for (final (i, col) in used.indexed)
              BentoBox(
                'used',
                i,
                usedCount[col]! *
                    used.length /
                    usedCount.values.fold(0, (a, b) => a + b),
                colour: col,
              ),
          for (final p in pals)
            for (final (i, col) in p.colors.indexed)
              BentoBox(
                p.id,
                i,
                (p.shares?[i] ?? 1 / p.colors.length) * p.colors.length,
                colour: col,
              ),
          for (final (i, g) in grads)
            if (!g.saved) BentoBox('grads', i, 1, grad: g),
        ],
        c,
        colors,
      ),
    );
    return Column(
      children: [
        top,
        Container(height: 1, color: WindowTokens.line),
        Expanded(child: list),
        PaletteDetails(c, colors),
      ],
    );
  }
}

/// The ways a gradient's colors are mixed between stops, and the label of each on its chip.
const _blends = {
  'rgb': 'RGB',
  'oklab': 'OKLab',
  'hue': 'Hue',
  'steps': 'Steps',
};

/// The photo picked on the Media shelf, if it is an image file on disk that Flutter can read.
/// It reads Media's own selection, because each shelf keeps its selection apart (the pane's memory in shelf_pane.dart).
String? _pickedPhoto(ShelfContext c) {
  final id = (c.ws.view['dock.Media'] as ShelfMemory?)?.sel['Media'];
  return id != null &&
          id.startsWith('/') &&
          RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false).hasMatch(id)
      ? id
      : null;
}
