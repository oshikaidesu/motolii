// Part of dock_make.dart (cut there by size, as it was).
part of 'dock_make.dart';

// ---- a recipe's motion: asked of the inside once (create_preview.dart), on a document of its own.
bool _isRecipe(DockCtx c, String name) {
  final m = c.ws.inside;
  if (m == null || !m.recipes.any((r) => r.$1 == name)) return false;
  RecipeMotions.ask(File(m.libPath).parent.parent.path, [for (final r in m.recipes) r.$1]);
  return true;
}

/// The colour's number, typed: After Effects' Color Picker and Figma's both take one, #d4a72c, d4a72c or #da2. Told on Return or on leaving it.
class _HexField extends StatefulWidget {
  const _HexField(this.hex, this.onTold);
  final String hex;
  final ValueChanged<Color> onTold;
  @override
  State<_HexField> createState() => _HexFieldState();
}

class _HexFieldState extends State<_HexField> {
  final _c = TextEditingController();
  final _f = FocusNode(debugLabel: 'colour-hex');

  void _tell() {
    final said = _c.text.trim().replaceFirst('#', ''), whole = said.length == 3 ? [for (final k in said.split('')) '$k$k'].join() : said;
    if (whole.length != 6 || _colourOf(whole) == null || '#${whole.toLowerCase()}' == widget.hex.toLowerCase()) return;
    widget.onTold(_colourOf(whole)!);
  }

  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (!_f.hasFocus) return _tell();
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _c.selection = TextSelection(baseOffset: 0, extentOffset: _c.text.length) : null);
    });
  }

  @override
  void dispose() {
    _f.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_f.hasFocus) _c.text = widget.hex;
    return TextHand(field: (k) => EditableText(key: k, rendererIgnoresPointer: true,
      controller: _c,
      focusNode: _f,
      style: T.value(Grey.g91).copyWith(fontWeight: FontWeight.w600),
      cursorColor: WsT.accent,
      backgroundCursorColor: Grey.g44,
      selectionColor: Grey.g38,
      cursorWidth: 1.5,
      maxLines: 1,
      onSubmitted: (_) => _f.unfocus(),
    ));
  }
}
