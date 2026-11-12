// The Code tab: the code of the selected layer, one cell for each of its cards that has code, in the order the cards act.
//
// It opens beside the Timeline, so the preview stays in sight above it and a line of code has the width of the window.
// A cell is the card's own code (EffectCode, shelf/effect_code.dart): the card in the Inspector and its cell here are
// one text, and typing here moves the card's sliders. A cell is as tall as its code and the tab scrolls, as a
// notebook's cells do (Jupyter). Any number of cells stay open; pressing a cell's head folds it.
// "Edit code" on a card in the Inspector unfolds its cell and scrolls to it (EffectCode.show).
// Beside the cells is the list of what the code may say (functions_panel.dart), for the cell last asked for, or the
// first one open. The word "Functions" in the head hides and shows it.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/disclosure_triangle.dart';
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/workspace/code/functions_panel.dart';
import 'package:motolii/workspace/inspector_feed/cards.dart';
import 'package:motolii/workspace/shelf/effect_code.dart';
import 'package:motolii/workspace/shelf/empty_effect.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The Code tab: the selected layer's code, a cell for each card that has code.
class CodePane extends StatefulWidget {
  const CodePane({super.key});
  @override
  State<CodePane> createState() => _CodePaneState();
}

class _CodePaneState extends State<CodePane> {
  /// One key for each cell on screen, by layer and card, so a cell that was asked for can be scrolled to.
  final _cells = <String, GlobalKey>{};

  /// The request last scrolled to (EffectCode.asked), so each request scrolls once.
  (String, int)? _shown;

  /// Why a new expression was refused, shown under the cells until the next try.
  String _why = '';

  void _scrollTo(GlobalKey cell) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (cell.currentContext case final at?) {
          Scrollable.ensureVisible(
            at,
            duration: const Duration(milliseconds: 160),
          );
        }
      });

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {
      WorkspaceAspect.document,
      WorkspaceAspect.picked,
      WorkspaceAspect.view,
    });
    final t = int.tryParse(ws.selected ?? '');
    if (ws.inside == null || t == null) {
      return const _Said(
        'Pick a layer. Its code opens here, one cell for each effect and expression.',
      );
    }
    final layer = ws.layers.where((l) => l.id == ws.selected).firstOrNull;
    final cells = [
      for (final c in valueCards(ws, ws.selected) ?? const <CardDeclaration>[])
        if (EffectCode.ofCard(ws, t, c.name, [
              for (final p in c.params) p.id,
            ], fit: true)
            case final code?)
          (c.name, code),
    ];
    final folded = ws.viewOf(EffectCode.folded, const <String>{});
    final asked = ws.viewOf<(String, int)?>(EffectCode.asked, null);
    if (asked != null && asked != _shown) {
      _shown = asked;
      if (_cells['$t/${asked.$1}'] case final cell?) _scrollTo(cell);
    }
    // The cell the lists beside the code are for: the one last asked for if it is open, else the first open one.
    final open = [
      for (final (title, code) in cells)
        if (!folded.contains(title)) (title, code),
    ];
    final beside =
        open.where((c) => c.$1 == asked?.$1).firstOrNull ?? open.firstOrNull;
    final lists = ws.viewOf('code.functions', true);
    void add() {
      setState(() => _why = '');
      emptyPut(
        ws,
        expression: true,
        told: (why) {
          if (mounted) setState(() => _why = why);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelHeader(
          layer?.name ?? '',
          trailing: [
            Text(switch (cells.length) {
              0 => 'no code yet',
              1 => '1 card with code',
              final n => '$n cards with code',
            }, style: TextStyles.label(Grey.g56)),
            SizedBox(width: Shape.s(10)),
            Pressable(
              onTap: () => ws.setView('code.functions', !lists),
              builder: (_, hot) => Text(
                'Functions',
                key: const ValueKey('code-functions-toggle'),
                style: TextStyles.label(lists || hot ? Grey.g95 : Grey.g56)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (cells.isEmpty)
                        const _Said(
                          'Nothing on this layer has code yet. Put an expression or an effect on it from Create or Effects, paste code, or start an empty expression below.',
                        ),
                      for (final (title, code) in cells)
                        _Cell(
                          title,
                          code,
                          key: _cells.putIfAbsent('$t/$title', GlobalKey.new),
                          open: !folded.contains(title),
                          onFold: () => ws.setView(
                            EffectCode.folded,
                            folded.contains(title)
                                ? ({...folded}..remove(title))
                                : {...folded, title},
                          ),
                        ),
                      _AddRow('New expression', _why, add),
                    ],
                  ),
                ),
              ),
              if (lists) ...[
                Container(width: 1, color: WindowTokens.line),
                SizedBox(
                  width: Shape.z(300),
                  child: FunctionsPanel(
                    beside == null ? null : EffectCode.source(beside.$2.word),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One cell: a head with the card's title and the language of its code, and under it the code, unless folded.
class _Cell extends StatelessWidget {
  const _Cell(
    this.title,
    this.code, {
    super.key,
    required this.open,
    required this.onFold,
  });
  final String title;
  final EffectCode code;
  final bool open;
  final VoidCallback onFold;

  /// What the code is written in, said by the file's ending.
  String get _language => switch (code.word.split('.').last) {
    'wgsl' => 'WGSL',
    'fs' => 'GLSL',
    _ => 'JavaScript',
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Pressable(
        onTap: onFold,
        builder: (_, hot) => Container(
          key: ValueKey('code-cell-head:$title'),
          height: Shape.z(26),
          padding: EdgeInsets.symmetric(horizontal: WindowTokens.inset),
          decoration: BoxDecoration(
            color: WindowTokens.card,
            border: Border(top: BorderSide(color: WindowTokens.line)),
          ),
          child: Row(
            children: [
              DisclosureTriangle(open: open, hot: hot),
              SizedBox(width: Shape.s(6)),
              Text(title, style: TextStyles.name(hot ? Grey.g95 : Grey.g91)),
              const Spacer(),
              Text(_language, style: TextStyles.micro(Grey.g56)),
            ],
          ),
        ),
      ),
      if (open)
        Padding(
          padding: EdgeInsets.fromLTRB(
            WindowTokens.inset,
            Shape.s(4),
            WindowTokens.inset,
            Shape.s(8),
          ),
          child: code,
        ),
    ],
  );
}

/// The row under the cells that starts an empty expression on the layer; [why] is why the last try was refused.
class _AddRow extends StatelessWidget {
  const _AddRow(this.label, this.why, this.onTap);
  final String label, why;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (_, hot) => Container(
      key: const ValueKey('code-new-expression'),
      height: Shape.z(26),
      padding: EdgeInsets.symmetric(horizontal: WindowTokens.inset),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: WindowTokens.line)),
      ),
      child: Row(
        children: [
          Text('+  $label', style: TextStyles.label(hot ? Grey.g95 : Grey.g63)),
          if (why.isNotEmpty) ...[
            SizedBox(width: Shape.s(8)),
            Expanded(
              child: Text(
                why,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.label(Role.error),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// A line that says what is empty here and what to do.
class _Said extends StatelessWidget {
  const _Said(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(Shape.s(24)),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyles.label(Grey.g63),
    ),
  );
}
