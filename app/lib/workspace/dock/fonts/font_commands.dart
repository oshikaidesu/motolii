// What the Fonts shelf asks the engine to do: set a text layer's font, or add a text layer in a font.
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/inspector/text/text_ranges.dart';
import 'package:motolii/widgets/text_gestures.dart' show wordsPicked;
import 'package:motolii/workspace/dock/fonts/font_file.dart';
import 'package:motolii/workspace/dock/fonts/fonts_controller.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// What the Fonts shelf asks the engine to do: set the font of a text layer, add a text layer in a font, and choose
/// the title and body fonts. Every call to the engine the shelf makes is a method here.
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
    final m = c.ws.inside!, t = int.tryParse(c.ws.selected ?? '');
    void told(bool done, String why) => c.set(
      () =>
          done ? c.mem.trouble.remove(f.family) : c.mem.trouble[f.family] = why,
    );
    if (t != null && m.word(t, 'kind') == 'text') {
      // Letters selected in the text take the font as a range of their own, as a word processor's font menu sets
      // the selection's font; the range names the file as its font-family (inspector/text/text_ranges.dart).
      if (pickedLetters(m.word(t, 'text'), wordsPicked.value) case final at?) {
        return c.ws.after(
          m.later(
            'say',
            layer: t,
            name: 'text_styles',
            word: styleRange(
              m.word(t, 'text_styles'),
              at.start,
              at.count,
              'font-family',
              "'${f.path!}'",
            ),
          ),
          told,
        );
      }
      return c.ws.after(
        m.later('say', layer: t, name: 'file', word: f.path!),
        told,
      );
    }
    // The new text layer and its colors form one undo step.
    m.later('together', number: 1);
    c.ws.after(
      m.later('add', name: 'text', word: f.path!),
      null,
      (made) => c.ws.select('$made'),
    );
    applyChosenInks(c.ws, 'text', '');
    c.ws.after(m.later('together'), told);
  }

  /// With no text layer selected, a click on a font sets the font of the current role, like a color click on the
  /// Colors shelf. With a text layer selected nothing happens here: its font is set by a double-click or Apply.
  void toRole(FontFile f) {
    final m = c.ws.inside, t = int.tryParse(c.ws.selected ?? '');
    if (m == null ||
        f.path == null ||
        (t != null && m.word(t, 'kind') == 'text')) {
      return;
    }
    fonts.used(f.family);
    c.set(
      () => c.ws.fontRole == 'body'
          ? c.ws.bodyFont = f.path!
          : c.ws.titleFont = f.path!,
    );
  }

  /// Adds a text layer in the given font at the playhead, with the current colors, and selects it.
  /// Like Canva's "Add a heading" and "Add a little bit of body text".
  void addIn(String font) {
    final m = c.ws.inside!;
    // The new text layer and its colors form one undo step.
    m.later('together', number: 1);
    c.ws.after(
      m.later('add', name: 'text', word: font),
      null,
      (made) => c.ws.select('$made'),
    );
    applyChosenInks(c.ws, 'text', '');
    c.ws.after(
      m.later('together'),
      (done, why) => c.set(
        () => done ? c.mem.trouble.remove('role') : c.mem.trouble['role'] = why,
      ),
    );
  }

  /// Sets the font file of the text layer [layer] to [face], the font of a role.
  void setFace(int layer, String face) => c.ws.after(
    c.ws.inside!.later('say', layer: layer, name: 'file', word: face),
  );
}
