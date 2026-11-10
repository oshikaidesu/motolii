# Documents

Every document under `docs/`, and who it is for. The entrance to the repository is the [README](../README.md). Where to put a file you found is in [`shelves/README.md`](../shelves/README.md), beside the shelves themselves. The code's own entrances are [`app/README.md`](../app/README.md) and [`engine/README.md`](../engine/README.md).

| Document | For | What it is |
|---|---|---|
| [`using/guide.md`](using/guide.md) ([日本語](using/guide.ja.md)) | People using the app | The long tour: what Motolii does, the formats it runs, building step by step, a first piece, how it compares |
| [`using/screen_tour.md`](using/screen_tour.md) ([日本語](using/screen_tour.ja.md)) | People using the app | Each tab of the screen, with pictures and how to use it |
| [`using/make_intro_movie.md`](using/make_intro_movie.md) | People using the app | The calls that make the guide's 8-second example; pasted, they write `~/Movies/Motolii/mv.mp4` (Japanese) |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Anyone changing the code | The whole design: how the app, the engine, drawing and video connect. Read it first (Japanese) |
| [`TESTING.md`](TESTING.md) | Anyone changing the code | How to run each kind of test, what CI runs, how to add a test |
| [`app/BRIDGE.md`](app/BRIDGE.md) | People changing the app (Flutter) | The contract between the app and the engine (Japanese) |
| [`app/DESIGN.md`](app/DESIGN.md) | People changing the app | The design system of the Timeline panel: colours, type, components, layout |
| [`app/GESTURES.md`](app/GESTURES.md) | People changing the app | What a press, a drag, a wheel and each key mean on every control. Read it before making a panel (Japanese) |
| [`app/skins/HANDOFF.md`](app/skins/HANDOFF.md) | People carrying on the app's look | The three layers that change the look, and where each is written (Japanese) |
| [`engine/WINDOWS.md`](engine/WINDOWS.md) | People changing the engine (C++) | What building the engine on Windows would take; nothing has been built there yet (Japanese) |
| [`pictures/`](pictures/) | — | The pictures and films the README and the guides show |
| [`internal/`](internal/) | The author | The author's working notes; nothing there is needed to use, extend or build Motolii |

Documents are in English; the pages a user opens first also have a Japanese translation beside them, named `X.ja.md`. The documents marked (Japanese) above are not in English yet; each starts with an English summary.

How to contribute: [`.github/CONTRIBUTING.md`](../.github/CONTRIBUTING.md).
