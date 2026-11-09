// Part of dock_parts.dart: the shelf's search well, and the search asked for from elsewhere.
part of 'dock_parts.dart';

/// The search well under the header: magnifier, editable text, clear.
/// The shelf's search asked for from elsewhere (the Inspector's Add Effect): the field in sight takes the keys, or the
/// next one to come.
final _searchAsked = ValueNotifier(0);
bool _searchAwaited = false;
void askDockSearch() {
  _searchAwaited = true;
  _searchAsked.value++;
}

class DockSearch extends StatefulWidget {
  const DockSearch({super.key, required this.controller, required this.hint, this.trailing});
  final TextEditingController controller;
  final String hint;

  /// Sits beside the well, e.g. the filter toggle.
  final Widget? trailing;
  @override
  State<DockSearch> createState() => _DockSearchState();
}

class _DockSearchState extends State<DockSearch> {
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(_r);
    _searchAsked.addListener(_asked);
    if (_searchAwaited) WidgetsBinding.instance.addPostFrameCallback((_) => _asked());
  }

  void _r() => setState(() {});

  void _asked() {
    if (!mounted) return;
    _searchAwaited = false;
    _focus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _focus.requestFocus() : null);   // (the press that asked gives the panel it came from the keys, a frame on: inspector_panel.dart)
    WidgetsBinding.instance.scheduleFrame();
    widget.controller.selection = TextSelection(baseOffset: 0, extentOffset: widget.controller.text.length);
  }

  @override
  void dispose() {
    _searchAsked.removeListener(_asked);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final well = GestureDetector(
      onTap: _focus.requestFocus,
      child: AnimatedContainer(
        duration: Mo.dur,
        curve: Mo.ease,
        height: Shape.z(24),
        padding: EdgeInsets.symmetric(horizontal: Shape.s(7)),
        decoration: BoxDecoration(
          color: WsT.well,
          borderRadius: BorderRadius.all(Shape.r(WsT.radius)),
          border: Border.all(color: _focus.hasFocus ? WsT.accentInk : WsT.well),
        ),
        child: Row(
          children: [
            DockGlyph(DockG.search, size: Shape.z(11), color: _focus.hasFocus ? WsT.accentInk : Grey.g56),
            SizedBox(width: Shape.s(6)),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (c.text.isEmpty)
                    IgnorePointer(
                      child: Text(widget.hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.name(Grey.g56)),
                    ),
                  TextHand(field: (k) => EditableText(key: k, rendererIgnoresPointer: true,
                    controller: c,
                    focusNode: _focus,
                    style: T.name(Grey.g95),
                    cursorColor: WsT.accent,
                    backgroundCursorColor: Grey.g44,
                    selectionColor: Grey.g38,
                    cursorWidth: 1.5,
                    maxLines: 1,
                  )),
                ],
              ),
            ),
            if (c.text.isNotEmpty)
              DockHover(
                onTap: c.clear,
                builder: (context, h) => DockGlyph(DockG.close, size: Shape.z(10), color: h ? Grey.g95 : Grey.g63),
              ),
          ],
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(WsT.inset, Shape.s(6), WsT.inset, Shape.s(4)),
      child: Row(
        children: [
          Expanded(child: well),
          if (widget.trailing case final t?) ...[SizedBox(width: WsT.gap), t],
        ],
      ),
    );
  }
}
