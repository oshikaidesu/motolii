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

## フレーム時間（窓が要る：2026-11-08 実行、不通過）

| Requirement | Verified source | What it checks | How to run | Status |
|---|---|---|---|---|
| Flutter's frame budget (about 16 ms a frame, 60 fps) while the Workspace timeline is scrolled | https://docs.flutter.dev/cookbook/testing/integration/profiling ("Measure performance with an integration test") | `traceAction` + `TimelineSummary` over 120 mouse-wheel notches on the timeline (40 shapes, vertical and sideways); fails if any frame misses the build or raster budget, or none were drawn (`skin/book/external_test/frame_timing_test.dart`, `frame_timing_driver.dart`) | `cd skin/book && flutter drive --profile -d macos --driver=external_test/frame_timing_driver.dart --target=external_test/frame_timing_test.dart` | FAIL on build budget (ran 2026-11-08, 2 runs; raster budget met) |

結果（2026-11-08、Apple M4、macOS profile ビルドの実窓、2 回流した。`flutter drive` は両回とも exit 1）：テスト本体は通過（期待値を持たない）、ドライバーの予算判定が落ちた。build（UI スレッド）が 16 ms を超えたコマがある。raster は両回とも 0 コマ超過。

| 項目 | 1 回目 | 2 回目 |
|---|---|---|
| frame_count | 30 | 29 |
| average_frame_build_time_millis | 15.44 | 13.55 |
| worst_frame_build_time_millis | 25.27 | 22.23 |
| missed_frame_build_budget_count | 11 | 3 |
| average_frame_rasterizer_time_millis | 3.89 | 3.18 |
| worst_frame_rasterizer_time_millis | 5.03 | 5.00 |
| missed_frame_rasterizer_budget_count | 0 | 0 |

- 平均の build が 13.5〜15.4 ms で、予算 16 ms すれすれ。余裕がなく、超過の回数は回ごとにばらつく（11 と 3）。数値は `skin/book/build/frame_timing.timeline_summary.json`（毎回上書き）。
- 注意：ホイール 120 ノッチに対して記録されたコマは 29〜30（1 コマに約 4 回分）。スクロールで実際に画面が動いたかは、試験が確かめていない（期待値なし）。ログに `integration_test plugin was not detected` の警告が出るが、結果は `responseDataCallback` に届いた。
- 試験ファイル・`lib/`・エンジンは変更していない。

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

## 実行結果：エンジン側の外の基準（2026-11-08）

`engine/out/edit_wgpu`（ビルド済み、`BACKEND=webgpu`）を `cd engine/out/wgpu_kit` から、ファイルごとに新しい文書で1回ずつ走らせた。1枚目の絵は `at 0.5`（ISF は `at` なし）の `still` で、「空白でない」は PNG（1080x1920）を読んで黒（0,0,0）でない画素を数えたもの。拒否は `NOT done: ...` の行、落ちは終了コードが 0 でないこと。`edit.sh` は走らせていない（ライブラリを作り直すため）。

### Lottie

| corpus | source URL | files | loaded | failed | notes |
|---|---|---|---|---|---|
| ThorVG `test/resources` の `.lot`（直接 `add picture`、改名なし） | https://github.com/thorvg/thorvg/tree/main/test/res（手元は `engine/third_party/thorvg_src/test/resources`） | 20 | 20 | 0 | 20 本とも空白でない |
| ThorVG `test/resources` の `.json`（poc1, poc2, resolver, audio_layer） | 同上 | 4 | 4 | 0 拒否・0 落ち | 空白でないのは audio_layer のみ。poc1・poc2・resolver は空白 |
| ThorVG example `res/lottie/*.json`（直下） | https://github.com/thorvg/thorvg/tree/main/src/examples/resources/lottie（手元は `engine/third_party/thorvg_example/res/lottie`） | 103 | 103 | 0 拒否・0 落ち | 102 本が空白でない、1 本（isometric）が 0.5 秒で空白 |
| 同 `expressions/` | 同上 | 31 | 31 | 0 拒否・0 落ち | 29 本が空白でない、2 本（24243, loopOut）が空白 |
| 同 `extensions/`（slot・resolver・audio・spin） | 同上 | 19 | 19 | 0 拒否・0 落ち | 16 本が空白でない、3 本（resolver1, resolver2, slot11）が空白 |
| 合計 | | 177 | 177（`NOT done` 0 行） | 拒否 0・落ち 0 | 空白でない 168、空白 9。空白でない画素数は最小 1,970・中央 78,524・最大 635,084 |

