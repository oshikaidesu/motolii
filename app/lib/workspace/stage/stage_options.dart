// The strip under the stage: the picked tool's options (fill, stroke, radius, font, the brush's kind), read from the
// picked thing or the inks a drawn one gets, and where the picked thing stands.
part of 'stage.dart';

/// Joined: a colour of the document as Flutter's (six digits; a ramp by its first); null: none.
Color? _colorOf(String word) => colorOfHex(word.split(' ').first.split('@').first)?.withAlpha(255); // (a gradient by its first stop, where it stands left out)

/// Joined: what the picked thing is painted with and how it is set (or, nothing picked, the inks a drawn thing gets).
// (read once a reading of the document and a pick: the strip is built at every picture while it plays, these do not
//  change with the moment, and a read then waits for the inside telling the stage its moment)
(Object, ({Color? fill, Color? stroke, String width, String round, String font, String size, int align}))? _paintRead;

({Color? fill, Color? stroke, String width, String round, String font, String size, int align}) _paintOf(Ws ws) {
  final key = (ws.rev, ws.selected, ws.ink, ws.edge);
  if (_paintRead case (final k, final p) when k == key) return p;
  final p = _paintNow(ws);
  _paintRead = (key, p);
  return p;
}

({Color? fill, Color? stroke, String width, String round, String font, String size, int align}) _paintNow(Ws ws) {
  final m = ws.inside!, t = int.tryParse(ws.selected ?? '');
  if (t == null) {
    return (fill: _colorOf(ws.ink), stroke: _colorOf(ws.edge), width: ws.edge.isEmpty ? 'None' : '6 px', round: '0%', font: '—', size: '—', align: 0);
  }
  final w = m.value(t, 'stroke_width', 0), r = m.value(t, 'round', 0), text = m.word(t, 'kind') == 'text';
  return (
    fill: _colorOf(m.word(t, 'fill')),
    stroke: _colorOf(m.word(t, 'stroke')),
    width: m.word(t, 'stroke').isEmpty ? 'None' : '${(w ?? 0).round()} px',
    round: '${((r ?? 0) * 200).round()}%', // (of the shorter side's half)
    font: text ? m.word(t, 'file').split('/').last.replaceFirst(RegExp(r'\.ttf$'), '') : '—',
    size: text ? '${((m.value(t, 'size', m.now) ?? 1) * m.point).round()} px' : '—',
    align: ((m.value(t, 'align', 0) ?? 0) * 2).round().clamp(0, 2),
  );
}

// ---- tool options strip ------------------------------------------------------------------------------------------------

class _OptionsStrip extends StatelessWidget {
  const _OptionsStrip({required this.tool, required this.opts, required this.onOpt, required this.scene, required this.layer, required this.ws});
  final Ws ws;
  final int tool;
  final Map<String, int> opts;
  final void Function(String, int) onOpt;
  final ArtScene scene;
  final WsLayer? layer;

  Widget _seg(BuildContext c, String key, List<String> items, {int initial = 0}) =>
      Forms.worn.segment(c, ChoiceSpec(labels: items, selected: opts[key] ?? initial, onSelect: (i) => onOpt(key, i)));
  Widget _flag(String key, String label, {bool initial = false}) {
    final on = (opts[key] ?? (initial ? 1 : 0)) == 1;
    return _Toggle(label: label, on: on, icon: _Icon.safe, onTap: () => onOpt(key, on ? 0 : 1));
  }

  List<Widget> _items(BuildContext c) => _joined(c, ws, _paintOf(ws));

  /// Joined: the tool's own settings (how it draws or carries), and the picked thing's values as the document has them.
  List<Widget> _joined(BuildContext c, Ws ws, ({Color? fill, Color? stroke, String width, String round, String font, String size, int align}) p) =>
      switch (tool) {
        0 => [
          _seg(c, 'sel.level', const ['Layer', 'Group']),
          _flag('sel.snap', 'Snap', initial: true),
          _flag('sel.pivot', 'Pivots'),
        ],
        1 => [
          _seg(c, 'move.axis', const ['Free', 'X', 'Y']),
          _flag('move.snap', 'Snap', initial: true),
        ],
        2 => [
          _Field('Fill', swatch: p.fill ?? WsT.body),
          _Field('Stroke', value: p.width),
          _Field('Radius', value: p.round),
          _seg(c, 'rect.mode', const ['Shape', 'Mask']),
        ],
        3 => [
          _Field('Fill', swatch: p.fill ?? WsT.body),
          _Field('Stroke', value: p.width),
          _seg(c, 'ell.from', const ['Corner', 'Centre']),
        ],
        4 => [
          _seg(c, 'pen.mode', const ['Path', 'Mask']),
        ],
        7 => [_Field('Drag', value: 'Orbit'), _Field('Wheel', value: 'Dolly')], // (what the hand does with it, as After Effects' camera tools are named)
        6 => [
          _Field('Fill', swatch: p.fill ?? WsT.body),
          _seg(c, 'brush.kind', const ['Brush', 'Pen', 'Fill', 'Eraser']),
          _seg(c, 'brush.size', const ['Thin', 'Medium', 'Thick'], initial: 1),
        ], // (Alight Motion's drawing tools: as the pressure says, as wide all along, the way gone round filled, and its eraser, of the picked drawing)
        _ => [
          _Field('Font', value: p.font),
          _Field('Size', value: p.size),
          Forms.worn.segment(
            c,
            ChoiceSpec(
              labels: const ['L', 'C', 'R'],
              selected: p.align,
              onSelect: (i) {
                // (the picked text's lines laid so: the document's align)
                final t = int.tryParse(ws.selected ?? '');
                final m = ws.inside;
                if (t == null || m == null) return;
                m
                  ..later('together', number: 1)
                  ..later('set', layer: t, name: 'align', number: i / 2)
                  ..later('set', layer: t, name: 'anchor_x', number: i - 1.0); // (round where it stands: After Effects' point text)
                ws.after(m.later('together')); // (without waiting)
              },
            ),
          ),
          _Field('Fill', swatch: p.fill ?? WsT.body), // (and its colour, in the same row: Alight Motion's text bar, align, font, size, colour)
        ],
      };

