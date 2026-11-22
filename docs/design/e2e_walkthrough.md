# Motolii 全体通し E2E ウォークスルーシナリオ（10 ステージ）＆ 発見バグ一覧

1 本のモーショングラフィックスを新規作成から動画／画像書き出しまで作り切ることで、全ペイン・全インスペクターカード・全インタラクションの繋ぎ目を一気通貫で検証するためのシナリオ。

## ステージ一覧

1. **起動・プロジェクト作成・窓まわり**
   - アプリ起動 → 新規プロジェクト作成 → 各ペインのリサイズ／タブ切替／Undo・Redo
2. **シェイプ・Fill / Stroke・Paths**
   - シェイプ作成 → グラデーション Fill / Stroke（Inside / Center / Outside）→ Paths オペレータ追加・並べ替え → ステージ上の直接ドラッグ＆アンカー操作
3. **日本語テキスト組版 & OpenType**
   - 日本語＋英数混在テキスト → 縦書き／横書き・禁則・ぶら下げ・文字種別サイズ・OpenType 折りたたみ → ステージ反映
4. **合成・Blending / Matte・クリッピング**
   - 複数レイヤー重ね → Blending + Matte / Feather → タイムラインでの順序入れ替え・クリッピングマスク・表示／非表示
5. **エフェクト重ね & `.ui.js` カスタムカード**
   - `Diagonal Blur` 等を複数重ね → `ui.svg` コンパス操作 → **`> Parameters`** 展開＆キーフレーム打ち → 並べ替え・目アイコン ON/OFF・コピー＆ペースト・削除
6. **Expression カスタムカード（Jolt / Wave / Lyric / Field / Audio）**
   - `Rigid Body` + `Wind`、`Field`、`Wave`、`Lyric`、`Rise to Sound` の適用・SVG 操作・マルチハンドルドラッグ・再生追従
7. **Macros（信号モジュレーション）**
   - ノブ操作・`○` プラグ D&D・`Map` モード連続割り当て・インライン `Min..Max` レンジ調整・Wave / Audio / Layer ソース切替・`Rand` / `Variations`
8. **タイムライン・Ease・再生・複数選択**
   - キーフレーム追加／移動 → Tool Panel の Ease カーブ編集 → スクラブ・再生・ループ → 複数レイヤー選択での一括操作
9. **Tool Panel & カスタムタブ（ドッキング＋ホットリロード）**
   - `Stagger` / `Quick Rig` / `Align` の実行 → `Tab` で独立ドッキングタブ切り出し＆閉じる → `.ui.js` 保存ホットリロード＆構文エラーからの `Retry` 復帰
10. **保存・再読み込み・書き出し**
    - 保存 → 再オープンで全状態復元確認 → 書き出しパネルで出力＆出力ファイル確認

---

## 2026-11-22 実機通し検証で発見した不具合・違和感一覧

### 重大（クラッシュ・機能不能）

1. **[修正済み] 終了／プロジェクト切替／タイル破棄時の Filament リーク＆ヒープ破損**（`engine/document/match/match_layers.cpp`, `engine/stage/effects/screen_fx.cpp`, `engine/entry/render_thread_loop.cpp`, `engine/entry/window.cpp`, `engine/document/undo.cpp`, `app/lib/bridge/motolii.dart`, `app/lib/workspace/workspace.dart`, `app/lib/workspace/state/tiles/tile_queue.dart`）
   - `motolii_close` 前に `doc_teardown` / `screen_stack_off` / `live_close`（`live_lock` 排他）で Filament・ThorVG・Interop リソースを完全解放し、Dart 側も `ws.detach()`＋`Overlay` キー更新で閉じた旧エンジンの解放済みネイティブバッファを参照しないよう修正。複数スレッドで競合する静的キャッシュ（`room()` / `folders.cpp` / `recipes.cpp` / `viewer_settings.cpp`）にも mutex を追加。
2. **[修正済み] 5 秒アイドルキャッシュ／タイル描画時の Dawn WebGPU `updateDescriptorSetTexture` use-after-free クラッシュ**（`engine/stage/render/render_layers.cpp`, `engine/document/evaluate/moment_fx.cpp`, `engine/stage/layer_effects/layer_fx.cpp`）
   - エフェクト付きレイヤーをマットに使った際、`thing_fx_textures` がオフスクリーンテクスチャを再生成しても `s.mattes` の `picture` バインドが更新されず破棄済みハンドルを参照していた。`matte_picture` / `refresh_matte_picture` で再バインドし、連続 27 フレームキャッシュでもクラッシュしないことを確認。
