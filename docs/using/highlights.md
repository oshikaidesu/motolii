# What sets Motolii apart

[日本語](highlights.ja.md)

Motolii is an open-source video editor for music videos and motion graphics. Its aim is that a look you found on the net works in your own video at once, without waiting for someone to write a plugin.

This page lists what Motolii does today that is hard to get elsewhere, and where each one stops. The comparison with other editors is in [the guide](guide.md#how-it-compares). What is not ready is in [Before you start](#before-you-start).

## Ask an AI, and it writes the layer's expressions and effects

Pick a layer and ask, in your own words, in the Agent panel. The agent writes that layer's After Effects expressions and ISF effects, and the picture changes the moment it saves. Anything new comes as a new card; code already there is changed only when you ask for it. The agent is handed the selected layer's Inspector cards and their values now, each card's code, and the After Effects reference.

It works with any agent in the ACP (Agent Client Protocol) registry — the same list Zed and JetBrains read. Every agent works the same way, and you can choose its model, effort and mode.

Where it stops: the agent is a separate program (started with `npx`, `uvx` and the like) and may need you to sign in the first time. What it writes does not always run correctly on the first try.

## Put a shader file in a folder and use it

An ISF (`.fs`) or WGSL (`.wgsl`) file put in the effects folder appears in the Effects list without restarting the app, with a moving picture of its own on its tile. There is nothing to install and nothing to convert.

The shelf already holds 420 `.fs` and 273 `.wgsl` files. How to add your own: [shelves/README.md](../../shelves/README.md).

Where it stops: ISF is an open format that VJ tools read too. What is new here is that it sits inside an editor with a timeline and MP4 export. Not every file in a supported format runs correctly.

## Every effect is a file

Blur, Drop Shadow, Duotone and Gradient Map are shelf files like any other; nothing in the effects list is built into the app. A file you drop in is on the same footing as they are, and you can open any of them to see how it is made and copy it.

## Paste code from creative-coding sites and it becomes a layer

Paste a sketch and Motolii works out which site's code it is. It reads Shadertoy, GLSL Sandbox, Hydra, three.js, Two.js, Turtletoy, Paper.js, canvas, Bonzomatic, twigl, Dwitter and tixy, and treats anything else as p5.js. p5.js runs without a browser, and the code stays editable on the layer.

For p5.js, each drawing line also gets a strength slider from 0 to 1, which you can keyframe.

Where it stops: a pasted work may run wrong, or not at all. The counts we took, and the known bug, are in [the specifications](specifications.md#supported-formats-and-how-they-run). Many of the works in the shelf are under non-commercial licences; check the licence of what you publish.

## AviUtl2 scripts on a Mac

AviUtl2 is a Windows-only editor with a large body of community scripts. Motolii runs its Lua and HLSL scripts as they are, converting the HLSL to WGSL. The shelf has 180 packages.

Where it stops: scripts that need a Windows DLL do not run, and not every other script runs correctly. The count of those that do is in [the specifications](specifications.md#supported-formats-and-how-they-run).

## Expression cards: an expression or a whole-group move, the same card

Paste an After Effects expression (`wiggle(2, 50)`, `thisComp…`) and it attaches to the layer as one card, with its handles in the Inspector. A first line `// --property:position` (or `rotation`, `scale`, `opacity`) says which value it drives.

The same expression family also writes `each`, which moves copies or letters one at a time, and `relate` and `force`, which move several layers together. For a group move, pick a group or select several layers and press the tile: the script sees all the selected layers at once, can call the `d3-force` physics-style forces (collision, attraction) and read what it did on the last frame. The shelf holds 21 expressions and 17 group moves (Around, Follow, Row, Push, Move in and more).

You can also have the AI in the Agent panel above write any of this code.

Where it stops: this is scripting, not node wiring. If you want to connect two properties by dragging, Motolii does not have that.

## Easing attaches to a span, and cards stack

An easing is a card on the span between two keyframes. Click the span's line in the Timeline to select it and swap the curve. It is never baked into the keyframes themselves, so you can keep changing it after it is applied — none of the usual problem where applying a preset stamps keyframes that are then awkward to edit.

Cards stack like a modifier stack (through, times, plus). A stacked curve is evaluated exactly rather than frozen, and the stack is saved as one expression.

## A map of effects arranged by how they look

Switch the Effects shelf to its map view and similar effects sit near each other. Press one to list its nearest neighbours. The Fonts shelf has the same map for typefaces.

Where it stops: the layout uses an image model that is not shipped with the app. Run `engine/deps/likeness_models.py` once to fetch it; until then the map falls back to a rougher likeness by colour.

## Every effect tile is a moving thumbnail

A tile in the effects shelf is a small moving preview of the effect itself. The app puts each effect on, takes sixteen pictures, picks the parameter that shows the effect best and moves it, and even judges whether the effect did something. So you can read the shelf and see what an effect does, which its name alone does not tell you.

This measure of which parameter matters most is also used for the colours in the Inspector (below).

## Group layers hold layers, nested

Layers go into groups, and a group can hold other groups. Open and close it with the triangle in the Timeline: closed it is one row, open its layers sit under it (as in Apple Motion). A group's own keyframes follow that one row.

## Inspector values are cards, and the parameters that matter are tinted

The values in the Inspector are drawn as the same cards as the effects you place. Each parameter keeps its name, its control and a small preview in one block, so nothing stretches down the panel as a label on its own line or an empty row. A colour folds its three numbers into one colour on one card, instead of a white taking three number fields.

Each parameter carries a weight for how much it moves the result (the same weight as the thumbnails above), and the ones that matter more are tinted more. The tint is a step of that strength, not a yes or no, so importance reads as a gradation of colour.

## Also

- The Colors shelf can take a palette from a photo.
- Skins: a folder of theme files changes the app's colours, sizes and controls. Six come with the app.

## Before you start

- **Tried only on a Mac with Apple silicon** (an M4, macOS 15.5). Windows and Linux have not been tried yet.
- **No packaged app.** You build from source (Xcode, Homebrew and Flutter; about 10 GB and 1 to 2 hours from nothing). A build runs only on the Mac that made it. Steps: [README](../../README.md#build-and-run).
- **In development.** There is no release yet. Presets cannot be saved, and MIDI sound is not supported.
- **Licences.** Motolii's own code is Apache-2.0 or MIT. Bundled works keep their authors' licences: [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md).

## Next

- A tour of the screen: [screen_tour.md](screen_tour.md)
- Everything in one place: [guide.md](guide.md)
