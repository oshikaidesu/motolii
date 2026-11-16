# Motolii 手順書

ここに来た人が「何がどこにあり、どう繋がるか」を掴むための地図。

## 木

```
motolii/
├── AGENTS.md                 ← 開発原則（全ての判断の根）
│
├── app/                      ← Flutter アプリ（見た目だけ）
│   ├── lib/
│   │   ├── main.dart                      起動
│   │   ├── workspace/                     ウィンドウ全体
│   │   │   ├── state/workspace_controller.dart  アプリの状態
│   │   │   ├── stage/                     ステージ（プレビュー）
│   │   │   └── timeline/                  タイムライン
│   │   ├── inspector/                     カード（ValuesCard が正本）
│   │   ├── bridge/motolii.dart            ← C API との境界（dart:ffi）
│   │   ├── panel.dart                     Code タブ・棚タブ
│   │   ├── skin/                          テーマ
│   │   ├── storage/                       設定の保存
│   │   └── widgets/                       共通部品
│   ├── test/                              Flutter テスト
│   ├── BRIDGE.md                          app ↔ engine の契約
│   └── README.md                          app 側の地図
│
├── engine/                   ← C++ エンジン（libmotolii.dylib）
│   ├── entry/
│   │   ├── motolii.h                      C API（約 400 行、唯一の境界）
│   │   └── render_thread.h                描画スレッド（GPU とプロジェクトを握る）
│   │
│   ├── document/             ← プロジェクト（SQLite）と評価
│   │   ├── document.h                     プロジェクトの読み書き
│   │   ├── evaluate/
│   │   │   └── place.cpp                  レイアウト・式の評価、GPU 読み口
│   │   ├── scripts/                       式の実行を繋ぐ口
│   │   ├── cards.cpp                      カード（何が出るか）
│   │   ├── match/                         値の照合
│   │   ├── edit/                          値の変更
│   │   └── undo.cpp                       取り消し
│   │
│   ├── community/            ← 各言語のアダプタ（原則 2: 既存実装を使う）
│   │   ├── after_effects/                 AE 式 → lottie-web（bytecode 焼済み）
│   │   │   ├── lottie_shim.js                 AE.compile / AE.run の板
│   │   │   ├── lottie_precompile.cpp          ビルド時バイトコード化
│   │   │   ├── lottie_canonical.h             モジュール名の正規化
│   │   │   └── lottie_bytecode.h              焼いたバイトコードの宣言
│   │   ├── script_runner/                 Script: QuickJS で each() を回す
│   │   │   ├── script_runner.cpp              本体（全 .js で lottie_shim をロード）
│   │   │   ├── script_parameters.cpp          スライダーの読み取り
│   │   │   └── project_reads.cpp              layerValue / sampleImage の口
│   │   ├── quickjs/                       QuickJS-ng の共通（leva, script）
│   │   ├── three/                         three.js / TSL
│   │   │   ├── tsl_each.cpp                   each() → WGSL（TSL ノードグラフ経由）
│   │   │   ├── tsl_shelf.h                    TSL エフェクト → 棚の WGSL
│   │   │   └── solid_three.cpp                three.js の BufferGeometry 取得
│   │   ├── three_shading_language_to_shelf/   from_each.js, convert.ts
│   │   ├── css/                           Stylo / Blitz（Rust、Cargo 経由）
│   │   ├── p5/                            p5.js スケッチ（Web Audio stand-in 含む）
│   │   ├── subtitles/                     libass（字幕を絵として渡す）
│   │   ├── isf/                           ISF シェーダー
│   │   ├── aviutl/                        AviUtl2 スクリプト（LuaJIT）
│   │   ├── hydra/                         Hydra ライブコーディング
│   │   ├── sites/                         ペースト判定（adapter_form）
│   │   ├── absent_motion/                 Absent Motion
│   │   ├── playcanvas/                    PlayCanvas
│   │   └── jolt/                          Jolt Physics（未使用、保持のみ）
│   │
│   ├── stage/                ← 描画
│   │   ├── render/                        Filament でフレームを描く
│   │   ├── canvas/                        ThorVG（2D テキスト・形状）
│   │   ├── effects/                       screen_fx, layer_fx（WGSL エフェクト）
│   │   └── layer_effects/                 レイヤー単位のエフェクト
│   │
│   ├── gpu/                  ← GPU compute
│   │   └── compute_interop.h              WGSL compute の dispatch（Filament 経由）
│   │
│   ├── media/                ← 映像・音声
│   │   ├── video_layer.h                  GStreamer でデコード
│   │   ├── sound_playback.h               プレビュー再生
│   │   └── sound_level.h                  AnalyserNode 互換の周波数解析
│   │
│   ├── motion/               ← イージング・補間
│   │   └── easing_curves.h                一つの solver（interp_bezier）
│   │
│   ├── shelf/                ← 棚のファイル読み込み
│   ├── base/                 ← ファイル読み書き等の共通
│   ├── materials/            ← Filament マテリアル
│   ├── preview/              ← プレビュー関連
│   │
│   ├── third_party/          ← 外部コード（原則 6: 交換しやすく）
│   │   ├── js/                            JavaScript ライブラリ
│   │   │   ├── three/                         three.js r186
│   │   │   ├── lottie/                        lottie-web（AE 式ランタイム）
│   │   │   ├── p5/                            p5.js + stand-in
│   │   │   ├── acorn/                         acorn 8.17.0（AST 書き換え）
│   │   │   └── ...
│   │   ├── filament/                      Filament 1.77.2（ビルド済み SDK）
│   │   ├── thorvg_src/                    ThorVG ソース
│   │   ├── stylo_src/                     Stylo（Servo の CSS エンジン）
│   │   ├── physics/                       Jolt Physics, Rapier
│   │   └── ...
│   │
│   ├── deps/                 ← ビルドスクリプトとパッチ
│   │   ├── patches/<lib>/                 各ライブラリへのパッチ
│   │   ├── filament.sh                    Filament ビルド
│   │   ├── thorvg.sh                      ThorVG ビルド
│   │   └── stylo.sh                       Stylo フェッチ＋パッチ
│   │
│   ├── CMakeLists.txt        ← エンジンのビルド定義
│   ├── build.sh              ← ビルド＋テスト（build.sh test）
│   └── check_syntax.sh       ← C++ 構文チェック（clang）
│
├── shelves/                  ← ユーザ側のコード（原則 1: 外に出せるものは全部外）
│   ├── expressions/                       式カード（each() ファイル）
│   │   ├── fade_in.js, wave.js, ...           コピーの動き
│   │   └── away_from_dark.js                  sampleImage を使う例
│   ├── create/                            レシピ（レイヤーを作る）
│   │   └── repeats/                           ae_grid.js, ae_ring.js, ...
│   ├── effects/                           WGSL エフェクト
│   ├── relations/                         relate() ファイル
│   ├── looks/                             見た目プリセット
│   ├── solids/                            three.js の立体
│   ├── ease/                              イージングプリセット
│   ├── behaviours/                        振る舞い
│   ├── aviutl_scripts/                    AviUtl2 スクリプト（180 本）
│   ├── skins/                             テーマ
│   └── workspaces/                        ワークスペースレイアウト
│
├── docs/                     ← 文書
│   ├── ARCHITECTURE.md                    構造の図解（mermaid）
│   ├── TESTING.md                         テスト手順
│   ├── README.md                          プロジェクト概要
│   ├── design/                            設計文書
│   │   ├── next_expressions.md                式の理想（本書）
│   │   ├── uat_scenarios.md                   UAT 448 行
│   │   ├── uat_order.md                       UAT の通す順
│   │   ├── tsl_collection.md                  TSL 棚の収集記録
│   │   ├── renamed_words.md                   名前の変更履歴
│   │   └── ...
│   ├── using/                             使い方
│   ├── internal/                          内部調査（git ignore）
│   └── pictures/                          スクリーンショット
│
└── .githooks/                ← pre-commit フック
```

