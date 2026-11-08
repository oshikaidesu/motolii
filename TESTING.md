# TESTING：外から来る要件だけを試験にする

## 原則

- 試験の「期待値」は、試験される側のコードの外にある（Flutter 公式のガイドライン、W3C の基準、標準規格）。
- 自作の試験は使い捨て。自作の期待値を守る試験は残さない（旧 `skin/book/test` `integration_test` `test_driver` `engine/check` は削除）。
- 失敗は UI を直す合図ではなく情報として記録する。ここでは通すために UI を変えていない。
- 置き場：`skin/book/external_test/`。

## 要件の一覧

| 要件 | 出所（取得して存在を確認） | 何を調べるか | 実行 | 状態 |
|---|---|---|---|---|
| 押せる所は 48x48 以上（Android） | https://docs.flutter.dev/ui/accessibility/accessibility-testing ・ https://api.flutter.dev/flutter/flutter_test/meetsGuideline.html | `androidTapTargetGuideline`（tap 可能な意味ノード） | 下記 A | 窓なしで実行済み：**失敗** 65 ノード |
| 押せる所は 44x44 以上（iOS） | 同上 | `iOSTapTargetGuideline` | 下記 A | 窓なしで実行済み：**失敗** 65 ノード |
| 押せる所に意味ラベルがある | 同上 | `labeledTapTargetGuideline` | 下記 A | 窓なしで実行済み：**失敗** 47 ノード |
| 文字のコントラスト | 同上 | `textContrastGuideline` | 下記 A | 窓なしで実行済み：**通過**（弱い証拠、下記） |
| 窓を開いたとき、描画の例外（レイアウトのはみ出し等）が出ない | 同上（フレームワーク自身の assertion を `takeException` で拾う） | 例外が 0 件 | 下記 A | 窓なしで実行済み：**失敗** 1 件 |
| WCAG 2.2 SC 1.4.3 Contrast (Minimum)：通常文字 4.5:1、大きい文字 3:1 | https://www.w3.org/TR/WCAG22/#contrast-minimum | 参照のみ。実行できる道具はまだ無い（`textContrastGuideline` の閾値が同じかは未確認） | — | 参照のみ（未実装） |
| WCAG 2.2 SC 2.5.8 Target Size (Minimum)：24x24 CSS px（例外あり） | https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html | 参照のみ。上の 48/44 は携帯の指向けで、マウス操作の desktop アプリにはこちらの 24 が近い | — | 参照のみ（未実装） |
| 静的解析：flutter_lints | https://pub.dev/packages/flutter_lints （flutter.dev 発行、6.0.0、`analysis_options.yaml` が include 済み） | 規約違反の lint | `cd skin/book && flutter analyze --no-pub` | このセッションでは未実行 |

実行 A：

```
cd skin/book && flutter test --no-pub external_test/accessibility_guidelines_test.dart
```

`external_test/` ごと流すと、別担当のフレーム時間の試験ファイルも拾う。あれは `flutter drive` 用なので `flutter test` では失敗する。

## 実行結果（2026-11-08、macOS、窓なし）

対象：実物の `Workspace`（`lib/workspace/workspace.dart`）を新しい空の文書で 1600x960 に開いた画面。エンジン（`engine/out/libmotolii.dylib`）は FFI で読み込めた。ライブラリが無い環境では `skip`。5 件中 1 件通過、4 件失敗。

- android 48x48：65 ノード。最初のメッセージ：`SemanticsNode#2 (150.6, 8.0, 174.6, 32.0) ... expected tap target size of at least Size(48.0, 48.0), but found Size(24.0, 24.0)`。次の `#3` も 24x24。`label: "1920 × 1080"` のノードは 124.0x20.0 で高さ不足。
- iOS 44x44：65 ノード（同じノードが並ぶ）。
- ラベル：47 ノード。最初は `#2` と `#3`（上と同じ 24x24 の押せる所）。`expected tappable node to have semantic label, but none was found`。
- コントラスト：通過。ただし文字は試験用の Ahem 書体の塗りつぶしで描かれ（Mac の書体を読み込んでいない）、最初の画面だけで、ポップアップやホバーは開いていない。通過は「見た範囲では違反なし」。
- はみ出し：`A RenderFlex overflowed by 9.9 pixels on the right.` `lib/workspace/timeline_header.dart:228`（幅 66.0 の Row）。

## フレーム時間（窓が要る：未実行）

| Requirement | Verified source | What it checks | How to run | Status |
|---|---|---|---|---|
| Flutter's frame budget (about 16 ms a frame, 60 fps) while the Workspace timeline is scrolled | https://docs.flutter.dev/cookbook/testing/integration/profiling ("Measure performance with an integration test") | `traceAction` + `TimelineSummary` over 120 mouse-wheel notches on the timeline (40 shapes, vertical and sideways); fails if any frame misses the build or raster budget, or none were drawn (`skin/book/external_test/frame_timing_test.dart`, `frame_timing_driver.dart`) | `cd skin/book && flutter drive --profile -d macos --driver=external_test/frame_timing_driver.dart --target=external_test/frame_timing_test.dart` | unrun (needs a window) |

