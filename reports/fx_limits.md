# 効果（fx）の決め打ち（11/3 洗い出し）

使う人が変えられない数や決まりで、効果の働きを狭めているもの。ユーザー（11/3）：「fxでなんか勝手に制限してるやつ全部洗い出して、そこは、出典がないものだから」。

- 出典あり：元のソフトや作者のコード・説明書に同じ数や決まりがある
- 出典なし：こちらで決めた。外すか、出典を見つけて置き換える
- 調べ方：エンジン、棚を作る道具、窓の 3 つに分けて読ませ、使う人に効くものはコードで確かめた（「確」の印）。印の無いものは読んだ報告のまま

## 直した（11/3）

| どこ | 何が起きていた | 直し方と出典 |
|---|---|---|
| `engine/tsl/shader_lab_shelf.ts` | ASCII の格子を 2048×1024・80 列で測って固めていた。測った値に当てはめるのが「a×値＋c」と大きさの 6 つの形だけで、作者の「列数×縦横比」の掛け算に合わず、80 列以外や横長の画面で縞・真っ黒になった（確） | 値と大きさの掛け算・割り算まで当てはめ、5 つの大きさ×3 つの値で確かめる。作者の syncGridSize（`ascii-pass.ts` 367–410 行：cellWidth = frame.width / columns） |
| 同 | 作者が切り上げる格子の数（103 列で 104）を直線に乗らないとして捨て、80 のまま固めていた（確） | 1 以内で直線に乗る整数として受ける。作者の `Math.ceil((1 - originX) / cellUvWidth)` |
| 同 | 格子の絵の大きさを、描かずに測っていた（作者は描く時に決める） | 作者の render() を回してから測る。場所で読むだけの絵（作者の `(cell + 0.5) / grid`）は舞台と同じ大きさにする。点の番号で読む絵（Connected Dots、textureLoad）は今のまま |
| `engine/screen.h` `screen_image` | 効果の横に置く絵（`--image@`、ASCII の字の絵）を ThorVG を始める前に読み、動画だけの書類では字の絵が全部 0 になって真っ黒（確） | 読む前に `tvg::Initializer::init`。ThorVG の `tvgTaskScheduler.cpp` TaskScheduler::request は始まる前の仕事を捨てる |
| `engine/aviutl_load.h` `aviutl_drawn` | 同じく ThorVG を始めずに canvas を作っていた | 同。ThorVG の `tvgCanvas.cpp` SwCanvas::gen は始まる前は何も作らない |
| `workspace/workspace_cards.dart`、`sets/inspector/inspector_number_field*.dart` | 打った数を表示の幅で止めていた（Datamosh の From 0–10 秒、Trim ±100%） | 表示の幅は滑らせる幅、打つ数はエンジンの幅まで（`@valid`）。After Effects の slider range と valid range（PF_FloatSliderDef の slider_min/max と valid_min/max） |
| `workspace/dock_effects.dart` | 1 本しか無いパックを Packs に出さなかった | 全部出す。sashimono-edit の追加メニューはフォルダごとにサブメニューを作る（`add_menu.py:280-285`） |
| `workspace/dock_effects.dart`、`ws_2.dart` | 何も選んでいない時、内蔵の効果・ルック・動きを棚から消していた | いつも出す。何も選んでいない時に押すと、絵と同じ大きさの新しい板に付く。After Effects の scripting guide、Layer.applyPreset：「If no layer is selected, it applies the animation preset to a new solid layer.」（後ろを写す調整の板には ThorVG の効果が効かなかった：ぼかしで縁の量 9.60 → 9.60） |
| `workspace/stage.dart`、`stage_view*.dart` | 舞台に落とした効果は、下にある物でなく選んでいる物へ | 落とした所の下の物を選んでから付ける。何も無い所は今まで通り。After Effects は Composition パネルの層へ落とした効果をその層に付ける |
| `workspace/dock_effects.dart`、`dock_fonts.dart`、`dock.dart`、`dock_tags.dart` | タグの札は 8 つ、補完は 6 つ | 全部、多い順に横に滑る 1 行で（窓の札の行 `Usual.chips` と同じ）。補完も折り返さず 1 行に |
| `workspace/effect_tiles.dart` | NO CHANGE の判定：写真 40 dB、カード 30 dB | AbsentMotion の `effect_thumbs.py` の change() と SAME = 2.0 そのまま：灰色に重ね、各色の差の平均（255 中）、一番違うコマが 2.0 未満なら見えない。同じ絵で PIL の change() と同じ値（3.608、3.524）を確かめた |
| `workspace/dock_effects.dart`、`ws_2.dart` | 棚から押した効果がもう付いていたら外していた | もう一つ付ける（.fs・.wgsl）。After Effects の Effects & Presets は押すたびに増やす（Gaussian Blur 2）。名前はエンジンの Duplicate と同じ `Glow~2.fs`（doc_fx_duplicate）。外すのは足の Remove と右クリックの Remove。Posterize を二つ付け、二つ目だけ 2 段にすると絵が変わる（差 35.35）のを確かめた |

