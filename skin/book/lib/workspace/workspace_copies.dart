// workspace_copies.dart: a group's Copies card (the user, 11/8, drawn on the screen): no picture of the copies; How
// many (the total); then the things the group holds as a list, each with its small picture (the timeline's,
// thumbs.dart), its name, and how many of the copies it takes in a turn (×, its ratio: doc_dealt). How the copies are
// laid is the Arrange card, not there unasked (doc_values.h). Any other thing's Copies card is as it was (ValuesCard, CopiesDrawing).
part of 'workspace.dart';

/// The Copies card as the window draws it: a group's own, or the usual one.
class WsCopiesCard extends StatelessWidget {
  const WsCopiesCard(this.card, {super.key});
  final Fx card;
  @override
  Widget build(BuildContext context) => Ctx.of(context).doc.kind == Kind.group ? WsGroupCopies(card) : ValuesCard(card, top: const CopiesDrawing());
}

class WsGroupCopies extends StatefulWidget {
  const WsGroupCopies(this.card, {super.key});
  final Fx card;
  @override
  State<WsGroupCopies> createState() => _WsGroupCopiesState();
}

class _WsGroupCopiesState extends State<WsGroupCopies> {
  late final _thumbs = WsThumbs(onLoaded: () => setState(() {}), mounted: () => mounted);
  (int, double)? _held;   // (a thing's ratio while a hand scrubs or types it: carried, not yet let go)

  // (what it lists is the group's things and their values, not the group's own: drawn again as the document changes,
  //  where the inspector's seat would only pour new numbers into the picked thing's fields)
  Ws? _ws;
  void _changed() => mounted ? setState(() {}) : null;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = WsScope.read(context);
    if (ws == _ws) return;
    _ws?.on[WsAspect.document]!.removeListener(_changed);
    ws.on[WsAspect.document]!.addListener(_changed);
    _ws = ws;
  }

  @override
  void dispose() {
    _ws?.on[WsAspect.document]!.removeListener(_changed);
    super.dispose();
  }

  // The hand's change of a thing's ratio: taken once, carried at each step, let go as one step (as the Count row was).
  void _ratio(Ws ws, Motolii m, int thing, double v) {
    if (_held == null) {
      m.later('together', number: 1);
      m.take(thing);
      if (ws.playing) ws.playing = false;
    }
    setState(() => _held = (thing, v));
    m.carry('ratio', v.roundToDouble());
  }

  void _ratioDone(Ws ws, Motolii m) {
    if (_held == null) return;
    m.later('let_go', number: 1);
    ws.after(m.later('together'), (_, _) {
      ws.reread();
      if (mounted) setState(() => _held = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ws = WsScope.read(context), m = ws.inside, l = ws.layer, t = int.tryParse(l?.id ?? '');
    if (m == null || t == null) return ValuesCard(widget.card);
    final card = widget.card, count = [for (final p in card.params) if (p.id == 'copies') p];
    final things = _membersOf(ws, m, t), locked = l?.locked ?? false;
    return Sect(
      title: card.name,
      tone: card.tone,
      mark: card.mark,
      children: [
        ParamGrid('v', count),   // (how many in all)
        // (the things it holds, in the timeline's order, each with its picture, its name and its share of a turn)
        Padding(
          padding: EdgeInsets.only(top: Shape.s(6)),
          child: Column(
            children: [
              for (final c in things)
                Padding(
                  key: ValueKey('ws-copies-member-${c.id}'),
                  padding: EdgeInsets.only(bottom: Shape.s(3)),
                  child: Row(
                    children: [
                      WtThumb.of(
                        kind: c.kind,
                        frames: _thumbs.framesOf(ws, c),
                        form: _thumbs.formOf(ws, c)?.$1,
                        fill: _thumbs.formOf(ws, c)?.$2,
                        outline: _thumbs.formOf(ws, c)?.$3 ?? false,
                        dim: c.hidden,
                        tone: c.tone,
                        size: Shape.z(20),
                      ),
                      SizedBox(width: Shape.s(8)),
                      Expanded(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(c.hidden ? Grey.g56 : Grey.g91))),
                      SizedBox(width: Shape.s(8)),
                      SizedBox(
                        width: Shape.z(64),
                        child: DeskScrub(
                          label: '',
                          value: _held?.$1 == int.parse(c.id) ? _held!.$2 : (m.value(int.parse(c.id), 'ratio', 0) ?? 1),
                          min: 1,
                          max: 20,
                          perPx: .1,
                          pad: 4,
                          enabled: !locked,
                          format: (v) => '×${v.round()}',
                          onChanged: (v) => _ratio(ws, m, int.parse(c.id), v),
                          onDone: () => _ratioDone(ws, m),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
