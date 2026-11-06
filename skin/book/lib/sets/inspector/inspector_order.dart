// The order's figure on the Copies card (docs/notes/GROUP_INSPECTOR.md §7 and §9): a group's members (its copies, a
// split text's letters) drawn as they lie, the first to move the brightest, and the order set by touching them: the one
// thing new in moving many by the same hand as one. The inside says where each lies and how much later it moves
// (Doc.onMembers: motolii_members, asked on another isolate, skin/BRIDGE.md Q), so the figure never works the order out.
//   a swipe along them: from the start, from the end; from the very middle out, from the centre; into it, from the edges
//     (GSAP's stagger from, Apple Motion's Sequence Text Direction);
//   a press on one: from that one out, in depth too (GSAP's from: an index; Cinema 4D's Plain Effector Time Offset
//     through a spherical field); its cross, where the point is, pulled to another;
//   a shake: at random, shaken again another seed (GSAP's from: "random");
//   a double press: all together (no delay), within Flutter's own double tap's time.
// 24 high, 72 under the hand (the note §7). Its words say the order, and under the hand what a hand may do there, as
// Blender's status bar says what the mouse does; with no keys, that a key makes them move in order (the note §9).
// Depth is drawn going up and to the right at half its length, a cabinet projection (as technical drawing puts depth on
// paper), its axes drawn by it, so a row going deeper stays a row, and every member is in the figure, on the picture or
// off it (the maker: a handle on the stage is in the way of the others, and out of reach once the camera leaves it).
// Played once, as they will move, whenever the order changes or a hand comes over it.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/widgets.dart';
import 'package:lab_book/sets/inspector/inspector_parts.dart';
import 'package:lab_book/sets/inspector/inspector_pulled.dart';
import 'package:lab_book/tokens.dart';

class OrderDrawing extends StatefulWidget {
  const OrderDrawing({super.key});
  static double get low => Shape.z(24.0);
  static double get high => Shape.z(72.0);
  @override
  State<OrderDrawing> createState() => _OrderDrawingState();
}

/// stagger_from's words as the inside lists them (doc_kinds.h), where the card does not say them.
const orderWords = ['start', 'centre', 'end', 'edges', 'random', 'point'];

class _OrderDrawingState extends State<OrderDrawing> with SingleTickerProviderStateMixin {
  late final AnimationController _play = AnimationController(vsync: this);
  final _path = <Offset>[];
  bool _pulling = false, _over = false, _down = false, _onCross = false;
  Timer? _single;   // (a press waits for a second one before it is a press)
  Offset? _firstPress;
  String _was = '', _asked = '';
  Offset? _hand;   // (where the mouse is over the figure)
  int _ticket = 0;
  List<double> _all = const [];

  @override
  void dispose() {
    _play.dispose();
    _single?.cancel();
    super.dispose();
  }

  // (played once: each member lit as its moment comes, the last a little after; a long order played quicker)
  void _replay(double stagger) {
    if (!mounted) return;
    _play
      ..duration = Duration(milliseconds: (1000 * (math.min(stagger, 3.0) + .35)).round())
      ..forward(from: 0);
  }

  static final _reads = RegExp('stagger|cop|seed|text|split|size|scale|anchor|space|font');
  // (what the members and their order are made of, as the card has it: asked again when it changes, and when the inside
  //  reads the document back, an undo)
  String _of(Doc doc) => [
        for (final e in doc.v.entries) if (_reads.hasMatch(e.key)) '${e.key}=${e.value}',
        for (final e in doc.s2.entries) if (_reads.hasMatch(e.key)) '${e.key}=${e.value}',
      ].join(';');

