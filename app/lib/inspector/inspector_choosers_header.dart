import 'package:motolii/widgets/fold_mark.dart';
import 'package:motolii/skin/inspector_tokens.dart';

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:motolii/skin/forms/forms.dart';
import 'package:motolii/skin/theme.dart';

import 'package:motolii/widgets/glyphs.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;

/// A dropdown for choosing one of [options], stored as a string under [id].
///
/// A short list belongs in a segmented control and a long one opens a searchable list. It never cycles with previous and next buttons.
class Chooser extends StatefulWidget {
  const Chooser({super.key, required this.id, required this.options});
  final String id;
  final List<String> options;
  @override
  State<Chooser> createState() => ChooserState();
}

class ChooserState extends State<Chooser> {
  bool _open = false, _up = false;
  final _node = FocusNode(debugLabel: 'chooser');
  final _list = ScrollController();
  // The index of the option the keyboard is on.
  int _at = -1;
  // The letters typed to jump to an option. A pause of a second starts them over.
  String _typed = '';
  DateTime _typedAt = DateTime(0);
  void Function(String)? _pick;
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  static const _itemH = 22.0, _maxItems = 8;

  @override
  void dispose() {
    _node.dispose();
    _list.dispose();
    super.dispose();
  }

  List<String> get _hits => widget.options;

  void _go(int to) {
    final n = _hits.length;
    if (n == 0) return;
    setState(() => _at = to.clamp(0, n - 1));
    if (_list.hasClients) {
      final top = _at * _itemH, seen = _maxItems * _itemH;
      if (top < _list.offset) _list.jumpTo(top);
      if (top + _itemH > _list.offset + seen) _list.jumpTo(top + _itemH - seen);
    }
  }

