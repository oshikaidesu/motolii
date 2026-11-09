// A program's code, typed in re_editor's CodeEditor (MIT) and coloured by re_highlight.
// What is typed is given to [write] a moment after the last key.
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/glsl.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import '../../skin/tokens.dart';
import '../state/state.dart';

/// A program's code: what is typed is given to [write] a moment after the last key (the shelf writes it over its file;
/// a thing's script on its card writes it to the thing's own copy: ScriptCode).
class ProgramCode extends StatefulWidget {
  const ProgramCode(this.file, this.write, {super.key, this.keep = false});
  final String file;
  final void Function(String text) write;
  final bool keep; // (what is typed kept as it is, the file not read back: being made, FxCode)
  @override
  State<ProgramCode> createState() => _ProgramCodeState();
}

class _ProgramCodeState extends State<ProgramCode> {
  late String _written = File(widget.file).readAsStringSync();
  late final _text = CodeLineEditingController.fromText(_written);
  Timer? _soon;

  void _save() {
    if (_written == _text.text) return;
    widget.write(_written = _text.text);
  }

  @override
  void didUpdateWidget(ProgramCode old) {
    super.didUpdateWidget(old);
    final now = File(widget.file).readAsStringSync();
    if (now != _written && !(_soon?.isActive ?? false) && !widget.keep) _text.text = _written = now; // (written by another editor)
  }

  @override
  void dispose() {
    if (_soon?.isActive ?? false) _save();
    _soon?.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CodeEditor(
    controller: _text,
    wordWrap: true, // (a shelf's width: a line pushed sideways is out of sight)
    autocompleteSymbols:
        false, // (exactly what is typed: re_editor puts in a closing " ] } and does not step over one typed, {"a":"b"} came out with ""} after it)
    onChanged: (_) {
      _soon?.cancel();
      _soon = Timer(const Duration(milliseconds: 400), _save);
    },
    indicatorBuilder: (context, editing, chunks, notifier) => DefaultCodeLineNumber(controller: editing, notifier: notifier),
    style: CodeEditorStyle(
      fontSize: T.value().fontSize,
      fontFamily: T.mono,
      fontHeight: 1.4,
      textColor: Grey.g91,
      backgroundColor: WsT.well,
      selectionColor: WsT.accent.withAlpha(90),
      cursorColor: Grey.g91,
      codeTheme: CodeHighlightTheme(
        languages: {widget.file.endsWith('.fs') ? 'glsl' : 'javascript': CodeHighlightThemeMode(mode: widget.file.endsWith('.fs') ? langGlsl : langJavascript)},
        theme: Grey.g07.computeLuminance() > .5 ? atomOneLightTheme : atomOneDarkTheme,
      ),
    ),
  );
}
