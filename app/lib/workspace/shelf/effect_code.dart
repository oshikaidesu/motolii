// The code of one card of a layer: an effect's, an expression's, or the Script card's (slot: 'script'). The Code tab
// shows it as a cell (workspace/code/code_pane.dart), and "Edit code" on the card in the Inspector opens that cell.
// It edits a .wgsl, an ISF .fs, or an expression (a .js with each() among its fx: document/scripts/expressions.h).
// Typing affects only this layer's effect. The shelf's file is never overwritten: the first edit copies it to a folder
// of the user's own (programs/fx/<stamp>/) under the same file name, and the layer's fx points at the copy.
// Keeping the file name keeps everything attached to it: the parameter names (js_<stem>_<param>, doc_screen_knob)
// and the card title (doc_fx_title), so the effect's visibility, place and values stay.
// Files the engine reads from the same folder are copied along: an ISF's .vs (isf.cpp), its line in first.tsv
// (script_first), and the images its header names (--image@, screen_fx.h).
import 'dart:io';

import 'package:motolii/workspace/shelf/effect_tiles_review.dart';

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart' show EffectTiles;
import 'package:motolii/workspace/shelf/shelf_add.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/code/expression_prompts.dart';
import 'package:motolii/workspace/code/expression_reference.dart'
    show supportedIn;
import 'package:motolii/workspace/code/expression_result.dart';
import 'package:motolii/workspace/shelf/code_field.dart';

