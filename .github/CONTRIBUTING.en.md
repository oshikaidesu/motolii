# Contributing

[日本語](CONTRIBUTING.md)

## What you can do

- **Issues**: bugs, a build that stopped, or "I want to use this look" (a URL and what is good about it). There are templates. English or Japanese.
- **Pull requests**: welcome. Motolii is dual licensed under Apache-2.0 or MIT; unless you explicitly state otherwise, what you send is under the same two licences.
- **Authors of bundled works**: if you want the way your work is bundled changed, or it removed, open an issue and it will be done ([`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md), Japanese).

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Security problems go to the Security tab, not to issues ([`.github/SECURITY.md`](SECURITY.md)).

## Building

As in [`README.en.md`](../README.en.md) ("Try it"). If you will commit, once in your clone:

```bash
git config core.hooksPath .githooks
```

How the code is laid out: [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) and [`engine/README.md`](../engine/README.md) (which files the current build uses; the rest are earlier probes). Both are in Japanese, with an English summary at the top.

Words in the code and the ledger: the UI is "window" (窓), the engine "the inside" (中身), a layer "thing" (物), a project file "document" (書類), the Stage "scene" (場面), and a tab of the left panel "shelf" (棚).

## Checks

| What | Command | When it holds |
|---|---|---|
| The ledger (rule 2 below) | `python3 .githooks/assets_check.py` | `ASSETS.md covers all … files` |
| The UI's code | `cd skin/book && flutter analyze lib` | No errors (100 notices today) |

GitHub Actions runs the ledger check on every push and pull request (`.github/workflows/assets.yml`; it only reports, it does not block a pull request). The whole build runs in `.github/workflows/build.yml` (on an Apple silicon Mac, built as the README says, then `flutter analyze`; on pull requests that touch the code, and by hand from the Actions tab). There are no self-written tests (they were removed on 2026-11-08: the same hands wrote the code and the tests); the external requirements are in [`docs/TESTING.md`](../docs/TESTING.md).

## Rules

1. **Look before you write.** Search [`ASSETS.md`](../ASSETS.md) (the ledger of what exists) and existing implementations on the net. If something can be used the way its author meant, use it.
2. **A new file gets a line in the ledger.** `ASSETS.md` says what exists and how far it was checked. The pre-commit hook stops a commit whose files have no place there. Add a row, or add the file's place to an existing row (places in backticks; a folder covers everything in it). **If that is too much, commit with `git commit --no-verify` and say so in the pull request; the maintainer will add it when merging.** The ledger is in Japanese; English in your row is fine.
3. **Say where things came from.** In the commit or pull request: what was borrowed from where (URL, version or commit), what was checked and what is not done yet. Example: `git show d46f69cac`. Keep the first line (the subject) to about 72 characters and put the details after a blank line (git's convention; much of the history so far has long subjects, but from now on).
4. **Bundling other people's work.**
   - Keep the author's folder as unchanged as possible, with their licence text (`LICENSE`) and where it came from (`SOURCE.txt`: name and author / licence / from / page) beside it.
   - Work whose author publishes no licence text is not bundled; fetch it from the author at build time instead (`engine/midi_roll.sh` is an example).
   - Changes to upstream code are kept as patches, applied to a pinned upstream at build time (`engine/dawn_probe/tvg_on_dawn.sh` is an example).
   - Add a row to [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

## Good first tasks

| What | Where to start | Difficulty |
|---|---|---|
| An `.app` you can hand out: put the Homebrew libraries the engine loads (GStreamer, glib, SQLite, LuaJIT, QuickJS, and ffmpeg for writing) inside the `.app`, with [dylibbundler](https://github.com/auriamg/macdylibbundler) or GStreamer's macOS framework | `engine/edit.sh`, `skin/book/macos/` | Medium |
| AviUtl2 calls still missing (`obj.computeshader`, the built-in effects, …), following the references (AviUtl2's lua.txt, sashimono-edit) | `docs/reports/aviutl2/converter_plan.md`, `engine/aviutl.cpp` | Medium–hard |
| TSL looks on the editor's shelves | `engine/tsl/`, `docs/reports/tsl_collection.md` | Medium |
| English beside the headings of `ASSETS.md` | `ASSETS.md` | Easy |

## Known gaps

- macOS on Apple silicon only.
- The engine (`libmotolii.dylib`) loads Homebrew's GStreamer and others, so a built `.app` does not run on another Mac as it is.
- `engine/` mixes the current engine with earlier probes at one level; [`engine/README.md`](../engine/README.md) lists which files the current build uses.
