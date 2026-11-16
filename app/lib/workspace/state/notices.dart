// The notice (Notices): the one line the window tells the user, how long it stays, and an optional progress fraction.
import 'dart:async' show Timer;

import 'package:flutter/foundation.dart' show VoidCallback;

/// The one line of text the window tells the user, such as why a change was not taken. May also carry a progress
/// fraction from 0 to 1 that the top bar draws as a slim bar under the text (for exports and other long work).
class Notices {
  /// Creates it with no notice shown. [onChanged] is called when the text or the progress changes.
  Notices({required this._onChanged});

  final VoidCallback _onChanged;

  String? _notice;
  double? _progress;
  Timer? _noticeEnds;

  /// What clicking the notice does while it is shown. A time in it is a place to go to, like a YouTube timestamp.
  void Function()? noticeGo;

  /// The text shown, or null for none. Setting another text forgets [noticeGo] and [progress].
  String? get notice => _notice;
  set notice(String? said) {
    if (said == _notice) return;
    _notice = said;
    _progress = null;
    noticeGo = null;
    _noticeEnds?.cancel();
    // Disappears after ten seconds like a Material snackbar, unless it ends in "…" (work still going on).
    if (said != null && !said.endsWith('…')) {
      _noticeEnds = Timer(const Duration(seconds: 10), () => notice = null);
    }
    _onChanged();
  }

  /// The progress fraction from 0 to 1, or null for no bar. The top bar draws a slim bar under [notice] when it is set.
  double? get progress => _progress;
  set progress(double? f) {
    if (f == _progress) return;
    _progress = f;
    _onChanged();
  }

  /// Stops the timer that would clear the notice.
  void dispose() => _noticeEnds?.cancel();
}
