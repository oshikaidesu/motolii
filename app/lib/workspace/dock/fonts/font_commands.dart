// What the Fonts shelf asks the engine to do: set a text layer's font, add a text layer in a font.
import 'package:motolii/widgets/text_gestures.dart' show wordsPicked;
import 'package:motolii/workspace/dock/fonts/font_file.dart';
import 'package:motolii/workspace/dock/fonts/fonts_controller.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/media/fonts_service.dart';

/// What the Fonts shelf asks the engine to do: set the font of a text layer, add a text layer in a font, and choose
/// the title and body fonts. The engine calls are in state (fonts_service.dart).
class FontCommands {
  /// [c] is the shelf as it is built now, and [fonts] what the shelf keeps between builds.
  FontCommands(this.c, this.fonts);

  /// The shelf's context: the project, the shelf's memory and a way to rebuild the shelf.
  final ShelfContext c;

  /// The fonts used lately are noted here.
  final FontsController fonts;

  /// Sets the font on the selected text layer, or on its selected letters. With no text layer selected, adds a new text layer in that font.
  void setFont(FontFile f) {
    fonts.used(f.family);
    void told(bool done, String why) => c.set(
      () =>
          done ? c.mem.trouble.remove(f.family) : c.mem.trouble[f.family] = why,
    );
    setFontOnSelection(c.ws, f.path!, picked: wordsPicked.value, told: told);
  }

  /// With no text layer selected, a click on a font sets the font of the current role, like a color click on the
  /// Colors shelf. With a text layer selected nothing happens here: its font is set by a double-click or Apply.
  void toRole(FontFile f) {
    if (!canSetRoleFont(c.ws) || f.path == null) return;
    fonts.used(f.family);
    c.set(
      () => c.ws.fontRole == 'body'
          ? c.ws.bodyFont = f.path!
          : c.ws.titleFont = f.path!,
    );
  }

  /// Adds a text layer in the given font at the playhead, with the current colors, and selects it.
  /// Like Canva's "Add a heading" and "Add a little bit of body text".
  void addIn(String font) => addTextIn(
    c.ws,
    font,
    (done, why) => c.set(
      () => done ? c.mem.trouble.remove('role') : c.mem.trouble['role'] = why,
    ),
  );

  /// Sets the font file of the text layer [layer] to [face], the font of a role.
  void setFace(int layer, String face) => setLayerFace(c.ws, layer, face);
}
