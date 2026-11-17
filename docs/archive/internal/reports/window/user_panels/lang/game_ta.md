# ゲーム業界テクニカルアーティスト（TA）が作った「標準UIの置きかえパネル」

調査日 2026-10-17。ウェブ検索のみ、約25分。サインインなし、ブラウザ不使用。
「画像」欄: **目視済** = ダウンロードして中身がパネルの絵だと確かめた。**未確認** = ページから拾ったURLで、中身は見ていない。

## 0. 先に作った語の一覧（コミュニティが使う呼び名）

| 機能 | 英語 | 中国語 | 韓国語 | 日本語 | ポーランド語 | ウクライナ語 | フランス語 |
|---|---|---|---|---|---|---|---|
| 1 イージング板 | ease presets, easing curve, tween, flow, bezier ease | 缓动曲线, 缓动预设, 曲线编辑器替代 | 이징 커브, 이징 프리셋 | イージング, 緩急, カーブプリセット | krzywe wygładzania, easing | криві згладжування, ізинг | courbes d'accélération, easing |
| 2 パイ/ホットボックス | pie menu, radial menu, marking menu, hotbox | 饼菜单, 饼状菜单, 环形菜单, 标记菜单 | 파이 메뉴, 방사형 메뉴, 마킹 메뉴 | パイメニュー, マーキングメニュー, ホットボックス | menu kołowe | кругове меню, пай-меню | menu radial, menu camembert, hotbox |
| 3 リグピッカー | picker, anim picker, selector, control panel | 拾取器, 选择器, 角色选择面板, 控制器选择 | 피커, 셀렉터, 컨트롤러 선택 툴 | ピッカー, セレクター, コントローラー選択 | picker, selektor | пікер | picker, sélecteur |
| 4 色パレット | palette, swatches, color wheel, color hub | 调色板, 色板, 色卡 | 팔레트, 색상 견본 | パレット, スウォッチ, カラーホイール | paleta kolorów, próbki | палітра, зразки кольорів | palette, nuancier |
| 5 検索/サムネ格子 | search, command palette, launcher, asset browser | 搜索, 命令面板, 资源浏览器, 缩略图 | 검색, 커맨드 팔레트, 에셋 브라우저 | 検索, コマンドパレット, アセットブラウザ, サムネイル | wyszukiwarka, paleta poleceń | пошук, палітра команд | recherche, palette de commandes |
| 6 階層の整理 | outliner, hierarchy, folders, color hierarchy | 层级面板, 大纲, 分组, 折叠, 颜色标记 | 하이어라키, 아웃라이너, 폴더 색상 | ヒエラルキー拡張, アウトライナー, フォルダ色分け | hierarchia, konspekt | ієрархія, аутлайнер | hiérarchie, outliner, dossiers |
| 7 タブ/サイドバー整理 | tabs, N-panel organizer, sidebar | 标签页, 侧边栏整理 | 탭 정리, 사이드바 | タブ整理, サイドバー, Nパネル | zakładki, pasek boczny | вкладки, бічна панель | onglets, barre latérale |
| 8 3x3 アンカー | origin grid, pivot, anchor presets, 3x3 | 轴心, 锚点, 原点九宫格 | 피벗, 앵커, 원점 | ピボット, 原点, 9点 | punkt obrotu, pivot | точка опори, півот | pivot, point d'ancrage |

検索で効いた語: 英語の pie menu / picker / hierarchy / N-panel / origin grid / easing presets。中国語・韓国語・ポーランド語・ウクライナ語の語では、置きかえパネル本体に当たらなかった（後述）。

## 1. イージング板（グラフエディタの代わり）

