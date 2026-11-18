// A card's code cell in the Code tab: .wgsl, ISF .fs, or expression .js.
// The first edit copies the shelf file to the user's own folder (copy-on-write); the filename stays so values and keys stay.
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/storage/shelf_disk.dart' show writeText;
import 'package:motolii/storage/text_file.dart' show readTextNow;
import 'package:motolii/workspace/code/expression_prompts.dart';
import 'package:motolii/workspace/code/expression_result.dart';
import 'package:motolii/workspace/shelf/code_field.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart';
import 'package:motolii/workspace/state/tiles/effect_code_cards.dart' as cards;
import 'package:motolii/workspace/state/engine_access.dart' show projectOpen;
import 'package:motolii/workspace/state/workspace_controller.dart';

class EffectCode extends StatefulWidget {
  const EffectCode(
    this.ws,
    this.thing,
    this.word, {
    this.slot = 'fx',
    this.shelf = true,
    this.fit = false,
    this.height,
    this.onHeight,
    super.key,
  });
  final WorkspaceController ws;
  final int thing;

  /// The file as the layer's slot names it.
  final String word;

  /// The layer property that names the file, and the programs/ folder that holds its copies.
  /// 'fx' is for effects; 'script' is the Script card's single file.
  final String slot;

  /// Whether to show "Add to shelf" under the editor: for an effect, not for a script.
  final bool shelf;

  /// Whether the editor is as tall as its code (CodeField.fit), not as tall as the room it is given.
  final bool fit;

  /// The height the editor was given by hand, and what is called when it is dragged to another (CodeField.height).
  final double? height;
  final void Function(double? height)? onHeight;
  @override
  State<EffectCode> createState() => _EffectCodeState();

  /// The view state the Code tab keeps: the titles of the cards whose cell is folded, and the card last asked for
  /// with a count, so that asking for the same card again is heard.
  static const folded = cards.codeFolded, asked = cards.codeAsked;

  /// Opens the Code tab on the card [title]: its cell is unfolded and scrolled into sight.
  static void show(WorkspaceController ws, String title) =>
      cards.showCodeCell(ws, title);

  /// The code of the card [title] on layer [thing], or null if the card has no code.
  static EffectCode? ofCard(
    WorkspaceController ws,
    int thing,
    String title,
    List<String> names, {
    bool fit = false,
    double? height,
    void Function(double? height)? onHeight,
  }) {
    final card = cards.codeOfCard(ws, thing, title, names);
    if (card == null) return null;
    final script = card.slot == 'script';
    return EffectCode(
      ws,
      thing,
      card.word,
      slot: card.slot,
      shelf: !script,
      fit: fit,
      height: height,
      onHeight: onHeight,
      key: script
          ? ValueKey('script-code-$thing')
          : ValueKey('fx-code-$thing-$title'),
    );
  }

  /// The file in a layer's [fx] that the card belongs to, or null if there is none or it is not code.
  static String? fileOf(String fx, String title, List<String> names) =>
      cards.codeFileOf(fx, title, names);

  /// The card title for an effect file (matches doc_fx_title).
  static String titleOf(String w) => cards.codeTitleOf(w);

  /// The file to read for an effect [w]. A re-applied effect reads its original.
  static String source(String w) => cards.codeSource(w);

  /// Whether [word] is the user's own copy, used by no other card.
  static bool alone(
    WorkspaceController ws,
    int thing,
    String word,
    String slot,
  ) => cards.codeAlone(ws, thing, word, slot);

  /// Whether the card takes a user-given name (from the code's first line).
  bool get named => cards.codeNamedInText(word, slot);
  void rename(String name, void Function(bool done, String why) told) =>
      cards.codeRename(ws, thing, word, slot, name, told);

  /// Copy-on-write: copies the file and its companions to `programs/<slot>/<stamp>/`.
  static (String, String, int) copyOwn(
    WorkspaceController ws,
    int thing,
    String word,
    String slot,
  ) => cards.codeCopyOwn(ws, thing, word, slot);
}

