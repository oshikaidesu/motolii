# Create と Program の線引き

## いまの考え（11/9 ユーザーと決めた）

- **Create** ＝ ホスト（Motolii）に頼るもの。Motolii の物（レイヤー）とその値があって、そこに付く・それを動かす。fx・レイヤーと同じ側。
- **Program** ＝ 中で閉じているパック。物も動きもノブも、コードの中に全部ある。p5.js、Cavalry のスクリプト。
- **AE の式は Create 側。** AE でも式はレイヤーの値に付くもので、単体では何も描かない。物に付いた式は、その物の詳細パネル（Code）にだけある。Program タブには出さない。
- **物に付く JS は全部「Expression」と呼ぶ。** Repeater、AE Grid/Ring/Stagger、今「Motion」と呼んでいる Cavalry の Animator を1つにまとめる。どれも中身は「物の値を動かす JS」で、同じ種類の物。名前は AE 自身の呼び名で、AE を使う人がこの言葉で探す。
- **Expression は Effects 棚に、選んでいる物に付くものとして並べる。** Create の「Copies」の枠はやめる。AE Grid/Ring/Stagger も、新しい丸を作るのをやめて、選んでいる物に付ける。
- **1つの物に Expression をいくつでも付けられるようにする。** AE は1つのレイヤーに式をいくつも付けられる。使う人は「並べる」と「動かす」を同時にやりたい。
- **Expression のカードは、エフェクトのカードと同じに扱う。** 詳細パネルでは同じ見た目なのだから、重ねる・目玉で消す・⋮メニュー・複製・並べ替えが同じにできる。今は Script のカードだけ1つしか付かず、目玉も並べ替えも無い（`skin/book/lib/sets/inspector/inspector_effects.dart:159`・`:165`）。

## 今の「レシピ」がこの線のどちらにいるか（11/9 時点のコード）

`engine/recipes/` の1つの書き方（`engine/doc_recipes.h:2` `doc_recipes_read`）に、両方が入っている。めちゃくちゃに見えるのはこのため。

| レシピ | 中身（根拠） | どっち |
|---|---|---|
| Canvalry の分（lissajous・cube・sphere など） | Cavalry のスクリプトを丸ごと動かす。コピーの位置・回転・ノブはスクリプトの中（`engine/recipes/from_canvalry.py:2`） | Program |
| Cube Wave・Dwitter-48ed・Blob Track | `// make` の頭が無く、p5 などのまま（`Cube Wave.js:1`「as it is」、`doc_recipes.h:10`） | Program |
| am_*（AbsentMotion の形） | ホストのパスの形に値を入れただけ（`// make shape path`） | Create |
| burst・rings・tunnel など | ホストのコピーの値を決めるだけ。計算は C++（`engine/doc_kinds.h:345` 付近） | Create |
| Repeater・AE Grid/Ring/Stagger | AE の式。ホストの物の値（コピーの位置）を動かす | Create |

## 今の作りとの差

- 11/9 の未コミットの変更（`skin/book/lib/workspace/script_code.dart`）は、打ち直した式の写しを `programs/` に置く。そのため Program タブに出てしまい、この線の反対側にいる。
- 同じ変更の「Add to Create」（式のプリセットを `recipes/` に書く、`dock_make_4.dart`）は、レシピの書き方をさらに増やしている。取り下げる方向で、まだ決めていない。
- 物の `script` にはファイルが1つしか入らない（`engine/doc_values.h:321`）。Effects の Motion も Repeater もこの1つを書き換えるので、同時に付けられない（`skin/book/lib/workspace/ws_2.dart:624`、`dock_make_2.dart:496` の「It has a script already」）。例外はステージ（物番号0）で、複数入る（`doc_values.h:329`）。
- 物の `fx`（エフェクトの列）にはファイルをいくつでも順に並べられ、AbsentMotion の動き（`.am`）はもう複数重なる（`doc_values.h:322`・`:333`）。Expression をこの列に入れられれば、並べ替え・目玉・外す・複製もエフェクトのカードの操作のまま使える。ただし、fx の列に入れた JS がコピーの並べ方（`each()`）まで動くかは、まだ確かめていない。
- Create の Copies の枠は、Repeater 1つだけの特別な枠（`skin/book/lib/workspace/dock_make_2.dart:416`）。
- Glass（Materials の枠）も「選んでいる固体を変える」ので、同じ理由で Create にいるのは筋が通らない。どこへ置くかはまだ決めていない。

## 出典

- AE の式はレイヤーのプロパティに付く：Adobe「Expression basics」（https://helpx.adobe.com/after-effects/using/expression-basics.html）
- Canvalry を丸ごと動かしている：`engine/recipes/from_canvalry.py` の頭のコメント
