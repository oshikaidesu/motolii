// The colour bento of the Colors shelf: boxes of colours and gradients.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:material_color_utilities/material_color_utilities.dart' show Cam16, ViewingConditions;

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/workspace/dock/dock_make.dart';
import 'package:motolii/workspace/dock/dock_make_palettes.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

/// One box of the color bento: a color or a gradient.
/// It belongs to a group: the project's colors, the user's own, a palette or the gradients.
/// [weight] is how much of the picture the box covers compared with the others of its group, where 1 is the same as each.
class BentoBox {
  const BentoBox(this.group, this.i, this.weight, {this.colour, this.grad});
  final String group;
  final int i;
  final double weight;
  final Color? colour;
  final ShelfGradient? grad;
}

int bentoDice = 0; // The dice's last throw, which sets the boxes' shapes.
const _rainbow = [
  Color(0xFFFF3B30),
  Color(0xFFFF9500),
  Color(0xFFFFCC00),
  Color(0xFF34C759),
  Color(0xFF00C7BE),
  Color(0xFF007AFF),
  Color(0xFFAF52DE),
  Color(0xFFFF3B30),
];
final _hovered = ValueNotifier<String?>(null); // The group of the box under the pointer.

/// Where each box lies, in grid cells, as (x, y, width, height).
/// The dice picks each box's shape: a color that covers more of the picture gets a larger box, and a gradient a wide one.
/// Each box then goes where it first fits from the top left, and later boxes fill the gaps
/// (dense auto-placement, CSS Grid Layout Module Level 1, section 8.5).
/// A throw changes about a third of the boxes and the rest keep their shapes, because changing all at once was too much.
List<(int, int, int, int)> _packed(List<BentoBox> boxes, int cols, int seed) {
  final taken = <int, Set<int>>{}, out = <(int, int, int, int)>[];
  bool free(int x, int y, int w, int h) {
    if (x + w > cols) return false;
    for (var j = y; j < y + h; j++) {
      for (var i = x; i < x + w; i++) {
        if (taken[j]?.contains(i) ?? false) return false;
      }
    }
    return true;
  }

  for (final b in boxes) {
    var thrown = 0; // The last throw that changed this box.
    for (var d = 1; d <= seed; d++) {
      if (math.Random(Object.hash(d, b.group, b.i, 7)).nextDouble() < .35) thrown = d;
    }
    final r = math.Random(Object.hash(thrown, b.group, b.i));
    final shapes = b.grad != null
        ? const [(2, 1), (3, 1), (2, 2)]
        : b.weight >= 1.6
        ? const [(2, 2), (3, 2), (2, 3), (3, 3)]
        : b.weight >= .9
        ? const [(2, 1), (1, 2), (2, 2), (1, 1)]
        : const [(1, 1), (1, 1), (1, 2), (2, 1)];
    final (w0, h) = shapes[r.nextInt(shapes.length)];
    final w = math.min(w0, cols);
    for (var y = 0; ; y++) {
      final x = [
        for (var x = 0; x < cols; x++)
          if (free(x, y, w, h)) x,
      ].firstOrNull;
      if (x == null) continue;
      for (var j = y; j < y + h; j++) {
        taken.putIfAbsent(j, () => {}).addAll([for (var i = x; i < x + w; i++) i]);
      }
      out.add((x, y, w, h));
      break;
    }
  }
  return out;
}

final _boxMenu = GlobalKey<ContextMenuState>();
(String, List<(int, int, int, int)>)? _bentoLaid; // The last layout, keyed by what it was laid out for.

/// The range of the box size slider. The size can be any value in it, not a few steps,
/// like Finder's icon size, Photoshop's Swatches panel and Lightroom's thumbnails.
const bentoTileLeast = 16.0, bentoTileMost = 120.0;
double bentoTile = 52;

