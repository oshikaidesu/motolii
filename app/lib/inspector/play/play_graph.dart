// The Play card's inside: a time graph. The line's slope is the layer's Speed — up is forward, down is reversed,
// flat is held — turning about the point where Speed holds it (its start, the playhead, or its end: speed_hold).
// Take the handle up or down to set the speed, as After Effects' Time-Remap graph is dragged. The Speed, Hold at and
// Frame rate tiles stay below, so a value may also be typed or chosen.
import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/skin/tokens.dart';

/// The Play card's inside (see host_cards.dart).
class PlayGraph extends StatefulWidget {
  const PlayGraph(this.card, {super.key});
  final CardDeclaration card;

  /// The values the graph reads. Their tiles stay on the card, so none is listed as drawn.
  static const pulls = ['v_speed', 'v_speed_hold'];

  static double get height => Shape.z(64);

  @override
  State<PlayGraph> createState() => _PlayGraphState();
}

class _PlayGraphState extends State<PlayGraph> {
  bool _held = false, _near = false;

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final params = {for (final p in widget.card.params) p.id: p};
    final speed = params['speed'];
    if (speed == null) return const SizedBox.shrink();
    final lo = speed.min ?? -4, hi = speed.max ?? 4;
    final span = (hi - lo).abs() < 0.01 ? 8.0 : hi - lo;
    final holdOpts = params['speed_hold']?.options ?? const [];
    return ListenableBuilder(
      listenable: Listenable.merge([
        doc.watch('v_speed'),
        doc.watch('v_speed_hold'),
      ]),
      builder: (context, _) => Padding(
        padding: EdgeInsets.only(bottom: Shape.s(6)),
        child: LayoutBuilder(
          builder: (context, box) {
            const pad = 14.0;
            final w = box.maxWidth, h = PlayGraph.height;
            final holdWord = holdOpts
                .elementAtOrNull((doc.get('v_speed_hold') ?? 0).round())
                ?.toLowerCase();
            // The point Speed turns about: the clip's start at the left, the playhead in the middle, its end at the right.
            final pivotX = switch (holdWord) {
              'start' => pad,
              'end' => w - pad,
              _ => w / 2,
            };
            final midY = h / 2;
            // The handle sits at the far end from the pivot, or the right end when it turns about the middle.
            final handleX = pivotX <= pad + 1 ? w - pad : pad;
            final vunit = (h / 2 - 8) / (span / 2);
            final v = (doc.get('v_speed') ?? 0).clamp(lo, hi);
            final handleY = (midY - v * vunit).clamp(6.0, h - 6);

            void setFrom(double y) {
              final nv = (midY - y.clamp(6.0, h - 6)) / vunit;
              doc.set('v_speed', speed.scrubbed(nv, v, past: false));
            }

            return MouseRegion(
              cursor: _held || _near
                  ? SystemMouseCursors.grab
                  : MouseCursor.defer,
              onHover: (e) {
                final n =
                    (e.localPosition - Offset(handleX, handleY)).distance <= 16;
                if (n != _near) setState(() => _near = n);
              },
              onExit: (_) => setState(() => _near = false),
              child: Listener(
                onPointerDown: (e) {
                  if (e.buttons != kPrimaryButton) return;
                  doc.beginGesture();
                  setState(() => _held = true);
                  setFrom(e.localPosition.dy);
                },
                onPointerMove: (e) {
                  if (_held) setFrom(e.localPosition.dy);
                },
                onPointerUp: (_) => _let(),
                onPointerCancel: (_) => _let(),
                child: CustomPaint(
                  key: const ValueKey('play-graph'),
                  size: Size(w, h),
                  painter: _PlayPaint(
                    pivot: Offset(pivotX, midY),
                    handle: Offset(handleX, handleY),
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

class _PlayPaint extends CustomPainter {
  const _PlayPaint({
    required this.pivot,
    required this.handle,
    required this.pad,
    required this.lit,
  });
  final Offset pivot, handle;
  final double pad;
  final bool lit;

  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, Shape.r(8)),
      Paint()..color = Grey.g07,
    );
    // The time baseline: where Speed is 1 (unchanged).
    final midY = s.height / 2;
    c.drawLine(
      Offset(pad, midY),
      Offset(s.width - pad, midY),
      Paint()
        ..color = Grey.g20
        ..strokeWidth = 1,
    );
    // The line through the pivot, its slope the Speed, drawn across the box.
    final ink = lit ? Accent.fill : Grey.g76;
    final slope = (handle.dx - pivot.dx).abs() < 0.01
        ? 0.0
        : (handle.dy - pivot.dy) / (handle.dx - pivot.dx);
    double yAt(double x) => pivot.dy + slope * (x - pivot.dx);
    c.drawLine(
      Offset(pad, yAt(pad).clamp(2.0, s.height - 2)),
      Offset(s.width - pad, yAt(s.width - pad).clamp(2.0, s.height - 2)),
      Paint()
        ..color = ink
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    // The pivot: a small ring where Speed holds the clip in time.
    c.drawCircle(
      pivot,
      3,
      Paint()
        ..color = Grey.g56
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // The handle, taken up or down to set the speed.
    c.drawCircle(handle, lit ? 6.5 : 5, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_PlayPaint o) =>
      o.handle != handle || o.pivot != pivot || o.lit != lit;
}
