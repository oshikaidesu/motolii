import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/inspector_state.dart';

/// The layer the Inspector shows, as its caller describes it: its kind and name, and its cards.
///
/// With no layer selected its kind is [Kind.none], and its cards are whatever the caller shows then.
class InspectedLayer {
  /// Creates the description of the layer an Inspector shows.
  const InspectedLayer({
    required this.kind,
    this.kindWord,
    this.title,
    this.cards,
    this.movable = const [],
    this.moreCards = const [],
    this.cardsOff = const [],
  });

  /// The kind of the layer, or [Kind.none] when no layer is selected.
  final Kind kind;

  /// The caller's name for the layer kind where the six kinds have none, such as video, image or solid. Null uses the kind's own name.
  final String? kindWord;

  /// The layer's name, when the caller knows it.
  final String? title;

  /// The caller's cards of values. Each card's params become fields keyed `v_` plus the value name.
  final List<CardDeclaration>? cards;

  /// Titles of the cards that can move up or down (the layer's effects), in the order of their stack.
  final List<String> movable;

  /// Titles of cards the caller could add that are not shown yet.
  final List<String> moreCards;

  /// Titles of the effects that are turned off.
  final List<String> cardsOff;
}
