# Motolii ベータ公開ロードマップ＆チェックリスト

チャットの長さやスレッド切替に関わらず抜け漏れを防ぐための、ベータ公開に向けた唯一の正本チェックリスト。
**原則：1 項目（または 1 フェーズ）ごとに実機確認 → このチェックリストを更新 → コミット。**

---

## Phase 1：土台固め（ベータ前スモーク＆初見事故の防止）
- [x] **MP4（音声付き）書き出しの実機通し確認**（1280×720 60fps H.264 + AAC 48kHz、1.02 秒で出力＆`ffprobe`・抽出フレーム画像確認済み）
- [x] **外部メディア D&D 読み込み＆保存→アプリ再起動→完全復元の実機確認**（PNG / MP4 / WAV / 日本語テキスト＋Undo＋再オープン復元確認済み）
- [x] **日本語 IME 入力・変換確定（Enter）の実機確認**（`TypedField` で IME composing 中の `Enter` / `Escape` が編集を誤終了・破棄しないよう保護）
- [x] **`Animate all`（`A` キー）誤爆防止＆状態強調**（既定ショートカットを `Shift+A` へ変更、ON 時はトップバーにクリック解除可能な `● REC · Animate all` チップ＆インスペクター赤ドット強調を表示）
- [x] **エラー文言の整理＆ログ／バグ報告導線**（`SavedDisplay` の警告強調＋`Not taken:` 接頭辞整理、`Help` メニューに `Open Logs Folder` / `Report an Issue…`、クラッシュダイアログに `問題を報告` 追加）

## Phase 2：初見 30 秒体験（サンプル＆ACP 入口）
- [x] **ホーム画面にすぐ開けるサンプルプロジェクト 2〜3 本を同梱**
  - `shelves/samples/` に 3 本同梱（`01_Japanese_Typography.motolii` 日本語横書き＋縦書きタイポグラフィ、`02_Motion_Shapes.motolii` シェイプモーショングラフィックス、`03_Custom_Card_Playground.motolii` `Diagonal Blur`＋`.ui.js` カスタムカード体験用）
  - ホーム画面サイドバー上部に `SAMPLES` セクションを追加し、1 クリックでプロジェクトフォルダへ複製して即開けるよう実装（同梱原本は不変）・実機画面確認済み
- [x] **`Agent`（ACP）パネルに 1 クリックで試せるスタータープロンプト**
  - 会話開始前の `Agent` パネルに `TRY ASKING` 4 カード（波打つ日本語タイトル／カスタムカード付きエフェクト／音に反応して弾む動き／Tool Panel 用ツール）を追加し、1 クリック送信（起動待ち時は入力欄へ自動セット）を実装・実機画面確認済み

## Phase 3：コミュニティ循環（棚アイテムの共有パック）
- [x] **共有パック仕様の確定**（[docs/design/motoliipack.md](motoliipack.md) — `motoliipack.json`＋エフェクト／`.vs`／`.ui.js`／`.png`／Tool Panel `.js`＋クレジットを 1 つの `.motoliipack` ZIP にまとめる最小 v1 仕様、パストラバーサル防止付き）
- [x] **エクスポート導線**（Effects 棚のコンテキストメニューに `Export Pack (.motoliipack)…`、Tool Panel のカスタム JS パネルヘッダーに `Pack` チップを追加）
- [x] **インポート導線**（`.motoliipack` のウィンドウ D&D および `File → Import Pack (.motoliipack)…` → ユーザー棚へ展開＋`meta.yaml` クレジット追記＋`motolii_files_changed()` / `clearShelfMetaCache()` 自動ホットリロード）
- [x] **実機確認**：`motolii_pack_test.dart`（`Diagonal Blur.fs`+`.ui.js`、Tool Panel `.js`、パストラバーサル拒否 4/4 合格）＋クリーン `MOTOLII_OWN` で実機 `Motolii.app` にパック展開した Tool Panel 表示・`Pack` チップ・`File → Import Pack (.motoliipack)…` メニュー確認済み

