// What the Colors shelf keeps while the window is open.
import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/workspace/dock/colors/saved_colors.dart';

/// What the Colors shelf keeps while the window is open: the color on the picker, the gradient stop it edits, the
/// palette whose details show, the throw of the dice, and the user's saved colors.
class ColorsController {
  /// The color shown on the picker.
  HSVColor wheelColor = const HSVColor.fromAHSV(1, 0, .8, .9);

  /// The property value the picker last followed. The picker takes the target's color again when this differs from it.
  String wheelFrom = '';

  /// True while the user drags the wheel; it then follows the pointer.
  bool wheelHeld = false;

  /// The stop the picker edits.
  int stop = 0;

  /// The palette whose details the shelf footer shows: the one under the pointer, else the one pressed last.
  final paletteShown = ValueNotifier<String?>(null);

  /// The palette of the box pressed last.
  String? palettePressed;

  /// Runs out a moment after the box size slider stops; the size is saved then, not on every frame of the drag.
  Timer? tileKept;

  /// The dice's last throw, which sets the boxes' shapes.
  int dice = 0;

  /// The group of the box under the pointer.
  final hovered = ValueNotifier<String?>(null);

  /// The right-click menu of the boxes.
  final boxMenu = GlobalKey<ContextMenuState>();

  /// The last layout of the boxes, keyed by what it was laid out for.
  (String, List<(int, int, int, int)>)? laid;

  /// The colors, palettes and gradients the user has saved.
  final saved = SavedColors();
}
