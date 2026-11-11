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

Every choice in this section and the next is judged by five rules:

1. The person writing never has to go to another screen or web page to find out what can be written.
2. Every list is made from what runs. No list is kept by hand.
3. No value is fixed or greyed out (principle 2).
4. There is one kind of card. Effects, expressions and relations are items of the same list.
5. A person and an LLM are shown the same lists.

### 3.1 Two steps in

- **Inspector:** a card, like an effect card, with sliders and an on/off switch. No code is visible.
- **Edit:** a button on the card. It opens the Program tab on that code, at that line. Going back, the card already shows the change. There is no cliff.
- A target (follow this layer) is a slider that holds a layer, declared in the code like any other slider. Picking another layer changes the slider, not the code. The card is never a second copy of the code ([AGENTS.md](../../AGENTS.md), principle 3).

### 3.2 Getting code in

Paste (⌘V), drop a file from a shelf, or type. All three give the same result. The language is recognised on paste and shown as a label. Clicking the label corrects it. There is no settings screen.

### 3.3 What a property is made of

A property is a number, keyframes or code. The timeline row draws a curve in all three cases. Code either sits on top of the keyframes (as in After Effects, where `value` is the keyframed value) or replaces them. The user chooses. Several pieces of code on one layer combine as they do today (positions add, size and opacity multiply).

### 3.4 Sliders and code are one text

A number in the code is a slider. Dragging it rewrites the number in the code. Editing the code moves the slider. There is one copy of the text. A slider's range is for display only; a typed value is not limited (principle 2). Once a slider has keyframes, they live on the card, as an effect slider's do, and the number in the code is its value where there are none.

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

There is no Apply button: the picture follows the code as it is typed. One Undo step ends where typing pauses.

### 3.8 Writing with an LLM

The person says what they want, for example "this layer gathers toward the middle of that layer", and an LLM writes the code.

- **The intent is a sentence.** The layers in it are not typed. They are picked by clicking on the stage or in the layer list, and each becomes a small tag in the sentence. A tag holds the layer's name as the code's language spells it (`thisComp.layer("B")`), so the LLM cannot invent a layer that does not exist.
- **Pressing the LLM button gives five things:**

| What | Example |
|---|---|
| One line saying what was understood | "A gathers toward the middle of B." It is read before any code. |
| The motion | The layer moves on the stage; play and scrub work. |
| Sliders | Whatever is a matter of taste: Amount, Spread. |
| The code | In the Program tab. Read it only if you want to. |
| What it decided | As sliders that pick from words, not as sentences (below). |

- **Anything a person may want to change later is a slider:** time, amount, direction, and the layer it acts on. No number in the code is a timing. "Over two seconds" is two keyframes on an Amount slider (0 to 100 %), which the LLM places as a start and the person moves on the timeline. Easing is the curve of those keyframes. This is After Effects' usual pairing: a Slider Control with keyframes, and an expression that reads it.

```
Gather
  Toward     [ B ▾ ]                  ← a slider that holds a layer
  Amount     ◆──────────◆  0 → 100 %   ← keyframes
  Middle     [ middle of what is drawn ▾ ]
```

- **A choice the LLM made** (that "middle" means the middle of what is drawn, not the anchor point) is a slider that picks from words. It is changed by picking, and the screen does not fill with sentences.
- **The LLM asks nothing back.** It decides and shows what it decided, because changing a slider is quicker than answering a question.
- **Asking again** ("a little slower") edits the same code; it does not write new code. Each change is one Undo step. What a slider can do does not call the LLM.
- **What cannot be read yet** (a name not in the tree of 4.4) is said plainly, "cannot read X yet", instead of being faked.

### 3.9 Code on a group

- **What a card acts on is the layer it is on.** On one layer it acts on that layer. On a group it acts on every layer inside, and the code receives them as an array in the order of the layer list. Dragging a layer up or down the list changes its number.
- **This is what a relation is.** The user does not tell an expression and a relation apart. Layers that should act together are grouped, and the card goes on the group; a single other layer is picked with a layer slider. (The Relations tab and the relation marks on the stage were removed on 2026-11-11; relation files are Expression tiles in the Create tab.)
- **One set of keyframes, many layers.** A Delay slider (seconds per layer) makes layer i read the same curve i × Delay later, so moving one curve changes every layer. An Order slider picks top first, bottom first, middle out or random, as Cavalry's Stagger does.
- **Beside the code, a table with one row per layer** shows the value the code gives each layer at the playhead, with a small bar. Pointing at a row lights that layer on the stage. After Effects' timeline and node tools show only the result, not the array; code shows the array, so it is shown.
- A group inside a group stays a tree (4.4).
- If the layer a slider picks is inside the same group, it does not move toward itself. It stays where it is, without a warning.
- The sliders are on the card only. They are not repeated on the group or on its layers.

### 3.10 Cards in order

- Cards act from top to bottom, as an effect stack does. A card receives the result of those above it as `value`, as After Effects gives an expression the keyframed value.
- A property moved by code is not locked or greyed out. Its keyframes stay editable, and the code gets them as `value`.
- The property's row shows a mark that code moves it. Pressing the mark goes to the card. This is the "who reads this" of 4.3, seen from the other end.

### 3.11 Keeping it on a shelf and using it again

- **Dragging a card to a shelf saves it:** the code, its sliders with their values, and their keyframes. There is no dialog; the name is the card's. The tile's picture is a few seconds of the motion, recorded, and it plays when pointed at.
- **The layers it was pointed at are not saved.** Those sliders are left empty, and the tile shows how many layers it needs.
- **Dropping it on a layer or a group** puts the card in. Its first empty layer slider lights, ready as a pick whip: clicking a layer fills it, and then the next one lights. Until they are filled, the layers stay as they are, with no error and nothing greyed out; the card says "pick a layer to start".
- **The tile and the card it came from are separate from then on**, as an After Effects animation preset is. A shelf is a library that is copied into a project when used (4.2).
- A file opened from a shelf only to be read is not yet decided (9).

## 4. One kind of thing, one editor, one list of what can be read

### 4.1 Code on a layer is one kind of thing

Everything that is code on a layer is told apart by one fact, which is in the file: what it returns.

