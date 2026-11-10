// Draws the whole window at the window zoom (WindowZoom), so every part scales alike.
import 'package:flutter/widgets.dart';

import 'package:motolii/workspace/state/window_zoom.dart';

/// [child] drawn at [WindowZoom.value].
class WindowZoomed extends StatelessWidget {
  const WindowZoomed({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: WindowZoom.value,
    builder: (context, z, _) => LayoutBuilder(
      builder: (context, box) {
        final mq = MediaQuery.of(context),
            size = Size(box.maxWidth / z, box.maxHeight / z);
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
              // The larger pixel ratio makes the preview render sharply.
              child: MediaQuery(
                data: mq.copyWith(
                  size: size,
                  devicePixelRatio: mq.devicePixelRatio * z,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    ),
  );
}
