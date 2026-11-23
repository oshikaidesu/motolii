# Motolii

[日本語](README.ja.md)

[![build](https://github.com/oshikaidesu/motolii/actions/workflows/build.yml/badge.svg)](https://github.com/oshikaidesu/motolii/actions/workflows/build.yml) [![checks](https://github.com/oshikaidesu/motolii/actions/workflows/checks.yml/badge.svg)](https://github.com/oshikaidesu/motolii/actions/workflows/checks.yml)

**A WebGPU-native motion graphics & video editor built to end sluggish previews, locked-in plugin ecosystems, and the wall between creative code and video.**

![Motolii workspace: shelves on the left, Stage preview in the center, Timeline at the bottom, and Inspector on the right](docs/pictures/tabs/window.jpg)

---

## Why Motolii?

Motion design tools have forced the same trade-offs for decades:

- **Lagging previews** — Stack a few shaders or clones and playback grinds to a halt.
- **Rebuilding web art from scratch** — Amazing Shadertoy, p5.js, CSS, Lottie, or Cavalry pieces can't just be dropped into a video timeline.
- **Cluttered UI & locked ecosystems** — Endless vertical parameter lists, painful scripting UX, and fear of losing paid plugins if you ever switch.

Motolii is built on a **WebGPU-native C++ engine** and **plain-file shelves**. Thousands of copies and stacked shaders stay smooth at 60 fps, and code from the web runs directly when you press `⌘V`.

---

## "If I switch from After Effects, do I lose my paid plugins and expressions?"

**No — bring them straight in.**  
Motolii is designed so you don't have to throw away years of plugins, scripts, or muscle memory:

- **Your native After Effects plugins (`.plugin` / `.aex`) work out of the box**  
  Drop or symlink third-party AE plugins (Deep Glow, Quick Chromatic Aberration, Zink Tools, Satori, etc.) into `ae_plugins/`. They appear with parameter cards, `#ae` tags, and live previews, running in an isolated worker via [aexlo](https://github.com/potistudio/aexlo) so a crashing plugin never takes down the editor.
- **After Effects expressions run natively**  
  Powered by `lottie-web`'s `ExpressionManager` compiled to QuickJS-ng — `thisComp`, `thisLayer`, `wiggle`, `linear`, `ease`, `sampleImage`, and keyframe queries work directly without reimplementation.
- **Lottie, PSD layers, Cavalry, AviUtl2, Shadertoy, p5.js & CSS in one timeline**  
  Import multi-layer PSDs ready for rigging, run 26 bundled Cavalry scripts, and mix 20+ creative formats on the same layer in any order.
- **Alpha Stage preview & ProRes 4444 alpha export**  
  Toggle the real-time checkerboard (`Alpha`) on the Stage and export straight-alpha ProRes 4444 `.mov` clips to slot smoothly into existing Premiere, DaVinci, or AE pipelines.

> See the [After Effects Migration Guide](docs/AFTER_EFFECTS.md) for full details.

---

## How Does It Feel to Use? (UI / UX)

### 1. Find Effects & Fonts Visually — No Memorizing Names

Browse 1,300+ bundled effects and your entire font library on an interactive **2D similarity map** with category islands, zoom controls, and an enlarged hover loupe — or hover any tile to preview it live on the Stage.

![Effects 2D similarity map with cluster island labels, zoom controls, and similarity strip](docs/pictures/map_showcase.jpg)

<p>
<img src="docs/pictures/tabs/effects_wide.jpg" alt="Effects shelf tile grid and tag filters" width="49%">
<img src="docs/pictures/tabs/fonts_wide.jpg" alt="Fonts shelf specimen grid and roles" width="49%">
</p>

### 2. Compact, Tactile Controls Instead of Endless Rows

- **Tile-based Inspector**: Parameters sit in dense multi-column cards that expand cleanly as you widen the pane, color-coded by visual impact.
- **Timeline + HDR Environment Objects**: Audio waveforms, tap-tempo BPM beat grids, stackable easings, and **timeline `Environment` layers** so you can trim, toggle, and keyframe HDR room lighting, rotation, fog, and skyboxes directly on the timeline.
- **Adjustable Freehand Smoothing & 3D Boxcam**: Dial Brush/Pen stroke stabilization (`Off`–`High`) with corner preservation, and steer 3D cameras alongside the live Depth radar panel.

<p>
<img src="docs/pictures/tabs/inspector.jpg" alt="Tile-based Inspector with 2.5D/3D Transform card" width="32%">
<img src="docs/pictures/tabs/timeline.jpg" alt="Timeline with audio waveform, keyframes, and easing curves" width="66%">
</p>
<p>
<img src="docs/pictures/tabs/ease.jpg" alt="Stackable easing curve editor and presets" width="49%">
<img src="docs/pictures/tabs/depth.jpg" alt="Depth radar panel for camera focus and DOF" width="49%">
</p>

### 3. Code & AI Side-by-Side (Code Workspace & ACP Agent)

Switch to the **CODE** workspace to keep **ACP AI Agents**, stacked **Code notebook cells**, **Stage**, and **Timeline** open together. Connect Claude Agent, Codex, Gemini CLI, or Cursor with live context of the selected layer's cards, values, and scripts.

![Code workspace: ACP Agent on the left, Code notebook in the center, Stage on the right, Timeline at the bottom](docs/pictures/tabs/code_workspace.jpg)

---

## Vism — Next-Gen Custom UI Panels & Cards

Instead of waiting on closed plugin vendors, **Vism** lets anyone build synth-grade custom Inspector faceplates and dockable tool panels in **a single JavaScript file** — zero WebView, rendered 100% natively in Flutter with 3D scenes (`.glb`/`.obj`/wavetables), 60 fps GLSL shaders, audio waveforms, 16-step sequencers, rig pickers, and rotary knobs.

![Vism 8 design vectors live demo: 3D toon, wavetable synth, hardware OLED, studio light rig, retro CRT, comic](docs/pictures/vism_3d_live.gif)

![Vism pro capabilities live demo: audio waveform, 16-step sequencer, GLSL shader, Live2D rig picker, curve and faders](docs/pictures/vism_live.gif)

- **Start building in 10 seconds**: Click **`+ New Vism`** in the Tools panel to scaffold a runnable starter with IDE autocomplete (`motolii-ui.d.ts`), open it as a live docking tab, and launch your editor — every save hot-reloads in ~80 ms.
- **Presets & 1-click `.vism` sharing**: Save parameter presets on any Vism card, export a `.vism` package (presets & assets bundled), and double-click or drop onto Motolii to install instantly.
- **Prefer a uniform UI?**: Toggle `Settings → Appearance → Vism Card Faceplates` off at any time to keep full functionality in Motolii's standard skin.

👉 [Vism 5-Minute Quickstart (Japanese)](docs/VISM_QUICKSTART.ja.md) · [Vism Custom Card Specification](docs/CUSTOM_CARDS.md)

---

## Download (Beta)

Prebuilt **macOS Apple Silicon (`.app`)** beta builds are published on [GitHub Releases](https://github.com/oshikaidesu/motolii/releases).

1. Download `Motolii-*-macos-arm64.zip` from [Releases](https://github.com/oshikaidesu/motolii/releases), unzip, and move `Motolii.app` to `/Applications`.
2. Because early beta builds are not yet notarized with an Apple Developer ID, run this once in Terminal before launching:
   ```bash
   xattr -cr /Applications/Motolii.app
   ```
3. Launch Motolii and click any bundled project under **SAMPLES** in the Home sidebar to explore right away.

> Windows (`x64`) and Linux builds are in progress. To build from source, see below.

## Build and Run

### Requirements

- Apple Silicon Mac (tested on M4, macOS 15.5)
- Xcode from the App Store (launch once, then run `sudo xcodebuild -license accept`)
- [Homebrew](https://brew.sh/), [Flutter](https://docs.flutter.dev/get-started/install) 3.50.0 (stable), Python 3, ~10 GB free disk space

```bash
git clone https://github.com/oshikaidesu/motolii.git
cd motolii
brew bundle
engine/build.sh
app/tool/live.sh
```

Run tests with `engine/build.sh test` (C++) and `cd app && flutter test` (Flutter). See [Testing](docs/TESTING.md).

---

## Supported Formats (20+)

Paste code (`⌘V`) or drop files into your shelf folders — formats are detected automatically.

| Format | How to add | Runtime |
|---|---|---|
| **After Effects plugins (`.plugin`, `.aex`)** | Place or symlink in `ae_plugins/` | [aexlo](https://github.com/potistudio/aexlo) (isolated worker) |
| **After Effects expressions** | Paste (`⌘V`) or Expression card | lottie-web in QuickJS-ng |
| **Lottie (`.json`)** | Drag & drop | ThorVG (with runtime expressions) |
| **Photoshop (`.psd` / `.psb`)** | Drag & drop | Multi-layer group import |
| **Shadertoy / GLSL Sandbox / twigl / Bonzomatic** | Paste (`⌘V`) | ISF → WGSL (glslang + Tint) |
| **ISF (`.fs`) / WGSL (`.wgsl`)** | Place in `effects/` | Native WebGPU |
| **p5.js / Paper.js / Two.js / Canvas 2D / Dwitter / tixy / Turtletoy** | Paste (`⌘V`) | QuickJS-ng |
| **Hydra / three.js TSL** | Paste (`⌘V`) | QuickJS-ng → WGSL |
| **Cavalry scripts** | Expression card | QuickJS-ng |
| **CSS `@keyframes` / Animated SVG** | Paste (`⌘V`) or D&D | Stylo (Firefox CSS engine) + ThorVG |
| **AviUtl2 (`.anm2`, `.obj2`)** | Place in `aviutl_scripts/` | LuaJIT |
| **3D models (`.glb`, `.gltf`) / Point clouds (`.ply`)** | Drag & drop | Filament WebGPU |
| **Subtitles (`ASS`/`SRT`/`LRC`/`VTT`)** | Drag & drop | libass via FFmpeg |

---

## Documentation

- [Tabs & Panels](docs/TABS.md) — Visual overview of every tab and feature
- [After Effects Migration Guide](docs/AFTER_EFFECTS.md) — Using your existing AE plugins, expressions, and Lottie assets
- [Vism Custom Panel & Card Quickstart (Japanese)](docs/VISM_QUICKSTART.ja.md) / [Specification](docs/CUSTOM_CARDS.md)
- [ACP Agent Tutorial (Japanese)](docs/ACP_TUTORIAL.ja.md) — PSD auto-rigging, Group Focus, and `ops.json` workflows
- [Camera Guide (Japanese)](docs/CAMERA.ja.md) — Boxcam 3D camera, Z-target lock-on, and Depth radar
- [Coding & Shader Reference](docs/CODING.md) — Supported formats, WESL WGSL attributes, and IDE workflow
- [User Guide (Japanese)](docs/GUIDE.md) — End-to-end guide from project creation to export
- [Architecture](docs/ARCHITECTURE.md) / [Bridge Contract](docs/app/BRIDGE.md) / [Testing](docs/TESTING.md)
- [Contributing](.github/CONTRIBUTING.md)

## Contributing & License

Questions are welcome in [Discussions](https://github.com/oshikaidesu/motolii/discussions) and bug reports in [Issues](https://github.com/oshikaidesu/motolii/issues) (English or Japanese).  
Dual-licensed under [Apache License 2.0](LICENSE-APACHE) or [MIT](LICENSE-MIT), at your option (see [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for bundled third-party works).
