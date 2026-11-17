# 夜間整理レポート (2026-11-16)

AGENTS.md 原則 1 に「エンジンは最小コア、外に出せるものは全部外へ」の軸を明文化したうえで、同夜に 16 件の整理コミットを積んだ。

## 走ったこと

- 完全版の原子分解: motolii_complete.md（462 行 → 793 行、全系 737 本中 85% を触る）に基づいて 3.A 機械的直し・3.B 軸に沿う直しを順に適用
- 1 コミット 1 件・各コミット前に `dart analyze lib` と `./engine/check_syntax.sh` を通す
- 最後に `engine/build.sh lib` で 177 本ビルド → ok、`flutter test` → 3 件失敗（**baseline でも同じ 3 件が落ちる既存の accessibility tap target 違反で、今夜の変更由来ではない**）
- `tool/live.sh` で起動確認: Motolii アプリは正常に動き、Depth パネルの視野角が engine の 24mm センサー式に合って 22.8° で表示されている（修正前は 33.4° で表示されていた）

## 積んだコミット（新しい順）

1. `refactor: canvas_redraw_now(d) に 3 文を 1 本化、5 箇所を置換` ── 切る系候補 9
2. `move: AviUtl2 globals の Lua 90 行を C++ 文字列から aviutl_globals.lua へ` ── 軸適用 #46
3. `refactor: cache_folder(name) を engine/base/cache_folder.h に、6 箇所を置換` ── 1.11
4. `refactor: read_text(path) を engine/base/file_read.h に、簡単な 4 箇所を置換` ── 1.15 の 4/36（残り 32）
5. `refactor: FNV-1a 64 を engine/base/hash.h に 1 本化、9 ファイル 11 箇所を置換` ── 1.1、B117
6. `refactor: homeFolder と parentFolderOf の同本体重複を 1 定義ずつにまとめる` ── B47 時限爆弾解除、1.23
7. `remove: studio.glsl / spectrum.glsl から未使用の定義を外す` ── B88
8. `remove: 死にコード engine/materials/poster.mat（誰も load しない Filament 材質）` ── B88
9. `remove: 死にコード motolii_grid と scipy_lsap 依存` ── B19
10. `remove: 死にコード TrimPath カードと trim_card_test（本番から呼ばれていない）` ── B18、377 行
11. `remove: isf.cpp の未使用 Tint writer include を外し <sstream> を明示する`
12. `remove: Motolii::dragged と毎周の held.tried コピー、存在しない motolii_revised の参照` ── B114
13. `fix: Depth ツールの視野角が engine と違って約 1.5 倍広く描かれていた` ── **B01 確定バグ**
14. `fix: undo.cpp の旧 copy_* → Repeater 移行で drop の表名が違い毎回 rollback していた` ── **B98 確定バグ**
15. `docs: AGENTS.md 原則 1 に「エンジンは最小コア」を書き加える` ── 今夜の判断の軸

## 削った行

- 製品 Dart コード: 約 377 行（TrimPath + test）
- Engine C++: 約 150 行（motolii_grid、Motolii::dragged、重複ハッシュ、重複 cache 組み立て、重複 canvas_redraw、aviutl_globals 外出し分）
- Engine .mat / .glsl: 約 70 行（poster.mat、studio/spectrum 未使用）
- 増えた: engine/base/hash.h（46 行）、engine/base/file_read.h（38 行）、engine/base/cache_folder.h（27 行）、aviutl_globals.lua（86 行、C++ 文字列からの移動）
- 正味: engine の重複が減り、横断の「どう動かすか」は base/ に集約

## 手を付けなかったもの（起きたとき一緒に判断）

### 3.A 機械的だが時間切れ
- read_text 残り 32 箇所（4/36 を済ませてパターンは確立。stringstream で複雑に連結する箇所、binary mode、多段 stream は個別の判断が要る）
- matte_released の 3 重コピー（evaluate_clipping.cpp 内）、path_read、libtess2 の 2 回呼び出し、各種同名異義の改名
- 候補 51 以降の engine 内の小さな複製（`Mesh::bounds`、SQL キー有り判定 4 組、`doc_act` RAII 54 箇所、など）

### 3.B 軸に沿うが設計判断が要る
- **3D 形状 render_shapes → shelves の three.js へ**（#37）── shelves/solids の Cube.js / Torus.js / Ellipsoid.js と C++ 側 4 形状を描画で比べる必要がある（原則 7）
- **AE 式の wiggle/noise を lottie-web の ExpressionManager / ThorVG の `_wiggle` へ**（#50）── まず QuickJS 単独で動くかの調査が先
- **Cavalry の behaviour/falloff の C++ 再実装を Cavalry の元 JS へ**（#71）── 同じく
- **VideoClock を media/ に 1 本化**（#20）── ループ・逆再生の挙動が変わり得るので画面確認が先
- Dart の擬似 WGSL 自作ループの解体（#30）── engine が型付き値を返す口を足す設計

### 3.C 画面確認が要る
- B73 `matte()` が Scene/View/Texture を破棄しない（メモリリーク）── matte lifetime の設計判断が要る
- B01（Depth fov）は修正済、画面で 22.8° を確認済み。他の画面変化が出るもの（B03 Blend ツール複数選択、B04 Transform drag しきい値、B06 サイズ 16〜8192 偶数、B07 24fps rate、B29 色スライダー、B29 lottie_parameters 3 数以上を色、など）は画面で動かしてから直す

## engine が外へ出せる余地（軸の効き方）

完全版の 3.D で見積もった「外に出す」6 件のうち、今夜 #46（aviutl Lua）を済ませた（約 90 行）。残り 5 件（#37、#50、#71、#73、#74）で engine から数百行が出せる見通し。最初に動かすべき調査 3 件：
1. Cavalry の元コードが QuickJS で動くか
2. AE 式の lottie-web ExpressionManager または ThorVG `_wiggle` が単独で動くか
3. shelves の three.js の Cube/Torus/Ellipsoid が C++ の 4 形状と描画で一致するか

これら 3 件が通れば #37、#50、#71 がすべて実行に移せる。

## 既知の確定バグで画面で確かめる価値が高いもの

Round 1/2 統合の §2 「画面で確かめれば白黒が付くもの」:
- **B01 Depth の円錐** ── 今夜修正済、22.8° で確認済
- B03 Blend ツールと複数選択
- B04 Inspector の Transform プレビュー
- B06 サイズに 10000 を打った時
- B07 24 fps の書類で `.5/rate` の許容幅
- B29 AviUtl/Lottie/splatfx の色が 3 本のスライダーに割れる
- B74 4096 超の画像を sampleImage で読む
- B75 dash と gap を分けた破線
- B87 sketch に 7 枚目の画像
- B89 duration=0 のレイヤー
- B144 高密度ズームでのキーの掴みと選択
- B149 fonts の footer でダブルクリック
- B150 create の pasted タイルを既存と同名に改名
- B98 旧 copy_* 入りの書類を開くと migration が rollback される ── 今夜修正済

## スクリーンショット

- `motolii_after_refactor.jpg` ── 今夜の変更後に tool/live.sh で動いているアプリ。右の Camera パネルで Depth ツールの視野角が engine と一致した 22.8° で表示されている
