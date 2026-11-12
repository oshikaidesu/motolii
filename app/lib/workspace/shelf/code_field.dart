// An editor for code, coloured by re_highlight. The Code tab's cells use it.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/glsl.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/code/expression_prompts.dart';

/// A stretch of code that is wrong: its line, counted from 1, and its columns. It is underlined with a red wave, as
/// VS Code underlines an error where it is in the code.
typedef CodeMark = ({int line, int from, int to});

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
    this.prompts,
    this.mark,
  });
  final String file;

  /// What to underline as wrong, if anything.
  final ValueListenable<CodeMark?>? mark;

  /// The names completed as they are typed (IntelliSense), for an After Effects expression; null for other code.
  final ExpressionPrompts? prompts;
  final void Function(String text) write;

  /// Whether the editor is as tall as its code, with one more line to type on, and not as tall as the room it is given.
  /// A notebook's cell is sized so (Jupyter). Lines are then not wrapped: a long line scrolls sideways.
  final bool fit;

  /// Whether the typed text is kept as it is, without reading the file back. EffectCode uses this while a script is being made.
  final bool keep;

  /// The editor that last had the keys, so that a list beside the code can write into it.
  static CodeLineEditingController? _last;

  /// Writes [text] where the cursor is in the editor that last had the keys, over what is selected there.
  /// Returns false if no editor has had the keys yet.
  static bool insert(String text) {
    _last?.replaceSelection(text);
    return _last != null;
  }

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  late String _written = File(widget.file).readAsStringSync();
  late final _text = CodeLineEditingController(
    codeLines: CodeLines.fromText(_written),
    spanBuilder: _marked,
  );

  /// The line as re_editor coloured it, with the marked columns underlined.
  TextSpan _marked({
    required BuildContext context,
    required int index,
    required CodeLine codeLine,
    required TextSpan textSpan,
    required TextStyle style,
  }) {
    final m = widget.mark?.value;
    if (m == null || m.line != index + 1) return textSpan;
    var at = 0;
    InlineSpan cut(InlineSpan span) {
      if (span is! TextSpan) return span;
      final text = span.text ?? '', from = at, to = at += text.length;
      final kids = span.children?.map(cut).toList();
      final a = m.from.clamp(from, to) - from, b = m.to.clamp(from, to) - from;
      if (a == b) {
        return TextSpan(text: text, style: span.style, children: kids);
      }
      final wave = (span.style ?? style).copyWith(
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.wavy,
        decorationColor: Role.error,
      );
      return TextSpan(
        style: span.style,
        children: [
          TextSpan(text: text.substring(0, a)),
          TextSpan(text: text.substring(a, b), style: wave),
          TextSpan(text: text.substring(b)),
          ...?kids,
        ],
      );
    }

    return cut(textSpan) as TextSpan;
  }

  void _remark() => _text.forceRepaint();
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
    widget.mark?.removeListener(_remark);
    if (identical(CodeField._last, _text)) CodeField._last = null;
    _focus.dispose();
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

  late final FocusNode _focus = FocusNode()
    ..addListener(() {
      if (_focus.hasFocus) CodeField._last = _text;
    });

  @override
  void initState() {
    super.initState();
    if (widget.fit) _text.addListener(_counted);
    widget.mark?.addListener(_remark);
  }

  @override
  Widget build(BuildContext context) {
    final size = TextStyles.value().fontSize!, pad = Shape.s(6);
    final prompts = widget.prompts, plain = _editor(size, pad);
    final editor = prompts == null
        ? plain
        : CodeAutocomplete(
            viewBuilder: (context, notifier, onSelected) =>
                expressionPromptsView(context, notifier, onSelected, prompts),
            promptsBuilder: DefaultCodeAutocompletePromptsBuilder(
              language: langJavascript,
              directPrompts: prompts.direct,
              relatedPrompts: prompts.related,
            ),
            child: plain,
          );
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
    focusNode: _focus,
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
    // A line longer than the cell shows its scrollbar, as VS Code does with its lines not wrapped; re_editor shows the
    // sideways one only while scrolling, so a cut-off line gave no sign that more of it was there.
    scrollbarBuilder: (context, child, details) => details.controller == null
        ? child
        : RawScrollbar(
            controller: details.controller,
            thumbVisibility: true,
            scrollbarOrientation: details.direction == AxisDirection.right
                ? ScrollbarOrientation.bottom
                : ScrollbarOrientation.right,
            thickness: Shape.s(5),
            radius: Shape.r(3),
            thumbColor: Grey.g38,
            child: child,
          ),
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
