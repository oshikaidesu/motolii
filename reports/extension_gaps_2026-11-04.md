# 便利な拡張が埋めている穴：AE・DAW・Figma をまとめて、Motolii に有る手・無い手（2026-11-04）

3 つの調べを 1 つの表にした。

- AE：まとめ 22 本（`reports/ae_panels_research_2026-10-17.md`）
- DAW・VST：まとめ 48 本、穴 9 種類（`research_notes/便利な拡張の穴と連番/daw_vst_utilities.md`）
- Figma：まとめ 15 本と人気順、穴 9 種類＋ウィジェット（`research_notes/便利な拡張の穴と連番/figma_plugins.md`）

Motolii の欄は、コードを読んで確かめた（行は各行の右）。

## 1. 穴は 13 種類

| 穴 | AE で埋める物 | DAW で埋める物 | Figma で埋める物 | Motolii |
|---|---|---|---|---|
| A 見て探す | 動く見本付きのプリセット一覧（Animation Composer） | XO、ADSR Sample Manager | Iconify・Unsplash、色と書体を選ぶ | **有る**：地図（種類の島と色）、説明文まで探す、★（`dock_map.dart`、`dock_effects.dart:77`） |
| B 自分の素材で試す・戻す | 乗せると再生する見本 | XO の Playground、ランダム化（Playbeat） | — | 一部：Snapshot で前と見比べるだけ。札の絵は見本の写真の上（`stage.dart:85`、`effect_tiles.dart:1`） |
| C 比べる・測る | Premiere の Comparison View、スコープ | SPAN、REFERENCE | — | 一部：Snapshot と音の波形だけ（`timeline.dart:419`） |
| D 見えない間違いを知らせる | 出典なし | （メーター） | Stark、Contrast、Design Lint | **無い** |
| E 自動でそろえる | Premiere の Auto Ducking・Color Match | VocAlign、Vocal Rider | — | **無い**（音の大きさと打点は読める：`engine/sound.h:1`） |
| F 何かで値を動かす | wiggle、音をキーに | Kickstart、LFOTool | — | 一部：振る舞い（揺れ・ノイズ・ずらし）、式。音で値を動かすのは無い（`doc_kinds.h:309`） |
| G 最初の案を出す | 色の一覧（Pigment） | Scaler、Ozone | Image Palette、uiGradients | 一部：写真から色、グラデの見本（`dock_make.dart:280`） |
| H 一発・名前で呼ぶ | KBar、Motion Tools | SWS、名前で呼ぶ命令 | 一押しで形（Remove BG、Autoflow） | 一部：揃え、キーの割り当て。命令を打って呼ぶ窓は無い（`keys.dart:1`、`workspace.dart:556`） |
| I まとめて扱う | 一括の名前変え（Global Renamer） | — | Rename It、Tokens Studio | 一部：見た目だけ貼る。番号付きの名前変え・探して置き換えは無い（`workspace.dart:337`） |
| J 中身を流し込む | CSV・JSON を式で読む | — | Content Reel、Charts | 一部：Count Up・Timecode。CSV・声から字幕は無い（`absent_motion.h:20`） |
| K よその形式と行き来 | Overlord | 形式の変換 | html.to.design、Image Tracer | 一部：SVG・Lottie・p5 などを読む。PSD・Lottie 書き出しは無い（`doc_edit.h:80`） |
| L 待たずに作る・配る | スクリプト | ReaPack | Automator、generative plugins | 一部：自分のフォルダ、デッキの共有コード。更新と棚は無い（`doc_edit.h:527`、`effect_decks.dart:114`） |
| M 置いた物が状態を持つ | — | — | ウィジェット（Vote、Timer） | 一部：文字の効果としてだけ（`absent_motion.h:20`） |

## 2. 次に入れる順（目的「見つけた表現をすぐ使う」に近い順）

1. **B 自分の素材で試す**：選んだ物の上で、効果の札に乗せると掛かった姿が出て、離すと戻る。押せば入る。XO の Playground と AE の「乗せると再生」が同じ穴。チェック表 708 行・409 行の続き。
2. **H 名前で呼ぶ窓**：命令と効果を打って呼ぶ。借り先は flutter_kbar（MIT）か command_palette（MIT）。AE は 2026 年に Quick Apply を本体に入れた。
3. **D 点滅を知らせる**：書き出しの前に、1 秒に 3 回より多い点滅を知らせる。借り先は EA の IRIS（BSD-3-Clause）。動画にしか無い穴（Figma の調べ 6 章）。
4. **E 声の間だけ音楽を下げる**：Premiere の Auto Ducking と同じ。音の大きさはもう読めている。

D・E は今は手が全く無い。B・H は一部ある物を伸ばす。
