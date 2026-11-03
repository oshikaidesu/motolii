# ギズモの場面（11/3）

ユーザー：「uxに直接関わるのがギズモやと思う、それぞれのシナリオ考えてみて」。

ステージの取っ手ひとつずつに、「ネットで見た表現を自分の動画で作る時に、何をしたくてそれを触るか」を当てた。お手本の手と比べて、印を付けた（同じ・今回・無い・割れる）。決め方は `mouse_map.md` と同じで、売れているアプリの公式の説明の重なり、割れたら Alight Motion。Alight Motion に無い（指 1 本の画面なので修飾キーが無い）所は、ほかのお手本から取る。

## 出典

全文を読んだもの：
- Alight Motion：AbsentMotion の `ui/editor/Preview.kt`（角 4 つは縦横比を保って真ん中から、辺の真ん中 4 つは片方だけ、文字は幅の取っ手、塗りのグラデーションは 2 点）、`ui/editor/effects/EffectBrowser.kt`（切り抜きは効果）
- Keynote：Resize, rotate, and flip objects（https://support.apple.com/guide/keynote/tanc0606ae81/mac）：角を斜めに引く → 縦横比を保つ、上下左右の辺 → 自由（Constrain proportions が切れている時だけ）。⇧ の刻みは書いていない
- Figma：Crop an image（https://help.figma.com/hc/en-us/articles/360040675194）：画像をダブルクリック → 切り抜き、どこかを押すか Enter → 終わり

検索の抜粋（ページは開けていない）：
- Photoshop：Scale layers / Transform（helpx、403 で開けず）：21.0 から角は縦横比を保つのが既定、⇧ で切り替え
- Figma：Adjust alignment, rotation, position, and dimensions：⇧ で回転は 15° 刻み、⇧ で縦横比を保つ
- Illustrator：Scale objects（helpx）：⇧ で縦横比、⌥ で真ん中から、辺の真ん中の取っ手
- Keynote：Edit an image：画像をダブルクリック → マスク（切り抜き）
- After Effects：公式は見つからず（aejuice、Creative COW）：⇧ + 角で縦横比、大きさはアンカーポイントの周り

## 場面

| 取っ手 | 場面 | 手 | お手本 | Motolii | 印 |
|---|---|---|---|---|---|
| 本体 | テロップを画面の下 3 分の 1 に置く | ドラッグ、真ん中や端にくっつく | 全部 | 同じ（6 px でくっつく） | 同じ |
| 本体 | 横から滑り込む文字の止まる所を、高さを変えずに決める | ⇧ ドラッグ → 横か縦だけ | Illustrator・Figma | 今回 | 今回 |
| 本体 | 同じ星をもう 1 つ横に並べる | ⌥ ドラッグ → 複製して動かす | Illustrator・Figma・Ableton | なし | 無い |
| 本体 | 動きの途中の位置をステージで直す | 道筋の上のキーをドラッグ | After Effects | 道筋は見える（Alight Motion の motion path）。触れない | 無い |
| 角 | 写真を画面いっぱいに、歪ませずに | 角を引く → 縦横比を保つ | Alight Motion・Keynote・Photoshop（Figma の画像も） | 今回（前は歪んだ） | 今回 |
| 角 | 文字をわざと横に潰す | ⇧ + 角 → 自由 | Photoshop | 今回 | 今回 |
| 角 | ロゴを真ん中からポンと大きく | ⌥ + 角 → 中心から | Illustrator・After Effects | 同じ | 同じ |
| 辺の真ん中 | テロップの下の帯の幅だけ伸ばす | 辺を引く → その向きだけ | 全部 | 今回（前は角だけ） | 今回 |
| 回転のつまみ | テロップを少し斜めに | つまみを回す | Figma・Illustrator（角の外）、Alight Motion（2 本指・ダイヤル） | 上のつまみ | 同じ |
| 回転のつまみ | ちょうど 45° に | ⇧ で刻む | Figma・Photoshop 15°、Illustrator 45°、Alight Motion・Keynote は無し | なし（数字を打つ） | 割れる |
| 中心 | 時計の針を根元で回す | 中心をドラッグ | Illustrator・Figma・After Effects | 同じ | 同じ |
| 角丸・頂点の数 | 星の角を丸く、とげを増やす | 印をドラッグ | Alight Motion | 同じ | 同じ |
| 切り抜き | 写真の余白を切る | ダブルクリック → 辺の棒を引く → どこかを押して終わる | Figma・Keynote（Alight Motion は効果のカードを開いている間） | 今回（前は選ぶといつも棒が辺に出て、辺の大きさの取っ手の場所と重なった） | 今回 |
| 文字の箱 | 長い字幕を決まった幅で折り返す | 幅の取っ手を引く | Alight Motion・Illustrator・Figma | なし | 無い |
| 塗りのグラデーション | 光の当たる向きを変える | 2 点をステージで引く | Alight Motion・Figma | 数字だけ（角度・大きさ） | 無い |
| パスの点 | ロゴの線を直す | 点・取っ手をドラッグ | 全部 | 同じ（足りない所は `mouse_map.md` の 4） | 同じ |
| カメラ | 被写体の周りを回る、寄る | 枠・注視点・ドラッグ・ホイール | After Effects・AbsentMotion | 同じ | 同じ |
| 3D の物 | 物を奥へ 1 方向だけ動かす | 矢印で 1 軸、輪で回す | Blender・After Effects | なし（深さのパネルの板） | 無い |

## 今回入れた手（試験：`test/workspace_joined_test_3.dart`、`test/sweep_test.dart`）

- 辺の真ん中に 4 つの取っ手。引いた向きだけ大きくなり、向かいの辺は動かない。斜めに引いても、その辺の向きの分だけ効く
- 角は縦横比を保つ（中身の `even_side`・`even_scale`、`engine/doc_paths.h`）。⇧ で自由、⌥ で中心から
- 写真の切り抜きの棒は、選んだ写真をダブルクリックした時だけ。どこかを 1 回押すと終わる
- ⇧ を押して本体をドラッグすると、横か縦（手が多く動いた方）だけ
- 窓では、選んだ物の枠・角・回転のつまみ・中心を中身が描いている（`engine/live.h` の desk_marks）。窓が描く印はその間は描かれず、角丸・頂点の数・切り抜きの印は、試験では出ても窓では出ていなかった。辺の四角は中身に足し、角丸・頂点の数・切り抜きは窓が上に描く

## 残り

- ⇧ の回転の刻み：15° と 45° に割れていて、Alight Motion と Keynote には無い。入れない
- ⌥ ドラッグで複製、道筋の上のキー、文字の箱の幅、グラデーションの 2 点、3D の矢印：お手本はそろっている。まだ
