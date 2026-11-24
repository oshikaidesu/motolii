# Motolii

[English](README.md)

[![build](https://github.com/oshikaidesu/motolii/actions/workflows/build.yml/badge.svg)](https://github.com/oshikaidesu/motolii/actions/workflows/build.yml) [![checks](https://github.com/oshikaidesu/motolii/actions/workflows/checks.yml/badge.svg)](https://github.com/oshikaidesu/motolii/actions/workflows/checks.yml) [![Discord](https://img.shields.io/badge/Discord-コミュニティに参加-5865F2?logo=discord&logoColor=white)](https://discord.gg/EFZQREAQ9g)

**離れていた表現の交差点。**

Shadertoy のシェーダーを音楽のビートに反応させる。After Effects のエクスプレッションと CSS `@keyframes` を同じテキストレイヤーに重ねる。p5.js のスケッチを Lottie アニメーションの背後に合成する。Web 上で見つけたコードを貼るだけで、そのまま映像として動きます。

Motolii は WebGPU ネイティブの軽量エンジンとプレーンファイル設計で、数千コピーやエフェクトの重ね掛けも 60 fps で軽快にプレビューできるオープンソースの動画編集ソフトです。

![Motolii ワークスペース：左に素材と棚、中央に Stage プレビュー、下に Timeline、右に Inspector](docs/pictures/tabs/window.jpg)

> 💬 **[Motolii Discord コミュニティ](https://discord.gg/EFZQREAQ9g)** — 見る専（ROM 専）大歓迎・参加ログは出ないので気軽に覗けます。日々の進捗クリップや、技術選定の裏話をまとめた開発小話コラム（`#dev-notes`）を公開しています。

---

## 今まで培った資産やプラグインも、そのまま持ち込めます

新しいツールを試すときに一番気になるのは、「これまで買い揃えたプラグインや書き溜めた式・素材が無駄にならないか」という点です。Motolii は既存の表現資産をそのまま活かせるように設計しています。

- **手持ちの After Effects プラグイン（`.plugin` / `.aex`）がそのまま動作**  
  Deep Glow・Quick Chromatic Aberration・Zink Tools・Satori などのサードパーティ製プラグインをユーザーフォルダの `ae_plugins/` に置く（またはシンボリックリンクする）だけで、パラメータカード・`#ae` タグ・プレビュー付きで Effects 棚に並びます。[aexlo](https://github.com/potistudio/aexlo) の隔離ワーカーで実行するため、安定性も保たれます。
- **After Effects エクスプレッションをそのまま評価**  
  `lottie-web` の `ExpressionManager` を QuickJS-ng で直接実行。`thisComp`・`thisLayer`・`wiggle`・`linear`・`ease`・`sampleImage`・キーフレーム参照がそのまま動きます。
- **Lottie・PSD・Cavalry・AviUtl2・Shadertoy・p5.js・CSS を 1 本のタイムラインに混在**  
  PSD はレイヤー構成のまま取り込んで自動リグ化でき、Cavalry スクリプト 26 本や 1,300 以上のコミュニティエフェクトも標準同梱しています。
- **透過背景ビュー（Stage `Alpha`）＆ ProRes 4444 透過書き出し**  
  編集中の透過確認からアルファ付き書き出しまでシームレスに完結するため、Premiere・DaVinci・After Effects などの既存パイプラインとの併用にも自然に組み込めます。

> 詳しい互換範囲は [After Effects 資産の持ち込みガイド](docs/AFTER_EFFECTS.ja.md) を参照してください。

---

## 触り心地とワークフロー（UI / UX）

### 1. 名前を覚えていなくても、見た目から直感的に探せる

1,300 以上のエフェクトやフォントを、**見た目の近さで自動配置された 2D マップ（カテゴリ島ラベル・ズーム・拡大ルーペ付き）** から直感的に探せます。タイルにカーソルを乗せるだけで Stage 上に仮適用される **ホバープレビュー** にも対応しています。

<p>
<img src="docs/pictures/tabs/effects_map.jpg" alt="Effects 2D 類似度マップ：カテゴリごとの島ラベル・ズームバー付き" width="49%">
<img src="docs/pictures/tabs/fonts_map.jpg" alt="Fonts 2D 類似度マップ：書体クラスタの島ラベル付き" width="49%">
</p>

<p>
<img src="docs/pictures/tabs/effects_wide.jpg" alt="Effects 棚のタイル表示とタグ絞り込み" width="49%">
<img src="docs/pictures/tabs/fonts_wide.jpg" alt="Fonts 棚の書体一覧とロール設定" width="49%">
</p>

### 2. 見渡しやすく、迷わず触れる操作系

- **タイル型 Inspector**：パラメータをコンパクトなカードとブロックで整理し、パネル幅に応じて自動で多列化。視覚的な効き具合を色分けして重要な操作子が一目で分かります。
- **タイムライン＆HDR 環境オブジェクト**：音声波形・BPM ビートグリッド・スタック可能なイージング（`.way`）に加え、**HDR ルーム照明・回転・背景も独立レイヤー（`Environment`）としてタイムライン上でトリム・切替・キーフレーム制御**できます。
- **手ブレ補正（Smooth）付きフリーハンド＆3D Boxcam カメラ**：Brush / Pen の手書きパス補正を `Off`〜`High` で調整でき、3D カメラも FPS レーダー型の Depth パネルと連動して直感的に扱えます。

<p>
<img src="docs/pictures/tabs/inspector.jpg" alt="タイル型 Inspector と 2.5D/3D Transform カード" width="32%">
<img src="docs/pictures/tabs/timeline.jpg" alt="音声波形・キーフレーム・イージング曲線付きタイムライン" width="66%">
</p>
<p>
<img src="docs/pictures/tabs/ease.jpg" alt="スタック可能なイージングカーブとプリセット" width="49%">
<img src="docs/pictures/tabs/depth.jpg" alt="カメラ距離と被写界深度を見る Depth パネル" width="49%">
</p>

### 3. コードと AI エージェントを並べて制作（Code ワークスペース & ACP Agent）

トップバーの **CODE** に切り替えると、**ACP 対応 AI エージェント・Code ノートブック・Stage・タイムライン** を一画面に並べて作業できます。Claude Agent・Codex・Gemini CLI・Cursor などと選択レイヤーのカード・値・コードを共有し、対話しながら表現やリグを育てられます。

![Code ワークスペース：左に ACP Agent、中央に Code ノートブック、右に Stage、下に Timeline](docs/pictures/tabs/code_workspace.jpg)

---

## 自由な操作盤を作って配れる規格「Vism（ヴィズム）」

**Vism** は、WebView を一切使わず **1 本の JavaScript** だけで、自分好みの操作パネルやインスペクター専用カードを作って配布できる Motolii のカスタム UI 規格です。Flutter ネイティブの 3D オブジェクト（`.glb`/`.obj`/ウェーブテーブル）・60 fps GLSL シェーダー・音声波形・16 ステップシーケンサー・リグピッカー・ロータリーノブを組み合わせて、楽器やシンセサイザーのように触れる道具を作れます。

![Vism 8デザインベクトル・ライブデモ（3D・ウェーブテーブル・ハードウェア・スタジオライト・CRT・マンガ）](docs/pictures/vism_3d_live.gif)

![Vism Pro 機能ライブデモ（音声波形・16ステップシーケンサー・GLSLシェーダー・Live2Dリグピッカー・カーブ＆フェーダー）](docs/pictures/vism_live.gif)

- **10 秒で作り始められる**：Tools パネルの **`+ New Vism`** を押すだけで、動くテンプレート生成＋IDE 型補完（`motolii-ui.d.ts`）配置＋独立タブオープン＋エディタ起動まで自動完了。保存から **約 80 ms で即ホットリロード**されます。
- **プリセット保存＆ワンクリック配布**：カードの設定をプリセット保存でき、**`Pack`** で `.vism` パック化。受け取った人は `.vism` をダブルクリックまたはウィンドウへドラッグ＆ドロップするだけで即導入できます。
- **統一 UI で使いたいときも安心**：`Settings → Appearance → Vism Card Faceplates` をオフにすれば、機能を保ったまま Motolii 標準スキンへ揃えられます。

👉 [5 分で始める Vism 開発クイックスタート](docs/VISM_QUICKSTART.ja.md) · [Vism カスタムカード仕様書](docs/CUSTOM_CARDS.ja.md)

---

## ダウンロード（ベータ版）

**macOS Apple Silicon（`.app`）** 向けのビルド済みベータ版は [GitHub Releases](https://github.com/oshikaidesu/motolii/releases) からダウンロードできます。

1. [Releases](https://github.com/oshikaidesu/motolii/releases) から `Motolii-*-macos-arm64.zip` をダウンロードして展開し、`Motolii.app` を `/Applications` に移動します。
2. 初期ベータ版は Apple Developer ID による公証前のため、初回起動前にターミナルで以下を 1 回だけ実行してください：
   ```bash
   xattr -cr /Applications/Motolii.app
   ```
3. Motolii を起動し、ホーム画面サイドバーの **SAMPLES** から同梱サンプル（日本語タイポグラフィ・モーションシェイプ・Vism カスタムカード体験）をクリックするとすぐ試せます。

> Windows（`x64`）・Linux 版は準備中です。ソースからビルドする場合は以下を参照してください。

## ビルドと実行

### 必要な環境

- Apple Silicon 搭載 Mac（検証環境：M4、macOS 15.5）
- App Store 版 Xcode（初回起動後に `sudo xcodebuild -license accept` を実行）
- [Homebrew](https://brew.sh/ja/) / [Flutter](https://docs.flutter.dev/get-started/install) 3.50.0（stable） / Python 3
- 約 10 GB の空きディスク容量（Xcode・Flutter 除く）

```bash
git clone https://github.com/oshikaidesu/motolii.git
cd motolii
brew bundle
engine/build.sh
app/tool/live.sh
```

テストの実行：C++ は `engine/build.sh test`、Flutter は `cd app && flutter test`（詳細は [Testing](docs/TESTING.md)）。

---

## 対応フォーマット（20+ 形式）

コードの貼り付け（`⌘V`）またはフォルダへの配置で形式は自動判定されます。

| フォーマット | 追加方法 | 実行ランタイム |
|---|---|---|
| **After Effects プラグイン (`.plugin`, `.aex`)** | `ae_plugins/` に配置（シンボリックリンク可） | [aexlo](https://github.com/potistudio/aexlo)（隔離ワーカー） |
| **After Effects エクスプレッション** | 貼り付け（`⌘V`）または Expression カード | lottie-web（QuickJS-ng） |
| **Lottie (`.json`)** | ドラッグ＆ドロップ | ThorVG（ランタイム式評価対応） |
| **Photoshop (`.psd` / `.psb`)** | ドラッグ＆ドロップ | レイヤー分解グループ読み込み |
| **Shadertoy / GLSL Sandbox / twigl / Bonzomatic** | 貼り付け（`⌘V`） | ISF → WGSL（glslang + Tint） |
| **ISF (`.fs`) / WGSL (`.wgsl`)** | `effects/` に配置 | WebGPU ネイティブ |
| **p5.js / Paper.js / Two.js / Canvas 2D / Dwitter / tixy / Turtletoy** | 貼り付け（`⌘V`） | QuickJS-ng |
| **Hydra / three.js TSL** | 貼り付け（`⌘V`） | QuickJS-ng → WGSL |
| **Cavalry スクリプト** | Expression カード | QuickJS-ng |
| **CSS `@keyframes` / アニメーション SVG** | 貼り付け（`⌘V`）または D&D | Stylo（Firefox CSS エンジン）+ ThorVG |
| **AviUtl2 (`.anm2`, `.obj2`)** | `aviutl_scripts/` に配置 | LuaJIT |
| **3D モデル (`.glb`, `.gltf`) / 点群 (`.ply`)** | ドラッグ＆ドロップ | Filament WebGPU |
| **字幕 (`ASS`/`SRT`/`LRC`/`VTT`)** | ドラッグ＆ドロップ | libass（FFmpeg 経由） |

---

## ドキュメント

- [タブ・パネル一覧](docs/TABS.ja.md) — 全タブの機能紹介（スクリーンショット付き）
- [After Effects 資産の持ち込みガイド](docs/AFTER_EFFECTS.ja.md) — 手持ちの AE プラグイン・エクスプレッション・Lottie の使い方
- [Vism 開発クイックスタート](docs/VISM_QUICKSTART.ja.md) / [カスタムカード仕様](docs/CUSTOM_CARDS.ja.md) — JS だけで 3D・シェーダー・音声連動の独自 UI を作る
- [ACP Agent チュートリアル](docs/ACP_TUTORIAL.ja.md) — AI と進める PSD 自動リグ・Group Focus・`ops.json` 編集
- [カメラガイド](docs/CAMERA.ja.md) — Boxcam 3D カメラ・Z ターゲット・Depth レーダー
- [コーディング・シェーダー開発リファレンス](docs/CODING.ja.md) — 対応形式・WESL WGSL 属性・IDE 連携
- [使い方ガイド](docs/GUIDE.md) — プロジェクト作成から書き出しまでの操作リファレンス
- [アーキテクチャ](docs/ARCHITECTURE.md) / [ブリッジ仕様](docs/app/BRIDGE.md) / [テスト](docs/TESTING.md)
- [コントリビューションガイド](.github/CONTRIBUTING.ja.md)

## コントリビューション & ライセンス

開発進捗や質問・相談は [Discord](https://discord.gg/EFZQREAQ9g) や [Discussions](https://github.com/oshikaidesu/motolii/discussions)、バグ報告や機能要望は [Issues](https://github.com/oshikaidesu/motolii/issues) へどうぞ（日本語・英語どちらも歓迎）。  
[Apache License 2.0](LICENSE-APACHE) または [MIT](LICENSE-MIT) のデュアルライセンスです（同梱サードパーティは [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) を参照）。
