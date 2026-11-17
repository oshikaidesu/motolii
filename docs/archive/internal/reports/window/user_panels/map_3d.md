# 3D ソフトで「使う人が自分のパネルを作る」文化 — 言葉と場所の地図

2026-10-17。ウェブ検索だけで調べた（ログインなし、ダウンロードなし、ブラウザは使っていない）。
方針の変更（途中で受けた指示）：ソフト本体の UI と公式の指針は対象から外した。
「人がパネルを自作する」こと自体が、本体の UI に穴がある証拠。だから見るのは
自作パネルのまわりの人の集まり、まとめ記事、SNS、それに人がパネルをどう語るか。
個々のパネルの順位づけはしない。何度も名前が出るものだけを「埋める穴」「UI でほめられる点」の一行で書く。

注意：Reddit、X、Threads、YouTube の本文は、検索ではほとんど拾えなかった（拾えたのは
Reddit の写し 1 件だけ）。まとめ記事、売り場の評価、フォーラムが中心。SNS は未踏として残す。

---

## 1. 呼び名（自作パネルを何と呼ぶか）

| ソフト | 呼び名（英語） | 日本語・中国語・韓国語で見えた言葉 |
|---|---|---|
| Blender | add-on / extension、panel、N-panel（サイドバー）、pie menu、popup、gizmo、tab | アドオン、パイメニュー、Nパネル／插件、面板、N面板／애드온、N-패널 |
| Maya | shelf（棚）、script、tool、picker（キャラ選択盤）、toolkit、dock | シェルフ、ピッカー、ツール／插件、选择器(picker)、工具架 |
| Houdini | HDA（デジタルアセット）、parameter interface、shelf tool、Labs | HDA、パラメータインターフェース（SideFX 日本語 PDF あり） |
| Cinema 4D | User Data（ユーザーデータ）、Python plugin、Python tag、rig、preset | ユーザーデータ |
| Unity | editor extension、custom inspector、editor window、attribute（属性で描く） | エディタ拡張／에디터 확장、인스펙터 |
| Unreal | Editor Utility Widget（EUW）、editor plugin、editor tab | エディタユーティリティウィジェット |
| 3ds Max | MaxScript rollout（ロールアウト）、floater、utility | ロールアウト |
| Rhino / Grasshopper | Human UI（自作窓）、plugin | — |

## 2. ほめ言葉・けなし言葉（見えたもの）

- ほめる：clean / tidy（すっきり）、minimal、no clutter（ごちゃつかない）、intuitive（直感的）、
  sleek、lean / organized、godsend（神）、"can't work without it"（これなしでは無理）、
  "should be built-in" 型（"how is this not an integrated part of UE5"）、
  "huge productivity booster"、"visual canvas — not a bone soup"（骨の山でなく絵の盤）、
  readable（読める）、one click、"learn it in an afternoon"。
- けなす：cluttered（ごちゃごちゃ）、tab jungle（タブの密林）、"only first letters show"
  （タブが頭文字しか見えない）、bloat、hacky、"some love it, some hate the layout logic"、
  "makes it too easy"（Houdini で MOPs への反発）、壊れた（版上げで起動しない）。
- 日本語：見やすい、使いやすい、直感的、すっきり、「日本人に易しい設計」（BOOTH の売り文句）。
- 中国語：简洁、好用、直观。韓国語：직관적、깔끔、군더더기 없이（無駄なく）。
- 「整理系のアドオンが売れる」こと自体が言葉になっている：Clean Panels、Plugin Hub
  （"tames Blender's tab jungle"）、Quick N-Panel、Horizontal Sidebar Navigator。

## 3. 何度も名前が出る自作パネル（埋める穴／UI でほめられる点）