## Phase 4：マルチ OS 配布パッケージ＆差分更新パイプライン
- [x] **Release `.app`（macOS）の完全自己完結バンドル化**
  - `packaging/macos/bundle_app.sh` で `libmotolii.dylib`＋依存 32 dylib を `Contents/Frameworks/` へ集約・`@loader_path/` へ書き換え（`otool -L` 外部参照 0 件監査＋ad-hoc 署名）、`filament_webgpu`・IBL ルーム・LGPL `ffmpeg`・`shelves/` を `Contents/Resources/` へ同梱
  - `app/lib/bridge/engine_paths.dart` / `motolii.dart` / `Release.entitlements` を自己完結バンドル起動対応にし、リポジトリ外 `/tmp`＋Homebrew なし `PATH`＋クリーン `MOTOLII_OWN` で実機起動＆サンプル表示を確認済み
- [x] **重い外部依存のプリビルド SDK 分離（CI 5〜10 分化）**
  - `.github/workflows/sdk-prebuilt.yml` を追加し、`engine/deps/**` 変更時のみ Filament / Dawn / Skia / ThorVG / libtess2 / IRIS をプリビルドキャッシュ
- [x] **アプリ本体のバイナリ差分更新導入（macOS `.app` / Windows `.exe`）**
  - `.github/workflows/release.yml` で macOS (`osx-arm64`) / Windows (`win-x64`) の Velopack (`vpk`) 差分 `.nupkg`・`releases.<channel>.json` を自動生成＋`Help → Check for Updates…`（`app/lib/workspace/state/update_check.dart`）実装
- [x] **`shelves/`（約 249 MiB / 2,931 ファイル）の SHA-256 マニフェスト差分同期**
  - `packaging/shelves_manifest.py`＋`app/lib/storage/shelves_sync.dart` 実装（実棚 2,931 ファイルのマニフェスト 478 KB、1 ファイル変更時の差分 28 KB 取得＆SHA-256 検証＋自動ホットリロード）
- [x] **Windows `.exe` リリースワークフロー整備**（`packaging/windows/bundle_windows.ps1`＋`app/windows/runner/main.cpp` のバンドル DLL `PATH` 対応＋`.github/workflows/release.yml` の `windows-x64` Velopack ビルドジョブ）

## Phase 5（将来トラック）：Linux 対応
- [ ] `app/linux` 追加＆エンジン側ゼロコピー共有テクスチャ（DMA-BUF / Vulkan）実装
- [ ] Linux 向け配布（Velopack または AppImage + zsync 差分更新）

---

## 進捗ログ
- 2026-11-22: ロードマップ作成（E2E ウォークスルー不具合 #1〜#10 修正・`origin/main` push 完了時点）
- 2026-11-22: **Phase 1 完了**（MP4+音声書き出し・保存再オープン復元検証、IME 変換保護、`Shift+A`＋`REC · Animate all` 強調、Help ログ／バグ報告導線・エラー表示整理）
- 2026-11-23: **Phase 2 完了**（`shelves/samples/` 3 本同梱＋Home サイドバー `SAMPLES` 1 クリック複製起動、`Agent` パネル 4 スタータープロンプト実装・実機 `Motolii.app` 画面確認済み）
- 2026-11-23: **Phase 3 完了**（`.motoliipack` 仕様策定・`motolii_pack.dart`＋`pack_service.dart` 実装、Effects／Tool Panel エクスポート・D&D／File メニューインポート＆自動ホットリロード、実機確認済み）
- 2026-11-23: **Phase 4 完了**（macOS 完全自己完結 Release `.app` バンドル＋リポジトリ外 `/tmp` 起動確認、Windows バンドルスクリプト＋ランナー対応、プリビルド SDK 分離 CI＋Velopack バイナリ差分リリース CI、`shelves/` SHA-256 差分同期＆`Help → Check for Updates…` 実装）
