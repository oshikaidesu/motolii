// The line under an After Effects expression's cell in the Code tab: what the expression gave at the playhead, or why
// it failed, as After Effects shows an expression's error under it and a browser's console shows a value as it is
// typed. The engine keeps what the expression last gave or threw (`__ae_last`, engine/community/sites/adapter.cpp);
// the line asks the running expression for it each time the playhead moves or the code is written, one question at a
// time.
//
// An error is written as After Effects writes it, "Error at line 3: ReferenceError: amp is not defined". For a name
// that is not defined there is a quick fix, as VS Code puts one beside an error: Add slider "amp" does what After
// Effects' Slider Control and pick whip do, a slider named amp that the expression reads.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip;
import 'package:motolii/widgets/number_field.dart' show NumberField;
import 'package:motolii/workspace/code/expression_reference.dart'
    show expressionReference;
import 'package:motolii/workspace/shelf/code_field.dart' show CodeMark;
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// What the expression of the code file [file] gives at the playhead. Nothing is shown for code that is not an After
/// Effects expression. [write] writes new code for the cell, for a quick fix.
class ExpressionResult extends StatefulWidget {
  const ExpressionResult(this.file, {super.key, this.write, this.mark})
    : onlyError = false;

  /// Only a red "Error" when the expression fails, for a folded cell's head, as After Effects puts a warning beside
  /// the property in the Timeline and VS Code marks a file's tab.
  const ExpressionResult.mark(this.file, {super.key})
    : write = null,
      mark = null,
      onlyError = true;
  final bool onlyError;
  final String file;
  final ValueChanged<String>? write;

  /// Set to the name that is not defined, where it is in the code, for the editor to underline it.
  final ValueNotifier<CodeMark?>? mark;
  @override
  State<ExpressionResult> createState() => _ExpressionResultState();
}

class _ExpressionResultState extends State<ExpressionResult> {
  Map<String, dynamic>? _last;
  bool _asking = false;
  String? _askedFor;
  Timer? _again;

  @override
  void dispose() {
    _again?.cancel();
    super.dispose();
  }

  /// The frame, how many times the document was read and the time the code was written: the answer changes when any
  /// does (a slider typed into changes the document, not the frame). Not each new snapshot: asking makes one.
  String _key(int frame) {
    final f = File(widget.file);
    return '$frame $_reads ${f.existsSync() ? f.lastModifiedSync().microsecondsSinceEpoch : 0}';
  }

