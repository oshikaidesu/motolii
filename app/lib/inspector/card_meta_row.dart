// The metadata line under a card's Section head: author · licence, and user tags as editable chips.
// Shared by ValuesCard (Inspector) and the Code tab's cells.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/shelf_meta.dart' show ShelfMeta;
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/text_gestures.dart' show TypedField;
import 'package:motolii/workspace/dock/common/shelf_tags.dart';

class CardMetaRow extends StatefulWidget {
  const CardMetaRow(
    this.name, {
    super.key,
    required this.meta,
    this.license = false,
    required this.padding,
    required this.fieldKey,
  });
  final String name;

  /// What the shelf's meta.yaml says about the card, and whether the licence is said after the author.
  final ShelfMeta? meta;
  final bool license;
  final EdgeInsets padding;

  /// The key of the field a new tag is typed in.
  final Key fieldKey;
  @override
  State<CardMetaRow> createState() => _CardMetaRowState();
}

class _CardMetaRowState extends State<CardMetaRow> {
  bool _tagging = false;
  String _typed = '';

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    final userTags = ShelfTags.shared.ownOf('Effects', widget.name);
    if ((meta == null || meta.isEmpty) && userTags.isEmpty && !_tagging) {
      return const SizedBox.shrink();
    }
    final parts = <String>[
      if (meta != null && meta.author.isNotEmpty) 'by ${meta.author}',
      if (widget.license && meta != null && meta.license.isNotEmpty)
        meta.license,
    ];
    return Padding(
      padding: widget.padding,
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
            key: widget.fieldKey,
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
}
