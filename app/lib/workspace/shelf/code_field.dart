// An editor for code, coloured by re_highlight. The Code tab's cells use it.
import 'dart:async';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/glsl.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';

/// An editor for code.
///
/// Typed text is passed to [write] shortly after the last key. A card's code writes it to the layer's own copy of
/// the file (EffectCode).
class CodeField extends StatefulWidget {
  const CodeField(
    this.file,
    this.write, {
    super.key,
    this.keep = false,
    this.fit = false,
  });
  final String file;
  final void Function(String text) write;

  /// Whether the editor is as tall as its code, with one more line to type on, and not as tall as the room it is given.
  /// A notebook's cell is sized so (Jupyter). Lines are then not wrapped: a long line scrolls sideways.
  final bool fit;

  /// Whether the typed text is kept as it is, without reading the file back. EffectCode uses this while a script is being made.
  final bool keep;
  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  late String _written = File(widget.file).readAsStringSync();
  late final _text = CodeLineEditingController.fromText(_written);
  Timer? _soon;

  void _save() {
    if (_written == _text.text) return;
    widget.write(_written = _text.text);
  }

  @override
  void didUpdateWidget(CodeField old) {
    super.didUpdateWidget(old);
    final now = File(widget.file).readAsStringSync();
    if (now != _written && !(_soon?.isActive ?? false) && !widget.keep) {
      _text.text = _written = now; // Another editor wrote the file.
    }
  }

  @override
  void dispose() {
    if (_soon?.isActive ?? false) _save();
    _soon?.cancel();
    _text.dispose();
    super.dispose();
  }

  /// The lines the editor's height was last worked out for, when it is as tall as its code.
  late int _lines = _text.lineCount;

  // re_editor also tells its listeners while it is being built, when nothing may be rebuilt. The height changes only
  // when the count of lines does, which a key press does and building does not.
  void _counted() {
    if (!mounted || _text.lineCount == _lines) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _counted());
      return;
    }
    setState(() => _lines = _text.lineCount);
  }

  @override
  void initState() {
    super.initState();
    if (widget.fit) _text.addListener(_counted);
  }

  @override
  Widget build(BuildContext context) {
    final size = TextStyles.value().fontSize!, pad = Shape.s(6);
    final editor = _editor(size, pad);
    return widget.fit
        ? SizedBox(
            height: (_lines + 1) * size * _lineHeight + 2 * pad,
            child: editor,
          )
        : editor;
  }

  static const _lineHeight = 1.4;

  Widget _editor(double size, double pad) => CodeEditor(
    controller: _text,
    // In a narrow place a line pushed sideways would be out of sight, so it is wrapped there.
    wordWrap: !widget.fit,
    padding: EdgeInsets.all(pad),
    // Keep exactly what is typed. re_editor inserts a closing quote or bracket and does not step over one that is typed,
    // so {"a":"b"} came out as {"a":"b""}.
    autocompleteSymbols: false,
    onChanged: (_) {
      _soon?.cancel();
      _soon = Timer(const Duration(milliseconds: 400), _save);
    },
    indicatorBuilder: (context, editing, chunks, notifier) =>
        DefaultCodeLineNumber(controller: editing, notifier: notifier),
    style: CodeEditorStyle(
      fontSize: size,
      fontFamily: TextStyles.mono,
      fontHeight: _lineHeight,
      textColor: Grey.g91,
      backgroundColor: WindowTokens.well,
      selectionColor: WindowTokens.accent.withAlpha(90),
      cursorColor: Grey.g91,
      codeTheme: CodeHighlightTheme(
        languages: {
          widget.file.endsWith('.fs')
              ? 'glsl'
              : 'javascript': CodeHighlightThemeMode(
            mode: widget.file.endsWith('.fs') ? langGlsl : langJavascript,
          ),
        },
        theme: Grey.g07.computeLuminance() > .5
            ? atomOneLightTheme
            : atomOneDarkTheme,
      ),
    ),
  );
}
