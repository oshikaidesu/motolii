// Part of dock_fonts.dart: the fonts on the map: each family's word drawn by the inside, its kind, and where FontCLIP
// places it (as FontMap does).
part of 'dock_fonts.dart';

/// On the map: a family's word as the stage sets it (drawn by the inside, [_drawn]: no face of all of them loaded here),
/// [_dot] points; its numbers are it made half as large, a point the four under it.
const _dot = (96, 32);
final _drawn = <String, Uint8List?>{}, _seen = <String, ui.Image>{}, _making = <String>{};
Future<void>? _drawing;
Future<void> _drawAll(Motolii m, List<String> files) => _drawing ??= Zone.root.run<Future<void>>(() async {
  // (once, as fontsRead)
  final byWord = <String, List<String>>{};
  for (final f in files) {
    (byWord[_wordOf(f, 0)] ??= []).add(f);
  }
  for (final MapEntry(key: w, value: some) in byWord.entries) {
    final drawn = await m.typePictures(some, w, _dot.$1, _dot.$2);
    for (final (i, f) in some.indexed) {
      _drawn[f] = drawn[i];
    }
  }
  dockRead.value++;
});

/// A font of other letters' own words (fontsRead), by its file.
var _ownWords = const <String, String>{};

/// The words a font is told by on the map: its dot's (0), and FontMap's two lines for FontCLIP (1, 2). A font of other
/// letters, by its own: its first word, and its words' halves (letters' halves, a script with no spaces between).
String _wordOf(String path, int line) {
  final own = _ownWords[path];
  if (own == null) return const ['Motion', 'Hamburge', 'fonstiv'][line];
  final words = own.split(' '), letters = own.runes.toList();
  final some = words.length > 1 ? words : [for (final r in letters) String.fromCharCode(r)], half = (some.length / 2).ceil(), by = words.length > 1 ? ' ' : '';
  return switch (line) {
    0 => words.length > 1 ? words.first : some.take(6).join(),
    1 => some.take(half).join(by),
    _ => some.skip(half).join(by),
  };
}

/// Each font as FontCLIP ([model]) sees its specimen drawn as FontMap draws it for FontCLIP (tfrere/fontmap,
/// pipeline/render/2-generate-svgs.mjs, generateEmbeddingSVG): "Hamburge" over "fonstiv" in a 224 square, 12 round it,
/// each line in its half no wider than 200 nor taller than 85, set at 75 and never larger, its middle at its line's;
/// black on white. 32 told at a time. null: not drawn.
/// A font's kind on the map, as FontMap colours each by its category (sans-serif, serif, handwriting, monospace,
/// decorative): the class CoreText gives it (motolii_font_tags), monospace before it as Google files a monospace font
/// ('' none said).
String _kindOf(Motolii m, String path) {
  final t = m.fontTags(path);
  return t.contains('mono') ? 'mono' : const ['serif', 'sans', 'script', 'ornaments', 'symbols'].firstWhere(t.contains, orElse: () => '');
}

Future<List<Float32List?>> _byFontClip(Motolii m, String model, List<String> files) async {
  String key(String f) {
    // (kept by the model, the font and when it was written, as the effects' pictures: only a new font is drawn and told)
    try {
      return '$model\n$f\n${File(f).lastModifiedSync().microsecondsSinceEpoch}\n${_wordOf(f, 1)} ${_wordOf(f, 2)}';
    } catch (_) {
      return '';
    }
  }

  final out = [for (final f in files) dockLookKept(key(f))],
      missing = [
        for (final (k, f) in files.indexed)
          if (out[k] == null && key(f).isNotEmpty) f,
      ];
  if (missing.isEmpty) return out;
  final lines = [
        for (final _ in const [1, 2]) List<Uint8List?>.filled(missing.length, null),
      ],
      byWords = <(String, String), List<int>>{};
  for (final (k, f) in missing.indexed) {
    (byWords[(_wordOf(f, 1), _wordOf(f, 2))] ??= []).add(k);
  }
  for (final MapEntry(key: (a, b), value: ks) in byWords.entries) {
    // (a font of other letters by its own two lines)
    for (final (j, w) in [a, b].indexed) {
      final drawn = await m.typePictures([for (final k in ks) missing[k]], w, 202, 87, most: 75);
      for (final (i, k) in ks.indexed) {
        lines[j][k] = drawn[i];
      }
    }
  }
  for (var i = 0; i < missing.length; i += 32) {
    final some = [for (var k = i; k < missing.length && k < i + 32; k++) k],
        drawn = [
          for (final k in some)
            if (lines[0][k] != null && lines[1][k] != null) k,
        ];
    final told = drawn.isEmpty ? null : await m.likeness(model, [for (final k in drawn) _specimen(lines[0][k]!, lines[1][k]!)]);
    for (final (j, k) in drawn.indexed) {
      if (told?[j] case final t?) {
        dockLookKeep(key(missing[k]), t);
        out[files.indexOf(missing[k])] = t;
      }
    }
  }
  return out;
}

