// Calls that change the document or the preview.
import 'dart:ffi';

import 'package:flutter/foundation.dart' show setEquals;

import 'package:ffi/ffi.dart';

import 'package:motolii/bridge/motolii.dart';

extension MotoliiWrites on Motolii {
  /// Renders the preview pane. [w] of 0 turns it off.
  int desk(int w, int h, double x, double y, double scale, double point) =>
      later('desk', word: '$w $h $x $y $scale $point');

  /// Tells the engine which layer is selected and hovered (0 = none).
  void pick(int layer, int hover) =>
      later('pick', layer: layer, number: hover.toDouble());

  /// Subscribes to the animated values of [layers]. Only re-sent when the set changes.
  void subscribe(Set<int> layers) {
    if (setEquals(layers, watched)) return;
    watched = layers;
    later('watch', word: layers.join(' '));
  }

  /// Writes the current preview as a PNG.
  bool still(String png) =>
      withStrings([png], (s) => bindings.motolii_still(handle, s[0])) != 0;

  /// Stores a poster frame in the project and writes it to [png].
  bool poster(String png) =>
      withStrings([png], (s) => bindings.motolii_poster(handle, s[0])) != 0;

  /// Copies the project and its media into [folder]. Returns file count, or -1 on failure.
  int pack(String folder, String name) => withStrings([
    folder,
    name,
  ], (s) => bindings.motolii_pack(handle, s[0], s[1]));

  bool play(bool on) => bindings.motolii_play(handle, on ? 1 : 0) != 0;

  bool at(double seconds) => bindings.motolii_at(handle, seconds) != 0;

  /// Evaluates an arithmetic expression. Returns null if invalid.
  double? workOut(String sum) => withStrings([sum], (s) {
    final out = malloc<Double>();
    try {
      return bindings.motolii_work_out(handle, s[0], out) != 0
          ? out.value
          : null;
    } finally {
      malloc.free(out);
    }
  });

  /// Adds a layer. Returns its number, or 0 on failure.
  int add(String kind, String file) => tookSnapshots(
    withStrings([kind, file], (s) => bindings.motolii_add(handle, s[0], s[1])),
  );

  bool remove(int layer) =>
      tookSnapshots(bindings.motolii_remove(handle, layer) != 0);

  bool set(int layer, String name, double number) => tookSnapshots(
    withStrings([
          name,
        ], (s) => bindings.motolii_set(handle, layer, s[0], number)) !=
        0,
  );

  bool say(int layer, String name, String word) => tookSnapshots(
    withStrings([
          name,
          word,
        ], (s) => bindings.motolii_say(handle, layer, s[0], s[1])) !=
        0,
  );

  bool key(int layer, String name, double at, double number) => tookSnapshots(
    withStrings([
          name,
        ], (s) => bindings.motolii_key(handle, layer, s[0], at, number)) !=
        0,
  );

  /// While on, every changed value gets a keyframe at the current time.
  void keying(bool on) => bindings.motolii_keying(handle, on ? 1 : 0);

  bool get keyingNow => bindings.motolii_keying(handle, -1) != 0;

  /// Starts a drag. The change becomes part of the project only on drag end (one undo step).
  void take(int layer) => later('drag_start', layer: layer);

  /// Updates the drag. [by]: 'place' (canvas delta), 'bar'/'head'/'tail' (time delta), or a property name (new value).
  bool dragUpdate(String by, double a, [double b = 0]) =>
      withStrings([
        by,
      ], (s) => bindings.motolii_drag_update(handle, s[0], a, b)) !=
      0;

  bool get looping => bindings.motolii_loop(handle, -1) != 0;

  set looping(bool on) => bindings.motolii_loop(handle, on ? 1 : 0);

  /// Runs a recipe script as one undo step. Returns the new layer, or 0.
  int create(String script) => tookSnapshots(
    withStrings([script], (s) => bindings.motolii_create(handle, s[0])),
  );

  /// Groups [changes] into one undo step.
  T together<T>(T Function() changes) {
    bindings.motolii_together(handle, 1);
    try {
      return changes();
    } finally {
      bindings.motolii_together(handle, 0);
    }
  }

  /// Queues a change for the render thread. Returns a ticket; calls run in order.
  int later(
    String call, {
    int layer = 0,
    String name = '',
    String word = '',
    double number = 0,
  }) => withStrings([
    call,
    name,
    word,
  ], (s) => bindings.motolii_later(handle, s[0], layer, s[1], s[2], number));
}