  int _reads = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reads++;
  }

  void _ask(WorkspaceController ws, int frame, [int tries = 0]) {
    final m = ws.inside, key = _key(frame);
    if (m == null || _asking || (_askedFor == key && tries == 0)) return;
    _asking = true;
    _askedFor = key;
    // What the expression gave at the playhead's time (the engine keeps it per time, in milliseconds); an error is
    // shown whenever it came, since a failed expression is not run again.
    final ms = (frame / WorkspaceController.fps * 1000).round();
    m
        .askScript(
          widget.file,
          '(() => { const a = globalThis.__ae_at, v = a && a.get($ms), l = globalThis.__ae_last; '
          // (NaN and Infinity as JavaScript writes them, as a console shows them: JSON would make them null)
          'return JSON.stringify(v || (l && l.error ? l : null), '
          '(k, x) => typeof x === "number" && !isFinite(x) ? String(x) : x); })()',
        )
        .then((said) {
          _asking = false;
          if (!mounted) return;
          final last = said.isEmpty ? null : jsonDecode(said);
          if (last is Map<String, dynamic>) {
            setState(() => _last = last);
            _markMissing();
          } else if (tries < 10 && File(widget.file).existsSync()) {
            // The engine has not run that time yet: what was shown stays, and it is asked again.
            _again?.cancel();
            _again = Timer(const Duration(milliseconds: 100), () {
              if (mounted && _askedFor == key) _ask(ws, frame, tries + 1);
            });
            return;
          } else {
            setState(() => _last = null);
            _markMissing();
          }
          // The playhead moved, or the code was written, while the question was out.
          if (_key(ws.frame) != key) _ask(ws, ws.frame);
        });
  }

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.read(context),
        frame = WorkspaceScope.frameOf(context);
    WorkspaceScope.of(context, {WorkspaceAspect.document});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ask(ws, frame);
    });
    final last = _last;
    if (last == null) return const SizedBox.shrink();
    if (widget.onlyError) {
      return last['error'] == null
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.only(right: Shape.s(8)),
              child: Text(
                'Error',
                key: const ValueKey('code-head-error'),
                style: TextStyles.micro(Role.error),
              ),
            );
    }
    final on = '${last['on'] ?? ''}';
    final error = last['error'];
    if (error != null) return _error('$error');
    final name = on.isEmpty ? 'Value' : on[0].toUpperCase() + on.substring(1);
    final at = ws.timecode(
      ((last['time'] as num? ?? 0) * WorkspaceController.fps).round(),
    );
    return Padding(
      padding: EdgeInsets.only(top: Shape.s(4)),
      child: Text(
        '$name = ${_said(last['value'], on)}   at $at',
        key: const ValueKey('code-result'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyles.value(Grey.g63),
      ),
    );
  }

  String get _code => File(widget.file).existsSync()
      ? File(widget.file).readAsStringSync()
      : '';

  /// The name the error says is not defined.
  static String? _missing(Object? error) => error == null
      ? null
      : RegExp(r"""^ReferenceError: '?([A-Za-z_$][\w$]*)'? is not defined""")
            .firstMatch('$error')
            ?.group(1);

  void _markMissing() {
    final mark = widget.mark;
    if (mark == null) return;
    final missing = _missing(_last?['error']);
    mark.value = missing == null ? null : _whereIn(_code, missing);
  }

  Widget _error(String error) {
    final code = _code, missing = _missing(error);
    final line = missing == null ? null : _whereIn(code, missing)?.line;
    final write = widget.write;
    // A name After Effects has (the reference) is not the user's own slip: no slider is offered for it.
    final theirs =
        missing != null && expressionReference.any((e) => e.name == missing);
    return Padding(
      padding: EdgeInsets.only(top: Shape.s(4)),
      child: Row(
        children: [
          Flexible(
            child: Text(
              '${line == null ? 'Error' : 'Error at line $line'}: $error'
              '${theirs ? ' (After Effects has $missing; Motolii does not run it yet)' : ''}',
              key: const ValueKey('code-result'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.label(Role.error),
            ),
          ),
          if (missing != null && !theirs && write != null) ...[
            SizedBox(width: Shape.s(8)),
            Chip(
              key: const ValueKey('code-fix'),
              label: 'Add slider "$missing"',
              onTap: () {
                write(withSlider(code, missing));
                // The new slider's value takes the cursor, so that its first number is typed at once.
                NumberField.typeInto('js_$missing');
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// [name] as a name in code: not part of a longer name, not after a dot, not in quotes.
RegExp _named(String name) =>
    RegExp('(?<![\\w\$.\'"])${RegExp.escape(name)}(?![\\w\$\'"])');

bool _comment(String line) => line.trimLeft().startsWith('//');

/// Where [name] is first named outside a comment: the line, counted from 1, and its columns.
CodeMark? _whereIn(String code, String name) {
  final lines = const LineSplitter().convert(code);
  for (var i = 0; i < lines.length; i++) {
    if (_comment(lines[i])) continue;
    if (_named(name).firstMatch(lines[i]) case final m?) {
      return (line: i + 1, from: m.start, to: m.end);
    }
  }
  return null;
}

/// [code] with a slider named [name]: the head line Motolii reads for a slider (`// --track@name:label,min,max,start,step`,
/// AviUtl2's form; engine/community/quickjs/script.h), and above the code one line that reads it into [name], as After
/// Effects tutorials write `var amp = effect("amp")("Slider");` and VS Code's "Declare variable" fix adds one line.
/// The posted lines are left as they are (the code is run as posted, not rewritten). 0 to 100 starting at 0 is a new
/// Slider Control's own range in After Effects.
String withSlider(String code, String name) {
  final lines = const LineSplitter().convert(code);
  var head = 0;
  while (head < lines.length && lines[head].trimLeft().startsWith('//')) {
    head++;
  }
  return [
    ...lines.take(head),
    '// --track@$name:$name,0,100,0,1',
    'var $name = effect("$name")("Slider");',
    ...lines.skip(head),
  ].join('\n');
}

/// A value as After Effects writes it in the Timeline: numbers to one decimal place, a list in brackets, with the
/// property's unit.
String _said(Object? value, String on) {
  String one(Object? v) => v is num ? v.toStringAsFixed(1) : '$v';
  final unit = switch (on) {
    'rotation' => '°',
    'scale' || 'opacity' => '%',
    _ => '',
  };
  return value is List
      ? '[${value.map(one).join(', ')}]$unit'
      : '${one(value)}$unit';
}
