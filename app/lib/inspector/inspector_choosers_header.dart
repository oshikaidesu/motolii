import 'package:flutter/widgets.dart';

import '../skin/tokens.dart';
import 'inspector_parts.dart';

class InspHeader extends StatelessWidget {
  const InspHeader({super.key});
  @override
  Widget build(BuildContext context) {
    final doc = Ctx.of(context).doc;
    final w = doc.kindWord; // (what the host calls it, where the kinds have no word)
    final word = switch (doc.kind) {
      Kind.shape when w != null => w,
      Kind.shape => 'Shape',
      Kind.text => 'Text',
      Kind.camera => 'Camera',
      Kind.group => 'Group',
      Kind.none => '',
    };
    return Container(
      height: Shape.z(34),
      padding: EdgeInsets.symmetric(horizontal: Pop.inset),
      color: Grey.g13,
      child: Row(
        children: [
          Flexible(
            child: FittedBox(
              // (drawn smaller, never cut)
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                doc.name,
                maxLines: 1,
                style: T.title(Grey.g100).copyWith(fontSize: T.px(13), fontWeight: FontWeight.w700, height: 1),
              ),
            ),
          ),
          SizedBox(width: Shape.s(6)),
          Text(word, maxLines: 1, style: T.label(Grey.g56)),
          const Spacer(),
          Text('Animate all', style: T.label(Grey.g63)),
          SizedBox(width: Shape.s(6)),
          OnOff(
            on: doc.animateAll,
            onChanged: (v) {
              doc.animateAll = v;
              doc.poke();
            },
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext context) {
    final x = Ctx.of(context);
    // contract: one plain muted line, no controls, no stale values (A6).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(top: Shape.s(4), bottom: Shape.s(8)),
          child: Text('Nothing selected', style: T.label(Grey.g56).copyWith(height: 1.4)),
        ),
        // (nothing picked, nothing shown: After Effects' Effect Controls is a layer's; the picture's own values open when asked)
        Hov(
          key: const ValueKey('stage-settings'),
          onTap: () => x.doc.flag('stage.open', !(x.doc.b['stage.open'] ?? false)),
          builder: (_, h) => Container(
            height: Pop.cell,
            margin: EdgeInsets.only(bottom: Pop.gap),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: h ? Grey.g20 : Grey.g15, borderRadius: BorderRadius.all(Shape.r(6))),
            child: Text('Stage settings', style: T.label(h ? Grey.g95 : Grey.g76)),
          ),
        ),
        if (x.doc.b['stage.open'] ?? false)
          for (final c in x.doc.cards) ValuesCard(c),
        SizedBox(height: Shape.s(1)),
        Container(height: 1, color: const Color.fromRGBO(255, 255, 255, .12)),
      ],
    );
  }
}
