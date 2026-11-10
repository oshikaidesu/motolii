import 'package:motolii/inspector/inspector_state.dart';

/// The selected layer's values as their owner has them at one moment.
class InspectorSnapshot {
  /// Creates a snapshot of the values an Inspector is to show.
  const InspectorSnapshot({
    this.numbers = const {},
    this.words = const {},
    this.flags = const {},
    this.keyMarks = const {},
    this.animating = false,
  });

  /// Values the caller owns, such as the layer's transform at this frame. They are written in silently when they change, so edits made here last until then.
  final Map<String, double> numbers;

  /// The strings the caller owns, such as a text's content or a chooser's choice.
  final Map<String, String> words;

  /// The on/off properties the caller owns, such as Clip to below.
  final Map<String, bool> flags;

  /// The key mark of each property (position, scale, rotation ...) as the caller's document has it.
  final Map<String, KeyframeState> keyMarks;

  /// The caller's own Animate all. It is shown as given and is never reset by a new kind.
  final bool animating;
}
