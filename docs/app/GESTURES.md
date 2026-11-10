# 操作の決まり

*The one grammar of gestures for Motolii's app: what a press, a double press, a right press, a drag, a wheel, a hover and each key mean on every control of a kind; the numbers they share (`Gestures`); the outer frame (fold, reorder, remove, hide, rename, menu); and the exceptions that stand, each with its reason from the side of the person using it. Read it before making a panel.*

アプリの Dart は操作の口で、自分の流儀を持たない。同じ操作は、同じ種類の部品のどこでも同じ意味で、同じ数で働く。例外が立つのは、使う人の側の理由がある時だけ。基本の操作は After Effects に従う。

パネルを作る前に読む。規格の部品（`app/lib/widgets/`）で組めば、ここの決まりは部品が守る。見た目の決まりは [DESIGN.md](DESIGN.md)。

決まりは 1 行に 1 つ。頭の `press.1` のような名前で引く。行の終わりが出所：

- `[AE]` After Effects　`[Mac]` macOS・Finder・Apple の指針　`[Alight]` Alight Motion
- `[他：名前]` それ以外の、使う人が知っているアプリや規格
- `[作者 日付]` 作者がその日に決めた　`[DESIGN]` DESIGN.md の決まり
- `[大半]` 使う人の側の出典は無い。アプリの大半が既にこうしている

もとは 2026-11-10 の調べ（全パネルの操作 655 行、外枠 261 行）。数は `app/lib/widgets/gestures.dart` の `Gestures` に 1 回だけ書き、部品はそこから読む（この文書が先で、コードはこれに合わせて直している）。

---

## 1. 押し

- `press.1` ボタン・チップ：主ボタンで押し、中で離した時に 1 回だけ働く。外へ滑らせて離せば取り消し。待たない。`[大半]`
- `press.2` 選ぶ・つかむ（タイル、行、プレビューのレイヤー、キーフレーム、取っ手）：ボタンが下りた時に取る。選ぶだけなら取り消しに残らない。`[Mac]` `[作者 2026-10-31]`
- `press.3` 切り替え（目・スイッチ）：1 回でその場で入れ替わり、すぐ見える。押し続けも順送りも無い。言葉とスイッチは 1 つの部品。`[Alight]`
- `press.4` 選択肢：1 回でそれになって光る。光っている物を押しても何も書かない。順送りしない。5 つ以上は浮く一覧から選ぶ。`[大半]`
- `press.5` 数：押してその場で離すと打ち込みになり、数は全部選ばれている。`[AE]`
- `press.6` スライダーと色：ボタンが下りた所の値をすぐ取り、手に付いていく。色見本は 1 回でその色になる。`[他：CLIP STUDIO PAINT]` `[Alight]`
- `press.7` 文字の欄：押すとキャレット、二度押しで単語、ドラッグで範囲、Shift＋押しで伸ばす。1 行の名前・値の欄は、全部選んだ状態でキーを取る。`[Mac]`
- `press.8` ビュー（プレビュー・ルーラー・帯）：押した所ですぐ働き、動くのは表示と選択だけ。何も無い所を押せば選択が外れる。作る道具のほかは何も作らない。再生はボタンが下りた時に止まる。`[AE]` `[Alight]`

## 2. 二度押しと押し続け

- `double.1` 数・スライダー：既定の値に戻る（1 回目で開いた打ち込みは、2 回目で閉じる）。`[作者 2026-10-20]`
- `double.2` 名前：その場で書き直す。全部選ばれている。`[他：Final Cut Pro・Figma]`
- `double.3` タイル：使う（付ける・作る・置く・開く）。取り消し 1 回。繰り返しても外れない。`[Mac]`
- `double.4` ビューの何も無い所・ルーラー：選んだ物へ、無ければ全体へズームする。`[他：Ableton Live]`
- `double.5` グラフの線：そこに点を 1 つ置く。`[他：Ableton Live]`
- `double.6` 仕切り・高さのつまみ：既定の大きさに戻る。`[大半]`
- `double.7` プレビューのレイヤー：そのレイヤー自身の編集に入る（画像は切り抜き）。`[他：Figma・Keynote]`
- `long.1` ボタン・チップ・切り替えを `Gestures.longPress` より長く押し続けても、何も起きない。`[大半]`

