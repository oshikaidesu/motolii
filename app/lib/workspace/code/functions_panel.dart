// The Functions list of the Code tab: what the code of the cell beside it may say, each name with the line that says
// what it does. Pressing a name writes it where the cursor is.
//
// For an After Effects expression the names and their words are After Effects' own reference (expression_reference.dart)
// and the groups are After Effects' objects (Layer, Property, Comp…). Which names run here is asked of the running
// script each time its file changes, so the list cannot drift from the engine: a name the runtime lacks is listed
// last in its group and marked, because posted code uses it and the mark is the order in which to make them run.
// For any other script the list is the functions its runtime adds to JavaScript's own, also asked, names only.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/disclosure_triangle.dart';
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/workspace/code/expression_reference.dart';
import 'package:motolii/workspace/shelf/code_field.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The Functions list for the code file [file], or for no cell when it is null.
class FunctionsPanel extends StatefulWidget {
  const FunctionsPanel(this.file, {super.key});
  final String? file;
  @override
  State<FunctionsPanel> createState() => _FunctionsPanelState();
}

class _FunctionsPanelState extends State<FunctionsPanel> {
  /// The file and its time of writing that the answers below are for.
  String? _askedFor;

  /// What the running expression has of the reference (`Layer.wiggle` to `bare` or `member`); null for a script that
  /// is not an After Effects expression, and before the answer has come.
  Map<String, String>? _runs;

  /// The functions the script's runtime adds to JavaScript's own.
  List<String> _adds = const [];
  bool _answered = false;
  String _query = '';
  final _folded = <String>{};

  void _ask() {
    final m = WorkspaceScope.read(context).inside, file = widget.file;
    if (m == null || file == null || !File(file).existsSync()) return;
    final key = '$file ${File(file).lastModifiedSync().microsecondsSinceEpoch}';
    if (key == _askedFor) return;
    _askedFor = key;
    Future.wait([
      m.askScript(file, runsHere(expressionReference)),
      m.askScript(file, runtimeAdds),
    ]).then((said) {
      if (!mounted || _askedFor != key) return;
      setState(() {
        _answered = true;
        _runs = said[0].isEmpty
            ? null
            : {
                for (final e
                    in (jsonDecode(said[0]) as Map<String, dynamic>).entries)
                  e.key: e.value as String,
              };
        _adds = said[1].isEmpty
            ? const []
            : [
                for (final n in jsonDecode(said[1]) as List<dynamic>)
                  n as String,
              ];
      });
    });
  }

