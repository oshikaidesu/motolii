# クローナーの要件（2026-11-08）

問い：クローナーは並べるだけのはずなのに、なぜコピーが付いてくるのか。よく売れているソフトも、なぜそうなっているのか。

この日の答えの移り変わり：

1. コピーは要る。問題は、コピーが無いと配列が動かない作りになっていること（根拠 A〜C）。
2. 「配列」と「壊さない 1 個だけの上書き」を両方持つ物は、クローナー系にもコンポーネント系にも無いように見えた（根拠 I）。けれど探し方が 2 つに割れていただけで、Adobe XD の Repeat Grid が両方を持っていた（根拠 J）。
3. 時間を特別に扱う必要は無い。編集中に動いた値の流れを記録すればよい（根拠 K）。
4. 記録できるということは、1 つの値にどこからでも値を入れられるということ。これを土台にすると、クローナーの要件の大半が「値の入れ口」1 つにまとまる（根拠 L）。

## 土台：値の入れ口

行ごと・値ごとに入れ口があり、入れ口には何でもつなげる。

| つなげる物 | 例 |
|---|---|
| 定数 | Inspector に打った値 |
| 手で打ったキー | タイムラインのキー |
| 記録 | 再生中にマウスで動かした流れ |
| 他の値 | 別の物の位置、別の行の値 |
| 音・LFO | 音の大きさ、揺れ |
| データの列 | テキストファイルの 1 行ずつ |
| 番号・住所を読む式 | 番号で色を変える、時刻 − 番号 × 遅れ |

つなぎ方は 2 通り：

- **足す**：手で動かした値や、全員への変更の上に重ねる（Ableton の Modulation、REAPER の Trim）
- **置き換える**：つないだ物だけが値を決める（Ableton の Remote Control、REAPER の Write）

記録は、つないだ入力をキーとして書き留めること。間引くかどうかは、書き留める時の問題にすぎない。

これまでの要件は、この入れ口の使い方に収まる：

- ばらつき・Effector ＝ 番号や住所を読んで値を返す入力（Graphite の Read Index、Cavalry の番号）
- 時間のずれ ＝ 「時刻 − 番号 × 遅れ」を返す入力（Animation Nodes の Delay、C4D の Step Gap）
- 1 個だけの上書き ＝ その行の入れ口に、手で値・キー・記録を入れること
- 全員への変更と 1 個の上書きの重なり ＝ つなぎ方が「足す」か「置き換える」か

クローナー本体に残るのは 2 つだけ：住所付きの行を作る**配列**と、物が足りない時の**巡回**。

Motolii の目的にも合う。ネットで見つけた表現を「入れ口につなぐ入力」として持ち込めれば、表現が増えるたびに開発側がクローナーを作り直さなくて済む。

## 要件