  @override
  Widget build(BuildContext context) {
    final doc = Ctx.of(context).doc;
    if (doc.onMembers case final ask? when _of(doc) != _asked) {
      _asked = _of(doc);
      final mine = ++_ticket;
      ask().then((all) {
        if (mounted && mine == _ticket) setState(() => _all = all);
      });
    }
    final all = _all, n = all.length ~/ 4;
    if (n < 2) return const SizedBox.shrink();
    final said = doc.cards.where((c) => c.name == 'Copies').firstOrNull?.params.where((p) => p.id == 'stagger_from').firstOrNull?.options ?? const <String>[];
    final words = said.isEmpty ? orderWords : said;
    final stagger = doc.get('v_stagger') ?? 0, from = words[(doc.get('v_stagger_from') ?? 0).round().clamp(0, words.length - 1)];
    final delays = [for (var i = 0; i < n; i++) all[4 * i + 3]];
    final point = (doc.get('v_stagger_x') ?? 0, doc.get('v_stagger_y') ?? 0, doc.get('v_stagger_z') ?? 0);
    final keyed = doc.keys.values.any((k) => k != KeyS.off);
    final told = '$stagger $from ${delays.join(',')}';
    if (told != _was) {
      if (_was.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _replay(stagger));
      _was = told;
    }
    void say({String? to, Map<String, double> also = const {}}) {
      final v = <String, double>{...also};
      if (to != null) {   // (the word with its number, as the Chooser says it: else the card's chooser puts the old word's number back)
        v['v_stagger_from'] = math.max(0, words.indexOf(to)).toDouble();
        doc.s2['v_stagger_from'] = to;
      }
      if (stagger <= 0 && to != null) v['v_stagger'] = .5;   // (an order given to those moving together: half a second, GSAP's own stagger)
      doc.setMany(v);
    }

    final open = _over || _down;
    return MouseRegion(
      cursor: _onCross ? SystemMouseCursors.grab : SystemMouseCursors.click,   // (a hand that may press here; on the cross, one that takes it: macOS's pointing and open hands, as Figma's handles)
      onEnter: (_) {
        setState(() => _over = true);
        _replay(stagger);
      },
      onHover: (e) => setState(() => _hand = e.localPosition),
      onExit: (_) => setState(() {
        _over = false;
        _hand = null;
      }),
      child: Padding(
        padding: EdgeInsets.only(bottom: Shape.s(6)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: open ? OrderDrawing.high : OrderDrawing.low,
          child: LayoutBuilder(builder: (context, box) {
            final f = OrderFigure(all, box.biggest);
            final cross = from == 'point' && stagger > 0 ? f.of(point.$1, point.$2, point.$3) : null;
            void pointAt(int k) => say(to: 'point', also: {'v_stagger_x': all[4 * k], 'v_stagger_y': all[4 * k + 1], 'v_stagger_z': all[4 * k + 2]});
            void pressed(Offset a) {
              if (_single?.isActive ?? false) {   // (the second press: all together)
                _single!.cancel();
                if ((a - _firstPress!).distance <= 16) {
                  doc.set('v_stagger', 0);
                  return;
                }
              }
              _firstPress = a;
              _single = Timer(kDoubleTapTimeout, () => mounted ? pointAt(f.nearest(a)) : null);
            }

            final onCross = cross != null && _hand != null && (_hand! - cross).distance <= 10;
            if (onCross != _onCross) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? setState(() => _onCross = onCross) : null);
            return Pulled(
              takes: (_) => true,
              onDown: (p) {
                setState(() => _down = true);
                _path
                  ..clear()
                  ..add(p);
                _pulling = cross != null && (p - cross).distance <= 10;
                if (_pulling) doc.beginGesture();
              },
              onMove: (p) {
                _path.add(p);
                if (_pulling && (p - _path.first).distance >= 4) pointAt(f.nearest(p));
              },
              onUp: () {
                setState(() => _down = false);
                final touch = _path.isEmpty ? null : orderTouch(_path);
                if (_pulling) {
                  _pulling = false;
                  doc.endGesture();
                  if (touch != OrderTouch.press) return;   // (pulled: the point is where it was let go; only pressed: a press as any other)
                }
                if (touch == null) return;
                final a = _path.first, b = _path.last;
                switch (touch) {
                  case OrderTouch.shake:
                    from == 'random' ? doc.set('v_seed', (doc.get('v_seed') ?? 0) + 1) : say(to: 'random');
                  case OrderTouch.press:
                    pressed(a);
                  case OrderTouch.swipe:
                    say(to: orderSwiped(f.nearest(a), f.nearest(b), n));
                }
              },
              child: AnimatedBuilder(
                animation: _play,
                builder: (_, _) => CustomPaint(
                  size: box.biggest,
                  painter: _OrderPaint(f, delays, stagger, from, cross, open, keyed, _play.isAnimating ? _play.value * (math.max(stagger, 0) + .35) : null),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

enum OrderTouch { press, swipe, shake }

/// What a hand's path on the figure was: a press (hardly moved), a shake (back and forth across or up and down, its runs
/// of 8 or more turning three times; a tremble in a run is no turn), a swipe.
OrderTouch orderTouch(List<Offset> path) {
  int turns(double Function(Offset) on) {
    var count = 0;
    double run = 0, last = 0;   // (how far since it last turned; the way the last run of 8 or more went)
    void ended() {
      if (run.abs() < 8) return;
      if (last != 0 && run.sign != last) count++;
      last = run.sign;
    }

    for (var i = 1; i < path.length; i++) {
      final d = on(path[i]) - on(path[i - 1]);
      if (d == 0) continue;
      if (run != 0 && d.sign != run.sign) {
        ended();
        run = 0;
      }
      run += d;
    }
    ended();
    return count;
  }

  if (math.max(turns((p) => p.dx), turns((p) => p.dy)) >= 3) return OrderTouch.shake;
  return (path.last - path.first).distance < 6 ? OrderTouch.press : OrderTouch.swipe;
}

/// The order a swipe from member [a] to member [b] says, of [n]: begun at the very middle and going out, from the
/// centre; ending there from further out, from the edges; else by its way along their numbers, from the start or the end.
String orderSwiped(int a, int b, int n) {
  final mid = (n - 1) / 2;
  bool middle(int i) => (i - mid).abs() <= .5;
  if (middle(a) && (b - mid).abs() > (a - mid).abs()) return 'centre';
  if (middle(b) && (a - mid).abs() > (b - mid).abs()) return 'edges';
  return b >= a ? 'start' : 'end';
}

/// Where each member is drawn in a figure of [size]: right of the words, x right, y up, depth (further, z less) up and to
/// the right at half its length (a cabinet projection), all of them fitted inside with room round them, as large as
/// they go.
class OrderFigure {
  OrderFigure(List<double> members, this.size)
      : deep = [for (var i = 2; i < members.length; i += 4) members[i]].any((z) => z.abs() > 1e-9),
        _laid = [for (var i = 0; i + 3 < members.length; i += 4) _flat(members[i], members[i + 1], members[i + 2])] {
    area = areaOf(size, deep: deep);
    var lo = const Offset(double.infinity, double.infinity), hi = const Offset(-double.infinity, -double.infinity);
    for (final p in _laid) {
      lo = Offset(math.min(lo.dx, p.dx), math.min(lo.dy, p.dy));
      hi = Offset(math.max(hi.dx, p.dx), math.max(hi.dy, p.dy));
    }
    final span = hi - lo;
    _scale = math.min(span.dx > 1e-9 ? area.width / span.dx : double.infinity, span.dy > 1e-9 ? area.height / span.dy : double.infinity);
    if (!_scale.isFinite) _scale = 0;
    _middle = (lo + hi) / 2;
  }
  static const words = 104.0;   // (the words' room on the left)
  /// Where the members are drawn in a figure of [size]: right of the words, room round them (and for the axes, deep).
  static Rect areaOf(Size size, {bool deep = false}) {
    final pad = size.height > 40 ? 12.0 : 6.0;
    return Rect.fromLTRB(words + 8, pad, math.max(words + 9, size.width - (deep ? 38 : 10)), math.max(pad + 1, size.height - pad));
  }

  final Size size;
  late final Rect area;
  final List<Offset> _laid;
  late double _scale;
  late Offset _middle;
  final bool deep;   // (some lie deeper than others: the axes drawn)
  static const _deep = .5 * .7071; // (half its length, at 45 degrees)
  static Offset _flat(double x, double y, double z) => Offset(x - z * _deep, -y + z * _deep);   // (y down on the figure; further is z less)
  int get count => _laid.length;
  Offset at(int i) => area.center + (_laid[i] - _middle) * _scale;
  /// Where a place of the members' own (the point an order spreads from) is drawn.
  Offset of(double x, double y, double z) => area.center + (_flat(x, y, z) - _middle) * _scale;
  int nearest(Offset p) {
    var best = 0;
    for (var i = 1; i < count; i++) {
      if ((at(i) - p).distanceSquared < (at(best) - p).distanceSquared) best = i;
    }
    return best;
  }

  /// How large a member is drawn: up to 4, as small as keeps them apart (1.5 the least).
  double get dot {
    if (count > 400) return 1.5;
    var least = double.infinity;
    for (var i = 0; i < count; i++) {
      for (var j = i + 1; j < count; j++) {
        least = math.min(least, (at(i) - at(j)).distance);
      }
    }
    return (least / 2.4).clamp(1.5, 4.0);
  }
}

class _OrderPaint extends CustomPainter {
  const _OrderPaint(this.f, this.delays, this.stagger, this.from, this.cross, this.open, this.keyed, this.playing);
  final OrderFigure f;
  final List<double> delays;
  final double stagger;
  final String from;
  final Offset? cross;
  final bool open, keyed;
  final double? playing;   // (seconds into a play; null: still)

  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, Shape.r(8)), Paint()..color = Grey.g07);
    final r = f.dot;
    for (var i = 0; i < f.count; i++) {   // (still: the first to move the brightest; played: each lit as its moment comes)
      final early = stagger > 0 ? 1 - (delays[i] / stagger).clamp(0.0, 1.0) : 1.0;   // (still: the first large and bright, the last small and faint, so an order reads at 24 high too)
      final lit = playing == null ? early : ((playing! - delays[i]) / .25).clamp(0.0, 1.0);
      c.drawCircle(f.at(i), r * (playing == null ? .55 + .45 * early : .7 + .5 * lit), Paint()..color = Pop.tonePlace.withValues(alpha: .12 + .88 * lit));
    }
    if (cross case final at?) {   // (the point it spreads from: a cross where it is, pulled to another)
      final ink = Paint()
        ..color = Pop.accent
        ..strokeWidth = 1.4;
      c.drawLine(at - const Offset(7, 0), at + const Offset(7, 0), ink);
      c.drawLine(at - const Offset(0, 7), at + const Offset(0, 7), ink);
    }
    final order = stagger <= 0 ? 'Together' : switch (from) {
      'centre' => 'From the centre',
      'end' => 'From the end',
      'edges' => 'From the edges',
      'random' => 'At random',
      'point' => 'From this one',
      _ => 'From the start',
    };
    (TextPainter(text: TextSpan(text: order, style: T.label(Grey.g56)), textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '…')..layout(maxWidth: OrderFigure.words - 8)).paint(c, Offset(8, open ? 8 : (s.height - 12) / 2));
    if (open) {   // (what a hand may do here; with nothing keyed, that nothing moves until something is)
      final hint = keyed ? 'Swipe along them, press one, shake, or double-click' : 'Key a value and they move in this order';
      (TextPainter(text: TextSpan(text: hint, style: T.micro(Grey.g44)), textDirection: TextDirection.ltr, maxLines: 3)..layout(maxWidth: OrderFigure.words - 8)).paint(c, Offset(8, 24));
    }
    if (open && f.deep) {   // (the axes, as the figure draws them: x right, y up, depth up and to the right)
      final o = Offset(s.width - 22, s.height / 2 + 6), ink = Paint()
        ..color = Grey.g38
        ..strokeWidth = 1;
      for (final (to, name) in [(const Offset(10, 0), 'x'), (const Offset(0, -10), 'y'), (const Offset(-6, 6), 'z')]) {   // (z towards the eye: down and to the left; further, up and to the right)
        c.drawLine(o, o + to, ink);
        (TextPainter(text: TextSpan(text: name, style: T.micro(Grey.g44)), textDirection: TextDirection.ltr)..layout()).paint(c, o + to * 1.3 - const Offset(3, 6));
      }
    }
  }

  @override
  bool shouldRepaint(_OrderPaint o) => true;
}
