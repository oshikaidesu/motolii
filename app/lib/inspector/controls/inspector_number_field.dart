import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/picks.dart' show clickKeys;
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/rows/row_info.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/context_menu.dart'
    show ContextMenu, ContextMenuItem, ContextMenuState;
import 'package:motolii/widgets/number_field.dart';
import 'package:motolii/widgets/number_format.dart';

/// A [NumberField] wired to the document, with a caption and an optional glyph.
class InspectorNumberField extends StatefulWidget {
  const InspectorNumberField(
    this.p, {
    super.key,
    required this.id,
    required this.caption,
    this.glyph,
    this.glyphOwnsPointer = false,
    this.glyphTall = false,
    this.compact = false,
    this.onSet,
  });

  /// The parameter as its card declares it.
  final Parameter p;

  /// The document id of the number this field edits.
  final String id;

  /// The label shown above the value.
  final String caption;

  /// A picture of the value, drawn in the top-right corner.
  final Widget? glyph;

  /// Whether a press on [glyph] belongs to the glyph instead of starting a drag on the number.
  final bool glyphOwnsPointer;

  /// Whether the glyph spans the block's full height on the right.
  final bool glyphTall;

  /// One row high, the number alone.
  final bool compact;

  /// Sets a new value instead of this field's id alone (for linked axes).
  final ValueChanged<double>? onSet;
  @override
  State<InspectorNumberField> createState() => InspectorNumberFieldState();
}

/// Wraps a card's fields to let values be dragged past the slider's ends.
/// Option-drag goes past for a single gesture (quasimode).
class PastRange extends InheritedWidget {
  const PastRange({super.key, required this.flag, required super.child});

  /// The document flag that allows going past the slider's ends.
  final String flag;

  /// The flag of the nearest [PastRange], or null outside one.
  static String? of(BuildContext c) =>
      c.getInheritedWidgetOfExactType<PastRange>()?.flag;
  @override
  bool updateShouldNotify(PastRange o) => o.flag != flag;
}

/// Whether a drag under [c] may go past the slider's ends: the card allows it (see [PastRange]), or Option is held.
bool goingPast(BuildContext c, InspectorValues doc) {
  final flag = PastRange.of(c);
  return (flag != null && (doc.flags[flag] ?? false)) ||
      HardwareKeyboard.instance.isAltPressed;
}

// Width thresholds shared by the whole panel.
// A cell narrower than unitMinWidth drops its unit. A cell narrower than decimalsMinWidth drops decimals, but never rounds to a false 0.
const unitMinWidth = 72.0, decimalsMinWidth = 60.0;

/// The document side of a number field: read/write, range, multi-select, keyframe mark, right-click menu.
class InspectorNumberFieldState extends State<InspectorNumberField> {
  final _menu = GlobalKey<ContextMenuState>();

  InspectorScope get _x => InspectorScope.read(context);
  Parameter get _p => widget.p;

