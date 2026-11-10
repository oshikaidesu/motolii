// A font's dot on the Fonts shelf's map.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/dock/fonts/font_commands.dart';
import 'package:motolii/workspace/dock/fonts/font_file.dart';
import 'package:motolii/workspace/dock/fonts/fonts_controller.dart';
import 'package:motolii/workspace/dock/map/shelf_map.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

/// A font's dot on the map, inked by where it lies on the [map] (see [dockPalette]).
///
/// Unlike the effect thumbnails, a word is a single ink, so colour can tell which island of fonts it belongs to.
/// FontMap colours fonts by category in the same way.
class FontDot extends StatefulWidget {
  const FontDot(this.f, this.c, this.controller, {super.key, this.map});
  final FontFile f;
  final ShelfContext c;

  /// What the shelf keeps between builds: the dots the engine drew and their images.
  final FontsController controller;
  final DockMapPlaces? map;
  @override
  State<FontDot> createState() => _FontDotState();
}

class _FontDotState extends State<FontDot> {
  void _make(String p, Uint8List g) {
    final rgba = Uint8List(g.length * 4);
    for (var i = 0; i < g.length; i++) {
      rgba.setRange(i * 4, i * 4 + 4, [g[i], g[i], g[i], g[i]]); // The pixels are premultiplied white. Without that Flutter showed white boxes.
    }
    ui.decodeImageFromPixels(
      rgba,
      fontDotSize.$1,
      fontDotSize.$2,
      ui.PixelFormat.rgba8888,
      (image) {
        // Flutter's own decoder turns the pixels into an image.
        widget.controller.dotImages[p] = image;
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.f, c = widget.c, sel = c.sel == f.family;
    final controller = widget.controller,
        commands = FontCommands(c, controller);
    if ((f.path, controller.dotsDrawn[f.path]) case (final p?, final g?)
        when controller.dotsMaking.add(p)) {
      _make(p, g);
    }
    return DockHover(
      onTap: () {
        c.pick(f.family);
        commands.toRole(f);
      },
      onDoubleTap: () => commands.setFont(f),
      builder: (context, h) => Container(
        color: dockFill(sel, h, WindowTokens.card),
        child: switch (widget.map) {
          final map? => ValueListenableBuilder(
            valueListenable: map.places,
            builder: (context, at, _) => RawImage(
              image: controller.dotImages[f.path],
              color: TextStyles.ink(
                dockInk(sel, dockPalette(at)[f.path] ?? Grey.g95),
              ),
              colorBlendMode: BlendMode.modulate,
              fit: BoxFit.contain,
            ),
          ),
          null => RawImage(
            image: controller.dotImages[f.path],
            color: TextStyles.ink(dockInk(sel, Grey.g95)),
            colorBlendMode: BlendMode.modulate,
            fit: BoxFit.contain,
          ),
        },
      ),
    );
  }
}
