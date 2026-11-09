# Motolii の見た目：引き継ぎ（人と AI 向け）

*Hand-over for people and AI who carry on the app's look: the two layers that change it without touching projects, motion or pictures, and where each is written. To only make a skin, read `shelves/skins/README.md`.*

Motolii のアプリ（Flutter、`app`）の見た目は、エンジンの側（プロジェクト・動き・絵）に触らずに2段で変えられる。この文書は、続きを作る人や AI が、これだけ読めば手を動かせるように書いてある。スキンを作るだけなら [README.md](../../../shelves/skins/README.md) で足りる。

## 1. 2つの段

| 段 | 何が変わる | 書くもの | 配り方 |
|---|---|---|---|
| ① 値 | 色・明暗・角・余白・大きさ・文字の大きさ・書体 | `theme.xml`（名前と値を並べるだけ） | フォルダを置くだけ |
| ② フォーム | オン・オフと数値の絵 | Dart（`lib/skin/forms/own_forms.dart`） | アプリに組み込む |

①は [README.md](../../../shelves/skins/README.md)・[ROLES.md](../../../shelves/skins/ROLES.md) に全部ある。
②はヘッドレス UI（React Aria・Radix と同じ分け方）。ここから下は主に②の話。

## 2. ファイルの地図

場所は [`app/`](../../../app/) から見た所。

| 場所 | 中身 |
|---|---|
| `lib/skin/theme.dart` | theme.xml を読む・見張る（`ColorTheme`）。着ている革は `~/.motolii/window.xml` の `Skin` |
| `lib/skin/tokens.dart` | 色の段（`Grey`、Background/Foreground から HCT で作る）、`Shape.r/s/z`（角・余白・大きさ）、`T.px`（文字）。数の効く範囲もここ |
| `lib/workspace/window/settings_file.dart` | `~/.motolii/window.xml` の読み書き（倍率と着ている革） |
| `lib/skin/forms/forms.dart` | **フォームの約束**：渡す物（`SwitchSpec`）と、フォームが書く関数、登録表 `forms` |
| `lib/skin/forms/own_forms.dart` | いつもの見た目のフォーム |
| `lib/skin/forms/number_paint.dart` | 数値の絵 |
| `../shelves/skins/<名前>/` | リポジトリの見本の革（labs、paper、streets、poster、lighttable） |
| `tool/live.sh` | アプリを開いたまま、`lib/` の .dart を保存した瞬間に描き直す（状態は保つ） |

## 3. フォームの作り方（ヘッドレス UI）

