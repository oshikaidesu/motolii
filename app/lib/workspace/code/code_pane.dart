// The Code tab: a cell per card of the selected layer that has code, in the order they act.
// Each cell shares its text with the Inspector card; typing here moves sliders.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/values_card.dart' show CardBin, CardGrip;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/shelf_meta.dart' show shelfMetaOfFile;
import 'package:motolii/storage/text_file.dart' show readText;
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/text_gestures.dart' show TypedField;
import 'package:motolii/widgets/disclosure_triangle.dart';
import 'package:motolii/widgets/glyphs.dart' show Glyph;
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/widgets/timeline_painters.dart' show TimelineGlyphs;
import 'package:motolii/workspace/code/expression_result.dart';
import 'package:motolii/workspace/code/functions_panel.dart';
import 'package:motolii/workspace/dock/common/shelf_tags.dart';
import 'package:motolii/workspace/inspector_feed/cards.dart';
import 'package:motolii/workspace/shelf/code_field.dart' show CodeField;
import 'package:motolii/workspace/shelf/effect_code.dart';
import 'package:motolii/workspace/shelf/empty_effect.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart' show ShelfNameField;
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/tiles/effect_code_cards.dart'
    show codeNameRefused;
import 'package:motolii/workspace/state/inspector/inspector_actions.dart'
    show effectTitles, effectsOff, moveEffect, removeCard, toggleEffect;
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The Code tab: the selected layer's code, a cell for each card that has code.
class CodePane extends StatefulWidget {
  const CodePane({super.key});
  @override
  State<CodePane> createState() => _CodePaneState();
}

class _CodePaneState extends State<CodePane> {
  /// The view state that keeps the height each cell was dragged to.
  static const _heights = 'code.heights';

  /// One key for each cell on screen, by layer and card, so a cell that was asked for can be scrolled to.
  final _cells = <String, GlobalKey>{};

  /// The request last scrolled to (EffectCode.asked), so each request scrolls once.
  (String, int)? _shown;

  /// Why a new expression was refused, shown under the cells until the next try.
  String _why = '';

  /// The cell whose name is being typed, by layer and card.
  String? _naming;

