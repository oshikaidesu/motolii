// One font on the Fonts shelf, set in its own face.
import 'package:motolii/workspace/shelf/shelf_looks.dart';

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/workspace/dock/common/star_button.dart';
import 'package:motolii/workspace/dock/fonts/font_commands.dart';
import 'package:motolii/workspace/dock/fonts/font_file.dart';
import 'package:motolii/workspace/dock/fonts/fonts_controller.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';

/// The badge shown for a font without Latin letters. Latin text set in it is drawn in the fallback font
/// (see type_fallback), and the inspector says so.
const _noLatin = 'NO LATIN';

/// The font files handed to Flutter so far. Flutter keeps a loaded font for as long as the app runs, so this set
/// lasts as long, whichever window asked.
final _loaded = <String>{};

/// Returns the font family a shelf row is set in, by loading the font file's bytes the first time the row is shown.
/// FontLoader is Flutter's way to use a font that is not bundled with the app.
///
/// The file name is often not the family name (Songti.ttc is "Songti SC", and a file in ~/Library/Fonts may use its
/// PostScript name), and the regular face of a family is not always the face ThorVG sets. Loading the file shows
/// the row in the same face the preview will use. The family name serves as a fallback until the file is read.
String _own(FontFile f) {
  final p = f.path;
  if (p == null) return f.family;
  if (_loaded.add(p)) {
    Zone.root.run(
      () =>
          (FontLoader(p)
                ..addFont(File(p).readAsBytes().then(ByteData.sublistView)))
              .load()
              .catchError((Object _) {}),
    ); // If the file has gone since, the row stays in the family name's face.
  }
  return p;
}

/// The text style that sets text in the font [f].
TextStyle fontFaceStyle(FontFile f, double size, Color c) => TextStyle(
  fontFamily: _own(f),
  fontFamilyFallback: [f.family, '.AppleSystemUIFont'],
  fontSize: size,
  color: TextStyles.ink(c),
  height: 1.1,
  decoration: TextDecoration.none,
);

/// One font as a tile of the Fonts shelf: a row (narrow) or a card (wide), its sample set in its own face.
Widget fontTile(
  FontFile f,
  ShelfContext c,
  FontsController controller, {
  required bool list,
  String? usedBy,
}) {
  final commands = FontCommands(c, controller);
  final sel = c.sel == f.family, star = c.starred(f.family);
  final tags =
      f.script ??
      controller.tags
          .of(
            'Fonts',
            f.family,
            f.path == null
                ? const <String>{}
                : (c.ws.inside?.fontTags(f.path!) ?? const <String>{}),
          )
          .take(2)
          .join(' ');
  return ShelfTile(
    ShelfItem(f.family, f.family, label: f.script ?? '', about: f.sample ?? ''),
    shelfLooks['Fonts']!,
    list: list,
    picked: sel,
    picks: false,
    onTap: () {
      c.pick(f.family);
      commands.toRole(f);
    },
    // A double-click sets the font. Dragging the tile into the preview does the same.
    onApply: () => commands.setFont(f),
    art: (_) => list
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              f.sample ?? fontSampleLine,
              maxLines: 1,
              style: fontFaceStyle(f, 17, dockInk(sel, Grey.g95)),
            ),
          )
        : Text(
            f.sample ?? 'Motion',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: fontFaceStyle(f, 28, dockInk(sel, Grey.g95)),
          ),
    says: '${f.family}  ·  $tags',
    marks: [
      if (f.script != null) ...[
        SizedBox(width: Shape.s(6)),
        Chip(label: _noLatin, look: ChipLook.tag(null)),
      ],
      if (usedBy case final u?) ...[
        SizedBox(width: Shape.s(6)),
        Chip(label: u, look: ChipLook.tag(sel ? null : WindowTokens.toneText)),
      ],
    ],
    after: (h) => [
      if (star || h || sel)
        StarButton(
          on: star,
          ink: sel ? WindowTokens.onAccent : null,
          onTap: () => c.star(f.family),
        )
      else
        SizedBox(
          width: list ? Shape.s(20) : null,
          height: list ? null : Shape.s(20),
        ),
    ],
  );
}
