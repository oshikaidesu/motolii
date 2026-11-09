# Rename plan: house words → the words users already know

*Decided 2026-11-09 by the author: the code drops its own English coinages and uses the words of After Effects,
Filament, Flutter and Blender. This note is the plan only; nothing in code is renamed by it. It replaces the
「言葉（Words）」 table of `docs/ARCHITECTURE.md` once the batches below have landed.*

Code paths are written in `code` (not links) on purpose: four sessions are moving `engine/library/`, `app/lib/engine/`,
the shelf folders and `docs/media/` right now, and `path_check.py` would break on links to the old places.

## 1. The words

Counts: identifier parts (snake/camel split, comments stripped) in our own code — `engine/` without
`third_party/`·`deps/`·`out/`, and `app/lib/` without `motolii_bindings.dart` — and every word in our `.md`.
Counter: §6. A count with ¹ includes the plain-English or third-party sense too (`sqlite3_step`, the Steps easing).
**Risk** = the old word is inside something users keep: `.motolii` files, the C API in `motolii.h`, shelf formats.

| # | Old word | Meaning | New word | Source that uses the new word for this meaning | engine / app / docs | Risk |
|---|---|---|---|---|---|---|
| 1 | thing(s), 物 | one item in the timeline | `layer` | AE: "Layers are the elements that make up a composition." [ae-layer]; the app already says `WsLayer` | 2230 / 532 / 273 | **yes**: table `thing`, column `fact.thing`, `motolii_things`, `motolii_thing_*` |
| 2 | fact (a row) | a value at a time; a row with `at` is a key | `keyframe` | AE: "A keyframe marks the point in time where you specify a value" [ae-key] | 176 / 21 / 22 | **yes**: table `fact`, `motolii_doc_facts` |
| 3 | fact(s) (a layer's named values) | a named value of a layer | `property` | AE `valueAtTime` is a method of Property [ae-expr]; AE's Effect Controls panel [ae-preset] | (in 2) | `motolii_doc_facts` |
| 4 | way(s) | how one key goes to the next | `easing` (the 9 built-in kinds stay `Interp` = interpolation) | AE keyframe interpolation: Linear, Bezier, Hold [ae-interp]; Blender F-Curve Interpolation Mode [bl-fcurve] | 450 / 215 / 136 | **yes**: table `way`, column `fact.way`, SQL function `way()` inside users' expressions, shelf `*.way` files, `motolii_way*` |
| 5 | goes | an easing's SQLite expression | `expression` | AE expressions [ae-expr] | 45 / 5 / 17 | **yes**: column `way.goes` |
| 6 | step(s) | one entry of undo | `undo_step` | Blender Preferences › System › "Undo Steps" [bl-undo-pref]; Blender Undo History [bl-undo] | 219¹ / 175¹ / 218 | **yes**: table `step`, `motolii_hand_step` |
| 7 | film (1) | the video layer kind | `video` | Blender: "A Movie strip displays video from a movie file" [bl-movie]; our own `Video*` struct already says it | 329 / 72 / 368 | **yes**: kind value `'film'` in every document; `createVideo('film')` in shelf recipes |
| 8 | film (2) | the video written out | `export` (`motolii_export`) | AE "rendering and exporting using the Render Queue panel" [ae-render] | (in 7) | **yes**: `motolii_write` |
| 9 | picture (1) | the image layer kind | `image` | Blender Image strip: "add still images" [bl-image]; ThorVG `Picture` is "an image read in one of the supported formats" [tvg] | 610 / 96 / 155 | **yes**: kind value `'picture'` |
| 10 | picture (2) | one drawn frame | `frame` | Filament `Renderer::beginFrame(swapChain)` … `endFrame()` draws one frame [fil-renderer] | (in 9) | `motolii_type_picture` |
| 11 | picture (3) | the copy of the document the app reads | `snapshot` | Flutter `AsyncSnapshot`: "Immutable representation of the most recent interaction…" [fl-snap]; the app already says `snapshot` (9×) | (in 9) | **yes**: `motolii_picture` |
| 12 | drawn (1) | the flat 2D plane ThorVG draws onto | `canvas` | ThorVG `Canvas`: "An abstract class for drawing graphical elements" [tvg] | 434 / 73 / 133 | no |
| 13 | drawn (2) | the kinds that are seen (`doc_drawn`) | `visible_kinds` | ThorVG `Paint::visible(bool on)` [tvg]; already our property name `visible` (`doc.h`) | (in 12) | no |
| 14 | made | one renderable placed on the stage | `renderable` | Filament: "An Instance representing a renderable component." [fil-rm] | 812¹ / 131¹ / 48 | no |
| 15 | make / recipe (レシピ) | a script that makes layers and values in one go | `preset` applied (`motolii_apply_preset`) | AE animation preset (`.ffx`) [ae-preset] — **decide with the shelves-names session** (§2 c) | — | **yes**: `motolii_make`, `shelves/recipes/` |
| 16 | kept | cache (frames on disk; anything worked out once) | `cache` | AE "RAM cache, disk cache, and media cache" [ae-cache] | 407¹ / 114¹ / 48 | `motolii_kept`; the cache folder on disk (throw-away) |
| 17 | told / tell (1) | a callback to the app | `listener` (`motolii_add_listener`) | Flutter `addListener`: "Register a closure to be called when the object notifies its listeners." [fl-listen] | 269 / 162 / 27 | **yes**: `motolii_tell` |
| 18 | tell (2), telling | work out every value at a time t | `evaluate` (`evaluating`) | AE `valueAtTime`: "Returns the value of a property at the specified time" [ae-expr] | (in 17) | no |
| 19 | moment(s) | a time in the document | `time` | AE `valueAtTime(t)` [ae-expr] | 68 / 131 / 56 | `motolii_key_moments`, `motolii_thing_key_moments` |
| 20 | hand (1) | the one thread owning document + GPU | `render_thread` | Filament: "the Engine instance starts a render thread" [fil-engine]; Flutter's raster thread [fl-perf] | 68 / 72 / 87 | `motolii_hand_step` |
| 21 | hand (2); hold / carry / let go | a pointer drag | `drag_start` / `drag_update` / `drag_end` | Flutter `GestureDetector.onPanStart/Update/End`, `DragStartDetails` [fl-pan] | (in 20) | **yes**: `motolii_hold`, `motolii_carry`, `motolii_let_go` |
| 22 | door (1) | a runner of other people's code in its own shape | `adapter` | "allows objects with incompatible interfaces to collaborate" [adapter] | 401 / 3 / 131 | no (folder names only) |
| 23 | door (2) | the reach into Filament/Dawn internals | `interop` | ARCHITECTURE already says "interop"; Filament `Texture::Builder::import` is the patched entry | (in 22) | no |
| 24 | seat | a panel's place in the window | `panel` | AE "Workspaces, panels, and viewers" [ae-panel] | 0 / 21 / 43 | no |
| 25 | kit (1) | Filament scene code `engine/stage/kit/`, `gpu/kit_wgpu.sh`, `out/wgpu_kit/` | `render` (`render/`, `filament_webgpu.sh`, `out/filament_webgpu/`) | Filament `View`: "all the state needed for rendering a Scene" [fil-view] | 68 / 16 / 286 | no (build script name: tell the other sessions) |
| 26 | kit (2) | small shared parts of the desk (app) | `widgets` | Flutter widget inspector [fl-inspect] | (in 25) | no |
| 27 | knob(s) | an effect's / script's input | `parameter` | Filament `MaterialInstance::setParameter` [fil-mi] | 353 / 134 / 35 | no (stored parameter names do not contain the word) |
| 28 | trouble | the last error's text | `error` (`motolii_error`) | SQLite `sqlite3_errmsg`: "English-language text that describes the error" [sq-err] | 256 / 61 / 9 | **yes**: `motolii_trouble` |
| 29 | eye | the stage's own camera / viewpoint | `camera` (`view_camera` where the layer kind `camera` is meant too) | Filament `View` holds a `Camera` [fil-view] | 159 / 98 / 48 | no |
| 30 | wear | the material a layer has | `material` (`doc_material.h`) | Filament: "A MaterialInstance represents a specific instance of a Material." [fil-mi] | 54 / 5 / 6 | no |
| 31 | look(s) | a layer's values saved as a file, put on another | `preset` | AE: "The filename extension for an animation preset is .ffx." [ae-preset] | 549¹ / 233¹ / 123 | **yes**: `shelves/looks/*.motolii`, `motolii_look_put/_save`, `motolii_looks` |
| 32 | desk | the drawer under the Inspector holding one tool | `tool panel` (`ToolPanel`) | AE panels [ae-panel] | 130 / 285 / 187 | UI label "Desk" (users see it) |
| 33 | 窓 / 中身 | app / engine | アプリ / エンジン (`app`, `engine`) | the entrance folders themselves | docs only | no |
| 34 | 書類 | the `.motolii` file | プロジェクト / project | AE "project" (composition basics [ae-comp]) | docs only | no |
| 35 | 場面 | the preview | プレビュー / preview (`Stage` stays, §2 d) | AE composition panel [ae-panel] | docs only | no |
| 36 | 棚 / shelf | the left tab of effects, presets… | **kept**: `shelf` | Blender "Asset Shelf" (manual, *regions*) [bl-shelf] | — | — |

**door does not survive**: rows 22–23. AGENTS.md rule 5 names it as its example of a house word; the docs batch
rewrites that line with `adapter`.

Not in this round (plain English used loosely, local variables only, no user risk): `said` (a value's text form,
544 / 256), `shell` (= the app, 21 / 7), `match` (`doc_match`: the stage rebuilt from the document), `went`, `relation`
(a group behaviour — Blender constraints are the nearest [bl-constraint], not the same). The guard below does not
list them; a later round may.

## 2. Collisions to avoid

a. **Filament** (`using namespace filament` in `kit_stage.h`, `gpu_door.cpp`, `compute_door.cpp`): no bare `Scene`,
   `View`, `Renderer`, `Camera`, `Material`, `Texture`, `Engine`, `Viewport`, `Entity` for our types. Row 14 stays
   nested: `Stage::Renderable`, never a free `Renderable`. Row 29's camera is a member (`view_camera`), not a type.
b. **ThorVG**: `tvg::Canvas`, `tvg::Picture`, `tvg::Scene`, `tvg::Shape`, `tvg::Paint`. Row 12's struct is `Canvas2D`
   (file `canvas_cache.h` for `drawn_kept.h`), never a bare `Canvas`, and nothing does `using namespace tvg`.
c. **Words already taken in our own code**:
   - `frame` already names a layer's box (`motolii_frame`, a layer's box on the picture). Rename that one to
     `bounds` first (same batch as row 10), then picture(2) may become `frame`.
   - `preset` already names the easing presets of the app (`desk_ease_presets`, `easePreset`). Rows 15 and 31 cannot
     both be `preset`: looks → `preset` (AE's `.ffx` is exactly a layer's values saved and applied); recipes are named for the Create tab
     they show in (the shelves-names session, 2026-11-09: `shelves/create/`); easing presets → `EasingPreset`.
   - `layer` already appears 365× in engine: AviUtl's layer number (same meaning) and `am::Layer` (Alight Motion's
     own reader, leave it). `video` already names the `Video*` reader: row 7 then reads naturally.
   - `camera` is also a layer kind: row 29 must stay `view_camera` where both are in scope.
   - The built-in kind `Steps` and `sqlite3_step` are not row 6: rename only the table, `doc_step`, `motolii_hand_step`.
