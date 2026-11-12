import 'package:flutter/widgets.dart';

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
    this.cardEdit,
    this.onCardEye,
    this.onCardSave,
    this.onCardInfo,
    this.onCardDuplicate,
    this.onCardCopy,
    this.onCardPaste,
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

  /// Removes an effect (the bin on the card head).
  final void Function(String title)? onCardRemove;

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
}
