# Third-party notices

Motolii に同梱した他の人の作品の、ライセンスと出所の一覧です。
作品の作者の方で、同梱のしかたの変更や削除をご希望の場合は、日本語で Issue を開いてください（[.github/CONTRIBUTING.ja.md](.github/CONTRIBUTING.ja.md)）。

Motolii exists so that you can use an expression you found on the net in your own video at once. To make that possible, it bundles works that many authors have published, and runs them as close to the author's own way as it can. Thank you to all the authors.

- Each bundled work belongs to its author and follows its author's licence. Motolii's own licence does not cover these works.
- Next to each work sit the author's licence text (`LICENSE` or similar) and where it was taken from (`SOURCE.txt` or `README.md`).
- Where a work is modified, the changes are kept apart as patches (`.patch`) applied to the original, and the original source is fetched from the author's own distribution when the engine is built (see "Fetched at build time" below).
- Works that are not stated to be free to redistribute are not bundled. Eight AviUtl2 packages, whose authors' distribution has no licence text and whose only basis was the licence listed in the catalogue, were removed from the bundle (2026-10-27).
- The Windows binaries that came in AviUtl2 packages (.mod2, .aux2, .exe, .dll, the whole of Chromium Embedded Framework) are not bundled, because Motolii runs on macOS. What was left out is listed under "left out" in each folder's `SOURCE.txt`, and can be taken from the author's distribution.
- Among the bundled works, those that are modified (for example shaders from three.js rewritten in WGSL) state the original and the changes on the first line of each file.
- **To authors**: if something in how a work is listed is wrong, please tell us in an issue. We will fix it at once, or remove the work.

## 1. Bundled works

