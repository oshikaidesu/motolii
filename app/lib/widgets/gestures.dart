// The numbers of [docs/app/GESTURES.md] section 12, read by every part so the
// document and the code never drift apart (UAT 188–191).
//
// Add a value here instead of writing it in a part. If a part needs a value
// that is not here, add it here first with the same name as in the document.
import 'package:motolii/skin/tokens.dart';

abstract final class Gestures {
  /// `drag.1` A press becomes a drag when the pointer moves this far from
  /// where it went down.
  static const double dragSlop = 4.0;

  /// `drag.3` The nearest item or handle within this distance of a press is
  /// grabbed. Used by the preview's handles and the timeline's keyframes.
  static const double grab = 8.0;

  /// `drag.4` Timeline bars and keyframes stop within this distance of other
  /// stopping points. The stage's `snap` is 6 px on the screen (see
  /// `stage_drag.dart`).
  static const double snapTimeline = 8.0;

  /// `hover.3` How long a state change takes. One motion with [Motion.dur].
  static Duration get change => Motion.dur;
}
