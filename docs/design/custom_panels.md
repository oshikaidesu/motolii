# Custom UI — 1 つのネイティブ描画コアと 2 つの出口

サードパーティ開発者向けの外部仕様書は [docs/CUSTOM_CARDS.ja.md](../CUSTOM_CARDS.ja.md)（[English](../CUSTOM_CARDS.md)）、型定義の正本は [shelves/motolii-ui.d.ts](../../shelves/motolii-ui.d.ts) を参照。

## 役割の分離（ごっちゃにしない）

Motolii の JS カスタム UI は、**1 つの共通コア（QuickJS サンドボックス + ネイティブ Flutter 描画 `PanelTreeView`）** の上に、役割の異なる **2 つの出口** をはっきり分けて持つ。

| 軸 | ① カスタムタブ（CEP 相当） | ② エフェクトカスタムカード（AE にない解決） |
|---|---|---|
| **対象** | コンポ全体・複数レイヤー・作業フロー（Stagger / Quick Rig / パレット等） | 1 レイヤー上の 1 エフェクト／エクスプレッションの固有 UI |
| **置き場** | `shelves/panels/*.js`（およびユーザー `panels/*.js`） | `<effect>.ui.js`（サイドカー）または `.js`/TSL 内の `renderCard(ctx)` |
| **UI の居場所** | **Tool Panel カタログ** ＋ **`Tab` ボタンで独立ドッキングタブ化**（組み込みツール `Align` / `Blend` も同じルールでタブ切り出し可） | **Inspector の `ValuesCard` 先頭**（`hide` 指定したパラメータは下の **`> Parameters` 折りたたみへ退避**され、キーフレームや Macro `○` 接続もそのまま届く） |
| **書き戻し** | `onAction(action, ctx)` が返す `ops` を 1 Undo で適用 | `onCardAction` が返す `{ set, say, state }`（未定義でも `id` がパラメータ名と一致すれば直接 `v_<prop>` へ双方向バインド） |

## 表現の天井を外す設計：操作部品は最小 JSON、自由描画は標準 SVG

- **ネイティブ操作部品**: スライダー・数値欄・セレクト・トグル・ボタンなど、OS／アプリと一貫すべき入力操作だけホストの最小 JSON プロトコルで受ける。
- **自由描画（`ui.svg`）**: グラフ・コンパス・スペクトラム・図解は既存依存の `flutter_svg` にそのまま託し、ホスト側で独自描画コマンドを増やし続けない。`var(--accent)` 等のスキン変数置換により現行テーマへ自動追従する（既存の `ui.canvas` も互換維持）。
- **マルチハンドルとライブ信号**: ドキュメント非保存のカードローカル `ctx.state`（ドラッグ中ハンドル保持等）と、エンジン既存 FFT（`motolii_sound_spectrum`）からの `ctx.audio` / `ctx.time` / `ctx.fps` を供給。
- **ホットリロードと層分離**: ファイル監視は `lib/storage/script_watch.dart` に隔離し、UI ウィジェットから `dart:io` を直接参照しない。

## 設計原則

1. **WebView を埋め込まない**（`AGENTS.md §3`）: 宣言的 JSON + 標準 SVG のみをネイティブ描画する。
2. **情報を二重に持たない**: エフェクト自身のパラメータ（`v_<prop>`）が唯一の正本。元の `.wgsl` / `.fs` / `.js` を改変せず `.ui.js` サイドカーで UI を後付けできる。
3. **安全サンドボックス**: QuickJS は 16 MiB メモリ上限 + 500 ms タイムアウト割り込み付きで実行し、例外時は非クラッシュのエラーバナー＋自動ホットリロードで復帰する。
