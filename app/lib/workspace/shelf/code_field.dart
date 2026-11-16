// An editor for code, coloured by re_highlight through code_forge.
// code_forge handles scrolling, line numbers, folding, bracket matching,
// indentation guides, and minimap internally. This file is the only place
// that imports it.
import 'dart:async';

import 'package:code_forge/code_forge.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:re_highlight/languages/css.dart' show langCss;
import 'package:re_highlight/languages/glsl.dart' show langGlsl;
import 'package:re_highlight/languages/javascript.dart' show langJavascript;
import 'package:re_highlight/languages/lua.dart' show langLua;
import 'package:re_highlight/re_highlight.dart' show Mode;

import 'package:motolii/skin/code_colors.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/storage/text_file.dart' show readTextNow;
import 'package:motolii/skin/window_tokens.dart';

/// A stretch of code that is wrong: its line, counted from 1, and its columns.
typedef CodeMark = ({int line, int from, int to});

/// An editor for code.
///
/// Typed text is passed to [write] shortly after the last key. A card's code
/// writes it to the layer's own copy of the file (EffectCode).
class CodeField extends StatefulWidget {
  const CodeField(
    this.file,
    this.write, {
    super.key,
    this.keep = false,
    this.fit = false,
    this.mark,
  });
  final String file;
  final ValueListenable<CodeMark?>? mark;
  final void Function(String text) write;
  final bool fit;
  final bool keep;

  static CodeForgeController? _last;

  static bool insert(String text) {
    if (_last == null) return false;
    _last!.insertAtAllCursors(text);
    return true;
  }

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  late String _written = readTextNow(widget.file);
  late final CodeForgeController _controller = CodeForgeController();
  Timer? _soon;
  bool _ready = false;

  static Mode _languageFor(String file) {
    if (file.endsWith('.fs') || file.endsWith('.glsl')) return langGlsl;
    if (file.endsWith('.css')) return langCss;
    if (file.endsWith('.lua') ||
        file.endsWith('.anm2') ||
        file.endsWith('.obj2')) {
      return langLua;
    }
    return langJavascript;
  }

  void _save() {
    if (_written == _controller.text) return;
    widget.write(_written = _controller.text);
  }

  void _onChanged() {
    if (!_ready) return;
    _counted();
    _soon?.cancel();
    _soon = Timer(const Duration(milliseconds: 400), _save);
  }

  /// The lines the editor's height was last worked out for, when it is as tall as its code.
  late int _lines = '\n'.allMatches(_written).length + 1;

  // code_forge fills the height it is given and cannot be as tall as its code by itself (its Column holds an
  // Expanded), so a cell's height is worked out from the count of lines. The controller may tell its listeners
  // while a frame is being built, when nothing may be rebuilt.
  void _counted() {
    if (!mounted || !widget.fit || _controller.lineCount == _lines) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _counted());
      return;
    }
    setState(() => _lines = _controller.lineCount);
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ready = true;
    });
  }

  @override
  void didUpdateWidget(CodeField old) {
    super.didUpdateWidget(old);
    final now = readTextNow(widget.file);
    if (now != _written && !(_soon?.isActive ?? false) && !widget.keep) {
      _controller.text = _written = now;
    }
  }

  @override
  void dispose() {
    if (_soon?.isActive ?? false) _save();
    _soon?.cancel();
    _controller.removeListener(_onChanged);
    if (identical(CodeField._last, _controller)) CodeField._last = null;
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  late final FocusNode _focus = FocusNode()
    ..addListener(() {
      if (_focus.hasFocus) CodeField._last = _controller;
    });

  @override
  Widget build(BuildContext context) {
    final fontSize = TextStyles.value().fontSize!;
    final dark = Grey.g07.computeLuminance() <= 0.5;
    final theme = dark ? darkCodeStyles : lightCodeStyles;
    final fit = widget.fit;
    final editor = _editor(fontSize, theme, fit);
    // One more line than the code, to type on, as a notebook's cell has (Jupyter).
    return fit
        ? SizedBox(
            height: (_lines + 1) * fontSize * _lineHeight + _pad.vertical,
            child: editor,
          )
        : editor;
  }

  static const _lineHeight = 1.4;
  static const _pad = EdgeInsets.only(top: 4, bottom: 8);

  Widget _editor(double fontSize, Map<String, TextStyle> theme, bool fit) {
    return CodeForge(
      controller: _controller,
      focusNode: _focus,
      language: _languageFor(widget.file),
      editorTheme: theme,
      initialText: _written,
      lineWrap: !fit,
      useSpaceAsTab: true,
      tabSize: 2,
      textStyle: TextStyle(
        fontSize: fontSize,
        fontFamily: TextStyles.mono,
        height: _lineHeight,
      ),
      innerPadding: _pad,
      enableFolding: !fit,
      enableMinimap: !fit,
      enableGuideLines: !fit,
      enableGutter: true,
      enableGutterDivider: false,
      gutterStyle: GutterStyle(
        lineNumberStyle: TextStyle(
          fontSize: fontSize,
          fontFamily: TextStyles.mono,
          height: _lineHeight,
          color: Grey.g38,
        ),
        backgroundColor: WindowTokens.well,
      ),
      selectionStyle: CodeSelectionStyle(
        cursorColor: Grey.g91,
        selectionColor: WindowTokens.accent.withAlpha(90),
      ),
      minimapStyle: fit
          ? null
          : MinimapStyle(backgroundColor: WindowTokens.well),
    );
  }
}
