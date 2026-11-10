import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/parameter_inference.dart';

/// A card as the engine declares it, for an effect or a layer's own values: a name and a WGSL uniform struct.
///
/// workspace/inspector_feed/cards.dart writes the struct from motolii_cards (card_table.h).
/// The card's fields are whatever [infer] makes of it.
class CardDeclaration {
  CardDeclaration(this.name, this.wgsl, {required this.toneOf});
  final String name, wgsl;

  /// The skin's colour for this card. It is read when drawn, so a card made before the skin changed shows the new colour.
  final Color Function() toneOf;
  Color get tone => toneOf();
  late final List<FieldDeclaration> decls = parseWgsl(wgsl);
  late final List<Parameter> params = [for (final d in decls) infer(d)];
}
