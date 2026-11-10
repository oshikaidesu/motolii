// Part of dock_make.dart: palettes and gradients. It holds the starters, the user's own saved in ~/.motolii/colors.json,
// a palette taken from a photo, and how a gradient is mixed and applied.
part of 'dock_make.dart';

/// A color palette: the starters, the user's saved ones, or one taken from a photo.
class _Pal {
  const _Pal(this.id, this.name, this.colors, {this.saved = false, this.reference, this.shares});
  final String id, name;
  final List<Color> colors;
  final bool saved;

  /// The photo the colors were taken from. A copy is kept beside the palette, so it is there whenever the palette is shown.
  final String? reference;

  /// How much of the image each color covers. The palette strip is drawn in these proportions.
  final List<double>? shares;
}

/// A gradient: its colors run down the layer as a straight linear ramp. Linear or radial is chosen in the inspector.
///
/// [blend] is how the colors are mixed between stops, and it is saved with the gradient:
/// - rgb
/// - oklab: the way an eye mixes, with no muddy middle between blue and yellow
/// - hue: around the hue circle
/// - steps: each color is held until the next
///
/// The engine does the mixing (gradient_blend, CSS Color 4's color-interpolation-method).
class _Gradient {
  const _Gradient(this.name, this.colors, {this.blend = 'oklab', this.saved = false, this.at});
  final String name;
  final List<Color> colors;

  /// Where each color sits, as a fraction of the way along the ramp. Null spreads them evenly.
  final List<double>? at;
  final String blend;
  final bool saved;
}

const _blends = {'rgb': 'RGB', 'oklab': 'OKLab', 'hue': 'Hue', 'steps': 'Steps'};

/// How the gradient being edited is mixed: the picked layer's gradient_blend, or the ink's. Unset means 'rgb'.
String _blendNow(DockCtx c) {
  final t = _colored(c), w = t != null && (c.ws.aim ?? 'fill') == 'fill' ? c.ws.inside!.word(t, 'gradient_blend') : c.ws.inkBlend;
  return w.isEmpty ? 'rgb' : w;
}

/// The stops for a gradient's preview on the shelf, mixed as the engine will mix it. OKLab is drawn with CAM16, the nearest perceptual mix Flutter has.
(List<Color>, List<double>?) _previewOf(List<Color> cs, String blend, [List<double>? at]) => at != null && blend == 'rgb'
    ? (cs, at)
    : switch (blend) {
        'steps' => (
          [
            for (final c in cs) ...[c, c],
          ],
          [
            for (var i = 0; i < cs.length; i++) ...[i / cs.length, (i + 1) / cs.length],
          ],
        ),
        'hue' => (
          [
            for (var i = 0; i < cs.length - 1; i++)
              for (var k = 0; k < 6; k++) HSVColor.lerp(HSVColor.fromColor(cs[i]), HSVColor.fromColor(cs[i + 1]), k / 6)!.toColor(),
            cs.last,
          ],
          null,
        ),
        'oklab' => (_stopsOf(cs, true), null),
        _ => (cs, null),
      };

/// Puts a gradient on what is being colored: its colors, and how they are mixed. That is the picked layer's gradient_blend,
/// or the ink's for the next layer drawn. It is one undo step.
void _putGradient(DockCtx c, List<Color> cs, String blend, [List<double>? at]) {
  final m = c.ws.inside!, t = _colored(c);
  final word = at != null && at.length == cs.length
      ? _wordOfStops([for (var i = 0; i < cs.length; i++) (cs[i], at[i])])
      : [for (final k in cs) _hex(k).substring(1).toLowerCase()].join(' ');
  if (t == null || (c.ws.aim ?? 'fill') != 'fill') {
    c.ws.inkBlend = blend;
    return _fill(c, word);
  }
  m.later('together', number: 1);
  _fill(c, word);
  m.later('say', layer: t, name: 'gradient_blend', word: blend);
  c.ws.after(m.later('together'));
}