  bool _hit(String name, String about) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        name.toLowerCase().contains(q) ||
        about.toLowerCase().contains(q);
  }

  /// What pressing [e] writes: the name with the arguments that must be given, reached through its object unless
  /// the expression can say it alone.
  String _written(ReferenceEntry e, String how, Map<String, String> roots) {
    final said = e.calls
        ? '${e.name}(${[for (final a in e.signature.substring(e.name.length + 1, e.signature.length - 1).split(', '))
            if (a.isNotEmpty && !a.endsWith('?')) a].join(', ')})'
        : e.name;
    final root = (roots[e.owner] ?? '')
        .replaceAll('?.(', '(')
        .replaceAll('?.', '.');
    return how == 'bare' || root.isEmpty ? said : '$root.$said';
  }

  @override
  Widget build(BuildContext context) {
    _ask();
    final runs = _runs;
    final roots = referenceRoots(expressionReference);
    // First what the expression is handed, in the order After Effects looks a bare name up: its property, then its
    // layer (ae-expressions.docsforadobe.dev), then the comp; then the other objects in the reference's order. A group
    // with nothing that runs here goes last.
    final all = <String>['Property', 'Layer', 'Comp'];
    for (final e in expressionReference) {
      if (!all.contains(e.owner)) all.add(e.owner);
    }
    bool some(String o) => runs?.keys.any((k) => k.startsWith('$o.')) ?? true;
    final owners = [...all.where(some), ...all.where((o) => !some(o))];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Search((q) => setState(() => _query = q)),
        Expanded(
          child: widget.file == null
              ? const _Note('Open a cell to see what its code may say.')
              : !_answered
              ? const _Note('Asking the running code…')
              : ListView(
                  padding: EdgeInsets.only(bottom: Shape.s(8)),
                  children: [
                    if (runs == null && _adds.isEmpty)
                      const _Note(
                        'This code does not run as a script here, so there is no list of what it may say yet.',
                      ),
                    if (runs != null)
                      for (final owner in owners) ..._group(owner, runs, roots),
                    if (runs == null && _adds.isNotEmpty) ...[
                      _Head(
                        'This script\'s runtime',
                        '${_adds.length}',
                        open: !_folded.contains('runtime'),
                        onTap: () => setState(
                          () => _folded.contains('runtime')
                              ? _folded.remove('runtime')
                              : _folded.add('runtime'),
                        ),
                      ),
                      if (!_folded.contains('runtime'))
                        for (final n in _adds)
                          if (_hit(n, ''))
                            _Row(
                              '$n()',
                              '',
                              runs: true,
                              onTap: () => CodeField.insert('$n()'),
                            ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  /// One object's names: those that run here in the reference's order, then those that do not run yet.
  List<Widget> _group(
    String owner,
    Map<String, String> runs,
    Map<String, String> roots,
  ) {
    final all = [
      for (final e in expressionReference)
        if (e.owner == owner && _hit(e.name, e.about)) e,
    ];
    if (all.isEmpty) return const [];
    final here = [
      for (final e in all)
        if (runs.containsKey('$owner.${e.name}')) e,
    ];
    final open = _query.trim().isNotEmpty
        ? true
        : here.isEmpty
        ? _folded.contains('open:$owner')
        : !_folded.contains(owner);
    return [
      _Head(
        owner,
        here.length == all.length
            ? '${all.length}'
            : '${here.length} of ${all.length} run',
        open: open,
        onTap: () => setState(() {
          // A group with nothing that runs starts folded.
          final key = here.isEmpty ? 'open:$owner' : owner;
          _folded.contains(key) ? _folded.remove(key) : _folded.add(key);
        }),
      ),
      if (open) ...[
        for (final e in here)
          _Row(
            e.signature,
            e.about,
            runs: true,
            onTap: () =>
                CodeField.insert(_written(e, runs['$owner.${e.name}']!, roots)),
          ),
        for (final e in all)
          if (!runs.containsKey('$owner.${e.name}'))
            _Row(e.signature, e.about, runs: false),
      ],
    ];
  }
}

/// The search field over the list, the app's standard text field in a well.
class _Search extends StatelessWidget {
  const _Search(this.onQuery);
  final ValueChanged<String> onQuery;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      WindowTokens.inset,
      Shape.s(6),
      WindowTokens.inset,
      Shape.s(4),
    ),
    child: Container(
      height: Shape.z(24),
      padding: EdgeInsets.symmetric(horizontal: Shape.s(7)),
      decoration: BoxDecoration(
        color: WindowTokens.well,
        borderRadius: BorderRadius.all(Shape.r(WindowTokens.radius)),
      ),
      child: Row(
        children: [
          Glyph(AppGlyphs.search, size: Shape.z(11), color: Grey.g56),
          SizedBox(width: Shape.s(6)),
          Expanded(
            child: TypedField(
              key: const ValueKey('code-functions-search'),
              text: '',
              style: TextStyles.name(Grey.g95),
              cursor: WindowTokens.accent,
              standing: true,
              onDone: (_) {},
              onPick: (v) => onQuery(v.text),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A group's head: its name, how many of its names run, and a triangle that folds it.
class _Head extends StatelessWidget {
  const _Head(
    this.title,
    this.count, {
    required this.open,
    required this.onTap,
  });
  final String title, count;
  final bool open;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (_, hot) => Container(
      key: ValueKey('code-functions-group:$title'),
      height: Shape.z(22),
      padding: EdgeInsets.symmetric(horizontal: WindowTokens.inset),
      child: Row(
        children: [
          DisclosureTriangle(open: open, hot: hot),
          SizedBox(width: Shape.s(6)),
          Text(
            title,
            style: TextStyles.label(hot ? Grey.g95 : Grey.g91)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(count, style: TextStyles.micro(Grey.g56)),
        ],
      ),
    ),
  );
}

/// One name: how it is written, and under it what it does. A name that does not run yet is dim and says so.
class _Row extends StatelessWidget {
  const _Row(this.signature, this.about, {required this.runs, this.onTap});
  final String signature, about;
  final bool runs;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
    builder: (_, hot) => Container(
      key: ValueKey('code-function:$signature'),
      padding: EdgeInsets.fromLTRB(
        WindowTokens.inset + Shape.s(14),
        Shape.s(3),
        WindowTokens.inset,
        Shape.s(3),
      ),
      color: hot && runs ? WindowTokens.raised : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  signature,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.value(runs ? Grey.g95 : Grey.g56),
                ),
              ),
              if (!runs)
                Text('does not run yet', style: TextStyles.micro(Grey.g56)),
            ],
          ),
          if (about.isNotEmpty)
            Text(
              about,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.label(runs ? Grey.g63 : Grey.g44),
            ),
        ],
      ),
    ),
  );
}

/// A line that says why the list is empty.
class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(Shape.s(16)),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyles.label(Grey.g63),
    ),
  );
}