Uint8List _specimen(Uint8List top, Uint8List bottom) {
  final px = Uint8List(224 * 224 * 4)..fillRange(0, 224 * 224 * 4, 255);
  for (final (line, g) in [top, bottom].indexed) {
    final y0 = 12 + 100 * line + 50 - 87 ~/ 2, x0 = 112 - 202 ~/ 2; // (its middle at its line's)
    for (var y = 0; y < 87; y++) {
      for (var x = 0; x < 202; x++) {
        final at = ((y0 + y) * 224 + x0 + x) * 4;
        px[at] = px[at + 1] = px[at + 2] = 255 - g[y * 202 + x];
      }
    }
  }
  return px;
}

Float32List _halved(Uint8List g) {
  final (w, h) = (_dot.$1 ~/ 2, _dot.$2 ~/ 2);
  final out = Float32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      out[y * w + x] =
          (g[2 * y * _dot.$1 + 2 * x] + g[2 * y * _dot.$1 + 2 * x + 1] + g[(2 * y + 1) * _dot.$1 + 2 * x] + g[(2 * y + 1) * _dot.$1 + 2 * x + 1]) / 1020;
    }
  }
  return out;
}

/// [map]: inked by where it lies on it ([dockPalette]: the user, 11/4, "文字のグラフビューは色が使えるからいい感じにジャンル別の島で
/// グラデしたら綺麗": a word in one ink, unlike the effects' pictures, so colour tells its island; FontMap's category colours).
class _FontDot extends StatefulWidget {
  const _FontDot(this.f, this.c, {this.map});
  final _Font f;
  final DockCtx c;
  final DockMapPlaces? map;
  @override
  State<_FontDot> createState() => _FontDotState();
}

class _FontDotState extends State<_FontDot> {
  void _make(String p, Uint8List g) {
    final rgba = Uint8List(g.length * 4);
    for (var i = 0; i < g.length; i++) {
      rgba.setRange(i * 4, i * 4 + 4, [
        g[i],
        g[i],
        g[i],
        g[i],
      ]); // (white, its colours already by how much is covered: Flutter takes them so, seen white boxes otherwise)
    }
    ui.decodeImageFromPixels(rgba, _dot.$1, _dot.$2, ui.PixelFormat.rgba8888, (image) {
      // (Flutter's own: the bytes as a picture)
      _seen[p] = image;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.f, c = widget.c, sel = c.sel == f.family;
    if ((f.path, _drawn[f.path]) case (final p?, final g?) when _making.add(p)) _make(p, g);
    return DockHover(
      onTap: () {
        c.pick(f.family);
        _toRole(c, f);
      },
      onDoubleTap: () => _setFont(c, f),
      builder: (context, h) => Container(
        color: dockFill(sel, h, WsT.card),
        child: switch (widget.map) {
          final map? => ValueListenableBuilder(
            valueListenable: map.places,
            builder: (context, at, _) => RawImage(
              image: _seen[f.path],
              color: T.ink(dockInk(sel, dockPalette(at)[f.path] ?? Grey.g95)),
              colorBlendMode: BlendMode.modulate,
              fit: BoxFit.contain,
            ),
          ),
          null => RawImage(image: _seen[f.path], color: T.ink(dockInk(sel, Grey.g95)), colorBlendMode: BlendMode.modulate, fit: BoxFit.contain),
        },
      ),
    );
  }
}
