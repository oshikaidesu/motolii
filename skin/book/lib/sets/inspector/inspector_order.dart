// The order's figure on the Relation card: the members of anything with two or more (a group's things, a split text's
// letters, copies alike) drawn where they lie, the first to move the brightest, and the place their order starts from,
// put anywhere by a hand as the Anchor card's point is (the user, 11/6: the Transform and Anchor cards are free; the
// critique of 11/6: an order was a list of words carried from Copies, its place snapped to a member). The inside says
// where each lies and how much later it moves (Doc.onMembers: motolii_members, asked on another isolate, skin/BRIDGE.md
// Q), so the figure never works the order out; its name is read off what the order is, as the Anchor's is off its
// numbers (inspector_anchor.dart: Custom where none fits).
//   a press, or a hand drawn across: the place there. By place, anywhere, caught by a member or the middle within a
//     few points (the only way a flat figure of a deep row can say a depth: Cinema 4D's field put on a clone). In their
//     order, on the member nearest (an order counted has no place between its members but halfway).
// Always as high: it is the one new thing on the card, and a figure that grows or plays again under a hand moves away
// from what the hand came to read (golf (g9)). Depth is drawn going up and to the right at half its length, a cabinet
// projection, its axes by it. Played once, as they will move, after the order changes.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:lab_book/sets/inspector/inspector_parts.dart';
import 'package:lab_book/sets/inspector/inspector_pulled.dart';
import 'package:lab_book/tokens.dart';

class OrderDrawing extends StatefulWidget {
  const OrderDrawing({super.key});
  static double get high => Shape.z(72.0);
  @override
  State<OrderDrawing> createState() => _OrderDrawingState();
}

/// stagger_from's words as the inside offers them (doc_words), where the card does not say them.
const orderWords = ['order', 'place', 'random'];

class _OrderDrawingState extends State<OrderDrawing> with SingleTickerProviderStateMixin {
  late final AnimationController _play = AnimationController(vsync: this);
  String _was = '', _asked = '';
  String? _by;   // (the word as last seen: one chosen by its name while they move together gives them a spread)
  int _ticket = 0;
  (double, double, double)? _put;
  List<double> _all = const [];

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  // (played once: each member lit as its moment comes, the last a little after; a long order played quicker)
  void _replay(double stagger) {
    if (!mounted) return;
    _play
      ..duration = Duration(milliseconds: (1000 * (math.min(stagger.abs(), 3.0) + .35)).round())
      ..forward(from: 0);
  }

  static final _reads = RegExp('stagger|cop|seed|text|split|size|scale|anchor|space|font');
  // (what the members and their order are made of, as the card has it, and a group's things as they stand: asked again
  //  when it changes, and when the inside reads the document back, an undo)
  String _of(Doc doc) => [
        for (final e in doc.v.entries) if (_reads.hasMatch(e.key)) '${e.key}=${e.value}',
        for (final e in doc.s2.entries) if (_reads.hasMatch(e.key)) '${e.key}=${e.value}',
        '${doc.held}',
      ].join(';');

  // (a hand let go is told to what watches the values it moved, not the whole card built again: as the Anchor card
  //  listens for its point, inspector_anchor.dart. Not the By word: a choice no field watches is what builds the panel
  //  again, its row with it (Doc.showAt); watched here, By stayed lit on the word before (golf 3, player 2))
  static const _moved = ['v_stagger', 'v_stagger_x', 'v_stagger_y', 'v_stagger_z'];

  @override
  Widget build(BuildContext context) {
    final doc = Ctx.of(context).doc;
    return ListenableBuilder(listenable: Listenable.merge([for (final id in _moved) doc.watch(id)]), builder: (context, _) => _figure(doc));
  }