空白だった 9 本（`add picture` は `done` を返したのに 0.5 秒の絵が黒だけ。0.0・0.2・1.0 秒でも撮り直した）：
- 0.0・0.2・1.0 秒でも空白：`expressions/24243.json`、`expressions/loopOut.json`、`extensions/resolver1.json`、`extensions/resolver2.json`、`extensions/slot11.json`、`test/resources/poc1.json`、`test/resources/poc2.json`、`test/resources/resolver.json`（8 本）。
- `isometric.json` は 0.5 秒だけ空白で、0.0 秒は 2,675 画素・0.2 秒は 18,181 画素・1.0 秒は 2,675 画素（0.5 秒の空白が本当に絵の中身なのか、描き損ねなのかは未確認）。
- poc1・poc2 は 1 層の欠けた JSON（ThorVG の読み込み耐性の試験入力）で、描くものが無いのが正しい可能性が高い。resolver 系は外の画像や文字を取りに行く試験入力で、取りに行く所が無い。24243・loopOut・slot11 が空白なのは未調査（式の対応不足か、元から何も描かない文書かは分けていない）。
- 引っかかる点：絵が出なかったのに、エンジンはどれにも拒否を返さず `add: done` と言う。「読めなかった」と「空白の絵」を呼び出し側が区別できない。

### ISF（Vidvox ISF-Files）

エンジンの `effect <thing> <name>` は、棚の `.fs` を1本も受け付けない（`effect 1 3d Rotate` は `NOT done: no effect is called 3d Rotate`。`doc_effect` が見るのは `doc_effects` の内蔵の効果だけ）。そのため棚の `.fs` は `hold 1` → `carry effect <file>` → `still`（絵は `engine/fx_sample.jpg`）で通した。`carry effect` は「持っている物の上に見せるだけで、置かない」呼び出し。`let_go 1` の後は元の絵に戻る（置いた後に残るかは未確認）。

| corpus | source URL | files | loaded | failed | notes |
|---|---|---|---|---|---|
| `engine/effects/*.fs` のうち Vidvox ISF-Files（全数） | https://github.com/Vidvox/ISF-Files | 318 | 318 | 拒否 0・落ち 0 | 318 本とも、効果なしの絵と画素が変わる。空白は 10 本 |

- 対象の決め方：git で追跡している `.fs` 419 本から、`CREDIT` が Sashimono（95）・ossia score（3）・pixi-filters（1）・gl-chromakey（1）・IMIMOT（1）の計 101 本を外した 318 本。未追跡の `Color Balance.fs`（GPUImage）も外した。つまり「Vidvox の ISF-Files そのもの」を元のリポジトリと突き合わせた集合ではなく、`CREDIT` で出所を分けた近似（gl-transitions 由来の 13 本は ISF-Files が ISF にした物として含む）。
- 最初は 5 並列で全数を走らせ、4 分を超えそうだったので 3 本おきの 106 本に切り替えたが、2 回目以降は速かったので残り 212 本も走らせ、全数 318 本になった。
- 絵が空白になった 10 本（拒否も落ちもなし）：`Bordered Box.fs`、`Color Organ Polyphonic.fs`、`ConstantAlpha.fs`、`Crazy Parametric Fun.fs`、`Doodler.fs`、`Duotone From Histogram.fs`、`FFT Spectrogram.fs`、`Optical Flow Generator.fs`、`Radial Spectrogram.fs`、`Random Shape.fs`。音・履歴（前のコマ）・時間・乱数を元に描く物が多く、静止画 1 コマの試験では黒になりうる。1 本ずつの原因は調べていない。
- 「読めた」の基準は 1 コマ描けたことまで。ISF の見出し（INPUTS・PASSES など）の意味が docs.isf.video どおりかは見ていない。

