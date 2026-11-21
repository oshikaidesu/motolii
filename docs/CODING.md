# Coding & Shader Reference

[日本語](CODING.ja.md)

This guide explains what each coding format in Motolii is based on, how upstream compatibility is preserved, and how to write native WGSL shaders and JavaScript expressions cleanly.

---

## 1. Format & compatibility matrix

Motolii separates **external formats** (run as their authors published them, without rewriting their syntax) from **Motolii-native formats** (modern, single-source declarations with zero duplication).

| Format | Upstream base | Runtime in Motolii | How compatibility is preserved |
|---|---|---|---|
| **Motolii WGSL (`.wgsl`)** | W3C WGSL + [WESL `wgsl-play`](https://wesl-lang.dev/docs/wgsl-play) UI attributes | Native WebGPU (Dawn via Filament) | UI attributes (`@range`, `@color`, `@toggle`, `@point`, `@group("...")`, `@label("...")`, `@auto`) are stripped to same-width spaces before reaching Dawn, keeping line numbers exact and standard `@group(N)` bindings untouched. Legacy `// --track@` comments remain supported. |
| **Motolii JS (`expressions/`, `relations/`, `solids/`)** | Standard JS + [`leva`](https://github.com/pmndrs/leva) (`const knobs = { ... }`) | QuickJS-ng (`relations/` also loads p5.js + `d3-force-3d`; `solids/` loads three.js) | Pure JS syntax works in any editor/LSP. Legacy `// --track@` comment headers remain supported. Rigid bodies use Jolt Physics' own property names (`mass`, `force`, `gravityFactor`, `restitution`, `friction`). |
| **ISF (`.fs`) & Web GLSL** (Shadertoy, GLSL Sandbox, twigl, Bonzomatic) | [Vidvox ISF](https://docs.isf.video/) JSON header + GLSL | `glslang` → SPIR-V → `Tint` → WGSL | External shaders stay unmodified; ISF `INPUTS`/`PASSES` and Shadertoy uniforms are translated at load time into WGSL. |
| **AviUtl2 (`.anm2`, `.obj2`)** | AviUtl2 LuaJIT + `obj` API + embedded HLSL | LuaJIT 2.1 + `glslang` (HLSL) → SPIR-V → `Tint` → WGSL | Original package folders and AviUtl2 `--track@` / `--check@` / `--select@` / `--color@` headers stay untouched in `shelves/aviutl_scripts/`. |
| **After Effects expressions** | Adobe AE expression language | `lottie-web` `ExpressionManager` bytecode in QuickJS-ng | Runs lottie-web's real evaluator instead of a custom C++ replica; supports `thisComp`, `thisLayer`, `sampleImage`, `fromWorld`, `wiggle`, `loopOut`, etc. |
| **After Effects plugins (`.plugin`, `.aex`)** | Adobe AE Effect SDK (PF / SmartFX) | [potistudio/aexlo](https://github.com/potistudio/aexlo) (MIT) in an isolated worker (`motolii_ae_worker`) | Runs unmodified user-supplied binaries out-of-process with timeout protection, `PF_InData.downsample` + AMD FSR 1.0 automatic Half preview (100% full-res on export), and automatic worker restart on binary rebuild. |
| **CSS `@keyframes` & Animated SVG** | W3C CSS Animations + Splitting.js | **Stylo** (Firefox CSS engine via Blitz) + **ThorVG** | Standard CSS rules and custom properties (`--duration`, etc.) evaluate natively without a browser. |
| **p5.js / Paper.js / Two.js / Hydra / TSL / Lottie** | Upstream JS libraries / Bodymovin JSON | QuickJS-ng / **ThorVG** (+ JerryScript for Lottie expressions) | Pasted sketches and files run on the real upstream libraries rather than hand-written emulators. |

---

## 2. Writing native WGSL shaders (WESL UI attributes)

Declare parameters directly on your `var<uniform>` struct so the GPU layout and Inspector UI share a single source of truth — no duplicate header comments required.

```wgsl
// My Glow: soft highlight glow
// --label:Stylize
// --about:Adds a tinted glow to bright pixels.
// --spill

struct Knobs {
  @auto time: f32,
  @auto resolution: vec2<f32>,

  @range(0, 8, 0.01, 1)      intensity: f32,
  @range(0, 200, 0.5, 25)    threshold: f32,

  @group("Tone")
  @label("Glow Tint")
  @color(1.0, 0.89, 0.77)    tint: vec3<f32>,
  @point(0.5, 0.5)           center: vec2<f32>,
  @toggle(0)                 glowOnly: u32,
};

@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var picture_sampler: sampler;
@group(0) @binding(2) var<uniform> knobs: Knobs;
```

### Supported attributes

| Attribute | Target types | Inspector control | Notes |
|---|---|---|---|
| `@range(min, max[, step[, init...]])` | `f32`, `i32`, `u32`, `vec2`, `vec3`, `vec4` | Numeric slider(s) | `step` defaults to `0.01` (`f32`) or `1` (`i32`/`u32`); `init` defaults to `min`. Vector types expand into `<name>_x`, `<name>_y`, … (matching `screen_resources.cpp` uniform packing). |
| `@toggle([init])` | `u32`, `i32`, `f32` | On/off switch (`0` or `1`) | `init` defaults to `0`. |
| `@color(r, g, b[, a])` | `vec3f` / `vec3<f32>`, `vec4f` / `vec4<f32>` | Color channels (`0..1`) | Expands to `<name>_x`..`_z` (or `_w`) labeled `R`, `G`, `B` (`A`). |
| `@point(x, y)` | `vec2f` / `vec2<f32>` | 2D coordinates (`0..1`) | Expands to `<name>_x`, `<name>_y` labeled `X`, `Y`. |
| `@group("Name")` / `@group()` | Struct scope | Collapsible Inspector group | Groups subsequent fields until the next `@group(...)` or empty `@group()`. Standard WGSL `@group(0)` numeric bindings are never touched. |
| `@label("Text")` | Next field | Custom display label | Optional; omitted labels are auto-capitalized from the field name (`colourStrength` → `Colour Strength`). |
| `@auto` | Built-in fields | Hidden from UI | Marks stage-supplied fields (`time`, `frame`, `aspect`, `resolution`, `frameRect`, `passRect`, `passindex`, `screen`, `layer`, `duration`, etc.). |

### Shader metadata & multi-pass directives

Pipeline-level directives remain short single-line comments at the top of the file:

- `// Name: description` — display name (line 1)
- `// --label:Category`, `// --about:Description`, `// --tag:tag1 tag2` — shelf metadata
- `// --spill` / `// --alpha` — layer bounds expansion / alpha override
- `// --pass@target:persistent,fine,width,height` — multi-pass render targets (`fine=1` uses RGBA16F; `s0.5` scales relative to stage; empty target writes final output)
- `// --picture@name:Label` / `// --image@name:file` / `// --history@frames:share` — extra texture inputs

All 274 bundled `.wgsl` effects under `shelves/effects/` use this format (see [`shelves/effects/stylize/halo_glow.wgsl`](../shelves/effects/stylize/halo_glow.wgsl) and [`shelves/effects/sources/to_wesl.py`](../shelves/effects/sources/to_wesl.py)).

### Compute geometry modifiers (`@compute`)

`.wgsl` files containing `@compute` deform the vertices of a layer's `solids/` mesh (flat layers automatically mount onto `solids/Plane.js`). They support the exact same WESL UI attributes on their uniform struct (`wgsl_strip_ui_attributes()` strips them before Dawn compilation). See [`shelves/README.md`](../shelves/README.md) for Group 0 storage buffer bindings.

---

## 3. Writing native JavaScript (`leva` knobs)

For `expressions/`, `relations/`, and `solids/`, declare parameters at the top of the file with [`leva`](https://github.com/pmndrs/leva) syntax:

```js
const knobs = {
  height: { value: 0.5, min: 0, max: 2, step: 0.01 },
  spin: false,
  Advanced: folder({
    speed: { value: 1.0, min: 0, max: 5 },
  }),
};

function each(i, n, t, k) {
  return { y: k.height * Math.sin(t * k.speed + i) };
}
```

See [`shelves/README.md`](../shelves/README.md) for the complete `each`, `relate`, `force`, `solid`, and recipe APIs.

---

## 4. Code tab & external IDE workflow

- **Syntax highlighting:** Dedicated highlighting for WGSL (including WESL `@range`/`@color`/`@toggle` attributes), GLSL/ISF, JavaScript, CSS, and Lua.
- **Header folding:** Files with 3+ leading `// --` directives automatically fold the directive block into a single `Header (N directives)` toggle bar so code starts on line 1; expanding edits the raw directives, and saving always preserves the full file.
- **Open in IDE (`🔗` button in every Code cell header):**
  - Detects `$VISUAL` / `$EDITOR`, then installed IDEs (`Cursor`, `VS Code`, `Zed`, `Windsurf`, `Antigravity`), falling back to the OS default editor.
  - If the file is still a bundled shelf original or shared with another layer, clicking the button creates a layer-local copy first (copy-on-write) so bundled originals are never overwritten.
  - Saving in your external IDE hot-reloads the Stage automatically.
- **Native AE plugin hot-reload:** Rebuilding a `.plugin` / `.aex` binary externally (Xcode, Cargo, Visual Studio) updates its modification stamp (including `Contents/MacOS/*` inside macOS bundles), automatically restarting the isolated worker and refreshing the Stage without restarting Motolii.
