# ギズモの場面（11/3）

ユーザー：「uxに直接関わるのがギズモやと思う、それぞれのシナリオ考えてみて」。

ステージの取っ手ひとつずつに、「ネットで見た表現を自分の動画で作る時に、何をしたくてそれを触るか」を当てた。お手本の手と比べて、印を付けた（同じ・今回・無い）。

決め方：ギズモは Figma に合わせる（11/3 ユーザー：「絶対フィグマに合わせた方がいい。フィグマの方がモダンだろ、どう考えても。」）。最初は `mouse_map.md` と同じ決め方（売れているアプリの公式の説明の重なり、割れたら Alight Motion）で角を「初めから縦横比を保つ」にしたが、Figma に合わせて「初めは自由、⇧ で保つ」に直した。Figma に書いていない所は、ほかのお手本から取る。

## 出典

全文を読んだもの：
- Figma：Adjust alignment, rotation, position, and dimensions（https://help.figma.com/hc/en-us/articles/360039956914）：角を引く → 幅と高さ、辺 → その向き。縦横比が外れている時、⇧ を押している間だけ縦横比を保つ。回すのは取っ手の「すぐ外」（"Hover just outside one of the layer's bounds"）、⇧ で 15° 刻み（"snap rotation values to increments of 15"）
- Figma：Crop an image（https://help.figma.com/hc/en-us/articles/360040675194）：画像をダブルクリック → 切り抜き、どこかを押すか Enter → 終わり
- tldraw：`packages/tldraw/src/lib/overlays/SelectionForegroundOverlayUtil.ts`（回転の角の所）：角の外に 1 辺 2 × 1.62 × 4.5 px（約 14.6 px）の四角。Figma は広さを書いていないので、ここから取った
- Alight Motion：AbsentMotion の `ui/editor/Preview.kt`（角 4 つは縦横比を保って真ん中から、辺の真ん中 4 つは片方だけ、文字は幅の取っ手、塗りのグラデーションは 2 点）、`ui/editor/effects/EffectBrowser.kt`（切り抜きは効果）
- Keynote：Resize, rotate, and flip objects（https://support.apple.com/guide/keynote/tanc0606ae81/mac）：角を斜めに引く → 縦横比を保つ、上下左右の辺 → 自由

検索の抜粋（ページは開けていない）：
- Figma：⌥ + 角 → 真ん中から（uxplanet の Figma tips、Figma フォーラム。公式のヘルプでは見つからず）
- Illustrator：Scale objects（helpx）：⇧ で縦横比、⌥ で真ん中から、辺の真ん中の取っ手
- Photoshop：Scale layers / Transform（helpx、403 で開けず）：21.0 から角は縦横比を保つのが既定、⇧ で切り替え
- Keynote：Edit an image：画像をダブルクリック → マスク（切り抜き）
- After Effects：公式は見つからず（aejuice、Creative COW）：⇧ + 角で縦横比、大きさはアンカーポイントの周り

## 場面

