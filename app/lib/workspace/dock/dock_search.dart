// Part of dock_widgets.dart: the shelf's search field, and a way for other panels to focus it.
part of 'dock_widgets.dart';

/// The search field at the top of a shelf, with a hint while empty and a clear button once it has text.
class DockSearch extends StatefulWidget {
  const DockSearch({super.key, required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;
  @override
  State<DockSearch> createState() => _DockSearchState();
}

class _DockSearchState extends State<DockSearch> {
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(_r);
    dockSearchAsked.addListener(_asked);
    if (dockSearchAwaited) WidgetsBinding.instance.addPostFrameCallback((_) => _asked());
  }

  void _r() => setState(() {});

  void _asked() {
    if (!mounted) return;
    dockSearchAwaited = false;
    _focus.requestFocus();
    // The press that asked gives the keys back to the panel it came from one frame later (see inspector_panel.dart),
    // so ask again after that frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _focus.requestFocus() : null);
    WidgetsBinding.instance.scheduleFrame();
    widget.controller.selection = TextSelection(baseOffset: 0, extentOffset: widget.controller.text.length);
  }

  @override
  void dispose() {
    dockSearchAsked.removeListener(_asked);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final well = NakedButton(
      enableFeedback: false,
      onPressed: _focus.requestFocus,
      mouseCursor: MouseCursor.defer,
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
            Glyph(DockG.search, size: Shape.z(11), color: _focus.hasFocus ? WsT.accentInk : Grey.g56),
            SizedBox(width: Shape.s(6)),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (c.text.isEmpty)
                    IgnorePointer(
                      child: Text(widget.hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.name(Grey.g56)),
                    ),
                  TextGestures(
                    field: (k) => EditableText(
                      key: k,
                      rendererIgnoresPointer: true,
                      controller: c,
                      focusNode: _focus,
                      style: T.name(Grey.g95),
                      cursorColor: WsT.accent,
                      backgroundCursorColor: Grey.g44,
                      selectionColor: Grey.g38,
                      cursorWidth: 1.5,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            if (c.text.isNotEmpty)
              DockHover(
                onTap: c.clear,
                builder: (context, h) => Glyph(DockG.close, size: Shape.z(10), color: h ? Grey.g95 : Grey.g63),
              ),
          ],
        ),
      ),
    );
    return Padding(padding: EdgeInsets.fromLTRB(WsT.inset, Shape.s(6), WsT.inset, Shape.s(4)), child: well);
  }
}
