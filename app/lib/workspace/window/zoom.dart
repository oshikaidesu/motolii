// Zooms the whole window in 1% steps, like Ableton's Zoom Display or a browser's Cmd+ and Cmd-.
//
// The content is laid out in a box 1/zoom the size of the window and drawn zoom times larger. Every part scales alike,
// stays sharp because Flutter draws vectors, and receives pointer input where it is drawn.
// The preview is told the real pixel ratio so it renders sharply.
// The zoom is saved in ~/.motolii/window.xml, beside the skin setting.
import 'package:flutter/widgets.dart';

import '../../skin/tokens.dart';
import 'settings_file.dart';
import '../../widgets/number_field.dart';

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

/// The zoom readout in the top bar.
///
/// Dragging sideways changes the zoom by 1% per 3 px and saves it when the drag ends. Double-clicking resets it to [WsZoom.usual].
class WsZoomReadout extends StatefulWidget {
  const WsZoomReadout({super.key});
  @override
  State<WsZoomReadout> createState() => _WsZoomReadoutState();
}

class _WsZoomReadoutState extends State<WsZoomReadout> {
  // True while the user is dragging. The zoom is saved once, when the drag ends.
  bool _held = false;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: WsZoom.value,
    builder: (context, z, _) => NumberField(
      key: const ValueKey('ws-zoom'),
      value: () => WsZoom.value.value * 100,
      text: (v, _) => '${v.round()}%',
      style: T.micro(z == WsZoom.usual ? Grey.g56 : Grey.g91),
      perPx: 1 / 3,
      typeOnTap: false,
      onGrab: () => _held = true,
      onChange: (v) => WsZoom.set(v / 100, keep: !_held),
      onDrop: () {
        _held = false;
        WsZoom.set(WsZoom.value.value);
      },
      onReset: () => WsZoom.set(WsZoom.usual),
      paint: (_, shown, _) => Padding(
        padding: EdgeInsets.symmetric(horizontal: Shape.s(4), vertical: Shape.s(4)),
        child: shown,
      ),
    ),
  );
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