1. **配列**：住所付きの行を出す。何も描かない。並べ方（格子・円・線・散らす・面に置く）を選ぶ。住所は、格子なら（列, 行）、線・円なら順番、散らすなら散らす部品が作る安定 ID、面に置くなら（面の番号, 面の中の座標）。並び順の番号は住所にしない。（根拠 A・E・F。React、Houdini の `id`、CSS Grid の明示配置、Blender Distribute Points の `id`、Houdini Scatter の Prim Num／Prim UVW）
2. **数**：「自動」か「数字」。自動なら受け手の数だけ席ができ、コピーは起きない。数字ならその数だけ席ができる。（根拠 G。Figma のグリッド、CSS Grid）
3. **受け手**：席の位置を親として受け取る。種類は問わない（既存のレイヤー、文字、破片、線の頂点）。受け手が自分で持つ値の流れは、その上に重なる。既存の物をコピーせずに並べられる。（根拠 B・H。AE の親子、Houdini Transform Pieces、Animation Nodes の Object Matrix Output）
4. **巡回**：受け手が席より少ない時だけ、席の ID が物の数を超えたら頭へ戻って参照を作る。参照は元の値の流れを共有する。（根拠 B・J。Blender Instance on Points の Instance Index、Cavalry Auto Id、TiXL DrawMeshChunksAtPoints、XD Repeat Grid のテキスト流し込み）
5. **入れ口**：行ごと・値ごとに入れ口を持ち、上の表の何でもつなげる。つなぎ方は「足す」と「置き換える」。（根拠 L。Graphite、Ableton の Map、XD Repeat Grid）
6. **上書き**：その行の入れ口に、手で値・キー・記録を入れる。保存は元と違う分だけを「誰の・どの値を・何に」の行にする。触っていない行は保存しない。（根拠 D・H。Godot は元と違う値だけ保存し、触っていないノードは書き出さない。Unity の `m_Modifications`）
7. **記録**：再生中に動かした値を入れ口に書き留める。録り直しの範囲は Touch（触っている間だけ）／Latch（触った所から止めるまで）／Write（全部）／Trim（上から相対的にずらす）。間引きは書き留める時に選ぶ。（根拠 K。AE Motion Sketch、Apple Motion、Ableton、REAPER）
8. **切り離し**：その 1 個だけ本物の受け手にする。上書きはそのまま移る。配列の子のまま残るので、席に並び続ける。並べるのだけやめたい時は「配列から外す」。（根拠 D。Figma Detach、Unity Unpack、Blender Realize Instances の Selection、Figma の Ignore auto layout）
9. **置く順**：住所を持つ物を先に置き、残りの受け手とコピーを順番に詰める。足りなければ行を足す。（根拠 E・H。CSS Grid、Taffy、Penpot のグリッド）
10. **席が消えた時**：上書きは捨てずに眠らせる。席が戻ればまた効く。消すのはユーザーの明示操作。（根拠 E。Unity の Unused Overrides。Godot と Penpot は捨てる方）

## UI

レイヤー一覧：

- 配列は 1 つのレイヤー。並べ方はドロップダウン。（C4D の Mode、Unreal の Layout）
- 受け手は配列レイヤーの下にドラッグして入れる。複数なら「順番／ランダム」。（C4D、Unreal）
- 数の欄に「自動」を置く。（Figma のグリッド）
- 配列レイヤーを開くと、上書きのある行だけが並ぶ。眠っている上書きは薄く出し、右クリックで消せる。（AE の UU「変えたプロパティだけ表示」、Unity の Unused Overrides → Remove）
- 切り離した物は、配列の下に普通のレイヤーとして並ぶ。（Unity の Unpack、Figma の Ignore auto layout）

キャンバス：

- クリックで配列全体、Cmd／Ctrl＋クリックで 1 個。（XD Repeat Grid、Figma の入れ子の選び方）
- 1 個を別のセルへドラッグすると、住所が変わる。（Figma の手動配置）

値の欄：

- 値ごとに、今何がつながっているか（定数・キー・記録・つないだ物）が分かる。
- 値の横の「つなぐ」で、他の値・音・LFO・データの列・式につなぐ。つなぎ方は「足す」か「置き換える」。（Ableton の Map と Modulation／Remote Control）
- 記録ボタンを押して再生し、値を動かすと記録される。録り直しは Touch／Latch／Write／Trim から選ぶ。（Ableton の Automation Arm、Apple Motion の記録、REAPER のモード）
- 1 個を選んで値を変えると、そのまま上書きになる。上書きした値は名前が太字、左に線。（Figma、AE、Unity）
- 値を変えた時だけ「戻す」「全員に」が出る。（AE の Pull／Push、Unity の Revert／Apply、Godot の戻す矢印）
- 右クリック「切り離す」で、その 1 個だけ普通のレイヤーになる。（Figma の Detach、Godot の Make Local）

ユーザーが覚えるのは「選んで変える」「つなぐ」「記録する」「戻す」「全員に」「切り離す」。「コピー」「参照」「時間のずれ」という仕組みの言葉は出てこない。

## 自分の組み立て（先例をそのまま写していない所）

