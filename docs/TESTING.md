# Testing

How to run every test suite in Motolii, what CI checks, and how to write new tests.

## Quick reference

Run commands from the repository root unless noted otherwise.

### Static checks (no build required)

- **Dart:** `cd app && dart analyze lib`
- **C++:** `./engine/check_syntax.sh` runs `clang++ -fsyntax-only` with CMake's flags (pass a path fragment to scope it, e.g. `./engine/check_syntax.sh document/undo.cpp`).
- **Markdown & shelf paths:** `python3 .githooks/path_check.py --all` checks that every path referenced in docs and shelf files exists.

### Flutter unit & widget tests (`app/test/`)

```bash
cd app && flutter test
```

By default, `flutter test` runs only **specification-backed tests** (tests whose expected values come from external specifications, published fixtures, or explicit calculations). Characterization tests that pin current behavior call `skipUnlessEveryTest()` from [`app/test/main_tests_only.dart`](../app/test/main_tests_only.dart) and are skipped unless explicitly enabled:

```bash
cd app && flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes
```

> Avoid `--run-skipped`, which also runs the user-folder test in `skin_folders_test.dart` against your real `~/.motolii`. To test it safely, pass a temp folder: `MOTOLII_OWN=$(mktemp -d) flutter test test/skin_folders_test.dart`.

Most Flutter tests require no compiled engine; `app/test/accessibility_guidelines_test.dart` opens the real `Workspace` and is skipped if `engine/out/libmotolii.dylib` is not built.

### Frame timing (requires a macOS GUI session)

```bash
cd app && FLUTTER_TEST_OUTPUTS_DIR=build/test_output flutter drive --profile -d macos \
  --driver=test_driver/frame_timing_driver.dart --target=integration_test/frame_timing_test.dart
```

Scrolls the Timeline by 120 wheel notches and fails if any frame exceeds the ~16 ms 60 fps budget. Writes `app/build/test_output/frame_timing.timeline_summary.json`.

### C++ unit tests (`ctest`)

```bash
engine/build.sh test
```

Builds the engine and runs all GoogleTest targets (`<name>_test.cpp` files discovered by [`engine/CMakeLists.txt`](../engine/CMakeLists.txt)). To build and run a single module's tests from `engine/`:

```bash
cmake --build out/cmake --target motolii_motion_test && ctest --test-dir out/cmake -R '^Easing'
```

The Rust CSS adapter has standalone tests not invoked by CMake:

```bash
cargo test --release --manifest-path engine/community/css/Cargo.toml --target-dir engine/out/cargo_test
```

### Snapshot diff verification

```bash
engine/snapshot_parts_check.sh
```

Drives `edit.sh` on a temporary project under `engine/out/` and verifies incremental snapshot updates match the [`app/BRIDGE.md`](app/BRIDGE.md) contract (full snapshot initially, targeted deltas on edits, empty when unchanged). Runs in CI.

### Randomized edit fuzzing

```bash
engine/random_edits_check.sh
SEED=40 STEPS=1000 RUNS=10 engine/random_edits_check.sh
```

Applies random sequences of edits, drags, and undo/redo steps through `edit.sh` under `engine/out/random_edits/`, checking after every step that:
1. Incremental snapshots match a full rebuild (`snapshot check`).
2. Sequential partial reads reconstruct the complete snapshot.

Failures are automatically minimized into a replayable `seed_N.calls` file. CI runs seeds 1–3 for 200 steps each.

### Visual regression comparison (`drawings_unchanged.sh`)

```bash
engine/drawings_unchanged.sh <old-commit>
```

Builds `<old-commit>` in a separate worktree, renders every Create recipe and Effects motion at `0.0s`, `0.7s`, and `1.9s` with an isolated `MOTOLII_OWN`, and compares PNG outputs byte-for-byte with `cmp`. Cached baselines live in `engine/out/drawings/`; pass `DRAWINGS_LIMIT=2` for a quick smoke check.

Exit codes: `0` = all matched, `1` = differences or missing commit/font, `2` = engine error or refused call.

## Test coverage summary

