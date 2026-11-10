# The app-engine bridge

The contract between the Flutter app (`app/`) and the C++ engine (`engine/`, called through `engine/entry/motolii.h`), for anyone who changes either side.

In short: writes are recorded and return at once, questions are answered later, and what changes every frame is subscribed to. The design follows other open-source apps with the same split: Lumit (a bridge contract), AppFlowy (one stream that says what changed and for whom), Rive's CommandQueue (writes are recorded and return, queries arrive later), Anthem (values that change every frame are subscribed to) and Thermion (a draw request is dropped while the previous one runs). Only the ideas of GPL and AGPL projects are borrowed. [`../design/bridge_rework.md`](../design/bridge_rework.md) records the rework that produced this contract.

## Rules

1. **The app never waits for the engine.** No path calls the engine from an app thread and blocks until it answers.
2. **The app never calls the engine inside a widget's `build`.** It reads only the snapshots the engine handed over.
3. **There are two snapshots.** The engine's render thread builds each while it holds the project lock, then swaps in the finished object whole. A snapshot is immutable and carries a version number.
   - **Project snapshot.** Built only when the project changes. It holds the list of layers and, for each layer: kind, name, length, key positions, ranges, cards, word choices, how it is shown, the effect list and the resting values. For the whole project it holds markers, guides, the work range, length, size and the list of easings. Each layer has its own version. A layer that did not change is the same object as before, so the app can compare with `identical`.
   - **Frame snapshot.** Built for every frame drawn. It holds the time, the values that are moving, each layer's bounds and visible rectangle, the carried values (`shows`), and for the selected layer whether it has keys, its points and its handles.
4. **The engine reports what changed through one channel.** The channel is a single `NativeCallable.listener`, as the Dart SDK recommends (`app/lib/bridge/motolii.dart`). The engine says which snapshot is new and, for the project snapshot, the numbers of the layers that changed. The app merges any number of notices within one frame into one.
5. **The app listens only to what it needs.** `WorkspaceController` (`app/lib/workspace/state/workspace_controller.dart`) splits its state into `ValueNotifier`s: the project (whole and per layer), the frame, and the app-only state (playhead, playing, selected layer, selected key, tool panel, shelves, view options, Animate). There is no catch-all `notifyListeners` for the whole controller.
6. **Writes are fire and forget.** A write goes into a queue and returns. A write that needs an id (`add`, `make`) gets its answer later, together with the next snapshot. If the queue already holds a write to the same value of the same layer, the newest one replaces it.
7. **A question about any time but now, or one that takes long, is a query.** The app asks and receives a `Future`. It does not wait inside `build`: when the answer arrives, only the widget that asked is redrawn.
8. **Data read once at start-up** (the folders of recipes, effects and expressions, and the font families) is read once on another thread when the app opens. After that:
   - The user's folder (`~/Library/Application Support/Motolii/`) is watched while the app runs, and its content is read again when a file comes or goes.
   - Every effect on a shelf gets a tile: eight frames of a sample balloon scene (0.1 to 1.9 seconds, played when the pointer is over the tile), rendered in a separate isolate. The engine says where each tile is kept (`~/Library/Caches/Motolii/tiles/`, named by the file and the time it was written; see `doc_tile` in `engine/document/scripts/recipes.cpp`), and the tile is shown at once. The user's files come first. An effect whose result cannot be told from the sample (above 40 dB PSNR, measured with ffmpeg) is marked NO CHANGE. The code is `app/lib/workspace/shelf/effect_tiles.dart`.
9. **The app owns the playhead, the selection and the zoom**, as Lumit does. It tells the engine about them as writes.
10. **A watchdog counts the waits.** `brokenCount` and `broken` in `app/lib/bridge/motolii_watch.dart` report each time the app's thread waited for the engine and each read that waited on the project longer than 2 ms. The count must stay 0.

## What the snapshots contain

Both are JSON, built in `engine/entry/snapshot.h` and read in `app/lib/bridge/`.

- **Project snapshot.** The project-wide part holds the length, size, work range, markers, guides, the list of easings, the easing curves (65 points each), the list of effects, the list of changed layers, the table of default values and the table of values each kind knows. The per-layer part holds the length, the names of values and of values that move, the cards, the effect list, the ranges, the key times, words, resting values, ranges, word choices, how to read the layer, how it is shown, and, for each value, its key times and their easings. Each per-layer part carries the version it was built at, and the app asks for what is newer than the version it has.
- **Frame snapshot.** The time; for each layer its bounds, visible rectangle and visible values (x, y, z, rotate, scale_x, scale_y and opacity, and whether a relation moves them); and for the selected layer its moving values, points and handles.
