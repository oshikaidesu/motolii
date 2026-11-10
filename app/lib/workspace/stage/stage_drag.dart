// A drag on the stage: what the pointer holds while it is down.
import 'dart:ui' show Offset;

/// What the pointer holds during a drag on the stage.
///
/// `from` is where the pointer went down and `moved` whether it has moved since. `by` names the handle that was
/// taken (scale, turn, pivot and so on); null means the layer itself, moved as a whole.
typedef StageHold = ({Offset from, bool moved, String? by});

/// The drag in progress on the stage.
class StageDrag {
  /// What the pointer holds, or null when no drag is in progress.
  ///
  /// The stage reports only how far the pointer moved, in composition pixels. The engine decides what that means
  /// for the layer and for the project.
  StageHold? held;
}