## 出典なし：使う人が気づくもの

### エンジン（`engine/`）

| どこ | 決め打ち | 使う人に見えること |
|---|---|---|
| `thing_fx.h:36-41`、`screen.h:489-494` | 読めない・Dawn が通さない効果は黙って外す。理由は stderr だけ | 効果が付かないのに何も言われない |
| `doc_match.h:211`、`doc_place.h:559-560` | 効果のファイルが無い・通らないと、物ごと作らない | レイヤーが出ない |
| `aviutl_fx.h:144,728,813-815`、`199,238,244,366-373`、`554-622` | まだ書いていない `obj.*`、合成モード、drawtarget、setoption、`obj.effect`（6 つ程と Sashimono の作り直しだけ）で止まる | AviUtl2 の効果が何もしない |
| `screen.h:301`、`isf.cpp:158`（確）、`door_shadertoy.h:127`、`aviutl_fx.h:804-806` | 効果が見る時間は 60 コマ固定（TIMEDELTA、FRAMEINDEX、iFrameRate、obj.framerate）。根拠は AGENTS.md の「60fps駆動」だけ | 24・30 コマの書類で動きがずれる |
| `isf.cpp:158`（確） | DATE を (0,0,0,TIME) にする。ISF_Spec を挙げつつ、その中身と違う | 時計のシェーダーが 0 時 |
| `isf.cpp:133`（確）、`isf.cpp:110,124-133` | point2D と色に MIN/MAX が無ければ 0..1。long の LABELS を捨てて数字に。event はスイッチに | 画素で指す点が 0..1 しか動かない。選択肢が数字で出る |
| `isf.cpp:86` | 同梱の絵（IMPORTED）を読むところが無い | 絵を同梱した ISF が通らない |
| `isf.cpp:50-68,76` | PASSES の大きさの式：つまみで変わるものは断る。他は 1000 で測って割合にする | 多段の ISF の一部が通らない |
| `isf.cpp:165-166`、`door_shadertoy.h:130` | テクスチャは 0 段だけ。LOD・bias・Grad を捨てる | LOD でぼかすシェーダーがくっきりのまま |
| `dawn_probe/screen_door.cpp:184-185`、`screen.h:432,440` | 読み方は常に linear と clamp | repeat・nearest を前提にした効果が崩れる |
| `door_shadertoy_json.h:27,55`、`door_shadertoy.h:81-85,129-132`、`door.h:179-212` | Shadertoy の絵・動画・カメラは物の絵に、キーボード・音・キューブ・3D は黒。Bonzomatic の絵と FFT は黒、マウス固定、Shadertoy のアルファは 1 | ノイズの絵を使うシェーダーが違って見える。透けない |
| `screen.h:120,131,193` | WGSL の効果：絵を 1 枚以上、つまみの struct は 1 つまで、数とベクトルのつまみだけ | ファイルが通らない |
| `three_isf.cpp:77,106,140,143` | `#include`、行列、sampler 無しは断る。つまみの幅は既定値の 4 倍 | 通らない。幅がおかしい |
| `screen.h:136-137` | `--history` は 2..240 コマ、大きさ 0.05..1 | 残像が 4 秒まで |
| `screen.h:243` | `--image` の絵は 4096 画素まで。超えると黙って自分の絵を読む | 違う絵が出る |
| `thing_fx.h:264`（確）、`thing_fx.h:251`（確） | 3D に立てた物の絵は 4096 画素まで。立体の面の絵は長い辺 2048（説明は 1024 と書く） | 近寄るとぼける |
| `aviutl_fx.h:276,806` | image_max は物の枠。totalframe・frame_s・num は frame+1、0、1 | 大きくなるスクリプトが切れる。進み具合で動くものが狂う |
| `aviutl_fx.h:561`、`aviutl.cpp:105-111,133` | ぼかしは縦横比と光の強さが 0 の時だけ。`--value`・`--file`・`--font`・`--string`・`--dialog` は既定値のまま | 一部のつまみが無い |
| `doc_recipes.h:336` | 同じ効果をもう一つ（Duplicate、棚でもう一度押す）は .fs と .wgsl だけ。内蔵の効果は値を一つずつしか持たない | AviUtl2・Lottie・内蔵の効果は二つ重ねられない（棚で押すと「まだ」と出る） |
| `hydra_isf.cpp:37,46,48,53` | 動く値は 0.1 秒ごと、30 秒まで。fft は 0 | 30 秒で止まる |
| `sound.h:96`（確） | 音の解析は 10 秒知らせが無いと打ち切る | 長い音が途中まで |
| `isf.cpp:120`（確） | つまみの行は 256 字まで | 名前の長いつまみが落ちる |
| `dawn_probe/screen_door.cpp:94`（確） | Dawn の検査を 2 秒待ち、過ぎたら通す | まれ |