3. **[修正済み] `Paths` → `Zig zag` オペレータ追加でシェイプが画面全体に爆発**（`app/lib/inspector/paths/paths_body.dart`）
   - 追加時の初期値 `_defaults` がエンジン単位（`zigzag: 0.04` 等）ではなく 100 倍近い値になっていたため、`values.h` に合わせた初期値＋`[min, max]` クランプへ修正。
4. **[修正済み] `doc.flag` の UI 専用フラグがエンジンに弾かれ、`> Parameters` 折りたたみが開かない／`Macros Map` でエラーが出る**（`app/lib/workspace/inspector_feed/values.dart`）
   - `writeFlags` のローカル状態許可リスト `looked` に `*.params`、`macros.*`、`transform.link`、`text.ot` を追加。
5. **[修正済み] ドッキングタブ（`S Stagger ×`）を閉じるとペイン比率が崩れる**（`app/lib/workspace/window/panes.dart`）
   - `docking` 1.16.2 の `AddItem` / `RemoveItem` が再構築コンテナの `weight` を落とす問題を、ツリーパス単位で `weight` を退避・復元する `_preservingWeights` で解消。

### 中・小（UI 操作性・見た目）

6. **[修正済み] `Fill` カードの `+ Stroke` ボタンが反応しない**（`engine/community/quickjs/script.cpp`）
   - `fx_entry_id` の長さ判定が `entry.size() <= 7` となっており、7 文字のストローク ID エントリ（例: `"7ea842:"`）を弾いていたため `< 7` に修正。
7. **[修正済み] `Paths` カードの `Inner radius` がダークテーマで真っ白背景になる**（`engine/document/values.h`, `engine/document/kinds.h`）
   - `inner` の下限が `0.05` / `0.01` になっており、`Rect` 既定値 `0.0` が範囲外（反転ハイライト）扱いになっていたため下限を `0` に修正。
8. **[修正済み] `Rect` 単色 Fill のメインプレビュー枠が暗灰色＋`—` のまま表示される**（`app/lib/inspector/fill/fill_body.dart`）
   - 空の `v_fill_media` が `'—'` として渡されメディア有り扱いになっていたため、`'—'` を空文字として正規化。
9. **[修正済み] テキスト欄クリック後の `Cmd+A` / ペーストがグローバルショートカットに吸われやすい**（`app/lib/inspector/text/text_notebook.dart`, `app/lib/widgets/text_gestures.dart`, `app/lib/workspace/commands/keymap.dart`）
   - `TextNotebook` の空白行／余白タップで確実に `TypedField` へフォーカスが入るよう `focusNode` を共有し、入力中（`_typing`）は `edit.selectAll` / `copy` / `paste` / `cut` をテキスト側へ譲るよう修正。
10. **[修正済み] ホーム画面の `1 projects` の単複表記、空プロジェクト時のタイムライン上部キャッシュ点々表示**（`app/lib/workspace/window/home_sidebar.dart`, `engine/preview/playback_cache.cpp`）
    - `1 project` / `N projects` の単複切替と、`d.on_stage.shown.empty() && !s.over` の空プロジェクト時はキャッシュ生成・参照をスキップするよう修正。

### 正常動作を確認できた主要機能
- ホーム画面 → ワークスペース遷移・ステージ上シェイプ作成・直接ドラッグ移動
- タイムライン目アイコンでの非表示切替・縦書きテキスト切替
- Effects 棚 1322 件の検索（`.ui.js` サイドカーは綺麗に非表示）
- **`Diagonal Blur.ui.js`（`ui.svg` 極座標コンパス + `45°` プリセット）の実アプリ動作＋ステージ GPU ブラー即時反映**
- **`Macros` カード追加・`Map` モードでの全フィールド `M1` バッジ表示**
- **`Tool Panel` での `Stagger` QuickJS パネル表示＆`Tab` 独立ドッキングタブ切り出し**
- **`Render` ダイアログからの 1920×1080 480 フレーム PNG 連番高速書き出し ＋ MIT クレジット（`e2e_demo_credits.txt`）自動生成**
