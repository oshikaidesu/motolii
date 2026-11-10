# Testing

*How to run each kind of test in Motolii, what it covers, what CI runs, how to add a test, and the rule about what a test may assert.*

## Running the tests

Run these from the repository root unless a command says otherwise.

### Static checks (no build, safe at any time)

- Dart: `cd app && dart analyze lib`. A pass prints no errors.
- C++: `./engine/check_syntax.sh` runs `clang++ -fsyntax-only` on every source of ours with the flags CMake gives it, and writes nothing. A pass prints `ok: <count> sources`. Pass part of a path to check only the sources that contain it, for example `./engine/check_syntax.sh document/undo.cpp`.
- Paths: `python3 .githooks/path_check.py --all` prints every path a shelf file or a Markdown file names that does not exist. A pass prints nothing.

### Flutter tests (`app/test/`)

```
cd app && flutter test
```

A pass ends with `All tests passed!`. To run one file, name it: `flutter test test/widgets/number_format_test.dart`. Most files need no engine. `app/test/skin_folders_test.dart` skips its own-folder case unless `MOTOLII_OWN` points at an empty folder: `MOTOLII_OWN=$(mktemp -d) flutter test test/skin_folders_test.dart`. `app/test/accessibility_guidelines_test.dart` opens the real `Workspace` and needs `engine/out/libmotolii.dylib` (it is skipped when the library is missing), so it needs a built engine.

### Frame timing (needs a window)

```
cd app && FLUTTER_TEST_OUTPUTS_DIR=build/test_output flutter drive --profile -d macos \
  --driver=test_driver/frame_timing_driver.dart --target=integration_test/frame_timing_test.dart
```

This scrolls the Workspace timeline with 120 mouse-wheel notches and fails if any frame misses Flutter's build or raster budget (about 16 ms), or if no frame was drawn. A pass exits 0. The summary is written to `app/build/test_output/frame_timing.timeline_summary.json`. `flutter test` does not pick this up, because it lives in `app/integration_test/`.

### C++ unit tests

```
engine/build.sh test
```

Builds the engine, then runs ctest. C++ unit tests are files named `<name>_test.cpp` beside the code they test; CMake collects them into one GoogleTest binary (see the Tests block of [engine/CMakeLists.txt](../engine/CMakeLists.txt)). None exists yet.

### Picture comparison

See below. It is a build.

## What is covered

| Kind | Where | What it checks |
|---|---|---|
| Unit and widget | `app/test/skin`, `app/test/widgets`, `app/test/inspector`, `app/test/workspace` | Number and colour formatting, theme tokens, inspector state and parameter inference, key bindings, timeline painters, tool-panel easing, settings files, workspace state |
| Skin folders | `app/test/skin_folders_test.dart` | The skins in `shelves/skins` and the user's own folder all appear in View > Skin |
| Accessibility | `app/test/accessibility_guidelines_test.dart` | Flutter's tap-target size and label guidelines, text contrast, and that opening the app raises no layout exception |
| Frame timing | `app/integration_test/`, `app/test_driver/` | Timeline scrolling stays inside the frame budget |
| Pictures | `engine/drawings_unchanged.sh` | Every shelf recipe and motion draws the same as at an older commit |
| Static | analyzer, `check_syntax.sh`, `path_check.py` | Dart and C++ compile cleanly; documents name real paths |

Most files under `app/test/` pin what the code does today (their header comment says the expected values are what the code gave when written). They are characterization tests: they catch a change, and are not evidence that the behaviour is right.

## Picture comparison

`engine/drawings_unchanged.sh <old-commit>` builds the engine at `<old-commit>` in a separate worktree, then draws every recipe of the Create shelf and every motion of the Effects shelf (applied to the text MOTOLII) with that engine and with this checkout's, on a fresh document at 0.0, 0.7 and 1.9 seconds. Each pair of PNGs is compared byte for byte with `cmp`. It reads and writes nothing of the user's own: it uses an empty `MOTOLII_OWN` folder and temporary documents.

Use it after a change that can alter what is drawn (the engine, a shelf item, a shader). Do not use it after moving code. It is a build: it takes the machine's build lock (`engine/tools/build_lock.sh`) and takes minutes. `DRAWINGS_LIMIT=2` limits it to the first two of each kind, to see that it runs.

Output ends with `N of M matched`, then a line for each pair that `differs:` and each item that exists on one side only (named, not compared). Exit codes:

