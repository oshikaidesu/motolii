// Engine diagnostics, for checks and for people debugging: why the last call was refused, how long calls take,
// when the app had to wait on the engine, and the frame rate.
part of 'motolii.dart';

extension MotoliiWatch on Motolii {
  String get error => _error(_m).toDartString();

  /// The project's frame rate in frames per second.
  int get rate => _rate(_m);

  /// The frame ranges [from, to) of the stage that are cached on disk for playback (motolii_cache).
  List<(int, int)> get cache {
    final n = _cacheRuns(_m).toDartString().split(' ').where((w) => w.isNotEmpty).map(int.parse).toList();
    return [for (var i = 0; i + 1 < n.length; i += 2) (n[i], n[i + 1])];
  }

  String get broken => _broken(_m).toDartString();

  // How many times since watching began. Reading it does not wait.
  int get brokenCount => _brokenCount(_m);
}