## 流れ

### コードが貼られてから画面に出るまで

```
⌘V (or ドロップ)
  │
  ▼
adapter_form (community/sites/)    ← 言語を判定: "js", "css", "svg", "tsl", ...
  │
  ├─ .js ──► Script (community/script_runner/)
  │           ├─ lottie_shim を読む（bytecode、全 .js 共通）
  │           ├─ ファイルを QuickJS で eval
  │           ├─ each() があれば tsl_each() で WGSL を試す → Script::wgsl()
  │           └─ 無ければ: トップレベル { } なら each() に包む
  │
  ├─ .css ──► Stylo / Blitz (community/css/)
  │           文字ごとの transform と opacity を返す
  │
  ├─ .svg ──► ThorVG + Stylo でアニメーション SVG を描く
  │
  ├─ .fs ───► ISF → WGSL (community/isf/)
  │
  ├─ .wgsl ─► そのまま screen_fx / layer_fx
  │
  └─ tsl ──► tsl_shelf() → WGSLNodeBuilder → .wgsl として棚へ
```

### 毎フレーム（式カード）

```
place.cpp : doc_laid
  │
  ├─ gpu_ready? (Script::wgsl() が在る + コピー数 ≥ 閾値)
  │   └─ [未実装] compute_interop.h で dispatch → instance buffer
  │
  └─ CPU: doc_expressions_lay
       └─ Script::ask(i, n, t, k) × コピー数
            └─ QuickJS で each(index, count, time, value) を呼ぶ
```

