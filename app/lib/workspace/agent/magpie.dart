// Motolii's mascot, the magpie, as decided on 2026-08-08 (rust_ae/Motolii git 912382f048,
// docs/reviews/2026-08-08-mascot-and-pet-decision.md): 8x8 dots in two colours, K the body and C the motif colour.
// It breathes (stand and sink, 1.6 s) and blinks (the eye filled for 0.17 s about every 3.4 s, never evenly). It is
// the agent's face (user, 2026-11-12: the postponed pet lands on the agent, whose words are the LLM's): while the
// agent works it hops (stand, sink, float: 0.54, 0.135, 0.225 s). Every state it shows is also in the pane's text
// (Stop, the tool rows), as the decision asks of a pet. It stands still when the system asks for less motion.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';

const _stand = [
  '.KKK....',
  'KKCKKK..',
  '.KKKKKK.',
  '.CCKKKKK',
  '.CCCKKKK',
  '..CCKKKK',
  '..C.C.KK',
  '.......K',
];
// Standing without its legs, drawn one dot higher: the only frame placed off its square.
const _float = [
  '.KKK....',
  'KKCKKK..',
  '.KKKKKK.',
  '.CCKKKKK',
  '.CCCKKKK',
  '..CCKKKK',
  '......KK',
  '.......K',
];
const _sink = [
  '........',
  '.KKK....',
  'KKCKKK..',
  '.KKKKKK.',
  '.CCKKKKK',
  '.CCCKKKK',
  '..CCKKKK',
  '.......K',
];

class Magpie extends StatefulWidget {
  const Magpie({super.key, this.dot = 4, this.hopping = false});

  /// The size of one dot.
  final double dot;

  /// Whether it hops, while the agent works, rather than breathes.
  final bool hopping;

  @override
  State<Magpie> createState() => _MagpieState();
}

class _MagpieState extends State<Magpie> {
  /// 0 stands, 1 sinks, 2 floats.
  var _frame = 0, _shut = false;
  Timer? _breath, _blink;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _step();
    _wink();
  }

  /// The next frame: breathing goes stand, sink; hopping goes stand, sink, float.
  void _step() => _breath = Timer(
    Duration(
      milliseconds: widget.hopping ? const [540, 135, 225][_frame] : 800,
    ),
    () {
      setState(() => _frame = (_frame + 1) % (widget.hopping ? 3 : 2));
      _step();
    },
  );

  void _wink() =>
      _blink = Timer(Duration(milliseconds: 2900 + _random.nextInt(1000)), () {
        setState(() => _shut = true);
        _blink = Timer(const Duration(milliseconds: 170), () {
          setState(() => _shut = false);
          _wink();
        });
      });

  @override
  void dispose() {
    _breath?.cancel();
    _blink?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    var rows = still ? _stand : const [_stand, _sink, _float][_frame];
    // The blink fills the eye: the one C with body on both sides.
    if (_shut && !still) {
      rows = [for (final r in rows) r.replaceFirst('KKCK', 'KKKK')];
    }
    return CustomPaint(
      size: Size.square(widget.dot * 8),
      painter: _Dots(rows, widget.dot, _frame == 2 && !still ? -widget.dot : 0),
    );
  }
}

class _Dots extends CustomPainter {
  _Dots(this.rows, this.dot, this.lift);
  final List<String> rows;
  final double dot, lift;

  @override
  void paint(Canvas canvas, Size size) {
    // The body turns over with the background; the motif colour stays.
    final body = Paint()..color = Color(Grey.light ? 0xFF0F0F0F : 0xFFEDEAE0);
    final motif = Paint()..color = const Color(0xFF3ED9A4);
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        final c = rows[y][x];
        if (c == '.') continue;
        canvas.drawRect(
          Rect.fromLTWH(x * dot, y * dot + lift, dot, dot),
          c == 'K' ? body : motif,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Dots old) =>
      old.rows != rows || old.dot != dot || old.lift != lift;
}
