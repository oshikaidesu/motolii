// number_field.dart: the one number of the window: dragged sideways it changes (Shift finer, Cmd or Ctrl ten times), a
// wheel or two fingers slid sideways over it do the same, the arrows nudge it, and it is typed in. It holds no number
// and limits none: it reads its value when it needs it, says each change, and its min and max only place the mark it
// shows. How far a hand takes it is its owner's to say (reach), with where that limit comes from. Its picture is the
// skin's form (number_paint.dart), or its owner's (paint). A panel gives it value, text and onChange.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../skin/forms/number_paint.dart';
import '../skin/tokens.dart';
import 'text_gestures.dart';

// [open] two clicks within this are a double click.
const dblParts = Duration(milliseconds: 320);

/// Past what is vouched for: a number drawn the other way about, light for dark (Flutter's ColorFilter.matrix inversion).
const pastInk = ColorFilter.matrix(<double>[-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]);

/// The number's own type in a tile (a row's is T.value at 10.5).
TextStyle blockValue(Color c) => T.value(c).copyWith(fontSize: T.px(14), fontWeight: FontWeight.w600, height: 1.1);

class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.value,
    required this.text,
    this.unit,
    this.onChange,
    this.onBy,
    this.onType,
    this.onGrab,
    this.onDrop,
    this.onReset,
    this.perPx,
    this.step,
    this.reach,
    this.parse,
    this.allow = r'[0-9.\-+eE*/() ]',
    this.keys = false,
    this.typeOnTap = true,
    this.sayOnLeave = true,
    this.onPress,
    this.ownsPress,
    this.onKey,
    this.past,
    this.min,
    this.max,
    this.bipolar = false,
    this.caption,
    this.glyph,
    this.glyphTall = false,
    this.glyphBox,
    this.keyDot,
    this.keyEmpty = false,
    this.picked = false,
    this.inline = false,
    this.height,
    this.pad,
    this.style,
    this.accent,
    this.editorKey,
    this.paint,
  });

  /// The number now, read each time it is needed (under a hand its owner need not build again); null: several numbers,
  /// shown as Mixed and moved by [onBy]. [text]: how it reads in a field `room` wide, and what typing begins from (room
  /// without end); [unit]: small after it ('': none).
  final double? Function() value;
  final String Function(double value, double room) text;
  final String Function(double value, double room)? unit;

  /// What a hand does; one left out does nothing. [onChange]: where the number is taken, each move of a drag, a slide
  /// or a nudge, and what was typed where [onType] is not given. [onBy]: how far, while [value] is null. [onGrab] and
  /// [onDrop]: a drag's first move and its letting go (Esc or a cancel puts the number back, then drops), for an owner
  /// that makes one step of a drag. [onReset]: a double press, and Delete or Backspace where it has the [keys].
  final ValueChanged<double>? onChange, onBy, onType;
  final VoidCallback? onGrab, onDrop, onReset;

  /// [perPx]: how much a pixel dragged or slid moves it (none: not scrubbed, the cursor a text field's). [step]: how
  /// much an arrow key does (none: the arrows are not its). [reach]: how far a hand takes it: a drag begun at `from`,
  /// or (from null) a slide, a nudge, a step of what is being typed. A number typed never passes through it. [parse]:
  /// the number that what was typed says (null: none, and the field stays open); not given, a plain number. [allow]:
  /// the letters it may be typed in, a RegExp (null: any).
  final double? perPx, step;
  final double Function(double to, double? from)? reach;
  final double? Function(String said)? parse;
  final String? allow;

  /// [keys]: a press gives it the keys and it keeps them (the arrows, Return or a digit to type, Tab on to the next,
  /// Delete), as the Inspector's fields; without, it has them only while typed in. [typeOnTap]: pressed and let go, it
  /// is typed (so no double press). [sayOnLeave] false: only Return says what was typed ([TypedField]'s).
  final bool keys, typeOnTap, sayOnLeave;

  /// Its owner's own hands. [onPress]: asked of every press first: true, the press is the owner's (a menu, a mark) and
  /// the field does nothing; false, the owner's, the field taking the keys and no more (a pick); null, the field's.
  /// [ownsPress]: a press there is not a scrub and not claimed (a dial in it). [onKey]: asked of a key after a drag's
  /// Esc, before the field's own. [past]: drawn the other way about ([pastInk]), asked while a hand drags it or not.
  final bool? Function(PointerDownEvent e, double room)? onPress;
  final bool Function(Offset at, double room)? ownsPress;
  final KeyEventResult Function(KeyEvent e)? onKey;
  final bool Function(bool live)? past;

  /// The skin's form (it fills the width it is given): [caption] over the number, or before it on one row ([inline]);
  /// [min] and [max], the ends of the mark that shows where the number lies (both, or no mark; [bipolar]: a range
  /// around zero fills out from the middle); [glyph], a picture of the value, in the corner ([glyphTall]: the full
  /// height); [keyDot], its key mark ([keyEmpty]: hollow); [picked], one of several picked; [accent], the mark's colour
  /// and the caret's. [paint]: its owner's picture instead (a quiet readout), given the number as text or, while
  /// `typing`, its editor ([editorKey]).
  final String? caption;
  final Widget? glyph;
  final bool bipolar, glyphTall, keyEmpty, picked, inline;
  final double? min, max, glyphBox, height, pad;
  final Color? keyDot, accent;
  final TextStyle? style;
  final Key? editorKey;
  final Widget Function(BuildContext context, Widget shown, bool typing)? paint;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

/// The field's claim on a press that scrubs it: taken at once, before a scroll round it can (Flutter's EagerGestureRecognizer, asked first).
class ScrubClaim extends EagerGestureRecognizer {
  bool Function(PointerDownEvent) takes = (_) => false;
  @override
  bool isPointerAllowed(PointerDownEvent event) => takes(event) && super.isPointerAllowed(event);
}