| 名前 | ホスト | 作者 / 地域 | 画像 | 製品URL | 更新 | 使用の証拠 | たどった道 |
|---|---|---|---|---|---|---|---|
| Zeeks Flow | Blender | Ezekiel-AA / 不明 | 未確認 https://extensions.blender.org/media/thumbnails/df/dfee07473588601cbb1db25ca206959ab96ee10b90540ba35fc2f85f43538306_1920x1080.webp | https://extensions.blender.org/add-ons/zeeks-flow/ | v1.4.0 2026-07-15 | 2,423 DL, 評価5.0(1件)。AEの Flow を手本と明記 | 「Flow のような」検索 |
| Flux | Blender | narusenia / 日本 | なし | https://narusenia.gumroad.com/l/flux-blender | 不明（ベータ） | ¥500〜。AE Flow のデータを読み込める＝Flowの写し | 同上 |
| FlowGraph | Blender | mirukodesu / 不明 | なし | https://mirukodesu.gumroad.com/l/FlowGraph | 不明 | 無料。easings.net の一覧を内蔵、Flow を真似たと作者が明記 | 同上 |
| Bezier Curve Editor | Blender | IcedDog / 不明 | なし | https://80.lv/articles/free-blender-add-on-inspired-by-after-effects-flow | 不明 | 80.lv が記事化。無料 | 同上 |
| Graphi | Blender | 不明 | なし | https://superhivemarket.com/products/graphi | Blender 4.2〜5.2 対応 | 有料 $14.25 | 同上 |
| AniKin | Maya | mihirDP / 不明 | なし | https://github.com/mihirDP/AniKin/wiki | 不明 | TW（中割り）と EA（緩急）をボタン化 | 「ease ボタン Maya」検索 |

所見: AE の Flow を Blender に写したものが少なくとも4つ独立にある（形が収束）。ゲーム系 TA 出身と明記された作は見つからず。

## 2. パイメニュー / ホットボックス

| 名前 | ホスト | 作者 / 地域 | 画像 | 製品URL | 更新 | 使用の証拠 | たどった道 |
|---|---|---|---|---|---|---|---|
| Hotbox Designer | Maya ほか | Lionel Brouyère ほか / フランス | 未確認 https://raw.githubusercontent.com/luckylyk/hotbox_designer/master/documentation/hotbox.gif | https://github.com/luckylyk/hotbox_designer | 不明 | 130★。dwpicker の元になった（写された） | dwpicker の README から逆向き |
| PiUE | Unreal | Solessfir / 不明 | **目視済** https://github.com/Solessfir/PiUE/raw/main/Resources/Screenshot.png （中央の輪と周りに文字ボタン5つ） | https://github.com/Solessfir/PiUE | 不明 | 27★、Fab でも配布、80.lv 記事。「Blender風」と明記 | 「Unreal pie menu」検索 |
| Quick Menu | Unreal | Grégoire Fontanelli / フランス語圏 | なし | https://www.fab.com/listings/5b5c797a-0e5d-4761-bacb-21e566592318 | UE 5.0〜5.7 | 有料、約250の動作を内蔵 | 同上 |
| Tentacle | Maya（Blender/Max は途中） | m3trik / 不明 | 未確認 https://raw.githubusercontent.com/m3trik/tentacle/main/docs/demo.gif | https://github.com/m3trik/tentacle | PyPI で更新中 | 27★、約60の道具パネル | 「marking menu github」検索 |
| Pie Menu Editor (PME) | Blender | roaoao（原作）/ Pluglug（継承版） | なし | https://roaoao.gumroad.com/l/pie_menu_editor ・ 継承版 github.com/Pluglug/pie-menu-editor-fork | 継承版 v1.19.0（Blender 5.0） | Blender Artists のスレッドが278ページ超。作者公認で継承された | 「Blender pie」検索 |
| Radial Menu | Unity（エディタ全体） | 不明 | なし | https://assetstore.unity.com/packages/tools/utilities/radial-menu-266112 | Unity 2021〜 | $9.90。左Altで全ウィンドウに出る | 「Unity editor pie」検索 |

## 3. リグピッカー（体の絵にボタン）

