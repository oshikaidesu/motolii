// The Source card's inside: a filmstrip of the video's file, with the in-point (begin) marked where play starts.
// Take the marker along the strip to slip the clip, as Premiere Pro's Slip and the pale bar in Motolii's timeline do.
// The "In" number stays below as the card's tile, so a value may also be typed.
import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/skin/tokens.dart';

/// The Source card's inside (see host_cards.dart).
class FilmStrip extends StatefulWidget {
  const FilmStrip(this.card, {super.key});
  final CardDeclaration card;

  static double get height => Shape.z(44);

  @override
  State<FilmStrip> createState() => _FilmStripState();
}

class _FilmStripState extends State<FilmStrip> {
  bool _held = false, _near = false;

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final begin = {for (final p in widget.card.params) p.id: p}['begin'];
    final lo = begin?.min ?? 0, hi = begin?.max ?? 60;
    final span = hi - lo <= 0 ? 60.0 : hi - lo;
    return ListenableBuilder(
      listenable: doc.watch('v_begin'),
      builder: (context, _) => Padding(
        padding: EdgeInsets.only(bottom: Shape.s(6)),
        child: LayoutBuilder(
          builder: (context, box) {
            const pad = 10.0;
            final w = box.maxWidth;
            double xOf(double s) =>
                pad + ((s - lo) / span).clamp(0.0, 1.0) * (w - pad * 2);
            double sOf(double x) =>
                lo + ((x - pad) / (w - pad * 2)).clamp(0.0, 1.0) * span;
            final at = doc.get('v_begin') ?? lo;
            return MouseRegion(
              cursor: _held || _near
                  ? SystemMouseCursors.grab
                  : MouseCursor.defer,
              onHover: (e) {
                final n = (e.localPosition.dx - xOf(at)).abs() <= 14;
                if (n != _near) setState(() => _near = n);
              },
              onExit: (_) => setState(() => _near = false),
              child: Listener(
                onPointerDown: (e) {
                  if (e.buttons != kPrimaryButton) return;
                  doc.beginGesture();
                  setState(() => _held = true);
                  doc.set('v_begin', sOf(e.localPosition.dx));
                },
                onPointerMove: (e) {
                  if (!_held) return;
                  doc.set('v_begin', sOf(e.localPosition.dx));
                },
                onPointerUp: (_) => _let(),
                onPointerCancel: (_) => _let(),
                child: CustomPaint(
                  key: const ValueKey('film-strip'),
                  size: Size(w, FilmStrip.height),
                  painter: _FilmPaint(
                    at: xOf(at),
                    pad: pad,
                    lit: _held || _near,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _let() {
    if (!_held) return;
    InspectorScope.of(context).doc.endGesture();
    setState(() => _held = false);
  }
}

class _FilmPaint extends CustomPainter {
  const _FilmPaint({required this.at, required this.pad, required this.lit});
  final double at, pad;
  final bool lit;

  @override
  void paint(Canvas c, Size s) {
    final body = RRect.fromRectAndRadius(Offset.zero & s, Shape.r(8));
    c.drawRRect(body, Paint()..color = Grey.g07);
    // The sprockets, top and bottom, and the frame lines, so the strip reads as film.
    final hole = Paint()..color = Grey.g15;
    const holeW = 7.0, holeH = 4.0;
    for (var x = pad; x < s.width - pad; x += 16) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 4, holeW, holeH),
          const Radius.circular(1.5),
        ),
        hole,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, s.height - 4 - holeH, holeW, holeH),
          const Radius.circular(1.5),
        ),
        hole,
      );
    }
    final frame = Paint()
      ..color = Grey.g20
      ..strokeWidth = 1;
    for (var x = pad + 24; x < s.width - pad; x += 24) {
      c.drawLine(Offset(x, 12), Offset(x, s.height - 12), frame);
    }
    // The part that plays, from the in-point on, lifted so the slip reads.
    c.save();
    c.clipRRect(body);
    c.drawRect(
      Rect.fromLTRB(at, 11, s.width - pad, s.height - 11),
      Paint()..color = Accent.fill.withValues(alpha: .12),
    );
    c.restore();
    // The in-point: a bright bar with a grip, taken along the strip to slip the clip.
    final ink = lit ? Accent.fill : Grey.g76;
    c.drawLine(
      Offset(at, 8),
      Offset(at, s.height - 8),
      Paint()
        ..color = ink
        ..strokeWidth = 2,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(at, s.height / 2),
          width: lit ? 9 : 7,
          height: lit ? 16 : 13,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = ink,
    );
  }

  @override
  bool shouldRepaint(_FilmPaint o) => o.at != at || o.lit != lit;
}