- 土台の「値の入れ口」に全部をまとめる形。Graphite（1 つの値に 3 通りの入れ方）、Ableton（どの値にも Map）、XD（各セルにデータを流し込む）を合わせたもの。配列・どこからでも入る入れ口・タイムラインへの記録の 3 つを全部持つ製品は、まだ確かめていない。
- 切り離した物が席に残る。Unity の Unpack（元の場所に残る）と Figma のオートレイアウト（子は既定で流れに並ぶ）を合わせたもの。
- 根拠 A の「なぜ束ねるか」。理由を書いた一次資料は見つかっていない。ドキュメントの作りからの推測。

## まだ

- 配列・入れ口・タイムラインへの記録の 3 つを全部持つ製品があるか。
- XD で 1 個だけ画像を差し替える方法と、Repeat Grid を解除した時の動き。
- 記録をどこまで間引くか、録り直しのモードをいくつ持つか。
- 入れ子の番号を、段ごとの列（Graphite）にするか、経路（cables）にするか、平たく（TiXL）するか。
- Unreal の Cloner のパラメータにキーを打てるか。公式ガイドの画像では各項目にひし形の印があるが、ソースでは確かめていない。入れ子にできるか、FreePlacement で物が席より少ない時どうなるかも未確認。
- 面そのものの数が変わる時（モデルを作り直した時）、面の番号の住所がずれる。Houdini は Primitive Seed Attribute で対処している。その中身は読んでいない。
- Cavalry の番号のずれは、ドキュメントからの導き。Cavalry 本体では試していない。
- TiXL で Loop と SetTime を組み合わせた見本は見つかっていない。

---

# 根拠

## A. 配列とコピーは、元から別の部品

配列が出すのは「位置の列」（位置・向き・大きさ・番号）だけで、それ単体では何も描かない。コピーは、その位置に物を置いて目に見えるようにする役。クローナーはこの 2 つを 1 つの部品に束ねている。

| 見本 | 配列（位置だけ） | 置く・コピー | 確かめた所 |
|---|---|---|---|
| Cinema 4D | Matrix Object：物を作らずに位置だけ作る。レンダリングされない | Cloner を Object モードにして Matrix を指す | Matrix は検索の抜粋。Cloner は 2027 の本文 |
| Houdini | 点の集まり | Copy to Points：入力 1 の形を入力 2 の点に置く | 検索の抜粋 |
| Blender | Distribute Points：点群を作る | Instance on Points：各点に形への参照を置く。"without duplicating the underlying data" | Instance on Points は本文、Distribute は索引ページ |
| Cavalry | Distribution：Duplicator 以外（Connect Shape）も使う | Duplicator | 本文 |
| Unreal Motion Design | Cloner に Layout が内蔵 | 同じ部品の中 | 本文（全 116,188 字のうち先頭 100,000 字） |

- 束ねている側の代表の Cinema 4D 自身が、配列だけの部品（Matrix）を持っている。
- Effector のタブは Matrix にもある（"share parts of the clone object settings, such as the Transformation and Effectors tabs"）。Effector が作用しているのはコピーではなく位置の列。
- Graphite は 11/2 に Copy to Points を「繰り返す」と「ばらつかせる（どんな並びにも効く）」に分けた（PR #4906。理由は書かれていない）。

なぜ売れているソフトは束ねるのか（推測。メーカーの説明は無い）：

- 物の一覧（C4D の Object Manager、AE・Alight のレイヤー）に並べられるのは「物」だけで、「位置の列」を置く場所が無い。点が普通のデータとして流れる Houdini と Blender は、自然に分かれている。
- 利用者の言葉が「これを 10 個並べて」なので、一手で済ませるために束ねる。

## B. コピー無しで配列を使っている先例

