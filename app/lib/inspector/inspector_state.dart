import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/widgets.dart';

import '../skin/tokens.dart';
import 'inspector_parts.dart';
part 'inspector_values.dart';

enum KeyS { off, anim, at }

enum Kind { shape, text, camera, group, none }

/// The inspector's type: a 12% hairline, and a rule above a group.
class Ed {
  const Ed();
  double get hair => .12;
  Color get rule => Color.fromRGBO(255, 255, 255, hair);

  String lab(String s) => s;
  TextStyle labStyle(Color c) => T.label(c);
}

/// The property a value is part of, whose key mark is theirs together: a document's x, y, z are its position; its
/// scale_x .. scale_z its scale, rotate_x, rotate_y and rotate its rotation, anchor_x .. anchor_z its anchor.
String propOf(String id) => _place.hasMatch(id) ? 'v_position' : _axis.firstMatch(id)?.group(1) ?? id;
final _place = RegExp(r'^v_[xyz]$'), _axis = RegExp(r'^(v_\w+?)_[xyz]$'); // (made once: asked hundreds of times a picture)
