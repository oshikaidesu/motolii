// The whole window drawn larger or smaller (Ableton's Zoom Display, a browser's ⌘+ / ⌘−): laid out in a box
// 1/zoom the window's size and drawn zoom times larger, so every part grows alike and stays sharp (Flutter's Transform.scale).
// Kept in ~/.motolii/window.xml, beside the theme.
import 'package:flutter/widgets.dart';

import 'settings_file.dart';

abstract final class WsZoom {
  /// The zoom a window opens at: at 100% the parts read too large (user, 2026-10-20).
  static const usual = .88;

  static final value = ValueNotifier<double>((double.tryParse(WindowFile.get('Zoom') ?? '') ?? usual).clamp(.5, 2.0));

  /// The zoom set (to the nearest 1%, 50% to 200%) and, unless [keep] is false, kept for the next time.
  static void set(double z, {bool keep = true}) {
    value.value = ((z * 100).round() / 100).clamp(.5, 2.0);
    if (keep) WindowFile.set('Zoom', value.value.toStringAsFixed(2));
  }

  static void by(int percent) => set(value.value + percent / 100);
}

/// [child] drawn at [WsZoom.value].
class WsZoomed extends StatelessWidget {
  const WsZoomed({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: WsZoom.value,
    builder: (context, z, _) => LayoutBuilder(
      builder: (context, box) {
        final mq = MediaQuery.of(context), size = Size(box.maxWidth / z, box.maxHeight / z);
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: size.width,
            maxWidth: size.width,
            minHeight: size.height,
            maxHeight: size.height,
            child: Transform.scale(
              scale: z,
              alignment: Alignment.topLeft,
              child: MediaQuery(
                data: mq.copyWith(size: size, devicePixelRatio: mq.devicePixelRatio * z),
                child: child,
              ),
            ),
          ),
        );
      },
    ),
  );
}
