# Contributing

[日本語](CONTRIBUTING.ja.md)

## What you can do

- **Issues**: bugs, a build that stopped, or "I want to use this expression" (a URL and what is good about it). There are templates. English or Japanese.
- **Pull requests**: welcome. Motolii is dual licensed under Apache-2.0 or MIT; unless you explicitly state otherwise, what you send is under the same two licences.
- **Authors of bundled works**: if you want the way your work is bundled changed, or it removed, open an issue and it will be done ([`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md)).

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Security problems go to the Security tab, not to issues ([`.github/SECURITY.md`](SECURITY.md)).

## Building

As in [`README.md`](../README.md) ("Build and run"); each step in detail is in the [guide](../docs/using/guide.md#try-it). Optionally, once in your clone, enable the hook that checks Dart formatting at commit time:

```bash
git config core.hooksPath .githooks
```

How the code is laid out: [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md), [`engine/README.md`](../engine/README.md) and [`app/README.md`](../app/README.md).

Words in the code and the docs are the ones After Effects, Filament, Flutter and Blender use: app, engine, layer, project, preview (`Stage` in the code). Only the left tabs have their own name, "shelf" (棚, as in Blender's Asset Shelf). No new coinages.

## Checks

Run these before you send a pull request. CI runs the same on every push and pull request (`.github/workflows/checks.yml`):

```bash
cd app && dart format . && flutter analyze && flutter test
```

For C++, `./engine/check_syntax.sh` checks syntax without building, `engine/build.sh` builds, and `engine/build.sh test` builds and runs the C++ tests. The full build runs on GitHub Actions in `.github/workflows/build.yml` (an Apple silicon Mac; on pushes to main and pull requests that touch `engine/`, `shelves/`, `app/` or `Brewfile`, and by hand from the Actions tab). How things are tested: [`docs/TESTING.md`](../docs/TESTING.md).

## Stance

The project's stance: **code you write yourself is a debt.** Look for an existing implementation first and use it the way its author meant; bundle other people's work as unchanged as possible, with their licence and source beside it; keep changes to upstream code as patches applied at build time; say in each commit what was borrowed from where. A lot of Motolii is still its own code today (the Flutter UI, for one); where something can be borrowed instead, the own code goes.

## Design principles

Decided by the author. A change that breaks one of them is not merged, even when its reasoning is sound. [`AGENTS.md`](../AGENTS.md) carries the same five for AI agents.

1. **Expressions from the net are not translated.** Pasted code (After Effects expressions, Cavalry, p5.js, shaders) is compiled once and run as it is. The same behaviour is not re-implemented in C++.
2. **No value is fixed without a source.** Nothing is greyed out or refused. A slider's range is for display and does not limit what can be typed. Where input is limited, the source that limits the same value is cited.
3. **No web page is embedded in the app.** A visual editor reads from the code and writes its edits back to the code; there is no second copy of the code.
4. **A small request is met with a mechanism Motolii already has.** Research outside the repository is for when Motolii has nothing.
5. **Dart holds looks only.** Presses, overlays and selection are handed to an implementation the app already depends on, and no dependency is added. The same hand-written code appearing several times is a copy, not a split: in the Inspector the effect card (`ValuesCard`) is the original, and other cards, number fields, chips and switches fold into it.

## Rules

1. **Look before you write.** Look at the tree (`engine/` the engine, `app/` the app, `shelves/` the bundled content) and at existing implementations on the net. If something can be used the way its author meant, use it.
2. **One job a file.** Split by what each part is for and name it so. Experiments stay on your own branch; main holds only what the app uses.
3. **Commit messages.**
   - The **subject** (first line) is 72 characters at most and says what changed. For example `Remove the unused Foo card`, `Fix Y in Z`.
   - After one blank line, the **body** says why it changed, what was checked and what is not done yet.
   - If you borrowed something, say where from (URL, version or commit) in the body. Example: `git show d46f69cac`.
4. **Bundling other people's work.**
   - Keep the author's folder as unchanged as possible, with their licence text (`LICENSE`) and where it came from (`SOURCE.txt`: name and author / licence / from / page) beside it.
   - Work whose author publishes no licence text is not bundled; fetch it from the author at build time instead (`engine/deps/midi_roll.sh` is an example).
   - Changes to upstream code are kept as patches, applied to a pinned upstream at build time (patches in `engine/deps/patches/<library>/`; `engine/deps/thorvg.sh` is an example).
   - Add a row to [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

## Good first tasks

| What | Where to start | Difficulty |
|---|---|---|
| An `.app` you can hand out: put the Homebrew libraries the engine loads (GStreamer, glib, SQLite, LuaJIT, QuickJS, and ffmpeg for writing) inside the `.app`, with [dylibbundler](https://github.com/auriamg/macdylibbundler) or GStreamer's macOS framework | `engine/edit.sh`, `app/macos/` | Medium |
| AviUtl2 calls still missing (`obj.computeshader`, the built-in effects, …), following the references (AviUtl2's lua.txt, sashimono-edit) | `docs/design/aviutl2_converter_plan.md`, `engine/community/aviutl/aviutl.cpp` | Medium–hard |
| TSL looks on the editor's shelves | `engine/community/three_shading_language_to_shelf/`, `docs/design/tsl_collection.md` | Medium |

## Known gaps

- Tried only on macOS on Apple silicon; Windows and Linux have not been tried yet.
- The engine (`libmotolii.dylib`) loads Homebrew's GStreamer and others, so a built `.app` does not run on another Mac as it is.
