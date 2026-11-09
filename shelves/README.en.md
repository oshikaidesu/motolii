# shelves/ — where to put a look you found

[日本語](README.md)

What Motolii has from the start. Each folder is named as the app shows it on screen: put a file you found in the folder named for where you want it to show.

Put it in your own folder (`~/Library/Application Support/Motolii/` on a Mac, `%APPDATA%\Motolii\` on Windows, or `MOTOLII_OWN`): make a folder there of the same name as one below and put the file in it. It shows in the same place at once, no restart. A file of the same name there wins over the one here.

| Folder | Where it shows in the app | Files to put | Name shown |
|---|---|---|---|
| `effects/` | Effects tab tiles (a layer's effect, or the whole screen's) | `.fs` (ISF), `.wgsl`, `.js` (three.js), `.mjs`, `.json` (Filament settings) | The first line's `// Name:`, else the file name. A `.fs`: its file name |
| `aviutl_scripts/` | Effects tab tiles; the package name is a chip | An AviUtl2 package (`.anm2`, `.obj2`, `@` files), the folder as its author ships it | The script's name and `--label:`; the package name is what follows `__` in the folder name |
| `create/` | Create tab, Recipes (a picture in one call). One with `function each` shows under Expression; closed packs (`--label:Cavalry`…) in the Program tab | `.js` | The first line's `// Name: what it makes`; a p5 sketch with no head: its file name |
| `expressions/` | Create tab, Expression (letters or layers coming in and going out; Cavalry's Animators) | `.js` (`function each`) | The first line's `// Name:` |
| `relations/` | Chips on the preview and in the Relations tab (many layers moved at once) | `.js` | The first line's `// Name:`, else the file name |
| `looks/` | Effects tab, look tiles (a layer's values, effects and keys saved under a name) | `.motolii` + its tile picture `.png` | The file name as it is (spaces and capitals kept) |
| `solids/` | A 3D shape on a layer's effect card (Alight Motion's Box, Torus…). No tile yet; it shows when a project names it | `.js` (`export function solid` returning a three.js BufferGeometry) | The first line's `// Name:` |
| `ease/` | Ease tiles, below (how a stretch between keys moves) | `.way` (one expression) | The first line's `// Name:`, else the file name |
| `skins/` | View › Skin (the window's look) | A folder (`theme.xml`, and any pictures and fonts). How to make one: [`skins/README.md`](skins/README.md) (Japanese) | The folder's name |
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