| 見本 | 位置を受け取る物 | つなぎ方 | 確かめた所 |
|---|---|---|---|
| C4D Fracture | 子にした既存の物。"views all child objects as clones that can be affected by any Effector" | 既存の物をクローンとして扱う | 2027 の本文 |
| Houdini Transform Pieces | 既存の形を、テンプレートの点の位置へ動かす | Index by Attribute（番号）か Match by Attribute（属性の値） | 本文（先頭 100,000 字） |
| Cavalry Connect Shape | 物ではなく、線の頂点 | Distribution の点 | 本文 |
| Animation Nodes Object Matrix Output | 既存のオブジェクトの並び。`min(len(objects), len(matrices))` 個に書き込み、余った席は無視 | 並び順 | ソース `e2c208a` |
| TiXL DrawMeshChunksAtPoints | メッシュの部品。"point n draws chunk n"、短ければ繰り返す | 番号と巡回 | ソース |
| Unreal FreePlacement | 下に付けた本物のアクターを選んで動かす（ガイドに載っていない） | アクターごとの位置 | ソース（公開ミラー） |

物が足りない時の埋め方：Cavalry Duplicator は Auto Id で巡回、C4D Cloner は "processed in sequence or randomly"、Unreal は Iterate／Random／Blend。

## C. コピーは自分のキーフレームを持てない

- Houdini はパラメータにならキーを打てる（Alt＋クリック）。打てないのは、配置した 1 個ずつに直接打つこと。
- C4D もクローン 1 個ずつには打てない。Maxon の開発者フォーラムの答えは「Cloner を Make Editable するしかない」（全部を本物にする）。
- コードを読んだ実装（根拠 H）でも、キーはいつも配列か Effector のパラメータに付き、コピー 1 個ずつにキーを持たせる実装は無かった。

キーフレーム式のソフトでの先例：After Effects の親子（子の動きは親からの相対）、C4D Inheritance Effector（手本のキーをクローンが順に受け継ぎ、Step Gap で遅らせる）。

## D. 1 個だけ変える：上書きと切り離し

| 見本 | 1 個だけの扱い | 確かめた所 |
|---|---|---|
| After Effects Essential Properties | 1 つのインスタンスで値を変えると、元の値かキーを上書きする。Push で全員に戻す | 検索の抜粋（helpx は 403） |
| Unity Prefab | 上書きは元より常に優先。保存は `m_Modifications` に `(target, propertyPath, value)` の行。Unpack は元の場所に残り、上書きも移す | 上書きの画面は本文、他は検索の抜粋 |
| Figma | 上書き：インスタンスを編集するとそのまま上書き。Detach：その 1 個だけ普通のフレームにする | 上書きは本文、Detach は検索の抜粋 |
| Blender Realize Instances | Selection で選んだインスタンスだけ本物にする | 検索の抜粋 |
| Godot | 元と違う値だけを名前と値で保存。触っていないノードは書き出さない。`unique_id` で探し直す。キーは上書きできず Make Unique（切り離し） | ソース `c51ff06e8` |
| Penpot | 値でなく「どの種類の値を触ったか」（`:touched`）を持つ。Reset はコピー丸ごと | ソース `904cdd971` |

「1 個だけ」には 2 段ある：上書き（つながったまま変える）と切り離し（本物にする）。C4D の Make Editable はこの 2 段が無く、全部か無しか。

## E. 並び順の番号はずれる

| 見本 | 書いてある事 | 確かめた所 |
|---|---|---|
| Unity | 配列の中の上書きは位置で記録される。項目を足し引きすると別の項目に付くことがある | 検索の抜粋 |
| React | 番号を key にすると、挿入・削除・並べ替えで取り違える。DB の ID を使う | 本文 |
| Flutter | key が無いと型と位置で対応させ、間違った State が付く | 本文 |
| Houdini | `id` は点の番号とは別。番号が変わっても追える | 本文 |
| Cavalry | 通し番号 1 つだけ。入れ子は足し合わせて 1 本 | Context は本文、Index Context は検索の抜粋 |
| Graphite | ばらつきの値は並び順で決まる（`spread.rs`） | ソース `be72f25` |

住所の先例：CSS Grid（位置を持つ物を先に置き、残りを詰める）、Figma のグリッド（自動配置を切るとドラッグしたセルに留まる）、Penpot（セルが id・行・列・auto／manual／area を持つ物として保存される）。

