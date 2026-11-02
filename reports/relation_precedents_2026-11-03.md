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
- [Cavalry Behaviours](https://cavalry.studio/docs/nodes/behaviours/)、[JavaScript Deformer](https://cavalry.studio/docs/nodes/behaviours/javascript-deformer/)