/// The colors as a bento of boxes of many sizes, wide and tall, packed with no holes.
/// As many boxes fit in a row as the shelf is wide. A poster's colors take the space they cover, so the boxes are not all squares.
/// The dice throws the shapes again. Boxes move to their new place quickly and without overshooting
/// (AnimatedPositioned with easeOutCubic).
class Bento extends StatelessWidget {
  const Bento(this.boxes, this.c, {super.key});
  final List<BentoBox> boxes;
  final ShelfContext c;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // As many columns as boxes of the chosen size fit, with the boxes stretching to fill the row.
      // CLIP STUDIO PAINT's Color Set and CSS Grid's repeat(auto-fill, minmax()) work the same way.
      // The layout is redone only when the columns, the colors or the dice change, and only then do the boxes move.
      // Widening the shelf just stretches them without a new layout, which keeps the app at 60 frames per second.
      final cols = math.max(1, box.maxWidth ~/ Shape.z(bentoTile)), unit = box.maxWidth / cols, all = boxes;
      final key = '$cols/$bentoDice/${[for (final b in all) '${b.group}.${b.i}.${b.weight.toStringAsFixed(2)}'].join(',')}';
      final laid = _bentoLaid?.$1 == key ? _bentoLaid!.$2 : _packed(all, cols, bentoDice), moved = _bentoLaid?.$1 != key;
      _bentoLaid = (key, laid);
      final rows = laid.fold(0, (a, l) => math.max(a, l.$2 + l.$4)), gap = Shape.s(3);
      return ContextMenu(
        key: _boxMenu,
        child: SizedBox(
          height: rows * unit,
          child: Stack(
            children: [
              for (final (k, b) in all.indexed)
                AnimatedPositioned(
                  key: ValueKey('${b.group}-${b.i}'),
                  duration: moved ? const Duration(milliseconds: 200) : Duration.zero,
                  curve: Curves.easeOutCubic,
                  left: laid[k].$1 * unit,
                  top: laid[k].$2 * unit,
                  width: laid[k].$3 * unit - gap,
                  height: laid[k].$4 * unit - gap,
                  child: b.grad != null ? _GradientTile('grad-${b.i}', b.grad!, c) : _ColorBox(b, c),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// A color's box. Pressing it applies the color, or sets the selected stop while a gradient is the target.
/// Hovering it draws a rim around its group and shows the group in the shelf footer.
/// For the user's own colors, the right-click menu replaces or deletes it.
class _ColorBox extends StatelessWidget {
  const _ColorBox(this.b, this.c);
  final BentoBox b;
  final ShelfContext c;
  @override
  Widget build(BuildContext context) {
    final col = b.colour!, own = b.group == 'mine', pal = colorPalettes.where((p) => p.id == b.group).firstOrNull;
    return DockHover(
      key: ValueKey('colour-box-${b.group}-${b.i}'),
      onMenu: (at) {
        final items = [
          if (own) ...[
            ContextMenuItem(
              'Replace with ${hexOfColor(wheelColor.toColor())}',
              () => c.set(() {
                ownColors[b.i] = wheelColor.toColor();
                colorsKeep();
              }),
            ),
            ContextMenuItem(
              'Delete',
              () => c.set(() {
                ownColors.removeAt(b.i);
                colorsKeep();
              }),
            ),
          ],
          if (pal != null && pal.saved)
            ContextMenuItem(
              'Delete this palette',
              () => c.set(() {
                ownPalettes.remove(pal);
                paletteShown.value = palettePressed = null;
                colorsKeep();
              }),
            ),
        ];
        if (items.isEmpty) return;
        final box = _boxMenu.currentContext?.findRenderObject() as RenderBox?;
        _boxMenu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, items);
      },
      onHover: (on) {
        paletteShown.value = on ? b.group : palettePressed;
        _hovered.value = on ? b.group : null;
      },
      onTap: () {
        paletteShown.value = palettePressed = b.group;
        takeColor(c, col);
      },
      builder: (context, h) => ValueListenableBuilder<String?>(
        valueListenable: _hovered,
        builder: (context, over, _) {
          // Hovering a box puts a rainbow rim around each box of its palette, so the palette is seen whole. The other boxes are not darkened.
          final box = Container(
            decoration: BoxDecoration(
              color: col,
              borderRadius: BorderRadius.all(Shape.r(over == b.group ? 3 : 5)),
              border: wheelFrom == hexOfColor(col).substring(1).toLowerCase() ? Border.all(color: Grey.g95, width: 2) : null,
            ),
          );
          return over != b.group
              ? box
              : Container(
                  key: const ValueKey('colour-rim'),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Shape.r(5)),
                    gradient: const SweepGradient(colors: _rainbow),
                  ),
                  child: box,
                );
        },
      ),
    );
  }
}

/// A gradient as a small tile. Its name shows only on hover, like a swatch's,
/// because the user looks for the colors and the tiles stay a compact block however many are saved.
class _GradientTile extends StatelessWidget {
  const _GradientTile(this.id, this.g, this.c);
  final String id;
  final ShelfGradient g;
  final ShelfContext c;
  @override
  Widget build(BuildContext context) {
    final word = [for (final k in g.colors) hexOfColor(k).substring(1).toLowerCase()].join(' ');
    final (look, at) = _previewOf(g.colors, g.blend, g.at);
    return Semantics(
      label: g.name,
      child: DockHover(
        key: ValueKey('colour-$id'),
        onMenu: !g.saved
            ? null
            : (at) {
                // The menu of the user's own gradient, which can be deleted like the user's own colors.
                final box = _boxMenu.currentContext?.findRenderObject() as RenderBox?;
                _boxMenu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, [
                  ContextMenuItem(
                    'Delete this gradient',
                    () => c.set(() {
                      ownGradients.remove(g);
                      colorsKeep();
                    }),
                  ),
                ]);
              },
        onTap: () => putGradient(c, g.colors, g.blend, g.at), // Applies it with the stop positions and blend it was saved with.
        builder: (context, h) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: look, stops: at),
            borderRadius: BorderRadius.all(Shape.r(5)),
            border: wheelFrom == word ? Border.all(color: Grey.g95, width: 2) : (h ? Border.all(color: Grey.g76) : null),
          ),
        ),
      ),
    );
  }
}