| Returns | Is | Examples |
|---|---|---|
| a picture | an fx. With no input it is a source: it draws from time and its sliders alone (Effects already has a Generate category of pictures made from nothing) | a shader, a Shadertoy, a p5.js sketch |
| values, per copy | an expression | an After Effects expression, Cavalry's `each()`, CSS keyframes |
| layers | a script that makes things; an adapter turns what it made into ordinary layers | a three.js scene (solid layers), an SVG (an image layer) |

There is no fourth kind, "a closed pack that holds its own things, motion and knobs". The 9 November split (Create for what the host holds, Program for packs that are closed) is dropped. A pack is code that has not yet been read as one of the three rows, and if some code cannot be, the cut is wrong and is rethought. Not yet checked: that every p5.js sketch and Cavalry script on the shelves reads as one of the rows. That check is the test of this cut.

How much of the host a file reads (its own sliders, any property of any layer) is also a fact in the file (section 2). It is not a kind. Nothing else tells the rows apart: not the shelf that showed the file, not the tab it was pasted from.

- **The kind is read from the file's content.** The engine already does this: `doc_expression` ([expressions.cpp](../../engine/document/scripts/expressions.cpp)) takes a `.css`, or a `.js` that lays copies, as an expression, and the rest of a layer's fx list is drawn. A shelf folder is for finding a file, not for deciding what it is.
- **A layer has one list.** Today it has two places: the fx list, and a single `script` slot used by sketches. With no closed packs the slot holds nothing the list cannot, so it is folded into the list (at 2026-11-11 the word is in 37 places in 21 engine files). Until then an expression and a sketch cannot sit on one layer together.
- **Where an fx and an expression cross:** an fx's sliders are names code can read, `effect("Blur")("Amount")` in After Effects' spelling. That one crossing is most of what "connecting" means in After Effects, and it is why the list in 4.3 holds fx sliders like any other property.

### 4.2 One editor

The Program tab is the editor that opens any item of a layer's list at its code. The Edit button on a card (3.1) opens it there, whether the card is an fx, an expression or a source. There is one editor, not one for each kind.

There is no Program shelf of packs, because there are no packs (4.1). Today the shelf's tiles and the editor are one class ([program_shelf.dart](../../app/lib/workspace/dock/program/program_shelf.dart)). The tiles go with the packs and the editor stays.

A file that came from outside by paste or drop belongs to the project, as a script in Blender's Text Editor belongs to the .blend. It is not a shelf item; a shelf is a library of other people's work that is copied into a project when used. (A design, not yet decided with the author.)

### 4.3 What the editor shows beside the code

After Effects shows neither what can be written nor what can be connected. Its expression language menu (the arrow button beside an expression) lists functions apart from the code being written, and is little used. Here every list is tied to the code, to the cursor and to the value now, and follows the project as it changes (layers added, removed or renamed; values at the playhead).

**The Program tab holds the code and nothing else.** What is shown beside it is in panels of their own. They follow the selected card and can be placed anywhere, as Blender's Properties editor follows the active object. A new use adds a panel; the tab itself does not change. On first opening only the code and its result are shown: the lists come up anyway as suggestions while typing.

| Where | What |
|---|---|
| **At the cursor, while typing** | Suggestions. After `thisComp.layer(`, the layers of this project; after `.`, what that layer can be read for (position, opacity, effect sliders). Each shows its value at the playhead. The nearest come first: the layers of the same group, then the group above it, then the project; a search covers the whole project. |
| **On the word under the cursor** | A short explanation and a small picture: the curve of `ease`, the shake of `wiggle`, the value now of a name. |
| **Under the code** | The result over time as a curve; on a group, the table of 3.9. An error is shown on its line in plain words, and the last good result stays on screen (3.6). |
| **Panel: Can read** | The tree of 4.4: every property of every layer (effect sliders, text, shapes, camera), time, frame, duration, project size, sound level, MIDI, and values other code makes. Searchable. Filtered by the type the property being edited wants (a number lists numbers); "show all" removes the filter. Pressing an item inserts it at the cursor as the code's language says it: an After Effects expression gets After Effects' way, Lua gets Lua's. |
| **Panel: Functions** | Grouped by what they are for, not by name: Shake, Ease between, Read another layer, Shift in time, Random. Each has one line and a small moving picture. Pressing one inserts it with blanks to fill. The list is made from what the runtime answers, not written by hand. An After Effects function that does not run yet is listed too, marked "does not run yet" and last in its group: posted code uses it, and this list is the order in which to make them run. |
| **Can return** | The names this property accepts (`x`, `y`, `size`, `opacity`, …), lit when the code returns them, and the sliders the code declares. Shown on the card. |
| **Who reads this** | Not a panel. A mark on the property's row in the Inspector (3.10), and the chips beside the code (3.5). The stage draws nothing about relations. |
| **Sending to an LLM** | Not a panel. A button that sends the code with the lists of 4.5 (3.8). |

```
┌ Program ─────────────────────┐ ┌ Can read ──────┐ ┌ Functions ────────────┐
│ 1 const B = thisComp.layer(  │ │ search [     ] │ │ search [            ] │
│   ┌──────────────────────┐   │ │ ▾ Leader       │ │ ▾ Shake               │
│   │ "B"     960, 540     │   │ │    Position    │ │    wiggle(speed, amt) │
│   │ "Leader" 200, 300    │   │ │    Opacity 100 │ │ ▾ Ease between        │
│   └──────────────────────┘   │ │ ▸ Circle       │ │    ease(t, a, b, …)   │
│ ← B · Position               │ │ ▸ Group (12)   │ │    linear(t, a, b, …) │
├ Result: curve / errors ──────┤ │ ▸ Time, Sound  │ │ ▸ Read another layer  │
│  ╭──╮___╭─                   │ │                │ │ ▸ (does not run yet)  │
└──────────────────────────────┘ └────────────────┘ └───────────────────────┘
```

### 4.4 The list is a tree, not a flat list

A project is built from groups, and the list must keep that.

