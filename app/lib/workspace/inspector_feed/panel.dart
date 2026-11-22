// panel.dart: the inspector's panel in the window: what it listens to, and when it builds again or only tells the fields their numbers.
import 'dart:async';
import 'dart:developer' show Timeline;

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/host_cards.dart';
import 'package:motolii/inspector/inspected_layer.dart';
import 'package:motolii/inspector/inspector_edits.dart';
import 'package:motolii/inspector/inspector_host.dart';
import 'package:motolii/inspector/inspector_panel.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_snapshot.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/values_card.dart';
import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/inspector_feed/cards.dart';
import 'package:motolii/workspace/inspector_feed/keyframe_marks.dart';
import 'package:motolii/workspace/inspector_feed/relation_stack.dart';
import 'package:motolii/workspace/inspector_feed/values.dart';
import 'package:motolii/workspace/shelf/effect_code.dart';
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/inspector/inspector_actions.dart';
import 'package:motolii/workspace/state/inspector/inspector_reads.dart';
import 'package:motolii/workspace/state/inspector/inspector_values.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/layers/layer_edits.dart'
    show groupBegin, groupEnd, soundLayer;
import 'package:motolii/workspace/state/layers/layer_reads.dart' show layerWord;
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/workspace.dart';

/// The Inspector of the lab, fed by the workspace's selection; its panel links open the dock's shelves or the tool panel.
class InspectorPane extends StatefulWidget {
  const InspectorPane({super.key, this.layer, this.only}); // (no layer: the Inspector; a layer and the titles of its cards: LayerCards)
  final int? layer;
  final List<String>? only;
  @override
  State<InspectorPane> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPane> {
  // (the inspector follows only what it shows: the document, what is picked, Animate, and the moment only while what is
  //  picked has keys; played, a thing with no keys shows the same numbers, so it is not built again each picture)
  WorkspaceController? _ws;
  int? _id(WorkspaceController ws) => widget.layer ?? ws.selected;
  Layer? _layerOf(WorkspaceController ws) => widget.layer == null
      ? ws.layer
      : ws.layers.where((x) => x.id == widget.layer).firstOrNull;
  Object? _seen;
  (int, bool)? _stageKeyed;
  bool _keyed(WorkspaceController ws) {
    final l = _layerOf(ws);
    if (l != null) return l.keys.isNotEmpty;
    if (!projectOpen(ws)) return true;
    if (_stageKeyed?.$1 != ws.rev) {
      _stageKeyed = (
        ws.rev,
        stageHasKeys(ws),
      ); // (the stage's: once a document)
    }
    return _stageKeyed!.$2;
  }

  // (the moment alone moved: the values and key marks told to the inspector as it stands; anything else: built again)
  final _live =
      ValueNotifier<(Map<String, double>, Map<String, KeyframeState>)>((
        const {},
        const {},
      ));
  int? _frame;
  String? _cards; // (the picked thing's cards, titles and values, as last read)
  Object _now(WorkspaceController ws) => (ws.rev, _id(ws), ws.animating);

  // (the reading of the document changed only numbers of what is picked, none that changes its cards: they are told
  //  to the fields that show them, as a moment's are; anything else, or not known: the inspector built again)
  bool _onlyNumbers(WorkspaceController ws) {
    final c = ws.lastChange, t = _id(ws);
    if (!projectOpen(ws) ||
        c == null ||
        c.layers ||
        t == null ||
        const bool.fromEnvironment('NOPOUR')) {
      return false;
    }
    final cards = '${layerCardsOf(ws, t)}';
    if (cards != _cards) {
      // (a card put on or taken off by its values alone: the Script card's knobs, as the Repeater is laid out from the Create shelf or taken off by its Reset;
      //  or a card's own values changed under the same title, as a slider is added to an expression's head in the Code tab)
      _cards = cards;
      return false;
    }
    for (final (thing, name) in c.values) {
      if (name == 'name' ||
          (thing == t &&
              (shapingNamesOf(ws).contains(name) ||
                  layerRangeOf(ws, t, name) == null ||
                  shownFactOf(ws, name)?.look == 'thing'))) {
        return false; // (another thing: shown by its name, a word) // (a name changed anywhere: things are named on cards; a word: it is not watched)
      }
      // (nor is an effect's colour, three numbers shown as one swatch as a word is (cards.dart): golf_noise.md (84))
      if (thing == t && isColourPartOf(ws, name)) return false;
    }
    return true;
  }

  static const _hears = [
    WorkspaceAspect.document,
    WorkspaceAspect.picked,
    WorkspaceAspect.animating,
  ]; // (what the inspector shows: the picked thing's cards, Animate all)
  void _changed() => Timeline.timeSync(
    'inspector at a moment',
    _changedNow,
  ); // (named in Flutter's timeline)
  void _changedNow() {
    final ws = _ws!, now = _now(ws), was = _seen;
    if (now != _seen) {
      _seen = now;
      _frame = ws.frame;
      if (was is (int, int?, bool) &&
          was.$2 == _id(ws) &&
          was.$3 == ws.animating &&
          _onlyNumbers(ws)) {
        _tellLive(ws);
        return;
      }
      if (mounted) setState(() {});
    } else if (ws.frame != _frame) {
      _frame = ws.frame;
      if (!_keyed(ws)) return;
      _tellLive(ws);
      _settle?.cancel();
      _settle = Timer(
        const Duration(milliseconds: 150),
        () => mounted ? setState(() {}) : null,
      ); // (the moment at rest: built once, whatever does not watch its own number shows it too)
    }
  }

  // Tells the fields that show them the picked layer's transform and key marks as they are now; nothing is built again.
  void _tellLive(WorkspaceController ws) {
    _live.value = (
      WorkspaceController.timed(
        'transform',
        () => layerTransform(ws, _layerOf(ws)?.id),
      ),
      WorkspaceController.timed(
        'key marks',
        () => keyframeMarks(ws, _layerOf(ws)?.id),
      ),
    );
  }

  Timer? _settle;
  // The ticket of the end of the step the inspector last told (together).
  int _stepEnd = 0;

  // (the engine showed something new while the document and the pick stayed (a hand carrying on the stage, a relation
  //  at a moment): the numbers told to the fields that show them; nothing built again)
  void _seenNow() {
    final ws = _ws!;
    if (_now(ws) != _seen || _id(ws) == null || ws.playing) {
      return; // (played: the moment's own reading above)
    }
    _tellLive(ws);
  }

  // (the panel itself, made once a size: a new one each build would build its whole tree again, whatever changed)
  (Size, InspectorPanel)? _panel;
  InspectorPanel _panelOf(BoxConstraints box) {
    final size = Size(box.maxWidth, box.maxHeight);
    if (_panel?.$1 != size) {
      _panel = (
        size,
        InspectorPanel(width: box.maxWidth, height: box.maxHeight),
      );
    }
    return _panel!.$2;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = WorkspaceScope.read(context);
    if (ws != _ws) {
      for (final a in _hears) {
        _ws?.on[a]!.removeListener(_changed);
        ws.on[a]!.addListener(_changed);
      }
      _ws?.moment.removeListener(_changed);
      _ws?.seen.removeListener(_seenNow);
      _ws = ws;
      ws.moment.addListener(
        _changed,
      ); // (the playhead too: the inspector's numbers are at the moment)
      ws.seen.addListener(_seenNow);
      _seen = _now(ws);
      _frame = ws.frame;
    }
  }

  @override
  void dispose() {
    for (final a in _hears) {
      _ws?.on[a]!.removeListener(_changed);
    }
    _ws?.moment.removeListener(_changed);
    _ws?.seen.removeListener(_seenNow);
    _settle?.cancel();
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.read(context),
        l = _layerOf(ws),
        k = _kindOf(l),
        own = widget.only == null;
    requireProject(ws);
    if (!own && l == null) {
      return const SizedBox.shrink(); // (never the stage's cards)
    }
    Widget host(Widget child) => InspectorHost(
      key: ValueKey(k),
      layer: InspectedLayer(
        kind: k,
        kindWord: _kindWord(ws, l?.id),
        cards: WorkspaceController.timed('value cards', () {
          final all = valueCards(
            ws,
            l?.id,
          )?.where((c) => own || widget.only!.contains(c.name)).toList();
          if (all == null) return null;
          return [
            ...all.where((c) => hostCards.containsKey(c.name)),
            ...all.where((c) => !hostCards.containsKey(c.name)),
          ];
        }),
        title: l?.name,
        movable: !own || l == null
            ? const []
            : effectTitles(ws, l.id), // (its effects, up or down their stack)
        moreCards: !own || l == null
            ? const []
            : [
                for (final c in moreCardTitles(ws, l.id))
                  if (l.kind != LayerKind.audio || c == 'Media') c,
              ], // (a sound's speed, Alight Motion's; nothing else)
        cardsOff: l == null ? const [] : effectsOff(ws, l.id),
      ),
      actions: CardActions(
        onCardMove: !own || l == null
            ? null
            : (title, by) => moveEffect(ws, l.id, title, by),
        onSum: (sum) => workOutSum(ws, sum),
        onMoreCard: !own || l == null
            ? null
            : (title) => askMoreCard(ws, l.id, title),
        onAddEffect:
            !own ||
                l == null ||
                l.kind == LayerKind.audio ||
                layerWord(ws, l.id, 'kind') == 'light'
            ? null
            : () {
                // (a light takes none: the engine's fx is a film's, a picture's, a text's, a shape's, a solid's, a camera's)
                ws.front('Effects');
                askDockSearch();
              },
        onCardRemove: l == null
            ? null
            : (title, names) => removeCard(ws, l.id, title, names),
        onAddStroke:
            l == null ||
                !const {
                  LayerKind.text,
                  LayerKind.shape,
                  LayerKind.image,
                }.contains(l.kind)
            ? null
            : () => addStroke(ws, l.id),
        cardEdit: l == null
            ? null
            : (title, names) =>
                  EffectCode.ofCard(ws, l.id, title, names) == null
                  ? null
                  : () => EffectCode.show(ws, title), // (a card's code is a cell of the Code tab: workspace/code/code_pane.dart)
        onCardEye: l == null ? null : (title) => toggleEffect(ws, l.id, title),
        onCardDuplicate: l == null
            ? null
            : (title) => duplicateEffect(ws, l.id, title),
        onCardInfo: (title) => ws.notice = aboutEffect(ws, title).isEmpty
            ? '$title: no words of its maker\'s'
            : '$title: ${aboutEffect(ws, title)}', // (in its maker's words, as the shelf searches them)
        onCardSave: l == null
            ? null
            : (title, names) => keepCardPreset(ws, l.id, title, names),
        onCardReset: !own || l == null
            ? null
            : (names) => resetCardValues(ws, l.id, names),
        onCardCopy: !own || l == null
            ? null
            : (names) => copyCardValues(
                ws,
                l.id,
                names,
                WorkspaceState.clipboard('card'),
              ), // (that card's values alone: Alight Motion's copy of one effect)
        onCardPaste: !own || l == null
            ? null
            : () => pasteCardValues(ws, l.id, WorkspaceState.clipboard('card')),
        shapeSvg: l == null ? null : () => shapeSvgOf(ws, l.id),
        fontMeta: (path) => fontMetaOf(ws, path),
        textClasses: (words) => textClassesOf(ws, words),
        propScale: l == null ? null : (prop) => propScaleOf(ws, l.id, prop),
      ),
      snapshot: InspectorSnapshot(
        numbers: WorkspaceController.timed(
          'transform',
          () => layerTransform(ws, l?.id),
        ),
        words: WorkspaceController.timed(
          'words',
          () => inspectorWords(ws, l?.id),
        ),
        animating: ws.animating,
        flags: own
            ? WorkspaceController.timed('flags', () => layerFlags(ws, l?.id))
            : const {},
        keyMarks: WorkspaceController.timed(
          'key marks',
          () => keyframeMarks(ws, l?.id),
        ),
      ),
      edits: InspectorEdits(
        onRoute: ws.route,
        onAim: (at) => ws.aim = at.startsWith('v_')
            ? at.substring(2)
            : null, // (a colour link of a card is aimed at that value)
        onWords: (changed, {required live}) =>
            writeWords(ws, l?.id, changed, live: live),
        onAnimateAll: (on) => ws.animating = on,
        onFlags: own ? (changed) => writeFlags(ws, l?.id, changed) : null,
        onValues: (changed, {required live}) =>
            writeNumbers(ws, l?.id, changed, live: live),
        onDrop: () => putDownValue(ws), // (put down unchanged, without waiting)
        onKey: (prop, mark) => applyKeyframeMark(ws, l?.id, prop, mark),
        together: (tells) {
          // (one step, asked without waiting: begun and ended in the engine's queue around what is told)
          groupBegin(ws);
          tells();
          ws.after(_stepEnd = groupEnd(ws));
        },
        // (the engine answers the step's end once it has taken it, its snapshots read first)
        whenTaken: (taken) =>
            projectOpen(ws) ? ws.after(_stepEnd, (_, _) => taken()) : taken(),
      ),
      live: _live,
      child: child,
    );
    return own
        ? Column(
            children: [
              const RelationStack(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => host(_panelOf(box)),
                ),
              ), // (the same panel while the pane keeps its size: built again only by what it reads, InspectorScope)
            ],
          )
        : host(const _Cards());
  }
}

