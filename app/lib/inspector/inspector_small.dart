import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:motolii/skin/forms/forms.dart';
import 'package:naked_ui/naked_ui.dart';

import '../skin/tokens.dart';
import 'inspector_parts.dart';

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
  const Hov({super.key, required this.builder, this.cursor = SystemMouseCursors.click, this.onTap});
  final Widget Function(BuildContext, bool) builder;
  final MouseCursor cursor;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) =>
      NakedButton(onPressed: onTap, mouseCursor: cursor, enableFeedback: false, builder: (context, st, _) => builder(context, st.isHovered));
}

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
  const OnOff({super.key, required this.on, required this.onChanged});
  final bool on;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Forms.worn.onOff(context, SwitchSpec(on: on, onChanged: onChanged)); // (as the skin's forms draw it)
}

/// The 28x16 on/off track.
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