- **The root is the group the code sits in.** Its other members are one line each. The groups above it are one line each, up to the project. Names that belong to the whole project (time, frame, size, sound, MIDI) come first.
- **A group is a row** (5.2). To code it is one line with a count, and it is read as `group[i]` of n. It is not n lines. The user steps into a group to see what is inside; nothing is expanded for them.
- **Nothing is written by hand.** The tree is made from what the engine can resolve at that moment (principle 3). A hand-kept copy would drift from the engine, and a list that has drifted is worse than none, because a reader trusts it.
- **The door exists; the list does not.** Code reads another layer today through `layerValue(id, name, t, otherwise, copy)` ([script_runner.h](../../engine/community/script_runner/script_runner.h)), by layer number, and only a relation written as a file uses it. It answers eight names: `x`, `y`, `z`, `size`, `rotate`, `rotate_x`, `rotate_y`, `opacity` (`doc_relate_names`, [relations.h](../../engine/document/evaluate/relations.h)). An fx slider, a text, a group or a name like `layer("Leader")` is not among them. The tree is the listing of what that door answers, and it grows as the door does.

### 4.5 The same tree goes to an LLM

The list is also what a person or an LLM needs in order to write the code. After Effects shows it only through the pick whip, so it can be handed to neither. Here the tree is text in the spelling of the code's language: an After Effects expression is given `thisComp.layer("Leader").transform.position`, not a Motolii name for it (principle 1).

- The string pressed in the list and the string given to the LLM are one string, from one place.
- The LLM gets the tree from the selected property, one level deep: a group arrives as a name, a count and a type, and is opened only when asked. The whole project is never sent.
- A name the LLM writes that is not in the tree is reported at once as unknown, so an invented layer name does not wait for playback to fail.

### 4.6 Who reads this

`AE.compile` already reads an expression once with acorn. A read written as a literal (`layer("Leader")`) is found there. A read built by calculation is marked "may change", which is safe and slow (section 7). Renaming a layer rewrites the literal ones (3.5).

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

Two ways of writing a row exist today: `each(i, n, t, k)`, asked once per copy, and a relation's `relate(things, t, k)`, given the whole array. Since 2026-11-11 a file with `each()` and no `relate()` also runs as a relation: layer i of the relation is copy i of n, and what `each()` says goes on top of the layer as it does on a copy (places and turns added, size and opacity multiplied). Pressing an Expression tile with several layers selected, or with a group picked, makes that relation; `fade_in.js` then fades the layers in one after another, unchanged. The other way round works too: a `relate()` file in a layer's effect list gets the copies, letters or words laid so far as its things, and what it says of each goes on top of that copy. `turns.js`, written for a lyric line of separate word layers, brings in the words of one text split into words, unchanged. The Relations tab took one picked layer too; the tab was removed on 2026-11-11, and the relation files are now tiles under Expression in the Create tab.

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

**Half-transparent letters stay lighter than in Chrome, on purpose (decided 2026-11-11).** Motolii blends layers in linear light (Filament), and a browser blends sRGB values. So opacity 0.5 of black over white shows as #BB in Motolii and #80 in Chrome. This was measured on the CSS stills; place, turn and size agree within 1.4 px. No opacity correction can close the gap. To match Chrome, black over white needs 0.78, but white over black needs 0.22: the needed value depends on both colours. Matching it would mean blending those layers in sRGB, so linear blending would be given up. Linear is kept for every layer, and fades are left as they are. Blender and Nuke make the same choice. At 0 and 1 the two agree.

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

The vocabulary of nodes is the meaning that every language shares. The proposal is TSL as the base, plus three nodes: read another property, read at another time, and copy number. Decided on 2026-11-11: the nodes are TSL's own, and the graph is never a condition for running (12.4).

The result is lightest when drawing reads per-copy values straight from a GPU buffer. The ideal includes that.

## 8. Rules this ideal relies on

From [AGENTS.md](../../AGENTS.md):

1. Net expressions are not translated; the posted code is run as it is (sections 6.3 and 7).
2. No value is fixed without a source; a slider's range is only for display (3.4).
3. No web page inside the app; looks are read from the code and edits are written back; no second copy of the code (3.1, 3.4).
5. Dart holds only the look; the lists, chips and curves are looks, and what they show comes from the engine (sections 3.5 and 4).

## 9. Open questions

