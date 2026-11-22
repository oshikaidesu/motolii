# マルチ OS 配布パッケージ＆差分更新パイプライン

Motolii を macOS（`.app`）・Windows（`.exe`）向けに自己完結バンドル化し、**アプリ本体は Velopack バイナリ差分**、**`shelves/`（約 256 MB）は SHA-256 マニフェスト差分**で配信するための仕組み。

## 1. 自己完結バンドル構造

### macOS (`packaging/macos/bundle_app.sh`)
```text
Motolii.app/Contents/
├── MacOS/Motolii
├── Frameworks/
│   ├── libmotolii.dylib              # @loader_path/ へ書き換え済み
│   └── libluajit / libsqlite3 / libgst* / libav* / libass / libqjs / libonnxruntime ...
└── Resources/
    ├── engine/out/filament_webgpu/   # コンパイル済みマテリアル・スカイボックス
    ├── engine/third_party/{js/p5,anime}/
    ├── gstreamer-1.0/                # 主要メディアプラグイン
    └── shelves/                      # エフェクト・サンプル・スキン・パネル
```
- `app/lib/bridge/engine_paths.dart` はバンドル起動時に `Contents/Resources/engine` と `Contents/Frameworks/libmotolii.dylib` を自動検出し、初期プロジェクト保存先も読み取り専用の `.app` 内ではなく `$MOTOLII_OWN/Projects/` を使う。
- `bundle_app.sh` は `otool -L` で `/opt/homebrew/` や `/Users/` 参照が 0 件であることを自動監査し、`codesign --force --deep --sign -` で署名する。

### Windows (`packaging/windows/bundle_windows.ps1`)
- `motolii.exe` と同じフォルダへ `libmotolii.dll`・依存 DLL・`engine/out/filament_webgpu/`・`shelves/` を配置し、`app/windows/runner/main.cpp` が起動時に同梱 DLL フォルダを `PATH` へ追加する。

## 2. CI の高速化（プリビルド SDK 分離）
- `.github/workflows/sdk-prebuilt.yml`: `engine/deps/**` のピン変更時のみ Filament / Dawn / Skia / ThorVG / libtess2 / IRIS をビルドしてキャッシュ。
- `.github/workflows/release.yml`: 通常リリースはプリビルド SDK を復元し、Motolii 本体 C++ + Flutter のみをビルド（約 5〜10 分）。

## 3. 2 階層の差分更新
1. **アプリ本体（バイナリ差分 — Velopack）**
   - `release.yml` で前回リリースの `.nupkg` を取得し、`vpk [osx] pack` / `vpk pack` が `-delta.nupkg` と `releases.<channel>.json` を自動生成。
   - アプリ側 `Help → Check for Updates…`（`app/lib/workspace/state/update_check.dart`）がフィードを参照。
2. **`shelves/`（SHA-256 マニフェスト差分同期）**
   - `packaging/shelves_manifest.py` が全ファイルの SHA-256・サイズを記録した `shelves-manifest.json` を生成。
   - `app/lib/storage/shelves_sync.dart` がローカルとの差分のみを取得し、SHA-256 検証＋原子的置換（`.part` → rename）で反映後、`motolii_files_changed()` で即ホットリロードする。