### Blender
- **Pie Menu Editor (PME)**：穴＝本体の Quick Favorites はほぼ変えられない。ほめ＝右クリックで何でもパイに入れられる、手元で完結。注意＝「先に自分の作業を分析しないと効かない」。Blender Market 5★/45件。
- **MACHIN3tools**：穴＝モード・表示・整列などが深い階層に散る。ほめ＝パイで一発、"godsend"、無料。けなし＝版上げで動かない声。
- **Hard Ops / Boxcutter**：穴＝ハードサーフェス作業の手数。ほめ＝画面上の操作で完結（ハードサーフェス勢の定番）。
- **Clean Panels / Plugin Hub / Quick N-Panel**：穴＝アドオンが増えると N パネルのタブが頭文字だけになる。ほめ＝パイや検索で呼べる、タブを片付けられる、起動も速く（作者談）。
- **Auto-Rig Pro のピッカー / X-Pose Picker / Animation Picker**：穴＝骨をビューで選ぶのがつらい。ほめ＝体の形の絵から選ぶ、左右で色分け、IK/FK 表示。けなし＝ARP は「ボタンが骨」で hacky（作者自身の言）。
- **Propui / Foam**：穴＝リグのカスタム属性が並び順も見た目も選べない。ほめ＝コードなしで並べて本物のパネルを生成。
- 公式同梱の「インターフェース」系（3D Viewport Pie Menus、Collection Manager など）は ja/ko 版マニュアルでまず挙がる。

### Maya
- **AnimSchool Picker / mgPicker / dwpicker**：穴＝リグのコントローラをビューで掴む手間。ほめ＝キャラの絵の上のボタン、名前空間を切り替えても効く、ズームできる、複数を同時に開ける。dwpicker は JSON で配布され、リグ販売者が添付する。
- **animBot（旧 aTools）**：穴＝tween、タイミング直し、選択セットなどが本体に散る／無い。ほめ＝約150ツールを一本の棚に、各ツールに GIF 付きの説明が出る。年額課金。
- **Studio Library**：穴＝ポーズの保存・再利用が本体に無い。ほめ＝サムネ一覧でポーズを混ぜる・左右反転、無料（LGPL）。
- **tweenMachine**：穴＝中割り。ほめ＝スライダー一本、一クリック。
- **KeyFlow / AnimKit**：穴＝同上。ほめ＝タイムライン上のドック、GIF 付きツールチップ、検索で絞る。

### Houdini
- **SideFX Labs**（150以上のツール、公式だが本体と別の更新）／**MOPs**／**qLib**／**Aelib**：穴＝よく使う手順をノード一つにしたい。ほめ＝本体と同じ流儀（HDA のパラメータ）で使える。けなし＝MOPs は「Houdini を簡単にしすぎ」という反発。
- HDA の UI で言われる言葉：lean、organized、easy to use（fxphd の講座）。不満＝カーソル近くのポップアップが作れない、多段パラメータのラベルが左寄せにできない。

### Cinema 4D
- **Signal（Greyscalegorilla）**：穴＝キーなしでループや揺れを付けたい。ほめ＝タグ一つ。サブスク限定。
- **Drop Zone / GorillaCam / Transform**：穴＝手順の多さ。ほめ＝ドラッグで正しいタグが付く。
- ユーザーデータ＋Python タグ：自作リグの操作盤の基本（Maxon 開発フォーラム）。「ボタンは Xpresso に入れるな、UI と評価は分けろ」という公式の答えがある。

### Unity
- **Odin Inspector**：穴＝インスペクタを変えるのにエディタコードが要る。ほめ＝属性を書くだけ（100以上）、"learn it in an afternoon"、ほぼ必須扱い。けなし＝ライセンス文。レビュー527〜541件。
- **vHierarchy / vFolders / vTabs（kubacho）**：穴＝ヒエラルキーやフォルダが見分けにくい。ほめ＝"minimal, no clutter"、色とアイコン、部品のミニマップ、消しても跡が残らない。
- Inspector Navigator：穴＝前に見たインスペクタへ戻れない。ほめ＝ブラウザの「戻る」と同じ。