### 分け方
- **アプリが渡す**：部品の言葉・今の値・押した時にすること（下の Spec）。
- **手で触った時の動き**：[naked_ui](https://pub.dev/packages/naked_ui)（BSD-3）。押す・手が乗る・選ぶ・切り替える・読み上げ。`NakedButton`、`NakedToggle`（`asSwitch: true` でスイッチ）、`NakedToggleGroup` と `NakedToggleOption`（どれか1つ）、ほかに `NakedSlider` `NakedTabs` `NakedSelect` `NakedMenu` など。builder に状態（`isHovered` `isPressed` `isSelected` `isFocused` `isDisabled`）が来る。
- **フォームが書く**：それをどう組み立てて見せるか、だけ。**動きを自分で作り直さない**（GestureDetector を足さず naked_ui を使う）。

### 約束（`lib/skin/forms/forms.dart`）

| 関数 | 渡る物 | アプリの部品 |
|---|---|---|
| `onOff(context, SwitchSpec)` | `on`、`onChanged` | オン・オフ（Animate all など） |

数値の絵は `number_paint.dart` の一つ。見た目の動き（`AnimatedContainer`、`TweenAnimationBuilder` など）は自由。手の受け取り（`GestureDetector`、`MouseRegion`、`Listener`）だけは書かず naked_ui に任せる。

### 使える材料

| 種類 | 名前 | 中身 |
|---|---|---|
| 文字の型 | `T.title()` `T.name()` `T.label()` `T.micro()` | 書体は革の `FontSans`。見出し・名前・小さな言葉・極小 |
| 文字の型 | `T.value()` | 書体は革の `FontMono`（等幅）。数と時間に |
| 文字の大きさ | `T.px(11)` | 革の TextScale を掛けた大きさ（`.copyWith(fontSize: T.px(n))`） |
| 書体の名前 | `T.sans` `T.mono` | 革が言う書体の名前 |
| 色 | `Grey.g00`〜`Grey.g100` | 灰色の段（どの段がアプリのどこかは [ROLES.md](../../../shelves/skins/ROLES.md) の表）。革の Background・Foreground から作られる |
| 色 | `Accent.fill` `Accent.on` `Accent.key` `Accent.ink` | 差し色の塗り、その上の文字、キーの印、地の上の線や文字 |
| 色 | `axX` `axY` `axZ`、Spec の `tone` | 軸の色、札の種類の色 |
| 形 | `Shape.r(n)` | 角の丸み（`Radius`、革の Corner を掛ける） |
| 形 | `Shape.s(n)` `Shape.z(n)` | 余白・大きさ（革の Spacing・Size を掛ける） |

フォームが自分の色を持つのも自由。革の色に合わせたい所だけ上の材料を使う。

### 手順
1. `lib/skin/forms/<名前>_forms.dart` に `class XForms extends Forms` を書き、`onOff` を書く。見本は `own_forms.dart`。
2. `lib/skin/forms/forms.dart` の `forms` に `'<名前>': XForms()` を1行足し、import する。
3. 革のフォルダの `theme.xml` に `<Forms Value="<名前>"/>` と書く（色は同じ theme.xml で）。
4. 見る：`app/tool/live.sh` でアプリを開き、View › Skin でその革を着て、フォームのファイルを保存するたびに描き直るのを見る。手を乗せた時・押した時は live.sh のアプリで手で確かめる。
5. 確かめる：切れ0・はみ出し0。色は文字の収まりに効かないので、書くのはフォームと書体（と Size・TextScale を変えるならそれ）だけでよい。

### 守ること
- 大きさは `Shape.z()`、余白は `Shape.s()`、文字は `T.name()` などの `T.*` と `T.px()` を通す（革の Size・Spacing・TextScale が効くように）。
- 文字は切らない。箱より広い時は `FittedBox(fit: BoxFit.scaleDown)` で縮める（長い名前は auto_size_text で2行まで）。
- `own_forms.dart` は「いつもの見た目」の正本。触る時は見た目を1画素も変えない。

## 4. デザインの方針

Anthropic 公式の考え方（[frontend-design スキル](https://github.com/anthropics/skills/tree/main/skills/frontend-design)、[公式ブログ](https://claude.com/blog/improving-frontend-design-through-skills)、[cookbook](https://platform.claude.com/cookbook/coding-prompting-for-frontend-aesthetics)）と、このプロジェクトで決まったことを合わせると：

- **題材に根を張る**：Motolii は「アイデアで勝つ MV を最短で作る道具」。その世界の素材から選ぶ。ありがちな既定値（Inter、白地に紫のグラデ、同じ角丸カードの繰り返し、クリーム×セリフ×テラコッタ、黒×蛍光緑、全部大文字の小見出し）は選択ではない。
- **色は意味**：札の種類・層の種類など、意味がある時だけ色を付ける。名前から適当に色を選ばない。
- **大胆さは1か所**：選んでいる物と Render のような主役にだけ。ほかは抑える。
- **文字が性格**：太さと大きさは極端に（細と極太、3倍の跳び）。大文字だけの言葉は避ける。
- **密度**：Ableton のように一目で読める密度を保つ。説明の文やホバーの説明は足さない。動画の画面が主役。
- **動き**：触った結果、何が変わったかを見せる動きだけ。
- **作り方は2回**：まず色4〜6個・書体・ASCII の配置図を書き、依頼と照らして直してから、コードを書く。撮って自分で講評する。

今の方向：ユーザーはスイスの幾何学ポスター（Posterlad の Checkers、Xavito deVito のライブのポスター）に寄せたい。候補を絵で並べた時の推しは「ポスター（静かめ）」：色は種類の意味だけ、派手なのは選択だけ、行の密度はミキサー卓のように詰める。

## 5. AI に頼む時の文

**値の革**（置くだけで着られる）：

> `shelves/skins/README.md` と `shelves/skins/ROLES.md` を読んで、`~/Library/Application Support/Motolii/skins/<名前>/theme.xml` に「（欲しい見た目）」の革を書いて。`app/tool/live.sh` でアプリを開いて見て、直して、また見る。読めない文字や差し色の埋もれがなくなるまで。

**フォーム**（組み立てから変える）。届く部品は §3 の表。

> `docs/app/skins/HANDOFF.md` を読んで、`lib/skin/forms/<名前>_forms.dart` に「（欲しい見た目）」のフォームを書き、登録して、`shelves/skins/<名前>/theme.xml` で着る革を作って。先に色4〜6個・書体・ASCII の配置図を書いて「ありがちな所」を直してから書くこと。§3 の表の関数を全部書く（書かない関数はアプリのいつもの絵のまま）。ドックのタブはまだ届かない。`app/tool/live.sh` でアプリを開いて見て直す。最後に切れ0・はみ出し0を確かめる。

## 6. 落とし穴（踏んだ物）

- **横に流れる行に Flexible**：スクロールする Row（例：プレビューの下の DeskStrip）の子に Flexible/Expanded を入れると、画面が組めずに15件落ちた。
- **const**：`Shape.z()` などは getter なので、`const` の中では使えない。解析器の `const_*` の指摘の所の `const` を外す。
- **ROLES.md の書き方**：`` `名前` `` と書いた物は全部「名前」として照合される。値の例は普通の文字で書く。範囲（`Clip1`〜`Clip7`）でなく全部並べる。
- **数の範囲**：Size 0.85〜1.5、TextScale 0.85〜1.3、Spacing 0〜2、Corner 0〜10 の外は端に収める（外だとタブが消える・文字が切れる）。
- **自動の札の色**：インスペクタの自動の札は、作った時の色を覚えていた。色は描く時に読む（`Fx.toneOf`）。

## 7. まだのこと

- フォームを通っている部品は、オン・オフと、数の絵。
- フォームはアプリに組み込まれるので、配った人が置くだけでは着られない。
- 細い線（1画素）の太さは革で変わらない。
- プレビューの中（枠の外の暗い所も）は作品の絵なので、革では変わらない。

## 8. 履歴

`1004c21` 手引き → `6572bd0` 革はフォルダ1つ・2色で灰色の段・shoot.sh・名前の照合 → `220e361` `cdcebd5` 外の LLM の指摘 → `adef71e` 直書きの大きさ0・文字は切らない → `517985e` 無茶な値の守り → `283dee2` 枠（9分割） → `760d873` ヘッドレス UI（フォーム） → `56ce5b4` この引き継ぎ → 外の AI がこれだけでライトテーブルのフォームを書いた（7/10、指摘は §3 の約束の細かい所・使える材料・§5 に反映）