| 名前 | ホスト | 作者 / 地域 | 画像 | 製品URL | 更新 | 使用の証拠 | たどった道 |
|---|---|---|---|---|---|---|---|
| picker | Maya | azagoruyko（リギングTD）/ 不明 | **目視済** https://user-images.githubusercontent.com/9614751/226429549-0582ae4a-92db-4aa0-a97c-8719848fdd07.png （人型に色付き台形ボタン、ik/fk 丸ボタン、右に属性パネル） | https://github.com/azagoruyko/picker | Maya 2025/PySide6 対応 | 31★。AnimSchool の .pkr を読み込める＝AnimSchool の形を継ぐ | 中国語「拾取器」検索 |
| dwpicker | Maya | DreamWall / ベルギー | 未取得（リポジトリの screenshots フォルダにあり） | https://github.com/dreamwall-animation/dwpicker | 不明 | 257★。Hotbox Designer の派生 | 「picker github」検索 |
| MG-Picker Studio | Maya | Wenfeng Gao（Miguel Winfield）/ 中国出身のアニメTD | なし | https://www.cgchannel.com/?p=73017 | 1.5 は2015年 | 既製レイアウトは無料、保存は有料 $120 | 「mgPicker」検索 |
| mGear Anim Picker 2.0 | Maya | mGear 開発陣 | なし | https://mgear4.readthedocs.io/en/master/animPickerUserDocumentation.html | 2.0 で書き直し | mGear 同梱（オープンソース）。SVG、HUD表示 | 中国語「拾取器」検索 |
| AnimSchool Picker | Maya | AnimSchool / 米国 | なし | https://blog.animschool.edu/2012/11/23/animschool-picker/ | 2012〜 | 無料、他ツールが形式を読み込む（写された） | 知乎向け検索の副産物 |
| FT Anim Picker → BGEN Picker | Maya | munorr / 不明 | なし | https://munorr.gumroad.com/l/ft-anim-picker-maya | 改名済 | ポーズのサムネイル付き | 中国語検索 |

## 4. 色パレット棚

| 名前 | ホスト | 作者 / 地域 | 画像 | 製品URL | 更新 | 使用の証拠 | たどった道 |
|---|---|---|---|---|---|---|---|
| uPalette | Unity | Haruma-K / 日本 | 1枚目は空の初期画面で外れ（目視）。2枚目 未確認 https://user-images.githubusercontent.com/47441314/157675124-bf3471c4-5f0f-4a07-ae10-8a97b3d986ad.png | https://github.com/Haruma-K/uPalette | 不明 | 385★。色を一か所で管理し一括で変える | 「Unity palette github」検索 |
| MagicPicker | Photoshop | Anastasiy / ウクライナ | なし | https://anastasiy.com/magicpicker_panel | 4.0 は2014年 | 有料。標準の色パネルの代わりに色相環。HUD モード | 「Photoshop color wheel panel」検索 |
| MyColors | Unreal | 不明 | なし | https://www.fab.com/listings/fbbd04ff-7af4-4fbc-9ae5-92a98f0c4005 | 不明 | 無料。名前付きスウォッチ帳、ページ分け | 「Unreal palette」検索 |
| Swatchr | Unity | 00jknight | なし | https://github.com/songlking/swatchr | 不明 | .ase/.png から読み込み、標準ピッカーに書き出し | 「Unity palette github」検索 |

## 5. 検索ボックス / サムネ格子

| 名前 | ホスト | 作者 / 地域 | 画像 | 製品URL | 更新 | 使用の証拠 | たどった道 |
|---|---|---|---|---|---|---|---|
| Searcher | Houdini | instance.id / 不明 | なし | https://www.artstation.com/marketplace/p/Kx1v/searcher-houdini-command-pallete-add-on | v0.1.1（2020） | $15。JetBrains / VS Code のコマンドパレットを手本と明記。あいまい一致 | 「Houdini searcher」検索 |
| （比較）Unity Search | Unity 公式 | Unity | なし | https://docs.unity3d.com/Manual/search-window-reference.html | Unity 6 | 利用者の Quick Search が公式に吸収された例。拡大でサムネ格子に切りかわる | 同上 |