/// The cards alone, sized to themselves (a thing's cards shown in a tool's pane: no head, no Add Effect).
class _Cards extends StatelessWidget {
  const _Cards();
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final c in InspectorScope.of(context).doc.cards) ValuesCard(c),
    ],
  );
}

/// A layer's own cards by their titles, drawn as the Inspector draws them and written the same way (a tool shows the engine's card, not its own number).
class LayerCards extends StatelessWidget {
  const LayerCards({super.key, required this.layer, required this.only});
  final int layer;
  final List<String> only;
  @override
  Widget build(BuildContext context) =>
      InspectorPane(key: ValueKey(layer), layer: layer, only: only);
}

/// The document's name for a layer's kind, for kinds the inspector's own [Kind] has no entry for (video, image, solid).
String? _kindWord(WorkspaceController ws, int? id) {
  if (id == null) return null;
  final w = layerWord(ws, id, 'kind');
  if (w == 'behaviour') {
    return relationKinds.contains(layerWord(ws, id, 'file'))
        ? 'Relation'
        : 'Behaviour';
  }
  if (w == 'film' && soundLayer(ws, id)) return 'Sound';
  return const {'film', 'picture', 'solid', 'light'}.contains(w)
      ? w.replaceRange(0, 1, w[0].toUpperCase())
      : null;
}

Kind _kindOf(Layer? l) => switch (l?.kind) {
  null => Kind.none,
  LayerKind.text => Kind.text,
  LayerKind.camera => Kind.camera,
  LayerKind.group => Kind.group,
  _ => Kind.shape,
};