席が消えた時：Unity は「使われていない上書き」として残し、戻ればまた効く。Godot は警告して捨てる。Penpot も捨てる。

## F. 散らす・面に置く配置の住所

| 見本 | 書いてある事 | 確かめた所 |
|---|---|---|
| Blender Distribute Points on Faces | 点ごとに安定した `id` を作る。密度を変えても、残った点の値は変わらない | 本文 |
| Houdini Scatter | `id` は後で点を消しても元の番号を追える。Prim Num（どの面の上か）と Prim UVW（面の中の座標）を出せる | 本文（先頭 100,000 字） |
| Houdini Attribute Interpolate | 面の番号と面の中の座標で、変形する形に点を付いて行かせる | 本文（先頭 100,000 字） |
| Blender Instance on Points | 置く物の番号は既定で点の ID。大きすぎる番号は頭へ巡回 | 本文 |

注意：Houdini Scatter は Force Total Count を切ると、面の広さや密度が変わった時に点がちらつくと書いている。

## G. 数をどこが持つか

| 系統 | 数の持ち方 | 見本 |
|---|---|---|
| クローナー系 | 配列が持つ。物は巡回 | C4D Cloner、Unreal、Cavalry、Houdini Copy to Points |
| レイアウト系 | 列は決める。行は「自動」が既定で、中身の数に合わせて増減 | Figma のグリッド（本文） |
| 〃 | 決めた枠を超えたら自動で行を足す | CSS Grid（MDN の本文）、Taffy、Penpot |

C4D はこの 2 つを別の部品に分けている（Cloner と Fracture）。Figma は 1 つの欄の「自動／数字」で両方を扱う。

## H. コードで読んだ時間の扱いと UI の出し方

4 つの調べ役がリポジトリのソースを読み、主な主張は親がソースで確かめた。ライセンスでは絞っていない。

### 時間

| 実装 | 配列のパラメータにキー | コピーの時間 | 1 個ごとの時間のずらし方 | 確かめた所 |
|---|---|---|---|---|
| Animation Nodes | Time Info からつなぐ | 番号でずらせる | `outTime = time - delay`、キーを打った動きを `frame - index * self.delay` で再生 | ソース `e2c208a` |
| TiXL | どの入力もキー可 | 全員同じ | 部品は無い。番号を 0〜1 にした値と、キーを打った Phase で作る | ソース |
| cables.gl | どのポートもキー可 | 全員同じ | 無い | ソース（11/7） |
| Graphite | エディタにキーはまだ無い | 全員同じ | 無い。中身の中で「番号を読む」と時間を計算 | ソース `be72f25` |
| Godot（シーンの複製） | — | 複製ごとに自分の再生器 | 親の Animation トラックで開始時刻を決める（`time - pos`） | ソース `c51ff06e8` |
| Friction（Link） | — | Link ごとにタイムラインのバーをずらせる | バーのずれと Frame Remapping | ソース `91179f8` |
| Unreal Cloner | 画像ではひし形の印あり（ソース未確認） | 付けた物は焼いたメッシュで全員同じ瞬間 | Delay Effect は効きのバネ遅れで、中身の時間ではない | ソース（公開ミラー）と公式ガイド |
| Glaxnimate Repeater | キー可 | 全員同じ `t` | 無い。Lottie の `o` は読み捨て | ソース `3d4c655` |
| ThorVG（Lottie Repeater） | 毎フレーム評価 | 全員同じ | 無い。`offset` は空間（`offset + i`） | ソース `d347fc8` |

### UI

