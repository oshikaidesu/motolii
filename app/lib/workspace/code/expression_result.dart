// The line under an After Effects expression's cell in the Code tab: what the expression gave at the playhead, or why
// it failed, as After Effects shows an expression's error under it and a browser's console shows a value as it is
// typed. The engine keeps what the expression last gave or threw (`__ae_last`, engine/community/sites/adapter.cpp);
// the line asks the running expression for it each time the playhead moves, one question at a time.
import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// What the expression of the code file [file] gives at the playhead. Nothing is shown for code that is not an After
/// Effects expression.
class ExpressionResult extends StatefulWidget {
  const ExpressionResult(this.file, {super.key});
  final String file;
  @override
  State<ExpressionResult> createState() => _ExpressionResultState();
}

class _ExpressionResultState extends State<ExpressionResult> {
  Map<String, dynamic>? _last;
  bool _asking = false;
  int? _askedAt;

  void _ask(WorkspaceController ws, int frame) {
    final m = ws.inside;
    if (m == null || _asking || _askedAt == frame) return;
    _asking = true;
    _askedAt = frame;
    m
        .askScript(
          widget.file,
          'JSON.stringify(typeof __ae_last === "object" ? __ae_last : null)',
        )
        .then((said) {
          _asking = false;
          if (!mounted) return;
          final last = said.isEmpty ? null : jsonDecode(said);
          setState(() => _last = last is Map<String, dynamic> ? last : null);
          // The playhead moved while the question was out.
          final now = ws.frame;
          if (now != frame) _ask(ws, now);
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
    final name = on.isEmpty ? 'Value' : on[0].toUpperCase() + on.substring(1);
    final at = ws.timecode(
      ((last['time'] as num? ?? 0) * WorkspaceController.fps).round(),
    );
    final error = last['error'];
    return Padding(
      padding: EdgeInsets.only(top: Shape.s(4)),
      child: Text(
        error != null
            ? 'Error at $at: $error'
            : '$name = ${_said(last['value'], on)}   at $at',
        key: const ValueKey('code-result'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: error != null
            ? TextStyles.label(Role.error)
            : TextStyles.value(Grey.g63),
      ),
    );
  }
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
