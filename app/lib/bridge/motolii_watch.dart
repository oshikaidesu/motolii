// motolii_watch.dart: how many pictures a second a film of the document has.
part of 'motolii.dart';

extension MotoliiWatch on Motolii {
  /// How many pictures a second a film written of the document has: what a frame is.
  int get rate => _rate(_m);
}
