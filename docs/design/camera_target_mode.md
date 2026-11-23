# カメラ設計 — Boxcam 額縁 × ゼルダ Z 注目 × FPS レーダー

> 枯れた技術の水平思考（横井軍平）：ゲームで解かれてきた 3D カメラ制御（Z 注目・FPS ミニマップ）と 2D モーショングラフィックスの Boxcam を、キーボード／マウス完結の最小コアで統合する。

ユーザー向け操作ガイドは [CAMERA.ja.md](../CAMERA.ja.md)、調査メモは [game_camera_ux_research.md](../internal/game_camera_ux_research.md) を参照。

---

## 確定アーキテクチャ（実装済み）

1. **額縁中心モデル（Boxcam 互換）**
   - カメラの `(x, y, z)` はレンズ座標ではなく **ピント面の額縁中心（`look`）**。
   - `eye = look + R_y(rotate_y) * R_x(rotate_x) * R_z(rotate) * (0, 0, kStageBack * distance)`。
   - `rotate_x = rotate_y = 0` では純粋な Boxcam として振る舞う。`focal_length` の既定値は `45 mm`、`focus == 0` の自動ピント距離は `length(eye - look)`（額縁面）に一致する。
2. **ライブ追従 Z 注目（`target` プロパティ）**
   - `target`（型 `"thing"`）にターゲットレイヤー ID をキーフレーム可能で保持。
   - 評価時はターゲットのワールド座標をリアルタイム参照し、`target` キー間はセグメントのイージングでワールド座標間を補間する（再帰ガードあり）。
   - `doc_number` は `"thing"` プロパティを離散ステップ評価し、中間フレームで不正 ID が出ないようにする。
   - 解除時は現在フレームのターゲット座標をカメラの `(x, y, z)` へベイクしてジャンプを防ぐ。
3. **Alight Motion 型タイムライン**
   - 専用のワールドタイムラインは持たず、通常レイヤーバー＋キーフレーム＋イージング＋複数カメラの上優先ルールで完結する。
4. **瞬間俯瞰 `3D View` と角度正対 `Match View`**
   - 既定の Stage は本番カメラ（`s.film`）。`3D View` ON 時のみ `god_view(s, true)` で作業カメラ（`s.god`）へ切り替え、アクティブカメラの額縁中心（`seen.look`）を周回する。
   - 3D View のギズモは四角錐・後方 `eye` ハンドルを廃し、純粋な **Boxcam 額縁**（外枠・三分割ガイド・中心ドット・選択時の四隅リサイズ＆上辺ロールノブ）のみ描画する。
   - **`Match View`**（`Option+C`）は `distance`・位置・`target`・`rotate` を保持したまま `rotate_y / rotate_x` のみを現在の 3D View 角度へ正対させ、`Animate all` に関係なく現在時刻へキーフレームを記録する（未キーかつ `t > 0` の初回実行時は `t = 0` の元の値も自動保持）。
   - 2D レイヤー（`space: "2d"`）は `facing_cam = d.working_camera.on ? s.camera : s.film` により、どちらのビューでも現在表示中のカメラへ正対追従する。
5. **FPS レーダー型 Depth パネル**
   - ワールド固定 XZ 平面の第三者俯瞰マップ上に、空間レイヤー（`space != "2d"`）の現在時刻スラブと、動き回るカメラマーカー・視界コーン（FOV）・DOF 帯・Boxcam 額縁ライン・Z 注目リングを描画する。
   - 正本である `Camera` カードはインスペクター側に 1 つだけ置き、Depth パネル右側は光学サマリ（DOF・Near・Far・Focus・Distance）に専念させる。

---

## 実装マップ

| 領域 | 主なファイル | 役割 |
|---|---|---|
| C++ カメラ評価 | [camera.cpp](../../engine/document/evaluate/camera.cpp) | `doc_view_camera_of`（額縁中心＋Z 注目補間）、`working_view_shown`（`seen.look` 周回）、`god_view` 切替 |
| C++ ステージカメラ | [render_stage.cpp](../../engine/stage/render/render_stage.cpp), [render_layers.cpp](../../engine/stage/render/render_layers.cpp) | `s.film` 既定バインド、`god_view(s, on)` による `s.god` / `s.film` 切替 |
| C++ プロパティ定義 | [kinds.h](../../engine/document/kinds.h), [values.h](../../engine/document/values.h), [card_table.h](../../engine/document/card_table.h), [arrange.cpp](../../engine/document/edit/arrange.cpp), [value_at.cpp](../../engine/document/evaluate/value_at.cpp) | `target`・`distance`・`focal_length`（既定 45 mm）、`"thing"` の離散評価 |
| C++ テスト | [cards_test.cpp](../../engine/document/cards_test.cpp) | `Cards.CameraFrameCenteredAndZTargetInterpolation` |
| Dart ギズモ＆操作 | [camera_gestures.dart](../../app/lib/workspace/stage/camera_gestures.dart), [view_painter.dart](../../app/lib/workspace/stage/view_painter.dart), [stage_pointer.dart](../../app/lib/workspace/stage/stage_pointer.dart) | 純粋 Boxcam 額縁描画、Z 注目ロック／解除、`cameraAlignToView`（`Match View`） |
| Dart UI＆コマンド | [stage.dart](../../app/lib/workspace/stage/stage.dart), [stage_options.dart](../../app/lib/workspace/stage/stage_options.dart), [toggle.dart](../../app/lib/workspace/stage/toggle.dart), [keymap.dart](../../app/lib/workspace/commands/keymap.dart), [command_actions.dart](../../app/lib/workspace/commands/command_actions.dart), [layer_menu.dart](../../app/lib/workspace/commands/layer_menu.dart) | `3D View` (`Shift+C`)、`Match View` (`Option+C`)、Camera ストリップ、右クリックメニュー |
| Dart Depth レーダー | [depth.dart](../../app/lib/workspace/tool_panel/depth.dart), [depth_lens.dart](../../app/lib/workspace/tool_panel/depth_lens.dart), [depth_diagram.dart](../../app/lib/workspace/tool_panel/depth_diagram.dart) | ワールド固定 XZ レーダー、DOF／画角ドラッグ、Auto Focus 復帰 |
