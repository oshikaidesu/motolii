# カスタムカード仕様（`.ui.js`）

[English](CUSTOM_CARDS.md)

エフェクト（`.wgsl` / `.fs` / `.js` / TSL）やエクスプレッション（`shelves/expressions/*.js`）に、**WebView なし・ビルド不要**で専用の Inspector カード UI を付けるための開発者向け仕様書です。

> **2 つの拡張ポイントの違い**
> - **カスタムカード（本書）**: 1 レイヤー上の 1 エフェクト／エクスプレッションの操作 UI。Inspector のカード先頭に表示され、シェーダー／スクリプト自身のパラメータを直接編集します。
> - **カスタムタブ（`shelves/panels/*.js`）**: 複数レイヤーの一括操作や制作ツールなど、コンポ全体を扱う独立パネル（Tool Panel およびドッキングタブ）。同じ `ui.*` ビルダーを使いますが、エントリポイントは `render(ctx)` / `onAction(action, ctx)` です。

---

## 1. ファイル配置と検出ルール

対象のエフェクト／エクスプレッション本体は一切書き換えず、**隣に同じベース名の `.ui.js` ファイル**を置くだけで自動的に読み込まれます。

```text
shelves/effects/blur/
  Diagonal Blur.fs       ← シェーダー本体（無改変）
  Diagonal Blur.ui.js    ← 専用カスタムカード UI

shelves/expressions/
  rigid_body.js          ← エクスプレッション本体
  rigid_body.ui.js       ← 専用カスタムカード UI
```

- **サイドカー優先**: `<dir>/<stem>.ui.js` が存在すればそれが使われます。
- **同梱方式**: `.js` / `.mjs` 本体の中に `function renderCard(ctx)` を直接定義しても認識されます（サイドカーが無い場合のフォールバック）。
- **シェルフ非表示**: `*.ui.js` は独立したエフェクト／エクスプレッション一覧には表示されません。
- **ユーザー領域**: ユーザーデータ配下の同じフォルダ構造にも配置できます。

---

## 2. 最小サンプル

```js
// my_blur.ui.js — my_blur.fs / my_blur.wgsl の隣に置く
function renderCard(ctx) {
  const width = Number(ctx.params.width ?? 0.25);
  const angle = Number(ctx.params.angle ?? 0);
  const deg = Math.round(angle * 180);

  const svg = `<svg viewBox="0 0 280 88">
    <circle cx="140" cy="44" r="34" fill="none" stroke="var(--border)" stroke-width="1"/>
    <line x1="140" y1="44"
          x2="${140 + Math.cos(Math.PI * angle) * width * 34}"
          y2="${44 + Math.sin(Math.PI * angle) * width * 34}"
          stroke="var(--accent)" stroke-width="2" stroke-linecap="round"/>
    <text x="10" y="15" fill="var(--muted)" font-size="9.5" font-family="Inter">${deg}°</text>
  </svg>`;

  return {
    hide: ["width", "angle"],
    ui: ui.column([
      ui.svg(88, svg, { id: "compass", label: "Blur Vector" }),
      ui.row([
        ui.button("Horiz", "preset:h"),
        ui.button("Vert", "preset:v"),
        ui.button("Off", "preset:off"),
      ]),
    ]),
  };
}

function onCardAction(action, ctx) {
  if (action.id === "compass" && action.value) {
    const nx = (Number(action.value.x) - 0.5) / 0.25;
    const ny = (Number(action.value.y) - 0.5) / 0.42;
    const w = Math.min(1, Math.hypot(nx, ny));
    return { set: { width: w, angle: Math.atan2(ny, nx) / Math.PI } };
  }
  if (action.id === "preset:h") return { set: { width: 0.25, angle: 0 } };
  if (action.id === "preset:v") return { set: { width: 0.25, angle: 0.5 } };
  if (action.id === "preset:off") return { set: { width: 0 } };
  return {};
}
```

---

## 3. ライフサイクルと API 契約

