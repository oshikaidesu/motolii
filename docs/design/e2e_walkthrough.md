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

1. **[修正済み] 終了／タイル破棄時の Filament リーク＆クラッシュ**（`engine/stage/render/render_stage.cpp` / `app/lib/workspace/state/tiles/tile_queue.dart`）
   - `close_stage` が `MaterialInstance` を破棄せず `Engine::destroy` も呼んでいなかった（`destroying material "flat" but 6 instances still alive.`）、かつ 4 つの `TileQueue` が並列で `Motolii.open` を起動していた。→ `close_stage` 修正＋`TileQueue` 直列化済み。
2. **[未修正・重大] 5 秒アイドルキャッシュ／タイル描画時の Dawn WebGPU `updateDescriptorSetTexture` use-after-free クラッシュ**
   - 症状: `breadcrumb: cache` またはタイル描画後に `Filament panic: Postcondition in handleCast:131 reason: use-after-free of Handle with id=87846`（`WebGPUDriver::updateDescriptorSetTexture`）で SIGABRT。
   - 発生箇所: `render_thread_loop.cpp:258`（5 秒アイドル後の `stage_cache_one`）およびバックグラウンドタイル描画時。
3. **[未修正・重大] `Paths` → `Zig zag` オペレータ追加でシェイプが画面全体に爆発**（ステージ 2）
   - 症状: `Rect` に `Paths` → `+ Operator` → `Zig zag` を追加しただけで、シェイプのメッシュ／ポリゴンが画面いっぱいに崩壊する（`06_text_and_zigzag.png`）。
4. **[未修正・重大] `doc.flag` の UI 専用フラグがエンジンに弾かれ、`> Parameters` 折りたたみが開かない**（ステージ 5・7）
   - 症状: `Diagonal Blur` カスタムカードの `> Parameters` を押しても `Not taken: the document has no v.Diagonal Blur.params` が出て展開しない。同様に `Macros` の `Map` ボタンでも `Not taken: the document has no macros.map` がトップバーにエラー表示される（`11_diag_blur_and_stagger.png`, `12_custom_card_params_and_tab.png`）。
5. **[未修正・中] ドッキングタブ（`S Stagger ×`）を閉じるとペイン比率が崩れて Stage が 18% に縮小＋レイヤー選択が外れる**（ステージ 9）
   - 症状: Tool Panel から `Tab` で切り出した `Stagger` タブの `×` を閉じると、`Inspector` が画面半分まで広がり `Stage` が 18% まで縮み、選択中レイヤーが `Nothing selected` になる（`13_macro_map_and_expressions.png`）。

### 中・小（UI 操作性・見た目）

6. **[未修正・中] `Fill` カードの `+ Stroke` ボタンが反応しない**（ステージ 2）
   - `Rect` の `Fill` カードで `+ Stroke` を押してもストローク行が追加されない（`05_stroke_and_paths.png`）。
7. **[未修正・中] `Paths` カードの `Inner radius` がダークテーマで真っ白背景になる**（ステージ 2）
   - `Rect` 選択時、`Paths` の `Inner radius 0%` だけ白背景＋黒文字で浮いて見える（`04_shape_inspector.png`）。
8. **[未修正・中] `Rect` 単色 Fill のメインプレビュー枠が暗灰色＋`—` のまま表示される**（ステージ 2）
   - `Text` では `#7F7F7F` で塗られるが、`Rect`（`#59AEA5`）では大スウォッチ枠が `—`（未設定風）に見える（`03_shape_created.png` vs `07_text_jp_vertical.png`）。
9. **[未修正・小] テキスト欄クリック後の `Cmd+A` / ペーストがグローバルショートカットに吸われやすい**（ステージ 3）
   - Text カードのノート欄クリック後に `Cmd+A` を押すと `Animate all` が ON になり、文字列の差し替えが入らなかった（`08_jp_text_and_fx_shelf.png`）。
10. **[未修正・小] ホーム画面の `1 projects · 28KB` の単複表記、空プロジェクト時のタイムライン上部キャッシュ点々表示**（ステージ 1）
    - `01_launch.png`、`02_workspace.png`。

### 正常動作を確認できた主要機能
- ホーム画面 → ワークスペース遷移・ステージ上シェイプ作成・直接ドラッグ移動
- タイムライン目アイコンでの非表示切替・縦書きテキスト切替
- Effects 棚 1322 件の検索（`.ui.js` サイドカーは綺麗に非表示）
- **`Diagonal Blur.ui.js`（`ui.svg` 極座標コンパス + `45°` プリセット）の実アプリ動作＋ステージ GPU ブラー即時反映**
- **`Macros` カード追加・`Map` モードでの全フィールド `M1` バッジ表示**
- **`Tool Panel` での `Stagger` QuickJS パネル表示＆`Tab` 独立ドッキングタブ切り出し**
- **`Render` ダイアログからの 1920×1080 480 フレーム PNG 連番高速書き出し ＋ MIT クレジット（`e2e_demo_credits.txt`）自動生成**
