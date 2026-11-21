# コーディング・シェーダー開発リファレンス

[English](CODING.md)

Motolii で動く各コード形式が**何の仕様をベースにしているか**、**既存資産との互換性をどう保っているか**、そして **Motolii ネイティブの WGSL / JavaScript をどう書くか** をまとめたリファレンスです。

---

## 1. フォーマット別のベース仕様と互換性

Motolii は **「外部フォーマット（元の仕様のまま無改変で動かす）」** と **「Motolii ネイティブ形式（二重管理ゼロのモダン記法）」** を明確に分けています。

| フォーマット | ベース仕様 | Motolii の実行ランタイム | 互換性の保ち方 |
|---|---|---|---|
| **Motolii WGSL（`.wgsl`）** | W3C WGSL ＋ [WESL `wgsl-play`](https://wesl-lang.dev/docs/wgsl-play) 風 UI 属性 | WebGPU ネイティブ（Filament / Dawn） | `@range`・`@color`・`@toggle`・`@point`・`@group("...")`・`@label("...")`・`@auto` を Dawn へ渡す直前に同幅スペースへ置換（行番号不変、標準の `@group(N)` バインディングは温存）。旧来の `// --track@` コメント記法も後方互換でそのまま動作。 |
| **Motolii JS（`expressions/`・`relations/`・`solids/`）** | 標準 JS ＋ [`leva`](https://github.com/pmndrs/leva)（`const knobs = { ... }`） | QuickJS-ng（`relations/` は p5.js + `d3-force-3d`、`solids/` は three.js） | 純粋な JS 構文なので外部 IDE の補完・Lint がそのまま効く。旧来の `// --track@` ヘッダも互換維持。剛体物理は Jolt Physics 本来のプロパティ名（`mass`, `force`, `gravityFactor`, `restitution`, `friction`）を使用。 |
| **ISF（`.fs`）＆ Web GLSL**（Shadertoy / GLSL Sandbox / twigl / Bonzomatic） | [Vidvox ISF](https://docs.isf.video/) JSON ヘッダ ＋ GLSL | `glslang` → SPIR-V → `Tint` → WGSL | 外部シェーダーは無改変のまま読み込み時に WGSL へ自動変換。ISF の `INPUTS` / `PASSES` や Shadertoy の uniform をそのまま解釈。 |
| **AviUtl2（`.anm2`・`.obj2`）** | AviUtl2 LuaJIT ＋ `obj` API ＋ 内蔵 HLSL | LuaJIT 2.1 ＋ `glslang`（HLSL）→ SPIR-V → `Tint` → WGSL | `shelves/aviutl_scripts/` のパッケージ構成および AviUtl2 本家の `--track@` / `--check@` / `--select@` / `--color@` は一切改変せずそのまま実行。 |
| **After Effects エクスプレッション** | Adobe AE 式言語 | `lottie-web` `ExpressionManager`（QuickJS-ng バイトコード） | C++ で独自再実装せず `lottie-web` の評価器をそのまま実行。`thisComp`・`thisLayer`・`sampleImage`・`fromWorld`・`wiggle`・`loopOut` 等に対応。 |
| **After Effects プラグイン（`.plugin`・`.aex`）** | Adobe AE Effect SDK（PF / SmartFX） | [potistudio/aexlo](https://github.com/potistudio/aexlo)（MIT）隔離ワーカー（`motolii_ae_worker`） | ユーザーが配置したネイティブバイナリを別プロセスで無改変実行。タイムアウト隔離、`PF_InData.downsample` ＋ AMD FSR 1.0 自動 Half プレビュー（書き出しは常に 100% Full）、バイナリ再ビルド時の自動ホットリロードに対応。 |
| **CSS `@keyframes`・アニメーション SVG** | W3C CSS Animations ＋ Splitting.js | **Stylo**（Firefox CSS エンジン / Blitz）＋ **ThorVG** | ブラウザなしで標準 CSS ルールや CSS カスタムプロパティ（`--duration` 等）をネイティブ評価。 |
| **p5.js / Paper.js / Two.js / Hydra / TSL / Lottie** | 各公式ライブラリ / Bodymovin JSON | QuickJS-ng / **ThorVG**（Lottie 式は JerryScript） | 各公式ライブラリ本体をそのまま動かすため、ネット上のスケッチや書き出しデータを貼り付けるだけで動作。 |

---

## 2. Motolii ネイティブ WGSL の書き方（WESL UI 属性）

`var<uniform>` 構造体に直接属性を書くだけで、GPU の uniform レイアウトと Inspector の UI が 1 箇所から自動生成されます（ヘッダコメントとの二重管理が不要です）。

```wgsl
// My Glow: やわらかなハイライトグロー
// --label:Stylize
// --about:明るい領域にティント付きグローを加えます。
// --spill

struct Knobs {
  @auto time: f32,
  @auto resolution: vec2<f32>,

  @range(0, 8, 0.01, 1)      intensity: f32,
  @range(0, 200, 0.5, 25)    threshold: f32,

  @group("Tone")
  @label("Glow Tint")
  @color(1.0, 0.89, 0.77)    tint: vec3<f32>,
  @point(0.5, 0.5)           center: vec2<f32>,
  @toggle(0)                 glowOnly: u32,
};

@group(0) @binding(0) var picture: texture_2d<f32>;
@group(0) @binding(1) var picture_sampler: sampler;
@group(0) @binding(2) var<uniform> knobs: Knobs;
```

### 対応する UI 属性一覧

| 属性 | 対応する WGSL 型 | Inspector の UI | 補足 |
|---|---|---|---|
| `@range(min, max[, step[, 初期値...]])` | `f32`, `i32`, `u32`, `vec2`, `vec3`, `vec4` | 数値スライダー | `step` 省略時は `0.01`（整数型は `1`）、初期値省略時は `min`。ベクター型は自動的に `<名前>_x`, `<名前>_y`… に展開されます。 |
| `@toggle([初期値])` | `u32`, `i32`, `f32` | オン／オフスイッチ（`0` / `1`） | 初期値省略時は `0`。 |
| `@color(r, g, b[, a])` | `vec3f` / `vec3<f32>`, `vec4f` / `vec4<f32>` | カラーチャンネル（`0..1`） | `<名前>_x`〜`_z`（`vec4` は `_w` まで）を `R`, `G`, `B`（`A`）として展開。 |
| `@point(x, y)` | `vec2f` / `vec2<f32>` | 2D 座標（`0..1`） | `<名前>_x`, `<名前>_y` を `X`, `Y` として展開。 |
| `@group("名前")` / `@group()` | 構造体スコープ | 折り畳みグループ | 次の `@group(...)` または空の `@group()` までをグループ化。標準 WGSL のバインディング指定 `@group(0)` とは衝突しません。 |
| `@label("表示名")` | 直後のフィールド | 任意の表示ラベル | 省略時はフィールド名から自動生成（`colourStrength` → `Colour Strength`）。 |
| `@auto` | 組み込みフィールド | UI 非表示 | エンジンが自動供給する値（`time`, `frame`, `aspect`, `resolution`, `frameRect`, `passRect`, `passindex`, `screen`, `layer`, `duration` 等）を明示。 |

### パイプライン系ディレクティブ

構造体外のパイプライン設定だけは先頭の短いコメント行で指定します：

- `// 名前: 説明` — 表示名（1 行目）
- `// --label:カテゴリ`・`// --about:説明`・`// --tag:タグ1 タグ2` — 棚メタデータ
- `// --spill` / `// --alpha` — レイヤー領域外への描画許可／アルファ置き換え
- `// --pass@名前:persistent,fine,幅,高さ` — マルチパス描画ターゲット（`fine=1` は RGBA16F、`s0.5` は相対解像度、名前空欄が最終出力）
- `// --picture@名前:ラベル` / `// --image@名前:ファイル` / `// --history@枚数:倍率` — 追加テクスチャ入力

`shelves/effects/` に同梱されている全 274 本の `.wgsl` はすべてこの形式に統一されています（実例：[`shelves/effects/stylize/halo_glow.wgsl`](../shelves/effects/stylize/halo_glow.wgsl)、一括変換スクリプト：[`shelves/effects/sources/to_wesl.py`](../shelves/effects/sources/to_wesl.py)）。

### コンピュート頂点変形シェーダー（`@compute`）

`@compute` を持つ `.wgsl` はレイヤーの 3D 立体（平面レイヤーは自動的に `solids/Plane.js`）の頂点を毎フレーム変形します。フラグメントシェーダーと全く同じ WESL UI 属性が使えます（Dawn コンパイル直前に自動ストリップ）。グループ 0 のバッファ配置は [`shelves/README.ja.md`](../shelves/README.ja.md) を参照してください。

---

## 3. Motolii ネイティブ JavaScript の書き方（`leva` 記法）

`expressions/`・`relations/`・`solids/` ではファイル先頭に [`leva`](https://github.com/pmndrs/leva) 形式でパラメータを宣言できます：

```js
const knobs = {
  height: { value: 0.5, min: 0, max: 2, step: 0.01 },
  spin: false,
  Advanced: folder({
    speed: { value: 1.0, min: 0, max: 5 },
  }),
};

function each(i, n, t, k) {
  return { y: k.height * Math.sin(t * k.speed + i) };
}
```

`each` / `relate` / `force` / `solid` / レシピの詳細 API は [`shelves/README.ja.md`](../shelves/README.ja.md) を参照してください。

---

## 4. Code タブと外部 IDE 連携ワークフロー

- **シンタックスハイライト：** WGSL（WESL の `@range` / `@color` / `@toggle` 属性含む）・GLSL / ISF・JavaScript・CSS・Lua にそれぞれ対応。
- **ヘッダ自動折り畳み：** 先頭に 3 行以上の `// --` ディレクティブがあるファイルは、開いた直後に `Header (N directives)` の 1 行に畳まれてコード本体が 1 行目から表示されます。クリックで生ヘッダを展開編集でき、保存時は常にヘッダごと書き戻されます。
- **外部 IDE で開く（各コードセル右上の `🔗` ボタン）：**
  - 環境変数 `$VISUAL` / `$EDITOR` を最優先し、未設定時はインストール済み IDE（`Cursor`・`VS Code`・`Zed`・`Windsurf`・`Antigravity`）を自動検出、見つからなければ OS 標準アプリで開きます。
  - 同梱原本や他レイヤー共有ファイルの場合は、自動でレイヤー専用コピー（copy-on-write）を作成してから開くため、同梱原本を壊しません。
  - 外部 IDE で保存すると Motolii の Stage が自動でホットリロードされます。
- **ネイティブ AE プラグインのホットリロード：** 外部（Xcode / Cargo / Visual Studio 等）で `.plugin` / `.aex` を再ビルドして上書きすると（macOS バンドル内の `Contents/MacOS/*` 更新も検知）、Motolii 本体を再起動せずに隔離ワーカーが再起動し Stage に即反映されます。
