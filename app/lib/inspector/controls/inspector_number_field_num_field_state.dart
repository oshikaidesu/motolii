import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/skin/tokens.dart';

import 'package:motolii/widgets/number_field.dart';

/// The Inspector's side of a number field.
///
/// [NumberField] handles dragging and typing. This state adds the document it reads and writes, the range it holds the value to,
/// multi-selection of fields, the keyframe mark and the right-click menu.
class NumFieldState extends State<NumField> {
  final _menu = ContextMenuController();
  Offset _menuAt = Offset.zero;

  /// The pointer id of the right-click press that opened a field's menu, so the surrounding row does not handle it too.
  static int rightAt = -1;

  Ctx get _x => Ctx.read(context);
  Param get _p => widget.p;

  // An angle past 360 degrees is shown as full turns, as in After Effects: 1x 30°.
  bool get _turns => _p.look == ParamLook.angle;

  // Rebuilds only this field when its value changes, not the whole Inspector.
  ValueListenable<int>? _watch;
  void _retold() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The key watcher makes the keyframe mark follow the document immediately instead of one step behind.
    final w = _x.doc.watch(widget.id), k = _x.doc.watch('key:${widget.id}');
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
    _menu.remove();
    super.dispose();
  }

  // Limits a value to its range.
  // With Param.open, min and max only bound dragging, and a typed number may go past them. The one limit kept is a min of 0 or more.
  // Otherwise validMin and validMax bound typed numbers. They follow After Effects' PF_FloatSliderDef, whose valid_min and
  // valid_max are separate from its slider_min and slider_max, which correspond to min and max here.
  double _clamp(double v) => math.min(
    _p.open ? double.infinity : _p.validMax ?? _p.max ?? double.infinity,
    math.max(_p.open && (_p.min ?? 0) < 0 ? double.negativeInfinity : _p.validMin ?? _p.min ?? double.negativeInfinity, v),
  );
  // Whether the card allows values past the slider's ends. See [PastRange].
  bool get _pastCard => switch (PastRange.of(context)) {
    final f? => _x.doc.b[f] ?? false,
    _ => false,
  };

  // Holding Option also allows going past the ends.
  bool get _going => _pastCard || HardwareKeyboard.instance.isAltPressed;

  // A drag stops at the slider's ends, or at the current value if a typed number already lies beyond them.
  // An angle drags as far as a typed one may go, as in After Effects, and so does a drag that is allowed past the ends.
  double _scrubbed(double v, double start) => _turns || _going || (!_p.open && _p.validMin == null && _p.validMax == null)
      ? _clamp(v)
      : math.min(math.max(_p.max ?? double.infinity, start), math.max(math.min(_p.min ?? double.negativeInfinity, start), v));

  // With several fields selected, typing sets them all to the value, while a drag or nudge moves them all by the same amount.
  void _apply(double v, {bool same = false}) {
    final c = _clamp(v);
    final doc = _x.doc;
    if (doc.isPicked(widget.id)) {
      final d = c - (doc.get(widget.id) ?? c);
      doc.setMany({for (final id in doc.picked) id: id == widget.id || same ? c : (doc.get(id) ?? 0) + d});
      return;
    }
    _x.doc.set(widget.id, c);
  }

  // The right-click menu: the keyframe actions match the mark. The rest of the row's menu is on the row's own label.
  List<(String, String, VoidCallback)> _menuItems() {
    final doc = _x.doc, id = widget.id, ks = doc.keys[id] ?? _keys;
    return [
      ('reset', 'Reset', _reset),
      (
        'copy',
        'Copy',
        () {
          if (doc.get(id) case final v?) Clipboard.setData(ClipboardData(text: fmt(v, _p.dec)));
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
        // This toggles the flag for the whole card.
        ('past', _pastCard ? 'Stop at Range Ends' : 'Go Past Range Ends', () => doc.flag(f, !_pastCard)),
      if (ks != KeyS.at) ('key', 'Key this frame', () => doc.setKey(id, KeyS.at)),
      if (ks == KeyS.at) ('unkey', 'Remove key', () => doc.setKey(id, KeyS.anim)),
      if (ks != KeyS.off) ('unanimate', 'Remove animation', () => doc.setKey(id, KeyS.off)),
    ];
  }

  void _reset() {
    final doc = _x.doc, id = widget.id;
    if (id.startsWith('v_') && doc.onCardReset != null) {
      // Use the card's own Reset, which restores the effect's real default. The Inspector's default is only the value from when the card was made.
      doc.onCardReset!([id.substring(2)]);
    } else {
      doc.resetIds([id]);
    }
  }

  bool _inGlyph(Offset p, double w) =>
      widget.glyph != null && widget.glyphOwnsPointer && p.dx > w - Pop.glyph - Pop.tilePad && (widget.glyphTall || p.dy < Pop.glyph + Pop.tilePad);

  // Whether the keyframe mark is drawn, and its state. Pressing the mark adds a keyframe at this time or removes it.
  bool _marked = false;
  KeyS _keys = KeyS.off;

  bool _inMe(Offset at) {
    final box = context.findRenderObject() as RenderBox?;
    return box != null && (box.localToGlobal(Offset.zero) & box.size).contains(at);
  }

  // Handles a pointer-down before the field starts a drag.
  // True means handled here, false means handled as a selection, and null leaves it to the field.
  bool? _press(PointerDownEvent e, double w) {
    if (e.buttons == kSecondaryButton) {
      // A right click on a value opens its menu, as in After Effects and Blender. It works for every number, with the mouse alone.
      rightAt = e.pointer;
      _menuAt = e.position;
      _menu.show(
        context: context,
        contextMenuBuilder: (_) => TinyMenuAt(
          at: _menuAt,
          name: 'num',
          of: widget.id,
          items: _menuItems(),
          hide: _menu.remove,
          // A second right press on this field keeps the menu open, as on macOS.
          keep: (e) => e.pointer == rightAt && e.buttons == kSecondaryButton && _inMe(e.position),
        ),
      );
      return true;
    }
    if (_marked && e.buttons == kPrimaryButton && (e.localPosition - Offset(w - Pop.tilePad - 3, Pop.tile - 10)).distance <= 9) {
      // Read the document's current state, because the field may not have been rebuilt since an undo.
      final now = _x.doc.keys[widget.id] ?? _keys;
      // Pressing the mark adds a keyframe at this time or removes it.
      _x.doc.setKey(widget.id, now == KeyS.at ? KeyS.anim : KeyS.at);
      return true;
    }
    if (_inGlyph(e.localPosition, w) || e.buttons != kPrimaryButton) return true;
    final doc = _x.doc;
    if (HardwareKeyboard.instance.isShiftPressed) {
      doc.pick(widget.id, span: true);
      return false;
    }
    if (!doc.isPicked(widget.id)) doc.pick(widget.id);
    return null;
  }

  KeyEventResult _key(KeyEvent e) {
    if (e.logicalKey != LogicalKeyboardKey.escape || _x.doc.picked.length <= 1) return KeyEventResult.ignored;
    _x.doc.unpick();
    return KeyEventResult.handled;
  }

  // Parses typed text as a number or an expression, as After Effects, Figma and Blender do.
  // Text starting with * or / continues from the current value.
  double? _typed(String said) {
    final cur = _x.doc.get(widget.id);
    return double.tryParse(said) ?? _x.doc.onSum?.call(said.startsWith(RegExp(r'[*/]')) && cur != null ? '$cur$said' : said);
  }

  // Whether the value is outside the range the card vouches for, or is being dragged there. It is drawn inverted.
  bool _past(bool live) {
    final v = _x.doc.get(widget.id), min = _p.min, max = _p.max;
    return (!_turns && min != null && max != null && v != null && (v < min || v > max)) ||
        (live && _going && (_p.open || _p.validMin != null || _p.validMax != null));
  }

  @override
  Widget build(BuildContext context) {
    final x = Ctx.of(context);
    // A dim dot means animated, and a lit dot means a keyframe at the playhead. A value that can be keyed always shows its mark,
    // hollow when it has no keyframes, and pressing the mark adds a keyframe there.
    // This follows Alight Motion's diamond beside each value and the stopwatch in After Effects and Premiere Pro.
    final ks = _keys = x.doc.keys[widget.id] ?? RowInfo.of(context).keys;
    _marked = ks != KeyS.off || x.doc.keys.containsKey(widget.id);
    return NumberField(
      value: () => _x.doc.get(widget.id),
      text: (v, w) => fmt(v, _p.dec, tight: w < wTight),
      unit: (v, w) => w < wUnit ? '' : (_turns && v.abs() >= 360 && w >= 120 ? '° ${(v / 360).truncate()}x ${fmt(v.remainder(360), 0)}' : _p.unit),
      keys: true,
      typeOnTap: false,
      perPx: _p.perPx,
      step: _p.dec > 0 ? _p.step * 10 : 1,
      // Both limits come from _clamp's ends, following After Effects' PF_FloatSliderDef.
      reach: (to, from) => from == null ? _clamp(to) : _scrubbed(to, from),
      parse: _typed,
      onGrab: () => _x.doc.beginGesture(),
      onChange: _apply,
      onBy: (d) => _x.doc.delta(widget.id, d),
      onType: (v) => _apply(v, same: true),
      onDrop: () => _x.doc.endGesture(),
      onReset: _reset,
      onPress: _press,
      ownsPress: _inGlyph,
      onKey: _key,
      past: _past,
      min: _p.min,
      max: _p.max,
      bipolar: _p.look == ParamLook.bipolar,
      caption: widget.caption,
      glyph: widget.glyph,
      glyphTall: widget.glyphTall,
      glyphBox: Pop.glyph,
      keyDot: !_marked ? null : (ks == KeyS.at ? Pop.keyDot : (ks == KeyS.anim ? Pop.keyDot.withValues(alpha: .5) : Grey.g56)),
      keyEmpty: ks == KeyS.off,
      picked: x.doc.isPicked(widget.id),
      height: Pop.tile,
      pad: Pop.tilePad,
    );
  }
}
