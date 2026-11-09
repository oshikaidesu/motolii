// motolii_watch.dart: how the inside is doing, for a check or a person looking: why the last call was refused, what it holds, what its calls cost, when the window waited on it, how many pictures it drew.
part of 'motolii.dart';

extension MotoliiWatch on Motolii {
  String get error => _error(_m).toDartString();

  /// How many pictures a second a film written of the document has: what a frame is.
  int get rate => _rate(_m);
}
