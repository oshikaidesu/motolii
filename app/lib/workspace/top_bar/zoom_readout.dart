// The zoom readout in the top bar: drag sideways to change the window zoom.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/number_field.dart';
import 'package:motolii/workspace/state/window_zoom.dart';

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
