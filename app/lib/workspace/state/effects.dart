// What is put on the picture: the effects on a thing and in the document, a whole-picture shape or adjustment board,
// a screen effect, a look or motion tried on and put, toggled by the shelf.
part of 'state.dart';

extension WsFx on Ws {
  static List<String> fxFiles(String fx) => Ws.fxFiles(fx); // (the class's own statics, named as these name them)
  static int get fps => Ws.fps;

  /// Joined: the effects on the picked thing (its fx: as the camera sees it, After Effects' effects on a layer), nearest
  /// the picture first. Effects are always a thing's: there is no stage-wide one (a whole picture's is a 2D plate showing
  /// what is behind it, as a lens, with the effect on the plate).
  List<String> get screenFx {
    final t = int.tryParse(selected ?? '');
    if (t == null) return const [];
    return fxFiles(_inside?.word(t, 'fx') ?? '');
  }

  /// Joined: all the effects and motions on anything in the document, as the shelf tells them. A document is a bundle
  /// no hand made: Suitcase's Font Sense keeps in a document the fonts it uses.
  Set<String> get fxUsed {
    final m = _inside;
    if (m == null) return const {};
    return {
      for (final t in m.layers) ...[...fxFiles(m.word(t, 'fx')), ...fxOf('$t'), if (m.word(t, 'script') case final s when s.isNotEmpty && s != 'none') s],
    };
  }

  /// A shape as large as the picture, picked, one step with what [also] says to it.
  void whole(String kind, [void Function(Motolii m)? also]) {
    final m = _inside;
    if (m == null) return;
    m.later('together', number: 1);
    var made = 0;
    after(m.later('add', name: 'shape', word: kind), null, (t) => made = t);
    m
      ..later('set', layer: -1, name: 'size', number: WsArt.comp.height / m.point)
      ..later('set', layer: -1, name: 'wide', number: WsArt.comp.width / WsArt.comp.height);
    wsInked(this, 'shape', kind);
    also?.call(m);
    after(m.later('together'), (done, _) {
      if (done && made > 0) select('$made');
    });
  }

  /// A board as large as the picture whose fill is what is behind it: what is on it works on all under it (After Effects'
  /// Adjustment Layer).
  void adjustment([String? file]) => whole('rect', (m) {
    m
      ..later('say', layer: -1, name: 'fill', word: 'behind')
      ..later('say', layer: -1, name: 'name', word: 'Adjustment');
    if (file != null) m.later('fx_file', layer: -1, word: file);
  });

  /// Joined: an effect put over the others on the picked thing, or taken off (one step either way). Nothing picked: a new
  /// adjustment layer with it (Photoshop's Adjustments panel: a press there adds a layer over the rest).
  bool screenToggle(String file) {
    final m = _inside, t = int.tryParse(selected ?? '');
    if (m == null) return false;
    if (t == null) {
      adjustment(file);
      return true;
    }
    // (at the end of its effects or out, by the inside's rule for its list; not taken, said why: a camera takes motions only)
    after(m.later('fx_file', layer: t, word: file), (done, why) => done || why.isEmpty ? null : notice = 'Not taken: ${why.split(':').first}');
    return true;
  }

  /// Joined: an effect put over the others on the picked thing, one more of it when it is on already, as After Effects'
  /// Effects & Presets panel puts on another each time (Gaussian Blur 2), its values as they come. The next is named as
  /// the inside's Duplicate names one ("Glow~2.fs", doc_fx_duplicate), which reads an ISF or a .wgsl file's alone.
  bool screenPut(String file) {
    final had = screenFx, dot = file.lastIndexOf('.');
    if (!had.contains(file)) return screenToggle(file);
    if (!file.endsWith('.fs') && !file.endsWith('.wgsl')) {
      notice = 'Not taken: only an ISF or a .wgsl effect is put on again so far'; // (the inside's words, doc_fx_duplicate)
      return false;
    }
    return screenToggle(firstFree(file, had.contains, (n) => '${file.substring(0, dot)}~$n${file.substring(dot)}'));
  }

  void tryOn(String? file) {
    final m = _inside, t = int.tryParse(selected ?? '');
    if (m == null) return;
    if (_trying) after(m.later('drag_end', number: 0));
    _trying = file != null && t != null;
    if (!_trying) return;
    after(m.later('drag_start', layer: t!)); // (without waiting, as Align's hold: the shelf's hand never stands still for it)
    after(m.later('drag_update', name: 'effect', word: file!));
  }

  /// Joined: the motion the picked thing has (its script's file; '' none).
  String get motion {
    final t = int.tryParse(selected ?? '');
    final w = t == null ? '' : (_inside?.word(t, 'script') ?? '');
    return w == 'none' ? '' : w;
  }

  /// Joined: an effect of the shelf put on the picked thing as it comes, or taken off (one step either way). Nothing
  /// picked: a new board as large as the picture with it, as After Effects' applyPreset puts a preset on a new solid layer
  /// when no layer is selected (its scripting guide, Layer.applyPreset) (a board whose fill is what is behind it takes ThorVG's own effects
  /// on no picture: a blur on one changed nothing, 11/3).
  void fxToggle(String name) {
    final m = _inside, t = int.tryParse(selected ?? '');
    if (m == null) return;
    if (t == null) return whole('rect', (m) => m.later('effect', layer: -1, name: name, number: frame / fps));
    after(m.later('effect', layer: t, name: name, number: frame / fps)); // (without waiting)
  }

  /// Joined: a look kept by its name given to the picked thing; nothing picked, to a new board, as [motionToggle].
  void lookPut(String file) {
    final m = _inside, t = int.tryParse(selected ?? '');
    if (m == null) return;
    if (t == null) return whole('rect', (m) => m.later('paste_style', layer: -1, word: file));
    after(m.later('paste_style', layer: t, word: file));
  }
}
