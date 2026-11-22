# `.motoliipack` 共有パック仕様（v1）

コミュニティでエフェクト・エクスプレッション・カスタム UI カード（`.ui.js`）・Tool Panel 用 QuickJS ツールを 1 ファイルでやり取りするための最小 ZIP フォーマット。

## 構造

拡張子 `.motoliipack` の標準 ZIP アーカイブ。

```text
MyGlow.motoliipack
├── motoliipack.json          # マニフェスト（UTF-8 JSON）
├── effects/                  # または expressions/ / panels/ / create/
│   ├── MyGlow.fs             # 本体
│   ├── MyGlow.vs             # 任意：頂点シェーダー
│   ├── MyGlow.ui.js          # 任意：カスタム操作カード UI
│   └── MyGlow.png            # 任意：サムネイル
```

## `motoliipack.json`

```json
{
  "version": 1,
  "kind": "effect",
  "name": "MyGlow",
  "author": "Alice",
  "license": "MIT",
  "source": "https://example.com/myglow",
  "files": [
    "effects/MyGlow.fs",
    "effects/MyGlow.ui.js"
  ]
}
```

- `version`: 整数 `1`。
- `kind`: `"effect"` / `"expression"` / `"panel"` / `"create"`。
- `name`: 表示名。
- `author` / `license` / `source`: クレジット情報（任意）。インポート時にユーザー棚の `meta.yaml` へ追記保存される。
- `files`: 展開対象の相対パス配列。許可されたルート（`effects/`・`expressions/`・`panels/`・`create/`）配下のみ展開し、`..` や絶対パスは拒否する。

## インポート時の展開先とホットリロード

- ユーザー棚（`$MOTOLII_OWN`、既定は macOS `~/Library/Application Support/Motolii` / Windows `%APPDATA%/Motolii`）配下へ展開。
- 展開直後に `motolii_files_changed()` と `clearShelfMetaCache()` を呼び出し、アプリ再起動なしで Effects 棚・Tool Panel・Inspector カスタムカードへ即反映する。