d. **Stage is kept.** It is our struct holding Filament's Scene + View + Renderer; Filament's own `Scene`/`View`/
   `Viewport` are taken (a), and `Composition` is the document's settings, not the drawer. Docs say "preview" (row 35).
e. **Flutter / Dart**: `Layer` (rendering), `Image` (widgets and dart:ui), `Picture`, `Scene`, `Canvas` (dart:ui),
   `Listener` (widgets), `Drawer`, `Key`. Keep the `Ws` prefix (`WsLayer`, `WsPanel`); a field may be `listener`, a
   class may not be `Listener`. Dart built-in identifiers [dart-kw] (`export`, `interface`, `part`, `library`,
   `extension`…) cannot name a type: the Dart method for row 8 is `exportVideo`, not `export`.
f. **C++**: `export` is a keyword — only ever prefixed (`motolii_export`, `doc_export`).
g. **SQLite**: new table and column names are not keywords [sq-kw]: `layer`, `keyframe`, `easing`, `expression`,
   `undo_step` are free. Do not pick `order`, `index`, `transaction`, `key` for any later table or column.

## 3. SQLite: old `.motolii` files keep opening

**Where it is today.** The schema is made in `engine/document/doc_steps.h` (`doc_open`, the `create table if not
exists fact/way/step/thing/setting` block). There is **no version number**: upgrades are found by probing
(`select way from fact limit 0` → add the column; `select made from step limit 0` → add the column;
`pragma_table_info('fact')` `at` REAL → rebuild). Three more places read these tables outside `doc_open`:
`doc_looks.h` (`attach database … as look`, creates `look.fact/way/thing`), `doc_marks.h:105` (opens *another*
document read-only and reads `fact`), and the SQL strings in `motolii_calls.h`, `motolii_write.h`, `stage/picture.h`,
`stage/stage_kept.h`.

