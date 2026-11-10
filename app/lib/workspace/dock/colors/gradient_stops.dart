// A gradient as its fill word and as a bar with stops to edit.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/hex_color.dart' show colorOfHex;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/dock/colors/color_palette.dart';
import 'package:motolii/workspace/dock/colors/colors_controller.dart';

/// Parses a gradient's fill word, such as "ff3366@0.35 ...", into colors and their positions.
/// A color without @ is spaced evenly. Returns an empty list if the word is not a gradient.
List<(Color, double)> stopsIn(String word) {
  final parts = word.split(' ').where((w) => w.isNotEmpty).toList();
  if (parts.length < 2) return const [];
  final out = <(Color, double)>[];
  for (final (i, w) in parts.indexed) {
    final col = colorOfHex(w.split('@').first);
    if (col == null) return const [];
    out.add((
      col,
      w.contains('@')
          ? (double.tryParse(w.split('@').last) ?? 0).clamp(0.0, 1.0)
          : i / (parts.length - 1),
    ));
  }
  return out;
}

/// The inverse of [stopsIn]: writes the stops back as a fill word.
String wordOfStops(List<(Color, double)> stops) {
  String hex8(Color c) =>
      hexOfColor(c).substring(1).toLowerCase() +
      (c.a < 1 ? (c.a * 255).round().toRadixString(16).padLeft(2, '0') : '');
  return [
    for (final (col, at) in [...stops]..sort((a, b) => a.$2.compareTo(b.$2)))
      '${hex8(col)}@${at.toStringAsFixed(3)}',
  ].join(' ');
}

/// The gradient editor: a bar with its stops beneath, as in Figma and Canva.
/// - Pressing the bar adds a stop there, in the color the bar has at that point.
/// - Pressing a stop selects it, and the square above then edits its color.
/// - Dragging a stop along the bar moves it.
/// - Remove deletes the selected stop, but at least two stay.
class GradientStops extends StatefulWidget {
  const GradientStops(
    this.colors,
    this.stops,
    this.onChanged,
    this.onPick, {
    super.key,
    this.onDrag,
  });

  /// What the shelf keeps between builds: the stop the picker edits is the one marked.
  final ColorsController colors;

  /// The gradient's colors and where each sits along the bar, from 0 to 1.
  final List<(Color, double)> stops;

  /// Called with the new stops when one is added or moved.
  final ValueChanged<List<(Color, double)>> onChanged;

  /// Called with the index of the stop the user pressed, added or dragged.
  final ValueChanged<int> onPick;

  /// Called with true when a drag starts and false when it ends, so the caller can make it one undo step.
  final ValueChanged<bool>? onDrag;
  @override
  State<GradientStops> createState() => _GradientStopsState();
}

class _GradientStopsState extends State<GradientStops> {
  List<(Color, double)>?
  _held; // The stops as they are while one is being dragged.

  Color _at(List<(Color, double)> s, double x) {
    final sorted = [...s]..sort((a, b) => a.$2.compareTo(b.$2));
    if (x <= sorted.first.$2) return sorted.first.$1;
    for (var i = 1; i < sorted.length; i++) {
      if (x <= sorted[i].$2) {
        return Color.lerp(
          sorted[i - 1].$1,
          sorted[i].$1,
          (x - sorted[i - 1].$2) /
              math.max(1e-6, sorted[i].$2 - sorted[i - 1].$2),
        )!;
      }
    }
    return sorted.last.$1;
  }

  @override
  Widget build(BuildContext context) {
    final s = _held ?? widget.stops,
        sorted = [...s]..sort((a, b) => a.$2.compareTo(b.$2)),
        knob = Shape.z(12);
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
                      gradient: LinearGradient(
                        colors: [for (final e in sorted) e.$1],
                        stops: [for (final e in sorted) e.$2],
                      ),
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
                      held[i] = (
                        held[i].$1,
                        (held[i].$2 + d.delta.dx / w).clamp(0.0, 1.0),
                      );
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
                        border: Border.all(
                          color: i == widget.colors.stop ? Grey.g95 : Grey.g44,
                          width: i == widget.colors.stop ? 2 : 1,
                        ),
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
