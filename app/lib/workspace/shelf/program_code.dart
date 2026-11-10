// An editor for a program's code, coloured by re_highlight. The Program shelf and a layer's script card both use it.
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/glsl.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';

/// An editor for a program's code.
///
/// Typed text is passed to [write] shortly after the last key. The shelf writes it over the program's file. A layer's
/// script on its card writes it to the layer's own copy instead (FxCode).
class ProgramCode extends StatefulWidget {
  const ProgramCode(this.file, this.write, {super.key, this.keep = false});
  final String file;
  final void Function(String text) write;

  /// Whether the typed text is kept as it is, without reading the file back. FxCode uses this while a script is being made.
  final bool keep;
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
    if (now != _written && !(_soon?.isActive ?? false) && !widget.keep) _text.text = _written = now; // Another editor wrote the file.
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
    // The shelf is narrow, and a line pushed sideways would be out of sight.
    wordWrap: true,
    // Keep exactly what is typed. re_editor inserts a closing quote or bracket and does not step over one that is typed,
    // so {"a":"b"} came out as {"a":"b""}.
    autocompleteSymbols: false,
    onChanged: (_) {
      _soon?.cancel();
      _soon = Timer(const Duration(milliseconds: 400), _save);
    },
    indicatorBuilder: (context, editing, chunks, notifier) => DefaultCodeLineNumber(controller: editing, notifier: notifier),
    style: CodeEditorStyle(
      fontSize: TextStyles.value().fontSize,
      fontFamily: TextStyles.mono,
      fontHeight: 1.4,
      textColor: Grey.g91,
      backgroundColor: WindowTokens.well,
      selectionColor: WindowTokens.accent.withAlpha(90),
      cursorColor: Grey.g91,
      codeTheme: CodeHighlightTheme(
        languages: {widget.file.endsWith('.fs') ? 'glsl' : 'javascript': CodeHighlightThemeMode(mode: widget.file.endsWith('.fs') ? langGlsl : langJavascript)},
        theme: Grey.g07.computeLuminance() > .5 ? atomOneLightTheme : atomOneDarkTheme,
      ),
    ),
  );
}
