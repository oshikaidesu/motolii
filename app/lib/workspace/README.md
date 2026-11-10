# Workspace — Motolii のアプリの画面

*The app's own code: `Workspace` (opened by `app/lib/main.dart`) and its panes. The project lives in the C++ engine, reached through `../bridge/motolii.dart`; this folder shows it and hands every edit back. Start here to add a panel of your own.*

`app/lib/main.dart` が開く `Workspace`（`workspace.dart`）がアプリの画面。プロジェクトは C++ のエンジン（`../bridge/motolii.dart` の `Motolii`、各メソッドが `motolii_*` の C 呼び出し 1 つ）にあり、Stage の絵もエンジン（Filament）が描く。アプリは見せて、ポインタの操作をプロジェクトに渡すだけ。プロジェクトを渡さずに開くと無題のプロジェクトを開く（AE と同じ）。

| 場所 | 中身 |
|---|---|
| `workspace.dart` | 画面の全体（`Workspace`）：上のバー、パネルの並び、プロジェクトを開く |
| `state/` | どのパネルも読むアプリの状態。`workspace_state.dart` に `WorkspaceController`、`effects.dart` に掛かった効果（`WorkspaceEffects`）、`workspace_scope.dart` に `WorkspaceScope`、`workspace_aspect.dart` 聞く面 `WorkspaceAspect`、`layer.dart` レイヤー `Layer` と種類の色 `wsTone`、`pane.dart` タブ `Pane`、`art_scene.dart` Stage の絵の寸法と箱（`ArtGeometry`・`ArtScene`）、`beats.dart` テンポの格子、`window_zoom.dart` 画面全体の拡大率 `WindowZoom` |
| `easing/` | イージングそのもの：`ease.dart` `Ease` とプリセット、`ease_text.dart` 文書に書く文字の形、`ease_curve.dart` 重ねたカードの曲線と式 |
| `window/` | ウィンドウの枠：`panes.dart` パネルの並び（pub の `docking`）、`home.dart` プロジェクトを選ぶ最初の画面、`zoom.dart` 画面全体を拡大率で描く |
| `top_bar/` | 上のバー：`top_bar.dart`、`size_chip.dart` 画面の大きさ、`zoom_readout.dart` 拡大率の表示、`timings.dart` エンジンにかかった時間 |
| `commands/` | 名前の付いた操作と、それを言うキー・メニュー：`keymap.dart` キーの表（VS Code の keybindings.json の形）、`command_actions.dart` 各操作がアプリの状態にすること（キーは Ableton Live 12 の表から）、`panel_requests.dart` パネルがほかのパネルに頼む合図（タイムライン・名前の変更・書き出し・大きさ・検索）、`menu_bar.dart` メニューバー、`layer_menu.dart` 右クリックの項目（メニューの部品は `widgets/menu.dart`） |
| `edits/` | 選んだ複数のレイヤーにまとめて掛ける編集：`make_relation.dart` 関係を作る、`group_moves.dart` グループの動き、`keyframe_edits.dart` キーフレームの移動・削除・コピー |
| `inspector_feed/` | プロジェクトから Inspector（`../inspector/`）へ渡す物。`panel.dart` パネルとして読み直す時、`cards.dart` カード、`values.dart` 値の読み書き、`keyframe_marks.dart` 値の横のキーの印 |
| `dock/` | 左の棚（Create・Effects・Media・Fonts・Colors …）のパネル |
| `shelf/` | 棚のタイル（効果・スクリプト・素材） |
| `stage/` | プレビュー（Filament が描いた絵と、その上のドラッグ） |
| `timeline/` | タイムライン |
| `tool_panel/` | Inspector の下のツールパネル（Ease、Align、Blend …） |

