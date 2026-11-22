import 'package:flutter/widgets.dart';

/// One layer entry offered as an Audio or Layer signal source in the Macros card.
typedef MacroLayerChoice = ({int id, String name, bool hasAudio});

/// Evaluator hooks for an effect card's custom JS UI (`<effect>.ui.js` or co-located `renderCard`).
typedef CardCustomUi = ({
  String uiFile,
  String Function(String ctxJson) render,
  String Function(String actionJson, String ctxJson) action,
});

/// What the buttons and menus on the Inspector's cards do. An action that is null is not offered.
class CardActions {
  /// Creates the actions offered on an Inspector's cards.
  const CardActions({
    this.onCardMove,
    this.onMoreCard,
    this.onAddEffect,
    this.onSum,
    this.onCardReset,
    this.onCardRemove,
    this.onAddStroke,
    this.cardEdit,
    this.onCardEye,
    this.onCardSave,
    this.onCardInfo,
    this.onCardDuplicate,
    this.onCardCopy,
    this.onCardPaste,
    this.shapeSvg,
    this.fontMeta,
    this.textClasses,
    this.propScale,
    this.layerChoices,
    this.cardCustomUi,
  });

  /// Moves a card that can move (see [InspectedLayer.movable]) by that many places in its stack.
  final void Function(String title, int by)? onCardMove;

  /// Adds one of the cards that are not shown yet (see [InspectedLayer.moreCards]).
  final void Function(String title)? onMoreCard;

  /// Opens the effect shelf with its search focused (the Add Effect row).
  final VoidCallback? onAddEffect;

  /// Evaluates an arithmetic expression typed into a number field. Returns null if the text is not one.
  final double? Function(String sum)? onSum;

  /// Resets a card's values to their defaults (Reset on the card head).
  final void Function(List<String> names)? onCardReset;

  /// Removes an effect (the bin on the card head). The card's value names are
  /// passed too, because several cards can share a title (e.g. per-instance
  /// Stroke cards): the handler reads the instance id off the names.
  final void Function(String title, List<String> names)? onCardRemove;

  /// Adds a stroke slot to the layer (the "+ Stroke" chip in the Add Effect
  /// row). Null when the layer cannot wear extra strokes.
  final VoidCallback? onAddStroke;

  /// What opens a card's code in the Code tab. The card is found by its title and its value names, because two cards
  /// can share a title. Null from the builder means the card has no code, and the row is not shown.
  final VoidCallback? Function(String title, List<String> names)? cardEdit;

  /// Turns an effect off or on again, keeping its values (the eye on the card head).
  final void Function(String title)? onCardEye;

  /// Saves an effect's values, keys included, as a preset on the shelf.
  final void Function(String title, List<String> names)? onCardSave;

  /// Shows what an effect does, in its author's words.
  final void Function(String title)? onCardInfo;

  /// Adds a copy of an effect after it, with its values.
  final void Function(String title)? onCardDuplicate;

  /// Copies a card's values so they can be pasted onto another layer (Copy on the card head).
  final void Function(List<String> names)? onCardCopy;

  /// Pastes the copied card values (Paste on the card head).
  final VoidCallback? onCardPaste;

  /// The SVG path of the selected shape layer's outline at the current time, with all path
  /// operators applied. Empty when the layer is not a drawable shape.
  final String Function()? shapeSvg;

  /// OpenType features (GSUB/GPOS) and variable-font axes (fvar) reported by the engine for a font file path.
  final String Function(String path)? fontMeta;

  /// Unicode character classes present in a text string, detected by the engine via ICU4X (`id\tlabel\tname` lines).
  final String Function(String words)? textClasses;

  /// Scale `(k, offset)` converting document units to inspector display units (`shown = doc * k + offset`).
  final (double, double) Function(String prop)? propScale;

  /// Layers available in the current composition for Audio / Layer signal sources.
  final List<MacroLayerChoice> Function()? layerChoices;

  /// Custom QuickJS Inspector card UI for an effect (sidecar `.ui.js` or co-located `renderCard`), or null.
  final CardCustomUi? Function(String title, List<String> names)? cardCustomUi;
}
