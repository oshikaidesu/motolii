// A skin's drawn parts, in the manner of KDE Plasma and Kvantum.
//
// The theme's `Parts` role names a folder. An SVG there named for a part (`tp.eye.svg`, `glyph.select.svg`, `undo.svg`)
// is drawn in place of the built-in drawing, in the colour the app gives that part.
// A `frame.<part>.svg` is stretched around that part in its own colours (see SkinFrame in widgets/skin_frame.dart).
// A part the folder does not have keeps the built-in drawing, so a skin may bring one picture or all of them.
// The part names are listed in shelves/skins/PARTS.md.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:motolii/skin/theme.dart';

/// The pictures of the current skin, loaded from the folder named by the theme's `Parts` role.
abstract final class SkinParts {
  static final _pics = <String, PictureInfo>{};
  static final _slices = <String, double>{}, _frames = <String, ui.Image>{};
  static String? _dir;

  /// Loads the pictures from the folder the theme names, and again whenever the theme changes.
  ///
  /// The app is rebuilt once the new pictures are loaded.
  static void follow() {
    void read() {
      final dir = ColorTheme.place(ColorTheme.word('Parts', ''));
      if (dir == _dir) return;
      _dir = dir;
      _load(dir);
    }

    ColorTheme.words.addListener(read);
    read();
  }

  static Future<void> _load(String dir) async {
    final next = <String, PictureInfo>{};
    final folder = Directory(dir);
    if (dir.isNotEmpty && folder.existsSync()) {
      for (final f in folder.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.svg'),
      )) {
        try {
          final name = f.uri.pathSegments.last.replaceAll('.svg', '');
          next[name] = await vg.loadPicture(SvgFileLoader(f), null);
          if (RegExp(r'data-slice="([0-9.]+)"').firstMatch(f.readAsStringSync())
              case final m?) {
            _slices[name] = double.parse(m.group(1)!);
          }
        } catch (_) {
          // A picture that cannot be read is skipped, so the built-in drawing stays.
        }
      }
    }
    // The theme moved on while these were loading.
    if (dir != _dir) return;
    // No pictures before or now, so there is nothing to repaint.
    if (next.isEmpty && _pics.isEmpty) return;
    for (final p in _pics.values) {
      p.picture.dispose();
    }
    for (final i in _frames.values) {
      i.dispose();
    }
    _frames.clear();
    _pics
      ..clear()
      ..addAll(next);
    WidgetsBinding.instance.reassembleApplication();
  }

  /// Draws the skin's picture [name] into [s] in [color], scaled to fit.
  ///
  /// Returns false when the skin has no such picture, and the caller then draws its own.
  static bool draw(Canvas c, Size s, String name, Color color) {
    final p = _pics[name];
    if (p == null || p.size.isEmpty) return false;
    final k = (s.width / p.size.width) < (s.height / p.size.height)
        ? s.width / p.size.width
        : s.height / p.size.height;
    c.save();
    c.translate(
      (s.width - p.size.width * k) / 2,
      (s.height - p.size.height * k) / 2,
    );
    c.scale(k);
    c.saveLayer(
      Offset.zero & p.size,
      Paint()..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
    );
    c.drawPicture(p.picture);
    c.restore();
    c.restore();
    return true;
  }

  /// Whether the skin brought a picture named [name].
  static bool has(String name) => _pics[name]?.size.isEmpty == false;

  /// Draws the skin's frame [name] around [r], as CSS border-image does, in the picture's own colours.
  ///
  /// The corners are drawn as they are and the edges and middle are stretched.
  /// The corner size is the SVG's `data-slice`, or a third of its smaller side when it has none.
  static void frame(Canvas c, Rect r, String name) {
    // The frame is rasterized at four times the logical resolution so it stays sharp on any screen.
    final p = _pics[name]!, k = 4.0;
    final img = _frames[name] ??= () {
      final rec = ui.PictureRecorder();
      Canvas(rec)
        ..scale(k)
        ..drawPicture(p.picture);
      return rec.endRecording().toImageSync(
        (p.size.width * k).ceil(),
        (p.size.height * k).ceil(),
      );
    }();
    final sl = (_slices[name] ?? (p.size.shortestSide / 3)).clamp(
      0.0,
      p.size.shortestSide / 2 - .5,
    );
    c.save();
    c.scale(1 / k);
    c.drawImageNine(
      img,
      Rect.fromLTRB(
        sl * k,
        sl * k,
        (p.size.width - sl) * k,
        (p.size.height - sl) * k,
      ),
      Rect.fromLTRB(r.left * k, r.top * k, r.right * k, r.bottom * k),
      Paint()..filterQuality = FilterQuality.medium,
    );
    c.restore();
  }
}
