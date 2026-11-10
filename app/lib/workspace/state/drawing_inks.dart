// The inks and fonts a new layer is given (DrawingInks): fill, stroke and gradient blend, and the fonts of a title and of body text.
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/painting.dart' show HSVColor;

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_writes.dart';

/// The inks and the fonts a new layer is given. They are saved with the document but are not undo steps.
class DrawingInks {
  /// Creates it with no ink and no font chosen.
  DrawingInks({required this._engine});

  final Motolii? Function() _engine;

  /// The font a new text layer uses: one that every machine of the platform has. The Create shelf and the preview's text tool share it.
  static final defaultTextFont = Platform.isWindows
      ? 'C:/Windows/Fonts/arial.ttf'
      : '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';

  String _ink = '', _edge = '', _inkBlend = '';

  /// The fill the drawing tools give a new layer. An empty string means none is chosen.
  String get ink => _ink;
  set ink(String v) => _ink = _kept('ink', _ink, v);

  /// The stroke colour the drawing tools give a new layer. An empty string means none is chosen.
  String get edge => _edge;
  set edge(String v) => _edge = _kept('edge', _edge, v);

  /// How a gradient ink is mixed (the layer's gradient_blend). An empty string means the document's own, or sRGB.
  String get inkBlend => _inkBlend;
  set inkBlend(String v) => _inkBlend = _kept('ink_blend', _inkBlend, v);
  String _kept(String name, String was, String now) {
    if (now != was) _engine()?.later('setting', name: name, word: now);
    return now;
  }

  String _titleFont = '', _bodyFont = '';

  /// Which of the two fonts the Fonts shelf sets: 'title' or 'body'.
  String fontRole = 'title';

  /// The font for a new title. An empty string means the default font.
  String get titleFont => _titleFont;
  set titleFont(String v) => _titleFont = _kept('title_font', _titleFont, v);

  /// The font for a new body text. An empty string means the default font.
  String get bodyFont => _bodyFont;
  set bodyFont(String v) => _bodyFont = _kept('body_font', _bodyFont, v);

  /// The font file a new body text uses.
  String get bodyFace => bodyFont.isEmpty ? defaultTextFont : bodyFont;

  /// The font file a new title uses: the body's when no title font is chosen.
  String get titleFace => titleFont.isEmpty ? bodyFace : titleFont;

  /// Takes the choices saved with the document ([kept] is its settings), without writing them back.
  void restore(Map<String, String> kept) {
    _ink = kept['ink'] ?? '';
    _edge = kept['edge'] ?? '';
    _inkBlend = kept['ink_blend'] ?? '';
    _titleFont = kept['title_font'] ?? '';
    _bodyFont = kept['body_font'] ?? '';
  }

  /// Applies the chosen inks to the layer just added (layer -1), wherever it was added from, including the Fonts and Create shelves.
  /// A text or a flat shape takes all the inks, because the preview draws only those. A line takes its colour only.
  void applyToNewLayer(String kind, String shape) {
    final m = _engine();
    if (m == null || !(kind == 'text' || kind == 'shape' && shape != 'null')) {
      return;
    }
    final line = shape == 'line';
    if (ink.isNotEmpty) m.later('say', layer: -1, name: 'fill', word: ink);
    // With no ink chosen, a shape gets a random colour as in Alight Motion (AbsentMotion's addShape, randomColor): any hue,
    // saturation 0.3 to 0.8, value 0.55 to 1. It is written to the document so the Inspector and Colors shelf show it.
    if (ink.isEmpty && kind == 'shape') {
      final r = math.Random(),
          c = HSVColor.fromAHSV(
            1,
            r.nextDouble() * 360,
            .3 + r.nextDouble() * .5,
            .55 + r.nextDouble() * .45,
          ).toColor();
      m.later(
        'say',
        layer: -1,
        name: 'fill',
        word: [c.r, c.g, c.b]
            .map((v) => (v * 255).round().toRadixString(16).padLeft(2, '0'))
            .join(),
      );
    }
    if (ink.contains(' ') && inkBlend.isNotEmpty && !line) {
      m.later(
        'say',
        layer: -1,
        name: 'gradient_blend',
        word: inkBlend,
      ); // A gradient ink is mixed as it was chosen.
    }
    if (edge.isNotEmpty && !line) {
      m
        ..later('say', layer: -1, name: 'stroke', word: edge)
        ..later('set', layer: -1, name: 'stroke_width', number: 6);
    }
  }
}
