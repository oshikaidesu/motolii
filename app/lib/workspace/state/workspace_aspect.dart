// The parts of the window's state a widget can listen to, one at a time.

/// What part of the window's state changed. A widget rebuilds only when an aspect it reads changes (see [WorkspaceScope.of]).
/// [document] means the engine's snapshot of the document was read again. [layers] means what that read lists changed:
/// a layer's row (name, bar, keyframes, switches, links, lanes), the markers, the work area, the tempo or the length.
/// A drag that changes only other values tells [document] alone.
/// [structure] means that read brought more than numbers: a name, a word, a card, a range, a layer come or gone,
/// the document's size or length. A widget that shows no number of the document listens to it instead of
/// [document], and is left alone while a value is dragged.
enum WorkspaceAspect {
  document,
  structure,
  layers,
  picked,
  playing,
  view,
  fronted,
  animating,
  notice,
  stage,
}
