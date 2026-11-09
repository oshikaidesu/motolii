import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:motolii/skin/forms/number_paint.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/skin/tokens.dart';

class NumFieldState extends State<NumField> implements TextSelectionGestureDetectorBuilderDelegate {
  final _node = FocusNode(debugLabel: 'num');
  late final FocusNode _ef = FocusNode(debugLabel: 'num-edit', onKeyEvent: _editKey);
  @override
  final editableTextKey = GlobalKey<EditableTextState>();
  @override
  bool get forcePressEnabled => false;
  @override
  bool get selectionEnabled => true;
  late final _gestures = TextSelectionGestureDetectorBuilder(delegate: this);
  final _menu = OverlayPortalController();
  Offset _menuAt = Offset.zero;
  static int rightAt = -1; // (the press a field took for its menu: the row round it leaves it)
  static bool _tabbed = false; // (the field that takes focus now was gone to by Tab: it opens to be typed in)
  final _ctl = TextEditingController();
  bool _editing = false, _hover = false, _focus = false, _drag = false, _moved = false, _cancelled = false;
  Offset _down = Offset.zero;
  double _start = 0, _acc = 0, _sum = 0;
  DateTime? _lastUp;

  Ctx get _x => Ctx.read(context);
  bool get _bounded => widget.min != null && widget.max != null;
  double get _zeroAt => _bounded ? ((0 - widget.min!) / (widget.max! - widget.min!)).clamp(0.0, 1.0) : 0;

  @override
  void initState() {
    super.initState();
    _ef.addListener(_editFocus);
  }