const _starterPals = <_Pal>[
  _Pal('pop', 'Pop Poster', [Color(0xFFB3C66B), Color(0xFF4781E5), Color(0xFFF08A5D), Color(0xFFE974AB), Color(0xFFEFCB4E), Color(0xFF15170D)]),
  _Pal('riso', 'Riso Print', [Color(0xFFFF48B0), Color(0xFF0078BF), Color(0xFFFFE800), Color(0xFF00A95C), Color(0xFFF15060), Color(0xFFF2EDE4)]),
  _Pal('coda', 'Coda Title', [Color(0xFFD9D2C3), Color(0xFFF08A5D), Color(0xFF7FB8B0), Color(0xFF3B3631), Color(0xFFF2C94C)]),
  _Pal('market', 'Night Market', [Color(0xFF1B1F3B), Color(0xFF53354A), Color(0xFFE84545), Color(0xFFFFB740), Color(0xFF2B9EB3)]),
  _Pal('candy', 'Candy Shop', [Color(0xFFFFB5C2), Color(0xFFB5EAD7), Color(0xFFC7CEEA), Color(0xFFFFDAC1), Color(0xFFE2F0CB), Color(0xFF9ADCFF)]),
  _Pal('signal', 'Signal', [Color(0xFFFF3B30), Color(0xFFFF9500), Color(0xFFFFCC00), Color(0xFF34C759), Color(0xFF007AFF), Color(0xFFAF52DE)]),
];

const _starterGrads = <_Gradient>[
  _Gradient('Lime dusk', [Color(0xFFB3C66B), Color(0xFF4781E5)]),
  _Gradient('Hot pink', [Color(0xFFE974AB), Color(0xFFF08A5D), Color(0xFFEFCB4E)]),
  _Gradient('Deep sea', [Color(0xFF15170D), Color(0xFF2B9EB3), Color(0xFF7DD5B1)]),
];

// What the user has saved, in ~/.motolii/colors.json: {"palettes": [{"name": "", "colors": ["#rrggbb"]}], "gradients": [{"name": "", "colors": [], "blend": "oklab"}], "colours": [], "tile": 52}.
final _minePals = <_Pal>[];

/// The user's own colors, saved one by one, as in CLIP STUDIO PAINT's color set: Add Color stores the drawing color,
/// pressing a tile draws with it, and a tile's menu replaces or deletes it.
final _mineColors = <Color>[];
final _mineGrads = <_Gradient>[];
bool _mineRead = false;
File _mineFile = File('${Platform.environment['HOME']}/.motolii/colors.json');

/// Sets where the saved colors are stored. A test points it elsewhere, and what was read is forgotten, as easeStarsAt does.
void colorsAt(File f) {
  _mineFile = f;
  _mineRead = false;
  _minePals.clear();
  _mineColors.clear();
  _mineGrads.clear();
  _tile = 52;
}

void _readMine() {
  if (_mineRead) return;
  _mineRead = true;
  try {
    final told = fileJson(_mineFile) as Map;
    for (final (i, p) in ((told['palettes'] as List?) ?? const []).indexed) {
      final cs = [for (final h in (p['colors'] as List)) ?colorOfHex('$h')];
      final sh = (p['shares'] as List?)?.map((v) => (v as num).toDouble()).toList();
      if (cs.isNotEmpty) {
        _minePals.add(
          _Pal('mine$i', '${p['name']}', cs, saved: true, reference: p['reference'] as String?, shares: sh != null && sh.length == cs.length ? sh : null),
        );
      }
    }
    _mineColors.addAll([for (final h in (told['colours'] as List?) ?? const []) ?colorOfHex('$h')]);
    if (told['tile'] case final num v) _tile = v.toDouble().clamp(_tileLeast, _tileMost);
    for (final g in (told['gradients'] as List?) ?? const []) {
      final cs = [for (final h in (g['colors'] as List)) ?colorOfHex('$h')];
      final at = (g['at'] as List?)?.map((v) => (v as num).toDouble()).toList();
      if (cs.length > 1) {
        _mineGrads.add(
          _Gradient(
            '${g['name']}',
            cs,
            blend: g['blend'] as String? ?? (g['oklab'] == false ? 'rgb' : 'oklab'),
            saved: true,
            at: at != null && at.length == cs.length ? at : null,
          ),
        );
      }
    }
  } catch (_) {
    // No file: only the starters are shown.
  }
}

