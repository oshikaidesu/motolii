// The tool panel's Ease tool: edits the easing between the picked keyframe and the next one (curve, handles, presets, numbers).

import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/workspace/easing/ease_text.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:async' show scheduleMicrotask;
import 'dart:math' as math;

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_cards.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_ends.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_graph.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_numbers.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_shelf.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_trial.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_side.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The curve copied in the Ease tool, kept until the app closes. Like Copy Curve in Alight Motion.
Ease? easeCopied;

/// Whether dragging an end of a segment up or down makes the value jump there.
///
/// When on, a keyframe one frame outside the segment keeps its old value, so the value jumps at the keyframe.
/// When off, only the keyframe's value moves and the neighbouring segment follows. Kept until the app closes.
bool easeJump = true;

/// Whether the graph shows values past 0 and 1. Like Enable Overshoot in Alight Motion. Kept until the app closes.
bool easeOvershoot = false;

class EaseToolState extends State<EaseTool> with EaseEnds {
  // While the pointer is down, each new ease is sent to the document so the canvas and the bars follow it.
  // While one is in flight the next waits and any in between are skipped. The whole drag is one undo step.
  bool _down = false, _open = false, _going = false;
  Ease? _pending, _waiting;
  // The ease sent to the document and not yet confirmed. It is shown meanwhile instead of the old one.
  Ease? _told;
  // For layered cards, the card the graph shows. Below 0 means the whole stack. Another segment resets it to the first card.
  int _card = 0;
  String _cardOf = '';
  // What a tile dragged over the graph would produce, shown before it is dropped. Like skimming an effect in Final Cut Pro.
  Ease? _held;
  // True after the user clicks the empty slot in the card flow: the next pick is added there, like Bitwig's + button.
  bool _adding = false;
  // The easing before a preview started. The preview runs in an open undo step and is kept only if the tile is dropped there.
  Ease? _base;
  // The shelf is open, and the shelf is built. It stays built until it has slid away.
  bool _shelf = false, _shelfShown = false;
  // Like AbsentMotion's lockOvershoot: once the graph shows past 0 and 1 it stays so, until the menu or another card or segment resets it.
  bool _overLocked = false;

