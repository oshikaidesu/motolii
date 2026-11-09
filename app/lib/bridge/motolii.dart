// The present inside (motolii/engine/motolii.h), called straight from Dart: dart:ffi on its C calls, as
// sets/glass_live.dart calls the old glass. The skin holds no document: it holds this handle and the numbers of things.
// One call = one change = one step of undo. A call that is not done returns false and [trouble] says why.
// macOS only, Debug build only (the Debug entitlements have the sandbox off so that the library can be loaded).
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show debugPrint, setEquals;
import 'package:flutter/services.dart';
import 'package:motolii/bridge/motolii_bindings.dart' as c; // (the inside's calls as Dart's ffigen made them: ffigen.yaml)
part 'motolii_document.dart';
part 'motolii_moment.dart';
part 'motolii_writes.dart';
part 'motolii_questions.dart';
part 'motolii_shelves.dart';
part 'motolii_watch.dart';

/// Where the inside lives: --dart-define=MOTOLII_DIR=/path/to/motolii/engine, or else the engine/ found going up from
/// where it was started (run from app) or from this program (the app is built under app/build/).
final String motoliiDir = () {
  const given = String.fromEnvironment('MOTOLII_DIR');
  if (given.isNotEmpty) return given;
  for (final from in [Directory.current, File(Platform.resolvedExecutable).parent]) {
    for (var d = from.absolute; ; d = d.parent) {
      if (File('${d.path}/engine/edit.sh').existsSync()) return '${d.path}/engine';
      if (d.parent.path == d.path) break;
    }
  }
  return 'engine';
}();

/// The library's own shelves (effects, create, skins…): shelves/, beside engine/.
final String motoliiShelves = '${Directory(motoliiDir).absolute.parent.path}/shelves';

/// The maker's own folder, a folder in it for each shelf: MOTOLII_OWN, or ~/Library/Application Support/Motolii (as the inside's doc_folders).
String get motoliiOwn => Platform.environment['MOTOLII_OWN'] ?? '${Platform.environment['HOME']}/Library/Application Support/Motolii';

/// The document the window opens: --dart-define=MOTOLII_DOC=/path/to.motolii, or the inside's own out/skin.motolii.
String get motoliiDoc {
  const given = String.fromEnvironment('MOTOLII_DOC');
  return given.isNotEmpty ? given : '$motoliiDir/out/skin.motolii';
}

typedef _P = Pointer<c.Motolii>;
typedef _S = Pointer<Utf8>;

class Motolii {
  Motolii._(this._lib, this._m, this.libPath);
  final DynamicLibrary _lib;
  late final _b = c.MotoliiBindings(_lib); // (the inside's calls, made by Dart's ffigen from motolii.h: ffigen.yaml)
  final _P _m;
  final String libPath;

  /// The document at [document] (made if it is not there), on a stage [wide] by [high]. null: it could not be opened.
  static Motolii? open(String document, {int wide = 1920, int high = 1080, String? dir}) {
    dir ??= motoliiDir;
    final path = '$dir/out/libmotolii.dylib';
    final DynamicLibrary lib;
    try {
      lib = DynamicLibrary.open(path);
    } catch (_) {
      return null;
    }
    final home = '$dir/out/filament_webgpu'.toNativeUtf8(), doc = document.toNativeUtf8();
    c.MotoliiBindings(lib).motolii_home(home);
    final m = c.MotoliiBindings(lib).motolii_open(doc, wide, high);
    malloc
      ..free(home)
      ..free(doc);
    if (m == nullptr) return null;
    return Motolii._(lib, m, path).._listen();
  }

  // ------------------------------------------------------------------ the pictures (docs/app/BRIDGE.md)
  // What the window reads of the document is the inside's two pictures, set down by its hand: the document's, made
  // again where it changes, and the moment's, made with each picture. The inside tells which is new through one
  // listener; nothing here asks the document itself, and nothing waits for the hand.
  late final _snapshot = _b.motolii_snapshot;
  late final _addListener = _b.motolii_add_listener;
  NativeCallable<Void Function(Int)>? _listenerCallable;
  Map<String, dynamic> _document = const {}; // (the document's own part)
  final _layer = <int, Map<String, dynamic>>{}; // (each thing's part, as of the version it came with)
  Map<String, dynamic> _moment = const {'layer': {}};
  int _documentAt = -1, _momentAt = -1;

  /// What the window does when the inside's pictures are new: [document] the document's (and which things changed in
  /// it), [moment] the moment's, [kept] the stretches of the stage's pictures kept on disk.
  void Function({required bool document, required bool moment, required bool cache})? listener;

