# Specifications

[日本語](specifications.ja.md)

What Motolii runs and what it needs: the system, the formats it reads with the counts we took, what it writes out, and how fast it is. What it lets you do is in [What sets Motolii apart](highlights.md) and [the guide](guide.md).

## Requirements

Motolii is still in development and has been tried only on a Mac with Apple silicon (an M4, macOS 15.5). Windows and Linux have not been tried yet.

There is no packaged app yet, so trying it means building it from source.

A Windows version is planned. The main parts, such as Filament, ThorVG, GStreamer and Flutter, support Windows, and only a small share of the code, such as handing over video and the picture on screen, is tied directly to the Mac. It has not been built or tested on Windows yet.

How each format runs, known bugs and the build steps are below.

## Supported formats and how they run

| Format | What was checked |
|---|---|
| ISF | 318 of 327 |
| Shadertoy | 261 of 300 drew and moved |
| p5.js | 97 of 168 drew a picture |
| AviUtl2 | 372 of 594 ran to the end |

Each was checked at a different time under different conditions. A p5.js work that draws may not match the original. The detailed conditions and limits are in the [test record](../design/sketch_import_test_record.md) (Japanese).

### Each format in detail

| You can | With | State |
|---|---|---|
| Apply effects shared for VJ software | ISF (`.fs`, from [ISF-Files](https://github.com/Vidvox/ISF-Files) and others) | Drop one into the effects folder and it appears in the list. 318 of ISF-Files' 327 run (the check that counted them was removed). 419 bundled |
| Apply WebGPU shaders | WGSL (`.wgsl`, including screen effects ported from three.js and others) | Applied to the whole scene. 266 bundled |
| Paste a p5.js sketch | p5.js (copy the code, press ⌘V in the app) | It becomes a layer and stays in the Program tab. You can keyframe it and change its speed with Time Remap. Of 168 works from OpenProcessing, 97 drew a picture (counted on 1 November; checked by eye, about 16 of the first 42 looked like the original) |
| Paste a Shadertoy shader | GLSL (copy the code, press ⌘V in the app) | A shader that draws by itself becomes a layer; one that reads `iChannel` is applied to the selected layer. Either way it stays in the Program tab. Of 300 picked at random from an API dump of 36,668, 261 drew and moved (counted in early November 2026). Of the 30 black ones, 26 wait for input such as a mouse; 9 failed to load. Time Remap is p5.js only so far |
| Use scripts made for AviUtl2, a Japanese video editor | `.anm2`, `.obj2` (their HLSL converted to WGSL) | 172 packages bundled. Counted on 26 October: 372 of the 594 scripts bundled then ran to the end ([`docs/design/aviutl2_catalogue.md`](../design/aviutl2_catalogue.md)). Scripts that need a Windows DLL don't run yet |
| Use looks written in TSL (three.js's shading language) | three.js's own compiler to WGSL | 19 from [Shader Lab](https://github.com/basementstudio/shader-lab) are in the effects list; the rest are converted to WGSL only |
| Place video, photos, text, shapes, 3D models and point clouds | Video (GStreamer), text and shapes (ThorVG), glTF and `.ply` (Filament) | Works |
| Place After Effects animations | Lottie `.json` (ThorVG) | Works |
| Animate from MIDI | MIDI (`.mid`): a piano roll, or keyframes on values at each note | Works; MIDI isn't heard yet (a video's sound is) |
| Make shapes, or give a layer an in/out animation | Your own scripts (`.js`) | Drop one in and it appears in the list. 101 recipes (ready-made animated pieces) and 13 in/out animations bundled |
| Move many layers together (line up, follow, flock, spring, collide) | Relation scripts (`.js`) | Drop one into `relations/` and it appears in the Relations tab. 14 bundled |

A work's rights stay with its author. Many works on Shadertoy and OpenProcessing carry a non-commercial licence, so ask the author before using one in paid work.

Also: keyframes and easing (anime.js eases work as they are), refracting glass, a camera (focal length, aperture, focus) and MP4 export.

**Build check**: on a GitHub Apple silicon Mac (macos-15) it is built fresh exactly as this guide says, then the UI's analyzer (`flutter analyze`) runs (the build badge on the [README](../../README.md)). The app's tests and the format and analyzer checks run on every push (the checks badge); how to run them yourself is in [`docs/TESTING.md`](../TESTING.md).

**Speed** (M4, the 8-second example above, 1080×1920): about 4 ms a frame, no frame dropped even at 240 frames a second. Exporting the 8 seconds takes about 5 seconds, ffmpeg's encoding included. To measure again, make the example, then `printf 'time 240\n' | engine/edit.sh ~/Movies/Motolii/mv.motolii`.

## Export

| Output | Format | State |
|---|---|---|
| Video | MP4, H.264 + AAC | The encoder is the first of Apple's, NVIDIA's, Intel's, AMD's, Windows Media Foundation's, VA-API, OpenH264 and x264 that the FFmpeg on the system lists. On the Mac that is Apple's, and the 1080×1920, 480-frame example exports as before. Quality was measured (VMAF) for Apple's and x264 only; the others get a plain bit rate and were not run. With no H.264 encoder listed, export stops with a message |
| Video with transparency | `.mov`, ProRes 4444 | Chosen because other editors read it. Against the PNG sequence of the same scene (480 frames of text), colour matches at 84.4 dB and transparency at 71.5 dB. The file is large: 64.5 MB for that scene, about 85 times the former HEVC-with-alpha file. Not yet opened in QuickTime, Final Cut, Premiere or Resolve |
| Video without transparency | `.mov`, HEVC | Apple's encoder only, so Mac only |

## Parts it relies on

- **FFmpeg**: an LGPL-only build (no x264). `engine/tools/bundle_ffmpeg.sh` turns it into a 21 MB folder that runs from any directory, with the licence text and the source's URL and SHA-256 beside it. The app finds it when started from Finder, and the About panel carries FFmpeg's notice.
- **ONNX Runtime 1.31.1** (MIT), from Microsoft's own release and checked by SHA-256. It draws the effects map. The Homebrew libraries the engine reaches went from 113 to 22.
- **Not packaged yet**: the engine still loads Homebrew's GStreamer, SQLite, LuaJIT and others, so a build runs only on the Mac that made it. A Developer ID signature and notarization need the owner's Apple certificate and are not done.
- **Windows and Linux**: how each part would reach a user is written down in [`docs/engine/PACKAGING.md`](../engine/PACKAGING.md) from the projects' own documents. Nothing was run on those systems.