### glTF（Khronos glTF-Sample-Assets と glTF-Validator）

モデルは `https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/<名前>/glTF-Binary/<名前>.glb` から、それぞれ新しいディレクトリに取った（先頭 4 バイトは `glTF`）。検証器は `npx gltf-validator` では動かない（npm の `gltf-validator` は実行ファイルを持たず `could not determine executable to run`）。リリースのバイナリは試さず、同じ Khronos の npm パッケージ（2.0.0-dev.3.10、`npm install --ignore-scripts`）の `validateBytes` を、10 行の Node スクリプトから呼んだ。

| corpus | source URL | files | loaded | failed | notes |
|---|---|---|---|---|---|
| glTF-Sample-Assets の .glb 4 本（Box 1,664 B・Duck 120,484 B・DamagedHelmet 3,773,916 B・Avocado 8,110,040 B） | https://github.com/KhronosGroup/glTF-Sample-Assets | 4 | 4 | 0 | `add solid <file.glb>`＋`at 0.5`＋`still`：拒否 0・落ち 0・4 本とも空白でない（Box 425,112・Duck 260,869・DamagedHelmet 264,269・Avocado 177,163 画素）。DamagedHelmet は目で見て、ヘルメットの形と質感が出ていた。Box は正面向きの赤い四角 |
| 検証器（glTF-Validator） | https://github.com/KhronosGroup/glTF-Validator | 4 | 4 検証済み | エラー 0 | Box：エラー 0・警告 0。Duck：エラー 0・警告 0。DamagedHelmet：エラー 0・警告 1（`MESH_PRIMITIVE_GENERATED_TANGENT_SPACE`：材質は接線空間を要るのに頂点に無い）。Avocado：エラー 0・警告 0（ヒント 5） |

### 走らせなかった物とその理由
- ISF の見出しの意味（docs.isf.video）と、Lottie の JSON Schema（lottie.schema.json）での構造検証：時間枠と、ajv-cli の手順が未確認のため走らせていない。
- ThorVG 自身の描画との画素の突き合わせ：エンジンの絵とだけ比べ、ThorVG の出力とは比べていない（「読めて空白でない」だけで、絵の正しさの証明にはならない）。
- glTF-Sample-Assets の他のモデル、`.gltf`・埋め込み `.gltf`、Khronos のリリースのバイナリの検証器、アニメ・複数の材質の拡張（KHR_*）の試験：4 本だけ。
- ISF 以外の `.fs`（Sashimono 95 本・ossia 3 本・Luma Key・Multi-Border・Key Spill Cleaner・Color Balance）、`.wgsl`・`.mjs` の効果：頼まれた範囲の外。
- Lottie は 0.5 秒の 1 コマだけ（空白だった物のみ 0.0・0.2・1.0 秒を追加）。動きや、描き込み先が黒の物（黒だけで描かれた物は「空白」に数えられる）の区別はしていない。
- ISF を棚から `effect` で入れる経路（頼まれた手順）は、全てが `no effect is called` で拒否されるため、`carry effect` 経由に変えた。

## 実行結果：新旧エンジンの画素比較（2026-11-08）

外の基準ではなく、**変更前のエンジン自身（コミット f3b7e30de）を正解役にした突き合わせ**。自作の台本（使い捨て）で、結果だけをここに残す。

