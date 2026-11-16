// An editor for code, coloured by re_highlight through code_forge.
// code_forge handles scrolling, line numbers, folding, bracket matching,
// indentation guides, and minimap internally. This file is the only place
// that imports it.
//
// As a cell of the Code tab ([CodeField.fit]) it is as tall as its code until the strip under it is dragged, and the
// wheel scrolls the tab, not the code, until the code is clicked: a page of editors scrolls so (GitHub's, a notebook's).
import 'dart:async';
import 'dart:math' as math;

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
import 'package:motolii/workspace/code/expression_prompts.dart';

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
    this.height,
    this.onHeight,
    this.prompts,
    this.mark,
  });
  final String file;

  /// What to underline as wrong, if anything: a red wave where it is in the code, as VS Code underlines an error.
  final ValueListenable<CodeMark?>? mark;

  /// The names completed as they are typed (IntelliSense), for an After Effects expression; null for other code.
  final ExpressionPrompts? prompts;
  final void Function(String text) write;

  /// Whether it is a cell: as tall as its code, with one more line to type on, and not as tall as the room it is given.
  final bool fit;

  /// The height a cell was given by hand; null is as tall as its code.
  final double? height;

  /// Called with the height the strip under a cell is dragged to, or null when the strip is pressed twice, which
  /// makes the cell as tall as its code again. Without it a cell has no strip.
  final void Function(double? height)? onHeight;
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

  // code_forge underlines what a language server calls wrong; the running expression's own error is told to it the
  // same way (lines and columns from 0, as the Language Server Protocol counts them).
  void _remark() {
    final m = widget.mark?.value;
    _controller.diagnosticsNotifier.value = [
      if (m != null)
        LspErrors(
          severity: 1,
          range: {
            'start': {'line': m.line - 1, 'character': m.from},
            'end': {'line': m.line - 1, 'character': m.to},
          },
          message: '',
        ),
    ];
  }

  /// The names an expression may say, as code_forge's list of completions takes them: a function is written with its
  /// brackets and the cursor between them.
  List<CustomCodeSnippet>? get _names => widget.prompts == null
      ? null
      : [
          for (final p in widget.prompts!.direct)
            p is CodeFunctionPrompt
                ? CustomCodeSnippet(
                    label: p.word,
                    value: '${p.word}()',
                    cursorLocations: {p.word.length + 1},
                  )
                : CustomCodeSnippet(
                    label: p.word,
                    value: p.word,
                    cursorLocations: const {},
                  ),
        ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    widget.mark?.addListener(_remark);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ready = true;
      // code_forge's painter takes what is wrong only when told of a change, so it is told once it is there.
      if (mounted) _remark();
    });
  }

  @override
  void didUpdateWidget(CodeField old) {
    super.didUpdateWidget(old);
    if (old.mark != widget.mark) {
      old.mark?.removeListener(_remark);
      widget.mark?.addListener(_remark);
      _remark();
    }
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
    widget.mark?.removeListener(_remark);
    if (identical(CodeField._last, _controller)) CodeField._last = null;
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  late final FocusNode _focus = FocusNode()
    ..addListener(() {
      if (_focus.hasFocus) CodeField._last = _controller;
      // A cell's frame and what the wheel scrolls follow the keys.
      if (mounted && widget.fit) setState(() {});
    });

  /// The cell's height when the drag of its strip began, moved by the drag since.
  double _dragged = 0;

  /// The strip under a cell: dragging it makes the cell taller or shorter, pressing it twice as tall as its code.
  Widget _strip(double now, double least) => MouseRegion(
    cursor: SystemMouseCursors.resizeUpDown,
    child: GestureDetector(
      key: const ValueKey('code-cell-size'),
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _dragged = now,
      onVerticalDragUpdate: (d) =>
          widget.onHeight!(math.max(least, _dragged += d.delta.dy)),
      onDoubleTap: () => widget.onHeight!(null),
      child: SizedBox(
        height: Shape.s(8),
        child: Center(
          child: Container(width: Shape.z(24), height: 2, color: Grey.g38),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final fontSize = TextStyles.value().fontSize!;
    final dark = Grey.g07.computeLuminance() <= 0.5;
    final theme = dark ? darkCodeStyles : lightCodeStyles;
    final fit = widget.fit;
    // A press anywhere else gives the keys back, so the window's shortcuts and the tab's scrolling work again.
    // The list of functions beside the code is of the same group (code_pane.dart): it writes into the code.
    final editor = TapRegion(
      groupId: CodeField,
      onTapOutside: (_) => _focus.unfocus(),
      child: _editor(fontSize, theme, fit),
    );
    if (!fit) return editor;
    // One more line than the code, to type on, as a notebook's cell has (Jupyter).
    final line = fontSize * _lineHeight,
        tall = widget.height ?? (_lines + 1) * line + _pad.vertical;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: tall,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(
                color: _focus.hasFocus
                    ? WindowTokens.accent
                    : WindowTokens.line,
              ),
            ),
            child: editor,
          ),
        ),
        if (widget.onHeight != null) _strip(tall, 3 * line + _pad.vertical),
      ],
    );
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
      // A cell's code is scrolled once it has the keys; until then the wheel scrolls the tab the cells are in.
      verticalScrollPhysics: !fit || _focus.hasFocus
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      useSpaceAsTab: true,
      tabSize: 2,
      // The list of completions opens on the words of the code itself, and the expression's names are put first in it.
      enableLocalSuggestions: widget.prompts != null,
      customCodeSnippets: _names,
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