  // With no keyframe picked, the segment follows the playhead. The panel rebuilds when it enters another segment, not every frame.
  WorkspaceController? _ws;
  String _spanAt = '';
  void _moved() {
    final id = spanId(easeSpan(_ws!));
    if (id != _spanAt && mounted) setState(() => _spanAt = id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = WorkspaceScope.read(context);
    if (ws == _ws) return;
    _ws?.moment.removeListener(_moved);
    _ws = ws..moment.addListener(_moved);
    _spanAt = spanId(easeSpan(ws));
  }

  @override
  void dispose() {
    _ws?.moment.removeListener(_moved);
    super.dispose();
  }

  // The segments of every picked keyframe, on any layer, one for each property keyed there.
  // A last keyframe has no segment after it, so the segment ending at it is used.
  List<(int, String, double)> _stretches(WorkspaceController ws) => [
    if (ws.stretch case final s?)
      (int.parse(s.layer), s.name, s.at)
    else if (ws.keys.isEmpty) // Nothing picked: the segment the playhead is in.
      if (easeSpan(ws) case final s?)
        for (final at in keysAt(ws, s).entries) (int.parse(s.layer.id), at.key, at.value),
    for (final k in ws.keys)
      if (ws.layers.where((l) => l.id == k.layer).firstOrNull case final l?)
        for (final at in keysAt(ws, (
          layer: l,
          from: l.keys.any((f) => f > k.frame) ? k.frame : (l.keys.where((f) => f < k.frame).fold<int?>(null, (a, f) => a == null || f > a ? f : a) ?? k.frame),
          to: k.frame,
          picked: k.frame,
        )).entries)
          (int.parse(l.id), at.key, at.value),
  ];

  // Sends the newest ease while the pointer is down. The first call opens the undo step.
  void _live(WorkspaceController ws, Ease e) {
    final m = ws.inside!;
    if (_going) {
      _waiting = e;
      return;
    }
    final all = _stretches(ws);
    if (all.isEmpty) return;
    if (!_open) {
      m.later('together', number: 1);
      _open = true;
    }
    _going = true;
    var last = 0;
    _define(m, said(e));
    for (final (t, name, at) in all) {
      last = m.later('easing', layer: t, name: name, number: at, word: said(e));
    }
    for (final t in {for (final (t, _, _) in all) t}) {
      last = m.later('show', layer: t);
    }
    ws.after(last, (_, _) {
      _going = false;
      final next = _waiting;
      _waiting = null;
      if (next != null) _live(ws, next);
    });
  }

  // Abandons a preview: the undo step it opened is removed whole.
  void _giveUp(WorkspaceController ws) {
    _waiting = null;
    if (!_open) {
      _base = null;
      return;
    }
    _open = false;
    ws.after(ws.inside!.later('together', number: -1), (_, _) => mounted ? setState(() => _base = null) : null);
  }

  void _define(Motolii m, String word) {
    for (final (name, goes) in easeDefines(word)) {
      m.later('define', name: name, word: goes);
    }
  }

  void _settle(WorkspaceController ws, EaseSpan? span) {
    final e = _pending;
    _pending = null;
    _waiting = null;
    if (e == null && _base != null) {
      // A tile was previewed and released. A drop on the graph or the flow is handled in this same event.
      scheduleMicrotask(() => _pending == null && !_down ? _giveUp(ws) : null);
      return;
    }
    _base = null;
    if (e == null || span == null) return;
    _told = e;
    final m = ws.inside!, to = said(e);
    final all = _stretches(ws);
    // Segments that already have this easing are skipped, so numbers with no field here are not overwritten.
    // If the drag already sent the ease, it is sent once more on release and the undo step is closed.
    final told = [
      for (final (t, name, at) in all)
        if (_open || said(heard(m.easingOf(t, name, at))) != to) (t, name, at),
    ];
    if (_open) {
      _open = false;
      _define(m, to);
      for (final (t, name, at) in told) {
        m.later('easing', layer: t, name: name, number: at, word: to);
      }
      _define(m, to);
      ws.after(m.later('together'), (done, why) => mounted ? setState(() => trouble = done ? null : why) : null);
      return;
    }
    if (told.isEmpty) return setState(() => trouble = all.isEmpty ? 'No key where the stretch begins' : null);
    m.later('together', number: 1);
    _define(m, to);
    for (final (t, name, at) in told) {
      m.later('easing', layer: t, name: name, number: at, word: to);
    }
    _define(m, to);
    ws.after(m.later('together'), (done, why) => mounted ? setState(() => trouble = done ? null : why) : null);
  }

  // Applies the curve after every keyframe of each picked keyframe's layer, for every property keyed there, as one undo step.
  void _onEveryKey(WorkspaceController ws, Ease e) {
    final m = ws.inside!,
        layers = ws.keys.isNotEmpty
            ? {for (final k in ws.keys) k.layer}
            // Nothing picked: the layer of the segment the playhead is in.
            : {if (easeSpan(ws) case final s?) s.layer.id};
    m.later('together', number: 1);
    _define(m, said(e));
    for (final l in ws.layers.where((l) => layers.contains(l.id))) {
      for (final f in l.keys) {
        for (final at in keysAt(ws, (layer: l, from: f, to: f, picked: f)).entries) {
          m.later('easing', layer: int.parse(l.id), name: at.key, number: at.value, word: said(e));
        }
      }
    }
    ws.after(m.later('together'), (done, why) => mounted ? setState(() => trouble = done ? null : why) : null);
  }

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {WorkspaceAspect.document, WorkspaceAspect.picked}), span = easeSpan(ws), store = eases[ws] ??= {}, id = spanId(span);
    if ((ws.inside, span) case (final m?, final span?)) {
      final at = keysAt(ws, span);
      final inDocument = at.isEmpty ? easingPreset('Linear') : heard(m.easingOf(int.parse(span.layer.id), at.keys.first, at.values.first));
      if (_told case final t? when !ws.waiting || said(t) == said(inDocument)) _told = null;
      var ease = _pending ?? _told ?? _base ?? inDocument;
      if (easeOther(ease) && ease.drawn == null) {
        // There is no tile for this kind, so its curve is the one the engine computes for it now.
        ease = easeCard(said(ease), m);
      }
      void set(Ease e) {
        setState(() => _pending = e);
        _down ? _live(ws, e) : _settle(ws, span);
      }

      return Listener(
        onPointerDown: (_) => _down = true,
        onPointerUp: (_) {
          _down = false;
          _settle(ws, span);
        },
        onPointerCancel: (_) {
          _down = false;
          setState(() => _pending = null);
        },
        child: _body(ws, span, ease, set),
      );
    }
    // No segment: the panel keeps its own easing, so the user can make and save presets. The document is not changed.
    final own = store[id] ?? easingPreset(ws.inside == null ? 'Ease' : 'Linear');
    return _body(ws, span, easeOther(own) ? easeCard(said(own), ws.inside) : own, (e) => setState(() => store[id] = e));
  }

  // Lays out the panel as AbsentMotion's EasingPanel.kt does: the left column, the graph and the preset thumbnails.
  Widget _body(WorkspaceController ws, EaseSpan? span, Ease ease, ValueChanged<Ease> set) {
    final cards = easeIsLaid(said(ease)) ? [for (final c in easeCards(said(ease))) easeCard(c, ws.inside)] : [ease];
    // Over plain Linear there is nothing to layer onto, so the new easing replaces it.
    Ease laidOn(Ease e) => said(ease) == 'Linear' ? e : easeLaid([...cards, for (final c in easeCards(said(e))) easeCard(c, ws.inside)]);
    final pile = _held == null ? cards : [for (final c in easeCards(said(_held!))) easeCard(c, ws.inside)];
    if (spanId(span) != _cardOf) (_cardOf = spanId(span), _card = 0, _adding = false, _overLocked = false);
    final at = _card.clamp(0, cards.length - 1), card = cards[at], laid = cards.length > 1, whole = laid && _card < 0;
    void put(Ease e) => set(laid ? easeLaid([...cards]..[at] = easeCard(said(e), ws.inside)) : e);
    final bezier = easeIsBezier(card);
    final overshoot = bezier && (easeOvershoot || _overLocked || [card.p1.dy, card.p2.dy].any((y) => y < 0 || y > 1));
    _overLocked = overshoot;
    // Where the beats fall on the selected card. A card that takes the cards above it as input follows their result, not the clock,
    // so a handle placed on a beat line does not miss the beat in the video.
    final grid = ws.beats, clock = !whole && at > 0 && easeThrough(card) ? easeLaid(cards.sublist(0, at)) : null;
    final beats = grid == null || span == null
        ? const <double>[]
        : [
            for (final (f, _) in grid.between(span.from + 1, span.to - 1))
              if ((f - span.from) / (span.to - span.from) case final u) clock?.at(u).clamp(0.0, 1.0) ?? u,
          ];
    void add(Ease e) {
      _adding = false;
      _card = cards.length;
      set(laidOn(e));
    }

    void over(Ease? e) {
      setState(() => _held = e);
      if (ws.inside == null || span == null) return;
      if (e == null) return _giveUp(ws);
      _base ??= ease;
      _live(ws, e);
    }

    Future<void> paste(void Function(Ease) put) async {
      ClipboardData? words;
      try {
        words = await Clipboard.getData(Clipboard.kTextPlain);
      } catch (_) {
        // The clipboard is unavailable, so fall back to the curve copied inside the app.
      }
      final e = easeFromText(words?.text, ws.inside) ?? easeCopied;
      if (e != null) {
        put(e);
      } else {
        ws.notice = 'No curve to paste';
      }
    }

    // Like AbsentMotion's reversed(): a Bezier has its handles turned, any other kind is marked as reversed.
    final turned = bezier ? card.reversed() : Ease(card.kind, card.p1, card.p2, easeTurn(said(card)));
    void overshootSet() {
      setState(() {
        easeOvershoot = !overshoot;
        _overLocked = !overshoot;
      });
      // Turning it off pulls the handles back inside 0 to 1, or the user could not reach them. AbsentMotion only zooms the view.
      if (overshoot && [card.p1.dy, card.p2.dy].any((y) => y < 0 || y > 1)) {
        put(card.withHandles(Offset(card.p1.dx, card.p1.dy.clamp(0.0, 1.0)), Offset(card.p2.dx, card.p2.dy.clamp(0.0, 1.0))));
      }
    }

    Widget graph(int frame, [double? trial]) => EaseGraph(
      beats: beats,
      ease: whole ? easeLaid(cards) : card,
      onion: _held ?? (laid && !whole ? easeLaid(cards) : null),
      ends: endsOf(ws, span),
      span: span,
      frame: frame,
      onChanged: put,
      jump: easeJump,
      overshoot: overshoot && !whole,
      onEnd: ws.inside == null ? null : (start, by) => toEnd(ws, span, start, by, done: true),
      onEndMove: ws.inside == null ? null : (start, by) => toEnd(ws, span, start, by),
      endSays: (start, by) => endSays(ws, span, start, by),
      trial: trial,
    );
    return LayoutBuilder(
      builder: (_, box) {
        // The left column is as wide as its two buttons. The thumbnails are as large as the height (or width) allows for seven and
        // a bit. The graph takes the rest. In a tall pane the thumbnails and cards go under the graph, like a CSS container query.
        final left = Shape.z(34), tall = box.maxHeight > box.maxWidth * 1.1;
        final side =
            (tall
                    ? math.min(box.maxWidth / easeFits(box.maxWidth) - Shape.s(4), (box.maxHeight * .4) / 2 - Shape.s(12))
                    : math.min(box.maxHeight / easeFits(box.maxHeight) - Shape.s(6), (box.maxWidth * .55 - left) / 2 - Shape.s(12)))
                .clamp(Shape.z(16), Shape.z(64));
        final column = side + Shape.s(12);
        final leftColumn = SizedBox(
          width: left,
          child: EaseLeft(
            onReverse: !whole && card != easingPreset('Linear') && turned != card ? () => put(turned) : null,
            menu: [
              (
                'copy',
                'Copy Curve',
                () {
                  setState(() => easeCopied = ease);
                  Clipboard.setData(ClipboardData(text: easeText(ease))).catchError((_) {});
                },
              ),
              // Pastes the curve copied in the app, or a cubic-bezier() or linear() from a web page. See easeFromText.
              ('paste', 'Paste Curve', () => paste(set)),
              if (easeCopied != null && ws.inside != null) ('all', 'Paste Curve to All Keyframes', () => paste((e) => _onEveryKey(ws, e))),
              ('jump', easeJump ? 'Jump On' : 'Jump Off', () => setState(() => easeJump = !easeJump)),
            ],
          ),
        );
        void shelf(bool open) => setState(() {
          _shelf = open;
          _shelfShown = _shelfShown || open;
        });
        void keep(int i) {
          final word = said(i < 0 ? easeLaid(cards) : cards[i]);
          if (word != 'Linear') setState(() => easeKeep(word));
        }

        final shapes = DragTarget<int>(
          onWillAcceptWithDetails: (_) {
            shelf(true);
            return true;
          },
          onAcceptWithDetails: (d) => keep(d.data),
          builder: (_, _, _) => EaseShapes(
            ease: whole ? ease : card,
            side: side,
            across: tall,
            shapes: easeRow(easingsWithoutTile(ws)),
            onPick: (e) {
              if (_adding) return add(e);
              if (whole) {
                // With the whole stack selected, the pick replaces the whole stack, as a click replaces a single card.
                _card = 0;
                return set(e);
              }
              put(e);
            },
          ),
        );
        final target = DragTarget<Object>(
          onWillAcceptWithDetails: (d) {
            if (d.data case final Ease e) over(laidOn(e));
            return true; // A card from the flow is accepted too, and stays where it is.
          },
          onLeave: (d) => d is Ease ? over(null) : null,
          onAcceptWithDetails: (d) {
            _held = null;
            if (d.data case final Ease e) {
              _card = cards.length; // The card just added becomes the selected one.
              set(laidOn(e));
            }
          },
          builder: (_, hot, _) => DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(border: hot.isEmpty ? null : Border.all(color: WindowTokens.accent, width: 2)),
            child: Flex(
              direction: tall ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ColoredBox(
                    color: WindowTokens.well,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: span == null
                              ? EaseTrial(way: said(ease), builder: (trial) => graph(ws.frame, trial))
                              : ValueListenableBuilder<int>(valueListenable: ws.moment, builder: (_, frame, _) => graph(frame)),
                        ),
                        if (span == null && ws.inside != null)
                          Positioned(
                            left: Shape.s(6),
                            top: Shape.s(4),
                            right: Shape.s(6),
                            child: IgnorePointer(
                              child: Text(
                                'Trying here. Pick a key to go on a stretch',
                                key: const ValueKey('ease-no-span'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: T.micro(Grey.g63),
                              ),
                            ),
                          ),
                        if (trouble case final why?)
                          Positioned(
                            left: Shape.s(4),
                            right: Shape.s(4),
                            top: Shape.s(2),
                            child: Text(why, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(Grey.g63)),
                          ),
                        if (span case final s?)
                          Positioned(
                            left: Shape.s(6),
                            top: Shape.s(4),
                            right: Shape.s(6),
                            child: IgnorePointer(
                              child: Text(
                                '${s.layer.name}  ${s.from} → ${s.to}',
                                key: const ValueKey('ease-span'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: T.micro(Grey.g63),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: EaseNumbers(card: whole ? easeLaid(cards) : card, onChanged: put, overshoot: overshoot, onOvershoot: overshootSet),
                        ),
                        Positioned(
                          left: Shape.s(2),
                          bottom: Shape.s(2),
                          child: EaseStep(span: span, back: true),
                        ),
                        Positioned(
                          right: Shape.s(2),
                          bottom: Shape.s(2),
                          child: EaseStep(span: span, back: false),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: tall ? null : column,
                  height: tall ? column : null,
                  child: EaseCards(
                    side: side,
                    across: tall,
                    cards: pile,
                    adding: _adding,
                    onSlot: () => setState(() => _adding = !_adding),
                    now: whole ? -1 : at,
                    whole: pile.length > 1 ? _held ?? easeLaid(cards) : null,
                    onWhole: () => setState(() => _card = -1),
                    onPress: (i) => setState(() => (_card = i, _adding = false, _overLocked = false)),
                    onOff: (i) => set(cards.length > 1 ? easeLaid([...cards]..removeAt(i)) : easingPreset('Linear')),
                    onMove: (from, to) {
                      final next = [...cards];
                      next.insert(to, next.removeAt(from));
                      _card = to;
                      set(easeLaid(next));
                    },
                    onLay: (e, i) {
                      _held = null;
                      _card = i;
                      set(easeLaid([...cards]..insertAll(i, [for (final c in easeCards(said(e))) easeCard(c, ws.inside)])));
                    },
                    onOver: (e, i) => over(e == null ? null : easeLaid([...cards]..insertAll(i, [for (final c in easeCards(said(e))) easeCard(c, ws.inside)]))),
                  ),
                ),
              ],
            ),
          ),
        );
        final across = (box.maxWidth * .3 / column).floor().clamp(1, 6), wide = across * column;
        const slide = Duration(milliseconds: 200);
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: tall
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    leftColumn,
                                    Expanded(child: target),
                                  ],
                                ),
                              ),
                              SizedBox(height: column, child: shapes),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              leftColumn,
                              Expanded(child: target),
                              SizedBox(width: column, child: shapes),
                            ],
                          ),
                  ),
                  ClipRect(
                    child: AnimatedContainer(
                      duration: slide,
                      curve: Curves.easeOutCubic,
                      width: _shelf ? wide : 0,
                      // Once the shelf is closed it is no longer built, so it is not rebuilt while the user drags a handle.
                      onEnd: () => _shelf ? null : setState(() => _shelfShown = false),
                      child: !_shelfShown
                          ? null
                          : OverflowBox(
                              alignment: Alignment.centerLeft,
                              minWidth: wide,
                              maxWidth: wide,
                              child: EaseShelf(
                                now: said(ease),
                                ways: easeOthers(easingsWithoutTile(ws)),
                                columns: across,
                                pitch: side + Shape.s(6),
                                side: side,
                                inside: ws.inside,
                                onKeep: keep,
                                onForget: (e) => setState(() => easeKeep(said(e), off: true)),
                                onPick: (e) {
                                  if (_adding) return add(e);
                                  _card = 0; // A preset is a whole easing.
                                  set(e);
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedPositioned(
              duration: slide,
              curve: Curves.easeOutCubic,
              top: Shape.s(8),
              right: _shelf ? wide : 0,
              child: EaseGrip(key: const ValueKey('ease.shelf'), open: _shelf, onTap: () => shelf(!_shelf)),
            ),
          ],
        );
      },
    );
  }
}
