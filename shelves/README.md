# `shelves/` — Bundled & User Content

[日本語](README.ja.md)

This directory holds Motolii's bundled effects, scripts, presets, and skins. To add your own files, create matching folders inside your **user folder**:

- **macOS:** `~/Library/Application Support/Motolii/`
- **Windows:** `%APPDATA%\Motolii\`
- **Override:** set the `MOTOLII_OWN` environment variable

Files placed in your user folder appear in Motolii immediately without restarting. If a file has the same name as a bundled one, your user file takes precedence.

## Where each file type goes

Match from the top down; folders live inside your user folder above.

| Asset / format | Destination |
|---|---|
| ISF shader (`.fs`) or WGSL shader (`.wgsl`) | `effects/` (any subfolder) |
| Native After Effects plugin (`.plugin` on macOS, `.aex` on Windows) | `ae_plugins/` (copy or symlink file/folder; never bundled by Motolii) |
| AviUtl2 script package (`.anm2`, `.obj2`, `@` files) | `aviutl_scripts/` (entire package folder) |
| Per-copy / per-character animation script (`function each`) | `expressions/` |
| After Effects expression (`wiggle(2, 50)`, `thisComp...`) | `expressions/` (`.js` containing only the expression). Add `// --property:position` (`rotation`, `scale`, or `opacity`) on line 1 to target a property; otherwise 2D arrays map to position and scalars to rotation |
| CodePen CSS text animation (`@keyframes` using Splitting.js `.char` / `.word`) | `expressions/` (`.css`, plus optional matching `.html`), or paste directly onto a text layer with `⌘V` |
| Multi-layer relation script (`function relate` / `function force`) | `relations/` |
| Layer recipe (`// make` lines), point distribution script, or p5.js sketch file | `create/` |
| Easing formula (`.way`) | `ease/` |
| Saved layer look preset (`.motolii`) | `looks/` |
| 3D geometry generator (`export function solid` in `.js`) | `solids/` |
| UI skin folder | `skins/` (entire folder) |
| three.js TSL page (`colorNode` / `positionNode`) | **Paste (`⌘V`).** Color nodes become effects and position nodes become geometry modifiers on the selected layer (or a full-canvas rectangle if none selected). Saved in `<user>/programs/` |
| Shadertoy, GLSL Sandbox, twigl, Bonzomatic, p5.js, Dwitter, tixy, Turtletoy, Two.js, Paper.js, Hydra | **Paste (`⌘V`) instead of placing files.** Saved under Code in the Create tab. (Hydra requires running `extensions/hydra/get.sh` once.) |

