// The timeline's tracks painted: each row's bar (its band, fill, keys, stretches, film frames, sound wave) and an
// open lane's value line.
part of 'timeline_paint.dart';

Color wtBand(int i, bool selected) => Forms.worn.trackBand(i, selected);

/// The bar's fill: the kind's hue, a step quieter when not selected; a hidden or soloed-out layer drops to grey.
Color wtBarFill(WtRow r) => Forms.worn.trackFill(r.tone ?? wsTone(r.kind), dim: r.dim, selected: r.selected);

// A way drawn from x [xa] to [xb]: as fine as the screen shows, where it is on the screen. What is left at 192 steps is more
// than a short stretch has pixels for, and a long one still has its curve; Skia draws a curve as such lines too.
void _wayLine(Path p, List<double> way, double xa, double xb, double width, double Function(double) y) {
  final n = way.length - 1, wide = xb - xa;
  if (wide <= 0) return;
  final every = math.max(1, (n * 1.5 / wide).floor());
  final from = ((-xa / wide * n).floor() - every).clamp(0, n), to = (((width - xa) / wide * n).ceil() + every).clamp(0, n);
  for (var i = from + every; i < to; i += every) {
    p.lineTo(xa + wide * i / n, y(way[i]));
  }
  p.lineTo(xa + wide * to / n, y(way[to]));
}

class WtTracksPainter extends CustomPainter {
  const WtTracksPainter({required this.rows, required this.view, required this.fps, required this.vscroll, this.tempo, this.restAt});
  final WsBeats? tempo;
  final int? restAt; // (where the hand has come to rest: Alight Motion's SnapLine)
  final List<WtRow> rows;
  final WtView view;
  final int fps;
  final double vscroll;

  @override
  void paint(Canvas c, Size s) {
    c.clipRect(Offset.zero & s);
    final p = Paint(), end = view.x(Ws.duration);
    c.drawRect(Offset.zero & s, p..color = WsT.body);
    for (var i = 0; i < rows.length; i++) {
      final top = i * WtM.row - vscroll;
      if (top > s.height || top + WtM.row < 0) continue;
      c.drawRect(Rect.fromLTWH(0, top, s.width, WtM.row - 1), p..color = wtBand(i, rows[i].selected));
      c.drawRect(Rect.fromLTWH(0, top + WtM.row - 1, s.width, 1), p..color = Grey.rowLine);
    }
    if (end < s.width) c.drawRect(Rect.fromLTRB(end, 0, s.width, s.height), p..color = WsT.body);
    _vLines(c, view, fps, math.min(s.width, end), 0, s.height, major: Grey.g20, fine: Grey.g15);
    for (var i = 0; i < rows.length; i++) {
      final top = i * WtM.row - vscroll;
      if (top > s.height || top + WtM.row < 0) continue;
      _row(c, s, rows[i], top + WtM.row / 2 - .5);
    }
    if (restAt case final f?) c.drawRect(Rect.fromLTWH(view.x(f).roundToDouble(), 0, 1, s.height), p..color = WsT.accent);
  }