class _NumberFieldState extends State<NumberField> {
  final _node = FocusNode(debugLabel: 'num');
  late final FocusNode _ef = FocusNode(debugLabel: 'num-edit', onKeyEvent: _editKey)..addListener(_editFocus);
  static bool _tabbed = false; // (the field that takes focus now was gone to by Tab: it opens to be typed in)
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

  /// Shift is finer, Cmd or Ctrl is ten times (Ableton Live's manual 42.6; the same keys on a scrub, a wheel, and the arrows).
  double _mult() {
    final k = HardwareKeyboard.instance;
    if (k.isShiftPressed) return .1;
    if (k.isMetaPressed || k.isControlPressed) return 10;
    return 1;
  }

  double _tidy(double v) => double.parse(v.toStringAsFixed(6));
  double _reach(double to, [double? from]) => widget.reach?.call(to, from) ?? to;

  // contract: Esc during a drag puts the value back and ignores the rest of the drag; pointer cancel does the same (C3).
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
      widget.onGrab?.call(); // (a scrub is one gesture: what it shows is settled when the hand lets go)
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
    if (mounted) setState(() {}); // (while a hand is on it the inspector is not built again: this field shows its own number)
  }

  void _onUp(PointerUpEvent e) {
    if (!_drag) return;
    _drag = false;
    if (_moved) {
      widget.onDrop?.call();
      setState(() => _moved = false);
      return;
    }
    if (widget.typeOnTap && (e.position - _down).distance < kTouchSlop) return _startEdit(); // (pressed and let go where it was: it is typed)
    final now = DateTime.now(), dbl = _lastUp != null && now.difference(_lastUp!) < dblParts;
    _lastUp = dbl ? null : now;
    if (dbl) widget.onReset?.call();
  }

  void _onCancel(PointerCancelEvent e) {
    if (_drag && _moved) _abort();
    _drag = false;
    _moved = false;
  }

  // contract: hover and slide sideways, every number the same way: slide right = more, left = less, at the drag's rate (perPx, Shift/Alt per the
  // panel's modifier rule), so a slide and a scrub of the same length move a value the same amount. An up/down slide is not claimed, so it scrolls
  // the panel. No button needs holding (do-not-repeat 4).
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
    final cur = widget.value(); // (a slide or a nudge: so far from where the number is now)
    cur == null ? widget.onBy?.call(d) : widget.onChange?.call(_reach(_tidy(cur + d)));
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (_editing && !_ef.hasFocus) {
      // (the editor has the keys a frame on: what comes before that is its all the same, golf_noise.md (113))
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
    // (typed: the number begun with that character)
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
      // contract: Esc while typing discards and restores the old value (C3).
      _close();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _commit();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.tab && widget.keys) {
      // (After Effects', Figma's and Blender's Tab: this number kept, the next field ready to type in; a number not taken stays here)
      if (_commit()) {
        final back = HardwareKeyboard.instance.isShiftPressed;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // (once its own editor is gone: that is what comes next till then)
          _tabbed = true;
          back ? _node.previousFocus() : _node.nextFocus();
          scheduleMicrotask(() => _tabbed = false); // (after the focus has gone there, a microtask of its own)
        });
      }
      return KeyEventResult.handled;
    }
    if (widget.step case final step? when e.logicalKey == LogicalKeyboardKey.arrowUp || e.logicalKey == LogicalKeyboardKey.arrowDown) {
      // (After Effects' and Figma's: the number typed so far moved a step)
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
      // (nothing typed: as Esc)
      _close();
      return true;
    }
    final t = _typed();
    if (t == null) {
      // contract: invalid text keeps the field open and says "Number required" (C2).
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
    if (refocus) widget.keys ? _node.requestFocus() : _ef.unfocus(); // (a field that keeps no keys gives them back to the window)
  }

  void _editFocus() {
    if (_editing && !_ef.hasFocus) {
      // contract: leaving the field applies a valid number and drops an invalid one.
      final t = widget.sayOnLeave ? _typed() : null;
      if (t != null) _say(t);
      _close(refocus: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value(), live = _drag && _moved, accent = widget.accent;
    final style = widget.style ?? (widget.inline ? T.value(Grey.g91).copyWith(fontSize: T.px(10.5)) : blockValue(Grey.g95));
    return LayoutBuilder(
      builder: (context, box) {
        final w = _w = box.maxWidth;
        final Widget value = v == null
            ? Text('Mixed', style: T.label(Grey.g76))
            : FittedBox(
                // (a number wider than its field is drawn smaller, never cut)
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: widget.text(v, w), style: style), // (its places fixed, as Push shows them: a number does not jump in width as it moves)
                      if (widget.unit?.call(v, w) case final unit? when unit.isNotEmpty) TextSpan(text: '\u2009$unit', style: T.label(Grey.g44)),
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
                  selectAllOnFocus: false, // (_startEdit says the selection: all of the number when begun by a click or Return; the caret after a number begun by typing it, which Flutter's own select-all on a desktop's focus took, so the next key replaced the first: golf P05, "230" came out 0)
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
                lead: _err && w >= 150 ? Text('Number required', style: T.label(Role.error)) : null,
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
          // (Cmd+A on a field held: all of its number, not every thing in the window; After Effects' and Figma's)
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
              // (a press that scrubs is the field's at once: a scroll round the inspector would take a drag that goes up or
              //  down too and carry the field away under the hand; a press on a glyph that owns it, or while typing, is not)
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
                  // (past what it vouches for, or going there under the hand: drawn the other way about)
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
