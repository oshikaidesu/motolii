# Create と Program の線引き

## いまの考え（11/9 ユーザーと決めた）

- **Create** ＝ ホスト（Motolii）に頼るもの。Motolii の物（レイヤー）とその値があって、そこに付く・それを動かす。fx・レイヤーと同じ側。
- **Program** ＝ 中で閉じているパック。物も動きもノブも、コードの中に全部ある。p5.js、Cavalry のスクリプト。
- **AE の式は Create 側。** AE でも式はレイヤーの値に付くもので、単体では何も描かない。物に付いた式は、その物の詳細パネル（Code）にだけある。Program タブには出さない。

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
- Create の中を「新しいレイヤー」と「物に付けるもの（fx・式）」でどう並べるかは、まだ決めていない。

## 出典

- AE の式はレイヤーのプロパティに付く：Adobe「Expression basics」（https://helpx.adobe.com/after-effects/using/expression-basics.html）
- Canvalry を丸ごと動かしている：`engine/recipes/from_canvalry.py` の頭のコメント
