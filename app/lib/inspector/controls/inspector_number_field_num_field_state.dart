import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/skin/tokens.dart';

import '../../widgets/number_field.dart';

/// The Inspector's side of a number ([NumberField] has the hands and the typing): the document it reads and writes, the
/// range it holds a value to, the fields picked with it, its key mark and what a right click on it offers.
class NumFieldState extends State<NumField> {
  final _menu = ContextMenuController();
  Offset _menuAt = Offset.zero;
  static int rightAt = -1; // (the press a field took for its menu: the row round it leaves it)

  Ctx get _x => Ctx.read(context);
  Param get _p => widget.p;
  bool get _turns => _p.look == ParamLook.angle; // (counted in turns past one, as After Effects' angle: 1x 30°)

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
    _menu.remove();
    super.dispose();
  }

  // (Param.open: min and max are how far a scrub goes; a number typed goes past them, only a min of 0 or more holding
  //  (After Effects' slider and valid ranges, PF_FloatSliderDef). validMin, validMax: how far a number typed goes when it is
  //  less than open's all: PF_FloatSliderDef's valid_min and valid_max, its slider_min and slider_max being min and max.)
  double _clamp(double v) => math.min(
    _p.open ? double.infinity : _p.validMax ?? _p.max ?? double.infinity,
    math.max(_p.open && (_p.min ?? 0) < 0 ? double.negativeInfinity : _p.validMin ?? _p.min ?? double.negativeInfinity, v),
  );
  // (its card let past its ends by a right click, or Option held now: PastRange)
  bool get _pastCard => switch (PastRange.of(context)) {
    final f? => _x.doc.b[f] ?? false,
    _ => false,
  };
  bool get _going => _pastCard || HardwareKeyboard.instance.isAltPressed; // (Option goes past the ends)

  // (a scrub stops at the knob's ends, or where a number typed past them already lies; an angle's goes on as far as one
  //  typed, as After Effects' angle scrubs, and so does one going past)
  double _scrubbed(double v, double start) => _turns || _going || (!_p.open && _p.validMin == null && _p.validMax == null)
      ? _clamp(v)
      : math.min(math.max(_p.max ?? double.infinity, start), math.max(math.min(_p.min ?? double.negativeInfinity, start), v));

  // contract: with several fields picked, typing sets them all; a scrub or nudge moves them all by the same amount.
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

  // (what a right click on it offers: its keys as its mark does, the rest of the row's menu on the row's own label)
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
        ('past', _pastCard ? 'Stop at Range Ends' : 'Go Past Range Ends', () => doc.flag(f, !_pastCard)), // (its whole card)
      if (ks != KeyS.at) ('key', 'Key this frame', () => doc.setKey(id, KeyS.at)),
      if (ks == KeyS.at) ('unkey', 'Remove key', () => doc.setKey(id, KeyS.anim)),
      if (ks != KeyS.off) ('unanimate', 'Remove animation', () => doc.setKey(id, KeyS.off)),
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

  bool _inGlyph(Offset p, double w) =>
      widget.glyph != null && widget.glyphOwnsPointer && p.dx > w - Pop.glyph - Pop.tilePad && (widget.glyphTall || p.dy < Pop.glyph + Pop.tilePad);

  // (whether the key mark is drawn, and what it says: a press near it keys the value there, or takes the key here away)
  bool _marked = false;
  KeyS _keys = KeyS.off;

  bool _inMe(Offset at) {
    final box = context.findRenderObject() as RenderBox?;
    return box != null && (box.localToGlobal(Offset.zero) & box.size).contains(at);
  }

  // (a press before it is a scrub: true, all this side's; false, a pick and the keys; null, the field's own)
  bool? _press(PointerDownEvent e, double w) {
    if (e.buttons == kSecondaryButton) {
      // (After Effects' and Blender's right click on a value; every number, its row or an effect's knob alike: all by the mouse alone, 10/29)
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
          keep: (e) => e.pointer == rightAt && e.buttons == kSecondaryButton && _inMe(e.position), // (right pressed here again: its place, as a Mac's)
        ),
      );
      return true;
    }
    if (_marked && e.buttons == kPrimaryButton && (e.localPosition - Offset(w - Pop.tilePad - 3, Pop.tile - 10)).distance <= 9) {
      final now = _x.doc.keys[widget.id] ?? _keys; // (as the document says it now: the field may not have been built since an undo)
      _x.doc.setKey(widget.id, now == KeyS.at ? KeyS.anim : KeyS.at); // (a press on the mark keys this frame, or takes that key away)
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

  // (the number typed, or a sum: After Effects', Figma's and Blender's; one begun with * or / goes on from the value as it is)
  double? _typed(String said) {
    final cur = _x.doc.get(widget.id);
    return double.tryParse(said) ?? _x.doc.onSum?.call(said.startsWith(RegExp(r'[*/]')) && cur != null ? '$cur$said' : said);
  }

  // (past what it vouches for, or going there under the hand: drawn the other way about)
  bool _past(bool live) {
    final v = _x.doc.get(widget.id), min = _p.min, max = _p.max;
    return (!_turns && min != null && max != null && v != null && (v < min || v > max)) ||
        (live && _going && (_p.open || _p.validMin != null || _p.validMax != null));
  }

  @override
  Widget build(BuildContext context) {
    final x = Ctx.of(context);
    // contract: animated = a dim dot, keyed at the playhead = a lit dot (the automation blip, not a column). A value
    // that takes keys shows its mark always, hollow when it has none, and a press on it keys it there (Alight Motion's
    // diamond beside each value, After Effects' and Premiere Pro's stopwatch: golf_noise.md (59)).
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
      reach: (to, from) => from == null ? _clamp(to) : _scrubbed(to, from), // (both by _clamp's ends: After Effects' PF_FloatSliderDef)
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