## 3. 右押し

- `right.1` その物のメニューが、ボタンが下りた時にポインターの所へ開く。先にその物が選ばれる。`[他：Ableton Live・Figma]`
- `right.2` 消せる・名前を変えられる・複製できる物は、そのメニューに Delete・Rename…・Duplicate がある。`[大半]`
- `right.3` 数：値のメニュー（Reset・Copy・Paste、キーフレームの行）。`[AE]`
- `right.4` 右押しは何も動かさない（こすらない、回さない、色を付けない、取り消しを増やさない）。メニューの無い物では何も起きない。`[大半]`

## 4. ドラッグ

- `drag.1` 押しがドラッグになるのは、下りた所から `Gestures.dragSlop` 動いた時。値も、物も、ビューも、囲みも同じ。`[大半]`
- `drag.2` 数：横にこする。右が増える。動かす間ずっと見え、パネルは流れない。`[AE]`
- `drag.3` 物・取っ手：`Gestures.grab` 以内の一番近い物を、ボタンが下りた時につかむ。飛びつかず、手が動いた分だけ動く。持つ間は光り、作っている数が手元に出る。`[他：Figma]` `[Alight]`
- `drag.4` タイムラインのバーとキーフレーム：フレーム単位で動く。ほかの止まり所の `Gestures.snap` 以内で止まり、そこに線が出る。`[Alight]`
- `drag.5` タイルを運ぶ：22 px のアクセントの四角がポインターに付く。プレビューに落とせば二度押しと同じ。ほかの所では何も起きない。`[他：Ableton Live]`
- `drag.6` 並びへ運ぶ：入る所が 2 px のアクセントの線か輪で見える。離すとそこへ入る。受ける所が無ければ元のまま。落として消えることは無い。`[AE]` `[Alight]`
- `drag.7` 選べる物があるビューの何も無い所：囲んで選ぶ（触れた物が入る）。見せるだけのビューでは表示が動く。`[AE]`
- `drag.8` 1 回のドラッグは取り消し 1 回。何も変わらなかったドラッグは取り消しに残らない。`[大半]`
- `drag.9` 見せている範囲は表示のため。こすりは範囲の端で止まり、Option で越える。打ち込んだ値は範囲で切らない。本当に限る時は、同じ値を限っている出典を数の横に書く。`[AE]` `[作者 2026-11-09]`

## 5. ホイールと 2 本指

- `wheel.1` 数：押さずに、上でホイールを横へ回すか 2 本指を横へ滑らせると、こすりと同じ速さで変わる。縦はパネルが流れる。`[大半]`
- `wheel.2` 値を変えるひと続きのホイール・滑りは取り消し 1 回。手が止まって `Gestures.burstRest` で閉じる。`[AE]`
- `wheel.3` ビュー：ホイールは表示を運ぶ（縦。横向きか Shift＋ホイールで横）。ズームは Cmd＋ホイールで、ポインターの下を中心に 1 目盛り 1.0015 倍。`[Mac]` `[大半]`
- `wheel.4` ビュー：2 本指は見えている物を指と一緒に運ぶ（1 px に 1 px）。つまむと指の下を中心にズームする。`[Mac]`
- `wheel.5` 一覧・メニュー・チップの列：ホイールで流れる（横の列は横の滑りか Shift＋ホイール）。どの行も切れない。`[Mac]`
- `wheel.6` 2 本指は押しにならない。値・取っ手・バーをドラッグせず、表示を運ぶか回すだけ（押しになるのはマウス・指・ペン：`wsPressing`）。`[他：Blender]`

## 6. ホバーとカーソル

