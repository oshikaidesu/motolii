# Contributing

[日本語](CONTRIBUTING.ja.md)

## What you can do

- **Issues**: bugs, a build that stopped, or "I want to use this expression" (a URL and what is good about it). There are templates. English or Japanese.
- **Pull requests**: welcome. Motolii is dual licensed under Apache-2.0 or MIT; unless you explicitly state otherwise, what you send is under the same two licences.
- **Authors of bundled works**: if you want the way your work is bundled changed, or it removed, open an issue and it will be done ([`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md), Japanese).

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Security problems go to the Security tab, not to issues ([`.github/SECURITY.md`](SECURITY.md)).

## Building

As in [`README.md`](../README.md) ("Build and run"); each step in detail is in the [guide](../docs/using/guide.md#try-it). Optionally, once in your clone, enable the hook that checks Dart formatting at commit time:

```bash
git config core.hooksPath .githooks
```

How the code is laid out: [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) and [`engine/README.md`](../engine/README.md) (which files the current build uses; the rest are earlier probes). Both are in Japanese, with an English summary at the top.

Words in the code and the docs are the ones After Effects, Filament, Flutter and Blender use: app, engine, layer, project, preview (`Stage` in the code). Only the left tabs have their own name, "shelf" (棚, as in Blender's Asset Shelf). No new coinages.

## Checks

Run these before you send a pull request. CI runs the same on every push and pull request (`.github/workflows/checks.yml`):

```bash
cd app && dart format . && flutter analyze && flutter test
```

For C++, `./engine/check_syntax.sh` checks syntax without building and `engine/build.sh` builds. The full build runs on GitHub Actions in `.github/workflows/build.yml` (an Apple silicon Mac; on pushes to main and pull requests that touch `engine/`, `shelves/`, `app/` or `Brewfile`, and by hand from the Actions tab). How things are tested: [`docs/TESTING.md`](../docs/TESTING.md).

## Stance

The project's stance: **code you write yourself is a debt.** Look for an existing implementation first and use it the way its author meant; bundle other people's work as unchanged as possible, with their licence and source beside it; keep changes to upstream code as patches applied at build time; say in each commit what was borrowed from where. A lot of Motolii is still its own code today (the Flutter UI, for one); where something can be borrowed instead, the own code goes.

## Rules

1. **Look before you write.** Look at the tree (`engine/` the product, `app/` the app, `docs/` research) and existing implementations on the net. If something can be used the way its author meant, use it.
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
| AviUtl2 calls still missing (`obj.computeshader`, the built-in effects, …), following the references (AviUtl2's lua.txt, sashimono-edit) | `docs/internal/reports/aviutl/aviutl2/converter_plan.md`, `engine/community/aviutl/aviutl.cpp` | Medium–hard |
| TSL looks on the editor's shelves | `engine/community/three_shading_language_to_shelf/`, `docs/internal/reports/effects/tsl_collection.md` | Medium |

## Known gaps

- macOS on Apple silicon only.
- The engine (`libmotolii.dylib`) loads Homebrew's GStreamer and others, so a built `.app` does not run on another Mac as it is.
