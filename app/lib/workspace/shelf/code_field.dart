// An editor for code, coloured by flutter_code_editor's highlight.js binding.
// The Code tab's cells use it.
import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart' as fce;
import 'package:highlight/languages/glsl.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/lua.dart';
import 'package:highlight/highlight_core.dart' show Mode;

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

  /// Whether the editor sizes to its code (notebook cell) or fills its parent.
  final bool fit;

  /// Whether to keep typed text as-is without reading the file back.
  final bool keep;

  /// The controller that last had the keys, so a list beside the code can
  /// write into it.
  static fce.CodeController? _last;

  /// Writes [text] where the cursor is in the editor that last had the keys.
  static bool insert(String text) {
    if (_last == null) return false;
    _last!.insertStr(text);
    return true;
  }

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  late String _written = readTextNow(widget.file);
  late final fce.CodeController _controller = fce.CodeController(
    text: _written,
    language: _languageFor(widget.file),
  );
  Timer? _soon;

  static Mode? _languageFor(String file) {
    if (file.endsWith('.fs') || file.endsWith('.glsl')) return glsl;
    if (file.endsWith('.css')) return css;
    if (file.endsWith('.lua') ||
        file.endsWith('.anm2') ||
        file.endsWith('.obj2'))
      return lua;
    return javascript;
  }

  void _save() {
    if (_written == _controller.text) return;
    widget.write(_written = _controller.text);
  }

  void _onChanged(String _) {
    _soon?.cancel();
    _soon = Timer(const Duration(milliseconds: 400), _save);
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
    final size = TextStyles.value().fontSize!;
    final theme = _buildTheme();
    final field = fce.CodeTheme(
      data: theme,
      child: fce.CodeField(
        controller: _controller,
        focusNode: _focus,
        onChanged: _onChanged,
        wrap: !widget.fit,
        textStyle: TextStyle(
          fontSize: size,
          fontFamily: TextStyles.mono,
          height: _lineHeight,
          color: Grey.g91,
        ),
        expands: !widget.fit,
        maxLines: widget.fit ? null : null,
        minLines: widget.fit ? 1 : null,
        background: WindowTokens.well,
        cursorColor: Grey.g91,
        gutterStyle: fce.GutterStyle(
          showErrors: false,
          showFoldingHandles: false,
          showLineNumbers: true,
          margin: Shape.s(4),
          textStyle: TextStyle(
            fontSize: size,
            fontFamily: TextStyles.mono,
            height: _lineHeight,
            color: Grey.g38,
          ),
        ),
      ),
    );
    if (!widget.fit) return field;
    final lines = '\n'.allMatches(_controller.text).length + 2;
    return SizedBox(
      height: lines * size * _lineHeight + Shape.s(12),
      child: field,
    );
  }

  static const _lineHeight = 1.4;

  fce.CodeThemeData _buildTheme() {
    final dark = Grey.g07.computeLuminance() <= 0.5;
    return fce.CodeThemeData(styles: dark ? darkCodeStyles : lightCodeStyles);
  }
}
