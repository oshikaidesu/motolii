# Bringing Your After Effects Assets to Motolii

[日本語](AFTER_EFFECTS.ja.md)

Motolii lets you bring your existing After Effects plugins, expressions, and Lottie animations directly into your projects — without starting from scratch.

---

## 1. Native After Effects plugins (`.plugin` / `.aex`)

Motolii loads third-party native After Effects plugins through an isolated worker process powered by [aexlo](https://github.com/potistudio/aexlo). Because plugins run outside the editor process, a hanging or crashing plugin will not crash or freeze Motolii.

> **Important:** Motolii never bundles third-party plugin binaries. Use plugins you already own or downloaded yourself under their respective licenses.

### Setup (no restart required)

Place or symlink your plugins into your Motolii user folder:

- **macOS (Apple Silicon):** `~/Library/Application Support/Motolii/ae_plugins/` (`.plugin` bundles)
- **Windows (x64, experimental):** `%APPDATA%\Motolii\ae_plugins\` (`.aex` files)
- **Custom location:** `$MOTOLII_OWN/ae_plugins/`

#### Tip: Symlink your existing After Effects plugin folders

You do not need to duplicate gigabytes of plugins. On macOS, symlink a specific vendor folder directly into `ae_plugins/`:

```bash
mkdir -p "$HOME/Library/Application Support/Motolii/ae_plugins"
ln -s "/Applications/Adobe After Effects 2025/Plug-ins/Plugin Everything" \
      "$HOME/Library/Application Support/Motolii/ae_plugins/Plugin Everything"
```

Subfolders inside `ae_plugins/` automatically appear as **Packs** in the Effects shelf sidebar, so you can browse by vendor or collection.

> Avoid symlinking Adobe's entire `Plug-ins/Effects` built-in directory at once — Adobe's built-in effects rely on private host APIs and are skipped during probing. Symlink third-party folders or drop individual plugins instead.

### Using plugins in the Effects shelf

1. Open the **Effects** tab on the left dock.
2. Plugins appear under the **After Effects** category and under their subfolder **Pack**.
3. Use filter tags to find them quickly:
   - `#ae` — all After Effects plugins
   - `#cpu` / `#gpu` — execution path reported by the plugin
   - `#image` — plugins that accept another layer as a map/input parameter
4. Double-click a tile or drag it onto a layer (or Stage) to apply. All sliders, checkboxes, dropdowns, 2D/3D points, colors, groups, and layer pickers are generated automatically in the **Inspector**.

### What works well vs. current limitations

| Status | Typical plugins |
|---|---|
| **Works well** | 2D stylize, color, glow, distortion, chromatic aberration, cel/anime FX, glitch, and procedural generators (e.g. Deep Glow 2, Quick Chromatic Aberration 3, Satori BlockSwap, Zink Tools 2D/Anime FX, HaloGlow, etc.) |
| **Partial** | Plugins using multi-layer inputs (`Layer` parameters work via Inspector layer pickers) or 3D effects that provide a fallback camera when no comp camera is exposed |
| **Not yet supported** | Adobe's private built-in effects, plugins requiring unimplemented AEGP host suites (comp cameras, text documents, custom modal dialogs), and cross-OS binaries (`.aex` on macOS or `.plugin` on Windows) |

### Performance tips

- Native AE plugins run through CPU RGBA8 transfer across the isolated worker boundary, so lightweight plugins (`BlockSwap`, `ZT_ASCIIArt`, etc.) run well above 60 fps while heavy CPU plugins (volumetric lighting, large-radius CPU blurs) take longer per frame — just as they do in After Effects.
- **Automatic Half-res preview + FSR 1.0 upscaling:** During interactive editing, any AE plugin taking more than 16 ms at full resolution automatically drops to Half resolution (`downsample = 1/2`) and is upscaled back on the GPU using AMD FidelityFX FSR 1.0 (EASU + RCAS). Lightweight plugins stay at full resolution, and final video/still exports always render at 100% full resolution. You can also switch between **Auto (FSR)**, **Full**, and **Half (FSR)** in the top bar's size popover.
- **Hot reload for plugin developers:** Rebuilding a `.plugin` / `.aex` binary in place automatically restarts its isolated worker and updates the Stage without restarting Motolii.
- You can freely stack AE plugins with GPU-native Motolii shaders (such as the bundled **Halo Glow**, ISF, and WGSL effects) on the same layer.
- Want a 60 fps, cross-platform GPU version of a look? Open the **Agent** tab and ask an ACP agent to recreate or adapt the look as a native `.wgsl` shader.

### Troubleshooting

- **Plugin doesn't appear on macOS (downloaded from the web):** Unsigned `.plugin` bundles downloaded in a browser are quarantined by macOS and refused by `dlopen`. Clear the quarantine flag:
  ```bash
  xattr -dr com.apple.quarantine "$HOME/Library/Application Support/Motolii/ae_plugins"
  ```
- **Plugin hangs or renders unchanged:** The worker automatically terminates any render exceeding 5 seconds and passes the original frame through safely so editing continues uninterrupted.
- **Refresh probe cache:** Plugin metadata is cached by file modification time under `~/Library/Caches/Motolii/ae_plugins/`. Deleting that cache folder forces a fresh probe.

---

## 2. After Effects expressions

Motolii runs After Effects expressions natively via lottie-web's `ExpressionManager` compiled into QuickJS-ng bytecode (not a rough reimplementation).

- **Paste directly:** Select a layer and press `⌘V` with an expression on your clipboard (e.g. `wiggle(2, 50)`), or open the **Code** tab and click **+ New expression**.
- **Save to shelf:** Place `.js` files containing bare expressions in `~/Library/Application Support/Motolii/expressions/`. Add `// --property:position` (or `rotation`, `scale`, `opacity`) on line 1 to choose the target property.
- **Supported features:** `thisComp`, `thisLayer`, `thisProperty`, `valueAtTime`, `loopOut` / `loopIn` (`cycle`, `pingpong`, `offset`, `continue`), `wiggle`, `linear`, `ease`, `sampleImage`, `fromWorld`, keyframe access, and cross-layer references.
- **Code tab tooling:** Autocompletion, live evaluated output at the playhead, inline line-numbered errors, and an AE-grouped **Functions** browser showing live engine support per symbol.

---

## 3. Lottie animations (`.json`)

Drag and drop Bodymovin `.json` exports straight onto the Stage or Timeline.

- Played natively by **ThorVG** with live **JerryScript** evaluation for embedded expressions (expressions are evaluated at runtime, not baked).
- Supports keyframes, easings, vector paths, parenting, precomps, time remapping, loops, mattes, blend modes, and Motolii's 3D layer & camera extension.

---

## 4. Bundled GPU-native alternatives

Motolii ships with 1,300+ open-source GPU effects (ISF, WGSL, AviUtl2, three.js TSL, AbsentMotion) — including a GPU-native multi-pass port of MIT-licensed **Halo Glow** (`shelves/effects/stylize/halo_glow.wgsl`). Every bundled effect is automatically credited in the export credits file beside your rendered video.