### 棚を作る道具

| どこ | 決め打ち | 当たる数 |
|---|---|---|
| `engine/tsl/shader_lab_shelf.ts` 余裕 | 大きさがつまみで変わる絵（点の番号で読むもの）は、一番大きい時の 1.1 倍。1.1 は出典なし | Connected Dots、Plotter |
| `engine/tsl/shader_lab_shelf.ts:197-227`、ASSETS.md:114 | vec2 のつまみ、文字の欄、作り直しが要るつまみ（crtMode、dithering の preset）、色のアルファは作者の既定のまま | vec2 13 個（7 本）、文字 6 本 |
| `engine/tsl/shader_lab_shelf.ts:23-26,118` | 作っていない：annotations、blob-tracking、blur、custom-shader、grain。fluid、magnify-lens、pixel-trail はマウスで動かす（tsl_collection.md 132 行）。particle-grid は板 1 枚より多く描くので断る。ASCII の Blocks・Shades・Hatching は字体に字が無い | 9 種＋ 3 組 |
| `engine/tsl/shelf_file.ts:60,66` | 色を 0..1 に切って入れて出す（1 を超える明るさが消える） | TSL の 98 本 |
| `engine/effects/from_sashimono.py:27` | 線形の計算を sRGB のまま（to_linear が何もしない） | 16 本 |
| `engine/effects/from_sashimono.py:34-41,157` | クリップの枠は絵全体、60 コマ、拡大 1。11 本は断る | 95 本の共通部分、11 本 |
| `engine/effects/from_absent.py:32-36,129` | SkSL の選ぶつまみは 0..1、刻み 0.01 | 22 本・43 個（am_channelremap の既定 2.0 が幅の外） |
| `engine/effects/from_absent.py:100-101` | ぼかしは ±96 画素まで（3σ は出典あり、96 は無し） | 18 本 |
| `engine/effects/from_absent.py:19-23,46-48,63-64` | ネイティブの効果、道に沿う動き、二枚目の絵は作らない | 14 本程 |
| `engine/effects/from_three.py:11-12,58-66` | つまみの幅は既定値の 4 倍。式で書かれた既定値は 0。Halftone の幅と高さは 1 | 10 本 |
| `engine/tsl/noise_fx_shelf.ts:22-27`、`textures_shelf.ts:21-22,30,42` | 入力を +3、Scale・Pace の幅、色以外の slot を外す、equirectangular を切る | 9 本＋ 9 本 |
| `engine/check/fx_chains.sh:2-3,55`、`engine/fx_first.sh:2-8,47,65` | 確かめる側：枠のまわり 128 点（checklist 668 行が出典なしと書く）、40 dB・30 dB、1.4 秒、512² | 判定の 588 本、既定を差し替えた 35 本 |
| `engine/tsl/check_node/check.ts:104-117` | 作者の描画と比べたのは 1 つの時刻、既定のつまみだけ。比べていないものもある | Shader Lab 43 本、tt・nf・tf は比べていない |

### 窓（`skin/book/lib/`）

