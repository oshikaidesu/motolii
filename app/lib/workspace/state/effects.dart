// What is applied to the canvas: effects on a layer, a canvas-sized shape or adjustment layer,
// and the presets and motions the shelf previews, applies and removes.
part of 'workspace_state.dart';

extension WsFx on Ws {
  // Forwarders to the statics on Ws, so the extension can use the same names.
  static List<String> fxFiles(String fx) => Ws.fxFiles(fx);
  static int get fps => Ws.fps;

  /// The effects on the selected layer, like After Effects' effects on a layer, in the order the engine applies them.
  /// Effects always belong to a layer. A whole-canvas effect is an adjustment layer showing what is behind it.
  List<String> get screenFx {
    final t = int.tryParse(selected ?? '');
    if (t == null) return const [];
    return fxFiles(_inside?.word(t, 'fx') ?? '');
  }

  /// Every effect and motion file used by any layer in the document, so the shelf can mark them.
  /// The document carries its own files, as Suitcase's Font Sense keeps the fonts a document uses.
  Set<String> get fxUsed {
    final m = _inside;
    if (m == null) return const {};
    return {
      for (final t in m.layers) ...[...fxFiles(m.word(t, 'fx')), ...fxOf('$t'), if (m.word(t, 'script') case final s when s.isNotEmpty && s != 'none') s],
    };
  }

  /// Adds a shape as large as the canvas, selects it, and applies [also] to it, all as one undo step.
  void whole(String kind, [void Function(Motolii m)? also]) {
    final m = _inside;
    if (m == null) return;
    m.later('together', number: 1);
    var made = 0;
    after(m.later('add', name: 'shape', word: kind), null, (t) => made = t);
    m
      ..later('set', layer: -1, name: 'size', number: Ws.comp.height / m.point)
      ..later('set', layer: -1, name: 'wide', number: Ws.comp.width / Ws.comp.height);
    wsInked(this, 'shape', kind);
    also?.call(m);
    after(m.later('together'), (done, _) {
      if (done && made > 0) select('$made');
    });
  }

  /// Adds a canvas-sized layer filled with whatever is behind it, so its effects apply to everything below
  /// (After Effects' Adjustment Layer). [file] is an effect to put on it.
  void adjustment([String? file]) => whole('rect', (m) {
    m
      ..later('say', layer: -1, name: 'fill', word: 'behind')
      ..later('say', layer: -1, name: 'name', word: 'Adjustment');
    if (file != null) m.later('fx_file', layer: -1, word: file);
  });

  /// Adds effect [file] after the others on the selected layer, or removes it. Either is one undo step.
  /// With no layer selected it creates a new adjustment layer carrying the effect, as Photoshop's Adjustments panel does.
  bool screenToggle(String file) {
    final m = _inside, t = int.tryParse(selected ?? '');
    if (m == null) return false;
    if (t == null) {
      adjustment(file);
      return true;
    }
    // The engine puts it at the end of the list or removes it. If refused, say why; a camera accepts motions only.
    after(m.later('fx_file', layer: t, word: file), (done, why) => done || why.isEmpty ? null : notice = 'Not taken: ${why.split(':').first}');
    return true;
  }

  /// Adds effect [file] after the others on the selected layer. If it is already there, adds another copy, as After
  /// Effects' Effects & Presets panel does (Gaussian Blur 2). The copy is named as the engine's Duplicate names it
  /// ("Glow~2.fs", see doc_fx_duplicate), which works for ISF and .wgsl files only.
  bool screenPut(String file) {
    final had = screenFx, dot = file.lastIndexOf('.');
    if (!had.contains(file)) return screenToggle(file);
    if (!file.endsWith('.fs') && !file.endsWith('.wgsl')) {
      // The wording comes from the engine, see doc_fx_duplicate.
      notice = 'Not taken: only an ISF or a .wgsl effect is put on again so far';
      return false;
    }
    return screenToggle(firstFree(file, had.contains, (n) => '${file.substring(0, dot)}~$n${file.substring(dot)}'));
  }

  /// Previews effect [file] on the selected layer without changing the document. Null ends the preview.
  void tryOn(String? file) {
    final m = _inside, t = int.tryParse(selected ?? '');
    if (m == null) return;
    if (_trying) after(m.later('drag_end', number: 0));
    _trying = file != null && t != null;
    if (!_trying) return;
    // Not awaited, like Align's drag, so the shelf never stalls on it.
    after(m.later('drag_start', layer: t!));
    after(m.later('drag_update', name: 'effect', word: file!));
  }

  /// The motion of the selected layer: its script file, or '' for none.
  String get motion {
    final t = int.tryParse(selected ?? '');
    final w = t == null ? '' : (_inside?.word(t, 'script') ?? '');
    return w == 'none' ? '' : w;
  }

  /// Adds the shelf effect [name] to the selected layer with its default values, or removes it. Either is one undo step.
  /// With no layer selected it creates a canvas-sized layer carrying the effect, as After Effects' applyPreset
  /// puts a preset on a new solid when no layer is selected (scripting guide, Layer.applyPreset).
  void fxToggle(String name) {
    final m = _inside, t = int.tryParse(selected ?? '');
    if (m == null) return;
    if (t == null) return whole('rect', (m) => m.later('effect', layer: -1, name: name, number: frame / fps));
    // Not awaited.
    after(m.later('effect', layer: t, name: name, number: frame / fps));
  }

  /// Applies the saved preset [file] to the selected layer, or to a new canvas-sized layer when none is selected.
  void lookPut(String file) {
    final m = _inside, t = int.tryParse(selected ?? '');
    if (m == null) return;
    if (t == null) return whole('rect', (m) => m.later('paste_style', layer: -1, word: file));
    after(m.later('paste_style', layer: t, word: file));
  }
}
