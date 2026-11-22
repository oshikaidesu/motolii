# Custom UI — 1 つのネイティブ描画コアと 2 つの出口

## 役割の分離（ごっちゃにしない）

Motolii の JS カスタム UI は、**1 つの共通コア（QuickJS サンドボックス + ネイティブ Flutter 描画 `PanelTreeView`）** の上に、役割の異なる **2 つの出口** をはっきり分けて持つ。

| 軸 | ① カスタムタブ（CEP 相当） | ② エフェクトカスタムカード（AE にない解決） |
|---|---|---|
| **対象** | コンポ全体・複数レイヤー・作業フロー（Stagger / Quick Rig / パレット等） | 1 レイヤー上の 1 エフェクト（`.wgsl` / `.fs` / `.js` / TSL）の固有 UI |
| **置き場** | `shelves/panels/*.js`（およびユーザー `panels/*.js`） | `<effect>.ui.js`（シェーダーの隣）または `.js`/TSL 内の `renderCard(ctx)` |
| **UI の居場所** | **Tool Panel カタログ** ＋ **`Tab` ボタンで独立ドッキングタブ化**（組み込みツール `Align` / `Blend` も同じルールでタブ切り出し可） | **Inspector の `ValuesCard` 先頭**（`hide` 指定したパラメータは下の **`Parameters` 折りたたみへ退避**され、キーフレームや Macro `○` 接続もそのまま届く） |
| **書き戻し** | `onAction(action, ctx)` が返す `ops` を 1 Undo で適用 | `onCardAction` が返す `{ set, say }`（未定義でも `id` がパラメータ名と一致すれば直接 `v_<prop>` へ双方向バインド） |

## 表現の天井を外す最小コア：`ui.canvas`

定型コントロール（`slider` / `number` / `select` / `toggle` / `button` / `xy` / `swatch`）に加えて、**`ui.canvas(height, drawOps, { id })`** 1 つだけを持つ。

- **描画**: 正規化座標 `0..1` のベクターコマンド（`line`, `rect`, `circle`, `arc`, `polyline`, `bezier`, `text`）をスキントークン（`"accent"`, `"muted"`, `"border"`, `"blend"` 等）または `#RRGGBB` で返す。
- **操作**: ポインタの `{ x, y, phase: "down"|"drag"|"up", shift }` がそのまま `onAction` / `onCardAction` へ届く。
- これ 1 つで、カーブエディタ・カラーホイール・極座標コンパス・帯域選択・ステップシーケンサー・エミッタ図解を WebView なしで自由に書ける。

## 設計原則

1. **WebView を埋め込まない**（`AGENTS.md §3`）
   - JS が返すのは宣言的 JSON（`ui.*` ビルダー）のみ。描画はすべて Motolii 本体の `NumberField` / `TypedField` / `Pressable` / 現行スキントークンで行う。
2. **情報を二重に持たない**
   - エフェクトカスタムカードでは、シェーダー／スクリプト自身のパラメータ（`v_<prop>`）が唯一の正本。カスタム UI から変更してもキーフレーム・Macro 接続・Undo がそのまま機能する。
   - 単一 `.wgsl` / `.fs` ファイルは一切書き換えず、隣に同名 `.ui.js` を置くだけで専用 UI（例：[Diagonal Blur.ui.js](../../shelves/effects/blur/Diagonal%20Blur.ui.js) の 2D 方向ベクトルパッド）を後付けできる。
3. **安全サンドボックス**
   - QuickJS 実行は 16 MiB メモリ上限 + 500ms タイムアウト割り込み付きで、ユーザースクリプトのバグや無限ループでアプリが固まらない。