## エンジン（参照のみ：まだ繋いでいない）

| requirement | verified URL | what it checks | how it could run against Motolii's engine | status |
|---|---|---|---|---|
| glTF 2.0 structural validity of every .glb/.gltf the engine loads (Khronos glTF-Validator) | https://github.com/KhronosGroup/glTF-Validator | Checks an asset against the glTF 2.0 spec; writes a JSON report of issues; exit code is non-zero when errors are found | Build the CLI (Dart SDK, `dart pub get`, `dart run grinder exe`, giving `build/bin/gltf_validator`). Run `gltf_validator -o <file>.glb` on each engine input, or pass a directory to validate all .gltf/.glb in it. Pass if exit code is 0 | reference only, not wired |
| glTF loader acceptance across the format's feature range (Khronos glTF Sample Assets) | https://github.com/KhronosGroup/glTF-Sample-Assets | Curated glTF 2.0 sample models under `Models/`, offered as .gltf (separate resources), embedded .gltf and binary .glb; listings such as `Models-testing.md` and `Models-core.md` | Clone the repo; feed each model's glTF-Binary (.glb) file to the engine's glTF load path and require load success plus a non-empty render; run the Validator above over the same set to separate "bad asset" from "engine bug" | reference only, not wired |
| ISF header and uniform semantics (ISF documentation) | https://docs.isf.video (JSON header reference: https://docs.isf.video/ref_json.html) | VIDVOX's ISF docs: GLSL shader plus a JSON header comment; the reference page documents ISFVSN, VSN, DESCRIPTION, CATEGORIES, INPUTS, PASSES, IMPORTED | Use the reference as the oracle for accepted header keys and input types: for each documented key, make a minimal .fs and require the engine to parse it with the documented meaning; a key the engine does not know must be reported, not silently dropped | reference only, not wired |
| ISF real-world shader corpus (Vidvox ISF-Files) | https://github.com/Vidvox/ISF-Files | "ISF generators and filters" conforming to ISF 2.0, just over two hundred shaders in the `ISF` folder, MIT licence | Clone the repo; run every `ISF/*.fs` through the engine's ISF loader/compiler and count compile or parse failures; a file that loads must also render one frame without error | reference only, not wired |
| Lottie JSON structure (Lottie Animation Format spec and its JSON Schema) | https://lottie.github.io/lottie-spec/latest/ (schema file: https://lottie.github.io/lottie-spec/latest/lottie.schema.json) | Official Lottie spec; its machine-readable JSON Schema (draft 2020-12) defines the document structure | Validate any Lottie JSON the engine reads or writes against `lottie.schema.json` with a JSON Schema 2020-12 validator, e.g. `npx ajv-cli validate --spec=draft2020 -s lottie.schema.json -d <anim>.json` (tool choice not verified here) | reference only, not wired |
| Lottie rendering conformance files (ThorVG test resources) | https://github.com/thorvg/thorvg/tree/main/test/res (runner source: https://github.com/thorvg/thorvg/tree/main/test/src, `testLottie.cpp`) | ThorVG's own test inputs: Lottie animations stored as `.lot` files (test.lot, test2.lot to test14.lot, slot.lot, tween.lot, segment.lot, embedded_font.lot) plus `audio_layer.json` and `resolver.json`, and a Lottie test source file | Copy the `.lot` files (they are JSON, so rename to `.json` if the loader keys on the extension) and load each through the engine's Lottie path, require no load error and one rendered frame; ThorVG is already the engine's 2D renderer, so frames can also be diffed against ThorVG's own output | reference only, not wired |
| After Effects expression names and meanings (AE Expression Reference mirror) | https://ae-expressions.docsforadobe.dev | Community-maintained After Effects expression reference: General (Global, Vector Math, Other Math, Interpolation), Objects, Layer, Text; each entry gives attributes, methods, return types, sometimes examples | Treat it as the external definition: extract every documented global/function name into a list and, for each, run a one-line recipe expression through the engine's expression runner; any name that errors as undefined, or returns a different type than documented, is a gap | reference only, not wired |

### 確認できなかった物
- Lottie spec root https://lottie.github.io/lottie-spec/ returns only a redirect to `latest/`; the verified URL is the `latest/` page.
- https://ae-expressions.docsforadobe.dev/expression-language.html returned 404, so only the site root is cited.
- `Models/model-index.json` in glTF-Sample-Assets is not confirmed on the repo page, so it is not relied on above.
- docs.isf.video does not call itself "the official specification" on its page, but it carries VIDVOX copyright; treated as the vendor's documentation.
- ThorVG: `test/resources` does not exist (404); the real folder is `test/res`. The `.lot` extension (not `.json`) means the "Lottie conformance" claim rests on file listing only, not on opening a file.
- The ajv-cli command is a suggestion; it was not checked.