| 取っ手 | 場面 | 手 | お手本 | Motolii | 印 |
|---|---|---|---|---|---|
| 本体 | テロップを画面の下 3 分の 1 に置く | ドラッグ、真ん中や端にくっつく | 全部 | 同じ（6 px でくっつく） | 同じ |
| 本体 | 横から滑り込む文字の止まる所を、高さを変えずに決める | ⇧ ドラッグ → 横か縦だけ | Figma・Illustrator | 今回 | 今回 |
| 本体 | 同じ星をもう 1 つ横に並べる | ⌥ ドラッグ → 複製して動かす | Figma・Illustrator・Ableton | なし | 無い |
| 本体 | 動きの途中の位置をステージで直す | 道筋の上のキーをドラッグ | After Effects | 道筋は見える（Alight Motion の motion path）。触れない | 無い |
| 角 | 文字をわざと横に潰す | 角を引く → 自由 | Figma・Illustrator | 今回（初めに入れた時は保っていた） | 今回 |
| 角 | 写真を画面いっぱいに、歪ませずに | ⇧ + 角 → 縦横比を保つ | Figma・Illustrator（Alight Motion・Keynote・Photoshop は初めから保つ） | 今回 | 今回 |
| 角 | ロゴを真ん中からポンと大きく | ⌥ + 角 → 中心から | Figma・Illustrator・After Effects | 同じ | 同じ |
| 辺の真ん中 | テロップの下の帯の幅だけ伸ばす | 辺を引く → その向きだけ | 全部 | 今回（前は角だけ） | 今回 |
| 辺の真ん中 | 写真を横に広げて、縦も合わせる | ⇧ + 辺 → もう片方も同じだけ、真ん中そろえ | Figma | 今回 | 今回 |
| 角の少し外 | テロップを少し斜めに | 角のすぐ外をドラッグ | Figma・Illustrator | 今回（回す形のカーソルは出ない。上の回転のつまみも残す） | 今回 |
| 回転 | ちょうど 45° に | ⇧ で 15° 刻み | Figma | 今回 | 今回 |
| 中心 | 時計の針を根元で回す | 中心をドラッグ | Figma・Illustrator・After Effects | 同じ | 同じ |
| 角丸・頂点の数 | 星の角を丸く、とげを増やす | 印をドラッグ | Alight Motion | 同じ | 同じ |
| 切り抜き | 写真の余白を切る | ダブルクリック → 辺の棒を引く → どこかを押すか Enter で終わる | Figma・Keynote（Alight Motion は効果のカードを開いている間） | 今回（前は選ぶといつも棒が辺に出て、辺の大きさの取っ手の場所と重なった） | 今回 |
| 文字の箱 | 長い字幕を決まった幅で折り返す | 幅の取っ手を引く | Figma・Alight Motion・Illustrator | なし | 無い |
| 塗りのグラデーション | 光の当たる向きを変える | 2 点をステージで引く | Figma・Alight Motion | 数字だけ（角度・大きさ） | 無い |
| パスの点 | ロゴの線を直す | 点・取っ手をドラッグ | 全部 | 同じ（足りない所は `mouse_map.md` の 4） | 同じ |
| カメラ | 被写体の周りを回る、寄る | 枠・注視点・ドラッグ・ホイール | After Effects・AbsentMotion | 同じ | 同じ |
| 3D の物 | 物を奥へ 1 方向だけ動かす | 矢印で 1 軸、輪で回す | Blender・After Effects | なし（深さのパネルの板） | 無い |

## 今回入れた手（試験：`test/workspace_joined_test_3.dart`、`test/sweep_test.dart`）

- 辺の真ん中に 4 つの取っ手。引いた向きだけ大きくなり、向かいの辺は動かない。斜めに引いても、その辺の向きの分だけ効く
- 角は初めは自由（向かいの角は動かない）。⇧ で縦横比を保つ（中身の `even_side`・`even_scale`、`engine/document/doc_paths.h`）、⌥ で中心から。辺の真ん中に ⇧ だと、もう片方も同じだけ、真ん中そろえ
- 角のすぐ外（約 14.6 px の四角）をドラッグすると回る。⇧ で 15° 刻み（中身の `even_turn`）
- 写真の切り抜きの棒は、選んだ写真をダブルクリックした時だけ。どこかを 1 回押すか Enter で終わる（文字を打っている間の Enter は文字のもの）
- ⇧ を押して本体をドラッグすると、横か縦（手が多く動いた方）だけ
- 窓では、選んだ物の枠・角・回転のつまみ・中心を中身が描いている（`engine/stage/live.h` の desk_marks）。窓が描く印はその間は描かれず、角丸・頂点の数・切り抜きの印は、試験では出ても窓では出ていなかった。辺の四角は中身に足し、角丸・頂点の数・切り抜きは窓が上に描く

## 残り

- 回す形のカーソル：Flutter の決まったカーソルに無い。絵のカーソルを出す方法を探すまで、上の回転のつまみが目印
- ⌥ ドラッグで複製、道筋の上のキー、文字の箱の幅、グラデーションの 2 点、3D の矢印：お手本はそろっている。まだ
