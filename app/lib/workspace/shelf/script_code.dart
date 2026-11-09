// A thing's script on its Script card, under its knobs: After Effects shows an expression under the value it drives, and
// the Repeater and the AE recipes are expressions (docs/reports/ae_expression_drawbacks_2026-11-08.md). The code view is the
// Program shelf's (re_editor's CodeEditor, MIT). What is typed is this thing's alone, as an AE expression is one
// property's: the file it came from is never written over; the first typing copies it to a folder of its own in the
// maker's programs (programs/script/<stamp>/, as an effect's code: fx_code.dart), where the Program shelf does not list
// it, and the thing is said to that copy. Its knobs' values stay: they are the thing's, by their names (js_StepX…),
// whichever file says them.
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../dock/dock_program.dart' show ProgramCode;
import 'effect_tiles.dart' show EffectTiles;
import '../ws.dart';

class ScriptCode extends StatefulWidget {
  const ScriptCode(this.ws, this.thing, {super.key});
  final Ws ws;
  final int thing;
  @override
  State<ScriptCode> createState() => _ScriptCodeState();
}

class _ScriptCodeState extends State<ScriptCode> {
  String? _mine;   // (the copy written and said, until the inside has it as the thing's script)

  String get _said => widget.ws.inside!.word(widget.thing, 'script');

  /// The file name the code came from, kept on the copy ('repeater.js').
  String get _name => _said.substring(_said.lastIndexOf('/') + 1);

  static String get _own => '${EffectTiles.own}/programs/script/';

  void _write(String text) {
    final ws = widget.ws, m = ws.inside!, said = _said;
    var to = _mine ?? said;
    if (!to.startsWith(_own)) {
      final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      to = '$_own$stamp/$_name';
      Directory('$_own$stamp').createSync(recursive: true);
    }
    File(to).writeAsStringSync(text);
    if (to != said) {
      _mine = to;
      m.later('say', thing: widget.thing, name: 'script', word: to);
    }
    ws.after(m.later('code', word: to), (done, why) {
      if (!done) ws.notice = why;   // (half typed: what ran stays, doc_script_of)
      ws.reread();
    });
  }

  @override
  Widget build(BuildContext context) {
    final said = _said;
    if (_mine == said) _mine = null;
    return ProgramCode(_mine ?? said, _write);
  }
}