- `hover.1` 押せる物は、手が乗るとすぐ（`Gestures.hover`）1 段明るくなる：灰色の地は `WsT.raised`、文字は g95、アクセントの地は `WsT.accentHot`、地の無い印や言葉は文字だけ。今押せない物は光らない。`[大半]`
- `hover.2` カーソル：押すと働く物は手。こする数は左右の矢印。打ち込み中は I。運べる物は grab。何もしない物は普通の矢印。`[大半]`
- `hover.3` 状態の変化（オン・オフ、スイッチ、畳みの印）は `Gestures.change` かけて変わる。`[DESIGN]`
- `hover.4` タイルは絵に 1 px の g76 の枠が付き、動く絵が手の下で動く。行は地が 1 段上がる。ホバーはいつも「選ばれた」より弱い（選ばれた見た目は DESIGN.md §4）。`[大半]`
- `hover.5` ビューとバーの上では、カーソルが「押したら何が起きるか」を言う（端：左右の矢印、体：grab、キーフレーム：手）。`[大半]`
- `hover.6` アクセントは「オン・選ばれた」の色。ホバーには使わない。`[大半]`

## 7. Return・Escape・離れる

- `key.1` Return：打った文字を 1 回言って欄を出る。空なら何も言わず前のまま。読めない文字は、理由を見せて欄を開けたまま断る。`[大半]`
- `key.2` 欄を離れる（ほかを押す・Tab）：Return と同じく言う。`[Mac]`
- `key.3` Escape：捨てる。前の文字に戻り、何も言わない。箱（ダイアログ）では Cancel で、開いてから押した設定も戻る。`[Mac]`
- `key.4` ドラッグの途中の Escape：物も値も元へ戻り、取り消しに残らない。`[大半]`
- `key.5` Escape は一番上の浮いている物（メニュー・一覧・箱）を閉じる。外を押しても閉じる（どのボタンでも。その押しは下の物にも届く）。`[Mac]`
- `key.6` Return・Space：キーが乗っているボタンを押す。数の上の Return は打ち込みを開く。`[大半]`
- `key.7` 浮いている物が開いている間、アプリのキーは後ろのプロジェクトに届かない。`[大半]`

## 8. Delete

- `del.1` Delete・Backspace：選んだ物を消す。消せる物ならどこでも（レイヤー、マーカー、エフェクトのカード、デッキ、自分の色、取っておいたイージング）。取り消し 1 回で戻る。`[他：Ableton Live]`
- `del.2` ディスクの上のファイルは、聞いてからゴミ箱へ入れる。`[Mac]`
- `del.3` キーが乗っている数：既定の値に戻る（二度押し・メニューの Reset と同じ）。打ち込み中は文字を消す。`[大半]`

## 9. Tab・矢印・文字のキー

- `tab.1` Tab：今の欄を言って、次の欄を打ち込める状態で開く。Shift＋Tab は前へ。`[AE]`
- `tab.2` Tab はボタン・チップ・切り替えにも届き、届いた印が描かれる。`[大半]`
- `arrow.1` 数（キーが乗っている時も、打ち込み中も）：上・右で増え、下・左で減る。1 歩は見えている桁から（整数は 1）。Shift と Cmd は `mod.1`。`[AE]`
- `arrow.2` 物と時間：1 つ分（1 フレーム、1 行、隣のタイル）。Shift で `Gestures.nudgeShift`。`[AE]`
- `arrow.3` 選択肢・一覧・メニュー：矢印は印を動かすだけ（端で止まる）。Return・Space で決める。Home・End で端へ。`[他：W3C ARIA]`
- `arrow.4` スライダー：1 歩はトラックの 1 px 分。Shift と Cmd は `mod.1`。Page は幅の 10 分の 1、Home・End は端。`[大半]`
- `keys.1` 文字 1 つの命令（道具の V・M・R …）は、文字を打っている時のほか、アプリがキーを持つどこでも働く。メニューに出る字はキーの割り当て（`keybindings.json`）に従う。`[AE]` `[他：VS Code]`
- `keys.2` キーが乗っている数の上で数字・`.`・`-` を打つと、その字から打ち込みが始まる。`[大半]`

## 10. Shift・Cmd・Option