  // (its own number at a new moment, told alone: the inspector is not built again for it)
  ValueListenable<int>? _watch;
  void _retold() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final w = _x.doc.watch(widget.id),
        k = _x.doc.watch('key:${widget.id}'); // (and its key mark's news: showAt tells it, so the mark is drawn as the document says it, not a step behind)
    if (w != _watch) {
      _watch?.removeListener(_retold);
      _watch = w..addListener(_retold);
    }
    if (k != _keyWatch) {
      _keyWatch?.removeListener(_retold);
      _keyWatch = k..addListener(_retold);
    }
  }

  ValueListenable<int>? _keyWatch;

  @override
  void dispose() {
    _watch?.removeListener(_retold);
    _keyWatch?.removeListener(_retold);
    _ef.dispose();
    _node.dispose();
    _ctl.dispose();
    super.dispose();
  }

  double _clamp(double v) => math.min(
    widget.open ? double.infinity : widget.validMax ?? widget.max ?? double.infinity,
    math.max(widget.open && (widget.min ?? 0) < 0 ? double.negativeInfinity : widget.validMin ?? widget.min ?? double.negativeInfinity, v),
  );
  // (its card let past its ends by a right click, or Option held now: PastRange)
  bool get _pastCard => switch (PastRange.of(context)) {
    final f? => _x.doc.b[f] ?? false,
    _ => false,
  };
  bool get _going => _pastCard || HardwareKeyboard.instance.isAltPressed; // (Option goes past the ends)

  /// Shift is finer, Cmd or Ctrl is ten times (Ableton Live's manual 42.6; the same keys on a scrub, a wheel, and the arrows).
  double _mult() {
    final k = HardwareKeyboard.instance;
    if (k.isShiftPressed) return .1;
    if (k.isMetaPressed || k.isControlPressed) return 10;
    return 1;
  }
  // (a scrub stops at the knob's ends, or where a number typed past them already lies; an angle's goes on as far as one
  //  typed, as After Effects' angle scrubs, and so does one going past)
  double _scrubbed(double v) => widget.turns || _going || (!widget.open && widget.validMin == null && widget.validMax == null)
      ? _clamp(v)
      : math.min(math.max(widget.max ?? double.infinity, _start), math.max(math.min(widget.min ?? double.negativeInfinity, _start), v));
  double _tidy(double v) => double.parse(v.toStringAsFixed(6));

  // contract: with several fields picked, typing sets them all; a scrub or nudge moves them all by the same amount.
  void _apply(double v, {bool same = false}) {
    final c = _clamp(v);
    final doc = _x.doc;
    if (doc.isPicked(widget.id)) {
      final d = c - (doc.get(widget.id) ?? c);
      doc.setMany({for (final id in doc.picked) id: id == widget.id || same ? c : (doc.get(id) ?? 0) + d});
      return;
    }
    doc.set(widget.id, c);
  }

  // (what a right click on it offers: its keys as its mark does, the rest of the row's menu on the row's own label)
  List<(String, String, VoidCallback)> _menuItems() {
    final doc = _x.doc, id = widget.id, ks = doc.keys[id] ?? _keys;
    return [
      ('reset', 'Reset', _reset),
      (
        'copy',
        'Copy',
        () {
          if (doc.get(id) case final v?) Clipboard.setData(ClipboardData(text: fmt(v, widget.decimals)));
        },
      ),
      (
        'paste',
        'Paste',
        () async {
          final t = double.tryParse((await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '');
          if (t != null && mounted) _apply(t, same: true);
        },
      ),
      if (PastRange.of(context) case final f?)
        ('past', _pastCard ? 'Stop at Range Ends' : 'Go Past Range Ends', () => doc.flag(f, !_pastCard)), // (its whole card)
      if (ks != null) ...[
        if (ks != KeyS.at) ('key', 'Key this frame', () => doc.setKey(id, KeyS.at)),
        if (ks == KeyS.at) ('unkey', 'Remove key', () => doc.setKey(id, KeyS.anim)),
        if (ks != KeyS.off) ('unanimate', 'Remove animation', () => doc.setKey(id, KeyS.off)),
      ],
    ];
  }

  void _reset() {
    final doc = _x.doc, id = widget.id;
    if (id.startsWith('v_') && doc.onCardReset != null) {
      doc.onCardReset!([
        id.substring(2),
      ]); // (as it comes: what is said of it forgotten, its card's own Reset; the inspector's default is only what it was when the card was made)
    } else {
      doc.resetIds([id]);
    }
  }

  // contract: Esc during a drag puts the value back and ignores the rest of the drag; pointer cancel does the same (C3).
  void _abort() {
    final cur = _x.doc.get(widget.id);
    if (cur == null) {
      _x.doc.delta(widget.id, -_sum);
    } else {
      _apply(_start);
    }
    _cancelled = true;
    _sum = 0;
    if (_moved) _x.doc.endGesture();
    setState(() => _drag = false);
  }

  // (where the key mark is drawn, and what it says: a press near it keys the value there, or takes the key here away)
  Offset? _keyAt;
  KeyS? _keys;

  bool _inMe(Offset at) {
    final box = context.findRenderObject() as RenderBox?;
    return box != null && (box.localToGlobal(Offset.zero) & box.size).contains(at);
  }

  void _onDown(PointerDownEvent e) {
    if (_editing) return;
    if (e.buttons == kSecondaryButton) {
      // (After Effects' and Blender's right click on a value; every number, its row or an effect's knob alike: all by the mouse alone, 10/29)
      rightAt = e.pointer;
      _menuAt = e.position;
      return _menu.show();
    }
    if (_keyAt case final k? when e.buttons == kPrimaryButton && (e.localPosition - k).distance <= 9) {
      final now = _x.doc.keys[widget.id] ?? _keys; // (as the document says it now: the field may not have been built since an undo)
      return _x.doc.setKey(widget.id, now == KeyS.at ? KeyS.anim : KeyS.at); // (a press on the mark keys this frame, or takes that key away)
    }
    if (e.buttons != kPrimaryButton) return;
    final doc = _x.doc;
    if (HardwareKeyboard.instance.isShiftPressed) {
      doc.pick(widget.id, span: true);
      _node.requestFocus();
      return;
    }
    if (!doc.isPicked(widget.id)) doc.pick(widget.id);
    _node.requestFocus();
    _down = e.position;
    _moved = false;
    _cancelled = false;
    _sum = 0;
    _start = _x.doc.get(widget.id) ?? 0;
    _acc = _start;
    _drag = true;
  }

  void _onMove(PointerMoveEvent e) {
    if (!_drag || _cancelled) return;
    if (!_moved && (e.position - _down).distance < 4) return;
    if (!_moved) {
      _x.doc.beginGesture(); // (a scrub is one gesture: what it shows is settled when the hand lets go)
      setState(() => _moved = true);
    }
    final d = e.delta.dx * widget.perPx * _mult();
    if (_x.doc.get(widget.id) == null) {
      _sum += d;
      _x.doc.delta(widget.id, d);
    } else {
      _acc = _scrubbed(_acc + d);
      _apply(_acc);
    }
    if (mounted) setState(() {}); // (while a hand is on it the inspector is not built again: this field shows its own number)
  }

  void _onUp(PointerUpEvent e) {
    if (!_drag) return;
    _drag = false;
    if (_moved) {
      _x.doc.endGesture();
      setState(() => _moved = false);
      return;
    }
    final now = DateTime.now(), dbl = _lastUp != null && now.difference(_lastUp!) < dblParts;
    _lastUp = dbl ? null : now;
    if (dbl) _reset();
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
    if (e is! PointerScrollEvent || _editing) return;
    final d = e.scrollDelta;
    if (d.dx.abs() <= d.dy.abs()) return;
    GestureBinding.instance.pointerSignalResolver.register(e, (ev) => _slide((ev as PointerScrollEvent).scrollDelta.dx));
  }

  void _onPan(PointerPanZoomUpdateEvent e) {
    if (_editing) return;
    final d = e.localPanDelta;
    if (d.dx.abs() > d.dy.abs()) _slide(d.dx);
  }

  void _step(double d) {
    final cur = _x.doc.get(widget.id);
    if (cur == null) {
      _x.doc.delta(widget.id, d);
    } else {
      _apply(_tidy(cur + d));
    }
  }

  void _slide(double right) => _step(right * widget.perPx * _mult());

  void _nudge(int dir) => _step(dir * widget.step * _mult());

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
    if (k == LogicalKeyboardKey.escape && _x.doc.picked.length > 1) {
      _x.doc.unpick();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.arrowRight) {
      _nudge(1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowLeft) {
      _nudge(-1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _startEdit();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.delete || k == LogicalKeyboardKey.backspace) {
      _reset();
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
    final v = _x.doc.get(widget.id);
    _ctl.text = typed ?? (v == null ? '' : fmt(v, widget.decimals));
    _ctl.selection = typed != null ? TextSelection.collapsed(offset: _ctl.text.length) : TextSelection(baseOffset: 0, extentOffset: _ctl.text.length);
    setState(() => _editing = true);
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
    if (e.logicalKey == LogicalKeyboardKey.tab) {
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
    if (e.logicalKey == LogicalKeyboardKey.arrowUp || e.logicalKey == LogicalKeyboardKey.arrowDown) {
      // (After Effects' and Figma's: the number typed so far moved a step)
      final t = double.tryParse(halfWidth(_ctl.text).trim()) ?? _x.doc.get(widget.id);
      if (t == null) return KeyEventResult.handled;
      final up = e.logicalKey == LogicalKeyboardKey.arrowUp ? 1 : -1;
      _ctl.text = fmt(_clamp(t + up * widget.step * _mult()), widget.decimals);
      _ctl.selection = TextSelection(baseOffset: 0, extentOffset: _ctl.text.length);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // (the number typed, or a sum: After Effects', Figma's and Blender's; one begun with * or / goes on from the value as it is)
  double? _typed() {
    final said = halfWidth(_ctl.text).trim(), cur = _x.doc.get(widget.id);
    return double.tryParse(said) ?? _x.doc.onSum?.call(said.startsWith(RegExp(r'[*/]')) && cur != null ? '$cur$said' : said);
  }

  bool _commit() {
    if (_ctl.text.trim().isEmpty) {
      // (nothing typed: as Esc)
      _close();
      return true;
    }
    final t = _typed();
    if (t == null) return false; // (invalid text keeps the field open)
    _apply(t, same: true);
    _close();
    return true;
  }

  void _close({bool refocus = true}) {
    if (!_editing) return;
    setState(() => _editing = false);
    if (refocus) _node.requestFocus();
  }

  void _editFocus() {
    if (_editing && !_ef.hasFocus) {
      // contract: leaving the field applies a valid number and drops an invalid one.
      final t = _typed();
      if (t != null) _apply(t, same: true);
      _close(refocus: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final x = Ctx.of(context);
    final v = x.doc.get(widget.id);
    final live = _drag && _moved;
    const idle = Color(0x00000000);
    final Color edge = live
        ? Role.selected.withValues(alpha: .8)
        : (_focus || _editing ? Grey.g63 : (_hover ? Grey.g38 : idle));
    final picked = x.doc.isPicked(widget.id);
    final fillC = picked ? Color.alphaBlend(Accent.fill.withValues(alpha: .14), Grey.g15) : (_hover || live ? Grey.g20 : Grey.g15);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final row = RowInfo.of(context);
        final showUnit = w >= wUnit, tight = w < wTight;
        final t = (_bounded && v != null) ? ((v - widget.min!) / (widget.max! - widget.min!)).clamp(0.0, 1.0) : 0.0;
        String unit = widget.unit ?? '';
        if (widget.turns && v != null && v.abs() >= 360 && w >= 120) unit = '° ${(v / 360).truncate()}x ${fmt(v.remainder(360), 0)}';
        Widget valueText() {
          if (v == null) return Text('Mixed', style: T.label(Grey.g76));
          return FittedBox(
            // (a number wider than its field is drawn smaller, never cut)
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: fmt(v, widget.decimals, tight: tight), // (its places fixed, as Push shows them: a number does not jump in width as it moves)
                    style: blockValue(Grey.g95),
                  ),
                  if (showUnit && unit.isNotEmpty) TextSpan(text: '\u2009$unit', style: T.label(Grey.g44)),
                ],
              ),
              maxLines: 1,
              softWrap: false,
            ),
          );
        }

        // contract: animated = a dim dot, keyed at the playhead = a lit dot (the automation blip, not a column). A value
        // that takes keys shows its mark always, hollow when it has none, and a press on it keys it there (Alight Motion's
        // diamond beside each value, After Effects' and Premiere Pro's stopwatch: golf_noise.md (59)).
        final ks = x.doc.keys[widget.id] ?? row?.keys;
        _keyAt = ks != null && (ks != KeyS.off || x.doc.keys.containsKey(widget.id)) ? Offset(w - Pop.tilePad - 3, Pop.tile - 10) : null;
        _keys = ks;
        final editor = _editing
            ? _gestures.buildGestureDetector(
                behavior: HitTestBehavior.translucent,
                child: EditableText(
                  key: editableTextKey,
                  rendererIgnoresPointer: true,
                  controller: _ctl,
                  focusNode: _ef,
                  style: blockValue(Grey.g95),
                  cursorColor: Grey.g95,
                  backgroundCursorColor: Grey.g20,
                  selectionColor: Role.selected.withValues(alpha: .4),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  selectAllOnFocus: false, // (_startEdit says the selection: all of the number when begun by a click or Return; the caret after a number begun by typing it, which Flutter's own select-all on a desktop's focus took, so the next key replaced the first: golf P05, "230" came out 0)
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-+eE*/() ]'))],
                ),
              )
            : null;
        final body = usualNumber(
          context,
          NumberSpec(
            value: valueText(),
            editor: editor,
            caption: widget.caption,
            width: w,
            height: Pop.tile,
            fillColor: fillC,
            borderColor: picked ? Accent.ink.withValues(alpha: .7) : (!(_focus || _editing || live) ? const Color(0x00000000) : edge),
            rangeColor: Grey.g56,
            fill: _bounded && v != null ? t : null,
            zeroAt: _zeroAt,
            bipolar: _bounded && widget.bipolar,
            editing: _editing,
            keyDot: _keyAt == null ? null : (ks == KeyS.at ? Accent.key : (ks == KeyS.anim ? Accent.key.withValues(alpha: .5) : Grey.g56)),
            keyEmpty: ks == KeyS.off,
            pad: Pop.tilePad,
          ),
        );
        return OverlayPortal.targetsRootOverlay(
          controller: _menu,
          overlayChildBuilder: (_) => TinyMenuAt(
            at: _menuAt,
            name: 'num',
            of: widget.id,
            items: _menuItems(),
            hide: _menu.hide,
            keep: (e) => e.pointer == rightAt && e.buttons == kSecondaryButton && _inMe(e.position),
          ), // (right pressed here again: its place, as a Mac's)
          child: Actions(
            // (Cmd+A on a field held: all of its number, not every thing in the window; After Effects' and Figma's)
            actions: {SelectAllTextIntent: CallbackAction<SelectAllTextIntent>(onInvoke: (_) => _startEdit())},
            child: Focus(
              focusNode: _node,
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
                //  down too and carry the field away under the hand; while typing, it is not)
                gestures: {
                  ScrubClaim: GestureRecognizerFactoryWithHandlers<ScrubClaim>(
                    () => ScrubClaim(),
                    (r) => r.takes = (e) => !_editing,
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
                    cursor: _editing ? SystemMouseCursors.text : SystemMouseCursors.resizeLeftRight,
                    onEnter: (_) => setState(() => _hover = true),
                    onExit: (_) => setState(() => _hover = false),
                    // (past what it vouches for, or going there under the hand: drawn the other way about)
                    child:
                        (!widget.turns && _bounded && v != null && (v < widget.min! || v > widget.max!)) ||
                            (_drag && _moved && _going && (widget.open || widget.validMin != null || widget.validMax != null))
                        ? ColorFiltered(colorFilter: pastInk, child: body)
                        : body,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
