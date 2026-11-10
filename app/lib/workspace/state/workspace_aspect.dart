// The parts of the window's state a widget can listen to, one at a time.

/// What part of the window's state changed. A widget rebuilds only when an aspect it reads changes (see [WorkspaceScope.of]).
///
/// [document] means the engine's snapshot of the document was read again.
enum WorkspaceAspect { document, picked, playing, view, fronted, animating, notice, stage }
