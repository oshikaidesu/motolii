// The cards whose inside the window draws itself, by the engine's card name.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/transform/transform_body.dart';

/// A card is here only when the window can show its values as a picture that is pulled to edit them, which a block
/// per value cannot (the author's rule, 2026-11-12). The card keeps its standard frame; [drawn] names the values the
/// inside shows, and the card's other values stay blocks under it.
final hostCards =
    <String, ({Set<String> drawn, Widget Function(CardDeclaration) body})>{
      'Transform': (
        drawn: TransformBody.drawn,
        body: (card) => TransformBody(card),
      ),
    };
