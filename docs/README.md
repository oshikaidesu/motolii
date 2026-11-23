# Documentation

Start with the repository [README](../README.md) for an overview and build instructions. Code entry points are documented in [`app/README.md`](../app/README.md) and [`engine/README.md`](../engine/README.md); see [`shelves/README.md`](../shelves/README.md) for placing custom effects, scripts, and plugins.

| Document | Audience | Summary |
|---|---|---|
| [`TABS.md`](TABS.md) ([日本語](TABS.ja.md)) | Users | Visual overview of every tab and panel |
| [`CAMERA.ja.md`](CAMERA.ja.md) | Users (Japanese) | Boxcam frame, Z-target lock-on, 3D View, Match View, and FPS radar Depth panel guide |
| [`ACP_TUTORIAL.ja.md`](ACP_TUTORIAL.ja.md) | Users (Japanese) | ACP Agent tutorial: scene-wide `ops.json` editing, PSD Live2D-style auto-rigging, Group Focus, and Texflow workflows |
| [`AFTER_EFFECTS.md`](AFTER_EFFECTS.md) ([日本語](AFTER_EFFECTS.ja.md)) | After Effects users | Bringing native AE plugins, expressions, and Lottie files into Motolii |
| [`CODING.md`](CODING.md) ([日本語](CODING.ja.md)) | Shader & script authors | Format bases, compatibility model, WESL WGSL attributes, and IDE workflow |
| [`VISM_QUICKSTART.ja.md`](VISM_QUICKSTART.ja.md) | Creators & plugin authors (Japanese) | 5-minute Vism custom panel / card quickstart (`+ New Vism`, hot reload, 3D/shader/audio, `.vism` distribution) |
| [`CUSTOM_CARDS.md`](CUSTOM_CARDS.md) ([日本語](CUSTOM_CARDS.ja.md)) | Plugin & effect authors | Vism `.ui.js` Custom Inspector Card spec (`surface`, `ui.scene3d`, `ui.shader`, `ui.knob`, `ui.waveform`, hot reload) |
| [`GUIDE.md`](GUIDE.md) | Users (Japanese) | Complete workflow guide from creating a project to exporting |
| [`design/effect_licences.md`](design/effect_licences.md) | Effect authors & contributors | Attribution model, export credit files, and bundling boundaries |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Developers | End-to-end architecture across Flutter, C++ engine, WebGPU, and shelves |
| [`TESTING.md`](TESTING.md) | Developers | Test suites (C++, Flutter, golden, mutation) and CI workflow |
| [`app/BRIDGE.md`](app/BRIDGE.md) | Flutter developers | FFI contract between the Flutter UI and C++ engine |
| [`app/GESTURES.md`](app/GESTURES.md) | Flutter developers | Pointer, drag, scroll, and keyboard interaction specs |
| [`design/uat_scenarios.md`](design/uat_scenarios.md) | QA / testers | Numbered end-to-end user acceptance test scenarios |
| [`design/uat_order.md`](design/uat_order.md) | QA / testers | Prioritized UAT execution and fix order |
| [`design/renamed_words.md`](design/renamed_words.md) | Developers | Terminology glossary for legacy symbol and file renames |
| [`archive/`](archive/) | Reference | Historical planning notes and superseded docs |

For contribution guidelines, see [`.github/CONTRIBUTING.md`](../.github/CONTRIBUTING.md).