  // Keyboard handling follows the select-only combobox in the W3C ARIA Authoring Practices.
  // Down, Up, Return or Space open the list. The arrows move through it, Return picks the highlighted option and Escape closes it.
  // A typed letter jumps to the first option that starts with it.
  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey, down = k == LogicalKeyboardKey.arrowDown, up = k == LogicalKeyboardKey.arrowUp;
    final enter = k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter;
    final letter = (e.character?.trim().length ?? 0) == 1 && !HardwareKeyboard.instance.isMetaPressed && !HardwareKeyboard.instance.isControlPressed
        ? e.character!
        : null;
    if (!_open) {
      if (!down && !up && !enter && k != LogicalKeyboardKey.space && letter == null) return KeyEventResult.ignored;
      _set(true);
      if (letter == null) return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      _set(false);
    } else if (down)
      _go(_at + 1);
    else if (up)
      _go(_at - 1);
    else if (enter) {
      if (_at >= 0 && _at < _hits.length) _pick?.call(_hits[_at]);
    } else if (letter != null) {
      final now = DateTime.now();
      _typed = (now.difference(_typedAt) > const Duration(seconds: 1) ? '' : _typed) + letter.toLowerCase();
      _typedAt = now;
      final to = _hits.indexWhere((o) => o.toLowerCase().startsWith(_typed));
      if (to >= 0) _go(to);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _set(bool open) {
    if (open) {
      // The list floats over the panel and never pushes the rows below it. It opens upward when there is no room underneath.
      final box = context.findRenderObject() as RenderBox?;
      final overlay = Overlay.maybeOf(context, rootOverlay: true)?.context.findRenderObject() as RenderBox?;
      if (box != null && overlay != null) {
        final bottom = box.localToGlobal(Offset(0, box.size.height), ancestor: overlay).dy;
        final need = math.min(widget.options.length, _maxItems) * _itemH + 12;
        _up = overlay.size.height - bottom < need && bottom - box.size.height > need;
      }
    }
    setState(() => _open = open);
    open ? _portal.show() : _portal.hide();
    if (open) {
      _at = widget.options.indexOf(InspectorScope.read(context).doc.s2[widget.id] ?? widget.options.first);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _node.requestFocus();
        // Scroll the current option into view and put the keyboard on it.
        _go(_at);
      });
    }
  }

  Widget _menu(BuildContext context, String cur, void Function(String) pick) {
    final hits = _hits;
    return Container(
      padding: EdgeInsets.all(Shape.s(3)),
      decoration: BoxDecoration(
        color: Grey.g15,
        borderRadius: BorderRadius.all(Shape.r(8)),
        border: Border.all(color: Grey.g26),
        boxShadow: [BoxShadow(color: ColorTheme.of('Shadow', const Color(0x99000000)), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: math.min(math.max(hits.length, 1), _maxItems) * _itemH,
            child: hits.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(Shape.s(6)),
                    child: Text('No match', style: TextStyles.label(Grey.g56)),
                  )
                : ListView.builder(
                    controller: _list,
                    padding: EdgeInsets.zero,
                    itemExtent: _itemH,
                    itemCount: hits.length,
                    itemBuilder: (_, i) {
                      final o = hits[i], sel = o == cur;
                      return Pressable(
                        onTap: () => pick(o),
                        builder: (_, h) => Container(
                          padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
                          decoration: BoxDecoration(color: h || i == _at ? Grey.g26 : (sel ? Grey.g20 : null), borderRadius: BorderRadius.all(Shape.r(5))),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(o, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyles.name(sel || h ? Grey.g95 : Grey.g76)),
                              ),
                              if (sel)
                                Container(
                                  width: Shape.z(5),
                                  height: Shape.z(5),
                                  decoration: BoxDecoration(color: Grey.g95, shape: BoxShape.circle),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context), cur = x.doc.s2[widget.id] ?? widget.options.first;
    void pick(String o) {
      x.doc.str(widget.id, o);
      _set(false);
    }

    _pick = pick;
    final field = Pressable(
      onTap: () => _set(!_open),
      builder: (_, h) => Container(
        height: InspectorSkin.cell,
        padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
        decoration: BoxDecoration(
          color: h || _open ? Grey.g10 : InspectorSkin.well,
          borderRadius: BorderRadius.all(Shape.r(6)),
          border: Border.all(color: _open ? Grey.g63 : const Color(0x00000000)),
        ),
        // The mark at the right shows that this is a menu, so no extra label is needed.
        child: Row(
          children: [
            // The default value (the first option) is dim. A chosen one is bright.
            Expanded(
              child: Text(cur, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyles.name(cur == widget.options.first ? Grey.g56 : Grey.g91)),
            ),
            FoldMark(open: true, hot: _open),
          ],
        ),
      ),
    );

    return Focus(
      focusNode: _node,
      onKeyEvent: _key,
      child: CompositedTransformTarget(
        link: _link,
        // Uses the root overlay, not the nearest one, so a list that extends beyond its pane still receives pointer events.
        child: OverlayPortal.targetsRootOverlay(
          controller: _portal,
          overlayChildBuilder: (_) {
            final w = (context.findRenderObject() as RenderBox?)?.size.width ?? 160;
            return Stack(
              children: [
                CompositedTransformFollower(
                  link: _link,
                  showWhenUnlinked: false,
                  targetAnchor: _up ? Alignment.topLeft : Alignment.bottomLeft,
                  followerAnchor: _up ? Alignment.bottomLeft : Alignment.topLeft,
                  offset: Offset(0, _up ? -4 : 4),
                  child: Align(
                    alignment: _up ? Alignment.bottomLeft : Alignment.topLeft,
                    child: TapRegion(
                      groupId: _link,
                      onTapOutside: (_) => _set(false),
                      child: SizedBox(width: math.max(w, 160), child: _menu(context, cur, pick)),
                    ),
                  ),
                ),
              ],
            );
          },
          // A press on the field is not an outside tap, so the field's own tap closes the list instead of it closing and reopening.
          child: TapRegion(groupId: _link, child: field),
        ),
      ),
    );
  }
}

/// The Inspector's header: the layer's kind icon, name and kind, and the Animate all switch.
class InspectorHeader extends StatelessWidget {
  const InspectorHeader({super.key});
  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    // The name the app gives the layer kind, for kinds that have no word of their own.
    final w = doc.kindWord;
    final (word, glyph) = switch (doc.kind) {
      Kind.shape when w != null => (
        w,
        w == 'Film' || w == 'Picture'
            ? Glyphs.image
            : w == 'Sound'
            ? Glyphs.media
            : Glyphs.shape,
      ),
      Kind.shape => ('Shape', Glyphs.shape),
      Kind.text => ('Text', Glyphs.text),
      Kind.camera => ('Camera', Glyphs.camera),
      Kind.group => ('Group', Glyphs.grid),
      Kind.none => ('', null),
    };
    return Container(
      height: Shape.z(34),
      padding: EdgeInsets.symmetric(horizontal: InspectorSkin.inset),
      color: InspectorSkin.card,
      child: Row(
        children: [
          Container(
            width: Shape.z(22),
            height: Shape.z(22),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: InspectorSkin.accent, borderRadius: BorderRadius.all(Shape.r(6))),
            child: glyph == null ? null : Glyph(glyph, size: Shape.z(13), color: InspectorSkin.onAccent),
          ),
          SizedBox(width: Shape.s(8)),
          Flexible(
            child: FittedBox(
              // Scale the name down rather than cut it off.
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                doc.name,
                maxLines: 1,
                style: TextStyles.title(Grey.g100).copyWith(fontSize: TextStyles.px(13), fontWeight: FontWeight.w700, height: 1),
              ),
            ),
          ),
          SizedBox(width: Shape.s(6)),
          Text(word, maxLines: 1, style: TextStyles.label(Grey.g56)),
          const Spacer(),
          Text('Animate all', style: TextStyles.label(Grey.g63)),
          SizedBox(width: Shape.s(6)),
          Forms.worn.onOff(
            context,
            SwitchSpec(
              on: doc.animateAll,
              onChanged: (v) {
                doc.animateAll = v;
                doc.poke();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// What the Inspector shows when nothing is selected.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context), ed = const InspectorHairline();
    // One plain muted line, with no controls and no stale values.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(top: Shape.s(4), bottom: Shape.s(8)),
          child: Text('Nothing selected', style: TextStyles.label(Grey.g56).copyWith(height: 1.4)),
        ),
        // With nothing selected, nothing is shown. After Effects' Effect Controls belongs to a layer and Alight Motion shows none.
        // The stage's own settings appear only when asked for, as in Apple Motion's Project pane.
        Pressable(
          key: const ValueKey('stage-settings'),
          onTap: () => x.doc.flag('stage.open', !(x.doc.b['stage.open'] ?? false)),
          builder: (_, h) => Container(
            height: InspectorSkin.cell,
            margin: EdgeInsets.only(bottom: InspectorSkin.gap),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: h ? Grey.g20 : InspectorSkin.well, borderRadius: BorderRadius.all(Shape.r(6))),
            child: Text('Stage settings', style: TextStyles.label(h ? Grey.g95 : Grey.g76)),
          ),
        ),
        if (x.doc.b['stage.open'] ?? false)
          // The stage's own cards, holding the values for the whole image.
          for (final c in x.doc.cards) ValuesCard(c),
        SizedBox(height: Shape.s(1)),
        Container(height: 1, color: ed.rule),
      ],
    );
  }
}
