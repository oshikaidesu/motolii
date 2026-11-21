# Contributing to Motolii

[日本語](CONTRIBUTING.ja.md)

## Ways to contribute

- **Issues:** Report bugs, build failures, or suggest creative formats/examples to support (include a URL and what makes it useful). Issue templates are available in English and Japanese.
- **Pull requests:** Welcome! Motolii is dual-licensed under Apache-2.0 or MIT; unless you explicitly state otherwise, your contributions are accepted under the same dual license.
- **Authors of bundled works:** If you want attribution updated or your work removed from the repository, open an issue and we will update or remove it promptly (see [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md)).

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Report security vulnerabilities through the GitHub Security tab rather than public issues (see [`.github/SECURITY.md`](SECURITY.md)).

## Development setup

Follow the build steps in [`README.md`](../README.md#build-and-run) (detailed troubleshooting is in the [build guide](../docs/archive/using/guide.md)). Enable the pre-commit formatting hook once per clone:

```bash
git config core.hooksPath .githooks
```

Codebase overviews: [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md), [`engine/README.md`](../engine/README.md), and [`app/README.md`](../app/README.md).

Use standard terminology from After Effects, Filament, Flutter, and Blender: app, engine, layer, project, preview (`Stage` in code), and shelf (for the left-side asset panels, following Blender's Asset Shelf). Avoid inventing custom jargon.

## Running checks

Run these locally before opening a pull request — CI runs the same suite on every push and PR (`.github/workflows/checks.yml`):

```bash
cd app && dart format . && flutter analyze && flutter test
```

For C++ engine changes:
- `./engine/check_syntax.sh` — fast syntax check without building
- `engine/build.sh` — incremental engine build
- `engine/build.sh test` — build and run C++ unit tests (`ctest`)

Full builds run on GitHub Actions (`.github/workflows/build.yml`, Apple Silicon macOS) on pushes/PRs touching `engine/`, `shelves/`, `app/`, or `Brewfile`. See [`docs/TESTING.md`](../docs/TESTING.md) for testing details.

## Engineering philosophy

**Custom code is long-term debt.** Prefer reusing well-tested upstream implementations in their native form rather than reimplementing them. Bundle third-party works unmodified with their license and source metadata, keep upstream modifications isolated as build-time `.patch` files, and cite references in every commit.

## Design principles

These principles are non-negotiable; changes violating them will not be merged. AI contributors follow the same principles in [`AGENTS.md`](../AGENTS.md).

1. **Run web expressions natively — don't reimplement them.** Pasted After Effects expressions, Cavalry scripts, p5.js sketches, and shaders run via their real runtimes rather than custom C++ replicas.
2. **Never hardcode arbitrary parameter limits.** Slider ranges are for display ergonomics and never reject typed values outside the range. Any strict limit must cite an upstream specification.
3. **No embedded webviews.** Visual inspectors read directly from source code and write edits back to that code — never maintain a second shadow copy of settings.
4. **Solve small tasks with existing Motolii mechanisms.** Don't introduce new frameworks or dependencies when an existing pattern already solves the problem.
5. **Keep Dart strictly focused on presentation.** Delegate input primitives, overlays, selection, and sliders to Flutter / `naked_ui` rather than rewriting them. The Inspector's effect card (`ValuesCard`) is the single source of truth; fold duplicate custom cards, chips, switches, and number fields into it rather than maintaining parallel copies.

## Contribution guidelines

1. **Search before building.** Check `engine/`, `app/`, `shelves/`, and existing OSS before writing new code.
2. **One responsibility per file.** Keep modules small and clearly named; keep experiments on feature branches and merge only production code to `main`.
3. **Commit messages:**
   - Subject line: ≤ 72 characters summarizing what changed (e.g. `fix(inspector): preserve focus on slider drag`).
   - Body (after a blank line): explain *why*, what was verified, and any remaining limitations.
   - Cite upstream sources (URL, version, or commit SHA) for borrowed code or algorithms.
4. **Adding third-party works:**
   - Keep the author's folder structure unmodified with `LICENSE` and `SOURCE.txt` (`author`, `license`, `from`, `page`).
   - Never bundle works published without explicit license text — fetch them at build time instead (see `engine/deps/midi_roll.sh`).
   - Keep patches to upstream dependencies in `engine/deps/patches/<library>/` applied at build time (see `engine/deps/thorvg.sh`).
   - Update [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

## Good first tasks

| Task | Starting points | Difficulty |
|---|---|---|
| Redistributable macOS `.app` bundle: package Homebrew dynamic libraries (GStreamer, GLib, SQLite, LuaJIT, QuickJS, FFmpeg) inside the `.app` using [dylibbundler](https://github.com/auriamg/macdylibbundler) or GStreamer's macOS framework | `engine/edit.sh`, `app/macos/` | Medium |
| Implement remaining AviUtl2 script APIs (`obj.computeshader`, built-in effects, etc.) following AviUtl2's lua.txt and `sashimono-edit` | `docs/archive/design/aviutl2_converter_plan.md`, `engine/community/aviutl/aviutl.cpp` | Medium–Hard |
| Expand TSL effects on the Effects shelf | `engine/community/three_shading_language_to_shelf/`, `docs/archive/design/tsl_collection.md` | Medium |

## Known limitations

- Verified only on Apple Silicon macOS; Windows and Linux builds are not yet verified.
- `libmotolii.dylib` dynamically links Homebrew libraries, so built `.app` bundles are not yet portable across machines.
