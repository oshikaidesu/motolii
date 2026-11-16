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
  /// stopping points.
  static const double snapTimeline = 8.0;

  /// `drag.4` A layer on the stage snaps to edges, centres and guides within
  /// this many screen pixels (divided by the view scale when compared to
  /// document distances).
  static const double snapStage = 6.0;

  /// `hover.3` How long a state change takes. One motion with [Motion.dur].
  static Duration get change => Motion.dur;

  /// Section 12 `nudgeShift`: how many units Shift+arrow moves an item or
  /// the time.
  static const int nudgeShift = 10;

  /// Section 12 `coarse`: how much faster Cmd (or Ctrl) makes scrubbing,
  /// wheel and arrow nudges, as in Ableton Live (manual, section 42.6).
  static const double coarse = 10.0;

  /// Section 12 `fine`: how much slower Shift makes the same drags, for
  /// precise control.
  static const double fine = 0.1;

  /// Section 12 `burstRest`: how long the Unified Camera tool's wheel waits
  /// after the last turn before closing the undo step. Also the delay for
  /// other burst-like inputs.
  static const Duration burstRest = Duration(milliseconds: 300);

  /// Section 12 `menuWidth`: a context menu's own width, in design points
  /// (parts wrap this in `Shape.z` to get screen pixels).
  static const double menuWidth = 220.0;

  /// Section 12 `menuRow`: the height of one row in a context menu, in
  /// design points.
  static const double menuRow = 22.0;
}