- 0: every compared picture matched.
- 1: some pictures differ, or the commit or the font was not found.
- 2: a call was refused, the engine stopped answering, or a picture was not made; the count does not stand.

## External requirements

Expected values come from the sources below, not from Motolii. Status is as last run on 2026-11-08, on macOS, without a window unless noted.

| Requirement | Source | What it checks | Status |
|---|---|---|---|
| Tap targets at least 48x48 (Android) | https://docs.flutter.dev/ui/accessibility/accessibility-testing and https://api.flutter.dev/flutter/flutter_test/meetsGuideline.html | `androidTapTargetGuideline` | Fails, 65 nodes |
| Tap targets at least 44x44 (iOS) | same | `iOSTapTargetGuideline` | Fails, 65 nodes |
| Tappable nodes have a semantic label | same | `labeledTapTargetGuideline` | Fails, 47 nodes |
| Text contrast | same | `textContrastGuideline` | Passes (weak evidence: the first screen only, drawn in the test font) |
| No rendering exception when the app opens | same | `takeException` count is 0 | Fails, 1 overflow (`RenderFlex overflowed by 9.9 pixels`) |
| Frame budget of about 16 ms at 60 fps while scrolling the timeline | https://docs.flutter.dev/cookbook/testing/integration/profiling | `traceAction` and `TimelineSummary` | Fails on the build budget (2 runs, raster budget met) |
| WCAG 2.2 SC 1.4.3 Contrast (Minimum) | https://www.w3.org/TR/WCAG22/#contrast-minimum | Not run; whether the Flutter threshold matches is unchecked | Reference only |
| WCAG 2.2 SC 2.5.8 Target Size (Minimum), 24x24 CSS px | https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html | Not run; closer to a mouse-driven desktop app than 48 and 44 | Reference only |
| Lint rules | https://pub.dev/packages/flutter_lints (included by `analysis_options.yaml`) | `flutter analyze` | Run by CI |

Reference only (no test runs these yet): the glTF-Validator and glTF Sample Assets from Khronos (https://github.com/KhronosGroup/glTF-Validator, https://github.com/KhronosGroup/glTF-Sample-Assets) for glTF loading; the ISF documentation (https://docs.isf.video) and the Vidvox shaders (https://github.com/Vidvox/ISF-Files) for ISF; the Lottie specification and JSON Schema (https://lottie.github.io/lottie-spec/latest/) and ThorVG's Lottie files (https://github.com/thorvg/thorvg/tree/main/test/res) for Lottie; the After Effects expression reference (https://ae-expressions.docsforadobe.dev) for expression names.

## How to add a test

- Dart: add `<name>_test.dart` under the matching folder of `app/test/` (widget and unit tests), or under `app/integration_test/` with a driver in `app/test_driver/` (tests that need a real window). Files a test writes go under `app/build/test_output/`.
- C++: add `<name>_test.cpp` beside the code it tests, in one of the folders listed in `engine/CMakeLists.txt`. CMake finds it by name; it needs GoogleTest.
- Pictures: no file to add; a new recipe or motion on a shelf is compared automatically.
- Follow the rule below.

## The rule for tests

A test's expected value must come from outside the code under test: a specification, a published sample, or a recorded picture a person approved. A test that only pins current behaviour is allowed if its first line says `characterization:`; it guards against change and is not evidence of correctness. A test must be seen failing before the fix it covers. Work is done when it is shown with something the user can see (a picture, the window, an exported file).

Tests written by the same hand that wrote the code tend to repeat its mistakes, which is why earlier self-written tests were removed on 2026-11-08.

## What CI runs

[.github/workflows/checks.yml](../.github/workflows/checks.yml) runs on every push and pull request, on Ubuntu with Flutter 3.47.2:

- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze --no-fatal-infos`
- `flutter test`
- `clang-format --dry-run --Werror` over the engine's own sources (clang-format 23.1.5, the root `.clang-format`)
- `python3 .githooks/path_check.py --all`

[.github/workflows/build.yml](../.github/workflows/build.yml) runs on pushes to main, pull requests that touch `engine/`, `shelves/`, `app/` or the `Brewfile`, and by hand, on macOS 15: `engine/build.sh test` (the build, then ctest), then `engine/edit.sh build.motolii` (a document opened by what was built). It runs no picture comparison.
