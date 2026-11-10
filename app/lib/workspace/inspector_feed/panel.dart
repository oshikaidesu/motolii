// panel.dart: the inspector's panel in the window: what it listens to, and when it builds again or only tells the fields their numbers.
import 'dart:async';
import 'dart:developer' show Timeline;
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/inspector/inspector_parts_insp_host.dart';
import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/inspector_feed/cards.dart';
import 'package:motolii/workspace/inspector_feed/keyframe_marks.dart';
import 'package:motolii/workspace/inspector_feed/values.dart';
import 'package:motolii/workspace/shelf/fx_code.dart';
import 'package:motolii/workspace/stage/stage_view_relations.dart' show RelationStack;
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/workspace.dart';

/// The Inspector of the lab, fed by the workspace's selection; its panel links open the dock's shelves or the tool panel.
class InspectorPane extends StatefulWidget {
  const InspectorPane({super.key, this.layer, this.only}); // (no layer: the Inspector; a layer and the titles of its cards: LayerCards)
  final String? layer;
  final List<String>? only;
  @override
  State<InspectorPane> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPane> {
  // (the inspector follows only what it shows: the document, what is picked, Animate, and the moment only while what is
  //  picked has keys; played, a thing with no keys shows the same numbers, so it is not built again each picture)
  WorkspaceController? _ws;
  String? _id(WorkspaceController ws) => widget.layer ?? ws.selected;
  Layer? _layerOf(WorkspaceController ws) => widget.layer == null ? ws.layer : ws.layers.where((x) => x.id == widget.layer).firstOrNull;
  Object? _seen;
  (int, bool)? _stageKeyed;
  bool _keyed(WorkspaceController ws) {
    final l = _layerOf(ws);
    if (l != null) return l.keys.isNotEmpty;
    final m = ws.inside;
    if (m == null) return true;
    if (_stageKeyed?.$1 != ws.rev) _stageKeyed = (ws.rev, m.moving(0).any((n) => m.keyTimes(0, n).isNotEmpty)); // (the stage's: once a document)
    return _stageKeyed!.$2;
  }

  // (the moment alone moved: the values and key marks told to the inspector as it stands; anything else: built again)
  final _live = ValueNotifier<(Map<String, double>, Map<String, KeyS>)>((const {}, const {}));
  int? _frame;
  String? _titles; // (the picked thing's cards' titles as last read)
  Object _now(WorkspaceController ws) => (ws.rev, _id(ws), ws.animating);

  // (the reading of the document changed only numbers of what is picked, none that changes its cards: they are told
  //  to the fields that show them, as a moment's are; anything else, or not known: the inspector built again)
  bool _onlyNumbers(WorkspaceController ws) {
    final m = ws.inside, c = ws.lastChange, t = int.tryParse(_id(ws) ?? '') ?? (_id(ws) == null ? 0 : null);
    if (m == null || c == null || c.layers || t == null || const bool.fromEnvironment('NOPOUR')) return false;
    final titles = [for (final (title, _) in m.cards(t)) title].join(';');
    if (titles != _titles) {
      // (a card put on or taken off by its values alone: the Script card's knobs, as the Repeater is laid out from the Create shelf or taken off by its Reset)
      _titles = titles;
      return false;
    }
    for (final (thing, name) in c.values) {
      if (name == 'name' || (thing == t && (m.shaping.contains(name) || m.range(t, name) == null || m.shown(name)?.look == 'thing'))) {
        return false; // (another thing: shown by its name, a word) // (a name changed anywhere: things are named on cards; a word: it is not watched)
      }
      // (nor is an effect's colour, three numbers shown as one swatch as a word is (cards.dart): golf_noise.md (84))
      if (thing == t && RegExp(r'_[xyz]$').hasMatch(name) && RegExp(r' [rgb]$').hasMatch(m.shown(name)?.label ?? '')) return false;
    }
    return true;
  }

  static const _hears = [
    WorkspaceAspect.document,
    WorkspaceAspect.picked,
    WorkspaceAspect.animating,
  ]; // (what the inspector shows: the picked thing's cards, Animate all)
  void _changed() => Timeline.timeSync('inspector at a moment', _changedNow); // (named in Flutter's timeline)
  void _changedNow() {
    final ws = _ws!, now = _now(ws), was = _seen;
    if (now != _seen) {
      _seen = now;
      _frame = ws.frame;
      if (was is (int, String?, bool) && was.$2 == _id(ws) && was.$3 == ws.animating && _onlyNumbers(ws)) {
        _live.value = (
          WorkspaceController.timed('transform', () => wsTransform(ws, _layerOf(ws)?.id)),
          WorkspaceController.timed('key marks', () => wsKeyMarks(ws, _layerOf(ws)?.id)),
        );
        return;
      }
      if (mounted) setState(() {});
    } else if (ws.frame != _frame) {
      _frame = ws.frame;
      if (!_keyed(ws)) return;
      _live.value = (
        WorkspaceController.timed('transform', () => wsTransform(ws, _layerOf(ws)?.id)),
        WorkspaceController.timed('key marks', () => wsKeyMarks(ws, _layerOf(ws)?.id)),
      );
      _settle?.cancel();
      _settle = Timer(
        const Duration(milliseconds: 150),
        () => mounted ? setState(() {}) : null,
      ); // (the moment at rest: built once, whatever does not watch its own number shows it too)
    }
  }

  Timer? _settle;

  // (the inside showed something new while the document and the pick stayed (a hand carrying on the stage, a relation
  //  at a moment): the numbers told to the fields that show them; nothing built again)
  void _seenNow() {
    final ws = _ws!;
    if (_now(ws) != _seen || _id(ws) == null || ws.playing) return; // (played: the moment's own reading above)
    _live.value = (
      WorkspaceController.timed('transform', () => wsTransform(ws, _layerOf(ws)?.id)),
      WorkspaceController.timed('key marks', () => wsKeyMarks(ws, _layerOf(ws)?.id)),
    );
  }

  // (the panel itself, made once a size: a new one each build would build its whole tree again, whatever changed)
  (Size, InspectorPanel)? _panel;
  InspectorPanel _panelOf(BoxConstraints box) {
    final size = Size(box.maxWidth, box.maxHeight);
    if (_panel?.$1 != size) _panel = (size, InspectorPanel(width: box.maxWidth, height: box.maxHeight));
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
      ws.moment.addListener(_changed); // (the playhead too: the inspector's numbers are at the moment)
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
    final ws = WorkspaceScope.read(context), l = _layerOf(ws), k = _kindOf(l), m = ws.inside!, own = widget.only == null;
    if (!own && l == null) return const SizedBox.shrink(); // (never the stage's cards)
    Widget host(Widget child) => InspHost(
      key: ValueKey(k),
      kind: k,
      kindWord: _kindWord(ws, l?.id),
      cards: WorkspaceController.timed('value cards', () => wsValueCards(ws, l?.id)?.where((c) => own || widget.only!.contains(c.name)).toList()),
      title: l?.name,
      onRoute: ws.route,
      onAim: (at) => ws.aim = at.startsWith('v_') ? at.substring(2) : null, // (a colour link of a card is aimed at that value)
      movable: !own || int.tryParse(l?.id ?? '') == null ? const [] : m.fxTitles(int.parse(l!.id)), // (its effects, up or down their stack)
      onCardMove: !own || int.tryParse(l?.id ?? '') == null
          ? null
          : (title, by) => ws.after(m.later('fx_move', layer: int.parse(l!.id), word: title, number: by.toDouble())),
      onSum: m.workOut,
      moreCards: !own || int.tryParse(l?.id ?? '') == null
          ? const []
          : [
              for (final c in m.moreCards(int.parse(l!.id)))
                if (l.kind != LayerKind.audio || c == 'Play') c,
            ], // (a sound's speed, Alight Motion's; nothing else)
      onMoreCard: !own || int.tryParse(l?.id ?? '') == null
          ? null
          : (title) {
              m.asked.putIfAbsent(int.parse(l!.id), () => {}).add(title);
              ws.reread();
            },
      onAddEffect: !own || int.tryParse(l?.id ?? '') == null || l?.kind == LayerKind.audio || m.word(int.parse(l!.id), 'kind') == 'light'
          ? null
          : () {
              // (a light takes none: the inside's fx is a film's, a picture's, a text's, a shape's, a solid's, a camera's)
              ws.front('Effects');
              askDockSearch();
            },
      onCardRemove: int.tryParse(l?.id ?? '') == null
          ? null
          : (title) => ws.after(
              title == 'Script' ? m.later('say', layer: int.parse(l!.id), name: 'script', word: '') : m.later('fx_out', layer: int.parse(l!.id), word: title),
              (_, _) => ws.reread(),
            ),
      cardCode: int.tryParse(l?.id ?? '') == null
          ? null
          : (title, names) => title == 'Script'
                ? (m.word(int.parse(l!.id), 'script').endsWith('.js')
                      ? FxCode(ws, int.parse(l.id), m.word(int.parse(l.id), 'script'), slot: 'script', shelf: false, key: ValueKey('script-code-${l.id}'))
                      : null)
                : FxCode.of(ws, int.parse(l!.id), title, names), // (a script's code under its knobs, and an effect's: fx_code.dart)
      onCardEye: int.tryParse(l?.id ?? '') == null
          ? null
          : (title) => ws.after(m.later('fx_visible', layer: int.parse(l!.id), word: title), (_, _) => ws.reread()),
      onCardDuplicate: int.tryParse(l?.id ?? '') == null
          ? null
          : (title) => ws.after(
              m.later('fx_duplicate', layer: int.parse(l!.id), word: title),
              (done, why) => done ? ws.reread() : ws.notice = why,
            ), // (Alight Motion's ⋮ Duplicate: put on again after it, its values with it)
      onCardInfo: (title) => ws.notice = m.about(title).isEmpty
          ? '$title: no words of its maker\'s'
          : '$title: ${m.about(title)}', // (in its maker's words, as the shelf searches them)
      onCardSave: int.tryParse(l?.id ?? '') == null
          ? null
          : (title, names) => ws.after(m.later('keep_preset', layer: int.parse(l!.id), name: names.join(' '), word: title), (done, why) {
              // (that effect's values and keys a look on the Effects shelf, by its name and a number the inside gives it)
              m.forgetFolders();
              ws.notice = done ? 'Preset kept: $title' : 'Not kept: $why';
              ws.reread();
            }),
      cardsOff: int.tryParse(l?.id ?? '') == null
          ? const []
          : [
              for (final t in m.word(int.parse(l!.id), 'fx_off').split(';'))
                if (t.isNotEmpty) t,
            ],
      onCardReset: !own || int.tryParse(l?.id ?? '') == null
          ? null
          : (names) => ws.after(m.later('reset', layer: int.parse(l!.id), word: names.join(' ')), (_, _) => ws.reread()),
      onCardCopy: !own || int.tryParse(l?.id ?? '') == null
          ? null
          : (names) => m.later(
              'copy_style',
              layer: int.parse(l!.id),
              name: names.join(' '),
              word: WorkspaceState.clipboard('card'),
            ), // (that card's values alone: Alight Motion's copy of one effect)
      onCardPaste: !own || int.tryParse(l?.id ?? '') == null
          ? null
          : () => File(WorkspaceState.clipboard('card')).existsSync()
                ? ws.after(m.later('paste_style', layer: int.parse(l!.id), word: WorkspaceState.clipboard('card')), (_, _) => ws.reread())
                : null,
      values: WorkspaceController.timed('transform', () => wsTransform(ws, l?.id)),
      strs: WorkspaceController.timed('words', () => wsWords(ws, l?.id)),
      onWords: (changed) => wsSay(ws, l?.id, changed),
      onAnimateAll: (on) => ws.animating = on,
      animating: ws.animating,
      flags: own ? WorkspaceController.timed('flags', () => wsFlags(ws, l?.id)) : const {},
      onFlags: own ? (changed) => wsFlag(ws, l?.id, changed) : null,
      keyMarks: WorkspaceController.timed('key marks', () => wsKeyMarks(ws, l?.id)),
      onValues: (changed, {required live}) => wsWrite(ws, l?.id, changed, live: live),
      onDrop: () => ws.after(m.later('drag_end')), // (put down unchanged, without waiting)
      onKey: (prop, mark) => wsMark(ws, l?.id, prop, mark),
      together: (tells) {
        // (one step, asked without waiting: begun and ended in the inside's queue around what is told)
        m.later('together', number: 1);
        tells();
        ws.after(m.later('together'));
      },
      live: _live,
      child: child,
    );
    return own
        ? Column(
            children: [
              const RelationStack(),
              Expanded(
                child: LayoutBuilder(builder: (context, box) => host(_panelOf(box))),
              ), // (the same panel while the pane keeps its size: built again only by what it reads, Ctx)
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
    children: [for (final c in Ctx.of(context).doc.cards) ValuesCard(c)],
  );
}

/// A layer's own cards by their titles, drawn as the Inspector draws them and written the same way (a tool shows the engine's card, not its own number).
class LayerCards extends StatelessWidget {
  const LayerCards({super.key, required this.layer, required this.only});
  final String layer;
  final List<String> only;
  @override
  Widget build(BuildContext context) => InspectorPane(key: ValueKey(layer), layer: layer, only: only);
}

/// The document's name for a layer's kind, for kinds the inspector's own [Kind] has no entry for (video, image, solid).
String? _kindWord(WorkspaceController ws, String? id) {
  final t = int.tryParse(id ?? ''), w = t == null ? '' : ws.inside?.word(t, 'kind') ?? '';
  if (w == 'behaviour') return wsRelations.contains(ws.inside?.word(t!, 'file')) ? 'Relation' : 'Behaviour';
  if (w == 'film' && wsSound(ws.inside!, t!)) return 'Sound';
  return const {'film', 'picture', 'solid', 'light'}.contains(w) ? w.replaceRange(0, 1, w[0].toUpperCase()) : null;
}

Kind _kindOf(Layer? l) => switch (l?.kind) {
  null => Kind.none,
  LayerKind.text => Kind.text,
  LayerKind.camera => Kind.camera,
  LayerKind.group => Kind.group,
  _ => Kind.shape,
};