| どこ | 決め打ち | 使う人に見えること |
|---|---|---|
| `workspace/effect_tiles.dart:356,392` | 見本の絵を作る時に動かすつまみは 8 つまで。alpha・不透明度・合成・mix・seed・スイッチ・選択は飛ばす。つまみが効いたかの見方は 40 dB、どこまで回すかは 24 dB のまま（NO CHANGE の札だけ AbsentMotion に揃えた） | 9 つ目や飛ばしたつまみでだけ変わる効果が NO CHANGE |
| `workspace/ws_2.dart:580-585`（確） | 動き（motion）は一つの物に一つ。新しいものが前のものと入れ替わる（Cavalry を挙げるが Cavalry は重ねる） | 二つ目を付けると一つ目が黙って消える |
| `workspace/dock_effects.dart:72`（確） | 動きのタイルに絵を渡していない | 動きのタイルが全部空 |
| `engine/doc_kinds.h:163`、`workspace/workspace_seat.dart:149` | 光とグループには効果が付かない。なのに「+ Add Effect」は出る | 押すと断られる |
| `engine/doc_values.h:306`、`sets/inspector/inspector_number_field_num_field_state.dart:73` | 幅の外まで打てるのは .wgsl・.fs の連続のつまみだけ | AviUtl2 のつまみは最大で止まる |
| `engine/doc_values.h:308`、`workspace/workspace_keys.dart:27` | キーは数のつまみだけ | スイッチや選択にキーが打てない |
| `engine/isf.cpp:122-129`、`aviutl.cpp:122,146,149`、`workspace/workspace_cards.dart:93` | 選択肢は数字に、`--color` は 0–255 の 3 本に、`--value`・`--file` はつまみ無し | 名前でなく数字、色見本でなく 3 本 |
| `workspace/dock.dart:26,192-194` | Presets は空 | 空のタブ |
| `workspace/effect_tiles.dart:60,180,199,229,237,414-420` | タイルの絵は 12 本ずつ作る。ffmpeg・sips が無いと静止画だけで NO CHANGE も無し | 絵がまとめて出る。ffmpeg 無しだと動かない |
| `workspace/effect_tiles.dart:140,144`、`workspace_seat.dart:66`、`dock_effects.dart:173,196,214`、`ws_3.dart:41`、`dock_parts.dart:346` | 待ち時間と大きさ：300 ms、150 ms、タイル 84 画素以上、8 列まで、説明は 2 行で切る | 長い説明が切れる |

## 出典あり（このまま）

| どこ | 決め打ち | 出典 |
|---|---|---|
| `engine/doc_moment_fx.h:217-220`（確） | 効果の余白 128 画素、舞台で切る | sashimono-edit の BAKE_MARGIN、AbsentMotion は場面で切る |
| `engine/aviutl_fx.h:97` | ぼかしのタップ 96 | sashimono-edit `builtin.py:191` の `min(radius, 96.0)` |
| `engine/aviutl_load.h:20,115`、`aviutl_fx.h:598` | 図形と Resize は 4096、線 4000 で塗り | sashimono-edit の MAX_FIGURE_SIZE、FILLED_LINE |
| `engine/aviutl_fx.h:263-265,349` | カメラの距離 1024、カメラの後ろの面は捨てる | sashimono-edit の CAMERA_DISTANCE、`projection.py` |
| `engine/sound.h:72-77` | ISF の音は 512 帯、1024 標本 | VVISF-GL の AudioController |
| `engine/door_shadertoy.h:118` | Shadertoy のバッファは PERSISTENT・FLOAT | rust_ae の `shadertoy.rs` |
| `engine/doc_recipes.h:479-501` | トランジションのキーは 1 秒 | Premiere Pro の既定、Final Cut Pro の 30 コマ |
| `engine/doc_recipes.h:472` | カメラは `.am` の動きだけ | AbsentMotion のカメラは自分の動きで置く |
| `engine/isf.cpp:192-193,201` | 生成する効果は物のアルファを掛ける、`#ifndef GL_ES` を外す | After Effects の Preserve Underlying Transparency、Vidvox の ISF-JS-Renderer |
| `workspace/dock_effects.dart:129,166`、`effect_decks.dart:27` | Recent は 10 個、40 個まで覚える | Alight Motion の `EffectBrowser.kt:117,217` |
| `motolii_shelves.dart:117-119` | 「もしかして」は 5 つ | RapidFuzz の extract |
| `workspace/effect_tiles.dart` | タイルの絵 16 コマ、384 画素で描き 192 画素で持つ | AbsentMotion |
| `engine/check/fx_chains.sh:49` | Pixellate、Triangles を外す（God Rays は出典なし） | 自分の行で 0..1 に切っている |