  @override
  Widget build(BuildContext context) {
    final items = _items(context);
    return LayoutBuilder(
      builder: (_, box) => ToolStrip(
        height: WsT.header,
        color: WsT.body,
        line: true,
        gap: WsT.inset,
        left: [
          SizedBox(
            width: Shape.z(62),
            child: Text(_tools[tool].$2.toUpperCase(), style: T.micro(Grey.g56).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          for (var i = 0; i < items.length; i++) ...[if (i > 0) SizedBox(width: Shape.s(6)), items[i]],
        ],
        right: [
          ConstrainedBox(
            // (as wide as it is, the tools before it given the rest; wider than the whole strip, drawn smaller, never cut, as dock_widgets.dart's trailing)
            constraints: BoxConstraints(maxWidth: (box.maxWidth - 2 * WsT.inset).clamp(0, double.infinity)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: ValueListenableBuilder<int>(
                valueListenable: ws.seen,
                builder: (_, _, _) => _Readout(scene: scene, layer: layer),
              ),
            ), // (and while a hand carries a value)
          ),
        ],
      ),
    );
  }
}

/// A labelled value in a well: the options strip's mock fields.
class _Field extends StatelessWidget {
  const _Field(this.label, {this.value, this.swatch});
  final String label;
  final String? value;
  final Color? swatch;
  @override
  Widget build(BuildContext context) => Container(
    height: Shape.z(20),
    padding: EdgeInsets.symmetric(horizontal: Shape.s(7)),
    decoration: BoxDecoration(color: WsT.well, borderRadius: BorderRadius.all(Shape.r(WsT.radius))),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: T.micro(Grey.g56)),
        SizedBox(width: Shape.s(6)),
        if (swatch case final s?)
          Container(
            width: Shape.z(22),
            height: Shape.z(12),
            decoration: BoxDecoration(color: s, borderRadius: BorderRadius.all(Shape.r(3))),
          )
        else
          Text(value ?? '', style: T.value(Grey.g91)),
      ],
    ),
  );
}

/// The selected layer at this frame: its hue and name, then position, scale and rotation as the stage sees them.
class _Readout extends StatelessWidget {
  const _Readout({required this.scene, required this.layer});
  final ArtScene scene;
  final WsLayer? layer;
  @override
  Widget build(BuildContext context) {
    final l = layer, box = WsArt.boxOf(scene, l?.id), ws = WsScope.of(context, {WsAspect.document, WsAspect.picked});
    if (l == null || ws.many.length > 1) {
      return Text(
        ws.many.isEmpty ? 'Nothing selected' : '${ws.many.length} picked',
        style: T.label(Grey.g56),
      ); // (picked together, one of them picked before or not: said so, as the bar over the stage does)
    }
    Widget pair(String k, String v) => Padding(
      padding: EdgeInsets.only(left: Shape.s(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(k, style: T.micro(Grey.g56)),
          SizedBox(width: Shape.s(4)),
          Text(v, style: T.value(Grey.g91)),
        ],
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Badge(l.tone, size: Shape.z(8), radius: Shape.r(2)),
        SizedBox(width: Shape.s(6)),
        Text(l.name, style: T.name(Grey.g95).copyWith(fontWeight: FontWeight.w600)),
        // (a relation has no picture of its own: nothing to say; nor has a camera, which is on the frame while its bar is,
        //  and has no size: its name alone, as After Effects' camera layer has no bounds and no Scale; golf (76))
        if (box == null &&
            ws.inside?.word(int.parse(l.id), 'kind') != 'behaviour' &&
            !(l.kind == WsKind.camera && (scene.layer(l.id)?.live(scene.frame) ?? false)))
          Padding(
            padding: EdgeInsets.only(left: Shape.s(10)),
            child: Text(
              l.kind == WsKind.audio
                  ? 'No picture'
                  : ws.freeEye && (scene.layer(l.id)?.live(scene.frame) ?? false)
                  ? 'In Camera View'
                  : 'Not on this frame',
              style: T.label(Grey.g56),
            ), // (a 2D thing shows in the camera's eye alone, as in After Effects' working views)
          )
        else if (l.kind != WsKind.camera) ...[
          // (the same numbers as the inspector's, which are the document's)
          if (wsPlace(ws, l.id) case final at) ...[
            pair('P', '${at['x']?.round()}, ${at['y']?.round()}'),
            pair('S', '${at['scale_y']?.round()}%'),
            pair('R', '${at['rotate']?.round()}°'),
          ],
        ],
      ],
    );
  }
}
