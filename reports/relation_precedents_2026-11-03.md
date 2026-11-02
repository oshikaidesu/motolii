# 関係の先行者の調べ（2026-11-03）

問い：今の関係（Around・Row・Follow・Push・Move in）はなぜしょぼいか。たくさんの物を一緒に動かす先行者は、何をしているか。
11/1 の `relations_2026-11-01.md` は「関係の持ち方」の調べ。今回は「関係で何ができるか」。

## 今の Motolii（コードを読んだ）

- 5 種は `engine/doc_relations.h:133` の `doc_related` に C++ で直に書いてある（71 行）。足すにはエンジンの作り直しが要る。
- 範囲が無い。全員に同じ強さで、違うのは順番（`lag`）だけ。`doc_falloff_at` はふるまい用にあるが、`doc_related` からは呼ばない。Push の半径だけが例外。
- 1 値ずつ。物 1 つの値 1 つごとに呼ばれ、全員を一度に見ない。
- 効く値は位置・回転・大きさ・不透明度。色・効果の値・文字には効かない。
- スクリプトの `each(i, n, t, k)` は 1 つの物の写し 1 個ずつ。他の物は絵と音しか読めない（`engine/script.cpp:119`）。

## 見本

| 見本 | 何をする | 作り | 確かめた所 |
|---|---|---|---|
| Cloners + Effectors（AE） | C4D の MoGraph を AE に。複製に 7 種の Effector と Falloff。多いと重いという報告あり | スクリプト | 検索の抜粋。aescripts と Toolfarm は 403 で本文は読めていない |
| Newton（AE） | 2D の物理。別窓で計算し、結果を AE のキーに書き戻す | キーに焼く | 検索の抜粋 |
| Layer React・Expression Tools（AE） | Null からの距離で大きさなどを変える | 式と Null | 検索の抜粋。Gumroad の本文は空 |
| Motion 4（AE） | Stare、Orbit、Trace など 1 回押す道具。何を書き出すかは説明に無い | 未確認 | 公式ガイドの `llms.txt` を読んだ |
| Creative Cow の 2023 年の相談 | 真ん中で膨らむ物の隣が、間隔を保って避ける。互いの値に依存するので式では難しい。文字レイヤーで前計算して解いた | 式の回り道 | 本文を読んだ |
| Cinema 4D MoGraph | Effector と Fields。Push Apart、Delay、Step、Target、Sound、Formula、Python など | 本体 | Inheritance は r21 の本文。他は検索の抜粋 |
| C4D Inheritance | 並びを別の物へ引き継ぐ。Morph Motion Object で複製の群れから群れへ移る。Step Gap で順にずらす | 本体 | r21 の本文 |
| C4D Python Effector | Parameter Control は 1 個ずつ、Full Control は全員を一度に扱う | 本体 | 公式マニュアルの検索抜粋 |
| Unreal Motion Design | Effector の形 6 種、モード 4 種、力 7 種。形ごとに内と外の境界とイージング | 本体 | 公式の本文（全 115,636 字のうち先頭 100,000 字） |
| Cavalry | ふるまい 78 種。Apply Layout、Distance、Is Within、Look At、Morph、Spring、Stagger、Sound など | 本体 | 公式の一覧（名前のみ）。JavaScript Deformer は本文 |

## 分かった事

- AE の拡張は、たくさんの層を本物のまま同時に生かす道が無く、式を書くかキーに焼く形で回っている。AE の SDK の説明は、効果は他の層を計算に使えるとだけ言う。層を動かせないとは明記していない。壁と見るのは、道具の作りと掲示板の話からの判断。
- しょぼさは種類の数ではない。閉じている（C++）、範囲が無い、全員を見ていない、の 3 つ。
- 範囲は C4D・Unreal・Cloners + Effectors・Cavalry の全部にある。Motolii も部品は持っていて、関係につながっていない。
- 全員を一度に見て全員に返す形は C4D の Full Control にある。Creative Cow の相談はこの形で解ける問題。
- C4D の Inheritance の Morph Motion は、ユーザーの 10/22 の「関係性のモーフィング」に近い。
- C4D と Unreal の Effector の相手は、説明を読んだ範囲では複製。種類の違う物どうし（文字と動画と 3D）の関係は、見本から確かめられていない。

