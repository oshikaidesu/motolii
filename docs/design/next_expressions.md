# Next-generation expressions: the ideal

*Status: an ideal, not a plan. It says what a user should be able to do and see. It chooses no library and no folder. Written on 2026-11-11 from a conversation with the author. Where it differs from an earlier note, the last section says so.*

## 1. The aim

Short code found on the net (an After Effects expression, Lua, a p5.js sketch, a Cavalry script, a Blender Python driver, TSL) is pasted and works. It runs as fast as a built-in effect, with a project of hundreds of layers open and the preview playing. Editing it is comfortable: save, and the frame under the playhead shows the new result.

This is the aim in [AGENTS.md](../../AGENTS.md) (an expression found on the net, usable in your video at once) applied to the part of Motolii that runs code.

## 2. One idea: code reads, and says what it reads

Code is a function. Given a time, a copy number and its sliders, it returns values. It may read any property of any layer, and the value of any property at an earlier time.

- Reading another layer is reading a property.
- "State" (a spring, a trail, a sketch that never clears its background) is reading its own value at an earlier time.
- There is no separate class of stateful code.
- The only thing refused is a loop at one instant: A reads B and B reads A at the same time. It is reported as an error. Reading an earlier time is always allowed.
- A long chain back in time can make the first jump to a distant frame wait. The wait shows its progress and never freezes the app.

Everything below follows from this. What the code reads is known, so it can be listed, searched, shown, and used to recompute only what changed.

## 3. What the user touches

### 3.1 Two steps in