| Work | Author and source | Licence | Where it sits |
|---|---|---|---|
| 172 AviUtl2 script packages (list below) | Each author. Collected as in the instructions of [Neosku/aviutl2-catalog-data](https://github.com/Neosku/aviutl2-catalog-data) | MIT 133, CC0 26, Unlicense 6, BSD-3-Clause 4, MIT-0 2, Apache-2.0 1 | `shelves/aviutl_scripts/<作者>__<名前>/` (each folder has LICENSE and SOURCE.txt; the folder name is author, two underscores, name) |
| ISF effects | [Vidvox/ISF-Files](https://github.com/Vidvox/ISF-Files) and others (the author is in `CREDIT` of each .fs) | MIT | `shelves/effects/*.fs`, `ISF-Files-LICENSE.txt` |
| CSS animation "Backwards" (Val Head), as its CSS panel is | [codepen.io/valhead/pen/zYvxEVX](https://codepen.io/valhead/pen/zYvxEVX); public pens are MIT ([CodePen licensing](https://blog.codepen.io/documentation/licensing/)) | MIT (Copyright (c) Val Head) | `shelves/expressions/hop_valhead.css` |
| ossia score ISF: Directional Blur, Polar Coordinates, Radial Blur | [ossia/score-user-library](https://github.com/ossia/score-user-library) | CC BY-SA 4.0 (covers only these 3 files and their modifications) | `shelves/effects/color/Directional Blur.fs`, `Polar Coordinates.fs`, `Radial Blur.fs`, `ossia-score-user-library-LICENSE.txt` |
| ossia score ISF: Luma Key (IMIMOT, ported from memo.tv) | [ossia/score-user-library](https://github.com/ossia/score-user-library) | MIT | `shelves/effects/key/Luma Key.fs`, `ossia-LICENSE-ISF.txt` |
| three.js screen effects (as WGSL) | examples/jsm/shaders of [mrdoob/three.js](https://github.com/mrdoob/three.js) | MIT | `shelves/effects/*.wgsl` (the source is on the first line of each file), `three-LICENSE.txt` |
| AbsentMotion effects (SkSL turned into WGSL with Skia's skslc) | [Comett1225/AbsentMotion](https://github.com/Comett1225/AbsentMotion) app/src/main/assets/effects, commit 0f5d891 | Apache-2.0 (Copyright 2026 The AbsentMotion authors) | `shelves/effects/am_*.wgsl` (the source and changes are on the first line of each file), `AbsentMotion-LICENSE.txt`, `AbsentMotion-NOTICE.txt` |
| Shader Lab effects (TSL turned into WGSL with three.js's converter) | [basementstudio/shader-lab](https://github.com/basementstudio/shader-lab), commit 7421a259f76e | Apache-2.0 (Copyright © 2026 basement.studio LLC) | `shelves/effects/sl_*.wgsl` (the source and changes are on the first line of each file), `ShaderLab-LICENSE.txt` |
| Geist Mono glyphs (images of the ASCII character set) | [vercel/geist-font](https://github.com/vercel/geist-font) | OFL-1.1 (Copyright (c) 2023 Vercel, in collaboration with basement.studio) | `shelves/effects/sl_ascii_*.0.png` (only images of the drawn glyphs; the font is not bundled) |
| tsl-textures materials (TSL turned into WGSL with three.js's converter) | [boytchev/tsl-textures](https://github.com/boytchev/tsl-textures), commit a7d5da1bb69a | MIT (Copyright (c) 2024 Pavel Boytchev) | `shelves/effects/tt_*.wgsl` (the source is on the first line of each file), `tsl-textures-LICENSE.txt` |
| threejs-noise-functions noise (TSL turned into WGSL with three.js's converter) | [bandinopla/threejs-noise-functions](https://github.com/bandinopla/threejs-noise-functions), commit 0122771daa36 | MIT (Copyright (c) 2026 lumiey) | `shelves/effects/nf_*.wgsl` (the source is on the first line of each file), `noise-functions-LICENSE.txt` |
| TSLFX explosions (TSL turned into WGSL with three.js's converter) | [verekia/tslfx](https://github.com/verekia/tslfx), commit 7fe666adec47 | MIT (Copyright (c) 2024 Verekia) | `shelves/effects/tf_*.wgsl` (the source is on the first line of each file), `tslfx-LICENSE.txt` |
| Sashimono Edit effects (GLSL turned into ISF) | [kagemorikosame/sashimono-edit](https://github.com/kagemorikosame/sashimono-edit) src/sashimono/effects/builtin.py, commit 761b6e4ba247 | MIT (Copyright (c) 2026 Sashimono Edit contributors) | `shelves/effects/* (Sashimono).fs` (made with `shelves/effects/sources/from_sashimono.py`), `shelves/effects/sources/sashimono-LICENSE.txt` |
| pixi-filters OutlineFilter (the outline of Multi-Border) | [pixijs/filters](https://github.com/pixijs/filters) 6.1.5, lib/outline/outline.mjs | MIT (Copyright (c) 2013-2025 Mathew Groves, Chad Engler) | `shelves/effects/stylize/Multi-Border.fs` (the ISF header gives the source and says that the uniforms became inputs), `pixi-filters-LICENSE.txt` |
| gl-chromakey ProcessChromaKey (the colour-spill removal of Key Spill Cleaner) | [bhj/gl-chromakey](https://github.com/bhj/gl-chromakey), src/lib/shaders/fragmentShaderPaint.js | MIT (Copyright (c) 2011 Mozilla Foundation, Copyright (c) 2020-2025 RadRoot LLC) | `shelves/effects/key/Key Spill Cleaner.fs` (the ISF header gives the source and says that image reads became ISF's IMG_NORM_PIXEL), `gl-chromakey-LICENSE.txt` |
| YMM4-LuaScript aviutl_rand (obj.rand and rand of AviUtl2 scripts) | [routersys/YMM4-LuaScript](https://github.com/routersys/YMM4-LuaScript), native/shim.lua and native/worker.lua, commit fd540b834bfd | MIT (Copyright (c) 2026 routersys) | `engine/community/aviutl/aviutl_fx.h` (kept as Lua, the source is in its header), `engine/third_party/ymm4-luascript/LICENSE` |
| leva knob conventions (folder(), and the step of numbers that have no range: getStep and the Number normalize) | [pmndrs/leva](https://github.com/pmndrs/leva), packages/leva/src/helpers/folder.ts, utils/math.ts and plugins/Number/number-plugin.ts, commit 402a1e9d0899 | MIT (Copyright (c) 2021 Poimandres) | `engine/community/quickjs/script_leva.h` (kept as JavaScript, the source is in its header), `engine/third_party/leva/LICENSE` |
| 13 transition effects (made into ISF by ISF-Files) | [gl-transitions](https://github.com/gl-transitions/gl-transitions) (the author is in the header of each .fs: gre, Jake Nelson, Fernando Kuteken, bobylito, Hewlett-Packard and others) | As in the header of each file: MIT 12, BSD-3-Clause 1 (Inverted Page Curl, Copyright (c) 2010 Hewlett-Packard; the copyright notice and the full licence text are in a comment in the file) | `shelves/effects/transition/Fade.fs`, `Wipe *.fs` and others; `CREDIT` has the gl-transitions URL |
| CRT finish (modified into WGSL) | post.wgsl of [vercel-labs/vgpu](https://github.com/vercel-labs/vgpu) | MIT | `shelves/effects/stylize/crt_finish.wgsl`, `vgpu-LICENSE.txt` |
| Datamosh (modified into WGSL) | [newomp4/phosphor](https://github.com/newomp4/phosphor) | MIT | `shelves/effects/glitch/datamosh.wgsl`, `phosphor-LICENSE.txt` |
| Time displacement (modified into WGSL) | [keijiro/SlitScanCam](https://github.com/keijiro/SlitScanCam) | Unlicense | `shelves/effects/glitch/time_displacement.wgsl`, `SlitScanCam-LICENSE.txt` |
| Sample photo for effects (hot-air balloon) | Wikimedia Commons "Mid-Hudson balloon festival 15" (photographed by Juliancolton) | Public domain (PD-self) | `shelves/effects/sources/fx_sample.jpg` (cropped to a square); the effect previews `shelves/effects/*.png` are this photo with the effect applied |
| Sample photo for effects (road, the destination of transitions) | Wikimedia Commons "Road through Mojave National Preserve" (NPS / Emily Hassell, Joshua Tree National Park's Flickr) | Public domain (US government work) | `shelves/effects/sources/fx_sample_end.jpg` (cropped to a square) |
| 4 point-cloud effects | scripts/esm/gsplat of [playcanvas/engine](https://github.com/playcanvas/engine) | MIT | `shelves/effects/*.mjs`, `playcanvas-LICENSE.txt` |
| three.js (parts that make shapes) | [mrdoob/three.js](https://github.com/mrdoob/three.js) r186 | MIT | `engine/third_party/js/three/` |
| d3-contour and d3-array | [d3](https://github.com/d3) | ISC | `engine/third_party/js/d3-contour/`, `d3-array/` |
| d3-force-3d, d3-octree and d3-binarytree (Vasco Asturiano), d3-quadtree (Mike Bostock) | [vasturiano/d3-force-3d](https://github.com/vasturiano/d3-force-3d), [vasturiano/d3-octree](https://github.com/vasturiano/d3-octree), [vasturiano/d3-binarytree](https://github.com/vasturiano/d3-binarytree), [d3/d3-quadtree](https://github.com/d3/d3-quadtree) | MIT (Copyright (c) 2017 Vasco Asturiano); d3-quadtree ISC (Copyright 2010-2021 Mike Bostock) | `engine/third_party/js/d3-force-3d/`, `d3-octree/`, `d3-binarytree/`, `d3-quadtree/` (each has its `LICENSE`) |
| Paper.js 0.16.0 | [paperjs/paper.js](https://github.com/paperjs/paper.js) | MIT (Copyright (c) 2011-2020 Jürg Lehni & Jonathan Puckey) | `engine/third_party/js/paper/` (`LICENSE.txt`, `SOURCE.txt`; run when a Paper.js script is run) |
| turtletoy 1.0.3 | [reindernijhoff/turtletoy-package](https://github.com/reindernijhoff/turtletoy-package) | MIT (Copyright (c) 2025 Reinder Nijhoff) | `engine/third_party/js/turtletoy/` (`LICENSE`, `SOURCE.txt`; run when a Turtletoy script is run) |
| Two.js 0.8.24 | [jonobr1/two.js](https://github.com/jonobr1/two.js) | MIT (Copyright (c) 2012-2025 jonobr1) | `engine/third_party/js/two/` (`LICENSE`, `SOURCE.txt`; run when a Two.js scene is run) |
| twigl shader helpers (`noise.glsl`; the simplex noise in it is Ashima Arts' webgl-noise) | [doxas/twigl](https://github.com/doxas/twigl) src/shader_snippet/noise.glsl | MIT (stated in `SOURCE.txt`; the folder has no separate licence file) | `engine/third_party/js/twigl/noise.h` (as it is) |
| rapidfuzz-cpp v3.3.4 (the fuzzy matching of search: typos, parts, abbreviations) | [rapidfuzz/rapidfuzz-cpp](https://github.com/rapidfuzz/rapidfuzz-cpp) extras/rapidfuzz_amalgamated.hpp | MIT (Copyright (c) 2020 Max Bachmann, 2011 Adam Cohen) | `engine/third_party/rapidfuzz/` (`LICENSE`, `SOURCE.txt`; unchanged) |
| anime.js v4.5.0 | [juliangarnier/anime](https://github.com/juliangarnier/anime) | MIT | `engine/third_party/anime/` |
| Splitting 1.1.0 stylesheet (the styles Splitting recommends, put before a pasted pen's CSS) | [shshaw/Splitting](https://github.com/shshaw/Splitting) | MIT (Copyright (c) 2018 Stephen Shaw) | `engine/third_party/splitting/` (`splitting.css` and `LICENSE.md` from the npm package, as they are; `SOURCE.txt`) |
| acorn 8.18.0 (the parser read once, when After Effects expressions are pasted) | [acornjs/acorn](https://github.com/acornjs/acorn) | MIT | `engine/third_party/js/acorn/` (`acorn.js` from the npm package and `LICENSE`, as they are; read only when a recipe says `AE.compile`, never per frame) |
| p5.js 1.11.13 | [processing/p5.js](https://github.com/processing/p5.js) | LGPL-2.1 | `engine/third_party/js/p5/` (`p5.min.js` and `license.txt` from the distribution, as they are; read as an ordinary file that can be replaced) |
| Cube Wave (Coding Challenge 86) | [CodingTrain/Coding-Challenges](https://github.com/CodingTrain/Coding-Challenges) (Copyright (c) 2022 Coding Train) | MIT | `shelves/create/repeats/Cube Wave.js` (the source on the first line, the rest unchanged) |
| Godot easing equations | easing_equations.h of [godotengine/godot](https://github.com/godotengine/godot) (Robert Penner's equations) | MIT | `engine/third_party/godot_easing/` |
| Godot's String::capitalize (shows a knob key as a name: ease_in becomes Ease In) | _separate_compound_words and capitalize in core/string/ustring.cpp of [godotengine/godot](https://github.com/godotengine/godot), commit c51ff06e8836 | MIT | `engine/community/quickjs/script_leva.h` (moved to JavaScript, the source is in its header); the licence is the same as the one in `engine/third_party/godot_easing/` |
| Japanese WordNet v1.1 (the table `ja_en.tsv` that looks Japanese up in English for search, cut out with `engine/deps/wnja_export.py`) | [bond-lab/wnja](https://github.com/bond-lab/wnja) (NICT, Francis Bond, Takayuki Kuribayashi) | The Japanese WordNet licence (`LICENSE-wnja.txt`) | `engine/third_party/wordnet_ja/` (`SOURCE.txt`) |
| Noto Sans JP (the fallback typeface for missing glyphs) | [notofonts/noto-cjk](https://github.com/notofonts/noto-cjk) | SIL OFL 1.1 | `engine/third_party/noto_sans_jp/` (`NotoSansJP-LICENSE.txt`) |
| gflanguages sample text (Fonts tab, `samples.json` cut out with `engine/deps/from_gflanguages.py`) | [googlefonts/lang](https://github.com/googlefonts/lang) | Apache-2.0 | `engine/third_party/gflanguages/` (`gflanguages-LICENSE.txt`) |
| Frame pacing | [nmfisher/thermion](https://github.com/nmfisher/thermion) | Apache-2.0 | `engine/third_party/thermion_frame/` (NOTICE.md) |
| t-SNE of the shelf map: qdtsne v3.0.3, knncolle v3.1.2, aarand v1.1.0, subpar v0.5.2, sanisizer v0.2.2 | [libscran/qdtsne](https://github.com/libscran/qdtsne) and others (Copyright (c) Aaron Lun) | MIT | `engine/third_party/qdtsne/` (LICENSE.<名前>, SOURCE.txt) |
| Grid of the shelf map: rectangular_lsap of SciPy v1.14.1 (the inside of linear_sum_assignment, by PM Larsen) | [scipy/scipy](https://github.com/scipy/scipy) (Copyright (c) 2001-2002 Enthought, Inc. 2003-2024, SciPy Developers) | BSD-3-Clause | `engine/third_party/scipy_lsap/` (LICENSE.scipy.txt, SOURCE.txt) |

## 2. Fetched at build time (not in the repository)

Each is fetched from the author's own distribution at a fixed version, and Motolii's patches (`.patch`), if any, are applied. Where it is fetched from and the version are at the top of each script.

| Work | Version | Licence | Script that fetches it | Motolii's patches |
|---|---|---|---|---|
| [Filament](https://github.com/google/filament) (includes Dawn and glslang) | v1.77.2 | Apache-2.0 and others | `engine/deps/filament.sh` | `engine/deps/patches/filament/`, `glslang/`, `tint/`, `dawn/` |
| [ThorVG](https://github.com/thorvg/thorvg) | 9203245 | MIT | `engine/deps/thorvg.sh` | `engine/deps/patches/thorvg/` |
| [Skia](https://skia.org/) (the path part only) | chrome/m149 | BSD-3-Clause | `engine/deps/skia.sh` | none |
| [libtess2](https://github.com/memononen/libtess2) | 8dbd648 | SGI Free Software License B 2.0 | `engine/deps/libtess2.sh` | none |
| [Jolt Physics](https://github.com/jrouwe/JoltPhysics) | 5.6.1 (a4b24c3) | MIT | `engine/deps/jolt.sh` | none |
| [FFmpeg](https://ffmpeg.org/): the programs `ffmpeg` and `ffprobe` (the exported video, the datamosh, the tiles' films) and the libraries libavformat, libavcodec, libavutil (linked dynamically by `libmotolii`, through IRIS's video reading) | 9.0.2 | LGPL-2.1 or later; built without GPL parts (no libx264, libx265), configured as `third_party/ffmpeg_lgpl/CONFIGURE.txt` says | `engine/deps/ffmpeg.sh` | none |
| [ONNX Runtime](https://github.com/microsoft/onnxruntime) (runs the CLIP and FontCLIP image encoders for the shelf maps; the release carries its own dependencies, whose notices are in the release's own third-party notices file) | 1.31.1 | MIT | `engine/deps/onnxruntime.sh` | none |
| [libass](https://github.com/libass/libass) (draws pasted ASS and SSA subtitles, karaoke included; linked dynamically by `libmotolii`, `engine/community/subtitles/`) | 0.17.5 | ISC | `Brewfile` (Homebrew) | none |
| [IRIS](https://github.com/electronicarts/IRIS) (checks exported video for flashing) | d96978a | BSD-3-Clause | `engine/deps/iris.sh` | none |
| [OpenCV](https://github.com/opencv/opencv) (only core, imgproc, features2d and videoio, which IRIS reads) | 4.12.0 (49486f6) | Apache-2.0 | `engine/deps/iris.sh` | none |
| [spdlog](https://github.com/gabime/spdlog) (IRIS's log; includes fmt) | v1.15.3 (6fa3601) | MIT | `engine/deps/iris.sh` | none |
| [nlohmann/json](https://github.com/nlohmann/json) (IRIS's settings and results) | v3.12.0 (55f9368) | MIT | `engine/deps/iris.sh` | none |
| [PianoRollSvg.js](https://github.com/bladeSk/midi-to-piano-roll) (the piano roll of the MIDI view) | 205854e | MIT (as declared in the author's package.json; not bundled, because the author's side has no licence text) | `engine/deps/midi_roll.sh` | none |
| 48 TSL expressions | As in `engine/community/three_shading_language_to_shelf/sources.tsv` | Each author | `engine/community/three_shading_language_to_shelf/fetch.sh` | `engine/deps/patches/shader-lab/`, `ics-creative/` |
| [perfect_freehand](https://pub.dev/packages/perfect_freehand) (the outline of Brush strokes; originally Steve Ruiz's perfect-freehand) | 2.5.2+1 | MIT (Copyright (c) 2021 Stephen Ruiz, 2023 Adil Hanney) | `app/pubspec.yaml` (flutter pub get) | none |
| [AbsentMotion](https://github.com/Comett1225/AbsentMotion) (the source of the effects turned into WGSL) | 0f5d891 | Apache-2.0 | `shelves/effects/sources/absent.sh` | none |
| [OpenAI CLIP](https://github.com/openai/CLIP) ViT-B/32 image encoder (shelf map: effect frames). Turned into ONNX and placed at `~/Library/Caches/Motolii/models/clip_b32.onnx` | The `openai` weights of open_clip (ViT-B-32.pt) | MIT | `engine/deps/likeness_models.py` (loaded with [open_clip](https://github.com/mlfoundations/open_clip), MIT; exported with torch.onnx.export of [PyTorch](https://github.com/pytorch/pytorch), BSD-3-Clause) | none |
| [FontCLIP](https://github.com/yukistavailable/FontCLIP) (Tatsukawa et al., Eurographics 2024) image encoder (shelf map: font samples). Turned into ONNX as `fontclip_b32.onnx` | model.pt from setup_data.py | MIT (the author says in issue 13 that the weights are MIT too) | `engine/deps/likeness_models.py` (follows the way fontclip_model.py of [FontMap](https://github.com/tfrere/fontmap) reads it, MIT) | none |

## 3. List of AviUtl2 scripts (172)

| Name | Author | Licence | Distribution | Where it sits |
|---|---|---|---|---|
| PSD連携アニメーション(非公式) | CJF | MIT | https://github.com/ColorJellyFish/aviutl2_cjf_psdanimation | `CJF__PSD_anime` |
| ペン&矩形ツール | CJF | MIT | https://github.com/ColorJellyFish/aviutl2_cjf_pentool | `CJF__PenTool` |
| AlphaDither_C | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#alphadither_c | `CatWithNeko__AlphaDither` |
| Canny | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts | `CatWithNeko__Canny` |
| Chromatic Aberration | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#chromatic-aberration | `CatWithNeko__ChromaticAberration` |
| Colorama | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#colorama | `CatWithNeko__Colorama` |
| Composite | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts | `CatWithNeko__Composite` |
| Dither | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#dither | `CatWithNeko__Dither` |
| Erosion | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#erosion | `CatWithNeko__Erosion` |
| Exposure | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#exposure | `CatWithNeko__Exposure` |
| Gamma | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#gamma | `CatWithNeko__Gamma` |
| Halftone | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts | `CatWithNeko__Halftone` |
| Leave Color | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#leave-color | `CatWithNeko__LeaveColor` |
| Lens | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts | `CatWithNeko__Lens` |
| Level | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#level | `CatWithNeko__Level` |
| LongShadow | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts | `CatWithNeko__LongShadow` |
| MaxMin | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#maxmin | `CatWithNeko__MaxMin` |
| Mosaic_C | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#mosaic_c | `CatWithNeko__Mosaic` |
| SelfDisplace | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#selfdisplace | `CatWithNeko__SelfDisplace` |
| Tonecurve_C | こんにゃくねこ | CC0-1.0 | https://x.com/CatWithNeko/status/1972685066963960255 | `CatWithNeko__ToneCurve` |
| Turbulent | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#turbulent | `CatWithNeko__Turbulent` |
| Wave Warp | こんにゃくねこ | CC0-1.0 | https://github.com/CatWithNeko/aviutl2-scripts#wave-warp | `CatWithNeko__WaveWarp` |
| Aviutl2_CJF | ColorJellyFish | MIT | https://github.com/ColorJellyFish/Aviutl2_CJF | `ColorJellyFish__Aviutl2_CJF` |
| aviutl2_cjf_maskselector | ColorJellyFish | MIT | https://github.com/ColorJellyFish/aviutl2_cjf_maskselector | `ColorJellyFish__aviutl2_cjf_maskselector` |
| 多角形モーフ_F | フマジメ | MIT | https://github.com/fu-majime/AviUtl2_PolygonMorph_F | `Fu-Majime__AviUtl2_PolygonMorph_F` |
| 日付と時刻 | Garech | CC0-1.0 | https://www.nicovideo.jp/watch/sm36307237 | `Garech__DateTime` |
| リッチな音声波形_Gk | Gohankaiju | MIT | https://github.com/Gohankaiju/aviutl2-rich-audio-spectrum | `Gohankaiju__rich-audio-spectrum` |
| AviUtl2Browser_H | HexBrowns | MIT | https://github.com/HexBrowns/AviUtl2Browser_H | `HexBrowns__AviUtl2Browser_H` |
|  | one download for: HexBrowns.Filters_H, HexBrowns.FineParticles_H, HexBrowns.ExtendedParticle_H, HexBrowns.Lowpoly, HexBrowns.Bubbles_H, HexBrowns.VerticalText, HexBrowns.HandheldCamera_H, HexBrowns.Beam_H, HexBrowns.OpticalBokeh, HexBrowns.ShapeDistort_H, HexBrowns.Grid_H, HexBrowns.LightShaft_H, HexBrowns.ProceduralPattern_H, HexBrowns.LightPath_H, HexBrowns.RadioWaves_H, HexBrowns.DecoParticle_H, HexBrowns.Caustics_H, HexBrowns.AutoFitText_H, HexBrowns.Lighting2D_H, HexBrowns.SceneTransitions, HexBrowns.CardDance_H, HexBrowns.Extrude_H, HexBrowns.TimeWarp_H, HexBrowns.VectorBlur_H, HexBrowns.BallAction_H, HexBrowns.Keying_H, HexBrowns.TestPattern_H, HexBrowns.RangeWarning_H, HexBrowns.PlanarTracking_H, HexBrowns.ContentAwareFill_H, HexBrowns.ColorSpaceBlend_H | MIT No Attribution | https://github.com/HexBrowns/HexScript | `HexBrowns__HexScript` |
| 色付き残像(画像履歴) | HexBrowns | MIT | https://github.com/HexBrowns/ColoredEchoImg | `HexBrowns__色付き残像_画像履歴_` |
| Open Glow | 絵に描いた虹 | MIT | https://github.com/IZUisMe/aviutl2-open-glow | `IZUisMe__OpenGlow` |
| ColorLink | 犬好アトム | MIT | https://github.com/InuyoshiAtom/aviutl2-colorlink | `InuyoshiAtom__ColorLink` |
| KSA | KAZOON | MIT | https://github.com/cycloawaodorin/ksa | `KAZOON__KSA` |
| 曲げKR | かろてら | MIT | https://github.com/karoterra/aviutl2-Bend | `Karoterra__Bend` |
| 色覚シミュレーションKR | かろてら | Unlicense | https://github.com/karoterra/aviutl2-ColorVisionSimulation | `Karoterra__ColorVisionSimulation` |
| 油絵KR | かろてら | MIT | https://github.com/karoterra/aviutl2-OilPainting | `Karoterra__OilPainting` |
| SoftAnchorBone | なたのこ | MIT | https://github.com/Natadecoco2539/AviUtl2-SoftAnchorBone | `Natadecoco__SoftAnchorBone` |
| 無印ノイズ | 猫愛 | MIT | https://github.com/nea-c/aviutl2_script_AviUtlNoise | `NeAc__AviUtlNoise` |
| BezierPath | 猫愛 | MIT | https://github.com/nea-c/aviutl2_script_BezierPath | `NeAc__BezierPath` |
| シネマスコープ | 猫愛 | MIT | https://github.com/nea-c/aviutl2_script_CinemaScope | `NeAc__CinemaScope` |
| エ霞(えがすみ) | 猫愛 | MIT | https://github.com/nea-c/aviutl2_script_Egasumi | `NeAc__Egasumi` |
| LongShadowN | 猫愛 | Apache-2.0 | https://github.com/nea-c/aviutl2_script_LongShadowN | `NeAc__LongShadowN` |
| Loop | 猫愛 | MIT | https://github.com/nea-c/aviutl2_script_Loop | `NeAc__Loop` |
| LyricMotioN | 猫愛 | MIT | https://github.com/nea-c/aviutl2_script_LyricMotioN | `NeAc__LyricMotioN` |
| Scatter | 猫愛 | MIT | https://github.com/nea-c/aviutl2_script_Scatter | `NeAc__Scatter` |
| 画面アスペクト | 猫愛 | MIT | https://github.com/nea-c/aviutl2_script_ScreenAspect | `NeAc__ScreenAspect` |
| スピード線 | 猫愛 | MIT | https://github.com/nea-c/aviutl2_script_SpeedLine | `NeAc__SpeedLine` |
| SeiSa | SLDC | MIT | https://github.com/samuelladoco/aviutl2-script-seisa | `SLDC__SeiSa` |
| AviUtl2-Script-GB_Style | SagyouDarui900 | MIT | https://github.com/SagyouDarui900/AviUtl2-Script-GB_Style | `SagyouDarui900__AviUtl2-Script-GB_Style` |
| DVD | サ行 | MIT | https://github.com/SagyouDarui900/AviUtl2_Script_SagyouDarui | `Sagyou__DVD` |
| JpegNoise_for_AviUtl2 | サ行 | MIT | https://github.com/SagyouDarui900/JPEGNoise_AviUtl2 | `Sagyou__JpegNoise` |
| OpticsCompensation_s_for_AviUtl2 | サ行 | MIT | https://github.com/SagyouDarui900/OpticsCompensation_s_for_AviUtl2 | `Sagyou__OpticsCompensation_s_for_AviUtl2` |
| Mathy_Su | Suzukeh | MIT | https://github.com/Suzukeh/Mathy_Su | `Suzukeh__Mathy_Su` |
| uta-resources | UtaUtaUtau | MIT | https://github.com/UtaUtaUtau/uta-resources | `UtaUtaUtau__uta-resources` |
| グランジ背景を生成 | arcana | MIT | https://github.com/ar-ca-na/aviutl2-grunge-bg | `ar-ca-na__grunge-bg` |
| 波形ライン | arcana | MIT | https://github.com/ar-ca-na/aviutl2-waveform-line | `ar-ca-na__waveform-line` |
| 連結ライン | arcana | MIT | https://github.com/ar-ca-na/connection_line | `arcana__connection_line` |
| AviUtl2-GradientEditor | azurite581 | MIT | https://github.com/azurite581/AviUtl2-GradientEditor | `azurite581__AviUtl2-GradientEditor` |
| 中心ずらし_A | azurite | MIT | https://github.com/azurite581/AviUtl2-AdjustPivot_A | `azurite__AdjustPivot_A` |
| ColorHalftone | azurite | MIT | https://github.com/azurite581/AviUtl2-ColorHalftone | `azurite__ColorHalftone` |
| グラデーション+ | azurite | CC0-1.0 | https://github.com/azurite581/AviUtl2-GradientPlus | `azurite__GradientPlus` |
| Hex-Tiling | azurite | MIT No Attribution | https://github.com/azurite581/AviUtl2-Hex-Tiling | `azurite__Hex-Tiling` |
| レイヤーグリッド表示 | azurite | MIT | https://github.com/azurite581/AviUtl2-LayerGridView | `azurite__LayerGridView` |
| ポイントズーム | azurite | MIT | https://github.com/azurite581/AviUtl2-PointZoom | `azurite__PointZoom` |
| scene-lighting | Beive60 | MIT | https://github.com/beive60/aviutl2-scene-lighting | `beive60__scene-lighting` |
| RhythmShapesForAviutl2 | coffin299 | MIT | https://github.com/coffin299/RhythmShapesForAviutl2 | `coffin299__RhythmShapesForAviutl2` |
| プレースホルダー | 映像学区 | MIT | https://github.com/eizo-gak/aviutl2-Placeholder | `eizo-gak__aviutl2-Placeholder` |
| aviutl2-script-skill | gasdyueer | MIT | https://github.com/gasdyueer/aviutl2-script-skill | `gasdyueer__aviutl2-script-skill` |
| PSDToolkit用自然な口パク | ただのごみ | MIT | https://github.com/gomi1124/PSDToolKit-Natural-LipSync | `gomi1124__PSDToolkit用自然な口パク` |
| aviutl2-RoundedRect | karoterra | MIT | https://github.com/karoterra/aviutl2-RoundedRect | `karoterra__aviutl2-RoundedRect` |
| AutoLyricAnimation_K | Korarei | MIT | https://github.com/korarei/AviUtl2_AutoLyricAnimation_K_Script | `korarei__AutoLyricAnimation_K` |
| AviUtl_GrungeConverter_Script | korarei | MIT | https://github.com/korarei/AviUtl_GrungeConverter_Script | `korarei__AviUtl_GrungeConverter_Script` |
| CameraTransform_K | Korarei | MIT | https://github.com/korarei/AviUtl2_CameraTransform_K_Script | `korarei__CameraTransform_K` |
| Diffusion_K | Korarei | MIT | https://github.com/korarei/AviUtl2_Diffusion_K_Script | `korarei__Diffusion_K` |
| FlowType_K | Korarei | MIT | https://github.com/korarei/AviUtl2_FlowType_K_Script | `korarei__FlowType_K` |
| Kaleidoscope_K | Korarei | MIT | https://github.com/korarei/AviUtl2_Kaleidoscope_K_Script | `korarei__Kaleidoscope_K` |
| PixelSorter_K | Korarei | MIT | https://github.com/korarei/AviUtl2_PixelSorter_K_Script | `korarei__PixelSorter_K` |
| @Stylize_K | Korarei | MIT | https://github.com/korarei/AviUtl2_Stylize_K_Script | `korarei__Stylize_K` |
| aviutl2-scripts | kusugawatsumiki | MIT | https://github.com/kusugawatsumiki/aviutl2-scripts | `kusugawatsumiki__aviutl2-scripts` |
| Unmult | mes51 | MIT | https://github.com/mes51/AVIUtl2_Unmult | `mes51__Unmult` |
| ベクターキャンバス | もげ | MIT | https://github.com/Mg32/aviutl2-vectorcanvas | `mogesystem__VectorCanvas` |
| SubObjRelativeMotionEX | natuneko722 | MIT | https://github.com/natuneko722/SubObjRelativeMotionEX | `natuneko722__SubObjRelativeMotionEX` |
| 吹き出し背景@テキスト | 夏猫 | MIT | https://github.com/natuneko722/TextBackgroundBalloonScript | `natuneko722__text-background-balloon-script` |
| AutoBlendLight | nctype | MIT | https://github.com/nctype/aviutl2_script_AutoBlendLight | `nctype__AutoBlendLight` |
| FilmPrintLUT | nctype | MIT | https://github.com/nctype/aviutl2_script_FilmPrintLUT | `nctype__FilmPrintLUT` |
| Pixelizer | nctype | MIT | https://github.com/nctype/aviutl2_script_Pixelizer | `nctype__Pixelizer` |
| PuniCollision | nctype | MIT | https://github.com/nctype/aviutl2_script_PuniCollision | `nctype__PuniCollision` |
| RainOnPane | nctype | MIT | https://github.com/nctype/aviutl2_script_RainOnPane | `nctype__RainOnPane` |
| ReflectionOnPane | nctype | MIT | https://github.com/nctype/aviutl2_script_ReflectionOnPane | `nctype__ReflectionOnPane` |
| SomethingLikeGlitch | nctype | MIT | https://github.com/nctype/aviutl2_script_SomethingLikeGlitch | `nctype__SomethingLikeGlitch` |
| AviUtl-Scripts | nea-c | MIT | https://github.com/nea-c/AviUtl-Scripts | `nea-c__AviUtl-Scripts` |
| aviutl2_script_Alignment | nea-c | MIT | https://github.com/nea-c/aviutl2_script_Alignment | `nea-c__aviutl2_script_Alignment` |
| aviutl2_script_CircularArrangementMask | nea-c | MIT | https://github.com/nea-c/aviutl2_script_CircularArrangementMask | `nea-c__aviutl2_script_CircularArrangementMask` |
| aviutl2_script_MousePointer | nea-c | MIT | https://github.com/nea-c/aviutl2_script_MousePointer | `nea-c__aviutl2_script_MousePointer` |
| aviutl2_script_ZoomJustFit | nea-c | MIT | https://github.com/nea-c/aviutl2_script_ZoomJustFit | `nea-c__aviutl2_script_ZoomJustFit` |
| VRM Toolkit for AviUtl2 | novenove | MIT | https://github.com/nove-nove/aviutl2-vrm-toolkit | `nove-nove__VRM_Toolkit_for_AviUtl2` |
| ObjectSlicerAnm2 | nssuperx | CC0-1.0 | https://github.com/nssuperx/ObjectSlicerAnm2 | `nssuperx__ObjectSlicerAnm2` |
| colorQuantizeAnm2 | nssuperx | CC0-1.0 | https://github.com/nssuperx/colorQuantizeAnm2 | `nssuperx__colorQuantizeAnm2` |
| dithering.anm2 | nssuperx | CC0-1.0 | https://github.com/nssuperx/dithering.anm2 | `nssuperx__dithering.anm2` |
| playground | nssuperx | Unlicense | https://github.com/nssuperx/playground | `nssuperx__playground` |
| AviUtl2-MIDI | rokujyushi | MIT | https://github.com/rokujyushi/AviUtl2-MIDI | `rokujyushi__AviUtl2-MIDI` |
| TTSFileRename | 黒猫大福 | MIT | https://github.com/rokujyushi/GCMZScripts | `rokujyushi__TTSFileRename` |
| VariableFont | 黒猫大福 | MIT | https://github.com/rokujyushi/Variable-Font-Plug-ins | `rokujyushi__VariableFont` |
| audio2obj | 黒猫大福 | MIT | https://github.com/rokujyushi/GCMZScripts | `rokujyushi__audio2obj` |
| midi2EAP2 | 黒猫大福 | MIT | https://github.com/rokujyushi/GCMZScripts | `rokujyushi__midi2EAP2` |
| svg2obj | 黒猫大福 | MIT | https://github.com/rokujyushi/GCMZScripts | `rokujyushi__svg2obj` |
| Aviutl2-RZoom | ryou8134 | MIT | https://github.com/ryou8134/Aviutl2-RZoom | `ryou8134__Aviutl2-RZoom` |
| BlockNoise | 3aGaM1 | MIT | https://github.com/sagami121/Aviutl2-BlockNoise | `sagami121__BlockNoise` |
| GParticle | 3aGaM1 | MIT | https://github.com/sagami121/GParticle | `sagami121__GParticle` |
| Glitch_T | 3aGaM1 | MIT | https://github.com/sagami121/Glitch_T | `sagami121__Glitch_T` |
| QRCode | 3aGaM1 | MIT | https://github.com/sagami121/Aviutl2-QRCode | `sagami121__QRCode` |
| 墨だまり | saluf | MIT | https://github.com/5qlufz-1536/AviUtl2_SumiDamari | `saluf__SumiDamari` |
| 角丸正多角形_sl | セイル | MIT | https://github.com/seilor0/roundedPolygon_sl | `seilor0__roundedPolygonSl` |
| twinkle_sl | セイル | MIT | https://github.com/seilor0/twinkle_sl | `seilor0__twinkle_sl` |
| ベベルとエンボス.anm2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/aviutl2-scripts/blob/main/scripts/%E3%83%99%E3%83%99%E3%83%AB%E3%81%A8%E3%82%A8%E3%83%B3%E3%83%9C%E3%82%B9/README.md | `sevenc-nanashi__aviutl2-scripts.bevel_and_emboss-anm2` |
| カメラフレーム.obj2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/aviutl2-scripts/blob/main/scripts/%E3%82%AB%E3%83%A1%E3%83%A9%E3%83%95%E3%83%AC%E3%83%BC%E3%83%A0/README.md | `sevenc-nanashi__aviutl2-scripts.camera_frame-obj2` |
| CRTディスプレイ風.anm2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/aviutl2-scripts/blob/main/scripts/CRT%E3%83%87%E3%82%A3%E3%82%B9%E3%83%97%E3%83%AC%E3%82%A4%E9%A2%A8/README.md | `sevenc-nanashi__aviutl2-scripts.crt-display.anm2` |
| ドカベン.anm2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/aviutl2-scripts/tree/main/scripts/%E3%83%89%E3%82%AB%E3%83%99%E3%83%B3 | `sevenc-nanashi__aviutl2-scripts.dokaben-anm2` |
| GPUピクセルソート.anm2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/aviutl2-scripts/blob/main/scripts/GPU%E3%83%94%E3%82%AF%E3%82%BB%E3%83%AB%E3%82%BD%E3%83%BC%E3%83%88/README.md | `sevenc-nanashi__aviutl2-scripts.gpu_pixelsort-anm2` |
| 出力時に非表示.anm2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/aviutl2-scripts/blob/main/scripts/%E5%87%BA%E5%8A%9B%E6%99%82%E3%81%AB%E9%9D%9E%E8%A1%A8%E7%A4%BA/README.md | `sevenc-nanashi__aviutl2-scripts.hide_on_export-anm2` |
| 旧発光.anm2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/aviutl2-scripts/tree/main/scripts/%E6%97%A7%E7%99%BA%E5%85%89 | `sevenc-nanashi__aviutl2-scripts.legacy_glow-anm2` |
| ドット絵変形.anm2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/aviutl2-scripts/tree/main/scripts/%E3%83%89%E3%83%83%E3%83%88%E7%B5%B5%E5%A4%89%E5%BD%A2#%E3%83%89%E3%83%83%E3%83%88%E7%B5%B5%E5%A4%89%E5%BD%A2anm2 | `sevenc-nanashi__aviutl2-scripts.pixel-transform-anm2` |
| 目標指定拡大縮小.anm2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/aviutl2-scripts/blob/main/scripts/%E7%9B%AE%E6%A8%99%E6%8C%87%E5%AE%9A%E6%8B%A1%E5%A4%A7%E7%B8%AE%E5%B0%8F/README.md | `sevenc-nanashi__aviutl2-scripts.targeted-scale-anm2` |
| 縦動画ガイド.obj2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/aviutl2-scripts/blob/main/scripts/%E7%B8%A6%E5%8B%95%E7%94%BB%E3%82%AC%E3%82%A4%E3%83%89/README.md | `sevenc-nanashi__aviutl2-scripts.vertical-video-obj2` |
| budoux.obj2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/budoux.obj2 | `sevenc-nanashi__budoux.obj2` |
| disassembler.anm2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/disassembler.anm2 | `sevenc-nanashi__disassembler.anm2` |
| extra_blend_mode.anm2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/extra_blend_mode.anm2 | `sevenc-nanashi__extra_blend_mode-anm2` |
| ntsc-rs.anm2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/ntsc-rs.anm2 | `sevenc-nanashi__ntsc-rs.anm2` |
| ported_tim | Nanashi. | MIT | https://github.com/sevenc-nanashi/ported_tim | `sevenc-nanashi__ported_tim` |
| time_control_assistant.tra2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/time_control_assistant.tra2 | `sevenc-nanashi__time_control_assistant-tra2` |
| transform_specific_chars.anm2 | Nanashi. | MIT | https://github.com/sevenc-nanashi/transform_specific_chars.anm2 | `sevenc-nanashi__transform_specific_chars.anm2` |
| AutoClipping_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_AutoClipping_S | `sigma-axis__AutoClipping_S` |
| Basic_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_Basic_S | `sigma-axis__Basic_S` |
| ColoredCollar_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_ColoredCollar_S | `sigma-axis__ColoredCollar_S` |
| GroundShadow2_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_GroundShadow2_S | `sigma-axis__GroundShadow2_S` |
| Histogram_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_Histogram_S | `sigma-axis__Histogram_S` |
| 最背面に配置 | σ軸 | Unlicense | https://github.com/sigma-axis/aviutl2_script_Layback | `sigma-axis__Layback` |
| Lens_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_Lens_S | `sigma-axis__Lens_S` |
| MovingMosaic_S | σ軸 | Unlicense | https://github.com/sigma-axis/aviutl2_script_MovingMosaic_S | `sigma-axis__MovingMosaic_S` |
| PageRoll_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_PageRoll_S | `sigma-axis__PageRoll_S` |
| Path_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_Path_S/ | `sigma-axis__Path_S` |
| PixelSnap_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_PixelSnap_S | `sigma-axis__PixelSnap_S` |
| RadRotDirBlur_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_RadRotDirBlur_S | `sigma-axis__RadRotDirBlur_S` |
| Region_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_Region_S | `sigma-axis__Region_S` |
| Resize_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_Resize_S | `sigma-axis__Resize_S` |
| シーンチェンジ自作キット | σ軸 | Unlicense | https://github.com/sigma-axis/aviutl2_script_SceneChangeKit_S | `sigma-axis__SceneChangeKit_S` |
| Tile_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_Tile_S | `sigma-axis__Tile_S` |
| WhiteBalance_S | σ軸 | MIT | https://github.com/sigma-axis/aviutl2_script_WhiteBalance_S | `sigma-axis__WhiteBalance_S` |
| aviutl2_script_ColorSolid_S | sigma-axis | MIT | https://github.com/sigma-axis/aviutl2_script_ColorSolid_S | `sigma-axis__aviutl2_script_ColorSolid_S` |
| aviutl2_script_GameOfLife | sigma-axis | Unlicense | https://github.com/sigma-axis/aviutl2_script_GameOfLife | `sigma-axis__aviutl2_script_GameOfLife` |
| aviutl2_script_PenroseTile_S | sigma-axis | MIT | https://github.com/sigma-axis/aviutl2_script_PenroseTile_S | `sigma-axis__aviutl2_script_PenroseTile_S` |
| 放射クリッピング | スーパーNyan | MIT | https://github.com/supernyan74/Radial-Clipping | `supernyan74__RadialClipping` |
| CrEasy | suti7yk5032 | CC0-1.0 | https://github.com/suti7yk5032/CrEasy | `suti7yk5032__CrEasy` |
| 四隅に配置 | てるよし | MIT | https://github.com/teruyoshii/Teruyoshi_AviUtl2_Scripts/blob/main/%E5%9B%9B%E9%9A%85%E3%81%AB%E9%85%8D%E7%BD%AE.anm2 | `teruyoshii__4corner` |
| AviUtl2_Keychain_to_Transform | teruyoshii | MIT | https://github.com/teruyoshii/AviUtl2_Keychain_to_Transform | `teruyoshii__AviUtl2_Keychain_to_Transform` |
| トラックバー音声同期 | てるよし | MIT | https://x.com/teruyoshi_uec/status/1965389717224276231 | `teruyoshii__TrackbarAudioSync` |
| ノイズグラデーション | てるよし | MIT | https://x.com/teruyoshi_uec/status/1979927691215471002 | `teruyoshii__noiseGradation` |
| ノイズ_Te | てるよし | MIT | https://github.com/teruyoshii/AviUtl2_Noise_Te | `teruyoshii__noiseTe` |
| パスブラー | てるよし | MIT | https://github.com/teruyoshii/Teruyoshi_AviUtl2_Scripts/blob/main/%E3%83%91%E3%82%B9%E3%83%96%E3%83%A9%E3%83%BC.anm2 | `teruyoshii__pathBlur` |
| パスグラデーション | てるよし | MIT | https://github.com/teruyoshii/Teruyoshi_AviUtl2_Scripts/blob/main/%E3%83%91%E3%82%B9%E3%82%B0%E3%83%A9%E3%83%87%E3%83%BC%E3%82%B7%E3%83%A7%E3%83%B3.anm2 | `teruyoshii__pathGradation` |
| 段階グラデーション | てるよし | MIT | https://github.com/teruyoshii/Teruyoshi_AviUtl2_Scripts/blob/main/%E6%AE%B5%E9%9A%8E%E3%82%B0%E3%83%A9%E3%83%87%E3%83%BC%E3%82%B7%E3%83%A7%E3%83%B3.anm2 | `teruyoshii__stepGradation` |
| Liquid Glass エフェクト | tettu0530 | MIT | https://github.com/Tettu0530/Liquid-Glass | `tettu0530__LiquidGlass` |
| Aviutl2-ImageLoop-Kai | uprpr3249 | MIT | https://github.com/uprpr3249/Aviutl2-ImageLoop-Kai | `uprpr3249__Aviutl2-ImageLoop-Kai` |
| Aviutl2-RandomPlacement-Kai | uprpr3249 | MIT | https://github.com/uprpr3249/Aviutl2-RandomPlacement-Kai | `uprpr3249__Aviutl2-RandomPlacement-Kai` |
| TypingEffect | 4vando | MIT | https://github.com/vandojapan/TypingEffect.obj2 | `vandojapan__TypingEffect` |
| aviutl2_metadata_script | yuratexi | MIT | https://github.com/yuratexi/aviutl2_metadata_script | `yuratexi__aviutl2_metadata_script` |
| どこでもバッファ | zopty | BSD-3-Clause | https://github.com/zopty/DokodemoBuffer | `zopty__DokodemoBuffer` |
| OSC4AU2 | zopty | BSD-3-Clause | https://github.com/zopty/osc4au2 | `zopty__OSC4AU2` |
| PerceptualColor.anm2 | zopty | BSD-3-Clause | https://github.com/zopty/PerceptualColor.anm2 | `zopty__PerceptualColor.anm2` |
| SmoothNoise | zopty | MIT | https://github.com/zopty/SmoothNoise | `zopty__SmoothNoise` |
| ブラインドループ | zopty | BSD-3-Clause | https://gist.github.com/zopty/ff3439d79fe609c7714d6db4ef1a39a6 | `zopty__ブラインドループ` |
| JPEGCrush | しけもち | MIT | https://note.com/sikemoti/n/n7017a0e6eabf | `しけもち__JPEGCrush` |