- 方法：f3b7e30de を別の作業コピーで組み（ネイティブの `copy_*`・`scatter_*` が残っている版）、同じ場面を旧エンジンと新エンジンで描いて、PNG を `cmp`（描画は決まった結果になることを、同じレシピを2回描いて先に確かめた）。
- 場面：棚の104本のレシピ × 時刻 0.0・0.7・1.9 秒（312組）。旧は頭が `copy_*`、新は `Repeater` の `js_*`。
- 結果：**312組すべて画素まで一致**。感度の確認：helix の `js_StepX` を 0.132 から 0.14 に変えると 131,023 画素が変わる（最大の差 255）ので、差があれば見える。
- 限界：(1) 同名の `helix.js` と `helix_points.js` があり、`make Helix` は後者を選ぶ。`helix.js`（移した物）は別名のコピーで別に確かめ、3時刻とも一致。(2) Bars と Burst の 0.0 秒は、大きさのキーが0で絵が空なので、証明は弱い。(3) 傾き（`js_RotateX/Y`）と `js_Rotate`、`js_Wide` と `js_ScatterRotate` の同時使用は、14本のどれにも無く、合成順の差は試されていない。

## 実行結果：古い書類の移行（2026-11-08、使い捨ての確認）

書類を開くとき（`doc_open`）、`script` が無く `copy_*`・`scatter_*`・`drift_*` の行を持つ物は、`Repeater` を付けて `js_*` に付け替える（キーと way は元のまま、`seed` は `js_Seed` へ、`js_StepX` は無ければ0、駆動していた `<名前>_by` は捨てる）。別のスクリプトを持つ物には触れない。

- 確認：古い書類に行を直接書き、新エンジンで開いた。物1（スクリプト無し）は、同じ値で新しく作った `Repeater` と **位置が一致（差 0、7コピー × 3時刻）**。物2（`script none`、キー付きの `copy_x`、`copy_rotate_by`）は、`js_StepX` の2つのキーと way（`linear`）が残り、`_by` の行は消えた。物3（Sunflower のスクリプトと `copy_x`）は変わらない。
- 限界：自作の確認で、書類は1つだけ。同梱の `.motolii` 23本には、移行の対象になる行が無かった。

## 決めてある試験：script を fx のように重ねる（2026-11-09 決めた、まだ走らせていない）

目的は1つ：1つの物に script を2つ以上重ねて、両方が効くこと（`docs/notes/CREATE_PROGRAM.md`）。走らせるのは、実装の文脈を持たない別のセッション。実窓は `--dart-define=MOTOLII_BARE=true` で組み、ユーザーの書類（`skin.motolii`）では試さない。

| # | 要件 | 何を調べるか | 状態 |
|---|---|---|---|
| S1 | 重ねたら両方効く | 実窓で、四角1つに Repeater と Spring In を付ける。断られず（「It has a script already」が出ない）、コピーが並び、かつそれぞれが Spring In の動きをする。時刻 0.0・0.5・1.0 秒の絵を撮り、Repeater だけ・Spring In だけの絵と並べて見せる | 未実行 |
| S2 | 今ある書類の見た目が変わらない | 変更前のエンジン（コミット `ed4868cf1`）で描いた絵を正解役に、script を1つ持つ物（棚のレシピ104本と `engine/animators/` の Motion、時刻 0.0・0.7・1.9 秒）を新エンジンで開いて描き、PNG を `cmp` で比べる（11/8 の新旧比較と同じやり方）。Motion はフォントで作った文字 MOTOLII に付ける。どちらかの側で置く呼び出しが断られる・エンジンが答えない・絵が出来ないときは数を認めず終了コード 2。片側にしか無い物は名前を出して比べない。全組一致 | 11/9：351 of 351（レシピ104本＋Motion 13本。`lyric.js` は ed4868cf1 に無く比べない）。それまでの「351 of 351」は Motion の文字が作られず、両側とも何も描かない絵同士の一致だった |
