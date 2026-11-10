import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/number_field.dart';
import 'package:motolii/widgets/number_field_look.dart';
import 'package:motolii/widgets/text_gestures.dart';

class NumberFieldState extends State<NumberField> {
  final _node = FocusNode(debugLabel: 'num');
  late final FocusNode _ef = FocusNode(debugLabel: 'num-edit', onKeyEvent: _editKey)..addListener(_editFocus);
  // True while the field receiving focus was reached with Tab. That field opens for typing.
  static bool _tabbed = false;
  final _ctl = TextEditingController();
  bool _editing = false, _err = false, _hover = false, _focus = false, _drag = false, _moved = false, _cancelled = false;
  Offset _down = Offset.zero;
  double _start = 0, _acc = 0, _sum = 0, _w = 0;
  DateTime? _lastUp;

  bool get _bounded => widget.min != null && widget.max != null;
  double get _zeroAt => _bounded ? ((0 - widget.min!) / (widget.max! - widget.min!)).clamp(0.0, 1.0) : 0;

  @override
  void dispose() {
    _ef.dispose();
    _node.dispose();
    _ctl.dispose();
    super.dispose();
  }

  /// Shift is finer and Cmd or Ctrl is ten times coarser, as in Ableton Live (manual, section 42.6).
  /// The same keys apply to a scrub, a wheel and the arrow keys.
  double _mult() {
    final k = HardwareKeyboard.instance;
    if (k.isShiftPressed) return .1;
    if (k.isMetaPressed || k.isControlPressed) return 10;
    return 1;
  }

  double _tidy(double v) => double.parse(v.toStringAsFixed(6));
  double _reach(double to, [double? from]) => widget.reach?.call(to, from) ?? to;

  // Esc during a drag restores the starting value and ignores the rest of the drag. A pointer cancel does the same.
  void _abort() {
    widget.value() == null ? widget.onBy?.call(-_sum) : widget.onChange?.call(_start);
    _cancelled = true;
    _sum = 0;
    if (_moved) widget.onDrop?.call();
    setState(() => _drag = false);
  }

  void _onDown(PointerDownEvent e) {
    if (_editing) return;
    final theirs = widget.onPress?.call(e, _w);
    if (theirs == true || (widget.ownsPress?.call(e.localPosition, _w) ?? false) || e.buttons != kPrimaryButton) return;
    if (widget.keys) _node.requestFocus();
    if (theirs == false) return;
    _down = e.position;
    _moved = false;
    _cancelled = false;
    _sum = 0;
    _start = widget.value() ?? 0;
    _acc = _start;
    _drag = true;
  }

  void _onMove(PointerMoveEvent e) {
    if (!_drag || _cancelled || widget.perPx == null) return;
    if (!_moved && (e.position - _down).distance < 4) return;
    if (!_moved) {
      // A scrub is a single gesture, so the caller can settle what it shows when the drag ends.
      widget.onGrab?.call();
      setState(() => _moved = true);
    }
    final d = e.delta.dx * widget.perPx! * _mult();
    if (widget.value() == null) {
      _sum += d;
      widget.onBy?.call(d);
    } else {
      _acc = _reach(_acc + d, _start);
      widget.onChange?.call(_acc);
    }
    // The inspector is not rebuilt during a drag, so the field redraws itself with its own number.
    if (mounted) setState(() {});
  }

  void _onUp(PointerUpEvent e) {
    if (!_drag) return;
    _drag = false;
    if (_moved) {
      widget.onDrop?.call();
      setState(() => _moved = false);
      return;
    }
    // Pressed and released in place: start typing.
    if (widget.typeOnTap && (e.position - _down).distance < kTouchSlop) return _startEdit();
    final now = DateTime.now(), dbl = _lastUp != null && now.difference(_lastUp!) < doubleClickTime;
    _lastUp = dbl ? null : now;
    if (dbl) widget.onReset?.call();
  }

  void _onCancel(PointerCancelEvent e) {
    if (_drag && _moved) _abort();
    _drag = false;
    _moved = false;
  }