### `renderCard(ctx)`（必須）

現在のパラメータと状態から、宣言的 UI ツリーを返す純粋関数です。

#### `ctx`（入力）
| フィールド | 型 | 内容 |
|---|---|---|
| `ctx.card` | `string` | カードの表示タイトル |
| `ctx.params` | `Record<string, number \| string>` | 現在値。元の宣言名（例 `field_radius`）と共通接頭辞を除いた短縮名（例 `radius`）の**両方**で参照可能 |
| `ctx.ranges` | `Record<string, { min, max, unit, label }>` | 各パラメータの宣言メタデータ |
| `ctx.theme` | `Record<string, string>` | 現在の Motolii スキン色（`#rrggbb`） |
| `ctx.state` | `Record<string, unknown>` | カードローカルの一時 UI 状態（ドキュメントには保存されない） |
| `ctx.time` | `number` | 現在の再生ヘッド時刻（秒） |
| `ctx.fps` | `number` | コンポジションのフレームレート |
| `ctx.audio` | `number[]` | 現在時刻の対数 24 バンド音声 FFT（20 Hz – 12 kHz、各 `0..1`）。音声トラックが無い／デコード中は空配列 `[]` |

#### 戻り値
- `{ hide?: string[], ui: UiNode }`（`hide` 不要なら `UiNode` を直接返しても可）
- **`hide` の挙動（重要）**: `hide` に挙げたパラメータは削除されるのではなく、カード下部の折りたたみ **`> Parameters`** へ退避されます。ユーザーはいつでも開いてキーフレームを打ったり Macro `○` プラグを接続でき、カスタム UI 側と常に同じ値（Single Source of Truth）を共有します。

### `onCardAction(action, ctx)`（任意）

コントロールが操作されたときに呼ばれます。

#### `action`（入力）
- `action.id`: 操作されたコントロールの `id`
- `action.value`: 値（ボタンは `true`、スライダー／数値は `number`、トグルは `boolean`、セレクト／入力は `string`、`xy` は `{ x, y }`、`ui.svg` / `ui.canvas` は `{ x, y, phase: "down" | "drag" | "up", shift: boolean }`）
- `action.live`: 連続ドラッグ中は `true`、確定（クリック／指を離した瞬間）は `false`。ホストは `live` に応じて自動で 1 Undo ステップへまとめます。

#### 戻り値
```js
{
  set?: { [paramName]: number },   // 数値パラメータの書き戻し
  say?: { [paramName]: string },   // 文字列パラメータの書き戻し
  state?: { [key]: unknown },      // ctx.state へのマージ（null で削除）
}
```

- **ゼロボイラープレート直結バインド**: `onCardAction` を省略した（または空 `{}` を返した）場合でも、コントロールの `id` がパラメータ名と一致していれば自動で対応パラメータに書き戻されます。`xy` は `id: "field_x,field_y"` のカンマ区切りで 2 パラメータへ直接バインドできます。

---

## 4. UI プリミティブと標準 SVG（`ui.svg`）

すべての描画は Motolii のネイティブウィジェットで行われます（HTML / WebView は使いません）。利用可能な全メソッドとオプションの正本は [`shelves/motolii-ui.d.ts`](../shelves/motolii-ui.d.ts) を参照してください。

### 組み込みコントロール
- **レイアウト**: `ui.column`, `ui.row`, `ui.grid`, `ui.section`, `ui.divider`, `ui.spacer`
- **表示**: `ui.text`, `ui.badge`, `ui.meter`, `ui.swatch`
- **操作**: `ui.button`, `ui.toggle`, `ui.slider`, `ui.number`, `ui.select`, `ui.input`, `ui.color`, `ui.xy`
- **自由描画**: **`ui.svg`**（推奨）、`ui.canvas`

### `ui.svg(height, svgMarkup, { id?, label?, fit? })`
標準の SVG 文字列をネイティブ描画（`flutter_svg`）します。`<path>`・`<linearGradient>`・`<radialGradient>`・`stroke-dasharray`・`transform` など SVG 標準の表現がそのまま使えます。