### Unreal
- **Blueprint Assist**：穴＝ノードの整列と移動が手作業。ほめ＝自動整列、キーボードだけで編集。けなし＝整列の癖で好き嫌いが割れる。
- **Electronic Nodes**：穴＝線が交差して読めない。ほめ＝45°/90°の線、"how is this not integrated in UE5"、"huge UX/UI upgrade"。
- **Node Graph Assistant**：「これが新版に対応するまでエンジンを上げない」という声。
- **Flat Nodes**：見た目だけ変える（性能に影響なしと明記）。

### 3ds Max / Rhino
- ScriptSpot：rollout を作るための rollout builder、rollout browser。本体の Utilities 枠は「狭く隠れている」と公式ヘルプ自身が書く。
- Grasshopper の **Human UI**：穴＝定義を知らない人に触らせる窓が無い。ほめ＝スライダー・タブ・3D ビューをコードなしで並べる、「見栄えがいい」。food4Rhino で約6.2万DL。

## 4. 集まる場所・並べられる場所

| 場所 | 中身 | 規模（見えた数字） |
|---|---|---|
| Superhive（旧 Blender Market） https://superhivemarket.com/market-stats | 星と評価件数、作者ページ、"Fresh Finds" などのまとめ記事 | 作者 6,519、商品 71,836、うちアドオン 6,024、累計販売 574万件（取得時点） |
| extensions.blender.org https://extensions.blender.org/add-ons/ | 公式無料置き場。DL 数と評価件数 | アドオン 1,115。上位は Mio3 UV 30.5万DL、Ucupaint 30.3万DL |
| Gumroad / BOOTH | 個人販売。BOOTH は日本語 UI を売りにする品あり（リギングサポートアドオン 1,500円、w_pie 1,800円） | 不明 |
| BlenderArtists https://blenderartists.org | アドオンごとの長いスレッド（MACHIN3tools は54ページ超）、「N-panel Clutter」スレ | — |
| BlenderNation https://www.blendernation.com | アドオン個別レビュー（PME など）、年ごとの "best add-ons" ガイド | — |
| まとめ記事 | CG Cookie、All3DP、KitBash3D、Garagefarm（Blender）／Creative Bloq（Maya・C4D）／AnimSchool ブログ「Top 10 tools for Maya animators」／80.lv（Maya 無料ツール500まとめなど） | — |
| 日本語 | CGWORLD の連載（著名作者の愛用アドオン）、YouTube「全て無料 おすすめアドオン20選」型、BOOTH | — |
| Maya | Highend3D、Gumroad、ArtStation Marketplace、GitHub | 80.lv：無料 Maya アニメツール500以上を一か所に |
| Houdini | Orbolt（公式アセット店）、SideFX フォーラム、GitHub（qLib、Aelib）、Vimeo | Labs 150以上 |
| C4D | Greyscalegorilla Plus、Toolfarm、Maxon 開発フォーラム | — |
| Unity Asset Store https://assetstore.unity.com | 星、レビュー件数、お気に入り数。editor extension は席ごとライセンス | 全体バナー「13,000以上の高評価アセット」。拡張だけの数は見つからず |
| Fab https://www.fab.com | 旧 Unreal Marketplace の後継。一部の古い品は未移行 | 不明 |
| food4Rhino | Rhino/Grasshopper の置き場 | 560以上のアプリ（2020年） |
| ScriptSpot | 3ds Max スクリプト、"UI" "rollout" タグ | ページ番号431まである |
| Reddit / X / Threads / YouTube | r/blender、r/Maya、r/Houdini、r/Unity3D、r/unrealengine。本文はほぼ拾えず | 未踏 |

## 5. 「自作パネルの UI の良さ」を書いた・測ったもの

