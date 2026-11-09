// Part of dock_make.dart: the palettes and gradients: the starters, one's own kept in ~/.motolii/colors.json, a
// palette taken from a photo, and how a gradient is mixed and put on.
part of 'dock_make.dart';

class _Pal {
  const _Pal(this.id, this.name, this.colors, {this.saved = false, this.reference, this.shares});
  final String id, name;
  final List<Color> colors;
  final bool saved;

  /// The photo the colours were taken from, kept beside them (a copy, so it is there whenever the palette is looked at),
  /// and how much of the picture each colour is (the strip is drawn by it: the picture's composition).
  final String? reference;
  final List<double>? shares;
}

/// A gradient: its colours down the thing (a straight ramp, linear: round or straight is the inspector's), and how they
/// are mixed between, kept with it (the user: a gradient's way of mixing is kept in its preset as it is): rgb, oklab (as
/// an eye mixes, no muddy middle between blue and yellow), hue (round the hue), steps (each held till the next). The
/// inside mixes them (gradient_blend, CSS Color 4's color-interpolation-method).
class _Gradient {
  const _Gradient(this.name, this.colors, {this.blend = 'oklab', this.saved = false, this.at});
  final String name;
  final List<Color> colors;
  final List<double>? at; // (where each colour stands, a share of the way; null: evenly)
  final String blend;
  final bool saved;
}

const _blends = {'rgb': 'RGB', 'oklab': 'OKLab', 'hue': 'Hue', 'steps': 'Steps'};

/// How the gradient coloured now is mixed: the picked thing's gradient_blend, or the ink's ('rgb' unsaid).
String _blendNow(DockCtx c) {
  final t = _colored(c), w = t != null && (c.ws.aim ?? 'fill') == 'fill' ? c.ws.inside!.word(t, 'gradient_blend') : c.ws.inkBlend;
  return w.isEmpty ? 'rgb' : w;
}

/// How a gradient looks on the shelf, mixed as the inside will mix it (OKLab drawn by CAM16, the eye's mix Flutter has).
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

/// A gradient put on what is coloured: its colours, and how they are mixed (the picked thing's gradient_blend, or the
/// ink's, for the next thing drawn); one step.
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

// What the maker has kept: ~/.motolii/colors.json {"palettes": [{"name": "", "colors": ["#rrggbb"]}], "gradients": [{"name": "", "colors": [], "blend": "oklab"}], "colours": [], "tile": 52}.
final _minePals = <_Pal>[];

/// One's own colours, kept one by one (CLIP STUDIO PAINT's colour set: Add Color puts the drawing colour in, a tile
/// pressed draws with it, a tile's menu replaces or deletes it).
final _mineColors = <Color>[];
final _mineGrads = <_Gradient>[];
bool _mineRead = false;
File _mineFile = File('${Platform.environment['HOME']}/.motolii/colors.json');

/// Where they are kept (a test points it elsewhere, and forgets what was read: as easeStarsAt).
void colorsAt(File f) {
  _mineFile = f;
  _mineRead = false;
  _minePals.clear();
  _mineColors.clear();
  _mineGrads.clear();
  _tile = 52;
}

Color? _colorOf(Object? hex) {
  final v = int.tryParse('$hex'.replaceFirst('#', ''), radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

void _readMine() {
  if (_mineRead) return;
  _mineRead = true;
  try {
    final told = jsonDecode(_mineFile.readAsStringSync()) as Map;
    for (final (i, p) in ((told['palettes'] as List?) ?? const []).indexed) {
      final cs = [for (final h in (p['colors'] as List)) ?_colorOf(h)];
      final sh = (p['shares'] as List?)?.map((v) => (v as num).toDouble()).toList();
      if (cs.isNotEmpty) {
        _minePals.add(
          _Pal('mine$i', '${p['name']}', cs, saved: true, reference: p['reference'] as String?, shares: sh != null && sh.length == cs.length ? sh : null),
        );
      }
    }
    _mineColors.addAll([for (final h in (told['colours'] as List?) ?? const []) ?_colorOf(h)]);
    if (told['tile'] case final num v) _tile = v.toDouble().clamp(_tileLeast, _tileMost);
    for (final g in (told['gradients'] as List?) ?? const []) {
      final cs = [for (final h in (g['colors'] as List)) ?_colorOf(h)];
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
  } catch (_) {} // (no file: only the starters)
}

void _keepMine() {
  try {
    _mineFile.parent.createSync(recursive: true);
    _mineFile.writeAsStringSync(
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
  } catch (_) {}
}

List<_Pal> get _pals => [..._minePals, ..._starterPals];
List<_Gradient> get _grads => [..._mineGrads, ..._starterGrads];

String _hex(Color c) {
  String h(double v) => (v * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#${h(c.r)}${h(c.g)}${h(c.b)}';
}

// ---- the mix of a gradient: CAM16-UCS (Google's, material_color_utilities), the space an eye mixes in, so the middle
// between two colours is what it expects. The ramp the document draws mixes plainly, so the middle is given as more
// stops, laid in that space (a few between each pair).
List<Color> _stopsOf(List<Color> cs, bool smooth, {int per = 5}) {
  if (!smooth || cs.length < 2) return cs;
  final out = <Color>[];
  for (var i = 0; i < cs.length - 1; i++) {
    final a = Cam16.fromInt(cs[i].toARGB32()), b = Cam16.fromInt(cs[i + 1].toARGB32());
    for (var k = 0; k < per; k++) {
      final t = k / per;
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

/// A palette taken from a photo: the picture shrunk, its pixels sorted into colours by Google's quantizer
/// (material_color_utilities, as Material You takes a palette from a wallpaper), each with how many pixels it has
/// (how much of the picture it is). The photo itself is copied beside the palette and stays there.
Future<_Pal?> _paletteFrom(String path, {int count = 6}) async {
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
    final found = (await QuantizerCelebi().quantize(pixels, count)).colorToCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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

/// The photo picked on the Media shelf, if it is one (a file of the disk that Flutter reads). Read from Media's own
/// keeping: each shelf keeps its picks apart (dock.dart's _mem), so this shelf's own never holds Media's.
String? _pickedPhoto(DockCtx c) {
  final id = (c.ws.view['dock.Media'] as DockMem?)?.sel['Media'];
  return id != null && id.startsWith('/') && RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false).hasMatch(id) ? id : null;
}
