import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/widgets.dart';

import 'inspector_parts.dart';
part 'inspector_values.dart';

/// Whether the next text-content field should take keyboard focus with all its text selected.
/// The preview sets it when it places a new text, so that typing replaces the text at once.
/// AbsentMotion's addText opens its EditText panel, and Figma's text tool types where the text was placed.
bool textToType = false;

enum KeyS { off, anim, at }

enum Kind { shape, text, camera, group, none }

/// The inspector's hairline: 12% white.
class Ed {
  const Ed();
  Color get rule => const Color.fromRGBO(255, 255, 255, .12);
}

/// The property that a value belongs to. All values of one property share one key mark.
/// The document's x, y, z belong to position; scale_x to scale_z to scale; rotate_x, rotate_y and rotate to rotation; anchor_x to anchor_z to anchor.
String propOf(String id) => _place.hasMatch(id) ? 'v_position' : _axis.firstMatch(id)?.group(1) ?? id;
// Compiled once because propOf runs hundreds of times for every frame.
final _place = RegExp(r'^v_[xyz]$'), _axis = RegExp(r'^(v_\w+?)_[xyz]$');