**Picked: migrate on open, `PRAGMA user_version` + `ALTER TABLE … RENAME`. Not a view.**
- `user_version` is "the user-version integer at offset 60 in the database header" [sq-pragma]: free for us, unused today.
- `ALTER TABLE RENAME` also renames "references to the table within trigger bodies and view definitions" [sq-alter];
  `RENAME COLUMN` keeps the column order.
- A view cannot carry the undo: SQLite's session extension records tables only [sq-session], so writes through a
  view's triggers would still be recorded under the old table names, and the code would keep saying `fact`.

**The trap: undo steps already in the file.** `step.change` holds session changesets, and a changeset records "The
name of the database table" [sq-session]. On apply, a table counts only if it "has the same name as the name recorded
in the changeset"; otherwise "it is not an error" and none of its changes are applied [sq-apply]. So after the rename
every old step would undo *nothing* and report success. The migration therefore cuts history at the upgrade:
`change` set to NULL, `made` kept (Total Edit Time still reads it), and `doc_step` stops at a NULL change. Columns
keep their positions, so steps made after the migration are whole.

```sql
-- doc_open, before the create-if-not-exists block (which then names the new tables):
-- user_version 0 and a table `fact` = a house-word document; 0 and no `fact` = a new file: just create, then set 1.
begin;
alter table thing rename to layer;
alter table fact rename to keyframe;
alter table keyframe rename column thing to layer;
alter table keyframe rename column way to easing;
alter table way rename to easing;
alter table easing rename column goes to expression;
alter table step rename to undo_step;
update undo_step set change = null;                      -- old changesets name `fact`/`way` (see above)
update keyframe set value = 'video' where name = 'kind' and value = 'film';
update keyframe set value = 'image' where name = 'kind' and value = 'picture';
pragma user_version = 1;
commit;
```

