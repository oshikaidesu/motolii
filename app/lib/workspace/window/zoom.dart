// Draws the whole window at the window zoom (WsZoom), so every part scales alike.
import 'package:flutter/widgets.dart';

import 'package:motolii/workspace/state/window_zoom.dart';

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
              // The larger pixel ratio makes the preview render sharply.
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