  /// Names the card [was] of layer [t] [to]; null leaves it as it is. What the window keeps by the card's name (its
  /// cell folded, its height, the card switched off) is kept for the new name.
  void _name(
    WorkspaceController ws,
    int t,
    String was,
    EffectCode code,
    String? to,
    Iterable<String> taken,
    bool off,
  ) {
    setState(() => _naming = null);
    final name = to?.trim();
    if (name == null || name == was) return;
    if (codeNameRefused(name, taken) case final why when why.isNotEmpty) {
      ws.notice = why;
      return;
    }
    // The engine knows a card that is off by its name (fx_off): it is put on under the old name and off under the new.
    if (off) toggleEffect(ws, t, was);
    code.rename(name, (done, why) {
      if (!done) {
        ws.notice = why;
        return;
      }
      final folded = ws.viewOf(EffectCode.folded, const <String>{}),
          heights = ws.viewOf(_heights, const <String, double>{});
      if (folded.contains(was)) {
        ws.setView(EffectCode.folded, {...folded, name}..remove(was));
      }
      if (heights['$t/$was'] case final h?) {
        ws.setView(_heights, {...heights, '$t/$name': h}..remove('$t/$was'));
      }
      if (off) toggleEffect(ws, t, name);
    });
  }

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
    final t = ws.selected;
    if (!projectOpen(ws) || t == null) {
      return const _Said(
        'Pick a layer. Its code opens here, one cell for each effect and expression.',
      );
    }
    final layer = ws.layers.where((l) => l.id == ws.selected).firstOrNull;
    // The height each cell was dragged to, by layer and card; a cell not in it is as tall as its code.
    final heights = ws.viewOf(_heights, const <String, double>{});
    final cards = valueCards(ws, ws.selected) ?? const <CardDeclaration>[];
    final cells = [
      for (final c in cards)
        if (EffectCode.ofCard(
              ws,
              t,
              c.name,
              [for (final p in c.params) p.id],
              fit: true,
              height: heights['$t/${c.name}'],
              onHeight: (h) => ws.setView(
                _heights,
                h == null
                    ? ({...heights}..remove('$t/${c.name}'))
                    : {...heights, '$t/${c.name}': h},
              ),
            )
            case final code?)
          (c.name, code, [for (final p in c.params) p.id]),
    ];
    // The layer's effects in the order they act. A cell of one of them can be moved, switched off and taken away,
    // as its card can in the Inspector; the Script card's cell is not among them.
    final stack = effectTitles(ws, t), off = effectsOff(ws, t);
    final folded = ws.viewOf(EffectCode.folded, const <String>{});
    final asked = ws.viewOf<(String, int)?>(EffectCode.asked, null);
    if (asked != null && asked != _shown) {
      _shown = asked;
      if (_cells['$t/${asked.$1}'] case final cell?) _scrollTo(cell);
    }
    // The cell the lists beside the code are for: the one last asked for if it is open, else the first open one.
    final open = [
      for (final (title, code, _) in cells)
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
                    .bold,
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
                      // Dragging a cell's head to another's place moves its effect there in the layer's stack.
                      ReorderableList(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cells.length,
                        onReorderItem: (from, to) {
                          final a = stack.indexOf(cells[from].$1),
                              b = stack.indexOf(cells[to].$1);
                          if (a < 0 || b < 0 || a == b) return;
                          moveEffect(ws, t, cells[from].$1, b - a);
                        },
                        itemBuilder: (context, i) {
                          final (title, code, names) = cells[i];
                          final effect = stack.contains(title);
                          return _Cell(
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
                            naming: _naming == '$t/$title'
                                ? ShelfNameField(
                                    title,
                                    (to) => _name(ws, t, title, code, to, [
                                      for (final c in cards) c.name,
                                    ], off.contains(title)),
                                    small: false,
                                  )
                                : null,
                            onName: code.named
                                ? () => setState(() => _naming = '$t/$title')
                                : null,
                            at: effect && stack.length > 1 ? i : null,
                            off: off.contains(title),
                            onEye: effect
                                ? () => toggleEffect(ws, t, title)
                                : null,
                            onRemove: () => removeCard(ws, t, title, names),
                          );
                        },
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
                  // A press in the list writes into the code, so it does not take the keys from it (CodeField).
                  child: TapRegion(
                    groupId: CodeField,
                    child: FunctionsPanel(
                      beside == null ? null : EffectCode.source(beside.$2.word),
                    ),
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

/// One cell: a head with the card's title and what its code is on or written in, and under it the code, unless folded.
class _Cell extends StatefulWidget {
  const _Cell(
    this.title,
    this.code, {
    super.key,
    required this.open,
    required this.onFold,
    required this.naming,
    required this.onName,
    required this.at,
    required this.off,
    required this.onEye,
    required this.onRemove,
  });
  final String title;
  final EffectCode code;
  final bool open;
  final VoidCallback onFold;

  /// The field the name is typed in while the card is being named, and what starts the naming when the name is
  /// pressed twice; null for a card whose name is not the user's to give (an ISF's, the Script card's).
  final Widget? naming;
  final VoidCallback? onName;

  /// The cell's place among the cells when its head can be dragged to another place; null when it cannot.
  final int? at;

  /// Whether the card is switched off, and what switches it on and off; null for a card with no eye (the Script card).
  final bool off;
  final VoidCallback? onEye;
  final VoidCallback onRemove;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  bool _tagging = false;
  String _typed = '';

  /// What the head says beside the title: the property an After Effects expression is on
  /// names it under the layer (`// --property:rotation` says Expression: Rotation, read as engine/community/sites/adapter.cpp
  /// reads it); for any other code, what it is written in, said by the file's ending.
  String get _on {
    final text = readText(EffectCode.source(widget.code.word)) ?? '';
    final named = RegExp(r'//\s*--property:\s*(\w+)')
        .firstMatch(text)
        ?.group(1);
    if (named != null && named.isNotEmpty) {
      return 'Expression: ${named[0].toUpperCase()}${named.substring(1)}';
    }
    return switch (widget.code.word.split('.').last) {
      'wgsl' => 'WGSL',
      'fs' => 'GLSL',
      _ => 'JavaScript',
    };
  }

  /// The head: a press folds the cell, a drag moves it. Its eye and bin are the card's in the Inspector.
  Widget _head() => Container(
    height: Shape.z(26),
    padding: EdgeInsets.symmetric(horizontal: WindowTokens.inset),
    decoration: BoxDecoration(
      color: WindowTokens.card,
      border: Border(top: BorderSide(color: WindowTokens.line)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Pressable(
            onTap: widget.onFold,
            builder: (_, hot) => Row(
              key: ValueKey('code-cell-head:${widget.title}'),
              children: [
                DisclosureTriangle(open: widget.open, hot: hot),
                SizedBox(width: Shape.s(6)),
                if (widget.naming case final field?)
                  SizedBox(
                    width: Shape.z(180),
                    height: Shape.s(18),
                    child: field,
                  )
                else
                  Flexible(
                    child: GestureDetector(
                      key: ValueKey('code-cell-name:${widget.title}'),
                      onDoubleTap: widget.onName,
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.name(
                          widget.off ? Grey.g56 : (hot ? Grey.g95 : Grey.g91),
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                if (!widget.open)
                  ExpressionResult.mark(EffectCode.source(widget.code.word)),
                Text(_on, style: TextStyles.micro(Grey.g56)),
                SizedBox(width: Shape.s(10)),
              ],
            ),
          ),
        ),
        if (widget.onEye case final eye?)
          Pressable(
            key: ValueKey(
              'code-cell-${widget.off ? 'show' : 'hide'}:${widget.title}',
            ),
            onTap: eye,
            builder: (_, h) => Padding(
              padding: EdgeInsets.only(right: Shape.s(6)),
              child: Glyph(
                widget.off ? TimelineGlyphs.eyeOff : TimelineGlyphs.eye,
                size: 12,
                color: h ? Grey.g95 : Grey.g56,
                fade: true,
              ),
            ),
          ),
        CardBin(
          widget.onRemove,
          key: ValueKey('code-cell-remove:${widget.title}'),
        ),
        if (widget.at != null) const CardGrip(),
      ],
    ),
  );

  /// The thin line under the head: author · licence, engine tags and user tags as chips.
  Widget? _metaRow() {
    final file = EffectCode.source(widget.code.word);
    final meta = shelfMetaOfFile(file);
    final tags = ShelfTags.shared;
    final userTags = tags.ownOf('Effects', widget.title);
    if ((meta == null || meta.isEmpty) && userTags.isEmpty && !_tagging) {
      return null;
    }
    final parts = <String>[
      if (meta != null && meta.author.isNotEmpty) 'by ${meta.author}',
      if (meta != null && meta.license.isNotEmpty) meta.license,
    ];
    return Container(
      padding: EdgeInsets.fromLTRB(
        WindowTokens.inset + Shape.s(18),
        0,
        WindowTokens.inset,
        Shape.s(4),
      ),
      child: Wrap(
        spacing: Shape.s(4),
        runSpacing: Shape.s(2),
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (parts.isNotEmpty)
            Text(parts.join(' · '), style: TextStyles.label(Grey.g44)),
          for (final t in userTags) _userChip(t),
          if (_tagging) _tagField() else _addTagButton(),
        ],
      ),
    );
  }

  Widget _userChip(String tag) => Pressable(
    onTap: () => setState(() {
      ShelfTags.shared.setOwn(
        'Effects',
        widget.title,
        ShelfTags.shared.ownOf('Effects', widget.title)..remove(tag),
      );
    }),
    builder: (_, hot) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: Shape.s(5),
        vertical: Shape.s(1),
      ),
      decoration: BoxDecoration(
        color: hot ? Grey.g26 : Grey.g20,
        borderRadius: Shape.round(WindowTokens.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('#$tag', style: TextStyles.label(Grey.g63)),
          SizedBox(width: Shape.s(2)),
          Text('×', style: TextStyles.label(hot ? Grey.g76 : Grey.g44)),
        ],
      ),
    ),
  );

  Widget _addTagButton() => Pressable(
    onTap: () => setState(() => _tagging = true),
    builder: (_, hot) => Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Shape.s(5),
        vertical: Shape.s(1),
      ),
      child: Text('+', style: TextStyles.label(hot ? Grey.g76 : Grey.g44)),
    ),
  );

  void _addTag(String text) {
    final tag = text.trim().toLowerCase().replaceFirst(RegExp(r'^#'), '');
    if (tag.isNotEmpty) {
      ShelfTags.shared.setOwn('Effects', widget.title, {
        ...ShelfTags.shared.ownOf('Effects', widget.title),
        tag,
      });
    }
    setState(() {
      _tagging = false;
      _typed = '';
    });
  }

  Widget _tagField() {
    final done = ShelfTags.shared.completing('Effects', _typed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: Shape.z(100),
          height: Shape.s(16),
          child: TypedField(
            key: ValueKey('code-cell-tag-input:${widget.title}'),
            text: '',
            style: TextStyles.label(Grey.g91),
            cursor: Grey.g76,
            take: true,
            escapes: true,
            onPick: (v) => setState(() => _typed = v.text),
            onDone: (said) =>
                said != null ? _addTag(said) : setState(() => _tagging = false),
          ),
        ),
        if (done.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: Shape.s(2)),
            child: Wrap(
              spacing: Shape.s(3),
              runSpacing: Shape.s(2),
              children: [
                for (final t in done)
                  Pressable(
                    onTap: () => _addTag(t),
                    builder: (_, h) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Shape.s(5),
                        vertical: Shape.s(1),
                      ),
                      decoration: BoxDecoration(
                        color: h ? Grey.g26 : Grey.g20,
                        borderRadius: Shape.round(WindowTokens.chipRadius),
                      ),
                      child: Text(t, style: TextStyles.label(Grey.g63)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.at case final i?)
        ReorderableDragStartListener(
          key: ValueKey('code-cell-drag:${widget.title}'),
          index: i,
          child: _head(),
        )
      else
        _head(),
      ?_metaRow(),
      if (widget.open)
        Padding(
          padding: EdgeInsets.fromLTRB(
            WindowTokens.inset,
            Shape.s(4),
            WindowTokens.inset,
            Shape.s(8),
          ),
          child: widget.code,
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
