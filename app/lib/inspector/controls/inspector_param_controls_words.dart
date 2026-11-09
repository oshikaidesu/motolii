// A words value's field: any words, typed (lines too), as Cavalry's string attribute.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/skin/tokens.dart';

import '../../widgets/text_gestures.dart';

/// Any words, typed (two lines shown): said to the host when the hand leaves; Esc puts back what was there.
class ParamWords extends StatefulWidget {
  const ParamWords({super.key, required this.id, required this.on});
  final String id;
  final bool on;
  @override
  State<ParamWords> createState() => ParamWordsState();
}

class ParamWordsState extends State<ParamWords> {
  final _c = TextEditingController();
  late final FocusNode _f = FocusNode(
    debugLabel: 'words',
    onKeyEvent: (n, e) {
      if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.escape) return KeyEventResult.ignored;
      _c.text = _was;
      _f.unfocus();
      return KeyEventResult.handled;
    },
  );
  String _was = '';

  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (_f.hasFocus) {
        _was = _c.text;
      } else if (_c.text != _was) {
        Ctx.read(context).doc.str(widget.id, _c.text);
      }
    });
    _c.addListener(() {
      // (its letters picked by the hand, kept for the Colors shelf to colour those alone: wordsPicked)
      if (!_f.hasFocus) return;
      final s = _c.selection;
      wordsPicked.value = s.isValid && !s.isCollapsed ? (text: _c.text, start: s.start, end: s.end) : null;
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
    final now = Ctx.of(context).doc.s2[widget.id] ?? '';
    if (!_f.hasFocus && _c.text != now) _c.text = now; // (out of the field it is what the host has now: another thing picked, an undo)
    if (textToType && widget.on) {
      // (a text just placed: the first words field built takes the keys, its words picked)
      textToType = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _f.requestFocus();
        _c.selection = TextSelection(baseOffset: 0, extentOffset: _c.text.length);
      });
    }
    return IgnorePointer(
      ignoring: !widget.on,
      child: TextGestures(
        key: ValueKey('words:${widget.id}'),
        field: (k) => EditableText(
          key: k,
          rendererIgnoresPointer: true,
          controller: _c,
          focusNode: _f,
          style: T.name(widget.on ? Grey.g95 : Grey.g44).copyWith(fontWeight: FontWeight.w400),
          cursorColor: Grey.g95,
          backgroundCursorColor: Grey.g20,
          minLines: 2,
          maxLines: 2,
          selectionColor: Role.selected.withValues(alpha: .4),
        ),
      ),
    );
  }
}
