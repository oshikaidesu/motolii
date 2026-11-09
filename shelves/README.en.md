# shelves/ — where to put a look you found

[日本語](README.md)

What Motolii has from the start. Each folder is named as the app shows it on screen: put a file you found in the folder named for where you want it to show.

Put it in your own folder (`~/Library/Application Support/Motolii/` on a Mac, `%APPDATA%\Motolii\` on Windows, or `MOTOLII_OWN`): make a folder there of the same name as one below and put the file in it. It shows in the same place at once, no restart. A file of the same name there wins over the one here.

| Folder | Where it shows in the app | Files to put | Name shown |
|---|---|---|---|
| `effects/` | Effects tab tiles (a thing's effect, or the whole screen's) | `.fs` (ISF), `.wgsl`, `.js` (three.js), `.mjs`, `.json` (Filament settings) | The first line's `// Name:`, else the file name. A `.fs`: its file name |
| `aviutl_scripts/` | Effects tab tiles; the package name is a chip | An AviUtl2 package (`.anm2`, `.obj2`, `@` files), the folder as its author ships it | The script's name and `--label:`; the package name is what follows `__` in the folder name |
| `create/` | Create tab, Recipes (a picture in one call). One with `function each` shows under Expression; closed packs (`--label:Cavalry`…) in the Program tab | `.js` | The first line's `// Name: what it makes`; a p5 sketch with no head: its file name |
| `expressions/` | Create tab, Expression (letters or things coming in and going out; Cavalry's Animators) | `.js` (`function each`) | The first line's `// Name:` |
| `relations/` | Chips on the stage and in the Relations tab (many things moved at once) | `.js` | The first line's `// Name:`, else the file name |
| `looks/` | Effects tab, look tiles (a thing's values, effects and keys kept by a name) | `.motolii` + its tile picture `.png` | The file name as it is (spaces and capitals kept) |
| `solids/` | A 3D shape on a thing's effect card (Alight Motion's Box, Torus…). No tile yet; it shows when a document names it | `.js` (`export function solid` returning a three.js BufferGeometry) | The first line's `// Name:` |
| `ease/` | Ease tiles, below (how a stretch between keys moves) | `.way` (one expression) | The first line's `// Name:`, else the file name |
| `skins/` | View › Skin (the window's look) | A folder (`theme.xml`, and any pictures and fonts). How to make one: [`skins/README.md`](skins/README.md) (Japanese) | The folder's name |
| `extensions/` | Not an item. Used once before pasting Hydra code | `hydra/get.sh` | — |

What is in a folder of the old names (`recipes/`, `animators/`, `ways/`) is still read.

## Folders that look empty

- `extensions/hydra/` holds only `get.sh`. Hydra (hydra-synth) is AGPL-3.0, so it is in neither this repository nor what is handed out. `get.sh` fetches it into `extensions/hydra/` in your own folder, and Motolii reads it there. Delete that folder and Motolii is as it was. It is here because whoever pastes Hydra code comes here for it.
- `ease/` holds one example (`snappy.way`). Presets are yours: what you put in `ease/` in your own folder is the shelf.

## Naming

Before renaming a file, look at "Name shown" above.

- Files with a first line `// Name:` (`effects/` `.js` and `.wgsl`, `create/`, `expressions/`, `relations/`, `solids/`, `ease/`): the file name is not shown, so any form will do. Those here keep their source's names (`solids/`: Alight Motion's names with `_` for spaces; `create/shapes/am_*`: AbsentMotion's shapes).
- Files whose name is shown (`looks/`, `effects/` `.fs`, a p5 sketch with no head such as `create/copies/Cube Wave.js`, a `relations/` file with no `// Name:`): write it with spaces and capitals as it should read. An ISF `.fs` keeps the name it was handed out with.
- `aviutl_scripts/`: `<author>__<package>/`, the author and package names of the AviUtl2 catalogue. Inside, the package as it is handed out, with its `LICENSE` and a `SOURCE.txt`.
- Only what is one item each goes here. A part of others (e.g. `face_uv.js`, the UVs of an extruded shape) goes beside the code that runs them (`engine/community/js/`).

## Not here

- The font for letters a font lacks (Noto Sans JP), the Fonts tab's sample lines, and the table the Effects search reads Japanese into English with (Japanese WordNet) are data the engine reads, not things you add to, so they are in `engine/third_party/` with their licences. What you put in `fonts/` or `words/` of your own folder adds to them.
- Which code reads which folder: [`docs/ARCHITECTURE.md`, 「棚を読む所」](../docs/ARCHITECTURE.md#棚を読む所).
- The scripts that make these files (`effects/sources/`, `create/shapes/absent_shapes.sh`) are run by hand; the build never calls them.
