// The Media card's inside: a filmstrip with the clip in-point (begin) scrub
// handle, speed-scaled frame density, and the discrete Hold-at anchor pin
// hosted inside the well as a glass pill.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/handle_drag.dart';
import 'package:motolii/inspector/controls/parameter_tile.dart';
import 'package:motolii/inspector/controls/well_pill.dart'
    show WellPill, maybeTip;
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/paint_helpers.dart' show drawWell;

/// The Media card's inside (see host_cards.dart).
class FilmStrip extends StatelessWidget {
  const FilmStrip(this.card, {super.key});
  final CardDeclaration card;

  static const Set<String> drawn = {'speed_hold'};

  static double get height => Shape.z(52);

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final byId = {for (final p in card.params) p.id: p};
    final begin = byId['begin'];
    final holdP = byId['speed_hold'];
    if (begin == null) {
      if (holdP == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(bottom: Shape.s(4)),
        child: ParameterTile(holdP),
      );
    }
    final lo = begin.min ?? 0, hi = begin.max ?? 60;
    final span = hi - lo <= 0 ? 60.0 : hi - lo;
    final holdOpts = holdP?.options ?? const <String>[];

    return ListenableBuilder(
      listenable: Listenable.merge([
        doc.watch('v_begin'),
        doc.watch('v_speed'),
        doc.watch('v_speed_hold'),
      ]),
      builder: (context, _) {
        final at = doc.get('v_begin') ?? lo;
        final speed = doc.get('v_speed') ?? 1.0;
        final holdIdx = holdOpts.isEmpty
            ? 0
            : (doc.get('v_speed_hold') ?? holdP!.def).round().clamp(
                0,
                holdOpts.length - 1,
              );
        final holdWord = holdOpts.elementAtOrNull(holdIdx)?.toLowerCase() ?? '';
        final holdPin = switch (holdWord) {
          'start' => 0,
          'end' => 2,
          _ => 1, // playhead
        };
        final holdLabel = _cap(holdWord.isEmpty ? 'playhead' : holdWord);

        return Padding(
          padding: EdgeInsets.only(bottom: Shape.s(4)),
          child: SizedBox(
            height: FilmStrip.height,
            child: LayoutBuilder(
              builder: (context, box) {
                const pad = 10.0;
                final w = box.maxWidth;
                double xOf(double s) =>
                    pad + ((s - lo) / span).clamp(0.0, 1.0) * (w - pad * 2);
                double sOf(double x) =>
                    lo + ((x - pad) / (w - pad * 2)).clamp(0.0, 1.0) * span;
                return Stack(
                  children: [
                    HandleDrag(
                      near: (p) => (p.dx - xOf(at)).abs() <= 14,
                      onDrag: (p) => doc.set('v_begin', sOf(p.dx)),
                      builder: (lit) => CustomPaint(
                        key: const ValueKey('film-strip'),
                        size: Size(w, FilmStrip.height),
                        painter: _FilmPaint(
                          at: xOf(at),
                          pad: pad,
                          speed: speed,
                          holdPin: holdOpts.isEmpty ? null : holdPin,
                          lit: lit,
                        ),
                      ),
                    ),
                    if (holdOpts.length >= 2)
                      Positioned(
                        right: 12,
                        top: (FilmStrip.height - Shape.z(20)) / 2,
                        child: maybeTip(
                          context,
                          'Hold at $holdLabel when speed changes',
                          WellPill(
                            key: const ValueKey('choice:speed_hold'),
                            label: holdLabel,
                            icon: (c, s, col) =>
                                _drawHoldPinGlyph(c, s, col, pin: holdPin),
                            onTap: () {
                              final next = (holdIdx + 1) % holdOpts.length;
                              doc
                                ..beginGesture()
                                ..set('v_speed_hold', next.toDouble())
                                ..endGesture();
                            },
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

void _drawHoldPinGlyph(Canvas c, Size s, Color col, {required int pin}) {
  final y = s.height * 0.55;
  final line = Paint()
    ..color = col.withValues(alpha: 0.5)
    ..strokeWidth = 1.1
    ..strokeCap = StrokeCap.round;
  c.drawLine(Offset(1.5, y), Offset(s.width - 1.5, y), line);
  final x = switch (pin) {
    0 => 2.0,
    2 => s.width - 2.0,
    _ => s.width * 0.5,
  };
  final pinPaint = Paint()
    ..color = col
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  c
    ..drawLine(Offset(x, 2), Offset(x, s.height - 1.5), pinPaint)
    ..drawCircle(Offset(x, 2.2), 1.6, Paint()..color = col);
}

class _FilmPaint extends CustomPainter {
  const _FilmPaint({
    required this.at,
    required this.pad,
    required this.speed,
    required this.holdPin,
    required this.lit,
  });
  final double at, pad, speed;
  final int? holdPin;
  final bool lit;

  @override
  void paint(Canvas c, Size s) {
    final body = drawWell(c, s);
    // Sprockets top and bottom so the strip reads as film.
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
    // Frame divisions compress/expand gently with playback speed.
    final step = (24.0 / speed.abs().clamp(0.35, 3.0)).clamp(10.0, 56.0);
    final frame = Paint()
      ..color = Grey.g20
      ..strokeWidth = 1;
    for (var x = pad + step; x < s.width - pad; x += step) {
      c.drawLine(Offset(x, 12), Offset(x, s.height - 12), frame);
    }
    // Active playback span from the in-point onward.
    c.save();
    c.clipRRect(body);
    c.drawRect(
      Rect.fromLTRB(at, 11, s.width - pad, s.height - 11),
      Paint()
        ..color = (speed < 0 ? InspectorSkin.toneTime : Accent.fill).withValues(
          alpha: .12,
        ),
    );
    c.restore();
    // Hold-at anchor marker along the top film rail (Start / Playhead / End).
    if (holdPin case final pin?) {
      final px = switch (pin) {
        0 => pad,
        2 => s.width - pad,
        _ => s.width * 0.5,
      };
      final marker = Path()
        ..moveTo(px - 3.5, 10)
        ..lineTo(px + 3.5, 10)
        ..lineTo(px, 14.5)
        ..close();
      c.drawPath(marker, Paint()..color = Accent.fill.withValues(alpha: 0.85));
    }
    // The in-point: a bright bar with a grip, dragged to slip the clip.
    final ink = lit ? Accent.fill : Grey.g76;
    c.drawLine(
      Offset(at, 9),
      Offset(at, s.height - 9),
      Paint()
        ..color = ink
        ..strokeWidth = 2,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(at, s.height / 2),
          width: lit ? 9 : 7,
          height: lit ? 18 : 14,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = ink,
    );
  }

  @override
  bool shouldRepaint(_FilmPaint o) =>
      o.at != at || o.speed != speed || o.holdPin != holdPin || o.lit != lit;
}
