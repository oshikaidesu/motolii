// The collage behind the home screen: design-tool marks at every size and angle, under a coloured haze.
import 'dart:math' as math;
import 'dart:ui' show ClipOp;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';

/// The collage behind the whole home screen: the marks of a design tool and of this app, many of them, at every size
/// and a little askew, each overlapping its neighbours, under a shade that keeps it in the background.
/// Rows are counted from the foot of the window and columns from its left, and each place draws from its own seed, so
/// a mark stays where it is when the window is resized.
class HomeCollage extends CustomPainter {
  HomeCollage({
    required this.tones,
    required this.ink,
    required this.ground,
    required this.keep,
  });

  /// The colours of [homeTones].
  final List<Color> tones;
  final Color ink, ground;

  /// The top-left corner of the window that is left empty.
  final Size keep;

  static const _wide = 112.0, _tall = 98.0;
  static const _words = [
    '⌘V',
    'PASTE',
    'RENDER',
    '.wgsl',
    'p5.js',
    '60 FPS',
    'GLSL',
    '.fs',
    'EASE',
    'LOTTIE',
    'KEYFRAME',
    'SHADER',
  ];
  static const _letters = ['Ag', '{ }', 'fx', 'Mo', '&', '</>', '01'];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.clipRect(Offset.zero & keep, clipOp: ClipOp.difference);
    final cols = (size.width / _wide).ceil() + 1,
        rows = (size.height / _tall).ceil() + 1;
    // From the top row down, so that a lower mark lies over the one above it.
    for (var row = rows - 1; row >= 0; row--) {
      for (var col = 0; col < cols; col++) {
        final r = math.Random(row * 7919 + col * 104729 + 5);
        final x =
            (col + (row.isOdd ? .5 : 0) + (r.nextDouble() - .5) * .7) * _wide;
        final y = size.height - (row + .3 + (r.nextDouble() - .5) * .7) * _tall;
        final turn = r.nextInt(3) == 0 ? 0.0 : (r.nextDouble() - .5) * .8;
        final grow = r.nextInt(8) == 0 ? 2.2 : .72 + r.nextDouble() * .8;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(turn);
        canvas.scale(grow);
        _mark(canvas, r);
        canvas.restore();
      }
    }

