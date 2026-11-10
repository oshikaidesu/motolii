#ifndef MOTOLII_ENTRY_SNAPSHOT_H_
#define MOTOLII_ENTRY_SNAPSHOT_H_
// Builds the two JSON snapshots that the app reads (see docs/app/BRIDGE.md).
// The app reads only these, never the document while it is being built.
//
// The render thread builds both while it holds the document, as JSON written
// with rapidjson (the copy that Filament's assimp ships). Each snapshot is
// stored whole, and the app is notified through its single listener which
// snapshot is new.
//   Document snapshot: rebuilt when the document changes. It holds every
//   layer's text values,
//     resting numbers, ranges, and keyframes.
//   Time snapshot: rebuilt with each frame. It holds where each layer is and
//   what moves, at the
//     time that was drawn.
#include "entry/motolii.h"

// Rebuilds the parts of the document snapshot that changed. Runs on the render
// thread while it holds the document.
//
// A layer is rebuilt when its properties changed. Every layer is rebuilt when a
// layer was added or removed, or when a layer was renamed, because a name
// determines which cards other layers offer. The document-wide part is always
// rebuilt. Each layer's part keeps the version it was built at, so the app can
// ask only for what is newer than what it has.
void snapshot_update(Motolii* m);

// Rebuilds the time snapshot for the current time. Runs on the render thread
// while it holds the document, whenever the time is set.
//
// For each layer it holds the bounding box, the box as seen, the gizmo, and the
// transform values as the stage shows them. For the selected layer and the
// layers the app watches it also holds the values that move at this time. For
// the selected layer it also holds its points and handles.
void snapshot_time(Motolii* m);

// Tells the app, through its listener, which snapshots are new. Call it after
// the document has been released, following Lumit's rule. The argument is a bit
// mask: 1 for the document snapshot, 2 for the time snapshot, and 4 for a
// change in which stage frames are cached on disk.
void snapshot_notify(Motolii* m);

#endif  // MOTOLII_ENTRY_SNAPSHOT_H_