| 実装 | 何として見せるか | 1 個を選べるか |
|---|---|---|
| Graphite | レイヤー。上流の部品が Inspector に並ぶ | 選べない（"Only item 0 is recorded since editing tools can only target a single item currently"）。Data パネルで番号を手で入れて評価し直す |
| TiXL | 部品のグラフ、パラメータ窓、タイムライン | 選べない。VisualizePoints で点の値を表として重ねる |
| Animation Nodes | ノードエディタ。コピーは本物のオブジェクト | 選べるが、毎フレーム上書きされる |
| Unreal Cloner | アクター。下に付けたアクターが元 | 選べない（焼くと静的メッシュ）。FreePlacement だけは下のアクターを選べる |
| Friction | Duplicate はパス効果、Link は 1 個ずつレイヤー | Link は選べる |
| Glaxnimate | レイヤーツリーの中の 1 つの部品 | 選べない |
| Godot | シーンツリーのノード。元と違う値に「戻す」矢印、ピン留め | 選べる |
| Penpot | レイヤー。上書きの印は普段の画面に無い | 選べる |

## I. 「配列」と「壊さない上書き」の両方を持つ物

クローナー・リピーターでは、1 個だけ変えるには壊す操作が要るか、そもそもできない。

| 実装 | 1 個だけ変えたい時 |
|---|---|
| Cinema 4D | Make Editable で全部を本物にする |
| Unreal | 静的メッシュに焼く（"this is a heavy operation"） |
| Glaxnimate | パスに焼く（`to_path`） |
| Godot | 値は上書きできるが、キーは Make Unique で切り離す |
| Graphite・TiXL | 1 個を狙う手段が無い |
| Animation Nodes | 手で変えても毎フレーム上書きされる（コードからの推測） |

壊さずに 1 個だけ変えられるのは、コンポーネント・インスタンス側（Godot、Unity、Figma、Penpot、AE Essential Properties）だけ。こちらは並べる機能を持たない。

## J. Adobe XD の Repeat Grid（I の空白は探し方の問題だった）

- 取っ手を引くと、引いた分だけ数が増えて並ぶ。
- スタイルの変更は全部のコピーに効く（"When you modify any style of an element, the change is replicated in all the elements of the grid"）。
- 文字の中身はコピーごとに別にできる（"Only the style of the text element is replicated and not the content"）。
- Cmd／Ctrl＋クリックで 1 個を選べる。
- テキストファイルをグリッドに落とすと、1 行ずつ各セルに入る。セルの方が多ければ頭から繰り返す。

並べる・つながったコピー・1 個だけ上書き・1 個を選ぶ・データを流し込む・足りなければ巡回、が 1 つの機能にある。確かめたのは公式ヘルプの検索の抜粋。タイムラインは無い。

UI のコードでも同じ組み合わせが普通に書かれている：key の付いたリスト（React・Flutter）をグリッドのレイアウト（CSS Grid）に流し、同じ部品を行ごとに違う値で描く。

## K. 時間は「動かした値の流れ」を記録すればよい

| 見本 | 動かした値を記録する仕組み | 記録の量を減らす方法 | 確かめた所 |
|---|---|---|---|
| After Effects Motion Sketch | 時間を流しながらレイヤーをドラッグすると、毎フレームに位置のキー | Smoothing（いらないキーを消す） | 検索の抜粋 |
| Apple Motion | 記録をオンにして再生し、パラメータを動かすとキーになる | Off／Reduced／Peaks Only、あとから Reduce Keyframes | 検索の抜粋 |
| Ableton Live | Automation Arm をオンにして録音すると、動かした値がすべてオートメーション | Simplify Envelopes | 検索の抜粋（マニュアル v12） |
| REAPER | 録り直しのモード：Touch（触っている間だけ、一番壊さない）、Latch（触った所から止めるまで）、Write（全部書き換え、一番壊す）、Trim（記録の上から相対的にずらす） | — | 解説記事の検索の抜粋（公式マニュアルではない） |

「壊さずに 1 個だけ」は、時間の上では DAW がもう解いている。Touch なら触った所だけ上書きされる。Trim なら全員への変更を、記録済みの流れの上から重ねられる。

## L. 1 つの値に、どこからでも入れる

