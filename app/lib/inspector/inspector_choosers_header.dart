import 'package:flutter/widgets.dart';

import '../skin/tokens.dart';
import 'inspector_parts.dart';

class InspHeader extends StatelessWidget {
  const InspHeader({super.key});
  @override
  Widget build(BuildContext context) {
    final x = Ctx.of(context), doc = x.doc, ed = const Ed();
    final w = doc.kindWord; // (what the host calls it, where the kinds have no word)
    final word = switch (doc.kind) {
      Kind.shape when w != null => w,
      Kind.shape => 'Shape',
      Kind.text => 'Text',
      Kind.camera => 'Camera',
      Kind.group => 'Group',
      Kind.several => 'Layers',
      Kind.none => '',
    };
    if (Pop.on(context)) {
      return Container(
        height: Shape.z(34),
        padding: EdgeInsets.symmetric(horizontal: Pop.inset),
        color: Pop.card,
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
            Text(doc.kind == Kind.several ? 'Several' : word, maxLines: 1, style: T.label(Grey.g56)),
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
    return Padding(
      padding: EdgeInsets.only(bottom: Shape.s(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ed.kick(doc.kind == Kind.several ? 'Several selected' : word),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ed.kickStyle(Grey.g56),
                ),
                SizedBox(height: Shape.s(4)),
                Text(
                  doc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ed.nameStyle(),
                ),
              ],
            ),
          ),
          SizedBox(width: Shape.s(8)),
          // contract: while on, editing an unkeyed value writes its first key at the playhead (D2).
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Animate all', style: T.label(doc.animateAll ? Grey.g95 : Grey.g63)),
              SizedBox(height: Shape.s(4)),
              OnOff(
                on: doc.animateAll,
                onChanged: (v) {
                  doc.animateAll = v;
                  doc.poke();
                },
              ),
            ],
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
    final x = Ctx.of(context), ed = const Ed();
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
            decoration: BoxDecoration(color: h ? Grey.g20 : Pop.well, borderRadius: BorderRadius.all(Shape.r(6))),
            child: Text('Stage settings', style: T.label(h ? Grey.g95 : Grey.g76)),
          ),
        ),
        if (x.doc.b['stage.open'] ?? false)
          for (final c in x.doc.cards) ValuesCard(c),
        SizedBox(height: Shape.s(1)),
        Container(height: 1, color: ed.rule),
      ],
    );
  }
}
