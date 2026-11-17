// The metadata line under a card's Section head: author · licence, and user tags as editable chips.
// Shared by ValuesCard (Inspector) and, through the same ShelfTags, the Code tab.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/storage/shelf_meta.dart' show shelfMetaByName;
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/text_gestures.dart' show TypedField;
import 'package:motolii/workspace/dock/common/shelf_tags.dart';

class CardMetaRow extends StatefulWidget {
  const CardMetaRow(this.name, {super.key});
  final String name;
  @override
  State<CardMetaRow> createState() => _CardMetaRowState();
}

class _CardMetaRowState extends State<CardMetaRow> {
  bool _tagging = false;
  String _typed = '';

  @override
  Widget build(BuildContext context) {
    final meta = shelfMetaByName(widget.name);
    final userTags = ShelfTags.shared.ownOf('Effects', widget.name);
    if ((meta == null || meta.isEmpty) && userTags.isEmpty && !_tagging) {
      return const SizedBox.shrink();
    }
    final parts = <String>[
      if (meta != null && meta.author.isNotEmpty) 'by ${meta.author}',
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        InspectorSkin.inset,
        0,
        InspectorSkin.inset,
        InspectorSkin.titleGap,
      ),
      child: Wrap(
        spacing: Shape.s(4),
        runSpacing: Shape.s(2),
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (parts.isNotEmpty)
            Text(parts.join(' · '), style: TextStyles.label(Grey.g44)),
          for (final t in userTags) _chip(t),
          if (_tagging) _field() else _add(),
        ],
      ),
    );
  }

  Widget _chip(String tag) => Pressable(
    onTap: () => setState(() {
      ShelfTags.shared.setOwn(
        'Effects',
        widget.name,
        ShelfTags.shared.ownOf('Effects', widget.name)..remove(tag),
      );
    }),
    builder: (_, hot) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: Shape.s(5),
        vertical: Shape.s(1),
      ),
      decoration: BoxDecoration(
        color: hot ? Grey.g26 : Grey.g20,
        borderRadius: BorderRadius.circular(Shape.s(3)),
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

  Widget _add() => Pressable(
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
      ShelfTags.shared.setOwn('Effects', widget.name, {
        ...ShelfTags.shared.ownOf('Effects', widget.name),
        tag,
      });
    }
    setState(() {
      _tagging = false;
      _typed = '';
    });
  }

  Widget _field() {
    final done = ShelfTags.shared.completing('Effects', _typed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: Shape.z(100),
          height: Shape.s(16),
          child: TypedField(
            key: ValueKey('card-meta-tag:${widget.name}'),
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
                        borderRadius: BorderRadius.circular(Shape.s(3)),
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
}