## 自分のパネルを足す（入口はここだけ）
使う物の置き場：`Workspace`（`workspace.dart`）、`Pane`（`state/pane.dart`。アイコンは `AppGlyphs` か null）、`WorkspaceController`・`WorkspaceScope`（`state/workspace_state.dart`・`state/workspace_scope.dart`）、`Motolii`（`../bridge/motolii.dart`）、Ease のタイル `easingsWithoutTile`（`tool_panel/tool_panel_ease.dart`）。
```dart
Workspace(document: path, extra: [
  Pane('Notes', null, () => const MyNotes()),   // (名前、アイコン（null なら頭文字）、中身)
])
```
- 足したパネルは Inspector の横にタブで並ぶ。本家のファイルは 1 行も変えない。
- パネルの中では `WorkspaceScope.of(context)` がアプリの状態（`WorkspaceController`。何かが変わるたびに組み立て直る。聞く面を言えば、その面が変わった時だけ：`WorkspaceScope.of(context, {WorkspaceAspect.picked})`。再生ヘッドは `WorkspaceScope.frameOf(context)`）：`inside` がプロジェクト（`Motolii`）、`selected` が選ばれたレイヤー、`frame` が今のコマ。値は `inside.value(thing, name, seconds)`、変えるのは `inside.set(...)`、キーは `inside.keyHere(...)`。
- レイヤーをプレビューの上で動かす（画素で）：`inside.take(t)`、`inside.dragUpdate('place', 10, 0)`、`inside.later('drag_end', number: 1)`（ドラッグしたのと同じ undo 1 回）。値をそのまま変えるのは `inside.set(t, name, value)`（プロジェクトの単位）。キーの数は `inside.keyTimes(t, name).length`。
- 気をつける 4 つ：選ばれたレイヤー `selected` は文字なので `int.parse` してからエンジンに渡す。今の秒は `frame / WorkspaceController.fps`。レイヤーの名前は `inside.word(t, 'name')`。プロジェクトを変えたら `ws.reread()`（アプリの他のパネルが読み直す）。

## 自分のツールパネルの道具を足す
```dart
Workspace(document: path, extra: [
  Pane('Snap', null, MySnap.new, at: PaneStrip.catalog, tone: Color(0xFF55AA88), acts: 'Picked thing'),   // (名前、アイコン、中身、置き場所＝道具の棚、色、何に効くか)
])
```
- アプリの道具の後ろに並び、選ぶとツールパネルがその `build` を出す。アイコンは頭文字。中では パネルと同じく `WorkspaceScope.of(context)`。

## 自分のプリセット（Ease の動き方）を足す
プリセットは利用者の持ち物（スクリプトと同じ）。利用者のフォルダ（下の「利用者のフォルダ」）の `ease/` にファイルを 1 つ置くと、どのプロジェクトでも Ease のツールパネルにタイルで出る。Motolii が持って来る見本は `shelves/ease/`。式で使えるもの：`a`（前のキーの値）、`b`（次のキーの値）、`u`（区間の 0〜1）、`p1`〜`p4`（区間に付けた数）、`bezier(u, x1, y1, x2, y2)`。
```
// Snappy: fast away from the first key, a long soft landing          (1 行目：名前、コロンの後は説明)
a + (b - a) * bezier(u, .2, 0, 0, 1)                                 (a: 前のキーの値、b: 次のキーの値、u: 区間の 0〜1)
```
- キーに当てると、その式がプロジェクトに書き込まれる（プロジェクトを人に渡しても同じに動く）。当てるのと書き込むのは undo 1 回。
- 例：`shelves/ease/snappy.way`。

## 利用者のフォルダ（スクリプト・エフェクト・動き・プリセット）
Mac：`~/Library/Application Support/Motolii/`、Windows：`%APPDATA%\\Motolii\\`（`MOTOLII_OWN` で差し替え）。中のフォルダごとに、置いた瞬間に出る（本体の見本は `shelves/` の同じ名前のフォルダ。同じ名前なら利用者のが勝つ）。
- `create/*.js`：1 回で絵を作るスクリプト。Create 棚にタイルで出て、パラメーターはレイヤーの **Script** カードに出る。頭の書き方は `engine/community/quickjs/script.h` の先頭（AviUtl2 と同じ `// --track@名前:ラベル,最小,最大,初め,刻み`、`--check@`、`--select@`）、例は `shelves/create/`。
- `relations/*.js`：たくさんのレイヤーを一度に動かす関係。プレビューの上と関係タブにチップで出て、パラメーターは関係の **Script** カードに出る。頭の書き方はレシピと同じ。本体は `relate(things, t, k)` 1 つで、全員を受けて変える物だけ返す（返さない値はそのまま）。`things` の 1 個は `i`（元の順番）、`x`、`y`、`z`、`size`、`rotate`、`rotate_x`、`rotate_y`、`opacity`、`w`、`h`、`id`。`near` は Falloff の形に覆われている割合で、普通の関係はこの分だけ自動で弱まる。p5 の `noise`、`createVector`、`constrain` などと `ease` が使える。4 つ目の引数を取ると `relate(things, t, k, was)` になり、前のコマに返した物を `was[a.i]` で受ける（最初のコマは `null`。返した物の好きな値を覚えられる）。`was` の中身は書き換えない。戻って計算し直す時に使う。Strength が 0 の間は呼ばれず、0 を超えた最初のコマが `null` で始まる。この形は自分で `near` を読む。動かす関係は `force(things, t, k)` で書く。`things` の 1 個は 1 つの粒で、`x`、`y`、`z` は今いる場所、`vx`、`vy`、`vz` はコマごとの速さ、`home` は放っておいた時の場所。d3-force と同じく、速さに足すだけでよい。乗っている全部の力が同じ速さに足され、Strength と Falloff の分だけ効き、最後に 1 度だけ動く。だからルールが替わっても速さが続く。粒に書いた値は次のコマにもある（`a.n = ...`）。頭に `d3.` があれば `d3.forceCollide` などが使える。どの力も押していない粒は、下にある場所に戻る。例は `shelves/relations/`。ファイルを置くか書き換えると、再起動なしで効く。
- `effects/*.wgsl`：画面全体のエフェクト（Effects 棚）。`expressions/*.js`：物に付ける動き（Create の Expression）。
- `ease/*.way`：Ease のプリセット（上）。
- `skins/<名前>/`：アプリのスキン（`shelves/skins/README.md`）。
- 前の名前のフォルダ（`recipes/`・`animators/`・`ways/`）も、そのまま読む（`engine/document/scripts/folders.h`）。
- どれも本家のファイルは 1 行も変えない。カードの名前を自分で付ける（例：Wobble）のはまだできない（Script と出る）。

