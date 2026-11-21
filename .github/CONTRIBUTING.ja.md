# コントリビューションガイド

[English](CONTRIBUTING.md)

## 貢献の方法

- **Issue：** バグ報告、ビルドエラーの報告、対応してほしい外部フォーマットや表現例の提案（URL と特徴を添えてください）。日本語・英語どちらのテンプレートも用意しています。
- **Pull Request：** 歓迎します。Motolii は Apache-2.0 と MIT のデュアルライセンスです。特段の記載がない限り、提出されたコードも同じデュアルライセンスで提供されるものとします。
- **同梱作品の作者の方へ：** クレジット表記の修正や同梱の取り下げをご希望の場合は Issue でお知らせください。速やかに対応します（[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md)）。

行動規範（[Code of Conduct](CODE_OF_CONDUCT.md)）を遵守してください。セキュリティ上の脆弱性は公開 Issue ではなく GitHub の Security タブから報告してください（[`.github/SECURITY.md`](SECURITY.md)）。

## 開発環境のセットアップ

ビルド手順は [`README.ja.md`](../README.ja.md#ビルドと実行) を参照してください（詳細なトラブルシューティングは[ビルドガイド](../docs/archive/using/guide.ja.md)にあります）。クローン後に一度だけ pre-commit フック（Dart のフォーマットチェック）を有効にしてください：

```bash
git config core.hooksPath .githooks
```

コードベースの全体像は [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)、[`engine/README.md`](../engine/README.md)、[`app/README.md`](../app/README.md) にまとまっています。

コードおよびドキュメントの用語は After Effects・Filament・Flutter・Blender の標準用語（アプリ、エンジン、レイヤー、プロジェクト、プレビュー／`Stage`、棚／Shelf）に揃え、独自用語を増やさない方針です。

## テストとチェック

Pull Request を送る前にローカルで以下を実行してください。CI（`.github/workflows/checks.yml`）でも同じチェックが自動実行されます：

```bash
cd app && dart format . && flutter analyze && flutter test
```

C++ エンジン側のチェック：
- `./engine/check_syntax.sh` — ビルドなしの高速構文チェック
- `engine/build.sh` — エンジンの差分ビルド
- `engine/build.sh test` — ビルド＋C++ ユニットテスト（`ctest`）の実行

フルビルドは GitHub Actions（`.github/workflows/build.yml`、Apple Silicon macOS）で `engine/`・`shelves/`・`app/`・`Brewfile` を変更する push / PR に対して実行されます。テストの詳細は [`docs/TESTING.md`](../docs/TESTING.md) を参照してください。

## 開発スタンス

**自作コードは将来の保守負債になります。** まず既存の OSS や公式実装を探し、元の仕様のまま動かすことを最優先にします。サードパーティ製コードは極力改変せずライセンスと出典を添えて管理し、改変が必要な場合はビルド時に適用する `.patch` ファイルに分離します。

## 設計原則

以下の原則はプロジェクトの核であり、これに反する変更はマージしません。AI エージェント向けの [`AGENTS.md`](../AGENTS.md) にも同じ原則を記載しています。

1. **外部の表現を独自に再実装しない。** AE エクスプレッション・Cavalry・p5.js・シェーダー・AE プラグインは元のランタイムでそのまま動かす。同じ挙動を C++ で手書き模倣しない。
2. **根拠なくパラメータ値を制限しない。** スライダー範囲は操作性のための表示であり、数値入力で範囲外を指定することを拒まない。制限を設ける場合は元仕様の出典を明記する。
3. **アプリ内に Web ページを埋め込まない。** UI はソースコードから直接生成し、編集はコードへ書き戻す。設定の二重管理をしない。
4. **既存機構で解決できる課題に新しい仕組みを足さない。** 外部ライブラリの追加は、Motolii 既存機能で解決できない場合のみ検討する。
5. **Dart は見た目と入力に専念させる。** ボタン・オーバーレイ・選択・スライダーは Flutter / `naked_ui` に委譲する。Inspector のカードは `ValuesCard` を正本とし、重複する手書き UI は正本に統合する。

## ルール

1. **書く前に探す。** 新規実装の前に `engine/`・`app/`・`shelves/` および既存の OSS を確認してください。
2. **1 ファイル 1 責務。** 役割ごとに簡潔に分割してください。実験的なコードは作業ブランチに留め、`main` には本体が使うコードのみを入れます。
3. **コミットメッセージ：**
   - 1 行目（件名）：72 文字以内で変更内容を要約（例：`fix(inspector): preserve focus on slider drag`）。
   - 空行を挟んだ本文：変更理由・確認した内容・未確認事項を記載。
   - 参考にした実装・仕様・アルゴリズムがある場合は出典（URL・バージョン・コミットハッシュ）を必ず記載。
4. **サードパーティ作品・ライブラリの追加：**
   - 作者のディレクトリ構成を極力維持し、`LICENSE` と `SOURCE.txt`（作者・ライセンス・取得元 URL）を同梱する。
   - 明示的なライセンス本文がない作品はリポジトリに同梱せず、ビルド時取得スクリプトを使う（例：`engine/deps/midi_roll.sh`）。
   - 外部ライブラリへの変更は `engine/deps/patches/<ライブラリ>/` にパッチとして分離し、ビルド時に適用する（例：`engine/deps/thorvg.sh`）。
   - [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) に追記する。

## 取り組みやすいタスク

| タスク | 着手箇所 | 難易度 |
|---|---|---|
| 配布可能な macOS `.app` バンドル作成：Homebrew 動的ライブラリ（GStreamer・GLib・SQLite・LuaJIT・QuickJS・FFmpeg）を [dylibbundler](https://github.com/auriamg/macdylibbundler) 等で `.app` 内に同梱 | `engine/edit.sh`、`app/macos/` | 中 |
| AviUtl2 スクリプトの未実装 API（`obj.computeshader` や標準エフェクト等）を AviUtl2 の lua.txt / `sashimono-edit` 準拠で実装 | `docs/archive/design/aviutl2_converter_plan.md`、`engine/community/aviutl/aviutl.cpp` | 中〜難 |
| TSL エフェクトの Effects 棚への拡充 | `engine/community/three_shading_language_to_shelf/`、`docs/archive/design/tsl_collection.md` | 中 |

## 既知の制限事項

- 動作確認は Apple Silicon macOS のみ（Windows / Linux は未検証）。
- エンジン（`libmotolii.dylib`）が Homebrew のライブラリを動的リンクしているため、ビルドした `.app` をそのまま別 Mac へ配布することはまだできません。
