// The cards whose inside the window draws itself, by the engine's card name.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/blend/blend_preview.dart';
import 'package:motolii/inspector/camera/camera_view.dart';
import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/fill/fill_body.dart';
import 'package:motolii/inspector/paths/paths_body.dart';
import 'package:motolii/inspector/source/film_strip.dart';
import 'package:motolii/inspector/text/text_body.dart';
import 'package:motolii/inspector/transform/anchor_box.dart';
import 'package:motolii/inspector/transform/transform_body.dart';

/// A card is here only when the window can show its values as a picture that is pulled to edit them, which a block
/// per value cannot (the author's rule, 2026-11-12). The card keeps its standard frame; [drawn] names the values the
/// inside and the fold show, and the card's other values stay blocks under them. [fold] is drawn inside the card's
/// standard fold, above the folded values it does not draw. [absorbs] names the card titles that this card shows
/// inline; those cards are suppressed from the main panel loop.
final hostCards =
    <
      String,
      ({
        Set<String> drawn,
        Set<String> absorbs,
        Widget Function(CardDeclaration) body,
        Widget Function(CardDeclaration)? fold,
      })
    >{
      'Transform': (
        drawn: {...TransformBody.drawn, ...AnchorFold.drawn},
        absorbs: const {},
        body: (card) => TransformBody(card),
        fold: (card) => AnchorFold(card),
      ),
      'Text': (
        drawn: TextBody.drawn,
        absorbs: const {},
        body: (card) => TextBody(card),
        fold: null,
      ),
      // The optional cards keep their number tiles below the picture, as Trim Paths did.
      'Blending': (
        drawn: const {
          'blend',
          'clip',
          'clip_matte',
          'clip_invert',
          'clip_feather',
        },
        absorbs: const {},
        body: (card) => BlendPreview(card),
        fold: null,
      ),
      'Paths': (
        drawn: PathsBody.drawn,
        absorbs: const {},
        body: (card) => PathsBody(card),
        fold: null,
      ),
      'Media': (
        drawn: const {},
        absorbs: const {},
        body: (card) => FilmStrip(card),
        fold: null,
      ),
      'Camera': (
        drawn: CameraBody.drawn,
        absorbs: const {},
        body: (card) => CameraBody(card),
        fold: null,
      ),
      'Fill': (
        drawn: FillBody.drawn,
        absorbs: const {'Stroke'},
        body: (card) => FillBody(card),
        fold: null,
      ),
    };
