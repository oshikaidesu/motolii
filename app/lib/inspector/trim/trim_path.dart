// The Trim Paths card's inside: a sample path, the part left after the trim drawn bright between its start and its
// end and slid along by the offset, round the end and back in at the beginning, as After Effects' Trim Paths does.
// Take an end to cut there, take the bright part to slide it. The card's numbers stay below as its tiles. The
// drawing came back from before 52289b693 (inspector_trim.dart), on a curve instead of a straight line.
import 'dart:ui' show PathMetric;

import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/transform/transform_layout.dart'
    show TransformZone;
import 'package:motolii/skin/tokens.dart';

/// The Trim Paths card's inside (see host_cards.dart).
class TrimPath extends StatefulWidget {
  const TrimPath(this.card, {super.key});
  final CardDeclaration card;

  /// The values the drawing pulls. Their tiles stay on the card, so none is listed as drawn.
  static const pulls = ['v_trim', 'v_trim_begin', 'v_trim_offset'];

  static double get height => Shape.z(56);

  @override
  State<TrimPath> createState() => _TrimPathState();
}

// both: the two knobs on one spot, until the hand's first move says which.
enum _Part { begin, end, both, slide }

class _TrimPathState extends State<TrimPath> {
  _Part? _held, _near;
  // Where along the path the hand took the bright part, 0 to 1.
  double _from = 0;

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    return ListenableBuilder(
      listenable: Listenable.merge([
        for (final id in TrimPath.pulls) doc.watch(id),
      ]),
      builder: (context, _) => Padding(
        padding: EdgeInsets.only(bottom: Shape.s(6)),
        child: LayoutBuilder(
          builder: (context, box) {
            // The card counts in hundredths: trim is what is cut off the end, the offset is in turns.
            final g = TrimView(
              Size(box.maxWidth, TrimPath.height),
              begin: (doc.get('v_trim_begin') ?? 0) / 100,
              end: 1 - (doc.get('v_trim') ?? 0) / 100,
              slide: (doc.get('v_trim_offset') ?? 0) / 100,
            );
            _Part? pick(Offset p) {
              final b = (p - g.at(g.begin + g.slide)).distance <= 9,
                  e = (p - g.at(g.end + g.slide)).distance <= 9;
              if (b && e) return _Part.both;
              if (b) return _Part.begin;
              if (e) return _Part.end;
              final u = g.along(p);
              return (p - g.at(u)).distance <= 10 && g.kept(u)
                  ? _Part.slide
                  : null;
            }

            return MouseRegion(
              cursor: _held == _Part.slide
                  ? SystemMouseCursors.grabbing
                  : _near == null
                  ? MouseCursor.defer
                  : _near == _Part.slide
                  ? SystemMouseCursors.grab
                  : SystemMouseCursors.resizeLeftRight,
              onHover: (e) {
                final n = pick(e.localPosition);
                if (n != _near) setState(() => _near = n);
              },
              onExit: (_) => setState(() => _near = null),
              child: Listener(
                onPointerDown: (e) {
                  if (e.buttons != kPrimaryButton) return;
                  final h = pick(e.localPosition);
                  if (h == null) return;
                  _from = g.along(e.localPosition);
                  doc.beginGesture();
                  setState(() => _held = h);
                },
                onPointerMove: (e) => _move(doc, g, g.along(e.localPosition)),
                onPointerUp: (_) => _let(doc),
                onPointerCancel: (_) => _let(doc),
                child: CustomPaint(
                  key: const ValueKey('trim-path'),
                  size: g.size,
                  painter: _TrimPaint(g, _held ?? _near),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _move(InspectorValues doc, TrimView g, double u) {
    if (_held == _Part.both && u != _from) {
      _held = u > _from ? _Part.end : _Part.begin;
    }
    switch (_held) {
      case _Part.begin:
        doc.set(
          'v_trim_begin',
          TrimView.wrap(u - g.slide).clamp(0.0, g.end) * 100,
        );
      case _Part.end:
        doc.set(
          'v_trim',
          (1 - TrimView.wrap(u - g.slide)).clamp(0.0, 1 - g.begin) * 100,
        );
      case _Part.slide:
        // From the value as it is now: the drawing may not be drawn again between two moves.
        doc.set(
          'v_trim_offset',
          (doc.get('v_trim_offset') ?? 0) + (u - _from) * 100,
        );
        _from = u;
      case _Part.both || null:
    }
  }

  void _let(InspectorValues doc) {
    if (_held == null) return;
    doc.endGesture();
    setState(() => _held = null);
  }
}

/// Where the sample path lies in a box of [size] and where a share of it is. [begin] and [end] are the trim's start
/// and end, 0 to 1, and [slide] its offset in turns.
class TrimView {
  TrimView(
    this.size, {
    required this.begin,
    required this.end,
    required this.slide,
  });
  final Size size;
  final double begin, end, slide;
  static const pad = 14.0;

  /// The sample path: one S curve across the box.
  late final Path path = Path()
    ..moveTo(pad, size.height * .72)
    ..cubicTo(
      size.width * .36,
      -size.height * .1,
      size.width * .64,
      size.height * 1.1,
      size.width - pad,
      size.height * .28,
    );
  late final PathMetric _metric = path.computeMetrics().first;

  static double wrap(double u) => u - u.floorToDouble();

  /// The point a share [u] along the path, round the end and back in at the beginning past 1.
  Offset at(double u) => _metric
      .getTangentForOffset(_metric.length * (u == 1 ? 1 : wrap(u)))!
      .position;

  /// The share along the path nearest [p].
  double along(Offset p) {
    var best = 0.0, gap = double.infinity;
    for (var i = 0; i <= 200; i++) {
      final d = (at(i / 200) - p).distanceSquared;
      if (d < gap) (best, gap) = (i / 200, d);
    }
    return best;
  }

  /// Whether the share [u] along the path is in the part left after the trim.
  bool kept(double u) {
    final s = wrap(u - slide);
    return s >= begin && s <= end;
  }

  /// The part left, as one or two stretches of the path: it goes round the end and comes back at the beginning.
  List<(double, double)> get stretches {
    if (end - begin >= 1) return [(0, 1)];
    if (end <= begin) return const [];
    final a = wrap(begin + slide), b = a + (end - begin);
    return b <= 1 ? [(a, b)] : [(a, 1), (0, b - 1)];
  }

  Path part(double a, double b) =>
      _metric.extractPath(_metric.length * a, _metric.length * b);
}

class _TrimPaint extends CustomPainter {
  const _TrimPaint(this.g, this.lit);
  final TrimView g;
  final _Part? lit;

  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, Shape.r(8)),
      Paint()..color = Grey.g07,
    );
    Paint line(Color colour, double width) => Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    // The whole path, faint, then the part left.
    c.drawPath(g.path, line(Grey.g20, 3));
    for (final (a, b) in g.stretches) {
      c.drawPath(
        g.part(a, b),
        line(lit == _Part.slide ? Accent.fill : TransformZone.move.color, 4),
      );
    }
    for (final (k, u) in [
      (_Part.begin, g.begin + g.slide),
      (_Part.end, g.end + g.slide),
    ]) {
      final on = lit == k || lit == _Part.both;
      c.drawCircle(
        g.at(u),
        on ? 6.5 : 5,
        Paint()..color = on ? Accent.fill : TransformZone.lift.color,
      );
    }
    // Which end is the start: a ring round it.
    c.drawCircle(g.at(g.begin + g.slide), 8.5, line(Grey.g56, 1.5));
  }

  @override
  bool shouldRepaint(_TrimPaint o) => true;
}