  void _row(Canvas c, Size s, WtRow r, double cy) {
    if (r.lane case final pts?) return pts.isEmpty ? null : _lane(c, s, r, pts, cy); // (empty: a row that only says what it aims at)
    final p = Paint(), x0 = view.x(r.inF), x1 = math.max(view.x(r.outF), x0 + 4), h = Forms.worn.trackBar(selected: r.selected);
    if (r.whole case (final a, final b)?) {
      c.drawRect(Rect.fromLTRB(view.x(a), cy - h / 2, view.x(b), cy + h / 2), p..color = wtBarFill(r).withValues(alpha: .18));
    }
    if (x1 < 0 || x0 > s.width) return;
    final bar = Rect.fromLTRB(x0, cy - h / 2, x1, cy + h / 2), rr = RRect.fromRectAndRadius(bar, Radius.circular(Forms.worn.trackRadius));
    final fill = wtBarFill(r), ink = r.dim ? Grey.g56 : WsT.onAccent, grip = Color.lerp(fill, Grey.g00, .28)!;
    final mix = r.mix;
    if (mix != null && mix.length > 1 && !r.dim) {
      // (a relation: its things' colours side by side, blended)
      c.drawRRect(
        rr,
        Paint()..shader = LinearGradient(colors: [for (final m in mix) r.selected ? Color.lerp(m, const Color(0xFFFFFFFF), .18)! : m]).createShader(bar),
      );
    } else {
      c.drawRRect(rr, p..color = fill);
    }
    c.save();
    c.clipRRect(rr);
    c.drawRect(Rect.fromLTWH(x0, bar.top, 5, bar.height), p..color = grip); // (the ends a hand cuts the bar by: wide, with a light notch)
    c.drawRect(Rect.fromLTWH(x1 - 5, bar.top, 5, bar.height), p..color = grip);
    final notch = ink.withAlpha(r.selected ? 200 : 120);
    c.drawRect(Rect.fromLTWH(x0 + 2, bar.top + 4, 1.5, bar.height - 8), p..color = notch);
    c.drawRect(Rect.fromLTWH(x1 - 3.5, bar.top + 4, 1.5, bar.height - 8), p..color = notch);
    if (r.frames case final f? when f.length == 1) {
      // (a photo: itself again and again along the bar at its own shape, as Alight Motion's photo bar)
      final im = f.single, step = math.max(4.0, bar.height * im.width / math.max(1, im.height));
      for (var x = bar.left + 5; x < bar.right - 5; x += step) {
        paintImage(
          canvas: c,
          rect: Rect.fromLTWH(x, bar.top, step, bar.height),
          image: im,
          fit: BoxFit.cover,
          opacity: r.dim ? .35 : .8,
          filterQuality: FilterQuality.low,
        );
      }
    } else if (r.frames case final f? when f.isNotEmpty) {
      // (each picture filling its part of the bar, its middle kept: a strip of frames, as Alight Motion's)
      final step = (bar.width - 10) / f.length;
      for (final (i, im) in f.indexed) {
        final at = Rect.fromLTWH(bar.left + 5 + i * step, bar.top, step, bar.height);
        paintImage(canvas: c, rect: at, image: im, fit: BoxFit.cover, opacity: r.dim ? .35 : .8, filterQuality: FilterQuality.low);
      }
    }
    if (r.wave case final w?) _wave(c, bar, ink, fill, r.inF, w);
    if (r.clipped) {
      // (↘: cut to the one under it)
      final at = Offset(math.max(x0 + 8, 6.0), cy - 4),
          arrow = Paint()
            ..color = ink
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
      c.drawLine(at, at + const Offset(7, 7), arrow);
      c.drawPath(
        Path()
          ..moveTo(at.dx + 7, at.dy + 3)
          ..lineTo(at.dx + 7, at.dy + 7)
          ..lineTo(at.dx + 3, at.dy + 7),
        arrow,
      );
    }
    final nameX = math.max(x0 + 8, 6.0) + (r.clipped ? 12 : 0);
    final t = _text(r.name, T.name(ink).copyWith(fontWeight: FontWeight.w700));
    if (nameX + 20 < x1) {
      if (r.wave != null || r.frames != null) {
        c.drawRRect(
          RRect.fromLTRBR(nameX - 4, cy - 6.5, nameX + t.width + 4, cy + 6.5, Shape.r(3)),
          p..color = fill,
        ); // (its name on its own ground, over its sound or its pictures)
      }
      c.save();
      c.clipRect(Rect.fromLTRB(nameX, bar.top, x1 - 6, bar.bottom));
      t.paint(c, Offset(nameX, cy - t.height / 2));
      c.restore();
    }
    t.dispose();
    if (r.locked) {
      for (var x = x0 - bar.height; x < x1; x += 6) {
        c.drawLine(
          Offset(x, bar.bottom),
          Offset(x + bar.height, bar.top),
          Paint()
            ..color = grip
            ..strokeWidth = 1,
        );
      }
    }
    c.restore();
    if (r.selected && !r.dim) {
      c.drawRRect(
        rr.deflate(.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Grey.g100,
      );
    }
    for (final st in r.stretches) {
      // (each stretch's way, from its key to the next, as a line inside the bar: how it goes there)
      final xa = view.x(st.from), xb = view.x(st.to);
      if (xb - xa < 6 || xb < 0 || xa > s.width) continue;
      final h = bar.height * .62, base = cy + h / 2;
      final line = Path()..moveTo(xa, base - st.shape.first.clamp(-.5, 1.5) * h);
      _wayLine(line, st.shape, xa, xb, s.width, (v) => base - v.clamp(-.5, 1.5) * h);
      c.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true
          ..color = Color.lerp(fill, Grey.g100, r.dim ? .25 : .6)!,
      ); // (Ableton's automation line: one thin line, the bar's own colour made lighter)
    }
    for (final k in r.keys) {
      final x = view.x(k);
      if (x < -8 || x > s.width + 8) continue;
      final on = r.picked.contains(k);
      final rad = on ? WtM.keyPicked : WtM.key;
      final d = Path()
        ..moveTo(x, cy - rad)
        ..lineTo(x + rad, cy)
        ..lineTo(x, cy + rad)
        ..lineTo(x - rad, cy)
        ..close();
      if (on) {
        c.drawPath(d, p..color = WsT.keyDot);
        c.drawPath(
          d,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeJoin = StrokeJoin.miter
            ..color = WsT.onAccent,
        );
      } else {
        c.drawPath(d, p..color = r.dim ? Grey.g44 : WsT.onAccent);
        c.drawPath(
          d,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = r.dim ? Grey.g26 : Color.lerp(fill, Grey.g100, .55)!,
        );
      }
    }
  }