class _EffectCodeState extends State<EffectCode> {
  // The copy's path, kept until the engine reports it as the layer's file.
  String? _mine;
  // Why the current code was rejected, shown on the card. Empty when it was accepted.
  String _why = '';
  // True while the copy is being made from the original, before the typed text overwrites it.
  bool _making = false;
  // Text typed while the copy was being made.
  String? _typed;
  // The name being typed for "Add to shelf".
  String? _adding;
  // The result of the last "Add to shelf": why it failed, or where it went.
  String _added = '';
  bool _addedOk = false;
  // The names completed in the editor, asked of the running expression once for each file.
  ExpressionPrompts? _prompts;
  String? _promptsFor;
  // Where the running expression is wrong, underlined in the editor.
  final _mark = ValueNotifier<CodeMark?>(null);

  void _askPrompts(String file) {
    if (!projectOpen(widget.ws) || file == _promptsFor) return;
    _promptsFor = file;
    cards.codeSupport(widget.ws, file).then((runs) {
      if (mounted && _promptsFor == file) {
        setState(
          () => _prompts = runs == null ? null : ExpressionPrompts.of(runs),
        );
      }
    });
  }

  @override
  void dispose() {
    _mark.dispose();
    super.dispose();
  }

  // The copy is made from the original first, then overwritten with the typed text.
  // This way the engine keeps showing the last accepted version while typing.
  void _write(String text) {
    if (_making) {
      _typed = text;
      return;
    }
    final ws = widget.ws,
        word = _mine ?? widget.word,
        file = EffectCode.source(word);
    if (EffectCode.alone(ws, widget.thing, word, widget.slot)) {
      writeText(file, text);
      return _saved(file);
    }
    final (said, to, read) = EffectCode.copyOwn(
      ws,
      widget.thing,
      word,
      widget.slot,
    );
    _mine = said;
    _making = true;
    _typed = text;
    ws.after(read, (_, _) {
      _making = false;
      writeText(to, _typed!);
      _typed = null;
      _saved(to);
    });
  }

  void _saved(String file) => cards.codeWritten(widget.ws, file, (done, why) {
    if (mounted) setState(() => _why = done ? '' : why.trim());
  });

  // Adds the card's code to the shelf under [name].
  void _add(String? name) {
    setState(() => _adding = null);
    if (name == null) return;
    final word = _mine ?? widget.word,
        file = EffectCode.source(word),
        expression = shelfIsExpression(file);
    final why = _why.isNotEmpty
        ? 'It does not compile: fix it first'
        : shelfAdd(
            widget.ws,
            file,
            _typed ?? readTextNow(file),
            name,
            shelfTaken(widget.ws, expression: expression),
          );
    setState(() {
      _addedOk = why.isEmpty;
      _added = why.isEmpty
          ? 'Added to ${expression ? 'Create, Copies' : 'Effects'} as ${name.trim()}'
          : why;
    });
  }

  Widget _shelf() {
    if (_adding case final name?) {
      return SizedBox(
        height: Shape.s(18),
        child: ShelfNameField(name, _add, small: false),
      );
    }
    return Row(
      children: [
        NakedButton(
          onPressed: () => setState(() {
            _adding = EffectCode.titleOf(_mine ?? widget.word);
            _added = '';
          }),
          enableFeedback: false,
          child: Text('Add to shelf', style: TextStyles.label(Grey.g76)),
        ),
        if (_added.isNotEmpty) ...[
          SizedBox(width: Shape.s(8)),
          Expanded(
            child: Text(
              _added,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.label(_addedOk ? Grey.g56 : Role.error),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mine == widget.word) _mine = null;
    _askPrompts(EffectCode.source(_mine ?? widget.word));
    return Column(
      mainAxisSize: widget.fit ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_why.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: Shape.s(4)),
            child: Text(
              'Does not compile; the last that did is shown. $_why',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.label(Role.error),
            ),
          ),
        if (widget.fit)
          CodeField(
            EffectCode.source(_mine ?? widget.word),
            _write,
            keep: _making,
            fit: true,
            height: widget.height,
            onHeight: widget.onHeight,
            prompts: _prompts,
            mark: _mark,
          )
        else
          Expanded(
            child: CodeField(
              EffectCode.source(_mine ?? widget.word),
              _write,
              keep: _making,
              prompts: _prompts,
              mark: _mark,
            ),
          ),
        // Expression result at the playhead.
        ExpressionResult(
          EffectCode.source(_mine ?? widget.word),
          write: _write,
          mark: _mark,
        ),
        if (widget.shelf)
          Padding(
            padding: EdgeInsets.only(top: Shape.s(4)),
            child: _shelf(),
          ),
      ],
    );
  }
}