## 開き方・確かめ方
```bash
cd app
F=$(dirname "$(command -v flutter)")   # (Flutter 3.47.2 on PATH)
tool/live.sh                            # (アプリを開く。.dart を保存すると開いたアプリにすぐ出る)
$F/flutter analyze lib
```
- アプリの文字は英語。会話と文書は日本語。

## トンマナ(InspectorSkin)
- 値は `WindowTokens`(アプリ、`lib/skin/window_tokens.dart`)と `InspectorSkin`(Inspector、`lib/skin/inspector_tokens.dart`)と `Grey` / `TextStyles`(`lib/skin/tokens.dart`)から取る。**数値を直書きしない**。
- 箱(パネル・カード)は四角く、隙間なく並べる(間は `WindowTokens.gutter` の暗い線)。触る物と読む物(欄・チップ・ボタン)は丸い。
- 色は平らで不透明。アクセントはライム 1 色(`#B3C66B`、上の文字は `#15170D`)。再生ヘッドもアクセント。
- レイヤーの種類ごとに色を 1 つ(`wsTone`)。Timeline のバー、Dock、Stage で同じ色を使う。

## カラーテーマ(Dark / Light)
- 上のバーの半円ボタン(key `ws-shade`)で切り替える。`Grey.shade`(`ValueNotifier<Shade>`)を反転して `reassembleApplication()` でアプリ全体を建て直す。State は残るので編集中の内容は消えない。
- **Workspace と Inspector(`lib/inspector/`)では灰色を `Grey.g07` などで取る。`DarkGrey.g07` は使わない。** `DarkGrey` は古い研究ページ用の暗い段で、テーマに追従しない(そのページは Dark のみ)。
- `Grey` は `DarkGrey` と同じ名前の段を持つ。役割(地・パネル・カード・欄・線・控えめな文字・文字)は両テーマで同じで、明るさだけが逆になる。Light ではカードが一番明るく、文字が一番暗い。
- テーマで変わる色は `const` にできない。`static const` / トップレベルの `final` / 引数の既定値に `Grey` や `WindowTokens.body` などを置かず、getter か `Color?` + `?? Grey.xx` にする(`final` に入れると最初の色のまま固まる)。
- アクセントは塗りなら `WindowTokens.accent` / `InspectorSkin.accent`。**線や文字として地の上に描くときは `accentInk`**(Light ではライムが白に溶けるので濃いオリーブ)。再生ヘッドの線は `accentInk`、頭の札は `accent`。
- 種類の色(`tone*`)はテーマで変えない。
- `TextStyles.name()` などの文字色の既定は `Grey` から取る。暗すぎる・薄すぎる文字の補正(`T._floor`)もテーマごとに向きが逆。

