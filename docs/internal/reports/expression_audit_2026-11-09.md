# Expression の棚の総当たり（四角）2026-11-09

profile build、四角 1 つに 1 本ずつ付けて、0 秒目・0.3 秒・1 秒を見て、⌘Z で外した。

## 合格
Bounce In / Fade In / Print On / Random Fade In / Slide In / Spring In / Lyric / Wave rows / Repeater（見た目）/ Poster（見た目）

## 文句

| # | ユーザーに見えること | 当たった表現 |
|---|---|---|
| A | 付けて ⌘Z を 1 回押してもカードが残る。2〜4 回押さないと外れない。1 回目は "How many" が 1 に戻るだけ（Maze で 1000 → 1） | AE Grid・AE Ring・Maze・Sunflower・Wave rows は 2 回、Repeater は 4 回 |
| B | 複製が置いた物の大きさを見ず、重なって 1 つの塊になる（格子・輪・迷路・ひまわりに見えない） | AE Grid（大きな四角 1 枚）、AE Ring（ギザギザのドーナツ）、AE Stagger（横長の棒）、Maze（菱形の市松）、Sunflower（ステージを覆う円・赤ポチ 12 → 122） |
| C | 動き系のカードに "How many 1" が出る。複製の無い動きでは意味が無く、Grid/Ring/Stagger では複製があるのに 1 と出て嘘になる | Fade In ほか動き系すべて、AE Grid・AE Ring・AE Stagger |
| D | 「消える」系を付けても最初の 1 秒は何も変わらない。Print Off だけは最初の 0.67 秒で消え、そのあと 8 秒の最後まで消えたまま。起きる場所が表現ごとにばらばら | Fade Out・Fall Out・Random Fade Out ／ Print Off |
| E | 棚のダブルクリックがたまに効かない（約 22 回で 2 回）。気づかず ⌘Z を押すと、前の操作が取り消される | 表現を問わない |
| F | Poster を付けると、四角から画面の外へ黄色の線が 2 本伸びる | Poster |

前から残っている文句：Lyric の 0 秒目が空、文字を置くと Arial Unicode.ttf が Project に勝手に入る、新しい書類のダイアログが毎回真ん中に出る、文字の色の初期値が灰色 #7F7F7F。

## 出す順
1. A（一操作 = ⌘Z 一回）出典：Apple `UndoManager.groupsByEvent`、AE の "Undo Apply Preset"
2. B + C（複製は置いた物の大きさに合わせる、"How many" は複製のある表現だけに出す）
3. D（「消える」系は付けた直後に見える場所で起こす。AE のプリセットは現在時刻を起点にキーを置く）
4. E・F は 1〜3 の確認のついでに再現手順を固める

文字に付ける回はまだやっていない。
