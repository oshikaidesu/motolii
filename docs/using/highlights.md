# What sets Motolii apart

[日本語](highlights.ja.md)

Motolii is an open-source video editor for music videos and motion graphics. Its aim is that a look you found on the net works in your own video at once, without waiting for someone to write a plugin.

This page lists what Motolii does today that is hard to get elsewhere, and where each one stops. The comparison with other editors is in [the guide](guide.md#how-it-compares). What is not ready is in [Before you start](#before-you-start).

## Put a shader file in a folder and use it

An ISF (`.fs`) or WGSL (`.wgsl`) file put in the effects folder appears in the Effects list without restarting the app, with a moving picture of its own on its tile. There is nothing to install and nothing to convert.

The shelf already holds 420 `.fs` and 266 `.wgsl` files. How to add your own: [shelves/README.md](../../shelves/README.md).

Where it stops: ISF is an open format that VJ tools read too. What is new here is that it sits inside an editor with a timeline and MP4 export. Not every file in a supported format runs correctly.

## Every effect is a file

Blur, Drop Shadow, Duotone and Gradient Map are shelf files like any other; nothing in the effects list is built into the app. A file you drop in is on the same footing as they are, and you can open any of them to see how it is made and copy it.

## Paste code from creative-coding sites and it becomes a layer

Paste a sketch and Motolii works out which site's code it is. It reads Shadertoy, GLSL Sandbox, Hydra, three.js, Two.js, Turtletoy, Paper.js, canvas, Bonzomatic, twigl, Dwitter and tixy, and treats anything else as p5.js. p5.js runs without a browser, and the code stays editable on the layer.

For p5.js, each drawing line also gets a strength slider from 0 to 1, which you can keyframe.

Where it stops: a pasted work may run wrong, or not at all. The counts we took, and the known bug, are in [the specifications](specifications.md#supported-formats-and-how-they-run). Many of the works in the shelf are under non-commercial licences; check the licence of what you publish.

## AviUtl2 scripts on a Mac

AviUtl2 is a Windows-only editor with a large body of community scripts. Motolii runs its Lua and HLSL scripts as they are, converting the HLSL to WGSL. The shelf has over 170 packages.

Where it stops: scripts that need a Windows DLL do not run, and not every other script runs correctly. The count of those that do is in [the specifications](specifications.md#supported-formats-and-how-they-run).

## Relations: one script moves a whole group of layers

Pick a group, or select several layers, and press a relation's tile under Expression in the Create tab. A relation is a short script that sees all the selected layers at once and moves them together. Around, Row, Follow, Push and Move in are files on the shelf like the nine others. A script can also call the `d3-force` physics-style forces (collision, attraction) and read what it did on the last frame.

Where it stops: this is scripting, not node wiring. If you want to connect two properties by dragging, Motolii does not have that.

## A map of effects arranged by how they look

Switch the Effects shelf to its map view and similar effects sit near each other. Press one to list its nearest neighbours. The Fonts shelf has the same map for typefaces.

Where it stops: the layout uses an image model that is not shipped with the app. Run `engine/deps/likeness_models.py` once to fetch it; until then the map falls back to a rougher likeness by colour.

## Also

- The Colors shelf can take a palette from a photo.
- Easing cards stack like a modifier stack and are saved as one expression.
- Skins: a folder of theme files changes the app's colours, sizes and controls. Six come with the app.

## Before you start

- **Tried only on a Mac with Apple silicon** (an M4, macOS 15.5). Windows and Linux have not been tried yet.
- **No packaged app.** You build from source (Xcode, Homebrew and Flutter; about 10 GB and 1 to 2 hours from nothing). A build runs only on the Mac that made it. Steps: [README](../../README.md#build-and-run).
- **In development.** There is no release yet. Presets cannot be saved, and MIDI sound is not supported.
- **Licences.** Motolii's own code is Apache-2.0 or MIT. Bundled works keep their authors' licences: [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md).

## Next

- A tour of the screen: [screen_tour.md](screen_tour.md)
- Everything in one place: [guide.md](guide.md)