    // A haze of colour quiets it, in place of a black shade: indigo where the marks begin, turning teal toward the foot
    // of the window. Above that it is the ground's own colour, so nothing shows in the upper part of the window.
    final dim = Color.lerp(tones[2], ground, .82)!;
    final all = Offset.zero & size;
    final from = (keep.height / size.height).clamp(0.0, .8);
    canvas.drawRect(
      all,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ground,
            dim.withValues(alpha: .88),
            dim.withValues(alpha: .5),
          ],
          stops: [from, from + (1 - from) * .45, 1],
        ).createShader(all),
    );
  }

  /// Draws one mark about the origin, roughly a hundred across.
  void _mark(Canvas c, math.Random r) {
    final tone = tones[r.nextInt(tones.length)];
    final fill = Paint()..color = tone;
    final blank = Paint()..color = ground;
    // The line that cuts a solid shape out of whatever lies under it.
    final edge = Paint()
      ..color = ground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    void solid(Path p) {
      c.drawPath(p, fill);
      c.drawPath(p, edge);
    }

    void handle(Offset at) {
      final box = Rect.fromCenter(center: at, width: 7, height: 7);
      c.drawRect(box, blank);
      c.drawRect(box, line);
    }

    void knob(Offset at) {
      c.drawCircle(at, 3.5, blank);
      c.drawCircle(at, 3.5, line);
    }

    void key(double x, bool full) {
      final p = Path()
        ..moveTo(x, -8)
        ..lineTo(x + 8, 0)
        ..lineTo(x, 8)
        ..lineTo(x - 8, 0)
        ..close();
      c.drawPath(p, full ? fill : blank);
      if (!full) c.drawPath(p, line);
    }

    void word(String s, double size, {Color? color, Paint? outline}) {
      final t = lineText(
        s,
        TextStyle(
          fontFamily: TextStyles.sans,
          fontSize: size,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: outline == null ? 1 : -2,
          color: color,
          foreground: outline,
        ),
      );
      t.paint(c, Offset(-t.width / 2, -t.height / 2));
      t.dispose();
    }

    switch (r.nextInt(19)) {
      // A layer in its bounding box.
      case 0:
        final box = Rect.fromCenter(
          center: Offset.zero,
          width: 104,
          height: 66,
        );
        c.drawRect(box, fill);
        c.drawRect(box, line);
        for (final p in [
          box.topLeft,
          box.topRight,
          box.bottomLeft,
          box.bottomRight,
        ]) {
          handle(p);
        }
      // A burst.
      case 1:
        final p = Path();
        for (var i = 0; i < 18; i++) {
          final a = i * math.pi / 9 - math.pi / 2;
          final o = Offset(math.cos(a), math.sin(a)) * (i.isEven ? 50.0 : 37.0);
          i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
        }
        solid(p..close());
      // A stack of discs.
      case 2:
        for (var i = 0; i < 4; i++) {
          final at = Offset(-20.0 + i * 13, -5.0 + i * 3);
          c.drawCircle(at, 34, fill);
          c.drawCircle(at, 34, edge);
        }
      // A triangle.
      case 3:
        solid(
          Path()
            ..moveTo(-46, 40)
            ..lineTo(46, 40)
            ..lineTo(0, -48)
            ..close(),
        );
      // A pen path: two anchors, and the handles that bend the line between them.
      case 4:
        const from = Offset(-56, 34), to = Offset(56, -30);
        const fromPull = Offset(-18, -40), toPull = Offset(6, 22);
        c.drawLine(from, fromPull, line);
        c.drawLine(to, toPull, line);
        c.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..cubicTo(
              fromPull.dx,
              fromPull.dy,
              toPull.dx,
              toPull.dy,
              to.dx,
              to.dy,
            ),
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6,
        );
        knob(fromPull);
        knob(toPull);
        handle(from);
        handle(to);
      // A row of keyframes.
      case 5:
        c.drawLine(const Offset(-62, 0), const Offset(62, 0), line);
        key(-52, true);
        key(-14, false);
        key(22, true);
        key(54, false);
      // Two clips on a timeline, and the playhead across them.
      case 6:
        c.drawRect(const Rect.fromLTWH(-54, -26, 84, 15), fill);
        c.drawRect(const Rect.fromLTWH(-12, -5, 66, 15), blank);
        c.drawRect(const Rect.fromLTWH(-12, -5, 66, 15), line);
        c.drawLine(const Offset(8, -40), const Offset(8, 30), line);
        c.drawRect(const Rect.fromLTWH(3, -46, 10, 8), Paint()..color = ink);
      // Someone else's cursor, with the block that carries their name.
      case 7:
        final p = Path()
          ..moveTo(-30, -30)
          ..lineTo(-30, 2)
          ..lineTo(-21, -6)
          ..lineTo(-8, -6)
          ..close();
        solid(p);
        c.drawRect(const Rect.fromLTWH(-12, 2, 58, 20), fill);
      // A ring.
      case 8:
        c.drawCircle(
          Offset.zero,
          36,
          Paint()
            ..color = tone
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14,
        );
      // Half a disc.
      case 9:
        solid(
          Path()
            ..addArc(
              Rect.fromCircle(center: Offset.zero, radius: 48),
              math.pi,
              math.pi,
            )
            ..close(),
        );
      // A button, outlined.
      case 10:
        final pill = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-56, -16, 112, 32),
          const Radius.circular(16),
        );
        c.drawRRect(pill, blank);
        c.drawRRect(pill, line);
        word(_words[r.nextInt(_words.length)], 12, color: ink);
      // A button, filled.
      case 11:
        final block = const Rect.fromLTWH(-52, -15, 104, 30);
        c.drawRect(block, fill);
        c.drawRect(block, edge);
        word(_words[r.nextInt(_words.length)], 12, color: ground);
      // A grid of dots.
      case 12:
        for (var i = 0; i < 25; i++) {
          c.drawCircle(
            Offset(-40.0 + (i % 5) * 20, -40.0 + (i ~/ 5) * 20),
            2.6,
            Paint()..color = ink,
          );
        }
      // A cross.
      case 13:
        solid(
          Path()
            ..moveTo(-12, -40)
            ..lineTo(12, -40)
            ..lineTo(12, -12)
            ..lineTo(40, -12)
            ..lineTo(40, 12)
            ..lineTo(12, 12)
            ..lineTo(12, 40)
            ..lineTo(-12, 40)
            ..lineTo(-12, 12)
            ..lineTo(-40, 12)
            ..lineTo(-40, -12)
            ..lineTo(-12, -12)
            ..close(),
        );
      // A zigzag.
      case 14:
        final p = Path()..moveTo(-54, 14);
        for (var i = 1; i <= 6; i++) {
          p.lineTo(-54.0 + i * 18, i.isOdd ? -14.0 : 14.0);
        }
        c.drawPath(
          p,
          Paint()
            ..color = tone
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8,
        );
      // A window, with something in it.
      case 15:
        const frame = Rect.fromLTWH(-52, -38, 104, 76);
        c.drawRect(frame, blank);
        c.drawRect(frame, line);
        c.drawLine(const Offset(-52, -22), const Offset(52, -22), line);
        for (var i = 0; i < 3; i++) {
          c.drawCircle(Offset(-43.0 + i * 9, -30), 2.4, Paint()..color = ink);
        }
        c.drawRect(const Rect.fromLTWH(-40, -10, 50, 34), fill);
      // Type in outline.
      case 16 || 17:
        word(
          _letters[r.nextInt(_letters.length)],
          92,
          outline: Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      // A quarter of a disc.
      default:
        solid(
          Path()
            ..moveTo(-40, 40)
            ..lineTo(-40, -40)
            ..arcToPoint(
              const Offset(40, 40),
              radius: const Radius.circular(80),
            )
            ..close(),
        );
    }
  }

  @override
  bool shouldRepaint(HomeCollage old) =>
      !listEquals(old.tones, tones) ||
      old.ink != ink ||
      old.ground != ground ||
      old.keep != keep;
}
