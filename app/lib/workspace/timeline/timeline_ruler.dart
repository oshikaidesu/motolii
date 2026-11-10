// The ruler's flags: finding, creating, naming and dragging the project's marks.
part of 'timeline.dart';

extension _WsTimelineRuler on _WsTimelineState {
  /// The mark whose flag is under the pointer [p], if any.
  (double, String)? _flagAt(Offset p) {
    if (p.dy < WtM.band + 1 || p.dy > WtM.band + 15) return null;
    final xs = [for (final m in _ws!.marks) _view.x((m.$1 * Ws.fps).round()).roundToDouble()];
    for (final m in _ws!.marks.reversed) {
      final x = _view.x((m.$1 * Ws.fps).round()).roundToDouble();
      if (p.dx >= x - 2 && p.dx <= x + wtFlagRoom(m.$2, x, xs)) return m;
    }
    return null;
  }

  void _rulerDown(Offset p) {
    final v = _view, f = v.frameAt(p.dx);
    _workDrag = null;
    if (_flagAt(p) case final flag?) {
      _markHeld = flag;
      _markTo = (flag.$1 * Ws.fps).round();
      _markGrab = f - flag.$1 * Ws.fps;
      _markOff = false;
      return;
    }
    if (p.dy <= WtM.band + 2) {
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
    _rulerMove(p);
  }

  /// The marks on the ruler, as frame and name. These are the project's named times.
  List<(int, String)> _marksOf(Ws ws) {
    return [
      for (final (at, name) in _ws!.marks)
        if ((at, name) != _markHeld)
          ((at * Ws.fps).round(), name)
        else if (!_markOff)
          // The mark being dragged is drawn where the pointer holds it, and disappears when dragged off the ruler.
          (_markTo, name),
    ];
  }

  /// The marks' colours by frame. The mark being dragged uses the frame where the pointer holds it.
  Map<int, Color> _markColorsOf(Ws ws) => {
    for (final MapEntry(key: at, value: k) in ws.markColors.entries) (_markHeld?.$1 == at ? _markTo : (at * Ws.fps).round()): wsLabelColor(k - 1),
  };

  void _flag(Ws ws, String name, String id) {
    final m = ws.inside!;
    ws.after(m.later('set', layer: int.parse(id), name: name, number: (name == 'solo' ? _isSolo(ws, id) : _isLocked(ws, id)) ? 0 : 1));
  }
}
