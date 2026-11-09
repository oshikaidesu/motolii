# 関係の先行者の調べ（2026-11-03）

問い：今の関係（Around・Row・Follow・Push・Move in）はなぜしょぼいか。たくさんの物を一緒に動かす先行者は、何をしているか。
11/1 の `relations_2026-11-01.md` は「関係の持ち方」の調べ。今回は「関係で何ができるか」。

## 今の Motolii（コードを読んだ）

- 5 種は `engine/document/doc_relations.h:133` の `doc_related` に C++ で直に書いてある（71 行）。足すにはエンジンの作り直しが要る。
- 範囲が無い。全員に同じ強さで、違うのは順番（`lag`）だけ。`doc_falloff_at` はふるまい用にあるが、`doc_related` からは呼ばない。Push の半径だけが例外。
- 1 値ずつ。物 1 つの値 1 つごとに呼ばれ、全員を一度に見ない。
- 効く値は位置・回転・大きさ・不透明度。色・効果の値・文字には効かない。
- スクリプトの `each(i, n, t, k)` は 1 つの物の写し 1 個ずつ。他の物は絵と音しか読めない（`engine/community/js/script.cpp:119`）。

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

形：`shelves/relations/` に JS を 1 本置く。本体は `relate(things, t, k)` 1 つ。全員を受けて、変える物だけ返す。C4D の Full Control の形で、書き方は Motolii の `each` に揃えた。

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

できない事は `docs/reports/alight_checklist.md` の T 節。

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

最初に先へ飛ぶと、2 秒分で約 0.3 秒かかった。戻るのは止まった絵 1 枚分の速さ。FastNoiseLite は入れていない。p5 の `noise` で足りている。

## 途切れず計算する（11/3、ユーザーの問い）

最初の実装は、書類がどこか変わるたびに全部捨てていた。1 分の位置で測ると、上の「約 9 秒」は甘かった。

| 1 分の位置での編集（立方体 30 個、1080p、窓なしで最後まで計算） | 前 | 今 |
|---|---|---|
| 群れと無関係な物を動かす | 20.4 秒 | 0.15 秒（普通の編集と同じ） |
| 仲間の、計算に効かない値を変える | 約 20 秒（測らず） | 1.35 秒 |
| 59 秒にキーを打つ（50 秒から後が変わる） | 20.8 秒 | 3.1 秒 |
| つまみを変える（全部が変わる） | 20.5 秒 | 11.8 秒 |

3 段で解いた。

1. その手が触った物を SQLite の changeset で知る。計算が読んだ物と重ならなければ何もしない
2. 重なれば各コマが告げられた内容を前回と比べ、違った最初のコマから先だけやり直す（GGPO の巻き戻し）
3. 窓では計算を 1 拍 5 ms に分ける（React の Scheduler の値）。追いつくまで今ある絵を見せ続ける

窓で 1 分先へ飛ぶと、25 秒以内に追いつく（約 15 秒後はまだ動いていて、約 25 秒後は止まっていた）。その間も行の選択、タブ、札がすぐ効き、舞台では群れが早送りで進む。追いついた絵は、最後まで一気に計算した絵と同じ並びになった（並べて目で確認）。静止画、書き出し、再生用に取っておく絵、Bake は最後まで待つ。

Blender は変わったキャッシュを無効の印だけ付けて残し、最初のコマへ戻った時に捨てる（issue #112154 の検索の抜粋。本文は 403 で読めていない）。Motolii は書き出しと画面を同じにしたいので、今の場所から新しい値で続ける形は取らなかった。

## ルールの推移（11/3、ユーザーの言葉「必ず 1 つのルールじゃなくて推移していく動きは自然の中に多い」）

見本は 3 系統ある。

| 推移 | 見本 | Motolii でのやり方 |
|---|---|---|
| ルールは同じで、少しの変化で群れの形が変わる | Couzin ら 2002。個体の小さな変化で群れの大きな移り変わりが起きる（抜粋。本文は読めていない） | つまみにキーを打つ。覚えた状態のまま続く |
| 別のルールへ渡す | Houdini の POP Force の Activation（値が 0 を超えると動く。本文） | 関係を重ね、上の Strength にキーを打つ。0 の間は眠り、起きた時の場所から始まる |
| 物ごとに次のルールへ移る | 3ds Max の Particle Flow の Test。通った粒だけ次の Event へ行く（抜粋） | 上の関係に Falloff を付けて形を動かす。形に触れた物から移る |

