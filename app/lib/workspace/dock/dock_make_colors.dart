// Part of dock_make.dart: the colour bento: boxes of colours and gradients.
part of 'dock_make.dart';

/// One box of the colour bento: a colour or a gradient, the group it is of (the document's, one's own, a palette, the
/// gradients), and how much of the picture it is beside the others of its group (1: as much as each).
class _Box {
  const _Box(this.group, this.i, this.weight, {this.colour, this.grad});
  final String group;
  final int i;
  final double weight;
  final Color? colour;
  final _Gradient? grad;
}

int _dice = 0; // (the dice's last throw: the boxes' shapes)
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
final _hovered = ValueNotifier<String?>(null); // (the group of the box the hand is on)

/// Where each box lies, in cells: its shape thrown by the dice (a colour that is more of the picture, a larger box; a
/// gradient wide), then each put where it first fits from the top left and the gaps filled by later ones (CSS Grid's
/// auto-placement, dense: CSS Grid Layout 1, 8.5). A throw takes up about a third of the boxes, the rest keep their
/// shapes (the user: all of them changing at once was too much).
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
    var thrown = 0; // (the last throw that took this box up)
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
(String, List<(int, int, int, int)>)? _bentoLaid; // (the last laying out, by what it was laid for)

/// How large a box is, any size the maker likes (the user: not a few steps, "任意で数値を"): a size slider over the
/// grid, as the Browser study's (sets/studies/panel_browser_b_8.dart, "size"), Finder's icon size, Photoshop's
/// Swatches panel, Lightroom's thumbnails.
const _tileLeast = 16.0, _tileMost = 120.0;
double _tile = 52;
Timer? _tileKept;