void _keepMine() {
  fileKeep(
    _mineFile,
    jsonEncode({
      'palettes': [
        for (final p in _minePals)
          {
            'name': p.name,
            'colors': [for (final c in p.colors) _hex(c)],
            'reference': p.reference,
            'shares': p.shares,
          },
      ],
      'gradients': [
        for (final g in _mineGrads)
          {
            'name': g.name,
            'colors': [for (final c in g.colors) _hex(c)],
            'blend': g.blend,
            'at': g.at,
          },
      ],
      'colours': [for (final c in _mineColors) _hex(c)],
      'tile': _tile,
    }),
  );
}

List<_Pal> get _pals => [..._minePals, ..._starterPals];
List<_Gradient> get _grads => [..._mineGrads, ..._starterGrads];

String _hex(Color c) {
  String h(double v) => (v * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#${h(c.r)}${h(c.g)}${h(c.b)}';
}

// ---- Gradient mixing in CAM16-UCS (from Google's material_color_utilities). This color space is close to how an eye mixes
// colors, so the middle of two colors looks as expected. The ramp the engine draws mixes plainly, so the middle is
// supplied as extra stops laid in that space, a few between each pair.
List<Color> _stopsOf(List<Color> cs, bool smooth) {
  if (!smooth || cs.length < 2) return cs;
  final out = <Color>[];
  for (var i = 0; i < cs.length - 1; i++) {
    final a = Cam16.fromInt(cs[i].toARGB32()), b = Cam16.fromInt(cs[i + 1].toARGB32());
    for (var k = 0; k < 5; k++) {
      final t = k / 5;
      out.add(
        k == 0
            ? cs[i]
            : Color(
                Cam16.fromUcs(
                  a.jstar + (b.jstar - a.jstar) * t,
                  a.astar + (b.astar - a.astar) * t,
                  a.bstar + (b.bstar - a.bstar) * t,
                ).viewed(ViewingConditions.sRgb),
              ),
      );
    }
  }
  return out..add(cs.last);
}

/// Builds a palette from a photo. The image is shrunk and its pixels are grouped into colors by Google's quantizer
/// (material_color_utilities, as Material You takes a palette from a wallpaper). Each color records how many pixels it has.
/// The photo is copied beside the palette and stays there.
Future<_Pal?> _paletteFrom(String path) async {
  try {
    final codec = await ui.instantiateImageCodec(await File(path).readAsBytes(), targetWidth: 96);
    final img = (await codec.getNextFrame()).image;
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    final pixels = <int>[
      for (var i = 0; i + 3 < data.lengthInBytes; i += 4)
        if (data.getUint8(i + 3) > 200) 0xFF000000 | (data.getUint8(i) << 16) | (data.getUint8(i + 1) << 8) | data.getUint8(i + 2),
    ];
    if (pixels.isEmpty) return null;
    final found = (await QuantizerCelebi().quantize(pixels, 6)).colorToCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = found.fold<int>(0, (s, e) => s + e.value);
    final kept = Directory('${Platform.environment['HOME']}/.motolii/references')..createSync(recursive: true);
    final name = path.split('/').last, copy = '${kept.path}/${DateTime.now().millisecondsSinceEpoch}_$name';
    File(path).copySync(copy);
    return _Pal(
      'mine${_minePals.length}',
      name.replaceFirst(RegExp(r'\.[A-Za-z0-9]+$'), ''),
      [for (final e in found) Color(e.key)],
      saved: true,
      reference: copy,
      shares: [for (final e in found) e.value / total],
    );
  } catch (_) {
    return null;
  }
}

/// The photo picked on the Media shelf, if it is an image file on disk that Flutter can read.
/// It reads Media's own selection, because each shelf keeps its selection apart (dock.dart _mem).
String? _pickedPhoto(DockCtx c) {
  final id = (c.ws.view['dock.Media'] as DockMem?)?.sel['Media'];
  return id != null && id.startsWith('/') && RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false).hasMatch(id) ? id : null;
}

/// The colors that layers are filled with, keyed by layer name. A gradient counts as its first color.
Map<String, Color> usedColors(Ws ws) {
  final m = ws.inside;
  if (m == null) return const {};
  return {
    for (final l in ws.layers)
      if (m.word(int.parse(l.id), 'fill').split(' ').first.split('@').first case final f when f.length == 6)
        if (int.tryParse(f, radix: 16) case final v?) l.name: Color(0xFF000000 | v),
  };
}
