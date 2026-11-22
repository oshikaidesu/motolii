# Custom Panels — WebView なしの JS カスタムパネル（CEP 相当）

## 目的

After Effects の CEP パネル（Motion 4 / Overlord / Rift 等）が担ってきた「よく使う操作を自分好みの専用パネルにまとめる」体験を、**WebView を一切埋め込まず**（`AGENTS.md §3`）に実現する。

JavaScript スクリプトが宣言的 UI ツリー（JSON）とドキュメント操作（`ops`）を返し、Motolii 側がネイティブの Flutter ウィジェットと現行スキントークンで直接描画する。

## 配置と単一正本

- 標準パネル: `shelves/panels/*.js`
- ユーザー独自パネル: `~/Library/Application Support/Motolii/panels/*.js`（同名ファイルはユーザー側が優先、`shelf_folders.h` の既存解決をそのまま利用）
- Tool Panel のカタログに標準ツール（`Blend`, `Align`）と並んで自動登録され、クリックで展開・ピン留めできる。
- スクリプトファイルそのものが正本であり、ディスク上の `.js` を書き換えて `Reload` すれば即反映される。

## スクリプト契約（純粋関数 + 宣言的データ）

```js
// --title: Panel Name
// --about: Short description
// --acts: Selection
// --tone: layout

function render(ctx) {
  // ui.* ビルダー（または同等のプレーン JSON）でネイティブ UI ツリーを返す
  return ui.column([...]);
}

function onAction(action, ctx) {
  // { state?, ops?, notice? } を返す
  // ops はすべて 1 回の Undo ステップ（groupBegin/groupEnd）として適用される
  return { state: {...}, ops: [{ op: "set", layer: 1, name: "start", value: 0.5 }], notice: "Done" };
}
```

### なぜ純粋関数 + `ops` 配列なのか

1. **安全・高速・決定的**: QuickJS ランタイムに C++ の生ポインタを渡さず、メモリ上限（16 MiB）とタイムアウト（500ms）のサンドボックス内で完結する。無限ループでもアプリ本体が固まらない。
2. **自動的に 1 Undo**: 複数レイヤーへの一括変更やマクロ自動リグでも、返却された `ops` をまとめて 1 回の Undo ステップとして積む。
3. **見た目の一貫性**: HTML/CSS を書かなくても、Motolii の Light / Dark / カスタムスキン、`NumberField` のスクラブ・数式入力・キーボード操作がそのまま手に入る。
4. **Macros との連携**: `say` オペレーションで `macro_sources` / `macro_map` / `macro_names` を書けるため、1 クリックで「Audio Bounce」「Wave Spin」等のモジュレーションリグを組むパネルを数行の JS で書ける。
