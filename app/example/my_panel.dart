// A panel of one's own, made of the standard alone (package:motolii/panel.dart): a value of the picked layer as a number,
// its cards as the engine declares them, and a press. To see it in the window, hand it to the Workspace in lib/main.dart:
//   Workspace(document: motoliiDoc, extra: const [Pane('Mine', null, MyPanel.new)])
// dart analyze keeps this file true: when the standard changes, this stops compiling until it is brought along.
import 'package:flutter/widgets.dart';
import 'package:motolii/panel.dart';

class MyPanel extends StatelessWidget {
  const MyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context),
        m = ws.inside,
        layer = int.tryParse(ws.selected ?? '');
    if (m == null || layer == null) {
      return Center(
        child: Text('Pick a layer', style: TextStyles.label(Grey.g56)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PanelHeader('Mine'),
        // A number of the document: read at the moment shown, carried while the hand drags, one step when it lets go.
        // The shown range (min, max) is for the bar: what is typed is not cut to it.
        NumberField(
          caption: 'Opacity',
          value: () => m.value(layer, 'opacity', m.now),
          text: (v, _) => (v * 100).toStringAsFixed(0),
          min: 0,
          max: 1,
          perPx: .005,
          onGrab: () => m.take(layer),
          onChange: (v) => m.dragUpdate('opacity', v),
          onDrop: () => ws.after(m.later('drag_end', number: 1)),
          onType: (v) => ws.after(
            m.later('set', layer: layer, name: 'opacity', number: v),
          ),
        ),
        // The layer's values as the engine declares them (engine/document/card_table.h): no Dart of one's own.
        Expanded(
          child: LayerCards(layer: ws.selected!, only: const ['Transform']),
        ),
        Chip(
          label: 'Opaque',
          onTap: () => ws.after(
            m.later('set', layer: layer, name: 'opacity', number: 1),
          ),
        ),
      ],
    );
  }
}