| 見本 | 1 つの値への入れ方 | 確かめた所 |
|---|---|---|
| Graphite | "Node parameters can be set to a constant value in the Inspector, exposed to the graph for procedural animation, or exposed to a channel in the upcoming Timeline panel for hand-authored keyframing." | ソース `website/content/features.md:449` |
| Ableton Live | LFO・Envelope Follower を、自動化できる値ならどれにでも Map でつなぐ。Modulation（手の値の上に足す）か Remote Control（つないだ物だけが決める） | 検索の抜粋（マニュアル v12） |
| Adobe XD Repeat Grid | テキストファイルの 1 行ずつを各セルに流し込む。足りなければ頭から繰り返す | 検索の抜粋 |

## 出典

ドキュメント：

- [Cinema 4D Cloner Object](https://help.maxon.net/c4d/2027/en-us/Content/html/OMOGRAPH_CLONER.html)
- [Cinema 4D Matrix Object](https://help.maxon.net/c4d/2027/en-us/Content/html/OMOGRAPH_MATRIX.html)
- [Cinema 4D Fracture Object](https://help.maxon.net/c4d/2027/en-us/Content/html/OMOGRAPH_FRACTURE.html)
- [Cinema 4D Inheritance Effector](https://help.maxon.net/c4d/s22/us/html/OEINHERITANCE-MGINHERITANCEEFFECTOR_GROUPEFFECTOR.html)
- [Cinema 4D MoGraph Selection Tool](https://help.maxon.net/c4d/en-us/Content/html/TOOL_MGSELECT.html)
- [Cinema 4D MoGraph Selection tag](https://help.maxon.net/c4d/2025/en-us/Content/html/TMGSELECTION.html)
- [Maxon Developers forum（クローン 1 個ずつの扱い）](https://developers.maxon.net/forum/post/38298)
- [Houdini Copying and instancing](https://www.sidefx.com/docs/houdini/copy/copytopoints.html)
- [Houdini Transform Pieces](https://www.sidefx.com/docs/houdini/nodes/sop/xformpieces.html)
- [Houdini Geometry attributes](https://www.sidefx.com/docs/houdini/model/attributes.html)
- [Houdini Animation basics](https://www.sidefx.com/docs/houdini/anim/basics.html)
- [Houdini Scatter](https://www.sidefx.com/docs/houdini/nodes/sop/scatter.html)
- [Houdini Attribute Interpolate](https://www.sidefx.com/docs/houdini/nodes/sop/attribinterpolate.html)
- [Blender Instance on Points](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/instances/instance_on_points.html)
- [Blender Point Nodes](https://docs.blender.org/manual/en/3.6/modeling/geometry_nodes/point/index.html)
- [Blender Distribute Points on Faces](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/point/distribute_points_on_faces.html)
- [Blender Realize Instances](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/instances/realize_instances.html)
- [Cavalry Duplicator](https://cavalry.studio/docs/nodes/shapes/duplicator/)
- [Cavalry Distribution Types](https://scenegroup.gitbook.io/cavalry/user-interface/general/distribution-types)
- [Cavalry Connect Shape](https://cavalry.studio/docs/nodes/shapes/connect-shape/)
- [Cavalry Context](https://cavalry.studio/docs/getting-started/key-concepts/context/)
- [Cavalry Index Context](https://docs.cavalry.scenegroup.co/nodes/utilities/index-context/)
- [Cavalry Grid Layout](https://docs.cavalry.scenegroup.co/nodes/behaviours/apply-layout/grid-layout/)
- [Unreal Motion Design Cloners and Effectors](https://dev.epicgames.com/documentation/en-us/unreal-engine/motion-design-cloners-and-effectors-in-unreal-engine)
- [After Effects layer properties（親子）](https://helpx.adobe.com/after-effects/using/layer-properties.html)
- [After Effects Essential Properties](https://helpx.adobe.com/after-effects/desktop/motion-graphics/essential-properties/essential-properties.html)
- [After Effects keyboard shortcuts（UU）](https://helpx.adobe.com/after-effects/desktop/get-started/keyboard-shortcuts/keyboard-shortcuts-reference.html)
- [After Effects Assorted animation tools（Motion Sketch）](https://helpx.adobe.com/after-effects/using/assorted-animation-tools.html)
- [Adobe XD Repeat Grid](https://helpx.adobe.com/xd/help/create-repeating-elements.html)
- [Apple Motion Animate on the fly](https://support.apple.com/kb/PH16103)
- [Apple Motion Simplify a keyframe curve](https://support.apple.com/guide/motion/simplify-a-keyframe-curve-motn147475e6/mac)
- [Ableton Reference Manual v12 Automation](https://www.ableton.com/en/live-manual/12/automation/)
- [Ableton Reference Manual v12 Max for Live Devices](https://www.ableton.com/en/live-manual/12/max-for-live-devices/)
- [REAPER automation modes（Tuts+）](https://music.tutsplus.com/how-to-use-reaper-automation-and-envelopes--cms-107723t)
- [Sound On Sound Automation in action](https://www.soundonsound.com/techniques/automation-action)
- [Unity Prefab instance overrides](https://docs.unity.com/en-us/engine/current/manual/working-with-gameobjects/prefabs/override/prefab-instance-overrides)
- [Unity YAML serialization of prefabs](https://docs.unity3d.com/6000.6/Documentation/Manual/yaml-prefab-serialization.html)
- [Unity Removing unused override data](https://docs.unity3d.com/6000.5/Documentation/Manual/UnusedOverrides.html)
- [Unity Revert a prefab instance to a GameObject（Unpack）](https://docs.unity3d.com/Manual/UnpackingPrefabInstances.html)
- [Figma Apply changes to instances](https://help.figma.com/hc/en-us/articles/360039150733-Override-properties-of-a-Component-Instance)
- [Figma Detach an instance](https://help.figma.com/hc/en-us/articles/360038665754-Detach-an-instance-from-the-component)
- [Figma Select layers and objects](https://help.figma.com/hc/en-us/articles/360040449873-Select-layers-and-objects)
- [Figma Use the grid auto layout flow](https://help.figma.com/hc/en-us/articles/31289469907863-Use-the-grid-auto-layout-flow)
- [Figma Guide to auto layout（Ignore auto layout）](https://help.figma.com/hc/en-us/articles/360040451373-Guide-to-auto-layout-in-Figma)
- [MDN Basic concepts of grid layout](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout/Basic_concepts_of_grid_layout)
- [MDN Auto-placement in grid layout](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout/Auto-placement_in_grid_layout)
- [React Rendering Lists](https://react.dev/learn/rendering-lists)
- [Flutter Key class](https://api.flutter.dev/flutter/foundation/Key-class.html)

ソース：

- [GraphiteEditor/Graphite](https://github.com/GraphiteEditor/Graphite)（`be72f25`）と [GraphiteEditor/Graphite#4906](https://github.com/GraphiteEditor/Graphite/pull/4906)
- [tixl3d/tixl](https://github.com/tixl3d/tixl)
- [JacquesLucke/animation_nodes](https://github.com/JacquesLucke/animation_nodes)（`e2c208a`）
- [cables-gl/cables](https://github.com/cables-gl/cables)
- [godotengine/godot](https://github.com/godotengine/godot)（`c51ff06e8`）
- [penpot/penpot](https://github.com/penpot/penpot)（`904cdd971`）
- [DioxusLabs/taffy](https://github.com/DioxusLabs/taffy)（`4aca4f4`）
- Unreal Engine ClonerEffector プラグイン（公開ミラー `orgitcog/u9n` の `Engine/Plugins/VirtualProduction/ClonerEffector`。本家 `EpicGames/UnrealEngine` は権限が無く 404）
- [TheDuckCow/Blender_Effectors](https://github.com/TheDuckCow/Blender_Effectors)
- [friction2d/friction](https://github.com/friction2d/friction)（`91179f8`）
- [Glaxnimate（KDE invent）](https://invent.kde.org/graphics/glaxnimate)（`3d4c655`）
- [thorvg/thorvg](https://github.com/thorvg/thorvg)（`d347fc8`）
