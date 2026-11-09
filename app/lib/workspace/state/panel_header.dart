// Part of state.dart: a panel's header and the panel round it.
part of 'state.dart';

/// A panel: a square tile of [WsT.body] that clips what it holds.
class WsPanel extends StatelessWidget {
  const WsPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRect(
    child: ColoredBox(color: WsT.body, child: child),
  );
}
