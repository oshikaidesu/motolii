// The whole window drawn larger or smaller (Ableton's Zoom Display, a browser's ⌘+ / ⌘−): laid out in a box
// 1/zoom the window's size and drawn zoom times larger, so every part grows alike and stays sharp (Flutter's Transform.scale).
// Kept in ~/.motolii/window.xml, beside the theme.
import 'package:flutter/widgets.dart';

import 'settings_file.dart';

abstract final class WsZoom {
  /// The zoom a window opens at: at 100% the parts read too large (user, 2026-10-20).
  static const usual = .88;

  static final value = (double.tryParse(WindowFile.get('Zoom') ?? '') ?? usual).clamp(.5, 2.0);
}

/// [child] drawn at [WsZoom.value].
class WsZoomed extends StatelessWidget {
  const WsZoomed({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final z = WsZoom.value;
    return LayoutBuilder(
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
    );
  }
}
