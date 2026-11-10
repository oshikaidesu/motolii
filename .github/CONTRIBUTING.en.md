# Contributing

[日本語](CONTRIBUTING.md)

## What you can do

- **Issues**: bugs, a build that stopped, or "I want to use this expression" (a URL and what is good about it). There are templates. English or Japanese.
- **Pull requests**: welcome. Motolii is dual licensed under Apache-2.0 or MIT; unless you explicitly state otherwise, what you send is under the same two licences.
- **Authors of bundled works**: if you want the way your work is bundled changed, or it removed, open an issue and it will be done ([`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md), Japanese).

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Security problems go to the Security tab, not to issues ([`.github/SECURITY.md`](SECURITY.md)).

## Building

As in [`README.en.md`](../README.en.md) ("Try it"). If you will commit, once in your clone:

```bash
git config core.hooksPath .githooks
```

Without it, almost the same checks still run on every push and pull request on GitHub (`.github/workflows/checks.yml`); with it, they stop you at commit time instead of on GitHub.

How the code is laid out: [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) and [`engine/README.md`](../engine/README.md) (which files the current build uses; the rest are earlier probes). Both are in Japanese, with an English summary at the top.

Words in the code and the docs are the ones After Effects, Filament, Flutter and Blender use: app, engine, layer, project, preview (`Stage` in the code). Only the left tabs have their own name, "shelf" (棚, as in Blender's Asset Shelf). No new coinages.

## Checks that run at a commit

On every commit, `.githooks/pre-commit` (a merge commit gets the same from `pre-merge-commit`) and `.githooks/commit-msg` run. When one refuses, the last line says `refused by .githooks/<file>`. How to fix each one: [`.githooks/README.md`](../.githooks/README.md) (Japanese). To run one by hand, from the root of the repository: `python3 .githooks/<file>.py`.

| Check | What it refuses | At a commit | On GitHub (checks.yml) |
|---|---|---|---|
| `size_check.py` | A file of our own over 500 lines; a numbered name such as `name_2.dart`. Ours means Dart in `app/lib`, C++ and `.js` in `engine/`, `.js` in `shelves/` (not other people's code in `engine/third_party/` and `shelves/aviutl_scripts/`). Files already over are listed in `over_500.txt` and may not grow | Staged files | All files |
| `layout_check.py` | Where things go (AGENTS.md 「構成の目標」): stray files at the root, a folder missing from its entrance README's table, `out/` or `build/` in git, numbered or letter-plus-number names, more than 40 files of our own in one folder. A Japanese `.md` with no `.en.md`, or with no English summary | Staged files | All files |
| `path_check.py` | A path a shelf file or one of our `.md` names (`import`, image, link) that leads nowhere | Staged shelf files (all of them when something is deleted or moved) | All files |
| `card_check.py` | An Inspector card drawn by hand in Dart (a value name written as a string). Cards are declared in the engine's `card_table.h` | Staged files | All files |
| `reach_check.py` | What the app cannot reach: a `motolii_*` C call nothing calls, a public class in `app/lib` nothing uses | Staged files | All files |
| `format_check.py` | Dart not as `dart format` leaves it | Staged Dart; skipped if `dart` is not on the PATH | **Not run** |
| `word_check.py` | Dropped house words (`docs/internal/notes/rename_words.md`). For now it only reports counts and refuses nothing | Added lines | All files (refuses nothing) |
| `shape_check.sh` | [ast-grep](https://ast-grep.github.io/) refuses the shapes in `.githooks/rules/`: hand-written presses, hovers, overlays and painters in Dart, a C++ branch that compares a layer kind by name. A staged file may not hold more refused shapes than it held at HEAD | Staged files; skipped if ast-grep is not installed | All files (CI installs ast-grep) |
| `subject_check.py` | A subject (first line) over 72 characters | The commit being written | Every commit a push or pull request brings |

`pre-commit` also prints one line first, `debt: ...`. It refuses nothing. It shows what the rules still let stand: the number of files over 500 lines (`over_500.txt`), the number of paths allowed to lead nowhere (`path_check_allow.txt`), and the lines of hand-written Dart. It is there so you can see whether a commit lowers them.

`git commit --no-verify` skips the local checks, but GitHub fails the same ones (all but `format_check.py`, which GitHub does not run).

To try things yourself:

- Dart: `cd app && dart analyze lib`
- C++: `./engine/check_syntax.sh` (checks syntax only, writes nothing)

The full build runs on GitHub Actions in `.github/workflows/build.yml` (on an Apple silicon Mac, as the README says, then `flutter analyze`; on pushes to main and pull requests that touch `engine/`, `shelves/`, `app/` or `Brewfile`, and by hand from the Actions tab). There are no self-written tests (they were removed on 2026-11-08: the same hands wrote the code and the tests); the external requirements are in [`docs/TESTING.md`](../docs/TESTING.md).

One more rule applies only when an AI agent edits through Claude Code. `.claude/hooks/own_code_sign.py` runs before the agent's edit and stops an edit that would lengthen a file of our own (Dart in `app/lib`, C++ in `engine/`) until it has looked for what already exists (`python3 .githooks/what_exists.py --sketch dart|engine FILE < SKETCH`). Neither a commit nor GitHub checks it, and it does not concern a person editing by hand.

## Rules

1. **Look before you write.** Look at the tree (`engine/` the product, `app/` the app, `docs/` research) and existing implementations on the net. If something can be used the way its author meant, use it. To search what already exists by words: `python3 .githooks/what_exists.py wave copies`.
2. **One job a file, 500 lines at most.** Split by what each part is for and name it so (a bare number like `_2` is refused). Experiments stay on your own branch; main holds only what the app uses.
3. **Commit messages.**
   - The **subject** (first line) is 72 characters at most and says what changed. For example `Remove the unused Foo card`, `Fix Y in Z`.
   - After one blank line, the **body** says why it changed, what was checked and what is not done yet.
   - If you borrowed something, say where from (URL, version or commit) in the body. Example: `git show d46f69cac`.
   - A longer subject is stopped by `.githooks/commit-msg`, and GitHub fails the pull request. The text you wrote is kept: `git commit -e -F <file>`.
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