  // Angles past 360° are shown as full turns: 1x 30°.
  bool get _turns => _p.look == ParameterLook.angle;

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
    super.dispose();
  }

  // Whether the card allows values past the slider's ends. See [PastRange].
  bool get _pastCard => switch (PastRange.of(context)) {
    final f? => _x.doc.flags[f] ?? false,
    _ => false,
  };

  bool get _going => goingPast(context, _x.doc);

  // With several fields selected, typing sets them all to the value, while a drag or nudge moves them all by the same amount.
  void _apply(double v, {bool same = false}) {
    final c = _p.typed(v);
    final doc = _x.doc;
    if (doc.fields.isPicked(widget.id)) {
      final d = c - (doc.get(widget.id) ?? c);
      doc.setMany({
        for (final id in doc.fields.picked)
          id: id == widget.id || same ? c : (doc.get(id) ?? 0) + d,
      });
      return;
    }
    if (widget.onSet case final set?) return set(c);
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
          if (doc.get(id) case final v?) {
            Clipboard.setData(ClipboardData(text: formatNumber(v, _p.dec)));
          }
        },
      ),
      (
        'paste',
        'Paste',
        () async {
          final t = double.tryParse(
            (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '',
          );
          if (t != null && mounted) _apply(t, same: true);
        },
      ),
      if (PastRange.of(context) case final f?)
        // This toggles the flag for the whole card.
        (
          'past',
          _pastCard ? 'Stop at Range Ends' : 'Go Past Range Ends',
          () => doc.flag(f, !_pastCard),
        ),
      if (ks != KeyframeState.at)
        ('key', 'Key this frame', () => doc.setKey(id, KeyframeState.at)),
      if (ks == KeyframeState.at)
        ('unkey', 'Remove key', () => doc.setKey(id, KeyframeState.anim)),
      if (ks != KeyframeState.off)
        (
          'unanimate',
          'Remove animation',
          () => doc.setKey(id, KeyframeState.off),
        ),
    ];
  }

  void _reset() {
    final doc = _x.doc, id = widget.id;
    if (id.startsWith('v_') && doc.actions.onCardReset != null) {
      // Use the card's own Reset, which restores the effect's real default. The Inspector's default is only the value from when the card was made.
      doc.actions.onCardReset!([id.substring(2)]);
    } else {
      doc.resetIds([id]);
    }
  }

  bool _inGlyph(Offset p, double w) =>
      widget.glyph != null &&
      widget.glyphOwnsPointer &&
      p.dx > w - InspectorSkin.glyph - InspectorSkin.tilePad &&
      (widget.glyphTall || p.dy < InspectorSkin.glyph + InspectorSkin.tilePad);

  // Whether the keyframe mark is drawn, and its state.
  bool _marked = false;
  KeyframeState _keys = KeyframeState.off;

  // True = handled here, false = handled as selection, null = leave to the field.
  bool? _press(PointerDownEvent e, double w) {
    if (e.buttons == kSecondaryButton) {
      _menu.currentState?.show(e.localPosition, [
        for (final (k, l, f) in _menuItems())
          ContextMenuItem(l, f, id: 'num-$k:${widget.id}'),
      ]);
      return true;
    }
    if (_marked &&
        e.buttons == kPrimaryButton &&
        (e.localPosition - Offset(w - _pad - 3, _height - 10)).distance <= 9) {
      // Read the document's current state, because the field may not have been rebuilt since an undo.
      final now = _x.doc.keys[widget.id] ?? _keys;
      // Pressing the mark adds a keyframe at this time or removes it.
      _x.doc.setKey(
        widget.id,
        now == KeyframeState.at ? KeyframeState.anim : KeyframeState.at,
      );
      return true;
    }
    if (_inGlyph(e.localPosition, w) || e.buttons != kPrimaryButton) {
      return true;
    }
    final doc = _x.doc;
    final k = clickKeys();
    if (k.add || k.span) {
      // Shift = span, Cmd = toggle (picks.dart).
      doc.fields.pick(widget.id, span: k.span, add: k.add);
      return false;
    }
    if (!doc.fields.isPicked(widget.id)) doc.fields.pick(widget.id);
    return null;
  }

  double get _height =>
      widget.compact ? InspectorSkin.cell : InspectorSkin.tile;
  double get _pad => widget.compact ? 7 : InspectorSkin.tilePad;

  KeyEventResult _key(KeyEvent e) {
    if (e.logicalKey != LogicalKeyboardKey.escape ||
        _x.doc.fields.picked.length <= 1) {
      return KeyEventResult.ignored;
    }
    _x.doc.fields.unpick();
    return KeyEventResult.handled;
  }

  // Text starting with * or / continues from the current value.
  double? _typed(String said) {
    final cur = _x.doc.get(widget.id);
    return double.tryParse(said) ??
        _x.doc.actions.onSum?.call(
          said.startsWith(RegExp(r'[*/]')) && cur != null ? '$cur$said' : said,
        );
  }

  // Whether the value is outside the range the card vouches for, or is being dragged there. It is drawn inverted.
  bool _past(bool live) {
    final v = _x.doc.get(widget.id), min = _p.min, max = _p.max;
    return (!_turns &&
            min != null &&
            max != null &&
            v != null &&
            (v < min || v > max)) ||
        (live &&
            _going &&
            (_p.open || _p.validMin != null || _p.validMax != null));
  }

  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context);
    // Dim dot = animated, lit dot = keyframe at playhead, hollow = can be keyed but has none.
    final ks = _keys = x.doc.keys[widget.id] ?? RowInfo.of(context).keys;
    _marked = ks != KeyframeState.off || x.doc.keys.containsKey(widget.id);
    return ContextMenu(
      key: _menu,
      child: NumberField(
        // Strip the `v_` prefix so the field shows the engine's name.
        name: widget.id.startsWith('v_') ? widget.id.substring(2) : widget.id,
        value: () => _x.doc.get(widget.id),
        text: (v, w) => formatNumber(v, _p.dec, tight: w < decimalsMinWidth),
        // A compact field's row names the unit once, before its cells.
        unit: (v, w) => w < unitMinWidth || widget.compact
            ? ''
            : (_turns && v.abs() >= 360 && w >= 120
                  ? '° ${(v / 360).truncate()}x ${formatNumber(v.remainder(360), 0)}'
                  : _p.unit),
        keys: true,
        typeOnTap: false,
        perPx: _p.perPx,
        step: _p.dec > 0 ? _p.step * 10 : 1,
        reach: (to, from) =>
            from == null ? _p.typed(to) : _p.scrubbed(to, from, past: _going),
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
        bipolar: _p.look == ParameterLook.bipolar,
        caption: widget.compact ? null : widget.caption,
        inline: widget.compact,
        glyph: widget.glyph,
        glyphTall: widget.glyphTall,
        glyphBox: InspectorSkin.glyph,
        keyDot: !_marked
            ? null
            : (ks == KeyframeState.at
                  ? InspectorSkin.keyDot
                  : (ks == KeyframeState.anim
                        ? InspectorSkin.keyDot.withValues(alpha: .5)
                        : Grey.g56)),
        keyEmpty: ks == KeyframeState.off,
        picked: x.doc.fields.isPicked(widget.id),
        height: _height,
        pad: _pad,
      ),
    );
  }
}
