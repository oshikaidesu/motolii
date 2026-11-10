// The numbers of an easing, shown exactly. Under the graph the easing's name carries the Inspector's fold mark and
// opens the numbers as a card over the foot of the graph, as an Inspector card does.
// The names are those of AbsentMotion's Keyframes.kt; Alight Motion only offers them as handles.
// Waves and steps are entered as a count rather than a length, which is how people think of them.
// Overshoot is switched here, next to the numbers it affects, rather than in a menu as in Alight Motion.
// Without it Y stops at 0 and 1, so typing a number cannot silently push the curve out of reach.
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_text.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:motolii/widgets/fold_mark.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, Hov;
import 'package:motolii/widgets/number_field.dart';

typedef _Number = ({String name, int at, double lo, double hi, bool many});
_Number _n(String name, int at, double lo, double hi, {bool many = false}) => (name: name, at: at, lo: lo, hi: hi, many: many);

// For each easing kind: its default numbers, then the numbers shown with their range.
// The kinds and defaults follow engine/motion/easing_curves.h. The range is how far a drag takes the number.
final _kinds = <String, (List<double>, List<_Number>)>{
  'Bezier': (const [0, 0, 1, 1], [_n('X1', 0, 0, 1), _n('Y1', 1, -2, 3), _n('X2', 2, 0, 1), _n('Y2', 3, -2, 3)]),
  'Bounce': (const [.3, .8], [_n('Length', 0, .02, 1), _n('Bounce', 1, 0, .95)]),
  'Elastic': (const [.25, 1, .5, 1], [_n('Half', 0, .02, .98), _n('Decay', 2, 0, 1), _n('Strength', 3, 0, 1)]),
  'Cyclic': (const [2 / 7, 0, .5, 0, 0], [_n('Waves', 0, 1, 50, many: true), _n('Sharp', 1, 0, 1), _n('Crest', 2, .02, .98), _n('Floor', 3, 0, 1)]),
  'Random': (
    const [.5, .5, .5, .5, .5, 0],
    [_n('Rate', 0, 0, 1), _n('Size', 1, 0, 1), _n('Seed', 2, 0, 1), _n('Fade', 3, 0, 1), _n('Warp', 4, 0, 1), _n('Tilt', 5, 0, 1)],
  ),
  'Steps': (const [.25, 0], [_n('Steps', 0, 1, 50, many: true), _n('Smooth', 1, 0, 1)]),
  'ElasticSteps': (const [.2, .5], [_n('Steps', 0, 1, 20, many: true), _n('Over', 1, 0, 1)]),
};

/// Whether the numbers are open. It stays as the user left it, like the Inspector's cards.
bool easeNumbersOpen = false;

/// Whether the easing uses its kind's default numbers. A tile then draws the kind itself, otherwise the easing's own curve.
bool easeIsUsual(String said) {
  final w = said.split(' '), usual = _kinds[w.first]?.$1;
  // A Bezier tile already draws its own numbers.
  if (usual == null || w.length == 1 || w.first == 'Bezier') return true;
  return [for (final (i, x) in w.skip(1).indexed) (double.tryParse(x) ?? 0) - (i < usual.length ? usual[i] : 0)].every((d) => d.abs() < 1e-6);
}

/// The easing's name with the fold-out card of its numbers.
class EaseNumbers extends StatefulWidget {
  const EaseNumbers({super.key, required this.card, required this.onChanged, this.overshoot = false, this.onOvershoot});

  /// The easing being edited: one card, or the whole easing, which has a name and no numbers.
  final Ease card;

  /// Called with the changed easing.
  final ValueChanged<Ease> onChanged;

  /// Whether a Bezier may go past 0 and 1 in Y, like Alight Motion's Enable Overshoot.
  final bool overshoot;

  /// Called when the user toggles Overshoot.
  final VoidCallback? onOvershoot;
  @override
  State<EaseNumbers> createState() => _EaseNumbersState();
}

class _EaseNumbersState extends State<EaseNumbers> {
  @override
  Widget build(BuildContext context) {
    final word = said(widget.card), laid = easeIsLaid(word), turned = easeIsTurned(word), plain = turned ? easeTurn(word) : word;
    final w = plain.split(' '), bezier = w.first == 'Linear' || w.first == 'Bezier', kind = laid ? null : _kinds[bezier ? 'Bezier' : w.first];
    Widget name(bool hot) => SizedBox(
      height: Shape.z(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text((laid ? 'Result' : easeWord(widget.card)).toUpperCase(), maxLines: 1, style: T.micro(hot ? Grey.g95 : Grey.g63).copyWith(letterSpacing: .6)),
          if (kind != null) ...[SizedBox(width: Shape.s(3)), FoldMark(open: easeNumbersOpen, hot: hot)],
        ],
      ),
    );
    if (kind == null) return Align(alignment: Alignment.bottomCenter, child: name(false));
    final said_ = [for (final x in w.skip(1)) double.tryParse(x) ?? 0];
    final now = w.first == 'Linear' ? kind.$1 : [for (final (i, u) in kind.$1.indexed) i < said_.length ? said_[i] : u];
    void change(int at, double to) {
      final next = [...now]..[at] = to, made = bezier ? 'Bezier ${next.join(' ')}' : '${w.first} ${next.join(' ')}';
      widget.onChanged(heard(turned ? easeTurn(made) : made));
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (easeNumbersOpen)
            Container(
              color: WindowTokens.card,
              padding: EdgeInsets.all(Shape.s(3)),
              child: LayoutBuilder(
                builder: (_, box) {
                  final each = (box.maxWidth - Shape.s(3)) / (box.maxWidth / Shape.z(82)).floor().clamp(1, kind.$2.length) - Shape.s(3);
                  return Wrap(
                    spacing: Shape.s(3),
                    runSpacing: Shape.s(3),
                    children: [
                      for (final n in kind.$2)
                        if ((n.name.startsWith('Y') && !widget.overshoot ? 0.0 : n.lo, n.name.startsWith('Y') && !widget.overshoot ? 1.0 : n.hi) case (
                          final lo,
                          final hi,
                        ))
                          SizedBox(
                            width: each,
                            child: NumberField(
                              key: ValueKey('ease-number-${n.name}'),
                              inline: true,
                              caption: n.name,
                              accent: WindowTokens.accent,
                              value: () => n.many ? 1 / now[n.at] : now[n.at],
                              text: (v, _) => n.many ? v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2) : v.toStringAsFixed(2),
                              min: lo,
                              max: hi,
                              perPx: n.many ? .05 : (hi - lo) / 200,
                              // Dragging stops at the range given in _kinds.
                              reach: (to, _) => to.clamp(lo, hi),
                              // A typed number is limited only where the engine limits it: Bezier X to 0..1
                              // (interp_ease in engine/motion/easing_curves.h clamps x1 and x2), and Y too while Overshoot is off.
                              onChange: (v) =>
                                  change(n.at, n.many ? 1 / v : (n.name.startsWith('X') || n.name.startsWith('Y') && !widget.overshoot ? v.clamp(lo, hi) : v)),
                            ),
                          ),
                      if (bezier)
                        SizedBox(
                          width: each,
                          child: Chip(key: const ValueKey('ease-overshoot'), label: 'Overshoot', on: widget.overshoot, onTap: widget.onOvershoot),
                        ),
                    ],
                  );
                },
              ),
            ),
          Hov(key: const ValueKey('ease-numbers'), onTap: () => setState(() => easeNumbersOpen = !easeNumbersOpen), builder: (_, h) => name(h)),
        ],
      ),
    );
  }
}
