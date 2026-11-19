import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/disclosure_triangle.dart';
import 'package:motolii/widgets/list_select.dart';

/// A dropdown for choosing one of [options]. The value under [id] is the option's index, kept once, in numbers,
/// as a segmented control keeps it; the words are only what [options] says that index is.
/// A short list belongs in a segmented control and a long one opens a list. It never cycles with previous and next buttons.
/// The list and its keys are [ListSelect]'s.
class Chooser extends StatefulWidget {
  const Chooser({super.key, required this.id, required this.options});
  final String id;
  final List<String> options;
  @override
  State<Chooser> createState() => ChooserState();
}

class ChooserState extends State<Chooser> {
  int _index(InspectorValues doc) =>
      (doc.get(widget.id) ?? 0).round().clamp(0, widget.options.length - 1);

  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context), cur = _index(x.doc);
    return ListSelect<int>(
      value: cur,
      options: widget.options.indexed.toList(),
      onChanged: (i) => x.doc.set(widget.id, i.toDouble()),
      itemHeight: 22,
      minWidth: 160,
      builder: (_, st, _) => Container(
        height: InspectorSkin.cell,
        padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
        decoration: BoxDecoration(
          color: st.isHovered || st.isOpen ? Grey.g10 : InspectorSkin.well,
          borderRadius: Shape.round(6),
          border: Border.all(
            color: st.isOpen ? Grey.g63 : const Color(0x00000000),
          ),
        ),
        // The mark at the right shows that this is a menu, so no extra label is needed.
        child: Row(
          children: [
            // The default value (the first option) is dim. A chosen one is bright.
            Expanded(
              child: Text(
                widget.options[cur],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.name(cur == 0 ? Grey.g56 : Grey.g91),
              ),
            ),
            DisclosureTriangle(open: true, hot: st.isOpen),
          ],
        ),
      ),
    );
  }
}
