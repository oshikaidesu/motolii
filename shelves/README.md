# shelves/ — where to put a look you found

[日本語](README.ja.md)

What Motolii has from the start, and where to put a look you found. If you are placing a file, read "Which kind is my file?" next.

Put it in your own folder (`~/Library/Application Support/Motolii/` on a Mac, `%APPDATA%\Motolii\` on Windows, or `MOTOLII_OWN`): make a folder there of the same name as one below and put the file in it. It shows in the same place at once, no restart. A file of the same name there wins over the one here.

## Which kind is my file?

Take the first row that fits. The folder goes inside your own folder (above).

| What you found | Where it goes |
|---|---|
| An ISF shader (`.fs`) or a WGSL shader (`.wgsl`) | `effects/` (any category folder inside) |
| JavaScript that decides, for one copy or letter at a time (the `i`-th), where it is and how (`function each`) | `expressions/` |
| A CodePen pen's CSS that moves letters (`@keyframes`, with Splitting.js's `.char` and `.word`) | `expressions/` (a `.css`; an `.html` of the same name beside it is the pen's HTML). Or paste it on a text with ⌘V |
| JavaScript that moves several layers together, looking at where the others are (`function relate`, `function force`) | `relations/` |
| Something that builds a picture or shape in one go (a `.js` with `// make` lines), a script that lays out points, a p5.js sketch as a file | `create/` |
| An easing formula (`.way`) | `ease/` |
| A saved set of values and effects (`.motolii`) | `looks/` |
| A 3D shape (a `.js` with `export function solid`) | `solids/` |
| The look of the app | `skins/` (the whole folder) |
| An AviUtl2 package | `aviutl_scripts/` (the whole folder) |
| A Shadertoy, GLSL Sandbox, twigl or Bonzomatic shader; p5.js, Dwitter, tixy, Turtletoy, Two.js, Paper.js or Hydra code | **Paste it, do not place it.** Copy the code and press ⌘V in the app. It stays in the Program tab. (Hydra first needs `extensions/hydra/get.sh`.) |

A file says its name and its sliders in its first lines. See "How a file's head is written" below.

## The contract of a `.js` file

Every `.js` starts with `//` lines (the head) giving its name and sliders, then the code. The head is the run of `//` lines and blank lines at the top; it ends at the first line of code.

### A motion: `expressions/` (`function each`)

It returns where one copy is and how.

```js
// Rise: each copy lifts a little higher than the one before, and fades in
// --track@height:Height,0,2,0.5,0.01
function each(i, n, t, k) {
  return { y: k.height * i / Math.max(1, n - 1), opacity: Math.min(1, t * 2) };
}
```

| Item | What it holds |
|---|---|
| Function name | `each`. The file runs as a plain script, so `import` is not available |
| `i` | This copy's number, from 0 |
| `n` | How many copies. For a text it is how many pieces its Split makes: its letters, its words, or its lines (Lines: one copy for each line the text has, cut where the text itself breaks; a line turns and scales about its own middle) |
| `t` | Seconds since the layer began |
| `k` | The sliders the head declares. `--track` and `--check` are numbers (a check is 0 or 1); `--select` is the chosen word. Also `k.duration` (how long the layer lasts, in seconds; 0 or less means not set), `k.round` (how long the project runs, in seconds), `k.px` (one pixel of the project, in stage units), `k.id` (this layer's number) and `k.time` (the project's second now; `t` counts from where the layer begins) |
| `at` (fifth, optional) | `at.x`, `at.y`, `at.z`: where this layer's script and the expressions before this one have put the copy so far (0 if none) |
| Returns | An object. The names read are `x`, `y`, `z` (stage units), `size`, `scale_x`, `scale_y`, `scale_z` (1 is unchanged), `rotate`, `rotate_x`, `rotate_y` (degrees), `opacity` (0 to 1), `colour` (a solid copy's own colour). A name you leave out, or a value that is not a number, stays as it was |
| Several expressions on one layer | Positions and angles add. `size`, `scale_*` and `opacity` multiply. `colour` is the last one given |
| Helper functions | `ease(name, u)` (`u` is 0 to 1; names `SlowIn`, `SlowOut`, `SlowInSlowOut`, `VerySlowIn`, `VerySlowOut`, `SpringOut`, `SmallSpringOut`, `BounceOut`, `Overshoot`; any other name returns `u`). `animate(i, n, t, k, a)`, shaped like a Cavalry Animator (`a` is `{ what, from, to, way }`, optionally `out`, `random`, `seed`; it reads `k.length` and `k.delay`, so declare them in the head; example: `expressions/fade_in.js`). `cavalry.random(low, high, seed, sequence)`. For After Effects expressions: `AE.compile` and `AE.run` (example: `create/repeats/ae_stagger.js`) |
| Reading other layers | `layerValue(id, name, t, otherwise, copy)`, `sampleImage(id, point, radius, postEffect, t)` and `fromWorld(id, point, t)`, as under "A relation" below. A `// --picture@video:Video` line is a layer picked on the card; `k.video` is its number. `layerValue(k.id, 'x', k.time, 0, i)` is where copy `i` of this layer is before this expression moves it (example: `expressions/away_from_dark.js`, whose letters read the video under them). The sound of a layer is read with `getByteFrequencyData(id, array, t)`, `getFloatFrequencyData(id, array, t)` and `getFloatTimeDomainData(id, array, t)`; a `// --sound@sound:Sound,fft,512` line is the layer picked for it (example: `expressions/rise_to_sound.js`, whose letters each rise with their own part of the pitch range). A file that names one of the six runs on one thread |
| Not available | p5.js functions and constants (`sin`, `PI`, `random`, `noise`, `createVector`, ...). Write `Math.sin` |

### A relation: `relations/` (`function relate` or `function force`)

It receives all the layers (`things`) at once. p5.js runs it, so `sin`, `TWO_PI`, `lerp`, `constrain`, `noise`, `createVector`, `ease` and the rest are there.

`relate` returns new values.

```js
// Wave: each goes up and down by where it stands along the row
// --track@height:Height,0,2,.45,0.01
// --track@speed:Speed,0,4,.6,0.01
function relate(things, t, k) {
  return things.map(a => ({ i: a.i, y: a.y + k.height * sin(a.x * 2 + t * k.speed * TWO_PI) }));
}
```

| Item | What it holds |
|---|---|
| One of `things` | `i` (its number), `id` (the layer's number), `w` and `h` (width and height now, size included), `near` (0 to 1: how much the relation's Falloff shape covers it; 1 with no Falloff), `from` (`x` and `y`: where it showed when it joined, `NaN` where that is not known; `a.x + place - a.from.x` adds only the step from there to `place`, so a layer the user moved stays moved; example: `relations/Row.js`), and `x`, `y`, `z`, `size`, `rotate`, `rotate_x`, `rotate_y`, `opacity` (its values now) |
| `t`, `k` | Seconds; the sliders (as above). A `// --picture@leader:Leader` line is a layer picked on the card: `k.leader` is its number, 0 for none |
| `layerValue(id, name, t, otherwise, copy)` | What layer `id` shows for `name` (`x`, `y`, `z`, `size`, `rotate`, `rotate_x`, `rotate_y` or `opacity`) at second `t`, relations included. `otherwise` is given where the layer has no keyframes for it (example: `relations/Follow.js`). With `copy` (from 0), `x`, `y` and `z` are where the middle of that copy (a split text's letter) is, its CSS, script and delay taken in (example: `relations/Letter.js`). `NaN` for any other name |
| `sampleImage(id, point, radius, postEffect, t)` | After Effects' `sampleImage` of layer `id`: `[red, green, blue, alpha]`, each 0 to 1, averaged by alpha over the rectangle `radius` (`[x, y]`, left out: half a pixel) around `point`, in the layer's own pixels (`[0, 0]` is the centre of its upper-left pixel), at second `t`. An image layer is read from its file; a video layer from the frame it shows at `t`. Any other layer, and what lies outside the picture, gives `[0, 0, 0, 0]`. `postEffect` is taken and not used yet: the file is read, before the layer's masks, key and effects |
| `fromWorld(id, point, t)` | After Effects' `fromWorld`: where a point of the stage (`[x, y]` or `[x, y, z]` in stage units, as `layerValue` gives them) is in the pixels of layer `id` at second `t`, to hand to `sampleImage`. `[NaN, NaN]` for a layer with no picture to read |
| `getByteFrequencyData(id, array, t)`, `getFloatFrequencyData(id, array, t)`, `getFloatTimeDomainData(id, array, t)` | The Web's `AnalyserNode` methods of the same names ([W3C Web Audio API](https://www.w3.org/TR/webaudio-1.1/#AnalyserNode)), with the layer's number first and the second last, on the sound of video or sound layer `id`. The first fills a `Uint8Array` with how strong each pitch is, 0 to 255; the second a `Float32Array` with the same in decibels (the bytes run from -100 dB to -30 dB). There are 1024 pitches, pitch `i` at `i` × 23.4375 Hz: what an `AnalyserNode` as it comes (an `fftSize` of 2048) gives on a 48,000 Hz page that asks sixty times a second. A shorter array takes the lowest pitches. The third fills a `Float32Array` with the latest 2048 samples of the wave, each -1 to 1. Silence while the layer is not on or has no sound. The same second always gives the same numbers |
| A track called `lag` | Each layer's Strength is read that many seconds later than the one before's, so a Strength that rises over time reaches them one after another (example: `relations/Group.js`). Use `k.lag` for the rest |
| Returns | An array of `{ i, the values to change... }`. Only the values you give change. If it returns nothing, the `things` as you edited them in place are used |
| Weight | With three arguments, the result is weakened by `near` |
| Fourth argument | `relate(things, t, k, was)`: what you returned for the previous frame (looked up by `i`; `null` on the first frame). Then the result is not weakened by `near`; use `near` yourself (example: `relations/stay.js`). Because it needs the frame before, it runs from the start, in order, 60 frames a second |

`force` pushes (the shape d3-force uses). It returns nothing and edits `things` in place.

```js
// Spring: each goes after where it would be left alone, past it and back
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

In `force`, each thing also has `vx`, `vy`, `vz` (speed), `home` (`x`, `y`, `z`: where it would be without this relation) and `index`. Read back are `x`, `y`, `z`, `size`, `rotate`, `rotate_x`, `rotate_y`, `opacity`, `vx`, `vy`, `vz`. Anything else you put on a thing is still there next frame. If the file says `d3.`, d3-force-3d is available (example: `relations/collide.js`). It runs from the start, in order, 60 frames a second.

### A recipe: `create/` (`// make` lines)

The first line gives the name; the lines under it are commands, one each, that make layers and set their values. The file may have no code.

```js
// White Flash: the stage goes white for an instant where the playhead is, gone in 0.4 seconds
// make shape rect
// here
// say fill ffffff
// fit fill
// set duration 0.4
// key opacity 0 1
// key opacity 0.4 0
```

For a motion of its own, put `each` after the head. The file then becomes the script of the first layer.

```js
// Bobbing Row: five dots that bob one after another
// make shape circle
// say fill ffd166
// set size 0.1
// set copies 5
// --track@height:Height,0,1,0.3,0.01
function each(i, n, t, k) {
  return { x: (i - (n - 1) / 2) * 0.3, y: k.height * Math.sin(t * 4 + i) };
}
```

| Command | Meaning |
|---|---|
| `make kind what` | Makes the first layer. It must be the first command, or the file is not listed. `make shape rect` (`rect`, `circle`, `polygon`, `star`, `line`, `ring`, `arc`, `arrow`, `squircle`, `cog`, `path`, `spiral`, `chamfer`, `null`), `make solid cube` (`ring`, `gem`, `cube`, `ball`, `sketch`), `make picture path-to-file` |
| `then kind what` | Makes another layer. The following `set`, `say` and `key` go to it |
| `set value number` | Sets a number. Instead of a number you can write `first` (the recipe's first layer), `before` (the layer made just before) or `behind` (the order just under the first layer). Value names are in `engine/document/kinds.h` (`size`, `copies`, `opacity`, `duration`, ...). A slider of the script is `js_<slider name>` |
| `say value words` | Sets a word value (`fill ff3366`, `path M 0 0 ...`, `copy_fill colour colour ...`). `say script this` is this file's code, `say script Repeater` is another recipe by name, `say script expressions/wave.js` is a shelf file |
| `here` | Begins at the playhead (without it, at the start of the project, going round with it). The seconds of `key` count from here |
| `fit fit` / `fit fill` / `fit stretch` | Fits it to the picture (inside, covering, stretched) |
| `key value seconds number` | Puts a key on the value at that time |

Watch out for:

- Every `//` line from the first one up to the code is read as a command. If you write a sentence there, do not start it with a command word (`make`, `then`, `set`, `say`, `here`, `fit`, `key`). A line starting with any other word is skipped.
- A file with `function each` also shows under Expression in Create.
- A p5.js sketch with no `// make` line, and with `function draw`, `function setup` or `createCanvas`, becomes one recipe as it is, named after the file.

### A p5.js sketch

```js
function setup() { createCanvas(400, 400); }
function draw() {
  background(20);
  circle(200 + 100 * sin(frameCount / 30), 200, 60);
}
```

- p5.js 1.11.13 runs it as it is (no browser), at 60 frames a second, and time only goes forward.
- A 2D sketch becomes a picture, fitted to the project. In `WEBGL`, `box`, `sphere`, `plane`, `ellipsoid`, `cylinder`, `cone` and `torus` become copies of a 3D solid.
- Each line that draws gets one slider for how strong that line's shapes are (named like `circle 3`).
- A picture loaded with `loadImage` is read, by its file name only, from a folder named like the file beside it (`Fire/` for `Fire.js`).
- p5.sound runs as it is when its file lies beside p5's (`engine/third_party/js/p5/addons/p5.sound.min.js`, from the same p5 distribution; it is not kept in this repository). A sketch then hears the video or sound layer under it: `loadSound` gives that sound whatever file it names, `p5.FFT` and `p5.Amplitude` read it with the numbers Chrome gives, and the sound is where the timeline is. A sketch that waits for a click to start its sound is clicked once. What a sketch plays is not heard in the export, and oscillators are silent. Without the file, p5.sound's names are there and silent.

### An easing: `ease/` (`.way`)

The first line is the name, then the formula.

```
// Snappy: fast away from the first key, a long soft landing on the next
a + (b - a) * bezier(u, .2, 0, 0, 1)
```

`a` is the first key's value, `b` the next key's, `u` is how far through (0 to 1), `p1` to `p4` are numbers. Write a formula that gives `a` at `u` = 0 and `b` at `u` = 1. `bezier(u, x1, y1, x2, y2)` and `way('Name', u)` can be used.

### The others

- `solids/`: `export function solid(k)` returns a three.js BufferGeometry. `k` is the sliders plus `k.w` and `k.h` (the thing's width and height). Example: `solids/Box.js`.
- `.wgsl` in `effects/`: declare sliders with `--track@` in the head, and return the picture from `fn fs_main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f`. The picture is a `texture_2d<f32>`, the sliders one `var<uniform>` struct. If the struct has `time`, `frame`, `aspect`, `resolution`, `width` or `height`, the stage fills them in. Example: `effects/glitch/rgbshift.wgsl`.
- `.fs` in `effects/`: ISF (Vidvox's format), placed as it is.
- `.wgsl` in `effects/` with a compute shader (`@compute`): it moves the points of the layer's solid (a `solids/` shape on the same layer), every frame. Bindings in group 0: at 0 a uniform struct of `f32`, `time` first, then one for each `--track@` line in order; at 2 the shape's points (`array<f32>`, x y z each); at 4 its texture coordinates (u v each); at 6 the points to draw, which it writes; at 8 the shape's normals (x y z each); at 10 the normals to draw, which it may write (a point left at zero keeps the shape's); at 12 the shape's tangents (x y z w each). Declare only the ones you use. A layer with no solid of its own (a flat picture, a text) is laid on `solids/Plane.js`, a sheet of many points. Its entry is `@compute @workgroup_size(64)`, point `i` is `global_invocation_id.x`. Example: `effects/geometry/tg_simple_points.wgsl`.

## How a file's head is written

The first line is `// Name: description`. The name is what comes before the first `:`. Where there is no such line (and for a `.fs`), the file name is the name; a p5.js sketch in `create/` is the same.

A slider is one line, `// --kind@name:Label,...`. The name is what the code reads as `k.name`. Both the `@` and the `:` are needed. Other lines (prose) are skipped.

| Line | Meaning |
|---|---|
| `// --track@name:Label,lowest,highest,as it comes,step` | A number. The step may be left out |
| `// --check@name:Label,as it comes` | On or off (1 or 0) |
| `// --select@name:Label,word1,word2,...` | One of some words; the first is as it comes. `k.name` is the chosen word |
| `// --picture@name:Label` | Reads another layer's picture (effects only) |
| `// --sound@name:Label,fft,512` | A layer picked on the card for its sound; `k.name` is its number, 0 for none. In an effect written as ISF it is that effect's audio input (`fft` or `wave`, and how many values) |
| `// --group:Name` ... `// --group` | The sliders between become a folded group of that name |
| `// --macro@name:Label,as it comes -> slider low high, ...` | One 0-to-1 slider that turns others |
| `// --label:Word` | The category in the list. In `create/`, it marks a closed pack |
| `// --about:Words` | An effect's description (used in the effects list) |
| `// --tag:word word` | Search tags of an effect (`#basic` finds the ordinary ones). Added to the tags Motolii reads from the file itself |

Instead of slider lines, a `const knobs = { distance: 2, ... }` at the top (leva's form) is read too.

## After you place it

Save it and it shows at once (no restart). Save it again and the picture follows at once.

- `effects/`: a tile in the Effects tab. Select a layer, press the tile, press **Add**.
- `create/`: a tile in the Create tab. Press it, then **Create**.
- `expressions/`: under Expression in the Create tab. Select a layer, press the tile, then **Put on** (it goes on that layer as a card of its own; its sliders show in the Inspector). With nothing selected it makes a new thing.
- `relations/`: under Expression in the Create tab, with the expressions. Pick a group, or select two or more layers, and press the tile: they move as one. On one picked layer it moves that layer's copies or letters.


## The folders

| Folder | Where it shows in the app | Files to put | Name shown |
|---|---|---|---|
| `effects/` | Effects tab tiles (a layer's effect, or the whole screen's) | `.fs` (ISF), `.wgsl`, `.js` (three.js), `.mjs`, `.json` (Filament settings) | The first line's `// Name:`, else the file name. A `.fs`: its file name |
| `aviutl_scripts/` | Effects tab tiles; the package name is a chip | An AviUtl2 package (`.anm2`, `.obj2`, `@` files), the folder as its author ships it | The script's name and `--label:`; the package name is what follows `__` in the folder name |
| `create/` | Create tab, Recipes (a picture in one call). One with `function each` shows under Expression; closed packs (`--label:Cavalry`…) in the Program tab | `.js` | The first line's `// Name: what it makes`; a p5 sketch with no head: its file name |
| `expressions/` | Create tab, Expression (letters or layers coming in and going out, a wave through a layer's copies; Cavalry's Animators and its oscillator) | `.js` (`function each`) | The first line's `// Name:` |
| `relations/` | Create tab, Expression, with the expressions (many layers moved at once: put on a group, or on layers selected together) | `.js` | The first line's `// Name:`, else the file name |
| `looks/` | Effects tab, look tiles (a layer's values, effects and keys saved under a name) | `.motolii` + its tile picture `.png` | The file name as it is (spaces and capitals kept) |
| `solids/` | A 3D shape on a layer's effect card (Alight Motion's Box, Torus…). No tile yet; it shows when a project names it | `.js` (`export function solid` returning a three.js BufferGeometry) | The first line's `// Name:` |
| `ease/` | Ease tiles, below (how a stretch between keys moves) | `.way` (one expression) | The first line's `// Name:`, else the file name |
| `skins/` | View › Skin (the window's look) | A folder (`theme.xml`, and any pictures and fonts). How to make one: [`skins/README.md`](skins/README.md) | The folder's name |
| `extensions/` | Not an item. Used once before pasting Hydra code | `hydra/get.sh` | — |

What is in a folder of the old names (`recipes/`, `animators/`, `ways/`) is still read.

## The folders inside

`effects/` and `create/` are read down through every folder inside. Those folders' names are not shown in the app; they are for whoever puts a file there. A document finds an effect or a recipe again by its file name, so moving one to another folder inside does not break documents.

Inside `effects/`, the folders follow After Effects' Effects & Presets categories ([Adobe's effect list](https://helpx.adobe.com/after-effects/desktop/apply-effects-and-animation-presets/effects-and-animation-presets/effect-list.html)). Where AE has none, the row says why.

| Folder | AE category | What goes in |
|---|---|---|
| `blur/` | Blur & Sharpen | Blurs and sharpens |
| `color/` | Color Correction | Colour and brightness correction |
| `distort/` | Distort | Bends the picture |
| `generate/` | Generate | Makes a picture (waveforms, patterns, crop shapes) |
| `stylize/` | Stylize | Changes how the picture looks (halftone, glow, edges) |
| `transition/` | Transition | From one picture to another |
| `key/` | Keying and Matte | Keys and masks by colour or brightness |
| `utility/` | Utility | Tools more than looks (alpha, colour bars, clock, timecode) |
| `move/` | none | Moves the thing itself over time (shake, repeat, spin). AE does this with expressions (`wiggle()`, `loopOut()`), not effects, so it has no category for it |
| `geometry/` | none | Shapes, 3D solids, flips, rotation. AE splits these between Perspective and Generate. The name is the one the ISF effects here give themselves in `CATEGORIES`: `Geometry Adjustment` |
| `glitch/` | none | The look of broken video (datamosh, VHS, RGB split). AE scatters these over Stylize and Time. The name is the one the ISF effects here give themselves in `CATEGORIES`: `Glitch` |
| `sources/` | not a category | Where the effects came from: each pack's licence, the import scripts, the sample photo tiles are drawn on, the AviUtl effect map. The source line in the head of 257 effects on the shelf names this place as their source, so the name stays |

Inside `create/`, folders are named after what you get.

| Folder | What goes in |
|---|---|
| `shapes/` | One shape (arrow, heart, callout…; AbsentMotion's shapes) |
| `cavalry/` | Points laid along curves and solids (Canvalry's Distributions as they are) |
| `repeats/` | One thing copied many times and moved in turn (AE's Repeater, Cavalry's Duplicator) |
| `over_footage/` | Laid over a film (boxes that follow what moves, a white flash, a poster) |

## Folders that look empty

- `extensions/hydra/` holds only `get.sh`. Hydra (hydra-synth) is AGPL-3.0, so it is in neither this repository nor what is handed out. `get.sh` fetches it into `extensions/hydra/` in your own folder, and Motolii reads it there. Delete that folder and Motolii is as it was. It is here because whoever pastes Hydra code comes here for it.
- `ease/` holds one example (`snappy.way`). Presets are yours: what you put in `ease/` in your own folder is the shelf.

## Naming

Before renaming a file, look at "Name shown" above. A document finds what it uses by file name, so a file once handed out keeps its name even when the name is not shown (`create/repeats/ae_grid.js` keeps its `ae_`).

- Files with a first line `// Name:` (`effects/` `.js` and `.wgsl`, `create/`, `expressions/`, `relations/`, `solids/`, `ease/`): the file name is not shown, so any form will do. Those here keep their source's names (`solids/`: Alight Motion's names with `_` for spaces; `create/shapes/am_*`: AbsentMotion's shapes).
- Files whose name is shown (`looks/`, `effects/` `.fs`, a p5 sketch with no head such as `create/repeats/Cube Wave.js`, a `relations/` file with no `// Name:`): write it with spaces and capitals as it should read. An ISF `.fs` keeps the name it was handed out with.
- `aviutl_scripts/`: `<author>__<package>/`, the author and package names of the AviUtl2 catalogue. Inside, the package as it is handed out, with its `LICENSE` and a `SOURCE.txt`.
- Only what is one item each goes here. A part of others (e.g. `face_uv.js`, the UVs of an extruded shape) goes beside the code that runs them (`engine/community/three/`, beside `solid_three.cpp`, which runs the `solids/` shelf). `face_uv.js` was written for Motolii, not brought in from someone else, so it lives under `engine/`, not on a shelf (AGENTS.md 構成の目標 3).

## Not here

- The font for letters a font lacks (Noto Sans JP), the Fonts tab's sample lines, and the table the Effects search reads Japanese into English with (Japanese WordNet) are data the engine reads, not things you add to, so they are in `engine/third_party/` with their licences. What you put in `fonts/` or `words/` of your own folder adds to them.
- Which code reads which folder: [`docs/ARCHITECTURE.md`, 「棚を読む所」](../docs/ARCHITECTURE.md#棚を読む所).
- The scripts that make these files (`effects/sources/`, `create/shapes/absent_shapes.sh`) are run by hand; the build never calls them.