- `mod.1` 値（こすり・ホイール・滑り・矢印。数でもスライダーでも）：Shift は 10 倍、Cmd は 10 分の 1。その都度読むので、途中で押しても離してもよい。`[AE]`
- `mod.2` 選ぶ：Shift＋押しは、行なら最後に選んだ所からここまで、プレビューのレイヤー・バー・キーフレームなら足す（選ばれていれば外す）。Cmd＋押しは 1 つ足すか外す。囲みも同じく足す。`[AE]` `[Mac]`
- `mod.3` 物・取っ手のドラッグ：Shift は縛る（縦横の比、片方の軸、15 度刻み）。Option は中心から大きさを変える。`[他：Illustrator・Figma]`
- `mod.4` ドラッグ中の Cmd：止まり所への吸い付きを切る。`[他：Ableton Live]`
- `mod.5` Cmd と書いた所は、どこでも Cmd か Ctrl（`Gestures.cmd`）。`[大半]`
- `mod.6` Option：畳みの頭では兄弟の全部（`fold.2`）。数のこすりでは見せている範囲の端を越える（`drag.9`）。`[Mac]` `[他：Houdini]`

## 11. 外枠

パネルの内側の部品ではなく、枠（カード・行・タイル・タブ）にする事。

**畳む**

- `fold.1` 頭を押すと畳む。頭がほかに何もしないなら頭の全部が押せる。行を押すと選ぶ・移る所では、印だけが畳む。`[大半]`
- `fold.2` Option＋押し：兄弟を全部、同じ状態にする。`[Mac]`
- `fold.3` 畳みの印は、どのスキンでも `Gestures.change` で回る。畳んでいた行はすぐ出る。`[DESIGN]`
- `fold.4` 畳みはアプリの見え方の状態で、覚えている。プロジェクトには書かず、取り消しにも入らない。`[大半]`

**並べ替える**

- `reorder.1` 並びの中の物は、その頭か行をつかんで運ぶ（`Gestures.dragSlop` から）。動かさずに離せば、そこの押しのまま。`[AE]`
- `reorder.2` つかむ印（≡）は印として残してよい。つかめる所をそこだけにしない。`[AE]`
- `reorder.3` 運ぶ間は浮いた写しが手に付き、入る所に 2 px のアクセントの線が出る。離すと取り消し 1 回。Escape か、受けない所で離せば元へ戻る。`[Alight]`

**消す**

- `remove.1` 印：ほかの印もある頭ではゴミ箱。頭の無いタイルやカードでは、右上の外（-4, -3）に丸い ×。`[他：AbsentMotion・Cavalry]`
- `remove.2` 印が無くても、選んで Delete（`del.1`）か、メニューの Delete（`right.2`）で消える。`[大半]`
- `remove.3` 消す時は聞かない。取り消し 1 回で戻る。ディスクのファイルだけ、聞いてからゴミ箱（`del.2`）。`[Mac]`

**隠す**

- `hide.1` 目を 1 回押すと隠れ、もう 1 回で戻る。値は残る。目の印が入れ替わり、隠れた物は薄く描かれる。プロジェクトの物なら取り消し 1 回。`[Alight]`
- `hide.2` 隠す・消す・複製は、選んだ物が幾つあっても全部に働く。`[大半]`

**名前を変える**

- `rename.1` 名前の二度押し、メニューの Rename…、選んで Cmd+R：その場で書く。全部選ばれている。タイルは二度押しが「使う」なので、メニューから。`[Mac]` `[他：Ableton Live]`
- `rename.2` Return か離れると言う。Escape は元のまま。空の名前・同じ名前は何もしない。取れない名前は理由を言って断る。`[Mac]`

**メニュー**

- `menu.1` 浮くメニューは 1 つ：幅 `Gestures.menuWidth`、行 `Gestures.menuRow`、高さはアプリの半分まで。ボタンが下りた時、ポインターの所（ボタンからなら下、入らなければ上）に開く。`[他：Ableton Live]`
- `menu.2` 行を押すと、先に閉じてから 1 回働く。プロジェクトを変える行は取り消し 1 回。今できない行は理由を見せ、光らず、何もしない。`[大半]`
- `menu.3` 消す行の言葉はどこでも Delete（Remove でも「Delete this palette」でもない）。`[他：Ableton Live]`
- `menu.4` Escape か外の押しで閉じる（`key.5`）。矢印と Return で選べる（`arrow.3`）。`[Mac]`
- `menu.5` ⋮ や ⋯ のボタンは、右押しと同じメニューを開く。物にする事は、その物のメニューにある。`[他：Ableton Live]`