## 決まっていること(利用者の裁定)
- **Media と Files は一つの棚(Media)。** AEViewer 2 型: 左(狭い時は上)に場所(Project / Home / Desktop / Downloads)とフォルダだけの木、右に開いているフォルダの中身をサムネイルかリストで。フォルダのタイルを押すとそのフォルダを開く。パンくずの各段も押せる。検索は今いる場所の中を全部探し、結果に入っているフォルダ名を添える。サムネイルの格子は捨てない。
- **アプリの画面はドックパネル。** Motolii 本体と同じ pub の `docking`(旧 Motolii の `ui/lib/workspace/dock_workspace.dart` を書き直したもの。この repo には無い)。ブラウザも棚ごとにペインに分けた(rail は無い)。**タブは記号で示す**: 棚のタブは記号だけ(中の見出しが名前を言う、5 枚並んでも細い)、Stage / Inspector / Timeline / Tool Panel は記号 + 名前(パネルの中の見出しに同じ名前を重ねない)。棚のタブを前に出すのは `WorkspaceController.front(name)`(`WorkspaceController.route` も同じ呼び出し)。別ウィンドウに出す Detach は native のウィンドウが要るので lab には無い。ペインは閉じられない(開き直す手段がまだ無い)。
- **初期配置**: 棚のタブの列・Inspector・Timeline・Tool Panel は基準の px で始め、Stage が残りを取る。`multi_split_view` は size を weight に直して足し合わせるので、残りを取るペインには weight を付けない。
- **ペインは広げたら得をする。** 列を固定して引き伸ばさない。
  - 格子は `wsCols(幅, セルの幅)` で列数を決め、`wsCell` でセルの幅を割り出す(Create のタイル、Colors の色見本、Tool Panel の道具)。
  - 一覧の区切り(Create の群、Colors の Used / Palettes / Gradients / Swatches、Effects の族)は `DockMasonry` のカードにする。1 列は 260〜300px 以上、最大 4 列、短い列から詰める。
  - Fonts は 440px 以上で見本の大きいカード、狭いと行。Media は 440px 以上で木が左、狭いと上。
  - Effects はフィルター帯を開いていて 560px 以上なら、帯を一覧の横に縦いっぱいで立てる。狭いと上の帯。
  - **Inspector は縦積みのまま**(カードを横に並べない)。カードの中身を、Effects のパラメーターと同じブロックの格子(`InspectorSkin.tileMin` ごとに列が増える)にする。
- **Inspector は一目でわかること。** フォント・色の一覧・イージングは、それぞれ専用のパネル(Browser › Fonts、Browser › Colors、Ease のツールパネル)が持つ。Inspector は今の値を見せて、そこへ誘導するだけ(`LinkLine` → `WorkspaceController.route`)。
- **Inspector の値は Stage と一致させる。** 位置・倍率・回転・塗りは `ArtGeometry.boxOf` と絵の色から渡す(`InspectorHost(values:, strs:)`)。
- **パスの操作は同じものを何度でも重ねられる**(パンク膨張の後にまたパンク膨張)。UI 側で数を絞らない。
- **シードなど普段触らない値も、隠さずに Advanced に置く**(宣言の `@advanced`、`ValuesCard` が畳む)。
- **テキストは普通に**: 入力欄、その下にサイズ・太さ・色。
- **Effects の一覧にサムネイルは付けない。** 見た目は Stage で確かめる: 行を選ぶ → 選択中のレイヤーに仮で掛かる → Add / Enter で確定、Cancel / Esc で取り消し。
- **効果のタグは 2 種類。** 振る舞い(Seat / Applies to / Time / Inputs / Parameters / Origin)は shader の静的解析が出す。何に見えるか(Look)だけを作者が `@tags(...)` で書く。試し表示だけで伝わらないこと(下の合成を読む、1 フレーム目に何も出ない、など)は、作者の `@preview(...)` か解析結果から帯に一言出す。
- **フィルター帯は Motolii 本体の草案に合わせる**: グループ同士は AND、グループ内は OR。クリックで 1 つ、Cmd/Ctrl-クリックで追加・解除。残る件数を札に出し、0 件になる札は押せない。件数と Clear は帯の一番下。**帯の高さは利用者が決める**(下端のグリップを上下にドラッグ、ダブルクリックで 168px に戻る)。

## 変えるときの作法
- パネルをまたぐ情報は `WorkspaceController` に足す。パネルどうしで import し合わない。Stage の絵の寸法と箱（`ArtGeometry`・`ArtScene`）も `state/art_scene.dart` にあり、どのパネルからも読める。
- コメントは、コードから読めない制約だけを書く(`contract:` で始まる行がそれ)。
- 区切りごとにコミットする(履歴が無いのが一番怖い、が利用者の方針)。

## まだ無いもの
- 見本とエンジンの二股（`inside == null`）が残っている。
