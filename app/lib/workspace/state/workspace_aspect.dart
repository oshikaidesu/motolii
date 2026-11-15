// The parts of the window's state a widget can listen to, one at a time.

/// What part of the window's state changed. A widget rebuilds only when an aspect it reads changes (see [WorkspaceScope.of]).
///
/// [document] means the engine's snapshot of the document was read again. [layers] means what that read lists changed:
/// a layer's row (name, bar, keyframes, switches, links, lanes), the markers, the work area, the tempo or the length.
/// A drag that changes only other values tells [document] alone.
enum WorkspaceAspect {
  document,
  layers,
  picked,
  playing,
  view,
  fronted,
  animating,
  notice,
  stage,
}