---

## 12. 数

`Gestures`（`app/lib/widgets/gestures.dart`）に書く数。部品もパネルも、ここの名前で読み、自分の数を書かない。

| `Gestures` の名前 | 値 | 出所 |
|---|---|---|
| `dragSlop` | 4 px（画面の上で） | `[大半]` 数のこすりと囲みが既にこの数 |
| `doubleTap` | 300 ms | `[他：Flutter]` `kDoubleTapTimeout` |
| `doubleTapSlop` | 100 px | `[他：Flutter]` `kDoubleTapSlop` |
| `longPress` | 500 ms | `[他：Flutter]` `kLongPressTimeout` |
| `grab` | 8 px（点・キーフレーム・取っ手・端のまわり） | `[大半]` プレビューの取っ手とキーフレームがこの数 |
| `snap` | 8 px | `[Alight]` 8 ポイント以内の一番近い所に止まる |
| `coarse` | 10 倍（値の上の Shift） | `[AE]` Shift はこすりを 10 倍にする（community.adobe.com/t5/after-effects-discussions/shortcut-for-scale-dragging/m-p/9417731） |
| `fine` | 10 分の 1（値の上の Cmd・Ctrl） | `[AE]` 同じ所：Command・Control は 10 で割る |
| `nudgeShift` | 10（物・時間の Shift＋矢印） | `[AE]` Shift＋矢印は 10 動かす |
| `hover` | 0 ms | `[大半]` |
| `change` | 120 ms（`Mo.dur`） | `[DESIGN]` 1 つだけの動き |
| `menuWidth` | 220 px | `[大半]` |
| `menuRow` | 22 px | `[大半]` |
| `menuMaxHeight` | アプリの高さの半分 | `[大半]` |
| `burstRest` | 300 ms | `[AE]` Unified Camera tool のホイール：止まってから 1 回 |
| `cmd`・`valueFactor` | 読み方（Cmd か Ctrl か／値に掛ける倍率） | `mod.5`・`mod.1` |

## 13. 立っている例外

使う人の側の理由がある物だけ。理由は調べの引用のまま。ここに無い違いは、規格に直す物。