  // A horizontal wheel or two-finger slide changes every number the same way: right is more, left is less.
  // It uses the drag's rate (perPx) and modifier keys, so a slide and a scrub of equal length change the value equally.
  // A vertical slide is not claimed and scrolls the panel. No button needs to be held.
  void _onSignal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent || _editing || widget.perPx == null) return;
    final d = e.scrollDelta;
    if (d.dx.abs() <= d.dy.abs()) return;
    GestureBinding.instance.pointerSignalResolver.register(e, (ev) => _by((ev as PointerScrollEvent).scrollDelta.dx * widget.perPx! * _mult()));
  }

  void _onPan(PointerPanZoomUpdateEvent e) {
    if (_editing || widget.perPx == null) return;
    final d = e.localPanDelta;
    if (d.dx.abs() > d.dy.abs()) _by(d.dx * widget.perPx! * _mult());
  }

  void _by(double d) {
    // A slide or nudge moves the value by `d` from where it is now.
    final cur = widget.value();
    cur == null ? widget.onBy?.call(d) : widget.onChange?.call(_reach(_tidy(cur + d)));
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (_editing && !_ef.hasFocus) {
      // The editor receives keys one frame late. Characters typed in that frame are inserted here so fast typing does not drop them.
      final c = e.character ?? '', at = _ctl.selection;
      if (e is! KeyDownEvent || !RegExp(r'^[0-9.\-+*/]$').hasMatch(c)) return _editKey(n, e);
      _ctl.value = TextEditingValue(
        text: _ctl.text.replaceRange(at.start, at.end, c),
        selection: TextSelection.collapsed(offset: at.start + 1),
      );
      return KeyEventResult.handled;
    }
    if (_editing) return KeyEventResult.ignored;
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.escape && _drag && _moved) {
      _abort();
      return KeyEventResult.handled;
    }
    if (widget.onKey?.call(e) == KeyEventResult.handled) return KeyEventResult.handled;
    final up = k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.arrowRight;
    if (widget.step case final step? when up || k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowLeft) {
      _by((up ? 1 : -1) * step * _mult());
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _startEdit();
      return KeyEventResult.handled;
    }
    if (widget.onReset case final reset? when k == LogicalKeyboardKey.delete || k == LogicalKeyboardKey.backspace) {
      reset();
      return KeyEventResult.handled;
    }
    if (RegExp(r'^[0-9.\-]$').hasMatch(e.character ?? '')) {
      _startEdit(e.character);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _startEdit([String? typed]) {
    // `typed` is the character the user started typing with.
    if (!mounted || _editing) return;
    final v = widget.value();
    _ctl.text = typed ?? (v == null ? '' : widget.text(v, double.infinity));
    _ctl.selection = typed != null ? TextSelection.collapsed(offset: _ctl.text.length) : TextSelection(baseOffset: 0, extentOffset: _ctl.text.length);
    setState(() {
      _editing = true;
      _err = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing) _ef.requestFocus();
    });
  }

  KeyEventResult _editKey(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      // Esc while typing discards the text and restores the old value.
      _close();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _commit();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.tab && widget.keys) {
      // As in After Effects, Figma and Blender, Tab keeps this number and opens the next field for typing.
      // If the typed number is not accepted, focus stays here.
      if (_commit()) {
        final back = HardwareKeyboard.instance.isShiftPressed;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Wait until this field's own editor is gone, because until then it would be the next focus target.
          _tabbed = true;
          back ? _node.previousFocus() : _node.nextFocus();
          // Reset in a separate microtask, after the focus has moved.
          scheduleMicrotask(() => _tabbed = false);
        });
      }
      return KeyEventResult.handled;
    }
    if (widget.step case final step? when e.logicalKey == LogicalKeyboardKey.arrowUp || e.logicalKey == LogicalKeyboardKey.arrowDown) {
      // As in After Effects and Figma, the arrows move the number typed so far by one step.
      final t = double.tryParse(halfWidth(_ctl.text).trim()) ?? widget.value();
      if (t == null) return KeyEventResult.handled;
      final up = e.logicalKey == LogicalKeyboardKey.arrowUp ? 1 : -1;
      _ctl.text = widget.text(_reach(t + up * step * _mult()), double.infinity);
      _ctl.selection = TextSelection(baseOffset: 0, extentOffset: _ctl.text.length);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  double? _typed() => (widget.parse ?? double.tryParse)(halfWidth(_ctl.text).trim());
  void _say(double t) => (widget.onType ?? widget.onChange)?.call(t);

  bool _commit() {
    if (_ctl.text.trim().isEmpty) {
      // Nothing typed: same as Esc.
      _close();
      return true;
    }
    final t = _typed();
    if (t == null) {
      // Invalid text keeps the field open and shows "Number required".
      setState(() => _err = true);
      return false;
    }
    _say(t);
    _close();
    return true;
  }

  void _close({bool refocus = true}) {
    if (!_editing) return;
    setState(() => _editing = false);
    // A field that does not keep the keys gives them back to the window.
    if (refocus) widget.keys ? _node.requestFocus() : _ef.unfocus();
  }

  void _editFocus() {
    if (_editing && !_ef.hasFocus) {
      // Leaving the field applies a valid number and discards an invalid one.
      final t = widget.sayOnLeave ? _typed() : null;
      if (t != null) _say(t);
      _close(refocus: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value(), live = _drag && _moved, accent = widget.accent;
    final style = widget.style ?? (widget.inline ? TextStyles.value(Grey.g91).copyWith(fontSize: TextStyles.px(10.5)) : blockValue(Grey.g95));
    return LayoutBuilder(
      builder: (context, box) {
        final w = _w = box.maxWidth;
        final Widget value = v == null
            ? Text('Mixed', style: TextStyles.label(Grey.g76))
            : FittedBox(
                // A number wider than its field is drawn smaller, never cut off.
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      // Fixed decimal places, as Push shows them, so the width does not jump as the number changes.
                      TextSpan(text: widget.text(v, w), style: style),
                      if (widget.unit?.call(v, w) case final unit? when unit.isNotEmpty) TextSpan(text: '\u2009$unit', style: TextStyles.label(Grey.g44)),
                    ],
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              );
        final editor = _editing
            ? TextGestures(
                key: widget.editorKey,
                field: (k) => EditableText(
                  key: k,
                  rendererIgnoresPointer: true,
                  controller: _ctl,
                  focusNode: _ef,
                  style: style,
                  cursorColor: accent ?? Grey.g95,
                  backgroundCursorColor: Grey.g20,
                  selectionColor: accent?.withValues(alpha: .3) ?? Role.selected.withValues(alpha: .4),
                  textAlign: widget.inline ? TextAlign.right : TextAlign.left,
                  maxLines: 1,
                  // _startEdit sets the selection: all of the number when editing starts by click or Return, and the caret after the first
                  // character when it starts by typing. Flutter's default select-all on desktop focus would make the next key replace it.
                  selectAllOnFocus: false,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [if (widget.allow case final letters?) FilteringTextInputFormatter.allow(RegExp(letters))],
                  onChanged: (_) {
                    if (_err) setState(() => _err = false);
                  },
                ),
              )
            : null;
        final body =
            widget.paint?.call(context, editor ?? value, _editing) ??
            paintNumber(
              context,
              NumberSpec(
                value: value,
                editor: editor,
                lead: _err && w >= 150 ? Text('Number required', style: TextStyles.label(Role.error)) : null,
                glyph: widget.glyph,
                caption: widget.caption,
                width: w,
                height: widget.height ?? Shape.z(widget.inline ? 22 : 42),
                fillColor: widget.picked ? Color.alphaBlend(Accent.fill.withValues(alpha: .14), Grey.g15) : (_hover || live ? Grey.g20 : Grey.g15),
                borderColor: widget.picked
                    ? Accent.ink.withValues(alpha: .7)
                    : (live ? Role.selected.withValues(alpha: .8) : (_focus || _editing ? Grey.g63 : const Color(0x00000000))),
                rangeColor: accent ?? Grey.g56,
                fill: _bounded && v != null ? ((v - widget.min!) / (widget.max! - widget.min!)).clamp(0.0, 1.0) : null,
                zeroAt: _zeroAt,
                bipolar: _bounded && widget.bipolar,
                editing: _editing,
                glyphTall: widget.glyphTall,
                hot: _hover,
                live: live,
                keyDot: widget.keyDot,
                keyEmpty: widget.keyEmpty,
                pad: widget.pad ?? (widget.inline ? 7 : Shape.s(8)),
                glyphBox: widget.glyphBox ?? Shape.z(20),
                inline: widget.inline,
              ),
            );
        return Actions(
          // As in After Effects and Figma, Cmd+A in a focused field selects its number, not everything in the window.
          actions: {if (widget.keys) SelectAllTextIntent: CallbackAction<SelectAllTextIntent>(onInvoke: (_) => _startEdit())},
          child: Focus(
            focusNode: _node,
            canRequestFocus: widget.keys,
            skipTraversal: !widget.keys,
            onKeyEvent: _key,
            onFocusChange: (f) {
              setState(() => _focus = f);
              if (f && _tabbed) {
                _tabbed = false;
                _startEdit();
              }
            },
            child: RawGestureDetector(
              // A press that scrubs belongs to the field at once. Otherwise a scroll view around the inspector would also take
              // a vertical drag and carry the field away under the pointer. A press on a glyph that owns it, or while typing, is not claimed.
              gestures: {
                ScrubClaim: GestureRecognizerFactoryWithHandlers<ScrubClaim>(
                  () => ScrubClaim(),
                  (r) => r.takes = (e) => !_editing && !(widget.ownsPress?.call(e.localPosition, _w) ?? false),
                ),
              },
              child: Listener(
                onPointerDown: _onDown,
                onPointerMove: _onMove,
                onPointerUp: _onUp,
                onPointerCancel: _onCancel,
                onPointerSignal: _onSignal,
                onPointerPanZoomUpdate: _onPan,
                child: MouseRegion(
                  cursor: _editing || widget.perPx == null ? SystemMouseCursors.text : SystemMouseCursors.resizeLeftRight,
                  onEnter: (_) => setState(() => _hover = true),
                  onExit: (_) => setState(() => _hover = false),
                  // Drawn inverted when past the vouched range, or when a drag is taking it there.
                  child: (widget.past?.call(live) ?? false) ? ColorFiltered(colorFilter: pastInk, child: body) : body,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
