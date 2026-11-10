// Engine diagnostics, for checks and for people debugging: why the last call was refused, how long calls take,
// when the app had to wait on the engine, and the frame rate.
import 'package:ffi/ffi.dart';

import 'package:motolii/bridge/motolii.dart';

extension MotoliiWatch on Motolii {
  String get error => bindings.motolii_error(handle).toDartString();

  /// The project's frame rate in frames per second.
  int get rate => bindings.motolii_rate(handle);

  /// The frame ranges [from, to) of the stage that are cached on disk for playback (motolii_cache).
  List<(int, int)> get cache {
    final n = bindings
        .motolii_cache(handle)
        .toDartString()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map(int.parse)
        .toList();
    return [for (var i = 0; i + 1 < n.length; i += 2) (n[i], n[i + 1])];
  }

  /// Diagnostics for the app's thread. [broken] lists, one per line, each change it waited for and each read that
  /// waited on the project longer than 2 ms. Empty when there are none.
  String get broken => bindings.motolii_broken(handle).toDartString();

  // How many times since watching began. Reading it does not wait.
  int get brokenCount => bindings.motolii_broken_count(handle);
}