1. **Node vocabulary:** TSL as the base with three nodes added, or Motolii's own? **Answered 2026-11-11:** TSL's own nodes, as three.js ships them. Motolii makes no form of its own in between (12.4).
2. **Drawing:** may drawing read per-copy values from a GPU buffer, and is that part of the ideal?
3. **Code and keyframes:** does code sit on top by default (the proposal) or replace? **Answered 2026-11-11:** on top. Cards act top to bottom and each gets what is above it as `value` (3.10); code that does not read `value` replaces it.
4. **Many copies:** a strip of copies against time, or one copy at a time? For the layers of a group it is a table, one row per layer at the playhead (3.9); for the copies of one layer it is still open.
5. **Blender Python:** drivers only, or `bpy` and the objects it reaches?
6. **p5.js:** later, as written; is that acceptable?
7. **CSS:** can Blitz sample `@keyframes` at any time, backwards included, and return values without drawing? **Answered 2026-11-11, tried:** yes, without a patch. Forward, `resolve(t)` gives each letter's opacity and transform as Stylo computes them (`calc(var(--char-index) * 100ms)` delays and `cubic-bezier` agree with each other to six places). Backward it does not: a finished animation stays finished, and a new document stamps its start at its first `resolve`. A seek is therefore a new document resolved at 0 and then at t, which gives the forward values exactly: 0.19 ms a seek, 0.0035 ms a frame played forward (blitz-dom and blitz-html 0.3.0-beta.4, release build, first build 1 min 3 s).
   **Measured against Chrome the same day, on CSS from the net.** Five public CodePen pens that animate letters split by Splitting.js were used: shshaw/paWgLq, valhead/zYvxEVX, dev_loop/vqpreL, MeriliVaziri/azoXqEQ and SRHubli/aboJpOq (a public pen is MIT). Their CSS and HTML were kept as written, with only `@import` of web fonts removed. The letters were marked up as Splitting.js marks them, read from its sources, not run: `.word` and `.char` spans with `--word-index`, `--char-index`, `--word-total` and `--char-total`. Chrome paused every animation at 0.3, 0.9 and 1.7 s at 1280 × 720.
   - **The values compared:** each `.word` and `.char`'s opacity, and its transform made a matrix. Blitz's transform is Stylo's computed value made a matrix by Stylo's own `to_transform_3d_matrix_f64`. Percentages were resolved against Chrome's box for that element, because the box is the drawer's to give: Motolii draws the letters, with its own font.
   - **Three things had to change on the way:**
     - Blitz's own `resolved_style_value` resolves a percentage against Blitz's layout box. Without a font, that box is 0, so `translateY(-60%)` came back as 0.
     - Stylo moves an animation on by one iteration an update (`iterate_if_necessary`, `servo/animation.rs`), because Servo updates once a frame. Jumping 0.8 s left a 0.5 s loop behind, so the document is moved on 1/60 s at a time, as Motolii plays. The seek above is therefore a replay from 0 at 60 steps a second, not one jump.
     - The checker first measured turns in pixels, and so missed a 0.42 turn. It was split into turn and scale (0.01) and move (0.5 px).
   - **Result:** dev_loop is left out, because its pen leaves `.char` inline: Chrome does not transform an inline box, and splitting.css, which makes it inline-block, was not among the pen's files. Of 294 element-times in the other four, 264 agree within 0.01 and 0.5 px. valhead agrees everywhere. The 30 that do not have two causes, both in Stylo:
     - It solves `cubic-bezier` only to 1/(200 × duration) (`servo/animation.rs` line 65), up to 5 ms of curve on a 1 s animation: 0.6–1.3 px on a 128 px letter. Chrome's value agreed with the curve solved exactly (bisection, 100 steps) to six places.
     - Where keyframes list different functions (`rotateY(-25deg)` against `translateY(2%) rotateY(25deg)` in SRHubli's fall), Stylo keeps an `InterpolateMatrix` to be resolved once the box is known, and turning it into a matrix gave identity. Stylo's own matrix interpolation (decomposition, `animated/transform.rs`) can resolve it once the box is passed in.
   - **Both causes removed, the same day:** all 294 element-times agree, the worst by 0.036 px.
     - The curve is solved to 1e-7, Chromium's `kBezierEpsilon` (`ui/gfx/geometry/cubic_bezier.cc`). This is a three-line patch to Stylo's `servo/animation.rs`.
     - `InterpolateMatrix` is resolved the way Stylo's own TODO in `to_3d_matrix` (`values/generics/transform.rs`) describes. Each list is made a matrix against the box, the two are interpolated by Stylo's `Matrix3D::animate`, and the list is multiplied by Stylo's `to_transform_3d_matrix_f64`. It is about 15 lines outside Stylo; Stylo itself is untouched.
     - The last 0.6 px was the checker's own: Chrome's `offsetHeight` rounds 77.5 px to 78. The box is now read from Chrome's computed width and height.
     - So the piece the engine needs takes each letter's box from Motolii. It gives back the letter's opacity and its matrix, and moves the document on one frame at a time.
   - The pages, the Rust probe, the patch and the in-Chrome comparison are kept in `docs/internal/css_letters/`, which git ignores.
   - **In the engine (2026-11-11):** `engine/community/css/` is the piece, built by Cargo through Corrosion; Stylo is fetched and patched by `engine/deps/stylo.sh`. A `.css` file in a text layer's effect list moves its letters (`doc_css_lay`, `document/scripts/expressions.cpp`), with an `.html` file of the same name beside it as the pen's HTML. Each letter's matrix composes transform-origin, `translate`, `rotate`, `scale` and `transform` as CSS Transforms 2 §6 says, and then every ancestor's. An ancestor's box is the box around the letters inside it.
     - **Checked against Chrome's drawn boxes:** Chrome measured each letter with every transform off (the box Motolii gives) and as drawn (`getBoundingClientRect`, opacity times its ancestors'). The given box moved by our matrix is compared with Chrome's. This covers transform-origin, ancestors and perspective, which the computed-value check did not.
     - All 5 pens, dev_loop included, agree on 279 of 279 letter-times (0.5 px, 0.01). Before the rule below, MeriliVaziri was off on 24 of them.
     - **The rule:** a plain inline box is not a transformable element (CSS Transforms 1). MeriliVaziri's letters are left inline, so Chrome draws them unmoved and only fades them.
     - **Drawn by the engine:** a text layer "Backwards" with valhead's CSS, stills at 0.3, 0.9 and 1.7 s. Each letter rises by Chrome's fraction of its box times one height, 162 to 169 px for every letter, upward.
     - **Pasted (the same day):** CSS with `@keyframes` and no JavaScript is the form `css` (`adapter_form`). ⌘V puts it on the selected text layer, kept in the Program shelf as a `.css` file, and splits the text into letters. Pasting valhead's CSS gives the same lifts as the file put on by hand. Before the change, the same paste was refused as "not code".
     - **Laid out by the pen (the same day):** where the CSS makes the text, or a word in it, a flex or grid container, the letters go where the page lays them out.
       - Blitz has no font here, so each letter stands in the page as an empty box of the size Motolii draws it at, and Taffy (Blitz's layout) arranges the boxes. The pen arranges the letters among themselves; the arrangement is set about the middle of the text as Motolii laid it. A container around the text, which a pen uses to centre it on its page, is not followed.
       - **Measured against Chrome** (headless, a page 1280 × 633), each letter's own box, from the middle of all of them: the 5 pens above (all centre their text with flex), and 12 pages that each put one value listed in css-flexbox-1 or css-grid-2 on Splitting's markup (`justify-content` five ways, `gap`, `row-reverse`, `column`, wrapped letters, wrapped words, two grids). The 12 pages were written here. No public pen that lays split letters out with flex or grid was found: CodePen refuses automated fetching (403), and of 14 public GitHub stylesheets that use Splitting.js beside flex, none puts it on the letters. Chrome is the outside judge.
       - 122 of 209 letters were off by more than 0.5 px at first, then 25, then none; the worst is 0.05 px. Three causes: Blitz rounds a run of inline boxes up to a whole device pixel (the page is now 32 device pixels to the CSS pixel, and the boxes are whole device pixels); a box on the baseline made its line taller by what a font keeps below it (the boxes hang from the top of the line); a space that is a flex item has no width in a browser (the page is made again with no width for its spaces).
       - **Drawn by the engine:** a text FLEXBOX with `justify-content: space-between; width: 900px` is 893 px wide on the still. With `gap` animated from 0 to 60 px over 2 s it is 269, 449 and 629 px wide at 0, 1 and 2 s: six gaps of 0, 30 and 60 px.
       - One CSS pixel is now one project pixel at any size of the layer. Before, it was one only at size 1: the letters are laid at size 1 and scaled afterwards, so `width: 900px` on a text of size 0.08 was 72 px.
       - Three of Chrome's cases are tests in `css.rs` ([TESTING.md](../TESTING.md)); the pages, the Chrome measurements and the check are in `docs/internal/css_flex/`, which git ignores.
       - **With other code on the same layer:** the flex CSS, the shelf's `slide_in.js` (a delay from letter to letter) and the shelf's Comet Tails effect (it keeps the frames before) were put on one text layer and exported as a film. The letters arrive one after another at the places flex gives them and leave trails: 3,759 pixels of the text's band are lit at 0.3 s, against 1,936 without the effect. Before, a `.css` file followed by another file in a layer's list was read as one path, so the CSS was lost when it came first (`script_files`, now with a test).
       - **Not yet:** letters left in a line that wraps by a CSS `width` alone, with no flex or grid; a space at the end of a wrapped line (ours keeps its width there). The older check of transforms in `docs/internal/css_letters/check` no longer matches the adapter's markup: it reports 46 of 279 off both before and after this change.
     - **Not yet:** with no text layer selected, the paste is refused. A new text needs a font, and only the app knows its default font. The shelf lists only `.js` as expressions. Only a pen's first `[data-splitting]` element is used. A pasted HTML panel is not taken in. The `perspective` property of a parent is not applied.
8. **ASS:** the picture is reached as it is (5.4). How large is the libass patch that hands out per-glyph values, and is it wanted before someone asks to put code on a karaoke letter?
9. **Animated SVG:** can an SVG that moves by CSS `@keyframes` (loaders such as svg-spinners, exports) play in Motolii as Chrome plays it, the SVG's text untouched? **Answered 2026-11-11, tried:** yes, by the same Blitz and Stylo as Q7. ThorVG runs no CSS animation, so each frame the SVG is written again with what Stylo computes for each element in its attributes, and ThorVG draws that still SVG.
   - **Measured on outside material:** the 46 CSS spinners of github.com/n3r4zzurr0/svg-spinners (MIT) on one page. Every animated property (transform, opacity, r, cx, cy, x, y, width, height, rx, ry, stroke-dasharray, stroke-dashoffset) of all 177 elements was read at 0.3, 0.9 and 1.7 s. Blitz was compared with Chrome's `getComputedStyle`, animations paused there.
   - **Three causes, found in that order:** 545 of 639 element-values agreed at first, then 633, 637 and 639.
     - Blitz maps no SVG presentation attribute (`cx="4"`) into CSS. A keyframe list with no 0% starts from the attribute. They are now put in, as SVG2 §6.6 says: author-level rules of specificity 0 before every other author style sheet (`:where()`).
     - The `transform` attribute has its own grammar (unitless numbers, `rotate(a cx cy)`). svgtypes, resvg's parser, reads it into the same CSS functions.
     - Stylo kept the ending iteration on the exact boundary. Motolii's 1/60 s frames land on it every loop of a 0.75 s spinner. It is now patched to Web Animations §4.8.4 within Chromium's one microsecond (`engine/deps/patches/stylo/stylo_iteration_boundary.patch`). The Q7 letters stay 279 of 279.
   - **Written back:** each element's transform, made with its origin against the view box, agreed with Chrome's own (the parent's `getCTM()` inverse times the element's) on 501 of 501.
   - **Drawn by the engine:** an image layer of `3-dots-bounce.svg` and of `180-ring.svg`, stills at 0.3, 0.9 and 1.7 s. Each was compared with Chrome's picture of the same time: IoU of the drawn pixels was 0.955 to 0.981. Motolii's 0.3 s against Chrome's 0.9 s gave 0.064 and 0.410.
   - **Pasted (the same day):** SVG text, beginning with `<svg` or an XML declaration, is the form `svg` (`adapter_form`), told before CSS: until then a spinner with `@keyframes` was taken for a pen's CSS and refused. ⌘V keeps it in the Program shelf as a `.svg` file, byte for byte, and adds an image layer of it. The still of a pasted 3-dots-bounce at 0.3 s agreed with Chrome's at IoU 0.981.
   - **SMIL (`<animate>`, `<animateTransform>`), looked into the same day: not reached, for want of an engine outside the browsers.** 24 of svg-spinners' 46 SMIL files chain their animations (`begin="a.end"`, `begin="a.begin+0.2s"`), so SMIL's timing (syncbase) is needed, not only its values.
     - anim_svg (github.com/robotoss/anim_svg, MIT, SVG to Lottie in Rust): no `begin` at all; its README lists explicit begin and end offsets as unsupported.
     - smil2css (github.com/webframes/smil2css, MIT, last change 2015): converts only frame-by-frame animation.
     - svg-rs (ginokent): no licence stated.
     - Ladybird (LibWeb/SVG, BSD-2) runs SMIL as Web Animations (`SMILAnimation` is an `Animations::Animation`), the way to watch. It was written in 2026, and syncbase is still a FIXME (`SVGAnimationElement.cpp`, `begin_time_from_begin_attribute`).
     - Turning SMIL into CSS keyframes for Stylo would be Motolii's own translation of the posted code (rule 1), so it is not done. svg-spinners has a CSS file for each SMIL one, which plays now.
   - **Not yet:** A spinner's frames are drawn for ten minutes at 60 a second, as a sketch's; a jump back replays the CSS from 0.
   - The page, the probe and the Chrome measurements are in `docs/internal/svg_anim/`, which git ignores.

10. **A shelf file opened to be read:** how it looks while it is only being read, beside the person's own code (3.11).

Decided in the conversation: there are no closed packs; code on a layer is told apart by what it returns, and a layer has one list (4.1); the Program tab is the way in for every written expression, and a row (copies, letters, the layers of a group, data rows) is one thing to code (section 5); renaming a layer rewrites names in code (with Undo); a pick whip is wanted; a reason is shown when code cannot be made fast.

Decided in the later conversation of 2026-11-11: the five rules at the head of section 3; the Program tab holds only the code, and the lists are panels beside it (4.3); an LLM is given an intent with picked layers and turns timing and choices into sliders (3.8); code on a group is what a relation is (3.9); cards act in order (3.10); a card is saved to a shelf with its sliders and keyframes, its layers left empty, and is separate from then on (3.11).

## 10. Relation to earlier notes

[create_and_program_shelves.md](create_and_program_shelves.md) (9 November) says an After Effects expression lives only in the layer's detail panel and is not shown in the Program tab. This note proposes that the Inspector card stays the place for light use and that **Edit opens any code in the Program tab**. If this ideal is accepted, that line of the earlier note is to be revised. The names in that note ("Expression", the Create shelf) are not changed here.

The same note says the Program tab holds closed packs only (p5.js, whole Cavalry scripts). There are no closed packs (4.1), and the Program tab is the editor for everything: text motion, CSS, subtitles and group layers come in through it (section 5). That note's split between Create and Program is dropped, and its table of recipes (which side each is on) no longer applies.

## 11. Beyond After Effects: taking the walls down

*An ideal, added 2026-11-11 from a conversation with the author. Nothing in this section is reached unless it says so.*

Section 1 asks that posted code works. This section asks how far an expression can go once the walls of After Effects' expressions are gone.

| Wall in After Effects | Taken down |
|---|---|
| An expression returns a value only | It may return a picture, a shape, text or a set of layers (the three rows of 4.1) |
| Few things can be read | Sound, MIDI, CSV and JSON, other code's output, and the pixels of any layer (After Effects has only `sampleImage`) |
| One property, alone | It sees every sibling and answers for all at once (`relate()`; layout; collisions; flocks) |
| No state | A simulation is an expression; its state is saved at intervals so time can be jumped (Blender's point cache is the model) |
| One language | Any language, meeting through values (section 5.3) |
| Poor reuse | A part is a file on a shelf; its sliders are made from the file |
| Invisible and slow | A tree of what reads what (4.4), cost shown (6.4), bulk work on the GPU (section 7) |

The picture behind it is a spreadsheet: every property is a cell, an expression is its formula, and a formula that returns a range makes layers appear, as a spreadsheet's dynamic array spills (5.2, "a row is a row").

Three things to build first, in this order, each a door like `layerValue` that every language gets at once:

1. **Pixels.** After Effects' own `sampleImage(point, radius, postEffect, time)` returns the colour of another layer; take its name and arguments so posted expressions run. First demonstration: letters over a video, each reading the brightness under it and moving away from dark areas.
2. **Sound.** Bands and level as readable names.
3. **Structure.** An expression that returns a range; rows of a CSV become layers.

Then state with a cache, and the round trip between an expression and keyframes by curve fitting (a hand-made fix then lies on top of the code's motion as a correction).

Fixed from the start: the same input gives the same output (an export must not change between runs); nothing is read from the network, only local files; the cost of an expression is always shown.

## 12. From a recording to code that stays editable

*An ideal, added 2026-11-11 from a conversation with the author. Nothing in this section is reached unless it says so.*

Until now, motion written as code could come into After Effects only as a screen recording. A recording brings the picture and leaves behind the code that makes it. This section says what is gained when the code itself comes in and stays editable, and how far that can go.

### 12.1 What a recording loses

| | A recording | The code itself |
|---|---|---|
| Size and frame rate | fixed when it was recorded | drawn again at the size and rate of each export |
| Transparency | none; a black background has to be keyed out | there from the start |
| A change afterwards | record again | edit the code, or drag a number in it as a slider (3.4) |
| Length and loop | the length that was recorded | any length |
| Timing with sound and cuts | lined up by hand | driven by keyframes or by sound |
| Other layers | it lies on top of them | it reads them, and they read it |

### 12.2 Five steps up from a recording

| Step | What the user can do | Today | Where it is described |
|---|---|---|---|
| 1 | Paste code and it is a layer. Time belongs to the timeline (scrub, reverse, time remap). Blending modes, masks, track mattes and effects apply as to any layer. | Partly. Pasted CSS, SVG, subtitles and sketches become layers (5.3, 5.4, questions 7 and 9). A pen's flex or grid lays out the letters of a text layer (question 7). | 3.2, 4.1 |
| 2 | Touch what the code drew. A circle that a sketch drew is picked on the stage and dragged, and the code changes. A timing in the code is a keyframe on the timeline. A colour is a swatch. An ease is a curve in the graph editor. | Not reached. | 3.4 for numbers; the rest is new here |
| 3 | Take only the motion and put it on your own material: the bounce of a CodePen on your own text layer, the scatter of a sketch's particles on the pieces of your own photo. | Reached where the code returns values: an `each()` or `relate()` file goes on any layer or group (5.2), and a pen's CSS on any text layer (question 7). Not reached where the code draws. | 3.9, 3.11, 5.2 |
| 4 | Mix languages on one layer: a CSS selector picks every third letter, an After Effects expression moves them, a shader paints them. | Not checked. | 5.3 |
| 5 | The project goes out as text and comes back. Another person or an LLM continues it. A video that has no code is shown to an LLM, which writes code for it. | Not reached. | 3.8, section 11 |

**Step 3 is the centre.** The aim is "usable in your video". What a person wants is rarely the demo itself. It is that motion on their own logo. Step 1 puts someone else's demo in your video; step 3 makes someone else's motion yours.

- Code that returns values (4.1) is at step 3 already: its values go to whatever layer or group its card is on. The CodePen bounce is this case.
- A shader is there too, because it is an effect and an effect goes on any layer.
- Code that draws its own picture (a p5.js sketch) is not. Its motion is inside the drawing, so it can be taken out only once the drawn shapes can be reached, which is step 2. The sketch's particles are this case.

**Step 2 without translating.** Reading the code and writing it again in another form is translation (principle 1). So what the code drew is taken from running it, not from reading it. A p5.js sketch already reaches the engine this way: each frame the engine receives the shapes, triangles, lines and points the sketch drew ([sketch_import_test_record.md](sketch_import_test_record.md)). What the engine does not know yet is which line of the sketch drew which shape, and it needs that to change the code when a shape is dragged. Some posted code will not allow it, for example a shape whose place comes out of a long calculation. Such code stays an ordinary layer, as in step 1. It still runs.

**Code written by an LLM from a video** is the LLM's guess. It is credited as that, not to the video's author.

### 12.3 Any language; each shared name has one implementation

A language is only a way of writing (5.3), so the language a person or an LLM writes in does not matter. What the languages share is a small set of names: time, the copy number, a layer's properties, `sampleImage`, the level of a sound, and easing. Each of them is implemented once, in Motolii. However a language writes it (`ease(...)` in an After Effects expression, `cubic-bezier(...)` in CSS), the same implementation answers.

Easing is the example.

- After Effects' `ease` and CSS's `cubic-bezier()` bring control points, which are data. One solver computes the curve: `interp_bezier` in [easing_curves.h](../../engine/motion/easing_curves.h).
- Before, the adapter for After Effects expressions computed its own easing in JavaScript, and ThorVG's expression runtime has a third. They did not agree: the adapter's `easeIn(0.5)` gave 0.125, and the one solver with lottie-web's control points gives 0.363 (commit 8516d84f2).
- **Reached:** After Effects' `ease`, `easeIn` and `easeOut` are three sets of control points on that solver (the same commit).
- **Not yet:** Stylo, the CSS engine of 5.4, still solves CSS curves with its own solver (question 7).
- **`sampleImage`:** its arithmetic over a still picture is in the engine (commit c1db919c6), the first piece of section 11's pixels.
- Posted code that carries its own easing inside it (anime.js code, a Lottie file) keeps it. That is the code as written.

So making another tool's code run means bringing its names and its control points. It never means bringing a second solver.

### 12.4 Between the code and the GPU: TSL itself

This answers question 1 of section 9.

To run on the GPU, code has to be turned into a shader. Section 7 does it through a graph of nodes. TSL (three.js Shading Language) is three.js's way of building such a graph from JavaScript.

- **Not a graph format of Motolii's own that resembles TSL.** With a format of our own, the step from each language into it would have to be written here, language by language. That is translation (principle 1), and all of it would be ours to maintain.
- **TSL as three.js ships it.** Posted code is run once in QuickJS (the JavaScript engine Motolii already runs expressions in), with TSL nodes where the numbers would be. three.js's own `WGSLNodeBuilder` turns the resulting graph into WGSL, the shader language the GPU takes (section 7). A probe outside the engine got 24 of the shelf's 25 `each()` files through (appendix). It is not wired into the engine.
- **The reads that section 7 adds** (another property, an earlier time, the copy number) go in as TSL's own input nodes. The probe did this for the copy number, time, the copy's place and the sliders. Reading another layer or an earlier time was not in the probe.
- **A value and a picture are the same thing there.** A formula for a position and a formula for a pixel's colour are both graphs. The same graph can run on the CPU for one layer and on the GPU for 10,000 copies.
- **It is a faster way to run code that already runs. It is never a condition for running** (6.3). Code that does not become a graph (a simulation that keeps state, a sketch that walks an array) runs as written. If the graph became a condition, each new expression would wait for a developer, which is what the aim forbids.
- **Not every language passes through it.** CSS selectors, layout and delays are worked out by Stylo, which hands over values. The timing of subtitles is worked out by libass, the subtitle renderer, which hands over a picture today (5.4). What every language shares is the names of 12.3, not the graph.

### 12.5 How progress is counted

- **By works from the net, pasted unchanged.** The measure is how many public works (CodePen, Shadertoy, OpenProcessing) look in Motolii as they look where they were published. The picture to compare with is taken from the original running there, as questions 7 and 9 did with Chrome. Files written here in order to be tested do not count.
- **The works that fail are the list of what to do next.** The count will be low at first, and it is shown as it is.
- **Each step is shown first as one thing a user can see,** from paste to export: for example the letters that move away from the dark areas of a video (section 11).
- **Motolii writes only the adapter for a language.** An adapter hands the code what it may read and takes what the code gives back. The engine that already exists for that language runs it: QuickJS for JavaScript, Stylo for CSS, libass for subtitles. An adapter should be small enough for someone outside the project to write one. Its test is the gallery of examples published for that language or library (p5.js's, three.js's), unchanged.

### 12.6 Open

1. **Easing on the GPU.** Run as written, code calls the one solver of 12.3. Turned into a graph, it must give the same curve, or the graph is not used (6.3). A second solver written in the shader would be a second implementation. The proposal is to compute the curve once with the one solver and hand it to the GPU as a table (6.2, "Simple forms"). Not decided.
2. **CPU or GPU.** Where the line falls between running a graph on the CPU and on the GPU.
3. **Step 2.** How a drawn shape is tied to the line of code that drew it without rewriting the code, and whether the way found for p5.js also serves three.js.
4. **Code that needs a whole web page.** No web page is embedded (principle 3), so such code is not brought in whole. This is the part of "any code" that is furthest away.
5. **The project as text (step 5).** A project is a SQLite database file today. What its text form is has not been looked at.

### 12.7 Four strengths in one chain (tried 2026-11-11)

The author's picture of what coexisting code is for: each engine does what it is best at, on the same material, one after another.

**The ideal: nothing is converted.** A text stays a text. A letter is one thing with four settings, and a layer is never made to stand for another.

| Setting | Decided by | In After Effects |
|---|---|---|
| Where it is put | CSS: flex and grid | not there |
| When it comes | A delay from letter to letter | `index * delay` in an expression |
| How it is drawn | Fill, stroke or points | A shape's fill and stroke; points are not there |
| What stays behind | An echo | Echo |

"How it is drawn" is a property of the layer. With a stroke, trim paths work; with points, points lie along the outlines. Typing the text again keeps all four. After Effects has Create Shapes from Text because text and shapes are two worlds there. That is its wall, not a feature to copy.

**Where the cut was wrong.** A text is drawn as a picture: one image, and a split letter is a strip of it as wide as the letter. So a letter has no path and no points of its own, and each wish for them needs a conversion. The ideal is the other way round: a letter is drawn from its outline from the start, so a text is a shape whose path comes from the font. Then the trim, the stroke and the path operators that shapes have act on letters, a split is the outlines taken letter by letter, and points are one more way to draw an outline. The code that measures where each strip lies would go.

| Part | Whose it is |
|---|---|
| The letters' outlines | The font, read by ThorVG |
| The layout | The CSS engine (Blitz) |
| Stroke, trim, path operators | ThorVG |
| Points, 3D, the final picture | Filament |
| Motolii | Handing one's result to the next |

**Today.**

| Setting | Today |
|---|---|
| Where it is put | Reached for the letters and words of a text layer (question 7). It acts only where the text itself, or a word, is a flex or grid container; that hidden condition is to go once letters are outlines. |
| When it comes, what stays behind | Reached on the same layer: the shelf's `slide_in.js` and Comet Tails over the flex layout (question 7). The echo is of the whole picture, not of each letter. |
| How it is drawn | Stroke only, and trim paths, reached on a text layer (the lighter road, below). Points not reached. |

**What was tried and taken out the same day.** `outline` on a text layer made a path shape of its letters above the text and hid the text, as Create Shapes from Text does (commit 647f5159e). It worked: the shape lay exactly where the text did, and trim paths drew the letters on. It was taken out because it is a conversion: the same letters were held twice, and typing the text again left the shape as it was. Letters apart and points would each have been one more copy.

**What is kept from it.** `tvg_text_outline` hands out the outlines ThorVG keeps inside a text (`tvgText.h`, `TextImpl`), as the adapter already reaches ThorVG's own path operators. Nothing reads the font here. It was checked against the font's own outlines as fontTools reads the same file: the 9 contours of MOTOLII and the 23 of "Wavy Type & go 258" in Roboto-Medium, each contour's width, height, area and place across as fractions of the whole text, worst difference 0.0001 (0.108 on a wrong text). One case is a test, `text_outline_test.cpp`. Nothing in the engine calls the function yet.

**Read and measured before building (the same day).** Two things could have refuted the cut: what only a text can do today, and speed. Neither did. Nothing was added to the engine for this.

*What a text can do today, set beside what a shape can* (read by an agent that knew nothing of this plan, from `canvas_type.cpp`, `match_shape.cpp`, `kinds.h` and ThorVG's `tvgSfntLoader.cpp`):

| | What | Drawn as a shape |
|---|---|---|
| Carries over | Fill, one stroke, fill "behind", copies | Shapes have them |
| Carries over | Letter and line spacing, wrapping, alignment, italics, vertical writing | Already in the outlines ThorVG hands out: it moves the points (italics through the shape's transform, which `tvg_text_outline` applies) |
| Gained | Dashes, caps and joins, trim paths, round, bloat, zigzag, morph, rough, a picture as fill, the even-odd rule | Shapes have them and texts do not |
| Depends on the route | A colour ramp, depth | Shapes have them, drawn as a ThorVG image, not as a mesh |
| No counterpart | The second and third strokes (rims), the bevel's step bands, changing the words in place without making the picture again | Shapes have none of the three |
| Same either way | Kerning (the `kern` table only), colour fonts (not read) | ThorVG's loader, on both sides |

The outlines carry no mark of where one letter ends: ThorVG appends each glyph's contours one after another. A split by letter therefore needs the letters asked for one at a time, or a mark added. Today's split has its own limit: it measures each strip by setting the words again up to that letter, and works on one unwrapped line only.

*Speed* (Apple M4; the outlines written from the font by fontTools as path data and said to a path shape; the shell's own times; a still of an empty project takes about 21 ms, which every figure includes):

| | A text, as today | The same letters as a path shape |
|---|---|---|
| A frame with nothing changing, 1,000 letters | as an empty project | as an empty project |
| A frame with every letter moving (the shelf's `fade_in.js`), 1,000 letters | 42.8 ms | 41.7 ms (1,000 copies of one outline) |
| Making it again after the letters change, 100 letters | about 45 ms | about 22 ms |
| Making it again after the letters change, 1,000 letters | about 49 ms | about 88 ms filled, 106 ms with a stroke and no fill |

The line set before measuring was: a still frame inside 16.7 ms, and making it again no more than twice today's. Stills cannot tell the first apart from an empty project, for either way. The second passes at 100 letters and for filled letters at 1,000 (1.8 times), and misses for stroked ones (2.2 times). The path-shape figures are an upper bound: they include reading and storing 618 KB of path data as text, which letters drawn straight from ThorVG's outlines would not pass through. A thousand moving letters cost 21 ms a frame over the floor either way; that is the copies and the expression, not strips against meshes.

**What this leaves.** The cut stands. Three things have to be dealt with, not lost: rims and the bevel's bands have no counterpart on shapes, and the words changed in place are a speed path of the picture. And one comment is wrong: `match_shape.cpp` says a shape with an edge, a dash, a trim or a bend is drawn as a ThorVG image, but the test under it (`plain`) asks only about depth, a wave, a spiral, a picture fill and a ramp, so those are drawn as meshes today.

**A lighter road, taken first (the same day).** Before drawing texts another way, the lightest form was looked for, and it was already there. ThorVG's Text holds the shape it draws the letters from, and the engine already trims a canvas's shape each frame (`trim_at`). So a text's canvas names that shape (`tvg_text_shape`), a text takes `trim`, `trim_begin`, `trim_offset` and the fill `none`, and ThorVG is told when the shape changed, as its own `Text::outline` tells it (`tvg_text_shape_changed`). The text stays a picture and stays a text: about twenty lines.

- **Before:** `say 1 fill none` and `key 1 trim` were refused on a text, and the picture was the same at every moment.
- **Drawn by the engine:** MOTOLII, no fill, a white stroke, its trim keyed from 1 to 0 over 2 s: nothing at 0 s, then 25, 45, 73 and 100 % of its stroke lit at 0.5, 1, 1.5 and 2 s. The removed conversion, which drew the same outlines as a mesh, gave 25, 44, 72 and 100 %. The words typed again keep the stroke and the trim. There is one layer throughout.
- A filled text is trimmed too, and so is a text split into letters. The second and third strokes are texts of their own under the first and are not trimmed.
- `drawings_unchanged.sh` against the commit before matched every picture, and the cards' tests pass with Trim Paths now offered to a text.

So a text need not be drawn as a shape for a stroke and a trim. That cut is still what points along the letters, and letters as meshes, would need; the reading and the measurements above are for that day. `tvg_text_outline` still has no caller.

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