## 試した結果（11/3、ユーザーの「実験してみてくれ」）

形：`engine/relations/` に JS を 1 本置く。本体は `relate(things, t, k)` 1 つ。全員を受けて、変える物だけ返す。C4D の Full Control の形で、書き方は Motolii の `each` に揃えた。

| 試した事 | どこで | 結果 |
|---|---|---|
| Creative Cow の問題（`swell.js`、20 行） | 手無し描画、6 語 | 隣との間隔は元が 40・38・30・42・53 px、膨らむ間も ±1 px。式では文字レイヤーの前計算が要った物 |
| p5 の道具（`shove.js`） | 手無し描画 | `noise` と `createVector` が動く。dylib は作り直していない。止め絵 4 枚で語の重なりなし |
| 歌詞が 1 語ずつ入る（`turns.js`） | 手無し描画 | 動いた。ユーザーの 10/22 の「順番に入るのは関係の一部」 |
| 窓を開けたままファイルを足す（`wave.js`） | 本物の窓 | 同じプロセスのままチップが出た。押すと Swell の上に積まれた |
| 書き換え | 本物の窓 | 窓が開いたまま動きが変わった |
| 書き間違い | 本物の窓 | 構文の誤りは前の形を保つ。実行時の誤りはその関係だけ外れ、下の Swell が見える。窓は落ちない |
| 目・焼く・消す | 本物の窓 | 全部効いた。焼くと位置と大きさが残る |

速さ（1 コマ、1920×1080）：

| 物 | 関係なし | Row（C++） | Swell（JS） |
|---|---|---|---|
| 立方体 20 個 | 10.54 ms | 11.00 ms | 11.38 ms |
| 立方体 200 個 | 96.55 ms | 106.86 ms | 111.52 ms |

文字 6 語は Swell 4.76 ms、Shove 6.96 ms。200 個の 96 ms は描く側の重さで、関係の分は C++ で 10 ms、JS で 15 ms。

実験で見つけて直した物：
- 焼くと 1 個ずつ抜けるので、ファイルの関係は残りの顔ぶれで計算し直し、形が崩れた。全員の位置を先に読むように直した（`doc_release`）。
- 舞台のチップは `Row` で、幅 624 の舞台で 9 個並ぶと 105 px あふれた。`Wrap` に変えた。

できない事は `reports/alight_checklist.md` の T 節。

## Cavalry の元ネタ（11/3、ユーザーの「動きの元ネタもあるはず」）

系譜：

| 年 | 物 | 作った人 | 確かめた事 |
|---|---|---|---|
| 1986〜87 | Boids（群れの 3 規則：離れる、揃える、寄る） | Craig Reynolds | 本人のページ |
| 2006 | MoGraph（C4D R9.6 の追加モジュール） | Per-Anders Edwards | Maxon の記事。元は本人の現場の必要 |
| 2012 | MASH（Maya の無料ノード 12 個） | Mainframe North | CG Channel。MoGraph にありそうな機能と書く |
| 2013 | MASH 2.0（21 個、C++ に書き直し、有料） | Mainframe | Lester Banks |
| 2015 | MASH が Autodesk へ（24 個） | Mainframe から移管 | CGPress |
| 2020 | Cavalry 1.0 | Scene Group。CG Channel は MASH の作り手と書く | 1.0 の日付は検索の抜粋 |

動きの対応（名前を並べた物で、受け継いだと作者が言ったのは確かめていない）：

| 動き | MoGraph | MASH | Cavalry |
|---|---|---|---|
| 範囲で効きを変える | Falloff、Fields | Falloff、Strength | Falloff、`strength` |
| 順にずらす | Step、Delay | Time、Delay | Stagger |
| 揺れる | Random、Formula | Signal（4D ノイズ、三角関数） | Oscillator、Noise |
| ばね | 未確認 | Spring | Spring（`mass`、`damping`） |
| 群れ | 未確認 | Flight | 定義に flock の語なし |
| スクリプト | Python Effector | Python ノード | JavaScript |

中身の出どころ（`/Applications/Cavalry.app` の同梱ファイルを読んだ。写していない）：
- ノイズは FastNoise（Jordan Peck、MIT）。`third_party_licences.txt` に載っている。後継の FastNoiseLite は MIT で JavaScript 版がある。
- ノードの種類は `simplexNoise`、`cellularNoise`。
- 式の部品は exprtk。