- **スキン自動追従（`var(--token)`）**: SVG 内で以下の CSS 変数を使うと、Motolii の現行スキン（ダーク／ライト／カスタムテーマ）へ自動置換されます。
  - `var(--accent)`, `var(--layout)`, `var(--blend)`, `var(--place)`, `var(--time)`, `var(--layer)`, `var(--text)`, `var(--muted)`, `var(--border)`, `var(--surface)`, `var(--well)`
- **フィット指定（`fit`）**:
  - `"contain"`（既定）: `viewBox` のアスペクト比を維持（コンパス・円形マップ向け）
  - `"fill"`: カード幅いっぱいに伸縮（`preserveAspectRatio="none"` と併用してグラフ・波形向け）
  - `"cover"`: アスペクト比を維持して枠を満たす
- **ポインタ操作**: `id` を指定するとクリック／ドラッグが正規化座標 `{ x, y, phase, shift }` で `onCardAction` に届きます。

---

## 5. マルチハンドル操作（`ctx.state`）

ドキュメントに保存したくない一時 UI 状態（「いまどのハンドルを掴んでいるか」など）は `state` で保持します。実例は [`shelves/expressions/rise_to_sound.ui.js`](../shelves/expressions/rise_to_sound.ui.js) を参照してください。

```js
function onCardAction(action, ctx) {
  if (action.id === "band" && action.value) {
    const { x, phase } = action.value;
    if (phase === "up") return { state: { drag: null } };
    const mode = phase === "down" ? hitTestHandle(x, ctx.params) : ctx.state.drag;
    if (mode === "lo") return { set: { start: toHz(x) }, state: { drag: "lo" } };
    if (mode === "hi") return { set: { end: toHz(x) }, state: { drag: "hi" } };
  }
  return {};
}
```

---

## 6. 開発ワークフロー（IDE 補完・ホットリロード・安全性）

- **IDE 補完（VS Code / Cursor）**: [`shelves/motolii-ui.d.ts`](../shelves/motolii-ui.d.ts) と [`shelves/jsconfig.json`](../shelves/jsconfig.json) が同梱されているため、`shelves/` 内の `.ui.js` を開くだけで `ui.*`・`ctx`・`action` の型補完と JSDoc が自動で効きます。
- **保存→即反映（ホットリロード）**: `.ui.js` を保存すると ~80 ms デバウンスで自動再評価されます。Motolii の再起動は不要です。
- **非クラッシュのエラー表示**: 構文エラーや実行時例外が発生してもアプリは落ちず、カード上部にファイル名・エラー箇所と `Retry` ボタンが表示されます。修正して保存すれば自動で復帰します。
- **サンドボックス制限**: QuickJS 実行には **16 MiB のメモリ上限**と **500 ms のタイムアウト割り込み**があり、無限ループや暴走スクリプトから本体を保護します。ファイル I/O やネットワーク API は露出されません。

---

## 7. 同梱リファレンス実装

- 物理・コンパス: [`rigid_body.ui.js`](../shelves/expressions/rigid_body.ui.js) / [`wind.ui.js`](../shelves/expressions/wind.ui.js)
- 空間フォールオフ: [`Field.ui.js`](../shelves/expressions/Field.ui.js)
- ライブ時間・ライブ音声（マルチハンドル）: [`wave.ui.js`](../shelves/expressions/wave.ui.js) / [`rise_to_sound.ui.js`](../shelves/expressions/rise_to_sound.ui.js)
- 変形・テキストカスケード: [`Scale_Assist.ui.js`](../shelves/expressions/Scale_Assist.ui.js) / [`lyric.ui.js`](../shelves/expressions/lyric.ui.js)
- シェーダーサイドカー: [`Diagonal Blur.ui.js`](../shelves/effects/blur/Diagonal%20Blur.ui.js)