所見: 利用者作の「サムネ格子で置きかえ」は見つからず、止めた（3件連続で新規なし）。

## 6. 階層（アウトライナー）の整理・折りたたみ

| 名前 | ホスト | 作者 / 地域 | 画像 | 製品URL | 更新 | 使用の証拠 | たどった道 |
|---|---|---|---|---|---|---|---|
| Rainbow Folders | Unity（Project 窓） | Borodar / ウクライナ（ウージュホロド） | **目視済** https://borodar.com/stuff/rainbowfolders/images/v05/01.png （左の木と右の格子でフォルダが13色） | https://github.com/Borod4r/unity3d-rainbow-folders | 2 版を販売中 | 650★、Asset Store で有料版 | 「Rainbow Folders」検索 |
| Rainbow Hierarchy 2 | Unity（Hierarchy 窓） | Borodar（推定）/ ウクライナ | なし | https://assetstore.unity.com/packages/tools/utilities/rainbow-hierarchy-2-106670 | v2.6.2 2024-12-10 | $15、アイコン200超 | 同上 |
| vHierarchy 2 | Unity | kubacho lab / 不明 | なし | https://assetstore.unity.com/packages/tools/utilities/vhierarchy-249759 | 不明 | 部品のミニマップ、1キー操作 | 「vTabs」検索 |
| HierarchyDecorator | Unity | Damian Slocombe（WooshiiDev）/ 不明 | 未確認 https://user-images.githubusercontent.com/31889435/226486126-009081e1-44de-465c-8ff7-5641870fdcae.png | https://github.com/WooshiiDev/HierarchyDecorator | 2025年3月に更新 | 1.4k★、fork 77 | 中国語「层级面板」検索 |
| Outliner2-SF（Pier Janssen 作 Outliner の復活版） | 3ds Max | spacefrog（原作 Pier Janssen / オランダ） | なし | https://scriptspot.com/3ds-max/scripts/outliner2-sf | v2.5.0.0 2026-05-09 | Max 2016〜2027。原作は長年の定番、公式 Scene Explorer が追いつかないと利用者が言う | 「3ds Max Outliner」検索 |
| Quick Folder（UTools） | Unreal | 不明 | なし | https://forums.unrealengine.com/t/2507090 | 不明 | 種類ごとに自動でフォルダ分け | 韓国語「아웃라이너」検索 |

## 7. タブ / サイドバー整理

| 名前 | ホスト | 作者 / 地域 | 画像 | 製品URL | 更新 | 使用の証拠 | たどった道 |
|---|---|---|---|---|---|---|---|
| vTabs 2 | Unity | kubacho lab / 不明 | なし | https://marketplace.unity.com/packages/tools/utilities/vtabs-2-253396 | v2.1.2 2025-02-09 | Unity 掲示板にスレッド、海賊配布まである（人気の裏返し） | 「vTabs」検索 |
| SISideBar | Maya | ShikouYamaue / 日本 | **目視済** https://user-images.githubusercontent.com/28256498/32726190-6982b406-c8bb-11e7-9c9d-25a018194a1a.jpg （縦長の帯：選択、絞りこみボタン列、移動/回転の数値欄） | https://github.com/ShikouYamaue/SISideBar | ver2.3.5 2018-01-27 | 54★。Softimage のサイドバーを Maya に写した | 日本語ピッカー検索の延長 |
| Ultimate N-Panel Organizer | Blender | 不明 | なし | https://superhivemarket.com/products/ultimate-n-panel-organizer/docs | Blender 4.5〜 | 隠す・名前変え・並べ替え・保存 | 「N panel tabs」検索 |
| SimplyTab | Blender | 不明 | なし | https://superhivemarket.com/products/simplytab | v1.2.0 | まとめる・隠す・並べ替え・固定 | 同上 |
| Simple Tabs / Simple N-Panel | Blender | bonjorno7・Chipp Walters | なし | https://chippwalters.gumroad.com/l/rjtea | 不明 | 有料。タブを一覧メニューにまとめる | 同上 |
| N-Panel SideOrder | Blender | Pixonomic | なし | https://superhivemarket.com/products/n-panel-sideorder/docs | Blender 4.2〜 | タブをドラッグで並べ替え | 同上 |

