// The window zoom factor: zooms the whole window in 1% steps, like Ableton's Zoom Display or a browser's Cmd+ and Cmd-.
//
// The zoom is saved in ~/.motolii/window.xml, beside the skin setting.
import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:motolii/storage/window_settings.dart' show WindowFile;

/// The window zoom factor.
abstract final class WsZoom {
  /// The zoom a window opens at and a double-click returns to. At 100% the parts looked too large.
  static const usual = .88;

  static final value = ValueNotifier<double>((double.tryParse(WindowFile.get('Zoom') ?? '') ?? usual).clamp(.5, 2.0));

  /// Sets the zoom, rounded to the nearest 1% and limited to 50% to 200%. Unless [keep] is false, it is also saved for the next run.
  static void set(double z, {bool keep = true}) {
    value.value = ((z * 100).round() / 100).clamp(.5, 2.0);
    if (keep) WindowFile.set('Zoom', value.value.toStringAsFixed(2));
  }
}