作例の元ネタ：Cavalry の例 14 本のうち、元を書いているのは Night and Day だけ（ある記事に着想）。作者の名前は無い。

Motolii に効く事：
- MASH の Python ノードは、全員の値を読み全員に書く形で今回の `relate()` に近い。さらに `getFalloff(0)` で物ごとの範囲の重みを読める。範囲を関係につなぐ時の見本。
- 群れは Boids の 3 規則まで戻れる。前のコマの速さを覚える必要がある。

確かめ方：
- ページの本文（取得ツールの要約で読んだ）：School of Motion、CG Channel 2012・2018、Lester Banks、CGPress、Autodesk の MASH の 2 ページ、Reynolds、Maxon、Cavalry の例の一覧。
- GitHub API で読んだ：FastNoiseLite の README。
- 検索の抜粋だけ：Creative Bloq（本文が取れない）、Greyscalegorilla の Edwards の話（本文が取れない）、EverybodyWiki と Yorkshire Post（403、回り道はしていない）。
- 作者が「MoGraph から取った」と言った文は見つけていない。MoGraph から MASH への線は CG Channel の比較と名前からの推測。

## Cavalry はどう解いたか（11/3、ユーザーの問い）

| 問題 | Cavalry の解き方 | 確かめた所 |
|---|---|---|
| たくさんの物 | 別々の層を結ばず、Duplicator・文字・SVG の 1 層の中の sub-mesh にする。位置や回転は id ごとの配列（`shapePosition` など）で、Stagger は最初の id に最小、最後の id に最大を配る | Stagger と Duplicator の説明は検索の抜粋、属性名は `nodeDefinitions.json` |
| 全員を一度に | JavaScript Deformer が `def.getPoints()` で全点を受け、`def.setPoints()` で返す | 本文 |
| 範囲 | Falloff が点ごとに 1 から 0 を出し、Behaviour の Strength に掛ける。形は Circle、Rectangle、Linear、Sweep、Shape | 本文 |
| 前のコマ | Value Solver が前のコマの値に積む（Accumulate、Highest、Lowest、Velocity）。Start Frame で始まり、Fade で戻る。Mesh Solver も同じで Pre-Roll がある。スクリプトは Context の `saveObject` で覚える | 本文。`saveObject` は検索の抜粋 |
| 飛んだ時 | `.sdcache` に書く。説明は「重い物に役立つ」までで、飛んだ時の動きは書いていない | 本文 |

別々の物どうしの関係については、Cavalry の説明からは解き方を見つけていない。接続で 1 本ずつつなぐ形までは 11/1 に確認した範囲。隣との間隔を保つ Apply Layout は、説明に間隔の話が無く、確かめられていない。

## 食った物（11/3）

| 物 | 見本 | 結果 |
|---|---|---|
| 範囲 | Cavalry の Falloff、MASH の `getFalloff` | 関係の Falloff 札で形を選ぶ。5 種にも効く。丸の外の物は元の場所のまま |
| 前のコマ | Value Solver、Context の `saveObject`、Motolii の p5 の `__to` | `relate(things, t, k, was)`。60 コマ毎秒で積み、コマを取っておく。戻っても同じ位置 |
| `flock.js` | Reynolds の Boids、MASH の Flight | 30 個が同じ向きに流れる |
| `spring.js` | Cavalry と MASH の Spring（Mass、Damping、Speed Limit） | キーの動きを行き過ぎて戻る |
| `stay.js` | Value Solver の Highest と Fade | 丸が通った所が変わったまま残る |
| `look.js` | Look At、Target Effector、Orient | 12 本が先頭の 1 個（`members` の最初）を指した。手無しの絵で見た。テストは無い |

速さ（立方体 30 個、1080p、1 コマ）：

| 物 | ms |
|---|---|
| 関係なし | 16.43 |
| `flock.js`（p5 のベクトル） | 34.22 |
| `flock.js`（素の計算） | 17.41 |

最初に先へ飛ぶと、2 秒分で約 0.3 秒かかった。1 分先なら約 9 秒の計算（測っていない）。戻るのは止まった絵 1 枚分の速さ。FastNoiseLite は入れていない。p5 の `noise` で足りている。

