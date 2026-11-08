// An effect's code on its card, under its knobs, as the Script card's is (script_code.dart): a .wgsl's, an ISF .fs's, an
// expression's (a .js with each() among its fx: doc_expressions.h). What is typed is this thing's effect alone. The shelf's file is never written over: the first typing copies it to a folder of its own in the maker's
// programs (programs/fx/<stamp>/) under the same file name, and this thing's fx says the copy in its place. The same
// name keeps what hangs on it: its values' names (js_<stem>_<knob>, doc_screen_knob), its card's title (doc_fx_title),
// so its eye, place and values stay. Beside it go what the engine reads from the file's folder: an ISF's .vs (isf.cpp),
// its line of first.tsv (script_first), the images its head names (--image@, screen.h).
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'dock_program.dart' show ProgramCode;
import 'effect_tiles.dart' show EffectTiles;
import 'ws.dart';

class FxCode extends StatefulWidget {
  const FxCode(this.ws, this.thing, this.word, {super.key});
  final Ws ws;
  final int thing;
  final String word;   // (as the thing's fx says it)
  @override
  State<FxCode> createState() => _FxCodeState();

  static final _code = RegExp(r'\.(wgsl|fs|js)$');   // (drawn code, and an expression: a .js with each(), doc_expressions.h)

  /// The code of a thing's effect card (null: not one of its code effects), by its values, not its title alone: two
  /// cards may share one (ThorVG's Tint is called Duotone, as an ISF file may be). An effect's values, and an expression
  /// put on again's ("repeater~2.js"), are named by its file (`js_<stem>_<knob>`, doc_values.h doc_script_of): the
  /// file whose name they all begin with. An expression's first are its knobs' own (`js_<knob>`): the .js whose head
  /// says them all. Of two that fit, the one whose head names the card, else the longer name.
  static FxCode? of(Ws ws, int thing, String title, List<String> names) {
    final word = fileOf(ws.inside!.word(thing, 'fx'), title, names);
    return word == null ? null : FxCode(ws, thing, word, key: ValueKey('fx-code-$thing-$title'));
  }

  /// The word of a thing's fx ([fx]) that a card is of (null: none, or not code).
  static String? fileOf(String fx, String title, List<String> names) {
    if (names.isEmpty) return null;
    (String, int)? best;
    for (final w in Ws.fxFiles(fx)) {
      if (!_code.hasMatch(w)) continue;
      final file = source(w), stem = EffectTiles.knobStem(w), head = _head(file);
      if (w.endsWith('.js') && _three(file)) continue;   // (a three.js effect: saved, it is run as a scene, doc_three_saved)
      final fits = w.endsWith('.js') && file == w ? names.every({for (final k in _knobs(head)) 'js_$k'}.contains) : names.every((n) => n.startsWith('js_${stem}_'));
      if (!fits) continue;
      final named = head.isNotEmpty && RegExp(r'^// ([^:]+):').firstMatch(head.first)?[1]?.trim() == title.replaceFirst(RegExp(r' \d+$'), '');
      final score = (named ? 1000 : 0) + stem.length;
      if (best == null || score > best.$2) best = (w, score);
    }
    return best?.$1;
  }

  /// Its head: the lines before its code (script.cpp script_knobs reads its knobs there).
  static List<String> _head(String file) {
    try {
      return [for (final l in File(file).readAsLinesSync().takeWhile((l) => l.startsWith('//') || l.trim().isEmpty)) if (l.startsWith('//')) l];
    } catch (_) {
      return const [];
    }
  }

  /// The knobs its head says, by name: "// --track@StepX:Step X,…" (script_knobs).
  static List<String> _knobs(List<String> head) => [
    for (final l in head)
      if ((l.indexOf('--'), l.indexOf('@'), l.indexOf(':')) case (final d, final a, final c) when d >= 0 && d < a && a < c && c > a + 1) l.substring(a + 1, c),
  ];

  static bool _three(String file) {   // (three_isf.cpp three_is: a .js with a fragmentShader)
    try {
      return File(file).readAsStringSync().contains('fragmentShader');
    } catch (_) {
      return false;
    }
  }

  /// The file read for an effect word: an effect put on again ("Glow~2.fs") reads its original's (fx_source, isf.h).
  static String source(String w) => File(w).existsSync() ? w : w.replaceFirstMapped(RegExp(r'~[0-9]+(\.[^./]+)$'), (x) => x[1]!);
}

class _FxCodeState extends State<FxCode> {
  String? _mine;   // (the copy said, until the inside has it as the thing's)

  static String get _own => '${EffectTiles.own}/programs/fx/';

  /// Whether the file is this thing's card's alone: one of its own copies, said by no other card of any thing.
  bool _alone(String word) {
    final m = widget.ws.inside!, file = FxCode.source(word);
    if (!file.startsWith(_own)) return false;
    for (final t in m.things) {
      for (final w in Ws.fxFiles(m.word(t, 'fx'))) {
        if (!(t == widget.thing && w == word) && FxCode.source(w) == file) return false;
      }
    }
    return true;
  }

  void _write(String text) {
    final ws = widget.ws, m = ws.inside!, word = _mine ?? widget.word;
    var file = FxCode.source(word);
    if (!_alone(word)) {
      final from = file, dir = '$_own${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
      Directory(dir).createSync(recursive: true);
      _beside(from, word, dir);
      file = '$dir/${from.split('/').last}';
      final said = '$dir/${word.split('/').last}';
      File(file).writeAsStringSync(text);
      _mine = said;
      final fx = [for (final w in Ws.fxFiles(m.word(widget.thing, 'fx'))) w == word ? said : w].join(' ');   // (as doc_fx_join says it)
      m.later('say', thing: widget.thing, name: 'fx', word: fx);
    } else {
      File(file).writeAsStringSync(text);
    }
    ws.after(m.later('code', word: file), (done, why) {
      if (!done) ws.notice = why;
      ws.reread();
    });
  }

  /// What the engine reads beside the file, copied beside the copy.
  static void _beside(String from, String word, String dir) {
    final home = from.substring(0, from.lastIndexOf('/'));
    if (from.endsWith('.fs')) {
      final vs = File(from.replaceFirst(RegExp(r'\.fs$'), '.vs'));
      if (vs.existsSync()) vs.copySync('$dir/${vs.path.split('/').last}');
    }
    final first = File('$home/first.tsv'), name = word.split('/').last;
    if (first.existsSync()) {
      final lines = [for (final l in first.readAsLinesSync()) if (l.split('\t').first == name) l];
      if (lines.isNotEmpty) File('$dir/first.tsv').writeAsStringSync('${lines.join('\n')}\n');
    }
    for (final l in File(from).readAsLinesSync()) {
      final image = RegExp(r'^//.*--image@[^:]*:(.+)$').firstMatch(l)?[1]?.trim();
      if (image == null || image.startsWith('/') || !File('$home/$image').existsSync()) continue;
      File('$dir/$image').parent.createSync(recursive: true);
      File('$home/$image').copySync('$dir/$image');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mine == widget.word) _mine = null;
    return ProgramCode(FxCode.source(_mine ?? widget.word), _write);
  }
}
