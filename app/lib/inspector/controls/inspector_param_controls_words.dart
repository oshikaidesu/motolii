// A words value's field: any words, typed (lines too), as Cavalry's string attribute.
import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/skin/tokens.dart';

import '../../widgets/text_gestures.dart';

/// Any words, typed (two lines shown): said to the host when the hand leaves; Esc puts back what was there.
class ParamWords extends StatelessWidget {
  const ParamWords({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final take = textToType; // (a text just placed: the first words field built takes the keys, its words picked)
    textToType = false;
    return TypedField(
      key: ValueKey('words:$id'),
      text: Ctx.of(context).doc.s2[id] ?? '', // (out of the field it is what the host has now: another thing picked, an undo)
      standing: true,
      take: take,
      escapes: true,
      lines: 2,
      style: T.name(Grey.g95).copyWith(fontWeight: FontWeight.w400),
      cursor: Grey.g95,
      backgroundCursor: Grey.g20,
      selection: Role.selected.withValues(alpha: .4),
      onDone: (said) => said == null ? null : Ctx.read(context).doc.str(id, said),
      // (its letters picked by the hand, kept for the Colors shelf to colour those alone: wordsPicked)
      onPick: (v) =>
          wordsPicked.value = v.selection.isValid && !v.selection.isCollapsed ? (text: v.text, start: v.selection.start, end: v.selection.end) : null,
    );
  }
}