## 読めていない物

- Plexus、Duik、Joysticks 'n Sliders、Rubberhose は今回読んでいない。
- AviUtl・YMM4 の側と、日本語の情報は探していない。
- C4D の Effector を複数の Cloner で分け合えるかは、11/1 に続き未確認。

## 出典

- [After Effects C++ SDK Guide: What Can I Do](https://ae-plugins.docsforadobe.dev/intro/what-can-i-do/)
- [Cloners + Effectors](https://aescripts.com/cloners-plus-effectors)
- [Newton](https://aescripts.com/newton)、[Newton 3 Crash Course](https://www.premiumbeat.com/blog/after-effects-newton-3-plugin/)
- [Layer React](https://xantips.gumroad.com/l/LayerReact)、[Expression Tools](https://xantips.gumroad.com/l/ExpressionTools)
- [Motion 4 Guide](https://motion.mtmograph.com/llms.txt)
- [Creative Cow: 隣との間隔を保って膨らむ](https://creativecow.net/?p=2449105)
- [C4D Inheritance Effector](https://help.maxon.net/c4d/r21/us/html/OEINHERITANCE-MGINHERITANCEEFFECTOR_GROUPEFFECTOR.html)
- [C4D Python Effector](https://developers.maxon.net/docs/Cinema4DPythonSDK/manuals/introduction/python_effector.html)
- [Unreal Motion Design Cloners and Effectors](https://dev.epicgames.com/documentation/en-us/unreal-engine/motion-design-cloners-and-effectors-in-unreal-engine)
- [Boids](https://www.red3d.com/cwr/boids/)、[Steering Behaviors（Reynolds、1999）](https://www.red3d.com/cwr/steer/gdc99/)、[MoGraph の受賞（Maxon）](https://www.maxon.net/en/article/maxon-cinema-4d-mograph-toolset-honored-with-academy-award-for-scientific-and-technical-achievement)、[Sci-Tech 賞（CG Channel）](https://www.cgchannel.com/2018/12/motion-graphics-tools-devs-win-sci-tech-academy-awards)
- [Mash の無料公開（CG Channel）](https://www.cgchannel.com/?p=45298)、[MASH 2.0](https://lesterbanks.com/2013/06/mainframe-releases-mash-2-0-procedural-animation-toolkit-for-maya-as-a-commercial-product/)、[MASH が Autodesk へ](https://cgpress.org/archives/mash-moves-to-autodesk.html)
- [MASH のノード一覧](https://help.autodesk.com/cloudhelp/2023/ENU/Maya-MotionGraphics/files/GUID-D4FECFDC-F91A-4BDC-A1B0-A24EB087B2DD.htm)、[MASH の Python ノード](https://help.autodesk.com/cloudhelp/2017/ENU/Maya/files/GUID-DCB144BD-DFE2-418B-9838-E06963F61A20.htm)
- [A First Look at Cavalry](https://www.schoolofmotion.com/blog/a-first-look-at-cavalry)、[Cavalry 1.1（CG Channel）](https://www.cgchannel.com/tag/cavalry-1-1)、[Cavalry の例](https://cavalry.studio/docs/getting-started/example-files/)
- [FastNoiseLite](https://github.com/Auburn/FastNoiseLite)
- [Value Solver](https://cavalry.studio/docs/nodes/behaviours/value-solver/)、[Mesh Solver](https://cavalry.studio/docs/nodes/behaviours/mesh-solver/)、[Falloff](https://cavalry.studio/docs/nodes/utilities/falloff/)、[Spring](https://cavalry.studio/docs/nodes/behaviours/spring/)、[Apply Layout](https://cavalry.studio/docs/nodes/behaviours/apply-layout/)
- [Duplicator](https://docs.cavalry.scenegroup.co/nodes/shapes/duplicator/)、[Stagger](https://docs.cavalry.scenegroup.co/nodes/behaviours/stagger/)、[Context Module](https://cavalry.studio/docs/tech-info/scripting/context-module/)
- [Cavalry Behaviours](https://cavalry.studio/docs/nodes/behaviours/)、[JavaScript Deformer](https://cavalry.studio/docs/nodes/behaviours/javascript-deformer/)
