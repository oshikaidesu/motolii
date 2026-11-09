# 窓から届かない物を切る（2026-11-10）

切る前の main は、ローカルのタグ `noise-archive-2026-11-09` に残してある（`git show noise-archive-2026-11-09:<path>`）。前例は `lab-archive-2026-11-09`。

## 物差し

- import では測らない（main.dart から 175 本全部が import で届く）。宣言ごと・メンバーごとに、`main()` から名前が本文に出てくるかでたどった。届かない物だけを切った。名前がかぶる物は生かす側に倒した。
- `app/lib/inspector/` は作り直し中なので根として扱い、インスペクターが使う物は残した。中身にも触れていない。
- エンジン：`motolii.h` の `motolii_*` を、Dart（`motolii_bindings.dart` を除く）・Swift（`MainFlutterWindow.swift`）・文字列で渡される名前（`motolii_desk_front`・`motolii_desk_frames`）・`stage/picture.h` の中・`edit.cpp`（`edit.sh` は README・`drawings_unchanged.sh`・CI `build.yml`・`docs/using/make_intro_movie.md` が回す）の README で使う命令から探した。どこにも出ない物を切り、そこからしか届かない内側の関数（include をたどる）も切った。
- スクリプト：`engine/` の下で、README・hook・CI・他のスクリプトのどれも回さない物。
- 組み立てはしていない（形が先）。静的な検査：`dart analyze lib` は誤り 0（警告は main と同じ物だけ）、`check_syntax.sh` は `entry/motolii.mm` で ok（わざと壊して落ちるのを見てから戻した）。

## 丸ごと消したファイル

| path | なぜ届かないか | 行 |
|---|---|---|
| `engine/community/js/js_returned.cpp` | `motolii_js_returned` だけを持つ。Dart も Swift も呼ばない | 134 |
| `engine/community/three_tsl/check_node/.gitignore` | Dawn の node 版で TSL を描いて比べる試し。README・hook・CI・他のスクリプトのどれも回さない | 8 |
| `engine/community/three_tsl/check_node/browser_bloom_16x9.hex` | Dawn の node 版で TSL を描いて比べる試し。README・hook・CI・他のスクリプトのどれも回さない | 1 |
| `engine/community/three_tsl/check_node/browser_plain_16x9.hex` | Dawn の node 版で TSL を描いて比べる試し。README・hook・CI・他のスクリプトのどれも回さない | 1 |
| `engine/community/three_tsl/check_node/build.sh` | Dawn の node 版で TSL を描いて比べる試し。README・hook・CI・他のスクリプトのどれも回さない | 12 |
| `engine/community/three_tsl/check_node/check.ts` | Dawn の node 版で TSL を描いて比べる試し。README・hook・CI・他のスクリプトのどれも回さない | 148 |
| `engine/community/three_tsl/check_node/package-lock.json` | Dawn の node 版で TSL を描いて比べる試し。README・hook・CI・他のスクリプトのどれも回さない | 245 |
| `engine/community/three_tsl/check_node/package.json` | Dawn の node 版で TSL を描いて比べる試し。README・hook・CI・他のスクリプトのどれも回さない | 9 |
| `engine/community/three_tsl/dawn_node.sh` | 上の check_node 用。回す物が無い | 19 |
| `engine/community/three_tsl/draw.sh` | `convert.ts` の drawable 出力を描く試し。回す物が無い（drawable 出力も消した） | 23 |
| `engine/community/three_tsl/jsrh_napi/build.sh` | JsRuntimeHost（QuickJS）で TSL を回す試し。回す物が無い | 16 |
| `engine/community/three_tsl/jsrh_napi/shaders.ts` | JsRuntimeHost（QuickJS）で TSL を回す試し。回す物が無い | 48 |
| `engine/community/three_tsl/jsrh_napi/web_globals.ts` | JsRuntimeHost（QuickJS）で TSL を回す試し。回す物が無い | 20 |
| `engine/deps/patches/dawn/dawn_lend.patch` | `tsl_on_dawn` 用の Dawn 手直し。使う組み立てが無い | 168 |
| `engine/deps/patches/jsruntimehost/jsrh_qjs017_dawn.patch` | jsrh_napi 用の手直し。使う組み立てが無い | 108 |
| `engine/deps/tree_sitter.sh` | `js_returned.cpp` の組み立て部品だけ | 16 |
| `engine/gpu/js_effects.cpp` | JS でエフェクトを回す試し。README・hook・CI・他のスクリプトのどれも回さない | 131 |
| `engine/gpu/js_effects.sh` | JS でエフェクトを回す試し。README・hook・CI・他のスクリプトのどれも回さない | 26 |
| `engine/gpu/tsl_on_dawn.cpp` | TSL を Dawn で直接描く試し。回す物が無い | 201 |
| `engine/gpu/tsl_on_dawn.sh` | TSL を Dawn で直接描く試し。回す物が無い | 11 |
| `engine/materials/boxlight.mat` | それを読む関数（paper_and_sun・glass_light・box_light・shadow_of・floor）を全部切ったので、`.filamat` 名で読む所が無い。`gpu/kit_wgpu.sh` の一覧からも外した | 134 |
| `engine/materials/floor_shade.mat` | それを読む関数（paper_and_sun・glass_light・box_light・shadow_of・floor）を全部切ったので、`.filamat` 名で読む所が無い。`gpu/kit_wgpu.sh` の一覧からも外した | 35 |
| `engine/materials/glassbox.mat` | それを読む関数（paper_and_sun・glass_light・box_light・shadow_of・floor）を全部切ったので、`.filamat` 名で読む所が無い。`gpu/kit_wgpu.sh` の一覧からも外した | 144 |
| `engine/materials/glasslight.mat` | それを読む関数（paper_and_sun・glass_light・box_light・shadow_of・floor）を全部切ったので、`.filamat` 名で読む所が無い。`gpu/kit_wgpu.sh` の一覧からも外した | 99 |
| `engine/materials/paper.mat` | それを読む関数（paper_and_sun・glass_light・box_light・shadow_of・floor）を全部切ったので、`.filamat` 名で読む所が無い。`gpu/kit_wgpu.sh` の一覧からも外した | 77 |
| `engine/materials/paper_copy.mat` | それを読む関数（paper_and_sun・glass_light・box_light・shadow_of・floor）を全部切ったので、`.filamat` 名で読む所が無い。`gpu/kit_wgpu.sh` の一覧からも外した | 17 |