  /// A value's lane, as Ableton draws an envelope in its own lane (Live 12 manual 25.5): its keys as breakpoints at
  /// their values, lowest at the bottom, joined as each goes there (its way's shape: Ableton draws a curved segment
  /// curved, 25.5.2; the bar's own stretches the same), and nothing before the first or after the last: with many lanes
  /// a line across the whole row tells nothing (the maker, 11/1; Theatre.js's connector goes from key to key); the line
  /// in the bar's colour made lighter, as the bar's own automation line (golf_noise.md ⑫: it was straight whatever the ease).
  void _lane(Canvas c, Size s, WtRow r, List<(int, double)> pts, double cy) {
    final top = cy - WtM.row / 2 + 4, h = WtM.row - 9, col = Color.lerp(wtBarFill(r), Grey.g100, r.dim ? .25 : .6)!;
    Offset at((int, double) q) => Offset(view.x(q.$1), top + (1 - q.$2) * h);
    final line = Path()..moveTo(at(pts.first).dx, at(pts.first).dy);
    for (var i = 0; i < pts.length; i++) {
      final a = at(pts[i]), way = i + 1 < pts.length ? r.laneWays?.elementAtOrNull(i) : null;
      line.lineTo(a.dx, a.dy);
      if (way == null) continue;
      final b = at(pts[i + 1]);
      _wayLine(line, way, a.dx, b.dx, s.width, (v) => (a.dy + (b.dy - a.dy) * v).clamp(top - 3, top + h + 3)); // (an overshoot kept within its own lane)
    }
    if (r.laneOn case final i? when i + 1 < pts.length) {
      c.drawRect(
        Rect.fromLTRB(at(pts[i]).dx, cy - WtM.row / 2, at(pts[i + 1]).dx, cy + WtM.row / 2),
        Paint()..color = WsT.accent.withValues(alpha: .18),
      ); // (Theatre.js's connector, lit while it is what the curve editor holds)
    }
    c.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color = col,
    );
    for (final q in pts) {
      c.drawCircle(at(q), WtM.key * .75, Paint()..color = col);
    }
  }

  /// Its sound as the inside reads it: -60 dB to full across the bar's height, the loudest of each two points.
  void _wave(Canvas c, Rect bar, Color ink, Color fill, int inF, List<double> db) {
    final p = Paint()..color = Color.lerp(fill, ink, .7)!;
    final h = bar.height - 4, cy = bar.center.dy;
    for (var x = math.max(bar.left + 4, 0.0); x < bar.right - 4; x += 2) {
      final a0 = view.frameAt(x).floor() - inF, a1 = view.frameAt(x + 2).ceil() - inF;
      var loud = -100.0;
      for (var k = math.max(a0, 0); k <= a1 && k < db.length; k++) {
        if (db[k] > loud) loud = db[k];
      }
      final a = ((loud + 60) / 60).clamp(0.0, 1.0);
      if (a > 0) c.drawRect(Rect.fromCenter(center: Offset(x.roundToDouble(), cy), width: 1, height: (a * h).roundToDouble().clamp(1, h)), p);
    }
  }

  @override
  bool shouldRepaint(WtTracksPainter o) => o.view != view || o.fps != fps || o.vscroll != vscroll || o.restAt != restAt || !_listEq(o.rows, rows);
}

// ---------------------------------------------------------------- playhead