/// The colours as a bento of boxes of many sizes, wide and tall, packed with no holes, as many to a row as the shelf is
/// wide (the user: a poster's colours come with the space they take, so not all squares; a dice throws the shapes
/// again). Boxes move briskly to where they now lie, without overshooting (Flutter's AnimatedPositioned, easeOutCubic).
class _Bento extends StatelessWidget {
  const _Bento(this.boxes, this.c);
  final List<_Box> boxes;
  final DockCtx c;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // (as many columns as boxes of the size chosen fit, the boxes stretching to fill the row: CLIP STUDIO PAINT's
      //  Color Set at a fixed tile size, as many a row as the palette is wide; CSS Grid's repeat(auto-fill, minmax()).
      //  Laid again only when its columns, its colours or the dice change, and only then do the boxes move; widened
      //  between, they only stretch, nothing laid again: the window's 60 frames a second kept)
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

/// A colour's box: pressed, it colours (or the stop picked, while a gradient is coloured); the hand on it rings its
/// group and tells the group in the shelf's foot; its right-click menu, for one's own, replaces or deletes it.
class _ColorBox extends StatelessWidget {
  const _ColorBox(this.b, this.c);
  final _Box b;
  final DockCtx c;
  @override
  Widget build(BuildContext context) {
    final col = b.colour!, own = b.group == 'mine', pal = _pals.where((p) => p.id == b.group).firstOrNull;
    return MouseRegion(
      onEnter: (_) => _named.value = _hovered.value = b.group,
      onExit: (_) {
        _named.value = _pressed;
        _hovered.value = null;
      },
      child: GestureDetector(
        onSecondaryTapDown: (d) {
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
          _boxMenu.currentState?.show(box?.globalToLocal(d.globalPosition) ?? Offset.zero, items);
        },
        child: DockHover(
          key: ValueKey('colour-box-${b.group}-${b.i}'),
          onTap: () {
            _named.value = _pressed = b.group;
            _take(c, col);
          },
          builder: (context, h) => ValueListenableBuilder<String?>(
            valueListenable: _hovered,
            builder: (context, over, _) {
              // (the hand on a box: a rainbow rim round each box of its palette, so a palette is seen whole with no gap kept round it: the user, a rim, not the others darkened)
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
        ),
      ),
    );
  }
}

/// The colour now kept as one's own (CLIP STUDIO PAINT's colour set: Add Color); a gradient coloured now is kept whole,
/// where its colours stand and how they mix.
void _keepNow(DockCtx c) {
  final stops = _stopsIn(_paintNow(c));
  stops.length > 1
      ? _mineGrads.insert(
          0,
          _Gradient('Gradient ${_mineGrads.length + 1}', [for (final s in stops) s.$1], at: [for (final s in stops) s.$2], blend: _blendNow(c), saved: true),
        )
      : _mineColors.insert(0, _wheel.toColor()); // (at the top, as the newest)
  _keepMine();
}

/// The dice: a die's face of five; pressed, the boxes are thrown again.
class _Dice extends StatelessWidget {
  const _Dice(this.onTap);
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => DockHover(
    key: const ValueKey('colour-dice'),
    onTap: onTap,
    builder: (context, h) => Container(
      width: Shape.z(22),
      height: Shape.z(22),
      decoration: BoxDecoration(color: h ? WsT.raised : WsT.well, borderRadius: BorderRadius.all(Shape.r(5))),
      child: CustomPaint(painter: _DiePaint(h ? Grey.g95 : Grey.g76)),
    ),
  );
}

class _DiePaint extends CustomPainter {
  const _DiePaint(this.ink);
  final Color ink;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = ink, d = s.width / 4.5;
    for (final o in const [Offset(-1, -1), Offset(1, -1), Offset(0, 0), Offset(-1, 1), Offset(1, 1)]) {
      c.drawCircle(s.center(Offset.zero) + o * d, s.width / 14, p);
    }
  }

  @override
  bool shouldRepaint(_DiePaint o) => o.ink != ink;
}

/// A gradient's colours and where each stands, as the document says its fill ("ff3366@0.35 ..."; one with no @ stands
/// evenly), and back.
List<(Color, double)> _stopsIn(String word) {
  final parts = word.split(' ').where((w) => w.isNotEmpty).toList();
  if (parts.length < 2) return const [];
  final out = <(Color, double)>[];
  for (final (i, w) in parts.indexed) {
    final hex = w.split('@').first, v = int.tryParse(hex, radix: 16);
    if (v == null || (hex.length != 6 && hex.length != 8)) return const [];
    out.add((
      hex.length == 8 ? Color(((v & 0xFF) << 24) | (v >> 8)) : Color(0xFF000000 | v),
      w.contains('@') ? (double.tryParse(w.split('@').last) ?? 0).clamp(0.0, 1.0) : i / (parts.length - 1),
    ));
  }
  return out;
}

String _wordOfStops(List<(Color, double)> stops) {
  String hex8(Color c) => _hex(c).substring(1).toLowerCase() + (c.a < 1 ? (c.a * 255).round().toRadixString(16).padLeft(2, '0') : '');
  return [
    for (final (col, at) in [...stops]..sort((a, b) => a.$2.compareTo(b.$2))) '${hex8(col)}@${at.toStringAsFixed(3)}',
  ].join(' ');
}

int _stop = 0; // (the stop the picker colours)

/// The gradient being coloured, its bar and its stops beneath (Figma's and Canva's gradient editors): a press on the
/// bar puts a stop there in the colour the bar has there; a stop pressed is the one the square above colours; a stop
/// carried along the bar moves; Remove takes the picked one out (two stay at least).
class _Stops extends StatefulWidget {
  const _Stops(this.stops, this.onChanged, this.onPick, {this.onDrag});
  final List<(Color, double)> stops;
  final ValueChanged<List<(Color, double)>> onChanged;
  final ValueChanged<int> onPick;
  final ValueChanged<bool>? onDrag; // (a hand down on it, and up: one step)
  @override
  State<_Stops> createState() => _StopsState();
}

class _StopsState extends State<_Stops> {
  List<(Color, double)>? _held; // (while a stop is carried: where the hand has it)

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
                    widget.onPick(s.where((e) => e.$2 <= x).length); // (where it stands among them: the document keeps them in order)
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
                      widget.onPick(held.where((e) => e.$2 < at).length); // (carried past another, it is picked where it now stands)
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

/// A gradient, a small tile of it: its name is said when the hand is on it, as a swatch's (the colours are what is
/// looked for, and the tiles keep to a block however many are kept).
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
      child: GestureDetector(
        onSecondaryTapDown: !g.saved
            ? null
            : (d) {
                // (one's own gradient's menu: deleted, as one's own colour)
                final box = _boxMenu.currentContext?.findRenderObject() as RenderBox?;
                _boxMenu.currentState?.show(box?.globalToLocal(d.globalPosition) ?? Offset.zero, [
                  WsMenuItem(
                    'Delete this gradient',
                    () => c.set(() {
                      _mineGrads.remove(g);
                      _keepMine();
                    }),
                  ),
                ]);
              },
        child: DockHover(
          key: ValueKey('colour-$id'),
          onTap: () => _putGradient(c, g.colors, g.blend, g.at), // (a press puts it on, where its colours stand and mixed as it was kept)
          builder: (context, h) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: look, stops: at),
              borderRadius: BorderRadius.all(Shape.r(5)),
              border: _wheelFrom == word ? Border.all(color: Grey.g95, width: 2) : (h ? Border.all(color: Grey.g76) : null),
            ),
          ),
        ),
      ),
    );
  }
}
