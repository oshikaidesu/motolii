// Part of dock_make.dart: the colour bento: boxes of colours and gradients.
part of 'dock_make.dart';

/// One box of the color bento: a color or a gradient.
/// It belongs to a group: the project's colors, the user's own, a palette or the gradients.
/// [weight] is how much of the picture the box covers compared with the others of its group, where 1 is the same as each.
class _Box {
  const _Box(this.group, this.i, this.weight, {this.colour, this.grad});
  final String group;
  final int i;
  final double weight;
  final Color? colour;
  final _Gradient? grad;
}

int _dice = 0; // The dice's last throw, which sets the boxes' shapes.
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
List<(int, int, int, int)> _packed(List<_Box> boxes, int cols, int seed) {
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

final _boxMenu = GlobalKey<WsMenuState>();
(String, List<(int, int, int, int)>)? _bentoLaid; // The last layout, keyed by what it was laid out for.

/// The range of the box size slider. The size can be any value in it, not a few steps,
/// like Finder's icon size, Photoshop's Swatches panel and Lightroom's thumbnails.
const _tileLeast = 16.0, _tileMost = 120.0;
double _tile = 52;
Timer? _tileKept;

/// The colors as a bento of boxes of many sizes, wide and tall, packed with no holes.
/// As many boxes fit in a row as the shelf is wide. A poster's colors take the space they cover, so the boxes are not all squares.
/// The dice throws the shapes again. Boxes move to their new place quickly and without overshooting
/// (AnimatedPositioned with easeOutCubic).
class _Bento extends StatelessWidget {
  const _Bento(this.boxes, this.c);
  final List<_Box> boxes;
  final DockCtx c;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // As many columns as boxes of the chosen size fit, with the boxes stretching to fill the row.
      // CLIP STUDIO PAINT's Color Set and CSS Grid's repeat(auto-fill, minmax()) work the same way.
      // The layout is redone only when the columns, the colors or the dice change, and only then do the boxes move.
      // Widening the shelf just stretches them without a new layout, which keeps the app at 60 frames per second.
      final cols = math.max(1, box.maxWidth ~/ Shape.z(_tile)), unit = box.maxWidth / cols, all = boxes;
      final key = '$cols/$_dice/${[for (final b in all) '${b.group}.${b.i}.${b.weight.toStringAsFixed(2)}'].join(',')}';
      final laid = _bentoLaid?.$1 == key ? _bentoLaid!.$2 : _packed(all, cols, _dice), moved = _bentoLaid?.$1 != key;
      _bentoLaid = (key, laid);
      final rows = laid.fold(0, (a, l) => math.max(a, l.$2 + l.$4)), gap = Shape.s(3);
      return WsMenu(
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
                  child: b.grad != null ? _Grad('grad-${b.i}', b.grad!, c) : _ColorBox(b, c),
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
  final _Box b;
  final DockCtx c;
  @override
  Widget build(BuildContext context) {
    final col = b.colour!, own = b.group == 'mine', pal = _pals.where((p) => p.id == b.group).firstOrNull;
    return DockHover(
      key: ValueKey('colour-box-${b.group}-${b.i}'),
      onMenu: (at) {
        final items = [
          if (own) ...[
            WsMenuItem(
              'Replace with ${_hex(_wheel.toColor())}',
              () => c.set(() {
                _mineColors[b.i] = _wheel.toColor();
                _keepMine();
              }),
            ),
            WsMenuItem(
              'Delete',
              () => c.set(() {
                _mineColors.removeAt(b.i);
                _keepMine();
              }),
            ),
          ],
          if (pal != null && pal.saved)
            WsMenuItem(
              'Delete this palette',
              () => c.set(() {
                _minePals.remove(pal);
                _named.value = _pressed = null;
                _keepMine();
              }),
            ),
        ];
        if (items.isEmpty) return;
        final box = _boxMenu.currentContext?.findRenderObject() as RenderBox?;
        _boxMenu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, items);
      },
      onHover: (on) {
        _named.value = on ? b.group : _pressed;
        _hovered.value = on ? b.group : null;
      },
      onTap: () {
        _named.value = _pressed = b.group;
        _take(c, col);
      },
      builder: (context, h) => ValueListenableBuilder<String?>(
        valueListenable: _hovered,
        builder: (context, over, _) {
          // Hovering a box puts a rainbow rim around each box of its palette, so the palette is seen whole. The other boxes are not darkened.
          final box = Container(
            decoration: BoxDecoration(
              color: col,
              borderRadius: BorderRadius.all(Shape.r(over == b.group ? 3 : 5)),
              border: _wheelFrom == _hex(col).substring(1).toLowerCase() ? Border.all(color: Grey.g95, width: 2) : null,
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

/// Saves the current color as the user's own, like Add Color in CLIP STUDIO PAINT's color set.
/// If the target is a gradient, the whole gradient is saved with its stop positions and blend.
void _keepNow(DockCtx c) {
  final stops = _stopsIn(_paintNow(c));
  stops.length > 1
      ? _mineGrads.insert(
          0,
          _Gradient('Gradient ${_mineGrads.length + 1}', [for (final s in stops) s.$1], at: [for (final s in stops) s.$2], blend: _blendNow(c), saved: true),
        )
      : _mineColors.insert(0, _wheel.toColor()); // At the top, as the newest.
  _keepMine();
}

/// Parses a gradient's fill word, such as "ff3366@0.35 ...", into colors and their positions.
/// A color without @ is spaced evenly. Returns an empty list if the word is not a gradient.
List<(Color, double)> _stopsIn(String word) {
  final parts = word.split(' ').where((w) => w.isNotEmpty).toList();
  if (parts.length < 2) return const [];
  final out = <(Color, double)>[];
  for (final (i, w) in parts.indexed) {
    final col = colorOfHex(w.split('@').first);
    if (col == null) return const [];
    out.add((col, w.contains('@') ? (double.tryParse(w.split('@').last) ?? 0).clamp(0.0, 1.0) : i / (parts.length - 1)));
  }
  return out;
}

/// The inverse of [_stopsIn]: writes the stops back as a fill word.
String _wordOfStops(List<(Color, double)> stops) {
  String hex8(Color c) => _hex(c).substring(1).toLowerCase() + (c.a < 1 ? (c.a * 255).round().toRadixString(16).padLeft(2, '0') : '');
  return [
    for (final (col, at) in [...stops]..sort((a, b) => a.$2.compareTo(b.$2))) '${hex8(col)}@${at.toStringAsFixed(3)}',
  ].join(' ');
}

int _stop = 0; // The stop the picker edits.

/// The gradient editor: a bar with its stops beneath, as in Figma and Canva.
/// - Pressing the bar adds a stop there, in the color the bar has at that point.
/// - Pressing a stop selects it, and the square above then edits its color.
/// - Dragging a stop along the bar moves it.
/// - Remove deletes the selected stop, but at least two stay.
class _Stops extends StatefulWidget {
  const _Stops(this.stops, this.onChanged, this.onPick, {this.onDrag});
  final List<(Color, double)> stops;
  final ValueChanged<List<(Color, double)>> onChanged;
  final ValueChanged<int> onPick;

  /// Called with true when a drag starts and false when it ends, so the caller can make it one undo step.
  final ValueChanged<bool>? onDrag;
  @override
  State<_Stops> createState() => _StopsState();
}

class _StopsState extends State<_Stops> {
  List<(Color, double)>? _held; // The stops as they are while one is being dragged.

  Color _at(List<(Color, double)> s, double x) {
    final sorted = [...s]..sort((a, b) => a.$2.compareTo(b.$2));
    if (x <= sorted.first.$2) return sorted.first.$1;
    for (var i = 1; i < sorted.length; i++) {
      if (x <= sorted[i].$2) return Color.lerp(sorted[i - 1].$1, sorted[i].$1, (x - sorted[i - 1].$2) / math.max(1e-6, sorted[i].$2 - sorted[i - 1].$2))!;
    }
    return sorted.last.$1;
  }

  @override
  Widget build(BuildContext context) {
    final s = _held ?? widget.stops, sorted = [...s]..sort((a, b) => a.$2.compareTo(b.$2)), knob = Shape.z(12);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth - knob;
        return SizedBox(
          height: Shape.z(18) + knob + Shape.s(4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: knob / 2,
                width: w,
                top: 0,
                height: Shape.z(18),
                child: GestureDetector(
                  key: const ValueKey('colour-stops-bar'),
                  onTapUp: (d) {
                    final x = (d.localPosition.dx / w).clamp(0.0, 1.0);
                    widget.onChanged([...s, (_at(s, x), x)]);
                    widget.onPick(s.where((e) => e.$2 <= x).length); // The index among the stops, because the document keeps them in order.
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Shape.r(3)),
                      gradient: LinearGradient(colors: [for (final e in sorted) e.$1], stops: [for (final e in sorted) e.$2]),
                    ),
                  ),
                ),
              ),
              for (final (i, (col, at)) in s.indexed)
                Positioned(
                  left: at * w,
                  top: Shape.z(18) + Shape.s(3),
                  width: knob,
                  height: knob,
                  child: GestureDetector(
                    key: ValueKey('colour-stop-$i'),
                    onTap: () => widget.onPick(i),
                    onHorizontalDragStart: (_) {
                      widget.onPick(i);
                      widget.onDrag?.call(true);
                      setState(() => _held = [...s]);
                    },
                    onHorizontalDragUpdate: (d) {
                      final held = _held!;
                      held[i] = (held[i].$1, (held[i].$2 + d.delta.dx / w).clamp(0.0, 1.0));
                      setState(() {});
                      widget.onChanged([...held]);
                    },
                    onHorizontalDragEnd: (_) {
                      final held = _held!, at = held[i].$2;
                      widget.onPick(held.where((e) => e.$2 < at).length); // If it was dragged past another stop, select it at its new index.
                      setState(() => _held = null);
                      widget.onDrag?.call(false);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: col,
                        borderRadius: BorderRadius.all(Shape.r(2)),
                        border: Border.all(color: i == _stop ? Grey.g95 : Grey.g44, width: i == _stop ? 2 : 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A gradient as a small tile. Its name shows only on hover, like a swatch's,
/// because the user looks for the colors and the tiles stay a compact block however many are saved.
class _Grad extends StatelessWidget {
  const _Grad(this.id, this.g, this.c);
  final String id;
  final _Gradient g;
  final DockCtx c;
  @override
  Widget build(BuildContext context) {
    final word = [for (final k in g.colors) _hex(k).substring(1).toLowerCase()].join(' ');
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
                  WsMenuItem(
                    'Delete this gradient',
                    () => c.set(() {
                      _mineGrads.remove(g);
                      _keepMine();
                    }),
                  ),
                ]);
              },
        onTap: () => _putGradient(c, g.colors, g.blend, g.at), // Applies it with the stop positions and blend it was saved with.
        builder: (context, h) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: look, stops: at),
            borderRadius: BorderRadius.all(Shape.r(5)),
            border: _wheelFrom == word ? Border.all(color: Grey.g95, width: 2) : (h ? Border.all(color: Grey.g76) : null),
          ),
        ),
      ),
    );
  }
}

/// The dice button, showing a face of five. Pressing it throws the box shapes again.
Widget _colourDice(VoidCallback onTap) => IconPress(
  (k) => glyph(Shape.z(22), DicePaint(k, 5, filled: false).paint, k),
  key: const ValueKey('colour-dice'),
  onTap: onTap,
  size: Shape.z(22),
  rest: WsT.well,
  ink: Grey.g76,
);