- **Inspector:** a card, like an effect card, with sliders and an on/off switch. No code is visible.
- **Edit:** a button on the card. It opens the Program tab on that code, at that line. Going back, the card already shows the change. There is no cliff.
- If the user picks a target on the card (follow this layer's position), the app writes it as code. Pressing Edit later shows the few lines the app wrote. The card is never a second copy of the code ([AGENTS.md](../../AGENTS.md), principle 3).

### 3.2 Getting code in

Paste (⌘V), drop a file from a shelf, or type. All three give the same result. The language is recognised on paste and shown as a label. Clicking the label corrects it. There is no settings screen.

### 3.3 What a property is made of

A property is a number, keyframes or code. The timeline row draws a curve in all three cases. Code either sits on top of the keyframes (as in After Effects, where `value` is the keyframed value) or replaces them. The user chooses. Several pieces of code on one layer combine as they do today (positions add, size and opacity multiply).

### 3.4 Sliders and code are one text

A number in the code is a slider. Dragging it rewrites the number in the code. Editing the code moves the slider. There is one copy of the text. A slider's range is for display only; a typed value is not limited (principle 2).

### 3.5 What the code reads, shown beside it

- Chips beside the code: "← Leader · Position", "← itself, 0.1 s earlier". Clicking one jumps to that layer.
- Selecting a property shows which code reads it.
- Renaming a layer rewrites the name inside the code. The change is shown and one Undo reverses both.
- A reference to something deleted turns red.
- A pick whip: drag from any property field onto a card or the code to connect them.

### 3.6 The result

The timeline row shows the curve over the whole time range. An error marks its line red, and the last good result stays on screen. For code that makes many copies, the picture is open (section 9).

### 3.7 Editing

In the app, or in an outside editor and save. Either way the frame under the playhead updates at once. The playhead, the selection and the sliders stay. Only the edited code and what reads it are recomputed.

## 4. The Program tab

After Effects shows neither what can be written nor what can be connected. The Program tab has two lists that follow the project as it changes (layers added, removed or renamed; values at the playhead).

| List | Holds |
|---|---|
| **Can read** | Every property of every layer (effect sliders, text, shapes, camera), time, frame, duration, project size, sound level, MIDI, and values other code makes. Filtered by the type the property being edited wants (a number lists numbers); "show all" removes the filter. Searchable. Pressing or dragging an item inserts it as the code's language says it: an After Effects expression gets After Effects' way, Lua gets Lua's. |
| **Can return, can say** | The names this property accepts (`x`, `y`, `size`, `opacity`, …), lit when the code returns them. The sliders the code declares. The language's own words (`wiggle`, `linear`, …) with a short explanation and an example. |
| **Who reads this** | For a selected property, the code that reads it. Known before a rename or a delete, not after something breaks. |

```
┌ Can read ───────┬ Code ────────────────────┬ Can return ───────┐
│ search [pos   ] │ 1 const L = ...          │ x     ● returned  │
│ ▾ Leader        │ 2 return ...             │ y     ○           │
│    Position     │                          │ size  ○           │
│    Opacity 100  │ ← Leader · Position      │ ── words ──       │
│ ▸ Circle        │ ← itself, 0.1 s earlier  │ wiggle(freq,amp)  │
│ ▸ Time, Sound   │                          │ linear(t,a,b,…)   │
├─────────────────┴ Result: curve / errors ──┴───────────────────┤
```

## 5. What the Program tab takes

### 5.1 The Inspector for one, the Program tab for many

The Inspector touches one value of one thing. The Program tab writes many at once. Text is the best interface for a row of things: one line says what a hundred sliders would.

Everything in Motolii therefore has two faces: a visual one (the Inspector, the timeline) and a written one (the Program tab). There is one copy of the truth (principle 3). The Program tab is not a place for p5.js sketches only. It is the way in for every expression that is written as text.

### 5.2 A row is a row

These are all the same thing to code: a row of n, each with its number i.

- the copies of a layer
- the letters, words or lines of a text layer (`split` already makes each one a copy)
- the layers inside a group layer
- the keyframes of a property
- the rows of a data file (CSV, JSON)
- the beats of a sound, the notes of a MIDI file, the lines of a timed lyric

In After Effects, a stagger across layers is written by hand from `index` in every layer (`thisLayer.index - 1` times a delay). That is the sign of a row that cannot be written as a row. Here, one piece of code on the group reaches every child as copy i of n.

So text motion is born in the Program tab. A text layer split into letters is a row, and any language that speaks of rows moves it.

Two ways of writing a row exist today: `each(i, n, t, k)`, asked once per copy, and a relation's `relate(things, t, k)`, given the whole array. Since 2026-11-11 a file with `each()` and no `relate()` also runs as a relation: layer i of the relation is copy i of n, and what `each()` says goes on top of the layer as it does on a copy (places and turns added, size and opacity multiplied). Pressing an Expression tile with several layers selected, or with a group picked, makes that relation; `fade_in.js` then fades the layers in one after another, unchanged. The other way round works too: a `relate()` file in a layer's effect list gets the copies, letters or words laid so far as its things, and what it says of each goes on top of that copy. `turns.js`, written for a lyric line of separate word layers, brings in the words of one text split into words, unchanged. In the Relations tab one picked layer is now enough; before, every relation was greyed out until two layers were picked.

### 5.3 Languages

A language is only a way of writing. The meaning is shared: read values, return values.

| What is written | Forms found on the net | Run as it is, by |
|---|---|---|
| Values over time | After Effects expression, Cavalry JavaScript, GSAP and anime.js timelines, Framer Motion springs | QuickJS (already) |
| Values over time, as CSS | `@keyframes`, `transition`, `cubic-bezier`, `steps()`; per letter with Splitting.js's `--char-index` and `--char-total` | a CSS engine without a browser (5.4) |
| Subtitles and karaoke | ASS override tags (`\k`, `\move`, `\t`, `\fad`), Aegisub's karaoke templater (Lua), LRC and SRT timed lyrics | pasted .ass, .srt, .lrc, .vtt and the other text formats FFmpeg reads, drawn by libass (reached 2026-11-11, `engine/community/subtitles/`); word-timed LRC and the templater open |
| Exported from After Effects | Lottie JSON, with expressions | ThorVG's Lottie loader, which already runs Lottie expressions in JerryScript (`src/loaders/lottie/tvgLottieExpressions.cpp`) |
| Looks | CSS `text-shadow` stacked many times, `background-clip: text`, `filter`, `mix-blend-mode` (most CodePen text effects) | a CSS engine without a browser (5.4) |
| Shapes | SVG paths, CSS `clip-path`, Paper.js | ThorVG's SVG loader (paths and a CSS subset; no `@keyframes`) |
| Pixels | GLSL, WGSL, ISF, Shadertoy, Hydra, TSL | the Effects shelf (already) |
| Drawing | p5.js, Processing, Canvas 2D, Dwitter | as today |
| Relations | springs, flocks, collisions | `shelves/relations/` (already) |
| Data | CSV and JSON into bars, lists and names (After Effects' data-driven animation) | p5.js's own `loadTable`, `loadJSON`, `loadStrings` and `fetch`, reading the files that came with the sketch (reached 2026-11-11, `fetch` in `engine/community/p5/p5_stand.h`); After Effects' `footage().dataValue` open |
| A whole scene | Motion Canvas, Remotion, Manim: scenes and time written as code | open |
| Lua, Blender Python | operators can be overloaded | scope open (section 9) |

Code never calls another language. An After Effects expression reads a Lua-driven property as a value. A property has one language. Languages meet through values, so CSS can sit on letters that an `each()` already placed.

### 5.4 CSS and ASS without a web page

No web page is embedded (principle 3). CSS and ASS are read as ways of writing values, and Motolii draws the result. Running them as they are (principle 1) needs an outside engine that returns values at a time, not pictures. What was found (2026-11-11, from documentation and source, not tried):

| Need | Candidate | What it gives | Not yet known |
|---|---|---|---|
| CSS at time t | Blitz (`blitz-dom`, MIT or Apache-2.0) on Servo's Stylo (MPL-2.0) | `BaseDocument::resolve(current_time_for_animations)` takes the time from the caller; Stylo samples `@keyframes` and transitions itself; `var()` and `calc()` per letter. **Tried 2026-11-11:** per-letter opacity and transform at any t, a seek being a new document (question 7) | whether `text-shadow` is computed though Blitz does not draw it; how a pasted CSS meets Motolii's letters (Splitting.js's own markup, `--char-index`) |
| CSS in SVG | anim_svg (MIT) | SVG with `@keyframes` or SMIL turned into Lottie, which ThorVG plays | experimental; SVG only, not split HTML text |
| ASS at time t | libass (ISC) | layout, `\t`, `\k` and `\move` done right | **Reached as a picture (2026-11-11):** FFmpeg's own probe tells a pasted text is subtitles (none of 10,394 shelf and library scripts was taken for one), FFmpeg writes SRT, LRC, WebVTT and the rest as ASS, and the text is wrapped into a sketch whose `__paints` asks libass for that one moment, so a song minutes long keeps no frames (`engine/community/subtitles/`, test `subtitles_sketch_test.cpp`). Per-glyph values, for code or effects on each letter, still need a patch (`GlyphInfo` in `ass_render.h`) |
| ASS as data | ass-compiler (MIT) | every tag typed, with times | the interpolation would be written by hand, which is translation; so libass is preferred |
| Karaoke templates | aegisub-cli | runs Aegisub automation from the command line | licence not stated; last push 2020 |

If neither CSS nor ASS can be had as values from an outside engine, the cut is wrong and is to be rethought before anything is written by hand.

## 6. Speed

### 6.1 When code is read and when it runs

The text of the code is read once per edit. Running happens whenever an input changes. A keyframed slider changes every frame, so the compiled form runs every frame.

The aim is therefore not "never evaluate each frame". It is: never read the text again each frame, never run what did not change, never run what is not seen, and where there are many copies do the work in bulk or on the GPU.

### 6.2 Principles

The cost follows what changed, not what exists. One frame at 60 fps is about 16.7 ms, drawing included.

| Principle | What it means | What the user sees |
|---|---|---|
| Only what is drawn | Work back from the layers on screen. Code on a layer that is hidden, outside its time range or under a hidden parent does not run. | Hiding a layer makes the project lighter. |
| Only what changed | If nothing it reads changed, reuse the last result. Code that reads only constants and sliders runs once. | A layer that does not move costs nothing. |
| Identical code together | The same code on 100 layers runs once, for 100 sets of values. A copy and a layer are the same thing here. | Duplicating a layer does not make it heavier. |
| Simple forms | Code that depends on time alone is turned into a curve and looked up. | Playback reads a table. |
| Ahead of time | Code that does not depend on an earlier time is computed for the frames after the playhead, in spare time. | Playback does not stutter. |
| Heavy work on the GPU | Positions of thousands of copies are computed on the GPU. The CPU hands over numbers. | A thousand copies stay light. |

### 6.3 The code as written is the reference

Code is first run as written, so it shows at once. A faster form is made in the background and replaces it only if it gives the same results. Code that cannot be made faster keeps running as written. Some code is fast and some is not, but no code fails to run. This is [AGENTS.md](../../AGENTS.md) principle 1: posted code is run as it is, not imitated.

### 6.4 Cost is visible

After Effects cannot say which expression is slow. Here, the layer list has a column for the cost of code (none, light, heavy), sortable. Each piece of code shows its time per frame ("0.3 ms"). The status bar warns when the total approaches the frame budget. A heavy piece of code says why, and how to write it so it is lighter.

### 6.5 The scale to design for

This is an estimate by the author and Claude, not a measurement: **200 layers with code, 10,000 copies, 60 fps**, with a few milliseconds a frame for all code together. 10,000 copies at 60 fps is 600,000 evaluations a second. A project with thousands of layers with code is unusual (templates, data-driven work). It need not be fast, but it must not break, and it must say it is heavy.

## 7. The node graph

The one intermediate form is a graph of nodes, as in TSL.

```
code (any language)
  │  run once; the inputs are marks: time, copy number i, sliders, reads
  ▼
node graph  ── the only intermediate form
  ├─ UI:       what it reads, sliders, types, who reads it, cost
  ├─ GPU:      compiled to WGSL, computed in bulk
  ├─ CPU:      computed in bulk
  └─ check:    compared with the result of running the code as written
```

TSL works in two stages. JavaScript runs once and builds the graph of nodes, which is compiled to WGSL or GLSL. Only a few numbers (uniforms) change per frame, and the shader is not rebuilt. Keyframes on a slider move a uniform and nothing else.

What follows from using a graph:

| Decided earlier | In the graph |
|---|---|
| What the code reads; who reads it | Nodes that read a property. Count the leaves. |
| Sliders, keyed over time | Uniform nodes. Only their values change. |
| Lists filtered by type | Every node has a type. |
| Identical code together | The same graph is the same graph. One build, one computation. |
| Cost shown | The sum of the cost of the nodes. |
| Hot reload | Rebuild the graph, swap what differs, reuse what did not change. |

How each language gets into a graph: the code is run once, as written, with marks instead of numbers. An After Effects expression already has its `+ - * /` rewritten once, by `AE.compile`; that step would build nodes instead of numbers, and `if` and `?:` become `select`. Cavalry's `each(i, n, t, k)` gets `i` as the copy-number node, so all copies are computed at once. Lua and Python overload operators, so they need no rewrite.

What falls outside, and keeps running as written, with the reason shown: loops whose count depends on a value, side effects inside an `if`, strings and objects (a node has a number, vector, colour, boolean or reference as its type), references built by calculation (treated as "may change", which is safe and slow), and recurrences on an earlier time (they run in order).

The vocabulary of nodes is the meaning that every language shares. The proposal is TSL as the base, plus three nodes: read another property, read at another time, and copy number.

The result is lightest when drawing reads per-copy values straight from a GPU buffer. The ideal includes that.

## 8. Rules this ideal relies on

From [AGENTS.md](../../AGENTS.md):

1. Net expressions are not translated; the posted code is run as it is (sections 6.3 and 7).
2. No value is fixed without a source; a slider's range is only for display (3.4).
3. No web page inside the app; looks are read from the code and edits are written back; no second copy of the code (3.1, 3.4).
5. Dart holds only the look; the lists, chips and curves are looks, and what they show comes from the engine (sections 3.5 and 4).

## 9. Open questions

1. **Node vocabulary:** TSL as the base with three nodes added, or Motolii's own?
2. **Drawing:** may drawing read per-copy values from a GPU buffer, and is that part of the ideal?
3. **Code and keyframes:** does code sit on top by default (the proposal) or replace?
4. **Many copies:** a strip of copies against time, or one copy at a time?
5. **Blender Python:** drivers only, or `bpy` and the objects it reaches?
6. **p5.js:** later, as written; is that acceptable?
7. **CSS:** can Blitz sample `@keyframes` at any time, backwards included, and return values without drawing? **Answered 2026-11-11, tried:** yes, without a patch. Forward, `resolve(t)` gives each letter's opacity and transform as Stylo computes them (`calc(var(--char-index) * 100ms)` delays and `cubic-bezier` agree with each other to six places). Backward it does not: a finished animation stays finished, and a new document stamps its start at its first `resolve`. A seek is therefore a new document resolved at 0 and then at t, which gives the forward values exactly: 0.19 ms a seek, 0.0035 ms a frame played forward (blitz-dom and blitz-html 0.3.0-beta.4, release build, first build 1 min 3 s).
8. **ASS:** the picture is reached as it is (5.4). How large is the libass patch that hands out per-glyph values, and is it wanted before someone asks to put code on a karaoke letter?

Decided in the conversation: the Program tab is the way in for every written expression, and a row (copies, letters, the layers of a group, data rows) is one thing to code (section 5); renaming a layer rewrites names in code (with Undo); a pick whip is wanted; a reason is shown when code cannot be made fast.

## 10. Relation to earlier notes

[create_and_program_shelves.md](create_and_program_shelves.md) (9 November) says an After Effects expression lives only in the layer's detail panel and is not shown in the Program tab. This note proposes that the Inspector card stays the place for light use and that **Edit opens any code in the Program tab**. If this ideal is accepted, that line of the earlier note is to be revised. The names in that note ("Expression", the Create shelf) are not changed here.

The same note says the Program tab holds closed packs only (p5.js, whole Cavalry scripts). Section 5 widens it: the Program tab is the written face of everything, and text motion, CSS, subtitles and group layers come in through it. That line is also to be revised.

## Appendix: where the code stands (2026-11-11), kept apart from the ideal

- `AE.compile` reads an expression once with acorn and rewrites `+ - * /` as vector-aware calls. Each frame the resulting function is called in QuickJS-ng ([ae_expr.h](../../engine/community/after_effects/ae_expr.h)).
- `each()` is called once per copy per frame (`Script::ask` in [script_runner.cpp](../../engine/community/script_runner/script_runner.cpp)).
- QuickJS-ng has no JIT. The note [sketch_import_test_record.md](sketch_import_test_record.md) says what that costs has not been measured. It did measure p5 sketches: a median of 0.8 ms a frame, and a median of 20 shapes a frame (at most 7,611). Copies of one solid are capped at 1000.
- TSL: three.js's own node builder runs in QuickJS as a tool; only the resulting `.wgsl` files are on the shelf ([ARCHITECTURE.md](../ARCHITECTURE.md)).
- Measured on 2026-11-11 (Apple M4, one thread, the engine built that morning, `Script::copies` called straight from the library, 60 frames, empty knobs): `fade_in.js`, `lyric.js` and `Field.js` from `shelves/expressions/` each cost about 0.6 µs a copy, whatever the script. 1,000 copies take 0.57–0.64 ms a frame; 10,000 take 5.7–6.5 ms. The line set before measuring was 4 ms at 10,000 copies, so 1,000 passes and 10,000 does not.
- Calling the same `each()` 10,000 times inside one JavaScript loop instead of once per copy from C++ was no faster (6.4–7.3 ms). The cost is QuickJS running the code, not the crossing between C++ and JavaScript. Doing the copies in bulk in JavaScript is therefore not enough; what is left is running them on several threads, or the node graph of section 7.
- Since 2026-11-11 `Script::copies` shares 2,000 copies or more among threads, each asking a `Script` of its own (one QuickJS runtime each), at least 1,000 copies a thread. 10,000 copies now take 1.3–1.4 ms a frame (median; the worst of 60 frames, 3.8–4.6 ms, is probably the first, which makes the helper runtimes, but that frame was not timed alone). This is under the 4 ms line, so the node graph of section 7 is not needed for speed at this scale. A p5.js sketch and a script that reads other layers stay on one thread. The rule that one runtime runs on one thread is the QuickJS manual's, section Runtime and contexts (https://bellard.org/quickjs/quickjs.html); quickjs.h only says to call `JS_UpdateStackTop` when changing thread (commit 746f3be29 named quickjs.h for it, wrongly).
- Section 7 tried on 2026-11-11, as a probe outside the engine (Apple M4). The 25 `each()` files on the shelf were run once each in QuickJS-ng with three.js 0.185.1's TSL nodes for `i`, `t`, the copy's place and the knobs, and three.js's own `WGSLNodeBuilder` built the result with no GPU, as [convert.ts](../../engine/community/three_shading_language_to_shelf/convert.ts) does. The operators were rewritten with acorn the way `AE.compile` rewrites them. An `if` that returns early became a `select` of both ways, and so did `?:`, `&&` and `||`. Code made with `new Function` (what `AE.compile` returns) was rewritten in the same way. The engine's own preludes were read from their sources: Cavalry's `animate` and `random`, `ease` by name, After Effects' runtime and leva's `folder`.
  - With each knob a uniform, 21 of 25 files became WGSL. With each knob built in as a constant, 24 of 25 did. Of the four, three (`wave`, `lyric`, `repeater`) have an `if` that decides on a knob, and a knob that decides an `if` has to be built in. Rebuilding the shader when such a knob moves is how TSL already treats a change of `defines`. The fourth, `poster.js`, cuts its grid in a loop whose count changes with time. It stays outside, and the reason is shown.
  - All 96 `.wgsl` files passed naga 30.0.1.
  - The check: each of the 24 files was run at t = 0.2, 0.7 and 2.5 s for 64 copies, as a compute shader on the GPU (Deno 2.9.7's WebGPU, wgpu on Metal). The results were compared with the same file run as written in QuickJS. 71 of 72 agreed to 1e-4. The one that did not is `wave_rows.js` at 2.5 s: one copy's turn is −0.00014° on the GPU and −5e-14° in JavaScript. That is `sin` in 32-bit floats, not a different meaning.
  - The check was seen failing first. With `0.33` changed to `0.34` in one shader, `fade_in` was reported as differing by 9.3e-3.
- TypeGPU's `tinyest-for-wgsl` 0.3.3 (a JavaScript-to-WGSL transpiler) was read, not installed. Judged against its table of the syntax it accepts, it would take 1 of the 25 files: arrow functions inside, `var`, several declarators in one statement and spread are refused. Running the code once, as above, needs none of that syntax handled.

Candidates for later, surveyed from documentation and not tried (none is part of the ideal): MLIR (an intermediate-form framework in LLVM; it does not read JavaScript or Python for you), tree-sitter (incremental parsing with byte positions), wasm3, WAMR and wasmtime (WebAssembly runtimes), Slang (shader language; WGSL and Metal output are experimental), NumExpr (a bytecode machine that runs an expression over chunks of 4096 values).

Sources used for the outside facts:
[Blitz CSS status](https://blitz.is/status/css) ·
[Blitz](https://github.com/DioxusLabs/blitz) ·
[Stylo animation.rs](https://docs.rs/stylo/0.18.0/src/style/servo/animation.rs.html) ·
[Stylo TElement](https://docs.rs/stylo/latest/style/dom/trait.TElement.html) ·
[anim_svg](https://pub.dev/documentation/anim_svg/latest/) ·
[libass ass.h](https://github.com/libass/libass/blob/master/libass/ass.h) ·
[libass ass_render.h](https://github.com/libass/libass/blob/master/libass/ass_render.h) ·
[ass-compiler tags](https://github.com/weizhenye/ass-compiler/blob/master/types/tags.d.ts) ·
[aegisub-cli](https://github.com/Myaamori/aegisub-cli) ·
[Aegisub karaoke templater](https://aegisub.org/docs/latest/automation/karaoke_templater/code_execution_environment) ·
[MLIR users](https://mlir.llvm.org/users/) ·
[MLIR Toy tutorial](https://mlir.llvm.org/docs/Tutorials/Toy/) ·
[MLIR SPIR-V dialect](https://llvm.googlesource.com/llvm-project/+/a58dcc5e08665f2d58a28c9d4510cf94de6ed3bf/mlir/docs/Dialects/SPIR-V.md) ·
[three.js TSL docs](https://threejs.org/docs/TSL.html) ·
[three.js TSL wiki](https://github.com/mrdoob/three.js/wiki/./Three.js-Shading-Language) ·
[NumExpr](https://numexpr.readthedocs.io/en/stable/intro.html) ·
[WebAssembly runtimes compared (arXiv)](https://www.arxiv.org/pdf/2405.09213) ·
[Slang compilation API](https://shader-slanggithubio-aidanfnv-wip.readthedocs.io/en/latest/compilation-api.html).
