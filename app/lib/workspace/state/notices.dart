// The notice (Notices): the one line the window tells the user, and how long it stays.
import 'dart:async' show Timer;

import 'package:flutter/foundation.dart' show VoidCallback;

/// The one line of text the window tells the user, such as why a change was not taken.
class Notices {
  /// Creates it with no notice shown. [onChanged] is called when the text changes.
  Notices({required this._onChanged});

  final VoidCallback _onChanged;

  String? _notice;
  Timer? _noticeEnds;

  /// What clicking the notice does while it is shown. A time in it is a place to go to, like a YouTube timestamp.
  void Function()? noticeGo;

  /// The text shown, or null for none. Setting another text forgets [noticeGo].
  String? get notice => _notice;
  set notice(String? said) {
    if (said == _notice) return;
    _notice = said;
    noticeGo = null;
    _noticeEnds?.cancel();
    // Disappears after ten seconds like a Material snackbar, unless it ends in "…" (work still going on).
    if (said != null && !said.endsWith('…')) {
      _noticeEnds = Timer(const Duration(seconds: 10), () => notice = null);
    }
    _onChanged();
  }

  /// Stops the timer that would clear the notice.
  void dispose() => _noticeEnds?.cancel();
}
