# Vism パック・グループ配列処理・察する ACP 設計

> 原則：エンジンは最小コア。p5.js / WGSL / ISF / TSL / Expression の元コードを一切隠蔽・再実装せず、使う人には「可視化＋操作ができる 1 枚の Inspector Vism カード」、潜る人には「Code パネルの入れ子 Notebook」としてそのまま解放する。

---

## 1. Vism パック（複数コード → Inspector 1 枚 ／ Code 入れ子 Notebook）

### フォルダ構造（1 フォルダ = 1 パック）
```text
KineticAura/
├── vism.json           # パック定義（name / about / ui / steps）
├── KineticAura.ui.js   # Inspector Vism カード UI（可視化＋操作）
├── motion.js           # Expression（配列処理 each）
├── draw.js             # p5.js / 生成（任意）
└── aura.wgsl           # WGSL / ISF / TSL シェーダー（任意）
```

### `vism.json` 最小スキーマ
```json
{
  "name": "Kinetic Aura",
  "about": "Group/layer array motion + shader look in one Vism card",
  "ui": "KineticAura.ui.js",
  "steps": ["motion.js", "aura.wgsl"]
}
```
- `steps` のパスは `vism.json` からの相対パス。`.js`（Expression / Sketch / Three）・`.wgsl`・`.fs`・`.css` を任意の順序で混在できる。
- `ui` 省略時は同フォルダ内の `<folder>.ui.js` / `card.ui.js` を探索。

### エンジンと UI の契約
1. **1 エントリ保持（`fx` スロット）**：レイヤーの `fx` には `id6:/.../KineticAura/vism.json` を 1 単位で格納する。ON/OFF（`fx_off`）・並替（`fx_move`）・削除・複製がパック丸ごと 1 操作で完結する。
2. **実行時の透過展開**：
   - `doc_expressions_fx` はパック内の Expression ステップ（`.js` with `each()` / `.css`）を順に取り出す。
   - `doc_fx_steps_with_ids` / `doc_fx_drawn` はパック内の描画ステップ（`.wgsl` / `.fs` / `.js` 等）をパックのインスタンス ID 付きで順に取り出す。
   - 各ステップのドキュメントパラメータ名は既存の `js_<stem>_<knob>`（Expression は `js_<knob>` または `js_<stem>_<knob>`）＋パック ID 接頭辞に従い、複数ステップで同名衝突がある場合はステップ stem 付きで区別し、非衝突時は短縮名でも解決する。
3. **Inspector（使う人の顔）**：`doc_cards_of` はパック全体を 1 枚のカードとして返す。`motolii_card_ui_file` が `vism.json` の `ui` を返し、全ステップのパラメータが 1 枚の `ValuesCard`（Vism UI ＋ 下部 `> Parameters` 折りたたみ）へ集約される。キーフレームと Macro `○` 接続もそのまま届く。
4. **Code パネル（潜る人の顔）**：パックのカードは 1 つの親セルとして現れ、展開すると `UI`（`.ui.js`）および `steps` 各ファイルが **入れ子 Notebook のサブセル** としてそのまま編集・保存即リロードできる。
5. **後方互換**：従来の単体エフェクト（`.fs` + `.ui.js` 等）とツールパネル（`panels/*.js`）は一切壊さずそのまま動作する。

---

## 2. グループレイヤー × 配列処理（`each(i, n, t, k, at)`）

- 従来の `doc_members(d, layer)` は `split: "letters"` と単一レイヤーの `copies` のみ対象だった。
- **拡張**：親レイヤーがグループレイヤー（`kind == "group"` または `shape == "null"` で子を持つ親）かつ `doc_expressions_on(d, parent)` を持つとき：
  - 親の直下子レイヤー一覧（layer 順、配列 `[0..n-1]`）を `doc_expressions_lay(d, parent, scs, n, ...)` で 1 フレーム 1 回評価し、`d.place_cache` にキャッシュする。
  - 各子レイヤー `i` は `doc_place` で親配列評価結果 `laid[i]` の位置・回転・スケール・行列を合成し、不透明度も `laid[i].opacity` を乗算する。
  - 子レイヤー自身のキーフレームやエフェクト、さらにグループ自身の `copies` 複製ともそのまま合成される。

---

## 3. 察する ACP（プロツール密度＋直近操作ログ＋Inspector Vism 第一選択）

- **廃止**：`TRY ASKING`＋4 枚の定型カード＋裏プロンプト文の UI 露出。
- **静かな空画面**：コンポーザーの 1 行プレースホルダーが今の状況（選択・グループ・再生位置・エフェクト数）に合わせて変わり、コンポーザー上には **0ms ローカル検知で実態に引っかかった時だけ最大 2 個の極小チップ**（短句のみ、裏プロンプト非表示）を表示する。
- **直近操作ログ（Recent Activity）**：`WorkspaceController` に最新 8 件の操作リングバッファを持ち、ACP 送信時の状況コンテキストへ自動添付する（例：追加した FX・選択変更・停止した時刻・Undo 等）。これにより「ちょっと強い」「ここ寂しい」「これ 1 枚にまとめて」といった主語ゼロの短文でも意図を察せる。
- **Vism 第一選択**：ACP ガイドは、レイヤー／グループ固有の表現・操作には **Inspector Vism（`.ui.js` / `vism.json` パック）** を第一選択とし、ドッキングパネル（`panels/*.js`）は複数レイヤー横断の制作ツール専用と明記する。