足したのは眠る仕組みと、`flock.js` と `spring.js` が `near` を読む数行だけで、見本の 1 本はほかは既存の部品でできた。輪のまま眠り、Strength でその場から飛び立ち、つまみで縮んで弾け、帯が触れた左から順に輪へ帰る。

分かった限界：Around と Row は「作った時の場所からの差」を足すので、下の関係の動きが残り、上に重ねても乗っ取れない。今回は輪を下に敷いて群れを上に重ねた。5 種は変えていない。

## Houdini と同じにする（11/3、ユーザーの言葉「houdiniと一緒にしよう」「実装してる他のリポジトリもあるはずだ」）

それまでは関係ごとに速さを覚えていて、重ねると上は場所しか受け取らなかった。今は力の関係が全部 1 つの世界に入り、物は 1 つの粒になる。

**どこを見たか**

| 見た物 | どう見たか | 分かった事 |
|---|---|---|
| [POP Solver](https://www.sidefx.com/docs/houdini/nodes/dop/popsolver.html) | 公式の本文（読み取りツールの要約） | 粒は速さと力で更新される。POP の部品は力を溜める。`force` で `v` を更新し、`v` で `P` を動かす。部品の順番と、`force` を毎回 0 に戻すかはこのページに無い |
| [POP Force](https://www.sidefx.com/docs/houdini/nodes/dop/popforce.html) | 公式の本文（要約） | `force` 属性を更新する。Activation はノード全体の入り切り。Group で当てる粒を絞る |
| [POP Steer Separate](https://www.sidefx.com/docs/houdini/nodes/dop/popsteerseparate.html) | 公式の本文（要約） | 群れの舵も、粒なら同じ `force` に書く |
| [d3-force の simulation.js](https://github.com/d3/d3-force/blob/main/src/simulation.js) | ソースの tick を読んだ（ISC） | 力を全部呼び、その後で `x += vx *= velocityDecay` を 1 回 |
| [d3-force-3d](https://github.com/vasturiano/d3-force-3d) | README の要約と、npm の配布物の `src/collide.js` | 同じ約束の 3D 版（MIT）。力は位置を読み、速さに足す |
| [Unity VFX Graph](https://docs.unity3d.com/Packages/com.unity.visualeffectgraph@13.1/manual/index.html)、[bevy_hanabi](https://www.github.com/djeedai/bevy_hanabi) | 検索の抜粋だけ | 力が速さを変え、後で位置を更新する同じ形。中身は読めていない |
| Houdini の Bullet の `active` | [SideFX フォーラム](https://www.sidefx.com/forum/post/394221)の検索の抜粋と、[公式の例](https://sidefx.com/docs/houdini/examples/nodes/dop/rbdpackedobject/AnimatedObjects.html)の要約 | アニメから途中で動的へ渡せる。公式の例のページは属性名も速さの引き継ぎも書いていない |

**食った物**

- 約束は d3-force のまま：`force(things, t, k)` が今の場所を読み、速さに足す。d3 の力がそのまま動く。
- 速さは d3-force と同じくコマあたり。1 コマに 1 回、全部の力に同じ状態を見せて足し合わせる。Houdini の溜める形に寄せた。
- `collide.js` は `d3.forceCollide` をそのまま呼ぶ。`forceSimulation` は使わない。力ごとに JS の実行環境が別で、世界の 1 行の足し算は C++ の `doc_world.h` にあるため。
- 物に書いた値は次のコマにもある。Houdini の粒の属性の形。ただし別の力からは見えない。

**出典の無い決まり**

どの力も押していない物は、下の場所へ戻る。押す量が 1 未満なら、下の場所との間を見せる。Houdini の粒なら惰性で飛び続けるので、ここは一緒ではない。Strength を下げた時に元へ戻る、今までの Motolii の動きを残した。Bullet の `active` は近いが、本文で確かめられていない。

**測った事**

30 個、力 3 つ（群れ・ばね・Collide）、1920×1080：計算済みの絵は 59 枚/秒。初回は 12 秒ぶんに 8.5 秒、1 コマ約 12 ms。窓では 8.6 秒先に約 15 秒で追いつき、計算済みなら実時間で再生できた。遅さの原因を 2 つ直した。`doc_script_of` が読むたびにファイルを開いていた事（書き出し 148 秒 → 38 秒）と、`spring.js` の `createVector`。

見つけた不具合：別のスレッドから JS を呼ぶと QuickJS が「スタックあふれ」と誤判定した。`Script::numbers` で `JS_UpdateStackTop` を呼ぶ。

分かった限界：間に挟んだ普通の関係は飛ばされる。1 つの力だけの Bake は絵を保てない。力を足し引きした後の Undo は計算し直す。残りは T 節。

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
- [Houdini の POP Force](https://www.sidefx.com/ja/docs/houdini/nodes/dop/popforce.html)、[Particle Flow](https://help.autodesk.com/cloudhelp/2016/ENU/3DSMax/files/GUID-F4FD836C-5967-4DF4-9E2B-66A16292173D.htm)、[Couzin ら 2002](https://www.cs.princeton.edu/courses/archive/fall24/cos597C/bib/couzinKJRF.pdf)、[Blender issue #112154](https://projects.blender.org/blender/blender/issues/112154)
- [React の frameYieldMs](https://raw.githubusercontent.com/facebook/react/main/packages/scheduler/src/SchedulerFeatureFlags.js)、[GGPO の呼び出し（Odin の包み）](https://pkg.odin-lang.org/vendor/ggpo)
- [Boids](https://www.red3d.com/cwr/boids/)、[Steering Behaviors（Reynolds、1999）](https://www.red3d.com/cwr/steer/gdc99/)、[MoGraph の受賞（Maxon）](https://www.maxon.net/en/article/maxon-cinema-4d-mograph-toolset-honored-with-academy-award-for-scientific-and-technical-achievement)、[Sci-Tech 賞（CG Channel）](https://www.cgchannel.com/2018/12/motion-graphics-tools-devs-win-sci-tech-academy-awards)
- [Mash の無料公開（CG Channel）](https://www.cgchannel.com/?p=45298)、[MASH 2.0](https://lesterbanks.com/2013/06/mainframe-releases-mash-2-0-procedural-animation-toolkit-for-maya-as-a-commercial-product/)、[MASH が Autodesk へ](https://cgpress.org/archives/mash-moves-to-autodesk.html)
- [MASH のノード一覧](https://help.autodesk.com/cloudhelp/2023/ENU/Maya-MotionGraphics/files/GUID-D4FECFDC-F91A-4BDC-A1B0-A24EB087B2DD.htm)、[MASH の Python ノード](https://help.autodesk.com/cloudhelp/2017/ENU/Maya/files/GUID-DCB144BD-DFE2-418B-9838-E06963F61A20.htm)
- [A First Look at Cavalry](https://www.schoolofmotion.com/blog/a-first-look-at-cavalry)、[Cavalry 1.1（CG Channel）](https://www.cgchannel.com/tag/cavalry-1-1)、[Cavalry の例](https://cavalry.studio/docs/getting-started/example-files/)
- [FastNoiseLite](https://github.com/Auburn/FastNoiseLite)
- [Value Solver](https://cavalry.studio/docs/nodes/behaviours/value-solver/)、[Mesh Solver](https://cavalry.studio/docs/nodes/behaviours/mesh-solver/)、[Falloff](https://cavalry.studio/docs/nodes/utilities/falloff/)、[Spring](https://cavalry.studio/docs/nodes/behaviours/spring/)、[Apply Layout](https://cavalry.studio/docs/nodes/behaviours/apply-layout/)
- [Duplicator](https://docs.cavalry.scenegroup.co/nodes/shapes/duplicator/)、[Stagger](https://docs.cavalry.scenegroup.co/nodes/behaviours/stagger/)、[Context Module](https://cavalry.studio/docs/tech-info/scripting/context-module/)
- [Cavalry Behaviours](https://cavalry.studio/docs/nodes/behaviours/)、[JavaScript Deformer](https://cavalry.studio/docs/nodes/behaviours/javascript-deformer/)
