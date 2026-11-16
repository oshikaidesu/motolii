// The sizes of the timeline's parts, scaled by the skin.
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/gestures.dart';

/// The timeline panel's own sizes.
abstract final class TimelineMetrics {
  static const divider = 1.0;
  static double get header => Shape.z(32.0);
  static double get label => Shape.z(200.0);

  /// The draggable name-column width is kept between these. The low end is where the header's "# LAYER n" and its
  /// four icons still fit without overflowing; the rows below clip, so only the header sets the floor.
  static double get labelMin => Shape.z(180.0);
  static double get labelMax => Shape.z(420.0);

  /// The width of the divider's grab area between the names and the tracks
  /// (`Gestures.grab`).
  static double get grip => Shape.z(Gestures.grab);
  static double get ruler => Shape.z(30.0);
  static double get row => Shape.z(24.0);
  static double get overview => Shape.z(12.0);

  /// The work-area band on top of the ruler, and the room left of frame 0 / right of the last frame.
  static double get band => Shape.z(12.0);
  static double get padL => Shape.s(10.0);
  static double get padR => Shape.s(14.0);
  static double get bar => Shape.z(18.0);
  static double get key => Shape.z(4.5);
  static double get keyPicked => Shape.z(6.0);
  static double get chip => Shape.z(14.0);
  static const maxZoom = 16.0;
}