| Suite | Location | Coverage |
|---|---|---|
| Flutter unit & widget | `app/test/{skin,widgets,inspector,workspace}` | Formatting, theme tokens, inspector inference, keybindings, timeline painters, easing, settings, cards, menus, viewport |
| Golden snapshots | `app/test/golden/` | Code field, drop overlay, render dialog, saved progress |
| Skin loading | `app/test/skin_folders_test.dart` | Bundled and user `skins/` discovery |
| Accessibility | `app/test/accessibility_guidelines_test.dart` | Tap target size/labels, text contrast, zero layout exceptions on startup |
| Frame timing | `app/integration_test/`, `app/test_driver/` | 60 fps Timeline scrolling budget |
| C++ unit tests | `engine/**/*_test.cpp` | Easing, script headers, shelf recipes, AE plugin probing, search paths, video encoder, Jolt rigid bodies, AE/CSS params, pixels, cards, relations, audio, subtitles |
| Visual regression | `engine/drawings_unchanged.sh` | Byte-identical renders against a baseline commit |
| Static checks | `dart analyze`, `check_syntax.sh`, `path_check.py` | Clean compilation and valid path references |

## External guidelines & benchmarks

Tracked against external standards (last full check: 2026-11-08, macOS):

| Standard | Reference | Check | Recorded status |
|---|---|---|---|
| Tap targets ≥ 48×48 (Android) | [Flutter Accessibility Testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing) | `androidTapTargetGuideline` | Failing (65 nodes) |
| Tap targets ≥ 44×44 (iOS) | Same | `iOSTapTargetGuideline` | Failing (65 nodes) |
| Semantic labels on tappables | Same | `labeledTapTargetGuideline` | Failing (47 nodes) |
| Text contrast | Same | `textContrastGuideline` | Passing (initial screen only) |
| Zero startup layout exceptions | Same | `takeException == 0` | Failing (1 overflow) |
| 60 fps timeline scroll (~16 ms) | [Flutter Integration Profiling](https://docs.flutter.dev/cookbook/testing/integration/profiling) | `TimelineSummary` | Failing build budget (raster met) |
| WCAG 2.2 SC 1.4.3 / SC 2.5.8 | [W3C WCAG 2.2](https://www.w3.org/TR/WCAG22/) | Reference only | Not yet automated |
| Dart lints | [`flutter_lints`](https://pub.dev/packages/flutter_lints) | `flutter analyze` | Enforced in CI |

Additional external references (not yet automated): [glTF-Validator](https://github.com/KhronosGroup/glTF-Validator), [glTF-Sample-Assets](https://github.com/KhronosGroup/glTF-Sample-Assets), [ISF docs](https://docs.isf.video), [Vidvox/ISF-Files](https://github.com/Vidvox/ISF-Files), [Lottie Spec](https://lottie.github.io/lottie-spec/latest/), [ThorVG test assets](https://github.com/thorvg/thorvg/tree/main/test/res), and [After Effects Expression Reference](https://ae-expressions.docsforadobe.dev).

## Adding tests & test policy

- **Dart:** Place `<name>_test.dart` under the matching folder in `app/test/` (or `app/integration_test/` with a driver in `app/test_driver/`).
- **C++:** Place `<name>_test.cpp` next to the module it tests and ensure the folder is listed in `engine/CMakeLists.txt`.
- **Policy:** Expected values in specification tests must derive from an external source (a spec, upstream sample, or human-approved golden), never simply copied from the implementation under test. Characterization tests that pin existing behavior must be labeled `characterization:` on line 1. Always verify a regression test fails before applying the fix.

## CI workflows

- **[`.github/workflows/checks.yml`](../.github/workflows/checks.yml)** (Ubuntu, Flutter 3.50.0, every push & PR):
  - `dart format --output=none --set-exit-if-changed .`
  - `flutter analyze`
  - `dart_code_linter` banned-import check (forbids Material / Cupertino imports)
  - `flutter test` (main specification tests)
  - `clang-format --dry-run --Werror` (v23.1.5)
  - `ast-grep scan` (`app/tool/rules/`)
  - `jscpd` duplicate-code check on `app/lib/`
  - `python3 .githooks/path_check.py --all`
- **[`.github/workflows/build.yml`](../.github/workflows/build.yml)** (macOS 15, pushes/PRs touching `engine/`, `shelves/`, `app/`, or `Brewfile`):
  - `engine/build.sh test`
  - `engine/edit.sh build.motolii` smoke test