  Widget _figure(Doc doc) {
    if (doc.onMembers case final ask? when _of(doc) != _asked) {
      _asked = _of(doc);
      final mine = ++_ticket;
      ask().then((all) {
        if (mounted && mine == _ticket) setState(() => _all = all);
      });
    }
    final all = _all, n = all.length ~/ 4;
    if (n < 2) return const SizedBox.shrink();
    final said = doc.cards.where((c) => c.name == 'Relation').firstOrNull?.params.where((p) => p.id == 'stagger_from').firstOrNull?.options ?? const <String>[];
    final words = said.isEmpty ? orderWords : said;
    final stagger = doc.get('v_stagger') ?? 0, by = words[(doc.get('v_stagger_from') ?? 0).round().clamp(0, words.length - 1)];
    // (an order first given spreads over as long as its keys run: the last starts as the first lands, seen as an order
    //  however many there are; with no keys yet, half a second, so the figure has an order to show)
    final spread = doc.keySpan > 0 ? doc.keySpan : .5;
    if (_by != null && by != _by && stagger == 0) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? doc.set('v_stagger', spread) : null);
    _by = by;
    final delays = [for (var i = 0; i < n; i++) all[4 * i + 3]];
    final place = (doc.get('v_stagger_x') ?? 0, doc.get('v_stagger_y') ?? 0, doc.get('v_stagger_z') ?? 0);
    final keyed = doc.keys.values.any((k) => k != KeyS.off);
    final told = '$stagger $by ${delays.join(',')}';
    if (told != _was) {
      if (_was.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _replay(stagger));
      _was = told;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.precise,   // (a place to put, as the Anchor's point is put: macOS's crosshair)
      child: Padding(
        padding: EdgeInsets.only(bottom: Shape.s(6)),
        child: SizedBox(
          height: OrderDrawing.high,
          child: LayoutBuilder(builder: (context, box) {
            final f = OrderFigure(all, box.biggest);
            // (a first place, given while they move together or at random: by place, from there; the word said at once,
            //  a step of its own, as under a hand only numbers are held)
            final first = stagger == 0 || by == 'random';
            final counted = !first && by == 'order';
            void put(Offset p, {bool word = false}) {
              final at = counted ? f.member(f.nearest(p)) : f.placeAt(p);
              if (at == null || (!word && at == _put)) return;
              _put = at;
              if (word) doc.s2['v_stagger_from'] = 'place';
              doc.setMany({
                if (word) 'v_stagger_from': math.max(0, words.indexOf('place')).toDouble(),
                'v_stagger_x': at.$1,
                'v_stagger_y': at.$2,
                'v_stagger_z': at.$3,
                if (word && stagger == 0) 'v_stagger': spread,
              });
            }

            final from = stagger == 0 || by == 'random' ? const <Offset>[] : by == 'place' ? [f.of(place.$1, place.$2, place.$3)] : [for (final i in f.starts(delays, stagger)) f.at(i)];
            return Pulled(
              takes: (_) => true,
              onDown: (p) {
                _put = null;
                if (first) put(p, word: true);
                doc.beginGesture();   // (drawn across: one step, the place where it is let go)
                put(p);
              },
              onMove: put,
              onUp: doc.endGesture,
              child: AnimatedBuilder(
                animation: _play,
                builder: (_, _) => CustomPaint(
                  size: box.biggest,
                  painter: _OrderPaint(f, delays, stagger, stagger != 0 && by == 'random' ? 'At random' : f.name(by, delays, stagger, place), from, keyed, _play.isAnimating ? _play.value * (stagger.abs() + .35) : null),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Where each member is drawn in a figure of [size]: right of the words, x right, y up, depth (further, z less) up and to
/// the right at half its length (a cabinet projection), all of them fitted inside with room round them, as large as
/// they go; and back, a point of the figure as a place among them.
class OrderFigure {
  OrderFigure(this.members, this.size)
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
    double low(int k) => [for (var i = k; i < members.length; i += 4) members[i]].reduce(math.min);
    double high(int k) => [for (var i = k; i < members.length; i += 4) members[i]].reduce(math.max);
    middle = ((low(0) + high(0)) / 2, (low(1) + high(1)) / 2, (low(2) + high(2)) / 2);
  }
  static const words = 104.0;   // (the words' room on the left)
  static const catches = 8.0;   // (how near a hand comes to a member or the middle to be put on it)
  /// Where the members are drawn in a figure of [size]: right of the words, room round them (and for the axes, deep).
  static Rect areaOf(Size size, {bool deep = false}) {
    final pad = size.height > 40 ? 12.0 : 6.0;
    return Rect.fromLTRB(words + 8, pad, math.max(words + 9, size.width - (deep ? 38 : 10)), math.max(pad + 1, size.height - pad));
  }

  final List<double> members;
  final Size size;
  late final Rect area;
  final List<Offset> _laid;
  late double _scale;
  late Offset _middle;
  /// The middle of the box they lie in, in their own units.
  late final (double, double, double) middle;
  final bool deep;   // (some lie deeper than others: the axes drawn)
  static const _deep = .5 * .7071; // (half its length, at 45 degrees)
  static Offset _flat(double x, double y, double z) => Offset(x - z * _deep, -y + z * _deep);   // (y down on the figure; further is z less)
  int get count => _laid.length;
  Offset at(int i) => area.center + (_laid[i] - _middle) * _scale;
  (double, double, double) member(int i) => (members[4 * i], members[4 * i + 1], members[4 * i + 2]);
  /// Where a place of the members' own (the place an order spreads from) is drawn.
  Offset of(double x, double y, double z) => area.center + (_flat(x, y, z) - _middle) * _scale;
  int nearest(Offset p) {
    var best = 0;
    for (var i = 1; i < count; i++) {
      if ((at(i) - p).distanceSquared < (at(best) - p).distanceSquared) best = i;
    }
    return best;
  }

  /// The place a point of the figure is among them: a member's own, or the middle, where it is caught; else as deep as
  /// the middle (a flat picture has no depth of its own to give). None where they all lie at one point.
  (double, double, double)? placeAt(Offset p) {
    final k = nearest(p);
    if ((at(k) - p).distance <= catches) return member(k);
    if ((of(middle.$1, middle.$2, middle.$3) - p).distance <= catches) return middle;
    if (_scale == 0) return null;
    final flat = (p - area.center) / _scale + _middle, z = middle.$3;
    return (flat.dx + z * _deep, z * _deep - flat.dy, z);
  }

  /// The ones it starts from, in their order: the first to move (the last, turned round: those it goes toward).
  List<int> starts(List<double> delays, double stagger) {
    final edge = stagger > 0 ? delays.reduce(math.min) : delays.reduce(math.max);
    final out = [for (var i = 0; i < delays.length; i++) if ((delays[i] - edge).abs() <= 1e-6 + stagger.abs() * 1e-4) i];
    return out.length > 2 ? const [] : out;
  }

  /// The order's name, read off what it is, as the Anchor's is off its numbers: from (or, turned round, toward) the
  /// first, the last, the middle, the ends, this one, here.
  String name(String by, List<double> delays, double stagger, (double, double, double) place) {
    if (stagger == 0) return 'Together';
    final toward = stagger > 0 ? 'From' : 'Toward';
    String one(List<int> s) {
      final last = count - 1, mid = count.isOdd ? [last ~/ 2] : [count ~/ 2 - 1, count ~/ 2];
      if (s.length == 1 && s.first == 0) return 'the first';
      if (s.length == 1 && s.first == last) return 'the last';
      if (s.length == mid.length && s.every(mid.contains)) return 'the middle';
      if (s.length == 2 && s.contains(0) && s.contains(last)) return 'the ends';
      return s.length == 1 ? 'this one' : 'here';
    }

    if (by != 'place') return '$toward ${one(starts(delays, stagger))}';
    final p = of(place.$1, place.$2, place.$3);
    if ((of(middle.$1, middle.$2, middle.$3) - p).distance < .5) return '$toward the middle';
    final k = nearest(p);
    return (at(k) - p).distance < .5 ? '$toward ${one([k])}' : '$toward here';
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
  const _OrderPaint(this.f, this.delays, this.stagger, this.order, this.from, this.keyed, this.playing);
  final OrderFigure f;
  final List<double> delays;
  final double stagger;
  final String order;
  final List<Offset> from;
  final bool keyed;
  final double? playing;   // (seconds into a play; null: still)

  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, Shape.r(8)), Paint()..color = Grey.g07);
    final r = f.dot, spread = stagger.abs();
    for (var i = 0; i < f.count; i++) {   // (still: the first to move the brightest; played: each lit as its moment comes)
      final early = spread > 0 ? 1 - (delays[i] / spread).clamp(0.0, 1.0) : 1.0;
      final lit = playing == null ? early : ((playing! - delays[i]) / .25).clamp(0.0, 1.0);
      final size = f.deep ? .8 : playing == null ? .55 + .45 * early : .7 + .5 * lit;   // (in depth one size: larger would read nearer)
      c.drawCircle(f.at(i), r * size, Paint()..color = Pop.tonePlace.withValues(alpha: .12 + .88 * lit));
    }
    for (final at in from) {   // (the place it spreads from: a cross, kept inside the figure where it lies beyond it)
      final p = Offset(at.dx.clamp(OrderFigure.words, s.width - 2), at.dy.clamp(2, s.height - 2));
      final ink = Paint()
        ..color = Pop.accent
        ..strokeWidth = 1.4;
      c.drawLine(p - const Offset(7, 0), p + const Offset(7, 0), ink);
      c.drawLine(p - const Offset(0, 7), p + const Offset(0, 7), ink);
    }
    (TextPainter(text: TextSpan(text: order, style: T.label(Grey.g56)), textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '…')..layout(maxWidth: OrderFigure.words - 8)).paint(c, const Offset(8, 8));
    final hint = keyed ? 'Press where they start from' : 'Key a value and they move in this order';   // (what a hand may do here; with nothing keyed, that nothing moves until something is)
    (TextPainter(text: TextSpan(text: hint, style: T.micro(Grey.g44)), textDirection: TextDirection.ltr, maxLines: 3)..layout(maxWidth: OrderFigure.words - 8)).paint(c, const Offset(8, 24));
    if (f.deep) {   // (the axes, as the figure draws them: x right, y up, depth up and to the right)
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
