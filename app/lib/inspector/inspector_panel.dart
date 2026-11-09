import 'package:flutter/widgets.dart';

import '../skin/tokens.dart';
import 'inspector_parts.dart';

/// The Inspector: one scrolling stack of the host's cards. Needs an InspHost above it.
class InspectorPanel extends StatefulWidget {
  const InspectorPanel({super.key});
  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  final _node = FocusNode(debugLabel: 'inspector');
  final _scroll = ScrollController();

  @override
  void dispose() {
    _node.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = Ctx.of(context).doc, k = doc.kind;
    final body = <Widget>[
      if (k == Kind.none)
        const EmptyState()
      else ...[
        // contract: one stack: the host's cards, Transform first, then the effects on it, then what it may do besides (Premiere Pro's Effect Controls: the effects put on under Motion and Opacity); every titled card folds on its own.
        for (final c in doc.cards) ValuesCard(c),
      ],
    ];
    final panel = Focus(
      focusNode: _node,
      child: Listener(
        onPointerDown: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_node.hasFocus) _node.requestFocus();
        }),
        child: SizedBox.expand(
          child: ColoredBox(
            color: Grey.g07,
            // (only the cards in sight are built: a stage with seventy effects on it builds as one with seven; a text just
            //  placed waits for its card, out of sight under Transform: built for it, the box then scrolls itself to the caret)
            child: Column(
              children: [
                // (the name and Animate all stay where they are, the cards going by under them: Alight Motion's key button stands in the panel's frame, outside what scrolls, LayerTools.kt LayerPanel)
                if (k != Kind.none) Padding(padding: EdgeInsets.fromLTRB(Pop.gap, Pop.gap, Pop.gap, 0), child: const InspHeader()),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: EdgeInsets.all(Pop.gap),
                    children: body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Overlay.maybeOf(context) == null ? Overlay.wrap(child: panel) : panel;
  }
}