class EffectCode extends StatefulWidget {
  const EffectCode(
    this.ws,
    this.thing,
    this.word, {
    this.slot = 'fx',
    this.shelf = true,
    this.fit = false,
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
  @override
  State<EffectCode> createState() => _EffectCodeState();

  // Drawn code, or an expression (a .js with each(), document/scripts/expressions.h).
  static final _code = RegExp(r'\.(wgsl|fs|js)$');

  /// The view state the Code tab keeps: the titles of the cards whose cell is folded, and the card last asked for
  /// with a count, so that asking for the same card again is heard.
  static const folded = 'code.folded', asked = 'code.asked';

  /// Opens the Code tab on the card [title]: its cell is unfolded and scrolled into sight.
  static void show(WorkspaceController ws, String title) {
    ws.setView(folded, {...ws.viewOf(folded, const <String>{})}..remove(title));
    ws.setView(asked, (
      title,
      (ws.viewOf<(String, int)?>(asked, null)?.$2 ?? 0) + 1,
    ));
    ws.front('Code');
  }

  /// The code of the card [title] of the layer [thing], or null if the card has no code.
  ///
  /// The Script card has one file. Any other card is matched to a file of the layer's effects by its parameter [names],
  /// not by the title alone, because two cards can share a title.
  /// An effect's parameters, and those of an expression applied again ("repeater~2.js"), are named after the file
  /// (`js_<stem>_<param>`, document/scripts/scripts.h doc_script_of), so the file is the one whose name they all begin with.
  /// An expression's own parameters are `js_<param>`, so the file is the .js whose header declares them all.
  /// If two files fit, the one whose title matches the card wins, then the longer name.
  /// A card with no parameters of its own (the engine still gives it a card, doc_cards_of) is matched by title alone.
  static EffectCode? ofCard(
    WorkspaceController ws,
    int thing,
    String title,
    List<String> names, {
    bool fit = false,
  }) {
    final m = ws.inside!;
    if (title == 'Script') {
      final script = m.word(thing, 'script');
      return script.endsWith('.js')
          ? EffectCode(
              ws,
              thing,
              script,
              slot: 'script',
              shelf: false,
              fit: fit,
              key: ValueKey('script-code-$thing'),
            )
          : null;
    }
    final word = fileOf(m.word(thing, 'fx'), title, names);
    return word == null
        ? null
        : EffectCode(
            ws,
            thing,
            word,
            fit: fit,
            key: ValueKey('fx-code-$thing-$title'),
          );
  }

  /// The file in a layer's [fx] that the card belongs to, or null if there is none or it is not code.
  static String? fileOf(String fx, String title, List<String> names) {
    (String, int)? best;
    for (final w in WorkspaceController.fxFiles(fx)) {
      if (!_code.hasMatch(w)) continue;
      final file = source(w),
          stem = TileReview.knobStem(w),
          titled = titleOf(w) == title;
      // A three.js effect is run as a scene once saved (doc_three_saved).
      if (w.endsWith('.js') && _three(file)) continue;
      // A card's own parameters begin with js_. The first card with code on a layer also shows values of the layer
      // itself (How many copies), which no file declares, so those do not decide.
      final own = [
        for (final n in names)
          if (n.startsWith('js_')) n,
      ];
      if (own.isEmpty) {
        if (titled) return w;
        continue;
      }
      final fits = w.endsWith('.js') && file == w
          ? own.every({for (final k in _knobs(_head(file))) 'js_$k'}.contains)
          : own.every((n) => n.startsWith('js_${stem}_'));
      if (!fits) continue;
      final score = (titled ? 1000 : 0) + stem.length;
      if (best == null || score > best.$2) best = (w, score);
    }
    return best?.$1;
  }

  /// The card title for an effect file, named as the engine does (document/cards.h doc_fx_title).
  ///
  /// An effect applied again ("Glow~2.fs") gets its original's title and its number.
  /// An ISF effect gets its file name (isf.cpp titles the WGSL it generates that way).
  /// Any other file gets the name in its first line ("// Repeater: …"), else its file name with each _ as a space
  /// and the first letter capitalised.
  static String titleOf(String w) {
    final file = source(w),
        stem = w.split('/').last.replaceFirst(RegExp(r'\.[^.]*$'), '');
    if (file != w) {
      return '${titleOf(file)} ${stem.substring(stem.lastIndexOf('~') + 1)}';
    }
    if (w.endsWith('.fs')) return stem;
    var first = '';
    try {
      first = File(file).readAsLinesSync().firstOrNull ?? '';
    } catch (_) {}
    if (first.startsWith('// ') && first.contains(':')) {
      return first.substring(3, first.indexOf(':'));
    }
    final t = stem.replaceAll('_', ' ');
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
  }

  /// The header of [file]: the comment lines before its code (script.cpp script_knobs reads its parameters there).
  static List<String> _head(String file) {
    try {
      return [
        for (final l in File(file).readAsLinesSync().takeWhile(
          (l) => l.startsWith('//') || l.trim().isEmpty,
        ))
          if (l.startsWith('//')) l,
      ];
    } catch (_) {
      return const [];
    }
  }

  /// The parameter names declared in [head], such as "// --track@StepX:Step X,…" (script_knobs).
  static List<String> _knobs(List<String> head) => [
    for (final l in head)
      if ((l.indexOf('--'), l.indexOf('@'), l.indexOf(':'))
          case (final d, final a, final c)
          when d >= 0 && d < a && a < c && c > a + 1)
        l.substring(a + 1, c),
  ];

  static bool _three(String file) {
    // Same test as three_isf.cpp three_is: a .js containing a fragmentShader.
    try {
      return File(file).readAsStringSync().contains('fragmentShader');
    } catch (_) {
      return false;
    }
  }

  /// The file to read for an effect [w]. An effect applied again ("Glow~2.fs") reads its original's file (fx_source, isf.h).
  static String source(String w) => File(w).existsSync()
      ? w
      : w.replaceFirstMapped(RegExp(r'~[0-9]+(\.[^./]+)$'), (x) => x[1]!);

  /// Whether the file [word] of the layer [thing] belongs to that card alone: one of the user's own copies, used by
  /// no other card on any layer.
  static bool alone(
    WorkspaceController ws,
    int thing,
    String word,
    String slot,
  ) {
    final m = ws.inside!, file = source(word);
    if (!file.startsWith('${EffectTiles.own}/programs/$slot/')) return false;
    for (final t in m.layers) {
      for (final w in WorkspaceController.fxFiles(m.word(t, slot))) {
        if (!(t == thing && w == word) && source(w) == file) return false;
      }
    }
    return true;
  }

  /// Gives the card's file [word] a copy of its own, as its first edit does: the file and the ones the engine reads
  /// beside it go to `programs/<slot>/<stamp>/`, and the layer's slot names the copy. Returns the copy as the slot
  /// names it, the copied file, and the engine's ticket for reading it.
  static (String, String, int) copyOwn(
    WorkspaceController ws,
    int thing,
    String word,
    String slot,
  ) {
    final m = ws.inside!, file = source(word);
    final dir =
            '${EffectTiles.own}/programs/$slot/${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
        to = '$dir/${file.split('/').last}',
        said = '$dir/${word.split('/').last}';
    Directory(dir).createSync(recursive: true);
    _EffectCodeState._beside(file, word, dir);
    File(file).copySync(to);
    // Joined the way doc_fx_join does.
    final fx = [
      for (final w in WorkspaceController.fxFiles(m.word(thing, slot)))
        w == word ? said : w,
    ].join(' ');
    m.later('say', layer: thing, name: slot, word: fx);
    return (said, to, m.later('code', word: to));
  }
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

  @override
  void dispose() {
    _mark.dispose();
    super.dispose();
  }

  void _askPrompts(String file) {
    final m = widget.ws.inside;
    if (m == null || file == _promptsFor) return;
    _promptsFor = file;
    supportedIn(m, file).then((runs) {
      if (mounted && _promptsFor == file) {
        setState(
          () => _prompts = runs == null ? null : ExpressionPrompts.of(runs),
        );
      }
    });
  }

  // The copy is first made from the original and accepted by the engine, then overwritten with the typed text.
  // A half-typed effect or expression then keeps showing the last version the engine accepted, which a copy
  // that was never accepted could not (isf.cpp, doc_script_of).
  void _write(String text) {
    if (_making) {
      _typed = text;
      return;
    }
    final ws = widget.ws,
        word = _mine ?? widget.word,
        file = EffectCode.source(word);
    if (EffectCode.alone(ws, widget.thing, word, widget.slot)) {
      File(file).writeAsStringSync(text);
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
      File(to).writeAsStringSync(_typed!);
      _typed = null;
      _saved(to);
    });
  }

  void _saved(String file) =>
      widget.ws.after(widget.ws.inside!.later('code', word: file), (done, why) {
        if (mounted) setState(() => _why = done ? '' : why.trim());
        widget.ws.reread();
      });

  /// Copies the files the engine reads beside [from] to the copy's folder [dir].
  static void _beside(String from, String word, String dir) {
    final home = from.substring(0, from.lastIndexOf('/'));
    if (from.endsWith('.fs')) {
      final vs = File(from.replaceFirst(RegExp(r'\.fs$'), '.vs'));
      if (vs.existsSync()) vs.copySync('$dir/${vs.path.split('/').last}');
    }
    final first = File('$home/first.tsv'), name = word.split('/').last;
    if (first.existsSync()) {
      final lines = [
        for (final l in first.readAsLinesSync())
          if (l.split('\t').first == name) l,
      ];
      if (lines.isNotEmpty) {
        File('$dir/first.tsv').writeAsStringSync('${lines.join('\n')}\n');
      }
    }
    shelfCopyImages(from, dir);
  }

  // Adds the card's code to the shelf under [name]: an effect to the Effects shelf, an expression to Create's Copies
  // (shelf_add.dart). The name is typed in place of the title, like Rename in Finder.
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
            _typed ?? File(file).readAsStringSync(),
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
        // What the expression gives at the playhead, under it as After Effects puts an expression's error.
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