  final _knows = <String, Set<String>>{}; // (the maker's tables, the same for every document: read once)
  static List<String> _spaced(Object? said) => [
    for (final w in ((said as String?) ?? '').split(' '))
      if (w.isNotEmpty) w,
  ];
  static List<double> _numbers(Object? said) => [for (final n in (said as List<dynamic>?) ?? const []) (n as num).toDouble()];

  late final _play = _b.motolii_play;
  late final _at = _b.motolii_at;
  late final _workOut = _b.motolii_work_out;

  late final _add = _b.motolii_add;
  late final _remove = _b.motolii_remove;
  late final _set = _b.motolii_set;
  late final _keying = _b.motolii_keying;
  late final _dragUpdate = _b.motolii_drag_update;
  late final _kindOf = _b.motolii_kind_of;
  late final _still = _b.motolii_still;
  late final _close = _b.motolii_close;

  static const _channel = MethodChannel('motolii/stage');

  Set<int> _watched = const {};

  late final _rate = _b.motolii_rate;

  final _unaskedSaid = <String>{};

  late final _shaping = _b.motolii_shaping;

  /// The names of the values that change what cards a thing has (and its name): the inside's own rule, asked once.
  late final Set<String> shaping = _shaping(_m).toDartString().split(' ').toSet();

  final _shownOf = <String, Shown?>{}; // (read out of the things' parts once a picture of the document)

  late final _later = _b.motolii_later;
  late final _answer = _b.motolii_answer;
  late final _answerWhy = _b.motolii_answer_why;

  final _waiting = <int, Completer<(int, String)>>{};

  void _listen() {
    _listenerCallable = NativeCallable<Void Function(Int)>.listener(_take);
    _addListener(_m, _listenerCallable!.nativeFunction);
    _take(7);
  }

  void _take(int which) {
    if (which & 8 != 0) which |= 3; // (the answers looked at are all there are by now, later ones than the one told: heard late, a step's end comes with what the step made, as answer() takes them)
    final version = malloc<Long>();
    if (which & 1 != 0) {
      final p = _snapshot(_m, 1, _documentAt, version), all = jsonDecode(p.toDartString()) as Map<String, dynamic>;
      malloc.free(p);
      if (version.value == _documentAt) which &= ~1; // (asked again, not new: nothing told)
      _documentAt = version.value;
      if (all['document'] case final Map<String, dynamic> d) _document = d;
      (all['layer'] as Map<String, dynamic>).forEach((t, part) => _layer[int.parse(t)] = part as Map<String, dynamic>);
      final are = {0, ...layers};
      _layer.removeWhere((t, _) => !are.contains(t));
      _shownOf.clear();
    }
    if (which & 2 != 0) {
      final p = _snapshot(_m, 2, 0, version);
      if (version.value == _momentAt) {
        which &= ~2; // (asked again, not new)
      } else {
        _moment = jsonDecode(p.toDartString()) as Map<String, dynamic>;
        _momentAt = version.value;
      }
      malloc.free(p);
    }
    malloc.free(version);
    if (which & 8 != 0) {
      // (an answer is there: the changes waited for, each looked at once)
      for (final t in [..._waiting.keys]) {
        final a = _answer(_m, t);
        if (a >= 0) _waiting.remove(t)!.complete((a, a >= 1 ? '' : answerWhy));
      }
    }
    if (which & 7 != 0) listener?.call(document: which & 1 != 0, moment: which & 2 != 0, cache: which & 4 != 0);
  }

  /// A change the window waited for (docs/internal/reports/window/bridge_rework_2026-10-24.md C3, going): its pictures taken at once, as the inside made them
  /// before it answered.
  T _took<T>(T answer) {
    _take(3);
    return answer;
  }

  T _with<T>(List<String> words, T Function(List<_S>) call) =>
      using((a) => call([for (final w in words) w.toNativeUtf8(allocator: a)])); // (package:ffi's Arena: all let go when the call is done)

  void close() {
    _addListener(_m, nullptr);
    _listenerCallable?.close();
    _close(_m);
  }
}

/// How a value is shown to a hand (Motolii.shown): look, unit, plain name, knob span, folded away.
class Shown {
  const Shown(this.look, this.unit, this.label, this.low, this.high, this.fold, {this.open = false});
  final String look, unit, label;
  final double low, high;

  /// The fold it lies in on its card, named by what the fold holds (null: on the card's first row).
  final String? fold;

  /// [low] and [high] are how far its knob goes; more is taken typed (the inside's document/layer_edit.h).
  final bool open;
}
