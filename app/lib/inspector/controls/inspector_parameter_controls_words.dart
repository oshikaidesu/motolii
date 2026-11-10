// The field for a words value: free text that may span lines, like Cavalry's string attribute.
import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/skin/tokens.dart';

import 'package:motolii/widgets/text_gestures.dart';

/// A text field for free text, two lines tall. The text is committed when the field loses focus, and Esc restores the previous text.
class ParameterWords extends StatelessWidget {
  const ParameterWords({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    // After a text layer has just been placed, the first words field built takes keyboard focus with its text selected.
    final take = textToType;
    textToType = false;
    return TypedField(
      key: ValueKey('words:$id'),
      // Outside editing, the text is whatever the document holds now, for example after another layer is selected or after undo.
      text: InspectorScope.of(context).doc.s2[id] ?? '',
      standing: true,
      take: take,
      escapes: true,
      lines: 2,
      style: TextStyles.name(Grey.g95).copyWith(fontWeight: FontWeight.w400),
      cursor: Grey.g95,
      backgroundCursor: Grey.g20,
      selection: Role.selected.withValues(alpha: .4),
      onDone: (said) => said == null ? null : InspectorScope.read(context).doc.str(id, said),
      // Remembers the selected characters in wordsPicked so the Colors shelf can colour just those.
      onPick: (v) =>
          wordsPicked.value = v.selection.isValid && !v.selection.isCollapsed ? (text: v.text, start: v.selection.start, end: v.selection.end) : null,
    );
  }
}