所見: Blender のサイドバーのタブ過多は「同じ不満から独立に5つ以上」作られている。

## 8. 3x3 アンカー / ピボット格子

| 名前 | ホスト | 作者 / 地域 | 画像 | 製品URL | 更新 | 使用の証拠 | たどった道 |
|---|---|---|---|---|---|---|---|
| Easy Axis | Blender | 不明 | なし | https://superhivemarket.com/products/easy-axis/docs | 不明 | 3x3 の位置格子、箱基準と形基準の2モード | 「origin 3x3」検索 |
| Set Origin Tool | Blender | Abbos Mirzaev / 不明 | 1枚目は題字だけで外れ（目視）。動く絵 未確認 https://assets.superhivemarket.com/cache/2d14d1430663c03da217a43c984d4e87.gif | https://superhivemarket.com/products/set-origin-tool | v1.0.1、1年以上前 | $1、60件以上売れた、評価5(3件)。パイ版もある | 同上 |
| Ultimate Origin Tools | Blender | 不明 | なし | https://superhivemarket.com/products/ultimate-origin-tools/docs | Blender 4.2〜5.x | 22点（面6・角8・辺12）に広げた版 | 同上 |
| gzPivot | Blender（Max/Maya 版もある名前） | albertogz | なし | https://albertogz.gumroad.com/l/gzPivot_Blender | 不明 | 無料版あり | 同上 |

所見: Unity では 3x3 格子の利用者作は見つからず（公式の Rect Transform アンカーが既にその形）。

## その他の置きかえ

| 名前 | 置きかえ先 | ホスト | 作者 / 地域 | 画像 | 製品URL | 証拠 |
|---|---|---|---|---|---|---|
| SIWeightEditor | Maya のウェイト表（コンポーネントエディタ）を Softimage 風の色付き表に | Maya | ShikouYamaue / 日本 | **目視済** https://user-images.githubusercontent.com/28256498/41656611-8d04f67a-74cb-11e8-856d-c365d2957ed6.png （骨ごとに色の付いた列見出し、上に丸ボタンの切替群） | https://github.com/ShikouYamaue/SIWeightEditor | 121★ |

## 見つからなかったもの（正直に）

- 知乎・UWA・游戏蛮牛・Tencent/NetEase の公開リポジトリ: 中国語の語で検索したが、置きかえパネル本体は出ず。出てくるのは英語圏ツールの紹介。中国出身の作者は MG-Picker の Wenfeng Gao のみ。
- 韓国（NC・Nexon・Smilegate の技術ブログ）: 該当なし。
- ポーランド（CD Projekt、Techland）: 該当なし。ウクライナは Borodar（Rainbow 系）と Anastasiy（MagicPicker）の2者。
- CEDEC: Maya の社内ツール講演（CEDEC+KYUSHU 2023、バンダイナムコ・カプコン・セガ）はあるが、パネル画面の公開物は見つからず。日本は ShikouYamaue（SI 系2本）、Haruma-K（uPalette）、narusenia（Flux）。
- 社内ツールは講演で見せても公開しないのが普通。公開されて残るのは個人の TA / アニメ TD の作。

## 所見（形の収束）

- 他ソフトの「良い画面」をそのまま写す型が多い: AE の Flow → Blender に4つ以上、Softimage → Maya（SISideBar、SIWeightEditor）、Blender のパイ → Unreal（PiUE）、VS Code のコマンドパレット → Houdini（Searcher）。
- 色で区別する型: Rainbow Folders、HierarchyDecorator、SIWeightEditor の列色。
- 置きかえは「標準の窓の中に足す」形（Hierarchy や Project の行に色・アイコン）が「別窓を開く」形より多く売れている。
