# shelves/ — the looks Motolii ships with

[日本語](README.md)

What Motolii has from the start. One folder per shelf. Make a folder of the same name in your own folder (`~/Library/Application Support/Motolii/` on a Mac, `%APPDATA%\Motolii\` on Windows, or `MOTOLII_OWN`) and put a file in it: it is on the same shelf at once, no restart. A file of the same name there wins over the one here (`doc_folders` in `engine/document/doc_edit.h`).

| Shelf | What you see in the app | Files | Where its shown name comes from | Read by |
|---|---|---|---|---|
| `effects/` | Effects dock tiles (a thing's effect, or the whole screen's) | `.fs` (ISF), `.wgsl`, `.js` (three.js), `.mjs`, `.json` (Filament settings) | The first line's `// Name:`, else the file name. A `.fs` is its file name | `doc_recipes.h` `doc_folder_names`, `effect_tiles.dart` |
| `aviutl_scripts/` | Effects dock tiles; the package name is a chip | AviUtl2 `.anm2`, `.obj2`, `@` files (packages as their authors ship them) | The script's name and `--label:`; the package name is what follows `__` in the folder name | `doc_recipes.h` `doc_aviutl_names`, `effect_decks.dart` `effectPack` |
| `recipes/` | Make dock, Create tiles (a picture in one call); closed packs (`--label:Cavalry`…) on the Program shelf | `.js` | The first line's `// Name: what it makes`; a p5 sketch with no head: its file name | `doc_recipes.h` `doc_recipes_read`, `dock_make_expressions.dart` `_expressionRecipes` |
| `animators/` | Make dock, Expression tiles (letters or things coming in and going out; Cavalry's Animators) | `.js` | The first line's `// Name:` | `motolii_calls.h` `motolii_animators` |
| `relations/` | Chips on the stage and in the Relations tab (many things moved at once) | `.js` | The first line's `// Name:`, else the file name | `motolii_calls.h` `motolii_relations`, `relate.dart` |
| `looks/` | Effects dock, look tiles (a thing's values, effects and keys kept by a name) | `.motolii` (SQLite) + its tile picture `.png` | The file name as it is (the name typed when it was saved: spaces and capitals kept) | `doc_looks.h` `doc_look_names` |
| `solids/` | A thing's effect card (a 3D shape its picture is laid on: Alight Motion's Box, Torus…). No shelf tile yet; it shows when a document's fx names it | `.js` (`export function solid` returning a three.js BufferGeometry) | The first line's `// Name:` | `solid_three.cpp`, `doc_moment_fx.h` |
| `ways/` | Ease desk tiles (how a stretch between keys moves) | `.way` (one expression) | The first line's `// Name:`, else the file name | `doc_recipes.h` (`doc_folders("ways")`), `desk_ease_shelf.dart` |
| `words/` | Not an item. Type Japanese in the Effects dock's search and effects with English names come up (the word bridge) | `ja_en.tsv` (made from Japanese WordNet), its source and how it was cut | — | `engine/library/find.h` `find_english` |
| `fonts/` | Not an item. The font used for letters a font lacks, and the Fonts dock's sample lines | `.otf`, `samples.json` (a sample line per script) | — | `drawn_made.h`, `dock_fonts.dart` |
| `extensions/` | Not an item. Pasted Hydra code runs | only `hydra/get.sh` | — | `doc_door.h`, `hydra_isf.cpp` |

## Shelves that look empty

- `extensions/hydra/` holds only `get.sh`. Hydra (hydra-synth) is AGPL-3.0, so it is in neither this repository nor what is handed out. `get.sh` fetches it into `extensions/hydra/` in your own folder, and Motolii reads it there. Delete that folder and Motolii is as it was.
- `ways/` holds one example (`snappy.way`). Presets are yours: what you put in `ways/` in your own folder is the shelf.

## Naming

Before renaming a file, look at "Where its shown name comes from" above.

- Files with a first line `// Name:` (`effects/` `.js` and `.wgsl`, `recipes/`, `animators/`, `relations/`, `solids/`, `ways/`): the file name is not shown, so any form will do. Those here keep their source's names (`solids/`: Alight Motion's names with `_` for spaces; `recipes/shapes/am_*`: AbsentMotion's shapes).
- Files whose name is the shown name (`looks/`, `effects/` `.fs`, a p5 sketch with no head such as `recipes/copies/Cube Wave.js`, a `relations/` file with no `// Name:`): the file name is what you see. Write it with spaces and capitals as it should read. An ISF `.fs` keeps the name it was handed out with.
- `aviutl_scripts/`: `<author>__<package>/`, the author and package names of the AviUtl2 catalogue (what follows `__` is shown as the pack). Inside, the package as it is handed out, with its `LICENSE` and a `SOURCE.txt`.
- A shelf holds only what is one item each. A part of others (e.g. `face_uv.js`, the UVs of an extruded shape) goes beside the code that runs them (`engine/community/js/`).

## Shelf and door

- `shelves/aviutl_scripts/` is the **shelf**: the AviUtl2 scripts themselves, handed to users.
- `engine/community/aviutl/` is the **door**: the code that runs those scripts inside Motolii (their Lua, their HLSL made WGSL).

The same holds for the other shelves: the doors that run code from the net are in `engine/community/` (ISF, three.js, p5, AE expressions, Shadertoy).

## Not here

- The knob weights (`knob_weights.json`) are not a shelf but a table the Effects dock's tiles read, so they sit beside the code that reads them, `effect_tiles.dart` (`app/lib/workspace/shelf/`).
- The Make dock's Elements (Alight Motion's My Elements) are only in `elements/` in your own folder; none ship with Motolii (`doc_looks.h`).
