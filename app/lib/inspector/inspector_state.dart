import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../skin/tokens.dart';
import 'inspector_parts.dart';
part 'inspector_values.dart';

/// Said by the stage as it places a text: the words field next built for it holds the keys, its words all picked, so
/// what is typed at once is the text's (AbsentMotion's addText opens its EditText panel; Figma's text tool types where
/// it was placed).
bool textToType = false;

enum ModRule { shiftBig, shiftFine }

enum ResetRule { dbl, del, arrow, both, live } // (live: Ableton Live's, Delete or double-click: its manual 42.4, 42.6)

enum KeyS { off, anim, at }

enum Kind { shape, text, camera, group, several, none }

class Cfg {
  const Cfg({this.mod = ModRule.shiftBig, this.rightUp = true, this.reset = ResetRule.dbl, this.tabs = true, this.maybe = false, this.locked = false});
  final ModRule mod;
  final bool rightUp, tabs, maybe, locked;
  final ResetRule reset;

  bool get resetDbl => reset == ResetRule.dbl || reset == ResetRule.both || reset == ResetRule.live;
  bool get resetDel => reset == ResetRule.del || reset == ResetRule.live;
  bool get typesOn => reset == ResetRule.live; // (a digit typed on a field starts its number: Live 42.6 "Type In Value 0…9")
  bool get resetArrow => reset == ResetRule.arrow || reset == ResetRule.both;

  /// One rule for scrub, wheel and arrows (C4): the same keys mean the same thing in every control.
  double mult() {
    final k = HardwareKeyboard.instance;
    if (mod == ModRule.shiftBig) {
      if (k.isShiftPressed) return 10;
      if (k.isAltPressed) return .1;
    } else {
      if (k.isShiftPressed) return .1;
      if (k.isMetaPressed || k.isControlPressed) return 10; // (Cmd on a Mac, Ctrl elsewhere, one key: Live's manual pairs them, as the timeline's zoom does)
    }
    return 1;
  }

  String get modWords => mod == ModRule.shiftBig ? 'Shift x10 · Alt fine' : 'Shift fine · Ctrl x10';
}

/// The inspector's type: a 12% hairline, caps on headings, and a rule above a group.
class Ed {
  const Ed();
  double get hair => .12;
  Color get rule => Color.fromRGBO(255, 255, 255, hair);
  double get row => 24;
  double get gap => 12;

  String head(String s) => s.toUpperCase();
  String lab(String s) => s;
  String kick(String s) => s.toUpperCase();
  TextStyle kickStyle(Color c) => T.micro(c).copyWith(letterSpacing: .8);
  TextStyle subStyle() => T.name(Grey.g91);
  TextStyle headStyle() => T.micro(Grey.g56).copyWith(letterSpacing: 1.0);
  TextStyle labStyle(Color c) => T.label(c);
  TextStyle nameStyle() => T.title().copyWith(fontSize: T.px(14), fontWeight: FontWeight.w500);
}

/// The property a value is part of, whose key mark is theirs together: a document's x, y, z are its position; its
/// scale_x .. scale_z its scale, rotate_x, rotate_y and rotate its rotation, anchor_x .. anchor_z its anchor.
String propOf(String id) => _place.hasMatch(id) ? 'v_position' : _axis.firstMatch(id)?.group(1) ?? id;
final _place = RegExp(r'^v_[xyz]$'), _axis = RegExp(r'^(v_\w+?)_[xyz]$'); // (made once: asked hundreds of times a picture)
