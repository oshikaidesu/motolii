// The small parts of the Colors shelf's picker that are not the wheel: fourteen sample colors, one press each, and the bar under them with
// the box size and the buttons that save the color, the project's colors, a photo's palette, and throw the box shapes again.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, IconPress;
import 'package:motolii/widgets/dice_painter.dart';
import 'package:motolii/widgets/media.dart' show MiniSlider, glyph;
import 'package:motolii/workspace/dock/colors/color_commands.dart';
import 'package:motolii/workspace/dock/colors/color_palette.dart';
import 'package:motolii/workspace/dock/colors/colors_controller.dart';
import 'package:motolii/workspace/dock/colors/photo_palette.dart';
import 'package:motolii/workspace/dock/colors/saved_colors.dart';
import 'package:motolii/workspace/dock/common/shelf_footer.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

/// Fourteen sample colors as in Alight Motion, white and black included, one press each.
class ColorSamples extends StatelessWidget {
  const ColorSamples(this.commands, {super.key});
  final ColorCommands commands;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
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
                    key: ValueKey(
                      'colour-sample-${rgb.toRadixString(16).padLeft(6, '0')}',
                    ),
                    onTap: () => commands.takeColor(Color(0xFF000000 | rgb)),
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
    ],
  );
}

/// The bar under the picker: the size of the boxes and the buttons that add to what is saved.
class ColorSavedBar extends StatelessWidget {
  const ColorSavedBar({
    super.key,
    required this.c,
    required this.colors,
    required this.commands,
    required this.used,
    required this.photo,
  });
  final ShelfContext c;
  final ColorsController colors;
  final ColorCommands commands;

  /// The colors the project uses, and the photo picked on the Media shelf, if there is one.
  final List<Color> used;
  final String? photo;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Colours',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.label(Grey.g76)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text('size', style: TextStyles.label(Grey.g76)),
        SizedBox(width: Shape.s(4)),
        Flexible(
          // Shrinks in a narrow shelf so it never pushes the row out.
          child: LayoutBuilder(
            builder: (context, b) => MiniSlider(
              // The box size can be any value. It is saved once the user stops dragging, not on every frame.
              key: const ValueKey('colour-size'),
              values: [colors.saved.tile],
              min: bentoTileLeast,
              max: bentoTileMost,
              width: math.min(Shape.z(64), b.maxWidth),
              onChanged: (v) {
                c.set(() => colors.saved.tile = v.first);
                colors.tileKept?.cancel();
                colors.tileKept = Timer(
                  const Duration(milliseconds: 400),
                  colors.saved.keep,
                );
              },
            ),
          ),
        ),
        SizedBox(width: Shape.s(6)),
        Chip(
          key: const ValueKey('colour-add'),
          label: '+',
          onTap: () => c.set(commands.keepNow),
        ), // Saves the current color, or the whole gradient, as the user's own, like CLIP STUDIO PAINT's Add Color.
        SizedBox(width: Shape.s(4)),
        Chip(
          key: const ValueKey('colour-keep'),
          label: 'Keep',
          onTap: used.isEmpty
              ? null
              : () => c.set(() {
                  // Saves the project's colors as a palette of the user's own.
                  colors.saved.palettes.insert(
                    0,
                    ColorPalette(
                      'mine${colors.saved.palettes.length}',
                      'Used ${colors.saved.palettes.length + 1}',
                      used,
                      saved: true,
                    ),
                  );
                  colors.saved.keep();
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
                  final p = await paletteFromPhoto(photo, colors.saved);
                  if (p != null) {
                    c.set(() {
                      colors.saved.palettes.insert(0, p);
                      colors.saved.keep();
                    });
                  }
                },
        ),
        SizedBox(width: Shape.s(6)),
        _colourDice(() => c.set(() => colors.dice++)),
      ],
    );
  }
}

/// The palette under the pointer or pressed last: its photo, name and owner, with a way to remove the user's own.
class PaletteDetails extends StatelessWidget {
  const PaletteDetails(this.c, this.colors, {super.key});
  final ShelfContext c;
  final ColorsController colors;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    // Details of the palette under the pointer or pressed last: its photo, name and owner.
    valueListenable: colors.paletteShown,
    builder: (context, id, _) {
      final p = colors.saved.allPalettes.where((p) => p.id == id).firstOrNull;
      if (p == null) return const SizedBox.shrink();
      final photo = p.reference != null && File(p.reference!).existsSync()
          ? p.reference
          : null;
      final whose = photo != null
          ? 'From ${photo.split('/').last.replaceFirst(RegExp(r'^[0-9]+_'), '')}'
          : p.saved
          ? 'Yours'
          : 'Starter';
      return ShelfFooter(
        key: const ValueKey('colour-details'),
        preview: photo != null
            ? Image.file(File(photo), fit: BoxFit.cover, cacheWidth: 96)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final col in p.colors)
                    Expanded(child: ColoredBox(color: col)),
                ],
              ),
        title: p.name,
        meta: '$whose · ${p.colors.length} colours',
        action: 'Remove',
        done: !p.saved,
        doneLabel: 'Starter',
        onAction: () => c.set(() {
          // Removes the user's palette from the shelf and updates its saved file.
          colors.saved.palettes.remove(p);
          colors.paletteShown.value = colors.palettePressed = null;
          colors.saved.keep();
        }),
      );
    },
  );
}

/// The dice button, showing a face of five. Pressing it throws the box shapes again.
Widget _colourDice(VoidCallback onTap) => IconPress(
  (k) => glyph(Shape.z(22), DicePainter(k, 5, filled: false).paint, k),
  key: const ValueKey('colour-dice'),
  onTap: onTap,
  size: Shape.z(22),
  rest: WindowTokens.well,
  ink: Grey.g76,
);
