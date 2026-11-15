// A word the app sets and a worker isolate reads, to tell the isolate to stop between its steps.
import 'dart:ffi';

import 'package:ffi/ffi.dart' show calloc;

class HaltFlag {
  HaltFlag._(this._word);

  /// A new flag, not raised. [dispose] it when its isolate has ended.
  static HaltFlag create() => HaltFlag._(calloc.allocate<Int32>(4)..value = 0);

  /// The flag at [address], as the isolate received it from [address].
  static HaltFlag at(int address) =>
      HaltFlag._(Pointer<Int32>.fromAddress(address));

  final Pointer<Int32> _word;

  int get address => _word.address;

  bool get raised => _word.value != 0;

  void raise() => _word.value = 1;

  void dispose() => calloc.free(_word);
}
