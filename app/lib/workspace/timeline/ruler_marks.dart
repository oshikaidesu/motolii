// The ruler's marks and what a drag on the ruler does: it scrubs the playhead, moves the work area, or moves a marker.
//
// The project's markers work like Ableton Live's locators. A marker can be dragged by its flag and keeps its name;
// dragging it off the ruler, up or down, deletes it. Each of these is one undo step.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/workspace/commands/panel_requests.dart'
    show selectedMarker;
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/frame_snap.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';

/// The work area and the markers as the ruler draws them, and the drag in hand on the ruler.
///
/// It notifies its listeners when a drag changes what the ruler draws.
class RulerMarks extends ChangeNotifier {
  /// The marks of the workspace that `workspaceOf` returns, laid out by `viewport`.
  ///
  /// `snapTo` gives the snapping to a set of frames, or null while snapping is off.
  RulerMarks({
    required this._workspaceOf,
    required this._viewport,
    required this._snapTo,
  });

  final WorkspaceController? Function() _workspaceOf;
  final TimelineViewport _viewport;
  final FrameSnap? Function(Set<int> stops) _snapTo;

  /// The workspace the timeline is shown in, read each time it is needed.
  WorkspaceController? get workspace => _workspaceOf();

  /// The first frame of the work area as the ruler draws it. It follows the pointer while the work area is dragged.
  int get workIn => _workIn;
  int _workIn = 12;

  /// The frame where the work area ends, as the ruler draws it.
  int get workOut => _workOut;
  int _workOut = 228;

  int? _workDrag; // 0 in, 1 out, 2 both, null scrub
  double _workGrab = 0;

  (double, String)? _markHeld;
  int _markTo = 0;
  // Where on its flag the marker was grabbed, in frames.
  // It is kept during the drag, as Live does for locators (6.4) and as _workGrab does for the work area.
  // Without it the marker jumped to the pointer, and one grabbed by the end of its name moved 0.47 s.
  double _markGrab = 0;
  bool _markOff = false;

  /// Takes the project's work area, unless it is being dragged. Called while the timeline is built, so it does not
  /// notify.
  void takeWorkArea() {
    if (_workDrag == null) {
      final (from, to) = workspace!.work;
      _workIn = (from * WorkspaceController.fps).round();
      _workOut = (to * WorkspaceController.fps).round();
    }
  }

  /// The marker whose flag is under the pointer [p], if any.
  (double, String)? flagAt(Offset p) {
    if (p.dy < TimelineMetrics.band + 1 || p.dy > TimelineMetrics.band + 15) {
      return null;
    }
    final view = _viewport.view;
    final xs = [
      for (final m in workspace!.marks)
        view.x((m.$1 * WorkspaceController.fps).round()).roundToDouble(),
    ];
    for (final m in workspace!.marks.reversed) {
      final x = view
          .x((m.$1 * WorkspaceController.fps).round())
          .roundToDouble();
      if (p.dx >= x - 2 && p.dx <= x + markerFlagRoom(m.$2, x, xs)) return m;
    }
    return null;
  }

  /// A press on the ruler at [p]: picks up the marker, the end of the work area or the work area under it, or else
  /// moves the playhead there.
  void down(Offset p) {
    final v = _viewport.view, f = v.frameAt(p.dx);
    _workDrag = null;
    if (flagAt(p) case final flag?) {
      _markHeld = flag;
      _markTo = (flag.$1 * WorkspaceController.fps).round();
      _markGrab = f - flag.$1 * WorkspaceController.fps;
      _markOff = false;
      return;
    }
    if (p.dy <= TimelineMetrics.band + 2) {
      final a = v.x(_workIn), b = v.x(_workOut);
      if ((p.dx - a).abs() <= 6) {
        _workDrag = 0;
      } else if ((p.dx - b).abs() <= 6) {
        _workDrag = 1;
      } else if (p.dx > a && p.dx < b) {
        _workDrag = 2;
        _workGrab = f - _workIn;
      }
    }
    move(p);
  }