Also, in the same batch:
- `user_version > 1` → `doc_open` refuses with "made by a newer Motolii" (today an older build would silently create an
  empty `fact` and show an empty project; that cannot be fixed for builds already out, only from here on).
- The SQL function `way()` stays registered under `way` **and** `easing`: users' own expressions and `shelves/ease/*.way`
  call `way('Cyclic', u)`.
- Kind names `film`/`picture` stay accepted on input (`motolii_add`, p5's `createVideo('film')` in
  `shelves/create/on_film/Blob Track.js`), written as `video`/`image`.
- Look files are attached, not opened: the same rename runs on `look.` when the version is 0, and the 22
  `shelves/looks/*.motolii` are converted once in the batch (they have `fact/thing/way`, no `step`).
- `doc_marks.h:105` opens read-only and cannot migrate: it reads `keyframe`, falling back to `fact` if that fails.

## 4. Batches, in landing order

Not before the four running moves (`engine/library/`, `app/lib/engine/`, shelf folders, `docs/media/`) are on main.
The engine is one translation unit (`motolii.mm`), so a name defined in one batch's files is renamed at its uses in
the same commit; therefore batches marked → land one after another, rebased on the last. Each batch also renames
its own files/folders and their one-line rows in the entrance README tables (AGENTS.md 構成の目標 2).

