// The composition's settings (CompositionSettings): its frame rate, its length and its size.
import 'dart:ui' show Size;

/// The composition's frame rate, length and size.
///
/// They start at a sample's values and are read from the document when one is opened.
class CompositionSettings {
  /// How many frames there are in a second.
  int frameRate = 30;

  /// The composition's length in frames.
  int duration = 240;

  /// The composition's size in pixels.
  Size size = const Size(1920, 1080);
}