Leading comment lines declare display names and parameters (see [Header directives](#header-directives)).

## `.js` script contracts

Every `.js` shelf file starts with a header of consecutive `//` comment lines (and blank lines) declaring its name and parameters. The header ends at the first line of code.

### Motion scripts: `expressions/` (`function each`)

Computes transform and style overrides for one copy or text unit at a time.

```js
// Rise: each copy lifts a little higher than the one before, and fades in
// --track@height:Height,0,2,0.5,0.01
function each(i, n, t, k) {
  return { y: k.height * i / Math.max(1, n - 1), opacity: Math.min(1, t * 2) };
}
```

| Item | Details |
|---|---|
| Function name | `each` (runs as a classic script; `import` is not available) |
| `i` | 0-based copy index |
| `n` | Total copy count. For split text: character, word, or line count (`Lines` splits on explicit line breaks; each line rotates and scales around its own center) |
| `t` | Seconds elapsed since the layer's start |
| `k` | Declared parameters (`--track` and `--check` as numbers, `--check` as `0`/`1`, `--select` as the chosen string), plus built-ins: `k.duration` (layer duration in seconds; `<= 0` if unset), `k.round` (project duration in seconds), `k.px` (1 pixel in stage units), `k.wide` / `k.high` (composition pixels), `k.id` (layer ID), `k.time` (composition time in seconds) |
| `at` (5th arg, optional) | `{ x, y, z }` accumulated by the layer's script and preceding expressions (`0` if none) |
| Return object | Optional keys: `x`, `y`, `z` (stage units), `size`, `scale_x`, `scale_y`, `scale_z` (`1` = unchanged), `rotate`, `rotate_x`, `rotate_y` (degrees), `opacity` (`0..1`), `colour` (3D solid copy color). Omitted or non-numeric keys remain unchanged |
| Stacking behavior | Positions and rotations add; `size`, `scale_*`, and `opacity` multiply; `colour` uses the last returned value |
| Rigid bodies (Jolt Physics) | Returning `mass` turns the copy into a 2D rigid-body box simulated by Jolt Physics. `mass: 0` creates a kinematic body (e.g. a floor) following layer keyframes. Optional Jolt fields: `force` (`[x, y]` in newtons, summed across expressions), `gravityFactor`, `restitution`, `friction`. Scale: `1 m = 100 px`. See `rigid_body.js` and `wind.js` |
| Built-in helpers | `ease(name, u)` (`u` in `0..1`; `SlowIn`, `SlowOut`, `SlowInSlowOut`, `VerySlowIn`, `VerySlowOut`, `SpringOut`, `SmallSpringOut`, `BounceOut`, `Overshoot`; unknown names return `u`). `animate(i, n, t, k, a)` (Cavalry Animator style; `a = { what, from, to, way }`, optional `out`, `random`, `seed`; requires `k.length` and `k.delay`; see `expressions/fade_in.js`). `cavalry.random(low, high, seed, sequence)`. `AE.compile` / `AE.run` (see `create/repeats/ae_stagger.js`) |
| Cross-layer & audio APIs | `layerValue(id, name, t, fallback, copy)`, `sampleImage(id, point, radius, postEffect, t)`, `fromWorld(id, point, t)` (see Relations below). Declare `// --picture@video:Video` to pick a layer (`k.video` = layer ID). `layerValue(k.id, 'x', k.time, 0, i)` reads copy `i`'s pre-expression position (see `expressions/away_from_dark.js`). Audio: `getByteFrequencyData(id, array, t)`, `getFloatFrequencyData(id, array, t)`, `getFloatTimeDomainData(id, array, t)` with `// --sound@sound:Sound,fft,512` (see `expressions/rise_to_sound.js`). Files using these 6 APIs run single-threaded |
| Not available | p5.js globals (`sin`, `PI`, `random`, `noise`, `createVector`, etc.) — use standard `Math.*` |

### Relations: `relations/` (`function relate` or `function force`)

Operates on multiple layers (`things`) simultaneously. Runs in a p5.js environment, so `sin`, `TWO_PI`, `lerp`, `constrain`, `noise`, `createVector`, `ease`, etc. are available.

`relate` returns updated properties per item:

```js
// Wave: oscillates each layer vertically based on its X position
// --track@height:Height,0,2,.45,0.01
// --track@speed:Speed,0,4,.6,0.01
function relate(things, t, k) {
  return things.map(a => ({ i: a.i, y: a.y + k.height * sin(a.x * 2 + t * k.speed * TWO_PI) }));
}
```

| Item | Details |
|---|---|
| `things[i]` fields | `i` (index), `id` (layer ID), `w` / `h` (current width/height including scale), `near` (`0..1` Falloff weight; `1` if no Falloff), `from` (`{ x, y }` position when added to the relation, or `NaN`; e.g. `a.x + target - a.from.x` preserves user offsets — see `relations/Row.js`), plus `x`, `y`, `z`, `size`, `rotate`, `rotate_x`, `rotate_y`, `opacity` |
| `t`, `k` | Composition time in seconds and declared parameters. `// --picture@leader:Leader` provides a layer picker (`k.leader` = layer ID, `0` if none) |
| `layerKeys(id, name)`, `layerNamed(name)` | Sorted keyframe timestamps in seconds for `name` on layer `id` (`[]` if none); layer ID by name (`0` if not found) |
| `layerValue(id, name, t, fallback, copy)` | Evaluates `name` (`x`, `y`, `z`, `size`, `rotate`, `rotate_x`, `rotate_y`, `opacity`) on layer `id` at time `t` including relations (`fallback` if unkeyed; see `relations/Follow.js`). With 0-based `copy`, returns that copy/character's center including CSS, scripts, and delay (see `relations/Letter.js`). Returns `NaN` for unknown names |
| `sampleImage(id, point, radius, postEffect, t)` | After Effects-compatible `sampleImage`: returns alpha-weighted average `[r, g, b, a]` (`0..1`) over `radius` (`[rx, ry]`, default `0.5 px`) around `point` in layer pixel coordinates (`[0, 0]` = top-left pixel center) at time `t`. Reads source files for image layers and decoded frame at `t` for video layers; returns `[0, 0, 0, 0]` outside bounds or for other layer types. `postEffect` is accepted for compatibility but currently reads pre-effect source pixels |
| `fromWorld(id, point, t)` | Converts a stage-unit point (`[x, y]` or `[x, y, z]`) into layer `id`'s pixel coordinates at time `t` for passing to `sampleImage`. Returns `[NaN, NaN]` for non-image layers |
| `getByteFrequencyData`, `getFloatFrequencyData`, `getFloatTimeDomainData` | Web Audio `AnalyserNode` equivalents ([W3C Web Audio API](https://www.w3.org/TR/webaudio-1.1/#AnalyserNode)) taking `(id, array, t)` on any video or audio layer. 1024 frequency bins (`bin i = i × 23.4375 Hz`, matching `fftSize = 2048` at `48 kHz`), byte values mapped from `-100 dB..-30 dB` to `0..255`; time-domain fills latest 2048 samples (`-1..1`). Deterministic per timestamp; silent when muted or inactive |
| `lag` parameter | A track named `lag` staggers each layer's Strength evaluation by `lag` seconds (see `relations/Group.js`) |
| Return value | Array of `{ i, ...changedFields }`, or return `undefined` to mutate `things` in place |
| Falloff weighting | With 3 parameters (`things, t, k`), output deltas are weighted by `near` |
| Stateful 4th arg | `relate(things, t, k, was)` receives the previous frame's return value (looked up by `i`; `null` on frame 0). Disables automatic `near` attenuation so you can apply `near` manually (see `relations/stay.js`). Simulated sequentially from `t = 0` at 60 fps |

`force` applies forces in place (d3-force convention) and returns nothing:

```js
// Spring: pulls each layer toward its home position with damping
// --track@mass:Mass,.05,10,1,0.01
// --track@damping:Damping,0,30,4,0.01
// --track@limit:Speed Limit,0,60,60,0.1
function force(things, t, k) {
  const pull = 1 / (60 * k.mass), keep = 1 - k.damping / 60, most = k.limit / 60;
  things.forEach(a => {
    a.vx = (a.vx + (a.home.x - a.x) * pull) * keep, a.vy = (a.vy + (a.home.y - a.y) * pull) * keep, a.vz = (a.vz + (a.home.z - a.z) * pull) * keep;
    const s = sqrt(a.vx * a.vx + a.vy * a.vy + a.vz * a.vz);
    if (s > most) a.vx *= most / s, a.vy *= most / s, a.vz *= most / s;
  });
}
```

In `force`, items additionally have `vx`, `vy`, `vz`, `home` (`{ x, y, z }` rest position), and `index`. Properties written back: `x`, `y`, `z`, `size`, `rotate`, `rotate_x`, `rotate_y`, `opacity`, `vx`, `vy`, `vz` (custom properties persist across frames). Referencing `d3.` enables `d3-force-3d` (see `relations/collide.js`). Simulated sequentially at 60 fps.

### Recipes: `create/` (`// make` directives)

Line 1 defines the recipe name; subsequent comment commands create layers and assign properties. Code is optional.

```js
// White Flash: brief full-screen white flash at the playhead (0.4s)
// make shape rect
// here
// say fill ffffff
// fit fill
// set duration 0.4
// key opacity 0 1
// key opacity 0.4 0
```

Adding `function each(...)` below the header attaches this file as the first layer's script:

```js
// Bobbing Row: five dots bobbing out of phase
// make shape circle
// say fill ffd166
// set size 0.1
// set copies 5
// --track@height:Height,0,1,0.3,0.01
function each(i, n, t, k) {
  return { x: (i - (n - 1) / 2) * 0.3, y: k.height * Math.sin(t * 4 + i) };
}
```

| Directive | Meaning |
|---|---|
| `make <kind> <value>` | Creates the first layer (must be the first directive). Shapes: `make shape rect` (`rect`, `circle`, `polygon`, `star`, `line`, `ring`, `arc`, `arrow`, `squircle`, `cog`, `path`, `spiral`, `chamfer`, `null`). Solids: `make solid cube` (`ring`, `gem`, `cube`, `ball`, `sketch`). Images: `make picture <path>` |
| `then <kind> <value>` | Creates another layer; subsequent `set`/`say`/`key` lines apply to it |
| `set <prop> <value>` | Sets a numeric property (see `engine/document/kinds.h`; script params use `js_<name>`). Special values: `first` (first layer ID), `before` (previous layer ID), `behind` (just below the first layer) |
| `say <prop> <text>` | Sets a string property (`fill ff3366`, `path M 0 0 ...`, `copy_fill ...`). For `script`: `this` attaches this file, a recipe name (e.g. `Repeater`) attaches that recipe, or a shelf path (`expressions/wave.js`) |
| `here` | Starts the layer at the playhead (default: `t = 0`). `key` timestamps are relative to this start |
| `fit fit` / `fit fill` / `fit stretch` | Scales the layer to fit inside, cover, or stretch to the composition |
| `key <prop> <seconds> <value>` | Inserts a keyframe at `<seconds>` |

Notes:
- Avoid starting prose comments in the header with command keywords (`make`, `then`, `set`, `say`, `here`, `fit`, `key`); unrecognized comment lines are ignored.
- Files defining `function each` also appear under Expression in the Create tab.
- A p5.js sketch without `// make` (containing `function draw`, `function setup`, or `createCanvas`) is automatically registered as a recipe using its filename.

### p5.js sketches

```js
function setup() { createCanvas(400, 400); }
function draw() {
  background(20);
  circle(200 + 100 * sin(frameCount / 30), 200, 60);
}
```

- Runs p5.js 1.11.13 natively (headless, no browser) sequentially at 60 fps.
- 2D sketches render as image layers fitted to the composition; `WEBGL` primitives (`box`, `sphere`, `plane`, `ellipsoid`, `cylinder`, `cone`, `torus`) become 3D solid copies.
- Each drawing call automatically exposes a strength slider (e.g. `circle 3`).
- `loadImage` loads assets by filename from a sibling folder matching the sketch name (`Fire/` for `Fire.js`).
- `p5.sound` works if `p5.sound.min.js` is placed at `engine/third_party/js/p5/addons/p5.sound.min.js` (not bundled in git). Sketches read audio from underlying video/audio layers matching Chrome's `p5.FFT` / `p5.Amplitude` values. Click-to-start sketches receive one synthetic click; sketch oscillators are muted during export.

### Easing presets: `ease/` (`.way`)

Line 1 is the display name, followed by a formula expression:

```
// Snappy: fast launch with a soft landing
a + (b - a) * bezier(u, .2, 0, 0, 1)
```

Variables: `a` (start value), `b` (end value), `u` (progress `0..1`), `p1`–`p4` (numeric parameters). The formula should evaluate to `a` at `u = 0` and `b` at `u = 1`. Helpers: `bezier(u, x1, y1, x2, y2)` and `way('Name', u)`.

### Other formats

- **After Effects expressions (`expressions/`):** Plain `.js` containing only the expression. `index` / `textIndex` are 1-based. Values follow AE conventions (position in top-left pixels with Y down, clockwise degrees, scale/opacity in percent). Supports `effect("Label")("Slider")`, bare `position`/`rotation`/`scale`/`opacity`/`transform`, `valueAtTime(t)`, `loopOut()`/`loopIn()` (`cycle`, `pingpong`, `offset`, `continue`), `thisComp.layer("Name")` (`transform`, `sampleImage`, `fromWorld`). Expressions referencing `index`/`textIndex`/`textTotal` evaluate per copy/character; others affect the whole layer.
- **3D solids (`solids/`):** `export function solid(k)` returning a three.js `BufferGeometry` (`k` includes parameters plus `k.w`, `k.h`; see `solids/Box.js`).
- **WGSL fragment effects (`effects/*.wgsl`):** Declare parameters either with WESL-style UI attributes directly on your `var<uniform>` struct (`@range(min, max[, step[, initial]])`, `@toggle([initial])`, `@color(r, g, b)` on `vec3f`, `@point(x, y)` on `vec2f`, `@group("Name")`, `@label("Text")`, `@auto` — following [wgsl-play](https://wesl-lang.dev/docs/wgsl-play)) or with leading `// --track@` comments. Return color from `fn fs_main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f`. Built-in uniform fields `time`, `frame`, `aspect`, `resolution`, `width`, `height` are populated automatically (see `effects/stylize/halo_glow.wgsl` and `effects/glitch/rgbshift.wgsl`).
- **ISF shaders (`effects/*.fs`):** Standard Vidvox ISF files, used directly.
- **WGSL compute geometry modifiers (`effects/*.wgsl` with `@compute`):** Deforms vertices of a layer's `solids/` mesh every frame (flat layers automatically mount onto `solids/Plane.js`). Group 0 bindings: `0` uniform struct of `f32` (`time`, then `--track@` params in order); `2` source positions (`array<f32>`, xyz); `4` UVs (uv); `6` output positions; `8` source normals (xyz); `10` output normals (zero preserves source normal); `12` source tangents (xyzw). Declare only bindings you use. Entry point: `@compute @workgroup_size(64)` with `global_invocation_id.x` as vertex index (see `effects/geometry/tg_simple_points.wgsl`).

## Header directives

Line 1 has the form `// Name: description` (text before `:` becomes the display name; omitted headers, `.fs` files, and bare p5.js sketches fall back to the filename).

Parameters use `// --<kind>@<name>:<Label>,...` where `<name>` is read in code as `k.<name>` (both `@` and `:` are required):

| Directive | Meaning |
|---|---|
| `// --track@name:Label,min,max,default,step` | Numeric slider (`step` optional) |
| `// --check@name:Label,default` | Boolean toggle (`0` or `1`) |
| `// --select@name:Label,opt1,opt2,...` | Dropdown (`opt1` is default; `k.name` holds the selected string) |
| `// --picture@name:Label` | Layer image input (effects only) |
| `// --sound@name:Label,fft,512` | Audio layer picker (`k.name` = layer ID, `0` if none; in ISF, configures `fft`/`wave` audio input) |
| `// --group:Name` … `// --group` | Collapsible parameter group |
| `// --macro@name:Label,default -> param min max, ...` | Single `0..1` macro driving multiple parameters |
| `// --label:Category` | Shelf category (marks a closed pack in `create/`) |
| `// --about:Description` | Short description shown in the Effects shelf |
| `// --tag:tag1 tag2` | Extra search tags (e.g. `#basic`), merged with auto-detected tags |

A leading `const knobs = { distance: 2, ... }` block (leva syntax) is also supported.

## Hot reload

Saving a file in any shelf folder updates Motolii immediately without restarting, and re-saving an active effect updates the Stage live.

- `effects/`, `ae_plugins/`, `aviutl_scripts/`: appear in the **Effects** tab.
- `create/`: appear under Recipes in the **Create** tab.
- `expressions/`, `relations/`: appear under Expression in the **Create** tab (applying a relation to a group or multi-selection drives all selected layers together; on a single layer it drives copies or characters).

## Folder reference

| Folder | Appears in | File types | Display name |
|---|---|---|---|
| `effects/` | Effects tab | `.fs` (ISF), `.wgsl`, `.js` (three.js), `.mjs`, `.json` (Filament settings) | `// Name:` or filename (`.fs` always uses filename) |
| `ae_plugins/` | Effects tab (subfolders become Packs) | `.plugin` (macOS), `.aex` (Windows) — user-placed or symlinked only | Cleaned filename stem (`_` → space) |
| `aviutl_scripts/` | Effects tab (package becomes a Pack) | AviUtl2 packages (`.anm2`, `.obj2`, `@` files) | Script name & `--label:`; pack name follows `__` |
| `create/` | Create tab (Recipes; `function each` also in Expression) | `.js` | `// Name:` (bare p5 sketches use filename) |
| `expressions/` | Create tab (Expression) | `.js`, `.css` | `// Name:` |
| `relations/` | Create tab (Expression) | `.js` | `// Name:` or filename |
| `looks/` | Effects / Looks tab | `.motolii` + `.png` thumbnail | Exact filename |
| `solids/` | 3D solid shapes referenced by layers | `.js` (`export function solid`) | `// Name:` |
| `ease/` | Ease shelf | `.way` | `// Name:` or filename |
| `workspaces/` | Top-bar Code workspace | `code.layout` | `Code` (`Standard` is defined in `app/lib/workspace/workspace_panes.dart`) |
| `skins/` | `View › Skin` menu | Folder (`theme.xml`, assets, fonts; see [`skins/README.md`](skins/README.md)) | Folder name |
| `extensions/` | Utility scripts (not a shelf) | `hydra/get.sh` | — |

Legacy user folder names (`recipes/`, `animators/`, `ways/`) remain supported for backward compatibility.

## Subfolders

`effects/` and `create/` are scanned recursively; subfolder names are organizational only and do not appear in the UI, so moving files between subfolders will not break saved projects.

`effects/` subfolders mirror [After Effects' Effects & Presets categories](https://helpx.adobe.com/after-effects/desktop/apply-effects-and-animation-presets/effects-and-animation-presets/effect-list.html):

| Subfolder | AE category | Contents |
|---|---|---|
| `blur/` | Blur & Sharpen | Blur and sharpen filters |
| `color/` | Color Correction | Color and tonal adjustments |
| `distort/` | Distort | Spatial warps and distortions |
| `generate/` | Generate | Procedural patterns, waveforms, shapes |
| `stylize/` | Stylize | Halftones, glow, outlines, looks |
| `transition/` | Transition | Image-to-image transitions |
| `key/` | Keying & Matte | Chroma/luma keying and mattes |
| `utility/` | Utility | Diagnostic and utility shaders (alpha, color bars, timecode) |
| `move/` | *(none)* | Time-based motion effects (AE handles these via expressions) |
| `geometry/` | *(none)* | Shapes, 3D transforms, flips (`Geometry Adjustment` in ISF) |
| `glitch/` | *(none)* | Datamosh, VHS, RGB split (`Glitch` in ISF) |
| `sources/` | *(metadata)* | Pack licenses, conversion scripts, sample preview images, AviUtl maps (referenced by 257 shader headers — do not rename) |

`create/` subfolders:

| Subfolder | Contents |
|---|---|
| `shapes/` | Single vector shapes (AbsentMotion shapes) |
| `cavalry/` | Point distributions (Cavalry Distributions) |
| `repeats/` | Repeater / Duplicator presets |
| `over_footage/` | Overlays (tracking boxes, flashes, posters) |

## Intentionally minimal folders

- `extensions/hydra/` contains only `get.sh` because Hydra (`hydra-synth`) is AGPL-3.0 and is never bundled. Running `get.sh` installs it into your user folder (`extensions/hydra/`).
- `ease/` ships only one sample (`snappy.way`); custom easing presets belong in your user `ease/` folder.

## Naming rules

Saved projects reference shelf items by filename, so **never rename already-shipped files** even if their display name comes from a comment header.

- Files using `// Name:` headers (`effects/` `.js`/`.wgsl`, `create/`, `expressions/`, `relations/`, `solids/`, `ease/`): preserve upstream filenames where applicable (`solids/` uses snake_case; `create/shapes/am_*` follows AbsentMotion).
- Files whose filename is displayed directly (`looks/`, `effects/*.fs`, bare p5.js sketches, headerless `relations/`): use readable capitalization and spaces.
- `aviutl_scripts/`: `<author>__<package>/` matching the AviUtl2 catalog, containing the unmodified package plus `LICENSE` and `SOURCE.txt`.
- Keep internal helper modules (such as `face_uv.js`) inside `engine/community/` rather than `shelves/` — every file under `shelves/` should represent one user-facing item.

## Data stored outside `shelves/`

- Built-in fallback fonts (Noto Sans JP), font preview samples (`gflanguages`), and the Japanese-to-English search dictionary (Japanese WordNet) live under `engine/third_party/`. Files placed in your user `fonts/` or `words/` folders extend them.
- For how each folder is loaded in code, see [`docs/ARCHITECTURE.md#where-the-shelves-are-read`](../docs/ARCHITECTURE.md#where-the-shelves-are-read).
- Generation scripts (`effects/sources/`, `create/shapes/absent_shapes.sh`) are run manually and are not part of the build.