## ファイルの中から消した宣言

| path | 消した物 | なぜ届かないか | 行 |
|---|---|---|---|
| `app/lib/bridge/motolii_shelves.dart` | `MotoliiShelves.repeaterScript`・`MotoliiShelves.hasRepeater` | Dart の呼び口。窓のどこからも呼ばれない（呼ぶ側が先に消えたか、`later(...)` に置き換わった） | 7 |
| `app/lib/bridge/motolii_document.dart` | `MotoliiDocument.documentNow` | Dart の呼び口。窓のどこからも呼ばれない（呼ぶ側が先に消えたか、`later(...)` に置き換わった） | 3 |
| `app/lib/bridge/motolii.dart` | `Motolii._unkey`・`Motolii._letGo`・`Motolii._keyHere`・`Motolii._raise`・`Motolii._stay`・`Motolii._redo`・`Motolii._keyMany`・`Motolii._sequence`・`Motolii.handStep` | Dart の呼び口。窓のどこからも呼ばれない（呼ぶ側が先に消えたか、`later(...)` に置き換わった） | 11 |
| `app/lib/bridge/motolii_writes.dart` | `MotoliiWrites.keyMany`・`MotoliiWrites.unkey`・`MotoliiWrites.letGo`・`MotoliiWrites.keyHere`・`MotoliiWrites.stay`・`MotoliiWrites.resize`・`MotoliiWrites.sequence`・`MotoliiWrites.setWork`・`MotoliiWrites.raise`・`MotoliiWrites.define`・`MotoliiWrites.redo` | Dart の呼び口。窓のどこからも呼ばれない（呼ぶ側が先に消えたか、`later(...)` に置き換わった） | 30 |
| `app/lib/bridge/motolii_questions.dart` | `MotoliiQuestions.valuesAt`・`MotoliiQuestions.setting` | Dart の呼び口。窓のどこからも呼ばれない（呼ぶ側が先に消えたか、`later(...)` に置き換わった） | 34 |
| `app/lib/bridge/motolii_moment.dart` | `MotoliiMoment.isNow` | Dart の呼び口。窓のどこからも呼ばれない（呼ぶ側が先に消えたか、`later(...)` に置き換わった） | 2 |
| `app/lib/workspace/inspector_feed/keyframe_marks.dart` | `wsKeyMarks` | 窓の部品だが、main() から名前でたどって一度も出てこない | 3 |
| `app/lib/workspace/state/effects.dart` | `WsFx.motionToggle` | 窓の部品だが、main() から名前でたどって一度も出てこない | 9 |
| `app/lib/workspace/edits/group_moves.dart` | `wsMoveSet`・`wsMoveHold`・`wsMoveTime`・`wsMoveTurn`・`wsMoveEase`・`wsShows`・`_poses`・`_posesOf`・`wsPosesTold`・`wsValue`・`_values` | 窓の部品だが、main() から名前でたどって一度も出てこない | 92 |
| `app/lib/workspace/stage/stage_art.dart` | `ArtInk`・`WsArt.cameraBox` | 窓の部品だが、main() から名前でたどって一度も出てこない | 7 |
| `app/lib/workspace/timeline/timeline_paint.dart` | `WtM.barRadius` | 窓の部品だが、main() から名前でたどって一度も出てこない | 1 |
| `app/lib/workspace/dock/dock_tags.dart` | `DockTags.ofColor`・`DockTags._ofColor`・`DockTags._tagsOf` | 窓の部品だが、main() から名前でたどって一度も出てこない | 25 |
| `app/lib/skin/tokens.dart` | `N.glaze9,glaze15`・`Grey.glaze9`・`Grey.glaze15`・`Role.keyEdge`・`Role.disabled`・`TL`・`Dose`・`Gui`・`OkMark`・`_OkMarkPainter` | 色・寸法の定義だが、どの部品も読まない | 148 |
| `app/lib/widgets/timeline_painters.dart` | `tpAccent`・`tpTime`・`tpGrid`・`TpHit`・`_TpHitState`・`TpValue`・`_TpValueState`・`TpIconButton`・`TpKey`・`TpInterp`・`tpKey`・`tpLink`・`tpSeg`・`TpBar`・`tpBarColor`・`tpBar`・`TpLanePainter`・`tpHead` | Widgetbook 時代の見本部品（media_set / timeline_set）。窓のどの部品も組み立てない | 364 |
| `app/lib/widgets/media.dart` | `kFast`・`kEase`・`ArtStyle`・`Asset`・`sampleAssets`・`ArtPainter`・`Art`・`TypeBadge`・`TimePill`・`Press`・`_PressState`・`Hold`・`_HoldState`・`drawFolder`・`StarButton`・`DashedBox`・`Pill`・`QuietButton`・`Tick` | Widgetbook 時代の見本部品（media_set / timeline_set）。窓のどの部品も組み立てない | 347 |
| `app/lib/widgets/controls.dart` | `ValueWell`・`Tool` | Widgetbook 時代の見本部品（media_set / timeline_set）。窓のどの部品も組み立てない | 100 |
| `app/lib/widgets/relations.dart` | `FamIcon`・`RelationTile`・`RelationCard`・`_Icon` | Widgetbook 時代の見本部品（media_set / timeline_set）。窓のどの部品も組み立てない | 168 |
| `engine/entry/export.h` | `motolii_asked`・`motolii_hand_step`・`motolii_timed` | `motolii_*` の C 関数。Dart（bindings 以外）・Swift・edit.cpp の README の使い方のどこも呼ばない | 3 |
| `engine/entry/calls.h` | `motolii_define`・`motolii_frame`・`motolii_handles`・`motolii_key_here`・`motolii_key_many`・`motolii_keyed`・`motolii_keys`・`motolii_let_go`・`motolii_look_put`・`motolii_look_save`・`motolii_pen`・`motolii_points`・`motolii_raise`・`motolii_seen`・`motolii_sequence`・`motolii_size`・`motolii_stay`・`motolii_unkey`・`motolii_value`・`motolii_work` | `motolii_*` の C 関数。Dart（bindings 以外）・Swift・edit.cpp の README の使い方のどこも呼ばない | 40 |
| `engine/entry/window.h` | `motolii_desk`・`motolii_heard`・`motolii_live`・`motolii_pick` | `motolii_*` の C 関数。Dart（bindings 以外）・Swift・edit.cpp の README の使い方のどこも呼ばない | 24 |
| `engine/entry/calls_later.h` | `motolii_redo` | `motolii_*` の C 関数。Dart（bindings 以外）・Swift・edit.cpp の README の使い方のどこも呼ばない | 1 |
| `engine/entry/calls_files.h` | `motolii_thumbnail` | `motolii_*` の C 関数。Dart（bindings 以外）・Swift・edit.cpp の README の使い方のどこも呼ばない | 1 |
| `engine/stage/kit/kit_things.h` | `paper_and_sun`・`box_light`・`glass_light`・`bubbles`・`shadow_of`・`key_out` | 上の切った C 関数からしか届かない絵の部品（紙と太陽・ガラス箱など、古い見本の舞台） | 152 |
| `engine/stage/kit/kit_stage.h` | `glass_blocks`・`fail` | 上の切った C 関数からしか届かない絵の部品（紙と太陽・ガラス箱など、古い見本の舞台） | 20 |
| `engine/motion/lottie_motion.h` | `motion_camera`・`motion_of` | 上の切った C 関数からしか届かない | 22 |
| `engine/stage/kit/kit_draw.h` | `sun_to`・`show`・`soak` | 上の切った C 関数からしか届かない絵の部品（紙と太陽・ガラス箱など、古い見本の舞台） | 57 |
| `engine/media/video_layer.h` | `key_out` | 誰も呼ばない | 7 |
| `engine/motion/easing_curves.h` | `interp_wave`・`interp_noise`・`interp_fract`・`interp_lattice`・`interp_mix` | 上の切った C 関数からしか届かない | 14 |
| `engine/document/cards.h` | `doc_keyed` | `motolii_keyed` からしか届かない | 1 |
| `app/lib/bridge/motolii_bindings.dart` | 上で切った C 関数 30 本の結び | ffigen の写し。`motolii.h` と同じ関数の組になるよう合わせた | 243 |
| `engine/entry/motolii.h` | 同じ 30 本の宣言 | 上と同じ | 57 |
| `engine/stage/kit/kit_things.h`・`kit_stage.h` | `Sunlit`・`view_floor`・`sunlight`・`sun`・`by_sun` | 切った関数だけが使う場所 | 約 30 |
| `engine/entry/edit.cpp` | `pen`・`points`・`handles`・`keys`・`unkey`・`define`・`value`・`look`・`time` 命令 | 切った C 関数の前口。README の使い方（`docs/using/make_intro_movie.md`：make・add・say・set・key・effect・write）は使わない。`let_go`・`redo` は窓と同じ `motolii_later` に付け替えた | 約 60 |
| `engine/community/three_tsl/convert.ts` | `writeDrawable` と `drawable` 引数 | `draw.sh` だけが読んでいた | — |