/// The stops for a gradient's preview on the shelf, mixed as the engine will mix it. OKLab is drawn with CAM16, the nearest perceptual mix Flutter has.
(List<Color>, List<double>?) _previewOf(List<Color> cs, String blend, [List<double>? at]) => at != null && blend == 'rgb'
    ? (cs, at)
    : switch (blend) {
        'steps' => (
          [
            for (final c in cs) ...[c, c],
          ],
          [
            for (var i = 0; i < cs.length; i++) ...[i / cs.length, (i + 1) / cs.length],
          ],
        ),
        'hue' => (
          [
            for (var i = 0; i < cs.length - 1; i++)
              for (var k = 0; k < 6; k++) HSVColor.lerp(HSVColor.fromColor(cs[i]), HSVColor.fromColor(cs[i + 1]), k / 6)!.toColor(),
            cs.last,
          ],
          null,
        ),
        'oklab' => (_stopsOf(cs, true), null),
        _ => (cs, null),
      };

// ---- Gradient mixing in CAM16-UCS (from Google's material_color_utilities). This color space is close to how an eye mixes
// colors, so the middle of two colors looks as expected. The ramp the engine draws mixes plainly, so the middle is
// supplied as extra stops laid in that space, a few between each pair.
List<Color> _stopsOf(List<Color> cs, bool smooth) {
  if (!smooth || cs.length < 2) return cs;
  final out = <Color>[];
  for (var i = 0; i < cs.length - 1; i++) {
    final a = Cam16.fromInt(cs[i].toARGB32()), b = Cam16.fromInt(cs[i + 1].toARGB32());
    for (var k = 0; k < 5; k++) {
      final t = k / 5;
      out.add(
        k == 0
            ? cs[i]
            : Color(
                Cam16.fromUcs(
                  a.jstar + (b.jstar - a.jstar) * t,
                  a.astar + (b.astar - a.astar) * t,
                  a.bstar + (b.bstar - a.bstar) * t,
                ).viewed(ViewingConditions.sRgb),
              ),
      );
    }
  }
  return out..add(cs.last);
}
