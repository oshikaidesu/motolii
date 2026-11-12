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
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// What the expression of the code file [file] gives at the playhead. Nothing is shown for code that is not an After
/// Effects expression. [write] writes new code for the cell, for a quick fix.
class ExpressionResult extends StatefulWidget {
  const ExpressionResult(this.file, {super.key, this.write});
  final String file;
  final ValueChanged<String>? write;
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

  /// The frame and the time the code was written: the answer changes when either does.
  String _key(int frame) {
    final f = File(widget.file);
    return '$frame ${f.existsSync() ? f.lastModifiedSync().microsecondsSinceEpoch : 0}';
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
          'return JSON.stringify(v || (l && l.error ? l : null)); })()',
        )
        .then((said) {
          _asking = false;
          if (!mounted) return;
          final last = said.isEmpty ? null : jsonDecode(said);
          if (last is Map<String, dynamic>) {
            setState(() => _last = last);
          } else if (tries < 10 && File(widget.file).existsSync()) {
            // The engine has not run that time yet: what was shown stays, and it is asked again.
            _again?.cancel();
            _again = Timer(const Duration(milliseconds: 100), () {
              if (mounted && _askedFor == key) _ask(ws, frame, tries + 1);
            });
            return;
          } else {
            setState(() => _last = null);
          }
          // The playhead moved, or the code was written, while the question was out.
          if (_key(ws.frame) != key) _ask(ws, ws.frame);
        });
  }

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.read(context),
        frame = WorkspaceScope.frameOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ask(ws, frame);
    });
    final last = _last;
    if (last == null) return const SizedBox.shrink();
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

  Widget _error(String error) {
    final code = File(widget.file).existsSync()
        ? File(widget.file).readAsStringSync()
        : '';
    final missing = RegExp(
      r"""^ReferenceError: '?([A-Za-z_$][\w$]*)'? is not defined""",
    ).firstMatch(error)?.group(1);
    final line = missing == null ? null : _lineOf(code, missing);
    final write = widget.write;
    return Padding(
      padding: EdgeInsets.only(top: Shape.s(4)),
      child: Row(
        children: [
          Flexible(
            child: Text(
              line == null ? 'Error: $error' : 'Error at line $line: $error',
              key: const ValueKey('code-result'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.label(Role.error),
            ),
          ),
          if (missing != null && write != null) ...[
            SizedBox(width: Shape.s(8)),
            Chip(
              key: const ValueKey('code-fix'),
              label: 'Add slider "$missing"',
              onTap: () => write(withSlider(code, missing)),
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

/// The line, counted from 1, where [name] is first named outside a comment.
int? _lineOf(String code, String name) {
  final lines = const LineSplitter().convert(code);
  for (var i = 0; i < lines.length; i++) {
    if (!_comment(lines[i]) && _named(name).hasMatch(lines[i])) return i + 1;
  }
  return null;
}

/// [code] with a slider named [name] added to its head and every [name] in it reading that slider, as After Effects'
/// pick whip writes `effect("Slider Control")("Slider")`. The head line is the one Motolii reads for a slider
/// (`// --track@name:label,min,max,start,step`, AviUtl2's form; engine/community/quickjs/script.h); 0 to 100 starting
/// at 0 is a new Slider Control's own range in After Effects.
String withSlider(String code, String name) {
  final lines = const LineSplitter().convert(code);
  var head = 0;
  while (head < lines.length && lines[head].trimLeft().startsWith('//')) {
    head++;
  }
  final read = 'effect("$name")("Slider")';
  return [
    ...lines.take(head),
    '// --track@$name:$name,0,100,0,1',
    for (final l in lines.skip(head))
      _comment(l) ? l : l.replaceAll(_named(name), read),
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