- パネル（アドオン）そのものの使いやすさを測った研究は見つからなかった。
- 近いもの：
  - 西江大（韓国）2025：Blender 4.4 と 3ds Max 2025 のツールバーを、ネット上の利用者コメント約80件で比較。Max は否定77.5%（リボンが複雑）、Blender は65.0%。Blender の不満の内訳＝クリックが増える 26.9%、道具の場所が散らばる 23.1%。 https://scholarworks.sogang.ac.kr/item/bf0bed3f-edcc-4a6d-af0f-a8d76efe4363
  - チャルマース工科大の修士論文「Material Tools - Creating an Intuitive User Friendly Interface」：3D ソフトは道具の多さと配置の悪さで人を圧倒し、操作の結果が見えにくい、と書いて要件に落とした。 https://odr.chalmers.se/handle/20.500.12380/112688
  - SUS（標準の使いやすさ点数）で 3D ツールを測った例：スケッチ式モデラー 79 点、ZBrush 41 点（初心者相手）。
- 売り場と SNS の言葉から見える物差し（研究ではない）：手数の少なさ、手元（カーソル脇・パイ）で済む、
  場所が散らばらない、ごちゃつかない、絵（キャラの形・線の形）で示す、本体に溶け込む／消しても跡が残らない、
  版上げで壊れない。

## 6. まだ見ていないところ
- Reddit・X・Threads・YouTube の本文とタイトル（検索に出てこない。ブラウザで一タブずつ読む必要がある）。
- 知乎、B站、Naver ブログ（各語で検索したが、出てきたのは英語ページだけ）。
- Unity Asset Store の editor extension の件数、Fab と Orbolt の件数。

## 出典（主なもの）
- https://superhivemarket.com/market-stats
- https://extensions.blender.org/add-ons/
- https://blenderartists.org/t/n-panel-clutter/1218580
- https://superhivemarket.com/products/clean-panels
- https://digitalproduction.com/2026/09/24/plugin-hub-tames-blenders-tab-jungle/
- https://www.blendernation.com/2020/04/07/blender-add-on-review-pie-menu-editor/
- https://blendermarket.com/products/pie-menu-editor/ratings
- https://superhivemarket.com/products/machin3tools/ratings
- https://polycount.com/discussion/comment/2588454
- https://www.strayspark.studio/blog/best-blender-rig-picker-addons-2026
- https://superhivemarket.com/products/propui
- https://booth.pm/ja/items/5994533
- https://cgworld.jp/regular/vol1.html
- https://animschool.edu/PickerInfo.aspx
- https://www.highend3d.com/maya/plugin/mg-picker-studio-for-windows-macos-linux-commercial-license-for-maya
- https://jrfk3d.gumroad.com/l/dfywo （dwpicker の配布例）
- https://blog.animschool.edu/2021/02/25/top-10-tools-and-plug-ins-essential-for-maya-animators/
- https://80.lv/articles/over-500-free-maya-animation-tools-are-now-available-in-one-place
- https://github.com/krathjen/studiolibrary
- https://www.sidefx.com/products/sidefx-labs/
- https://media.sidefx.com/uploads/japan/hda_guidelines_ja.pdf
- https://www.sidefx.com/forum/topic/56650/
- https://blog.fxphd.com/details/654/
- https://greyscalegorilla.com/plugins/signal
- https://developers.maxon.net/forum/post/57006
- https://assetstore.unity.com/packages/tools/utilities/odin-inspector-and-serializer-89041/reviews
- https://assetstore.unity.com/packages/tools/utilities/vhierarchy-249759
- https://discussions.unity.com/t/vtabs-tab-management-done-right/912112
- https://reddit.sentinel-team.org/posts/1qbw6sx/snapshots/2026-01-15T02%3A00%3A17.3129Z （Unreal の Reddit スレの写し）
- https://unreal-garden.com/tutorials/keyboard-only-blueprint-editing/
- https://dev.epicgames.com/documentation/en-us/unreal-engine/editor-utility-widgets-in-unreal-engine
- https://www.scriptspot.com/3ds-max/scripts/tags/rollout
- https://www.grasshopper3d.com/group/human-ui
- https://blog.rhino3d.com/2020/03/4500000-downloads-on-food4rhino.html