切った C 関数（30）：`motolii_asked`・`motolii_define`・`motolii_desk`・`motolii_frame`・`motolii_hand_step`・`motolii_handles`・`motolii_heard`・`motolii_js_returned`・`motolii_key_here`・`motolii_key_many`・`motolii_keyed`・`motolii_keys`・`motolii_let_go`・`motolii_live`・`motolii_look_put`・`motolii_look_save`・`motolii_pen`・`motolii_pick`・`motolii_points`・`motolii_raise`・`motolii_redo`・`motolii_seen`・`motolii_sequence`・`motolii_size`・`motolii_stay`・`motolii_thumbnail`・`motolii_timed`・`motolii_unkey`・`motolii_value`・`motolii_work`

## わざと残した物

- `motolii_now`：`edit.cpp` の `effect` が使い、`docs/using/make_intro_movie.md` が回す。
- `stage/picture.h` の中で使う `motolii_*`（cards・things・values・words など）：Dart は直接呼ばないが、窓に渡す絵の JSON を作る。
- `motolii_front`・`motolii_frames`・`motolii_solo_front`・`motolii_finished`（Swift）、`motolii_desk_front`・`motolii_desk_frames`（文字列で渡す）。
- テストの継ぎ目（`easeKeptAt`・`fontRecentAt`・`dockMapsAt`・`dockStarsAt`・`effectRecentAt`・`effectDecksAt`・`coloursAt`・`latchedAt`）：`test/` が使う。
- `workspace/commands/command_actions.dart`（キーボードの近道、メニューから結ぶ）、`skin/forms/*`（`shelves/skins` の皮が名前で選ぶ）。
- `three_tsl` の `run.sh`・`fetch.sh`・`check.sh` と変換器：棚の `.wgsl` を作る。
- 読み取り器の誤り（ジェネリック関数・レコード拡張）で死んで見えた `_listEq`・`DockCtx.foot`/`footOpen`・`stage_view` のレコード拡張。

## インスペクターの作り直しに渡す物（触れていない）

同じ物差しで届かない：`inspector_advanced.dart`・`inspector_layer_tiles.dart`・`inspector_relations.dart`、`EffectsStack`・`ParamSearch`・`EffectCard`・`LayoutGroup`・`PopGroupLabel`・`Cap`・`DepthRow`・`TransformGroup`・`readParams`。
