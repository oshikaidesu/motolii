// The cards whose inside the window draws itself, by the engine's card name.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/text/text_body.dart';
import 'package:motolii/inspector/transform/anchor_box.dart';
import 'package:motolii/inspector/transform/transform_body.dart';

/// A card is here only when the window can show its values as a picture that is pulled to edit them, which a block
/// per value cannot (the author's rule, 2026-11-12). The card keeps its standard frame; [drawn] names the values the
/// inside and the fold show, and the card's other values stay blocks under them. [fold] is drawn inside the card's
/// standard fold, above the folded values it does not draw.
final hostCards =
    <
      String,
      ({
        Set<String> drawn,
        Widget Function(CardDeclaration) body,
        Widget Function(CardDeclaration)? fold,
      })
    >{
      'Transform': (
        drawn: {...TransformBody.drawn, ...AnchorFold.drawn},
        body: (card) => TransformBody(card),
        fold: (card) => AnchorFold(card),
      ),
      'Text': (
        drawn: TextBody.drawn,
        body: (card) => TextBody(card),
        fold: null,
      ),
    };
