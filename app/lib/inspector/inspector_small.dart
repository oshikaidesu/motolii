import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:motolii/skin/forms/forms.dart';
import 'package:naked_ui/naked_ui.dart';

import '../skin/tokens.dart';
import 'inspector_parts.dart';

// ---- 3. small things ------------------------------------------------------------------------------------------------
/// What floats over the window goes when anything else is touched, by either button, and on Esc (Flutter's TapRegion; a
/// Mac's menu, Windows' too): [keep] a press it leaves alone, the one that opens it again; [group] what counts as inside.
class FloatShut extends StatefulWidget {
  const FloatShut({super.key, required this.shut, required this.child, this.group, this.keep});
  final VoidCallback shut;
  final Widget child;
  final Object? group;
  final bool Function(PointerDownEvent)? keep;
  @override
  State<FloatShut> createState() => _FloatShutState();
}

class _FloatShutState extends State<FloatShut> {
  final _keys = FocusNode(debugLabel: 'float');
  final _was = FocusManager.instance.primaryFocus; // (who held the keys: given back)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _keys.requestFocus() : null); // (a field holding the keys would take Esc for itself)
  }

  @override
  void dispose() {
    if (_keys.hasFocus) _was?.requestFocus();
    _keys.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TapRegion(
    groupId: widget.group,
    onTapOutside: (e) {
      if (!(widget.keep?.call(e) ?? false)) widget.shut();
    },
    child: Focus(
      focusNode: _keys,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.escape) return KeyEventResult.ignored;
        widget.shut();
        return KeyEventResult.handled;
      },
      child: widget.child,
    ),
  );
}

class Hov extends StatelessWidget {
  const Hov({super.key, required this.builder, this.cursor = SystemMouseCursors.click, this.onTap, this.excludeSemantics = false});
  final Widget Function(BuildContext, bool) builder;
  final MouseCursor cursor;
  final VoidCallback? onTap;

  /// A Semantics node above already names this control.
  final bool excludeSemantics;
  @override
  Widget build(BuildContext context) => NakedButton(
    onPressed: onTap,
    mouseCursor: cursor,
    enableFeedback: false,
    excludeSemantics: excludeSemantics,
    builder: (context, st, _) => builder(context, st.isHovered),
  );
}

String trimZeros(String s) => s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;

/// A value as a folded card shows it: short, trailing zeros dropped, — when mixed.
String brief(double? v, [int dec = 1]) => v == null ? '—' : trimZeros(v.toStringAsFixed(dec));

String fmt(double v, int dec, {bool tight = false}) {
  var d = tight ? 0 : dec;
  var s = v.toStringAsFixed(d);
  while (v != 0 && double.parse(s) == 0 && d < 4) {
    d++;
    s = v.toStringAsFixed(d);
  }
  return s == '-0' ? '0' : s;
}

/// The word-and-switch for On/Off (G2): the state is a word, never colour alone.
class OnOff extends StatelessWidget {
  const OnOff({super.key, required this.on, required this.onChanged, this.enabled = true});
  final bool on, enabled;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final live = enabled && !RowOff.offOf(context);
    return Forms.worn.onOff(context, SwitchSpec(on: on, onChanged: onChanged, enabled: live)); // (as the skin's forms draw it)
  }
}

class PopSwitch extends StatelessWidget {
  const PopSwitch({super.key, required this.on});
  final bool on;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 120),
    curve: Curves.easeOut,
    width: Shape.z(28),
    height: Shape.z(16),
    padding: EdgeInsets.all(Shape.s(2)),
    alignment: on ? Alignment.centerRight : Alignment.centerLeft,
    decoration: BoxDecoration(color: on ? Pop.accent : Grey.g26, borderRadius: BorderRadius.all(Shape.r(8))),
    child: Container(
      width: Shape.z(12),
      height: Shape.z(12),
      decoration: BoxDecoration(color: on ? Pop.onAccent : Grey.g63, shape: BoxShape.circle),
    ),
  );
}

/// A choice drawn as a small picture and its word (a plate of a row of them).
class GlyphPlate extends StatelessWidget {
  const GlyphPlate(this.label, this.glyph, {super.key, required this.on, required this.onTap});
  final String label;
  final void Function(Canvas c, Paint stroke) glyph; // (drawn in a 16 x 14 box)
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: on,
    label: label,
    child: Hov(
      onTap: onTap,
      excludeSemantics: true,
      builder: (_, h) {
        final pop = Pop.on(context);
        final ink = on ? (pop ? Pop.onAccent : Grey.g95) : (h ? Grey.g76 : Grey.g56);
        return Container(
          height: pop ? 22 : 26,
          decoration: pop
              ? BoxDecoration(color: on ? Pop.accent : (h ? Grey.g20 : Pop.well), borderRadius: BorderRadius.all(Shape.r(11)))
              : BoxDecoration(
                  color: on ? Grey.g20 : (h ? Grey.g15 : Grey.g13),
                  borderRadius: BorderRadius.all(Shape.r(5)),
                  border: Border(bottom: BorderSide(color: on ? Role.selected : const Color(0x00000000))),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(size: const Size(16, 14), painter: _GlyphPaint(glyph, ink)),
              SizedBox(width: Shape.s(6)),
              Flexible(
                // (narrow, the word gives way; the glyph stays)
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: pop ? T.micro(on ? Pop.onAccent : Grey.g76).copyWith(fontWeight: FontWeight.w700) : T.label(on ? Grey.g95 : Grey.g63),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _GlyphPaint extends CustomPainter {
  const _GlyphPaint(this.glyph, this.ink);
  final void Function(Canvas c, Paint stroke) glyph;
  final Color ink;
  @override
  void paint(Canvas c, Size s) => glyph(
    c,
    Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  @override
  bool shouldRepaint(_GlyphPaint o) => o.ink != ink || o.glyph != glyph;
}
