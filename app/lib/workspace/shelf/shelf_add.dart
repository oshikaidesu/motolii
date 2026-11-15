// Adding an effect or expression from a layer to the shelf under a name the user chooses ("Add to shelf" on the
// card's code, effect_code.dart), and renaming one added that way from its tile's menu.
// What is added belongs to the user: it goes in their own folder (EffectTiles.own), never in the library's (engine/).
// An effect (.fs, .wgsl) goes in effects/, where the Effects shelf reads the user's effects (doc_folders).
// An expression (a .js with each()) goes in expressions/, the Expression group's folder. The engine also reads it
// as a motion, but Create shows it only once, as the user's (dock_make_expressions.dart).
// Nothing is overwritten: a name already on the shelf, or an existing file of that name, is refused.
// A rename writes the name beside the file (<file>.name, as pasted code does: CodeFile.rename in dock/create/code_file.dart).
// The file stays where it is, so documents that use it still find it. The disk and the engine's side are in
// state/shelf_items.dart; this file has the name field and the names the Create and Effects shelves already hold.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/workspace/dock/create/create_catalog.dart'
    show createNames;
import 'package:motolii/workspace/state/media/shelf_items.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

export 'package:motolii/workspace/state/media/shelf_items.dart';

/// The names already on the shelf that a new item goes to, from the library and the user.
/// An effect goes to the Effects shelf (dock_effects.dart); an expression ([expression]) goes to Create (dock_make.dart).
Set<String> shelfTaken(WorkspaceController ws, {required bool expression}) {
  if (expression) return createNames(ws);
  return shelfTakenNames(ws);
}

/// A name edited in place, as in Finder. Return or leaving the field commits it; Escape cancels and calls [done] with null.
class ShelfNameField extends StatelessWidget {
  const ShelfNameField(this.name, this.done, {super.key, this.small = true});
  final String name;
  final void Function(String? name) done;

  /// Whether it edits a tile's name (true) or a card's (false).
  final bool small;
  @override
  Widget build(BuildContext context) => Container(
    color: Grey.g91,
    padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
    alignment: Alignment.centerLeft,
    child: TypedField(
      text: name,
      take: true,
      escapes: true,
      style: small ? TextStyles.micro(Grey.g13) : TextStyles.name(Grey.g13),
      cursor: Grey.g13,
      selection: Grey.g63,
      onDone: done,
    ),
  );
}