| 部品 | 規格と違う所 | 理由 | 場所（`app/lib/`） |
|---|---|---|---|
| 上のバーの Undo・Redo | 押すと、何を戻したかを知らせに書く | "as After Effects' and Premiere Pro's Edit menu names the step" | `workspace/top_bar/top_bar.dart` |
| Ease の Overshoot チップ | 曲線が 0〜1 の外にあると自分でオンになり、オフにすると取っ手が中へ戻る | "the maker, 10/31: a number written turned it on unseen, and the curve went out of reach" | `workspace/tool_panel/tool_panel_ease_numbers.dart` |
| プレビューの Show（スナップショット） | 切り替えではなく、押している間だけ見せる | "After Effects' Show Snapshot: seen while it is held; let go, the picture as it is now" | `workspace/stage/stage.dart` |
| 選択肢が 5 つ以上の Chooser | 1 回目で一覧が開き、2 回目で決まる | "A short list lives in a segmented control; a long one opens a searchable list" | `inspector/inspector_choosers_header.dart` |
| メニューバー | アプリのメニューではなく、OS のメニュー | "every command in the menu bar, where the Help menu's search finds it by its name, Apple's HIG" | `workspace/commands/menu_bar.dart` |
| Ease の形の列（Linear・In・Out …） | タイルだが 1 回押すだけで付く。手が乗ると 2 px 持ち上がる | "the maker, 10/31: the shapes, one row, one press each" | `workspace/tool_panel/tool_panel_ease_side.dart` |
| Ease の棚のタイル | 1 回押すと、区間の全部がそれに替わる | "A press puts a tile on the stretch whole, in place of all that is there, so one after another can be tried" | `workspace/tool_panel/tool_panel_ease_shelf.dart` |
| Inspector の数の角の点 | 押すと打ち込みでもこすりでもなく、そのフレームのキーフレームを打つ・外す | "Alight Motion's diamond beside each value, After Effects' and Premiere Pro's stopwatch" | `inspector/controls/inspector_number_field_num_field_state.dart` |
| 道具の列の色の箱（fill・stroke） | 押しても色は付かず、Colors の棚をそのインクに向ける | "Illustrator's Fill and Stroke boxes: the one chosen is edited" | `workspace/stage/stage.dart` |
| Camera View のタブ | 押しもドラッグも受けない | "Nothing to hold here: a look, the hand is on the stage." | `workspace/stage/stage_camera.dart` |
| Relations マップの軸のギズモ | 押すと選ぶのではなく、その軸から見た向きになる | "an axis of the gizmo: seen from that side, as Blender's" | `workspace/tool_panel/tool_panel_relations.dart` |
| Rectangle・Ellipse・Text の道具 | 押すだけで 1 つ作り、道具が Select に戻る | "Alight Motion's Add is one act and Figma's tool goes back to select" | `workspace/stage/stage_view_state.dart` |
| ルーラーのマーカーの旗 | 押すと選ぶだけでなく、再生ヘッドがそこへ行き、再生が止まる | "Live's locators (a click picks and goes to one)" | `workspace/timeline/timeline_asked.dart` |
| Relations マップ | ドラッグで表示が動くのでなく回る。2 本指でも回る | "a trackpad's two fingers turn the view, as Blender's do" | `workspace/tool_panel/tool_panel_relations.dart` |
| Camera の道具（ドラッグ） | カメラが回る（1 px に 0.25 度）。自由な視点では表示だけが動く | "After Effects' Unified Camera tool: a drag turns the camera round where it looks" | `workspace/stage/stage_view_state.dart` |
| 作業範囲の帯の端 | 0.5 秒より短くできない（バーは 1 フレームまで） | "never shut to nothing: half a second at least, so the document cannot be dragged out of sight" | `workspace/timeline/timeline_ruler.dart` |
| 角度のダイヤル | 横にこするのでなく、ポインターの角度で回る | "one turn of the pointer is one turn of the value"、After Effects の角度 | `inspector/controls/inspector_param_controls_angle_dial.dart` |
| 点・大きさのパッド | 点は下が増え、大きさは上が増える | "Y follows the canvas (down is more) for a point, and up is more for a height" | `inspector/controls/inspector_param_controls_tile.dart` |
| カメラのギズモの回す印 | Camera の道具と逆の向きに、円の大きさで決まる速さで回る | "it goes the way the hand does; a turn as far as the hand has gone on the circle it goes round" | `workspace/stage/stage_view_camera.dart` |
| Camera の道具（ホイール） | 表示が動くのでなく、カメラが寄る・引く | "After Effects' Unified Camera tool's wheel: the camera nearer or further from where it looks" | `workspace/stage/stage_view_camera.dart` |
| Colors の色の箱（ホバー） | 手が乗ると、同じパレットの箱の全部に虹の縁が付く | "the user, a rim, not the others darkened" | `workspace/dock/dock_make_colors.dart` |
| デッキの名前の欄（Save Favorites…） | 名前を言うと Favorites が空になり、戻せない | "as Lightroom's Clear Quick Collection After Saving" | `workspace/dock/dock_effect_places.dart` |
| 数のメニュー | 同じ数をもう一度右押しすると、閉じずにその所で開き直す | "right pressed here again: its place, as a Mac's" | `widgets/float_shut.dart` |
| 区間を選んでの Delete | 区間は消えず、イージングが Linear に戻る | "a stretch picked: its way off, straight again, not the thing" | `workspace/commands/menu_bar.dart` |
| Program のコードの欄 | 閉じかっこを足さない。取り消しは欄の物で、プロジェクトの物ではない | "exactly what is typed" | `workspace/dock/dock_program.dart` |
| カードのエフェクトのコード | 最初に打った時に棚のファイルを写し、写しの方に書く | "the shelf's file is never written over" | `workspace/shelf/fx_code.dart` |
| ルーラーのこすり | 吸い付きは普段は切れていて、Shift で入る（バーとキーフレームは逆） | "After Effects': Shift held while the time indicator is dragged, it rests on what it passes" | `workspace/timeline/timeline.dart` |
