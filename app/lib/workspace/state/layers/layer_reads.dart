// Reads of one layer from the engine's snapshot (layer 0 is the stage): its properties, keyframes, how it is shown and
// where it is on the canvas. Each returns a plain value. Not connected means the engine's own empty answer.
import 'dart:ui' show Rect;

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// How a property is shown to the user: its label and unit, and the range of its slider.
typedef PropertyLook = ({String label, String unit, double low, double high});

/// A property's label, unit and slider range, or null when the engine has none for it (or is not connected).
PropertyLook? propertyLook(WorkspaceController ws, String name) {
  final s = ws.inside?.shown(name);
  return s == null
      ? null
      : (label: s.label, unit: s.unit, low: s.low, high: s.high);
}

/// A layer's string property by name (kind, file, shape, blend, text, fill). Empty if it has none.
String layerWord(WorkspaceController ws, int layer, String name) =>
    ws.inside?.word(layer, name) ?? '';

/// The strings a layer's property may take, such as blend modes. Empty if any string is allowed.
List<String> layerWords(WorkspaceController ws, int layer, String name) =>
    ws.inside?.words(layer, name) ?? const [];

/// A property's own value at [at]. Null if the engine has none.
double? layerValue(WorkspaceController ws, int layer, String name, double at) =>
    ws.inside?.value(layer, name, at);

/// The names of a layer's properties that can have keyframes.
List<String> layerMoving(WorkspaceController ws, int layer) =>
    ws.inside?.moving(layer) ?? const [];

/// The times of a property's keyframes, in seconds. Empty if it has none.
List<double> layerKeyTimes(WorkspaceController ws, int layer, String name) =>
    ws.inside?.keyTimes(layer, name) ?? const [];

/// The value of each keyframe of a property, in the order of [layerKeyTimes].
List<double> layerKeyValues(WorkspaceController ws, int layer, String name) =>
    ws.inside?.keyValues(layer, name) ?? const [];

/// The easing of the span that starts at the property's keyframe at [at], as its word. Empty if there is none.
String layerEasingAt(
  WorkspaceController ws,
  int layer,
  String name,
  double at,
) => ws.inside?.easingOf(layer, name, at) ?? '';

/// How a stored number converts to the shown one: shown = value * scale + offset, as (scale, offset).
(double, double) layerReading(WorkspaceController ws, int layer, String name) =>
    ws.inside?.reading(layer, name) ?? (1.0, 0.0);

/// A layer's box on the canvas at the stage's time: centre x, y, width, height, rotation, rotation anchor x, y and depth.
/// Null if it is not shown.
List<double>? layerBounds(WorkspaceController ws, int layer) =>
    ws.inside?.bounds(layer);

/// The box around a layer's visible outline, in canvas points from the top left. Null if it is not shown.
Rect? layerSeen(WorkspaceController ws, int layer) => ws.inside?.seen(layer);
