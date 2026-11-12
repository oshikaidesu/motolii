// Completion in a cell's editor, as VS Code's IntelliSense completes a name as it is typed: the names an After Effects
// expression may use here, each with how it is written and what it does. The list and its keys (arrows, Enter) are
// re_editor's own CodeAutocomplete; the names are the Functions list's, from the reference and what the running
// expression has (expression_reference.dart), so the two cannot disagree.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/workspace/code/expression_reference.dart';

/// What completes a name in the editor: names said alone, names after an object (`thisComp.`), and for each prompt
/// the reference's entry that the list shows beside it.
class ExpressionPrompts {
  const ExpressionPrompts(this.direct, this.related, this.entries);
  final List<CodePrompt> direct;
  final Map<String, List<CodePrompt>> related;
  final Map<CodePrompt, ReferenceEntry> entries;

  /// The prompts for the names [runs] says the running expression has (`Layer.wiggle` to `bare` or `member`).
  factory ExpressionPrompts.of(Map<String, String> runs) {
    final roots = referenceRoots(expressionReference);
    // The objects an expression is handed by name, as `thisComp.` is typed.
    final handed = {
      for (final e in roots.entries)
        if (!e.value.contains('.')) e.key: e.value,
    };
    final direct = <CodePrompt>[], related = <String, List<CodePrompt>>{};
    final entries = <CodePrompt, ReferenceEntry>{};
    for (final e in expressionReference) {
      final how = runs['${e.owner}.${e.name}'];
      if (how == null) continue;
      final p = _prompt(e);
      entries[p] = e;
      if (how == 'bare') direct.add(p);
      if (handed[e.owner] case final root?) {
        (related[root] ??= []).add(p);
      }
    }
    return ExpressionPrompts(direct, related, entries);
  }
}

/// A name as a prompt. A function is written with its brackets and the cursor between them, as VS Code completes a
/// call, not with its arguments' names, which would be wrong code until each was replaced.
CodePrompt _prompt(ReferenceEntry e) => e.calls
    ? CodeFunctionPrompt(
        word: e.name,
        type: e.gives,
        customAutocomplete: CodeAutocompleteResult(
          input: '',
          word: '${e.name}()',
          selection: TextSelection.collapsed(offset: e.name.length + 1),
        ),
      )
    : CodeFieldPrompt(word: e.name, type: e.gives);

/// The completion list: each name as it is written and, under it, what it does; the chosen one lit.
PreferredSizeWidget expressionPromptsView(
  BuildContext context,
  ValueNotifier<CodeAutocompleteEditingValue> notifier,
  ValueChanged<CodeAutocompleteResult> onSelected,
  ExpressionPrompts prompts,
) {
  final row = Shape.z(34), shown = math.min(notifier.value.prompts.length, 8);
  final size = Size(Shape.z(380), row * shown + Shape.s(10));
  // The overlay gives the list loose room: it is held to its own size.
  return PreferredSize(
    preferredSize: size,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox.fromSize(
        size: size,
        child: Container(
          key: const ValueKey('code-completion'),
          padding: EdgeInsets.all(Shape.s(4)),
          decoration: BoxDecoration(
            color: WindowTokens.raised,
            border: Border.all(color: WindowTokens.line),
            borderRadius: BorderRadius.all(Shape.r(WindowTokens.radius)),
          ),
          child: ValueListenableBuilder<CodeAutocompleteEditingValue>(
            valueListenable: notifier,
            builder: (context, value, _) => ListView.builder(
              padding: EdgeInsets.zero,
              itemExtent: row,
              itemCount: value.prompts.length,
              itemBuilder: (context, i) {
                final p = value.prompts[i], e = prompts.entries[p];
                return Pressable(
                  onTap: () =>
                      onSelected(value.copyWith(index: i).autocomplete),
                  builder: (_, hot) => Container(
                    padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
                    color: i == value.index || hot ? WindowTokens.well : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e?.signature ?? p.word,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.value(Grey.g95),
                        ),
                        if (e != null && e.about.isNotEmpty)
                          Text(
                            e.about,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.label(Grey.g63),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