### ビルドと確認

```
[Dart を触った]    →  cd app && dart analyze lib
[C++ を触った]     →  ./engine/check_syntax.sh
[コミット前]       →  cd app && flutter test
[エンジンテスト]   →  engine/build.sh test  （重い、1 本ずつ）
[フレーム計測]     →  docs/TESTING.md「Frame timing」
```

## 原則 → 配置の対応

| 原則 | 配置のルール |
|---|---|
| 1. エンジンは最小コア | `engine/` は骨組みだけ。式・エフェクト・形状は `shelves/` |
| 2. 既存実装を使う | `engine/community/` が口、`engine/third_party/` が実装 |
| 3. 情報を二重に持たない | 正本は SQLite のプロジェクト。app は C API で読むだけ |
| 4. 役割を重複させない | Dart = 見た目。C++ = 動き。1 つの役目に 1 つ |
| 5. 小さく直す | 新しいフォルダを増やす前に既存を見る |
| 6. 交換・削除しやすく | `third_party/` / `deps/patches/` / `community/` の 3 層分離 |
| 7. 実際に動かして確かめる | テスト + 画面・映像・書き出しで確認 |

## 触る時の道しるべ

| やりたいこと | 見る場所 |
|---|---|
| 新しい言語のアダプタを足す | `engine/community/` に 1 フォルダ。`adapter_form` に判定を足す |
| 棚にエフェクトを足す | `shelves/effects/` に `.wgsl` か `.fs` を置く |
| 棚に式を足す | `shelves/expressions/` に `.js`（`each()` またはオブジェクトリテラル） |
| カードの見た目を変える | `app/lib/inspector/` |
| タイムラインを触る | `app/lib/workspace/timeline/` |
| C API を足す | `engine/entry/motolii.h` + `app/lib/bridge/` |
| ライブラリを更新する | `engine/deps/<lib>.sh` のバージョン + `deps/patches/` のパッチ確認 |
| GPU compute を繋ぐ | `engine/gpu/compute_interop.h` → `place.cpp` の `gpu_ready` 枝 |
| テストを足す | `app/test/` (Dart) / `engine/community/<dir>/*_test.cpp` (C++) |

## 関連文書

- [AGENTS.md](../AGENTS.md) — 開発原則（全ての判断の根）
- [docs/ARCHITECTURE.md](ARCHITECTURE.md) — 構造の図解
- [docs/TESTING.md](TESTING.md) — テストの手順
- [docs/design/next_expressions.md](design/next_expressions.md) — 式の理想
- [docs/design/uat_scenarios.md](design/uat_scenarios.md) — UAT 448 行
- [docs/design/uat_order.md](design/uat_order.md) — UAT の通す順
- [docs/design/renamed_words.md](design/renamed_words.md) — 名前の変更
- [app/BRIDGE.md](../app/BRIDGE.md) — app ↔ engine の契約
- [app/README.md](../app/README.md) — app 側の地図