| Batch | Files it owns | Words | Done when (seen, not assumed) |
|---|---|---|---|
| **B1 document + SQLite** → first, alone | `engine/document/**`; the SQL strings only in `motolii_calls.h`, `motolii_write.h`, `stage/picture.h`, `stage/stage_kept.h`; the 22 `shelves/looks/*.motolii` | rows 1–7, 9, 18, 19, 28, 29, 30, 31 inside the document; §3 migration; `doc_steps.h`→`doc_undo.h`, `doc_ways_put.h`→`doc_easings_put.h`, `doc_wear.h`→`doc_material.h`, `doc_eye.h`→`doc_camera.h`, `doc_looks.h`→`doc_presets.h`, `doc_moment.h`→`doc_evaluate.h`, `doc_door.h`→`doc_adapter.h` | `check_syntax.sh` ok; an old document from `~/Movies/Motolii` (copy it first) opens, shows its layers, `pragma user_version` = 1; a new edit undoes; Cmd+Z past the upgrade stops |
| **B2 stage + gpu + community** ∥ B4 | `engine/stage/**`, `engine/gpu/**`, `engine/community/**`, `engine/media/**`, `engine/motion/**`, `engine/edit.sh` | rows 10, 12–14, 16, 22, 23, 25(1), 27; `drawn/`→`canvas/`, `kit/`→`render/`, `thing_fx.h`→`layer_fx.h`, `stage_kept.h`→`stage_cache.h`, `door*.h`→`adapter*.h`, `*_door.*`→`*_interop.*`, `kit_wgpu.sh`→`filament_webgpu.sh` (tell every session: the build script's name changes) | `check_syntax.sh` ok; one build under the lock; a frame of an old document written as PNG, same as before the batch (pixel diff 0) |
| **B4 app UI** ∥ B2 | `app/lib/**` except `app/lib/engine/` | rows 21 (Dart side), 24, 25(2), 32; `workspace_seat.dart`→`workspace_panel.dart`, `desk_kit.dart`→`desk_widgets.dart`; the "Desk" label | `dart analyze lib` clean; the app shown with the renamed panel visible in a screenshot |
| **B3 bridge** → after B2 and B4 | `motolii.h` and the files beside it, `app/lib/engine/**` (bindings regenerated by ffigen), the call sites in `app/lib/**` | every C API name of rows 1–31 (§1 Risk); `motolii_hand*.h`→`motolii_render_thread*.h`; `picture.h`→`snapshot.h` | `check_syntax.sh` + `dart analyze lib`; the app opens an old document, drags a layer, undoes it (screen recording) |
| **B5 docs** → after B3 | `docs/**/*.md`, every README, AGENTS.md word line and rule 5, `.github/CONTRIBUTING.md` | the Japanese words (rows 33–35), `door`; delete ARCHITECTURE「言葉」and point to this note's §1 | `path_check.py --all` ok; a newcomer reads `engine/README.md` without a word table |
| **B6 guard** → last | `.githooks/word_check.py`, `.githooks/pre-commit`, `.github/workflows/checks.yml` | §5 | §5's two checks |

Size: B1 is the largest (`thing` alone is 1700 of the engine's 2230 in `engine/document/`), all mechanical: a
whole-word `sed` per row, then the compiler. Each is one session. B2 and B4 touch no common file and may run at once.

## 5. The guard (draft — not installed)

Fails when a dropped word is part of an identifier (snake or camel part) or names a table in an SQL string, in our
own code; comments may still use plain English. Hook mode reads only the lines a commit adds (so it could go in
before B6); `--all` reads every file (CI, after B5).
Tried on this tree: `--all` refuses 258 files today; in a scratch repo a staged `int ok = sqlite3_step(s);` passes,
`static int doc_thing_count();` is refused with `doc_thing_count`.

```python
#!/usr/bin/env python3
# Do our own identifiers use a dropped house word? (docs/internal/notes/rename_words.md §1)
# Hook mode: only the lines a commit adds. --all: every own file (CI, after the last batch lands).
import re, subprocess, sys
DROPPED = {'thing', 'things', 'fact', 'facts', 'way', 'ways', 'film', 'films', 'picture', 'pictures', 'drawn', 'made',
           'kept', 'told', 'tell', 'telling', 'hand', 'door', 'doors', 'seat', 'kit', 'knob', 'knobs', 'trouble', 'wear', 'eye'}
TABLES = re.compile(r'\b(?:from|into|update|join|table(?: if not exists)?|attach database \S+ as)\s+(?:\w+\.)?(step|fact|way|thing)\b', re.I)
OWN = re.compile(r'^(engine/(?!third_party/|deps/|out/).*\.(h|cpp|mm|c|sh|py)|app/lib/.*(?<!_bindings)\.dart)$')
FOREIGN = set()   # (a name someone else's code gives, kept as they wrote it: add it here with why)
COMMENT = re.compile(r'//[^\n]*|/\*.*?\*/|^\s*#(?!include|define|!)[^\n]*', re.S | re.M)

def words(ident):
    return {p.lower() for p in re.findall(r'[A-Z]?[a-z]+|[A-Z]+(?![a-z])', ident)}

def bad(text):
    text = COMMENT.sub('', text)
    hits = {i for i in re.findall(r'[A-Za-z_][A-Za-z0-9_]*', text) if i not in FOREIGN and words(i) & DROPPED}
    return hits | {'table ' + m for m in TABLES.findall(text)}

def git(*a):
    return subprocess.run(['git', *a], capture_output=True).stdout.decode('utf-8', 'replace')

found = {}
if '--all' in sys.argv:
    for path in git('ls-files').splitlines():
        if OWN.match(path):
            hits = bad(open(path, errors='replace').read())
            if hits: found[path] = hits
else:
    path = None
    for line in git('diff', '--cached', '-U0', '--diff-filter=ACMR').splitlines():
        if line.startswith('+++ '): path = line[6:] if OWN.match(line[6:]) else None
        elif path and line.startswith('+'):
            hits = bad(line[1:])
            if hits: found.setdefault(path, set()).update(hits)
if found:
    for path, hits in sorted(found.items()):
        print(f'{path}: {", ".join(sorted(hits)[:8])}', file=sys.stderr)
    print('word check refused this commit: a dropped house word (docs/internal/notes/rename_words.md §1)', file=sys.stderr)
    sys.exit(1)
```

Install (B6): add `word_check.py` to the `for check in …` line of `.githooks/pre-commit`, and a CI step
`python3 .githooks/word_check.py --all`. The old-name aliases of §3 (`way()`, `'film'`, `'picture'`, the `fact`
fallback) live in string literals, which the identifier scan still sees: B6 adds those exact lines to `FOREIGN`-like
allow entries with the reason, never a whole file.

## 6. How the counts were made

```python
# python3 count.py thing,fact,...   (run from the repository root)
import os, re, sys, collections
W = set(sys.argv[1].split(',')); SKIP = {'third_party', 'out', 'deps', 'build', '.dart_tool'}
def files(root, ext):
    for dp, dn, fn in os.walk(root):
        dn[:] = [d for d in dn if d not in SKIP]
        yield from (os.path.join(dp, f) for f in fn if f.endswith(ext) and not f.endswith('_bindings.dart'))
for name, paths in (('engine', files('engine', ('.h', '.cpp', '.mm', '.c', '.sh', '.py'))),
                    ('app', files('app/lib', ('.dart',))), ('docs', files('docs', ('.md',))) ):
    c = collections.Counter()
    for p in paths:
        t = open(p, errors='ignore').read()
        if not p.endswith(('.md', '.sh', '.py')): t = re.sub(r'//[^\n]*|/\*.*?\*/', '', t, flags=re.S)
        for i in re.findall(r'[A-Za-z_]\w*', t):
            c.update(w for w in (p.lower() for p in re.findall(r'[A-Z]?[a-z]+|[A-Z]+(?![a-z])', i)) if w in W)
    print(name, dict(c))
```
(docs counted every `.md` under `docs/` plus the root `.md` files; checked 2026-11-09 at `b4e08d277`.)

[ae-layer]: https://helpx.adobe.com/after-effects/desktop/work-with-layers/create-layers/creating-layers.html
[ae-key]: https://helpx.adobe.com/after-effects/desktop/animate-in-after-effects/animation-keyframes/setting-selecting-deleting-keyframes.html
[ae-interp]: https://helpx.adobe.com/after-effects/desktop/animate-in-after-effects/animation-keyframes/keyframe-interpolation.html
[ae-cache]: https://helpx.adobe.com/after-effects/desktop/memory-storage-performance/memory-and-storage/memory-storage1.html
[ae-comp]: https://helpx.adobe.com/after-effects/desktop/work-with-compositions/composition-settings/composition-basics.html
[ae-preset]: https://helpx.adobe.com/after-effects/desktop/apply-effects-and-animation-presets/effects-and-animation-presets/effects-animation-presets-overview.html
[ae-render]: https://helpx.adobe.com/after-effects/desktop/render-and-export/basics-of-rendering-and-exporting/basics-rendering-exporting.html
[ae-panel]: https://helpx.adobe.com/after-effects/desktop/get-started/get-familiar-with-the-interface/workspaces-panels-viewers.html
[ae-expr]: https://ae-expressions.docsforadobe.dev/objects/property/
[fil-rm]: https://github.com/google/filament/blob/main/filament/include/filament/RenderableManager.h
[fil-view]: https://github.com/google/filament/blob/main/filament/include/filament/View.h
[fil-mi]: https://github.com/google/filament/blob/main/filament/include/filament/MaterialInstance.h
[fil-renderer]: https://github.com/google/filament/blob/main/filament/include/filament/Renderer.h
[fil-engine]: https://github.com/google/filament/blob/main/filament/include/filament/Engine.h
[tvg]: https://github.com/thorvg/thorvg/blob/main/inc/thorvg.h
[fl-listen]: https://api.flutter.dev/flutter/foundation/Listenable/addListener.html
[fl-snap]: https://api.flutter.dev/flutter/widgets/AsyncSnapshot-class.html
[fl-pan]: https://api.flutter.dev/flutter/widgets/GestureDetector/onPanStart.html
[fl-perf]: https://docs.flutter.dev/perf/ui-performance
[fl-inspect]: https://docs.flutter.dev/tools/devtools/inspector
[dart-kw]: https://dart.dev/language/keywords
[bl-fcurve]: https://docs.blender.org/manual/en/latest/editors/graph_editor/fcurves/properties.html
[bl-undo]: https://docs.blender.org/manual/en/latest/interface/undo_redo.html
[bl-undo-pref]: https://docs.blender.org/manual/en/latest/editors/preferences/system.html
[bl-movie]: https://docs.blender.org/manual/en/latest/video_editing/edit/montage/strips/movie.html
[bl-image]: https://docs.blender.org/manual/en/latest/video_editing/edit/montage/strips/image.html
[bl-shelf]: https://docs.blender.org/manual/en/latest/interface/window_system/regions.html
[bl-constraint]: https://docs.blender.org/manual/en/latest/animation/constraints/introduction.html
[adapter]: https://refactoring.guru/design-patterns/adapter
[sq-alter]: https://sqlite.org/lang_altertable.html
[sq-pragma]: https://sqlite.org/pragma.html#pragma_user_version
[sq-session]: https://sqlite.org/sessionintro.html
[sq-apply]: https://sqlite.org/session/sqlite3changeset_apply.html
[sq-err]: https://sqlite.org/c3ref/errcode.html
[sq-kw]: https://sqlite.org/lang_keywords.html
