// Calls that change the document or the preview (docs/app/BRIDGE.md, section W).
// Each is either queued without waiting for the engine, or done in one synchronous call.
// Covers dragging, keyframes, easing and undo.
import 'dart:ffi';

import 'package:flutter/foundation.dart' show setEquals;

import 'package:ffi/ffi.dart';

import 'package:motolii/bridge/motolii.dart';

extension MotoliiWrites on Motolii {
  /// Asks the engine to render the whole preview pane, [w] x [h] pixels.
  ///
  /// The canvas sits at [x], [y] (its top left) at [scale] pixels per point, and whatever lies outside it is drawn
  /// around it. The selected layer is marked on top. [point] is the number of screen pixels per point.
  /// A [w] of 0 turns this off and goes back to the canvas's own frame.
  /// Queued with [later]. The returned ticket tells [answer] when the frame exists.
  int desk(int w, int h, double x, double y, double scale, double point) =>
      later('desk', word: '$w $h $x $y $scale $point');

  /// Tells the engine which layer is selected and which is under the pointer (0 for none) so the preview marks them.
  /// Queued with [later].
  void pick(int layer, int hover) =>
      later('pick', layer: layer, number: hover.toDouble());

  /// Subscribes to the animated values of [layers].
  ///
  /// Their values are included in the snapshot from the next frame on. Queued with [later].
  /// The engine is told again only when the set changes.
  void subscribe(Set<int> layers) {
    if (setEquals(layers, watched)) return;
    watched = layers;
    later('watch', word: layers.join(' '));
  }

  /// Writes the current preview as a PNG to [png], for callers that can only look at images.
  bool still(String png) =>
      withStrings([png], (s) => bindings.motolii_still(handle, s[0])) != 0;

  /// Renders a small poster frame (at the project's poster_at time, otherwise the current time).
  ///
  /// It is stored in the project with its size and length, so a project list can show it without opening the
  /// project (see docFactsOf). The image is also written to [png].
  bool poster(String png) =>
      withStrings([png], (s) => bindings.motolii_poster(handle, s[0])) != 0;

  /// Copies the project (as [name].motolii) and every file its layers use into [folder], so it can be moved as a whole.
  ///
  /// Returns the number of files copied, or -1 on failure.
  int pack(String folder, String name) => withStrings([
    folder,
    name,
  ], (s) => bindings.motolii_pack(handle, s[0], s[1]));

  bool play(bool on) => bindings.motolii_play(handle, on ? 1 : 0) != 0;

  bool at(double seconds) => bindings.motolii_at(handle, seconds) != 0;

  /// Evaluates an expression typed into a number field (+ - * / and parentheses).
  ///
  /// SQLite evaluates it, as it does for easing expressions. Returns null if [sum] is not a valid expression.
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

  /// Adds a layer of [kind] (video, image, text or solid) from [file].
  ///
  /// For a solid, [file] is a model file, or one of ring, gem or cube. Its material is its `fill` property: a color or `glass`.
  /// Returns the new layer's number, or 0 if it was not created.
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

  /// Turns "animate all" on or off (the inspector's Animate all).
  ///
  /// While on, every value the user changes or drags gets a keyframe at the current time.
  void keying(bool on) => bindings.motolii_keying(handle, on ? 1 : 0);

  /// Whether "animate all" is on.
  bool get keyingNow => bindings.motolii_keying(handle, -1) != 0;

  /// Starts a drag on [layer] without waiting for the engine (see motolii.h).
  ///
  /// If the engine refuses, the matching drag end reports why. Every drag (on the canvas, a timeline bar or a value)
  /// has the same three steps: start, update, end. What is dragged shows at once, but it only becomes part of the
  /// project when the drag ends, as one undo step.
  void take(int layer) => later('drag_start', layer: layer);

  /// Updates the current drag. [by] says what is dragged.
  ///
  /// - 'place': a layer on the canvas. [a] and [b] are how far the pointer has moved, in points of the frame.
  /// - 'bar', 'head' or 'tail': a layer's bar on the timeline. [a] is the change in seconds.
  /// - Any other string is a property name and [a] is its new value.
  ///
  /// Sent without waiting. The result appears in the next snapshot.
  bool dragUpdate(String by, double a, [double b = 0]) =>
      withStrings([
        by,
      ], (s) => bindings.motolii_drag_update(handle, s[0], a, b)) !=
      0;

  /// Whether playback loops over the work area instead of stopping at its end.
  bool get looping => bindings.motolii_loop(handle, -1) != 0;

  set looping(bool on) => bindings.motolii_loop(handle, on ? 1 : 0);

  /// Runs a recipe script at the current time as one undo step.
  ///
  /// Returns the new layer's number, or 0 if nothing was created. [trouble] then gives the reason.
  int create(String script) => tookSnapshots(
    withStrings([script], (s) => bindings.motolii_create(handle, s[0])),
  );

  /// Runs [changes] so that everything they do becomes one undo step.
  T together<T>(T Function() changes) {
    bindings.motolii_together(handle, 1);
    try {
      return changes();
    } finally {
      bindings.motolii_together(handle, 0);
    }
  }

  /// Queues a change for the engine's render thread without waiting for it.
  ///
  /// Used for say, set, drag end, undo, redo and together. Calls run in the order queued.
  /// Returns a ticket at once. [answer] reports when the call has finished.
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
