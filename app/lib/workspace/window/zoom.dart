// The whole window drawn larger or smaller in 1% steps (Ableton's Zoom Display, a browser's ⌘+ / ⌘−): laid out in a box
// 1/zoom the window's size and drawn zoom times larger, so every part grows alike, stays sharp (Flutter draws vectors) and
// takes the hand where it is drawn; the stage is told the finer pixels. Kept in ~/.motolii/window.xml, beside the theme.
import 'package:flutter/widgets.dart';

import '../../skin/tokens.dart';
import 'settings_file.dart';
import '../../widgets/number_field.dart';

abstract final class WsZoom {
  /// The zoom a window opens at and a double tap returns to: at 100% the parts read too large (user, 2026-10-20).
  static const usual = .88;

  static final value = ValueNotifier<double>((double.tryParse(WindowFile.get('Zoom') ?? '') ?? usual).clamp(.5, 2.0));

  /// The zoom set (to the nearest 1%, 50% to 200%) and, unless [keep] is false, kept for the next time.
  static void set(double z, {bool keep = true}) {
    value.value = ((z * 100).round() / 100).clamp(.5, 2.0);
    if (keep) WindowFile.set('Zoom', value.value.toStringAsFixed(2));
  }
}

/// The zoom in the top bar, quiet: scrubbed sideways it moves 1% every 3 px (kept when let go), tapped twice it is the usual zoom again.
class WsZoomReadout extends StatefulWidget {
  const WsZoomReadout({super.key});
  @override
  State<WsZoomReadout> createState() => _WsZoomReadoutState();
}

class _WsZoomReadoutState extends State<WsZoomReadout> {
  bool _held = false; // (a hand dragging it: the zoom is kept once, when it lets go)
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
              child: MediaQuery(
                data: mq.copyWith(size: size, devicePixelRatio: mq.devicePixelRatio * z),
                child: child,
              ), // (finer pixels: the stage renders sharp)
            ),
          ),
        );
      },
    ),
  );
}
