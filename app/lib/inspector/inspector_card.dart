import 'package:flutter/widgets.dart';

import '../skin/tokens.dart';
import 'inspector_parts.dart';

/// A card as the inside declares it: a name and a WGSL uniform struct. Its fields are whatever [infer] makes of them.
class Fx {
  Fx(this.id, this.name, this.wgsl, {Color? tone, Color Function()? toneOf}) : _tone = tone, _toneOf = toneOf;
  final String id, name, wgsl;
  final Color? _tone;
  final Color Function()? _toneOf; // (a skin's colour: read when drawn, so a card made before the skin changed wears the new one)
  Color get tone => _toneOf?.call() ?? _tone!;
  late final List<Decl> decls = parseWgsl(wgsl);
  late final List<Param> params = [for (final d in decls) infer(d)];
}

/// Every card of the panel, drawn one way: its declaration's Params, each field a value.
class ValuesCard extends StatelessWidget {
  const ValuesCard(this.card, {super.key});
  final Fx card;
  @override
  Widget build(BuildContext context) {
    final doc = Ctx.of(context).doc, k = 'v.${card.name}', adv = doc.b['$k.adv'] ?? false;
    final heroes = [for (final p in card.params) if (!p.advanced) p];
    final rest = [for (final p in card.params) if (p.advanced) p];
    return PastRange(
      flag: '$k.past',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: Shape.s(4)),
            child: Text(card.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(card.tone)),
          ),
          ParamGrid('v', heroes),
          if (rest.isNotEmpty) ...[
            Hov(
              onTap: () => doc.flag('$k.adv', !adv),
              builder: (_, h) => Padding(
                padding: EdgeInsets.only(top: Shape.s(4)),
                child: Row(
                  children: [
                    Text(rest.first.fold ?? 'Advanced', style: T.label(h || adv ? Grey.g95 : Grey.g63)),
                    const Spacer(),
                    FoldMark(open: adv, hot: h || adv),
                  ],
                ),
              ),
            ),
            if (adv) ParamGrid('v', rest),
          ],
        ],
      ),
    );
  }
}