  /// The pointer moved to [p] during a drag on the ruler.
  void move(Offset p) {
    final f = _viewport.view.frameAt(p.dx).round();
    if (_markHeld != null) {
      _markTo = (_viewport.view.frameAt(p.dx) - _markGrab).round().clamp(
        0,
        WorkspaceController.duration,
      );
      // Dragged off the ruler: the marker is deleted on release.
      _markOff =
          p.dy < -TimelineMetrics.ruler * .6 ||
          p.dy > TimelineMetrics.ruler * 1.6;
      notifyListeners();
      return;
    }
    switch (_workDrag) {
      case 0:
        // The work area is at least half a second long, so it cannot be dragged out of sight.
        _workIn = f.clamp(0, _workOut - WorkspaceController.fps ~/ 2);
        notifyListeners();
      case 1:
        _workOut = f.clamp(
          _workIn + WorkspaceController.fps ~/ 2,
          WorkspaceController.duration,
        );
        notifyListeners();
      case 2:
        final len = _workOut - _workIn,
            a = (_viewport.view.frameAt(p.dx) - _workGrab).round().clamp(
              0,
              WorkspaceController.duration - len,
            );
        _workIn = a;
        _workOut = a + len;
        notifyListeners();
      default:
        // As in After Effects, holding Shift while dragging the time indicator snaps it to what it passes.
        final shift = HardwareKeyboard.instance.isShiftPressed;
        workspace!.frame = shift
            ? _snapTo(workspace!.stops())?.nearest(f) ?? f
            : f;
    }
  }

  /// Ends a drag on the ruler. The work area becomes the project's on release, as one undo step.
  void end() {
    final m = workspace?.inside;
    if (_markHeld case (final at, final name)?) {
      _markHeld = null;
      final to = _markTo / WorkspaceController.fps;
      if (_markOff) {
        workspace!.after(m!.later('mark', number: at));
      } else if ((to - at).abs() >= 0.5 / WorkspaceController.fps) {
        // Moved: one undo step, and the name is kept.
        m!.later('together', number: 1);
        m.later('mark', number: at);
        m.later('mark', number: to, word: name);
        // The colour moves with the marker.
        if (workspace!.markColors[at] case final k?) {
          m.later('mark_colour', number: to, word: '$k');
        }
        workspace!.after(m.later('together'));
      } else {
        // Released where it was grabbed, so a small shake is not a drag. Treated as a click on the marker.
        selectedMarker.value = (at, name);
        workspace!
          ..playing = false
          ..frame = _markTo;
      }
      notifyListeners();
      return;
    }
    if (_workDrag != null) {
      workspace!.after(
        m!.later(
          'work',
          number: _workIn / WorkspaceController.fps,
          word: '${_workOut / WorkspaceController.fps}',
        ),
      );
    }
    _workDrag = null;
  }

  /// The markers on the ruler, as frame and name. These are the project's named times.
  List<(int, String)> get markers {
    return [
      for (final (at, name) in workspace!.marks)
        if ((at, name) != _markHeld)
          ((at * WorkspaceController.fps).round(), name)
        else if (!_markOff)
          // The marker being dragged is drawn where the pointer holds it, and disappears when dragged off the ruler.
          (_markTo, name),
    ];
  }

  /// The markers' colours by frame. The marker being dragged uses the frame where the pointer holds it.
  Map<int, Color> get markerColors => {
    for (final MapEntry(key: at, value: k) in workspace!.markColors.entries)
      (_markHeld?.$1 == at ? _markTo : (at * WorkspaceController.fps).round()):
          labelColor(k - 1),
  };

  /// Frames where the selected group's intro ends and its outro starts, for marking on the ruler.
  ///
  /// They are the End of intro and Start of outro values of the group's Element card (the engine's doc_element_clock).
  List<int> get retimed {
    final ws = workspace!;
    final m = ws.inside, t = int.tryParse(ws.selected ?? '');
    if (m == null || t == null) return const [];
    final start = m.value(t, 'start', 0) ?? 0;
    return [
      for (final n in const ['retime_in', 'retime_out'])
        if ((m.value(t, n, 0) ?? 0) > 0)
          ((start + m.value(t, n, 0)!) * WorkspaceController.fps).round(),
    ];
  }
}
