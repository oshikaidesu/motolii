# 本家の言語圏で集めた「標準UIの置きかえパネル」(2026-10-17)

担当: 各ソフトの「生まれた国の言葉」の集まり。C4D=ドイツ語、Houdini と Toon Boom Harmony=フランス語・カナダ英語、VEGAS Pro と 3ds Max=ロシア語、Blender と Krita=オランダ語・ヨーロッパ。
やりかた: 言葉の表を先に作る → ウェブ検索 → ページの og:image を取り、画像を一枚の見本帳にして目で見た。
画像の欄の印: ◯ = パネルそのものが写っている(目で確認)、△ = 一部だけ、× = 宣伝の絵だけ(パネルは写っていない)、- = 取れず。

## 正直な注意(先に読む)

- 本家の言語の掲示板(c4d-treff.de、render.ru、od|force、ロシア語の VEGAS サイト)は、検索エンジンからほぼ届かなかった。c4d-treff は表紙だけ、3ddd.ru は記事1本だけ当たった。
- だから見つかったものの多くは英語の売り場(Gumroad、Superhive、lesterbanks、krita-artists)経由。作者の国は名前や所属からの推測が多い。推測には「推測」と書いた。
- scriptspot と ArtStation のページは機械からの取得を拒否された(画像は取れず)。
- VEGAS Pro のロシア語圏パネルは見つからなかった。Toon Boom Harmony はパイメニュー以外ほぼ空振り。
- サインインなし、個人情報の入力なし、ダウンロードした物の実行なし。

## 言葉の表(各コミュニティが使う呼び名)

| 機能 | ドイツ語 (C4D) | フランス語 (Houdini/Harmony) | ロシア語 (3ds Max/VEGAS) | 英語での売り場の呼び名 |
|---|---|---|---|---|
| 1 イーズ曲線 | Kurveneditor, F-Kurve, Easing-Presets, Animationskurve | éditeur de courbes, courbe d'animation, ease in/out, préréglages | редактор кривых, сглаживание ключей, кривые анимации | easing presets, ease panel, curve presets, F-curve presets |
| 2 パイメニュー | Tortenmenü, Kreismenü, Radialmenü, Popup-Menü | menu circulaire, menu radial, menu camembert | круговое меню, радиальное меню, квад-меню | pie menu, radial menu, marking menu, hotbox, wheel |
| 3 リグピッカー | Charakter-Auswahl, Picker, Visual Selector | sélecteur de contrôleurs, picker | пикер, выбор костей, свиток с кнопками | rig picker, character picker, control picker |
| 4 色パレット | Farbpalette, Farbfelder, Farbmanager | palette de couleurs, nuancier | палитра цветов, образцы цвета | color palette, swatches, color manager |
| 5 検索と見本グリッド | Suche, Asset-Browser, Vorschaubilder | recherche, navigateur d'assets, vignettes | поиск, менеджер ассетов, превью, библиотека моделей | asset browser, thumbnails, command palette, searcher |
| 6 層の整理 | Objekt-Manager, Ebenen, Ordner, Labels | outliner, calques, dossiers | менеджер слоёв, слои, аутлайнер, группы | outliner, layer manager, nested layers |
| 7 タブ整理 | Reiter, Seitenleiste aufräumen | onglets, barre latérale | вкладки, панель, свиток (rollout) | N-panel organizer, sidebar tabs, tab manager |
| 8 3x3 基準点 | Achse zentrieren, Achse setzen, Ankerpunkt | point de pivot, ancrage | пивот, опорная точка, выравнивание пивота | pivot grid, align pivot, anchor point, axis center |

ロシア語で 3ds Max の窓の単位は「свиток」(rollout)。スクリプトの窓を指す一番ふつうの言葉。

---

## 1. イーズ曲線ボード(グラフエディタの代わり)

| 名前 | ソフト | 作者・国 | 画面の形 | 画像 | 製品URL | 最終更新 | 使われ方 | たどった道 |
|---|---|---|---|---|---|---|---|---|
| Grafixer | C4D | Kengo Ito(日本) | 小窓に曲線1本+下にプリセットの小さな曲線ボタン列。Get/Apply | ◯ https://public-files.gumroad.com/032ruvwbv9to3pvmzqsbnn0x4d3o | https://kengoito1110.gumroad.com/l/nRZHQ | S24 以降は Motion Manager に統合と作者 | Toolfarm で紹介 | 「c4d-treff Kurven Easing」検索 |
| Kengo Ito Motion Manager | C4D | Kengo Ito(日本) | イーズのコピペ、バウンス/弾性、プリセット棚、ライブ確認 | - | https://www.toolfarm.com/?p=116823 | C4D 2024 対応 | Toolfarm 販売 | Grafixer の説明から |
| Magic AnimCurve | C4D | Nitroman / Nitro4D | 曲線の絵のボタンを ease in/out/in-out の組で並べた窓 | ◯ https://lesterbanks.com/lxb_metal/wp-content/uploads/2014/08/Magic-AnimCurve-for-cinema-4d.jpg | https://lesterbanks.com/2014/08/magic-animcurve-c4d/ | 2014 | lesterbanks 紹介 | 同上 |
| Easeit | Blender | AndyCuccaro | サイドバーのタブにプリセット(Simple/Advanced/Custom)。キー選んで1クリック | ◯ https://extensions.blender.org/media/thumbnails/9b/9bd2f8de66d1542e73d1e53dcb836c474e370643c86295e39e686f7c80b148d1_1920x1080.webp | https://extensions.blender.org/add-ons/easeit/ | v2.0.3, 2026-09-04 | 9,903 ダウンロード、5.0点(8件) | 「ease curve presets panel」検索 |
| Graph Pilot | Blender | 不明 | Ease In/Out スライダー+26以上のプリセット、3Dビューから使える | × https://assets.superhivemarket.com/store/product/192801/image/d7b41cf318c929048988a2bcd4ad7898.jpg | https://superhivemarket.com/products/graphpilot | 不明 | レビューあり(「即時に反映しない」との不満) | 同上 |
| Relative Ease | Blender | Fede Parodi | 影響スライダー+Set ボタン | × https://public-files.gumroad.com/bbi9fsn5vrmeov73h7not8f17wmy | https://fedeparodi.gumroad.com/l/relative-ease | 不明 | 無料 | 同上 |
| Fusion Ease Pro | Blender | Fusion Art Studios | 影響スライダー、プリセット、平らなハンドル、イーズのコピペ | × https://public-files.gumroad.com/srgmnfb9hpc2omg0zsiasm6qntmy | https://fusionartstudios.gumroad.com/l/68e2075394b94 | 不明 | 有料 $9.99 | 同上 |
| Graphi | Blender | 不明 | すぐ選べるプリセット棚(曲線の絵) | 動くGIF(未確認) https://assets.superhivemarket.com/cache/6d58e5cb0afe452ebe3ce8435ae2bfdb.gif | https://superhivemarket.com/products/graphi | 不明 | 有料 | 同上 |
| Flux / FlowGraph | Blender | narusenia / mirukodesu | イーズ値に名前を付けて保存・呼び出し | - | https://narusenia.gumroad.com/l/flux-blender | ベータ | 不明 | 同上 |

まとめ: どれも「曲線を描く」をやめて「曲線の小さな絵のボタンを押す」へ置きかえている。Toon Boom Harmony では同じ形の第三者パネルは見つからず(dpotekhin のオーバーシュート追加スクリプトはパネルではない)。

## 2. パイメニュー・円形メニュー

| 名前 | ソフト | 作者・国 | 画面の形 | 画像 | 製品URL | 最終更新 | 使われ方 | たどった道 |
|---|---|---|---|---|---|---|---|---|
| Dials | C4D | Daniel Sterckx(PolyGnome の作者) | カーソル下に道具アイコンの輪。後にドラッグで中身を入れかえ | ◯ https://lesterbanks.com/lxb_metal/wp-content/uploads/2018/10/C4D-Dials-to-Get-Drag-and-Drop-Customization.jpg / ◯ https://lesterbanks.com/lxb_metal/wp-content/uploads/2018/07/Radial-Menus-Coming-to-Cinema-4D-in-a-New-Plugin.jpg | https://lesterbanks.com/?p=52954 | 2018(試作段階のまま) | lesterbanks 2回紹介 | 「Tortenmenü」検索 → Maxon 開発者フォーラム |
| Radially | 3ds Max | winged | 最大14項目のパイ。キーを押して、なぞって、離す | △ https://public-files.gumroad.com/o4qic2z12jbphnmt0qgaye8rgk4y | https://winged.gumroad.com/l/radially | Max 2015〜2024 対応 | scriptspot・CGPress 掲載 | scriptspot 検索 |
| Octopus | 3ds Max | 不明 | Maya 風マーキングメニュー、全体をプログラムで変えられる | × https://cgpress.org/wp-content/uploads/2018/05/Octopus.jpg | https://cgpress.org/archives/octopus-for-3ds-max-released.html | 2018 | CGPress 紹介 | Radially の検索結果から |
| Shortcut Composer | Krita | wojtryb(ポーランド、推測) | キーを押す間だけ出るパイ。ブラシ・道具・不透明度などを選ぶ | ◯ https://krita-artists.org/uploads/default/optimized/3X/7/0/706b1c031aec8a322dc55c9cf985ed4b77953d23_2_1024x576.jpeg | https://krita-artists.org/t/shortcut-composer/55314 | v1.7.1(Krita 5.3) | スレッド24ページ超、GameFromScratch 紹介 | 名前で検索 |
| Pie Menu v0.4 | Krita | krita-artists の投稿者 | 中心の輪から6方向に文字ボタン(不透明度、流量、サイズ…) | ◯ https://krita-artists.org/uploads/default/original/3X/4/4/4496816163b44800f0ca9259acad65ff713aa95e.jpeg | https://krita-artists.org/t/plugin-pie-menu-v0-4/15888 | 不明 | Shortcut Composer の先祖格 | Shortcut Composer の検索結果から |
| MACHIN3tools | Blender | MACHIN3(国は未確認) | 12種のパイ(モード、保存、表示、整列、カーソル…) | × https://assets.superhivemarket.com/store/product/153574/image/xlarge-11e8492d6192ea3905c8adc9fc6b958a.jpg | https://superhivemarket.com/products/machin3tools | 継続更新 | 無料、BlenderArtists で人気 | 「Blender ドイツ作者」探し |
| Pie Menu Editor (PME) | Blender | roaoao(ロシア語圏、推測) | パイ・ふつうのメニュー・ポップアップ・サイドパネル・道具棚を自作 | ◯ https://assets.superhivemarket.com/store/product/70990/image/xlarge-71766bc7a2f4536ec9e71e419a862c8f.png | https://roaoao.gumroad.com/l/pie_menu_editor | v1.18.8。Blender 5.0 で動かない苦情、作者公認の分岐あり | BlenderArtists スレッド231ページ超、BlenderNation 書評 | 「ロシア語圏の作者」探し |
| EZ Backdrop | Toon Boom Harmony | visualdroids | ノードを選び、円形の色パイで背景枠の色を選ぶ | ◯ https://public-files.gumroad.com/kzdxfa5wrbaxpra0g2te0073pb8g | https://visualdroids.gumroad.com/l/ezbackdrop | 不明 | 有料 | 「OpenHarmony pie menu」検索 |
| OpenHarmony の Pie Menu 部品 | Toon Boom Harmony | Mathieu Chaptel, Chris Fourney | スクリプト用ライブラリ内のパイメニュー部品 | -(README に絵なし) | https://github.com/cfourney/OpenHarmony | 不明 | 81 スター、724 コミット | 記憶から → 確認 |

## 3. リグピッカー(体の絵にボタン)

| 名前 | ソフト | 作者・国 | 画面の形 | 画像 | 製品URL | 最終更新 | 使われ方 | たどった道 |
|---|---|---|---|---|---|---|---|---|
| MW Character Picker | C4D | ddingone | 体の形に並んだ色つき四角ボタン(赤=右、青=左)、右に人型の絵 | ◯ https://public-files.gumroad.com/f5ff15qibv5jnzrdx3boyg69farc | https://ddingone.gumroad.com/l/MWCharacterPicker | v1.0 | 0円〜(投げ銭) | 「C4D character picker」検索 |
| rig_picker | Blender | Autour de Minuit(パリのアニメスタジオ) | ノードエディタ領域に2D図形を描き、押すとコントローラ選択。1リグに複数ピッカー | △ https://git.autourdeminuit.com/autour_de_minuit/rig_picker/raw/branch/master/attachments/doc_picker_01.png(インストール画面。ピッカー本体は doc_picker_02 以降) | https://git.autourdeminuit.com/autour_de_minuit/rig_picker | README 2024-10-30、2025 にも更新 | スタジオ内で実運用 | 「フランスの作者」探し |
| (参考)Visual Selector | C4D 標準 | Maxon | 右クリックでボタン追加、グループ化 | - | Maxon 標準 | - | 標準機能なので置きかえではない | 同上 |

3ds Max と Harmony のピッカーは、ロシア語でも英語でも、作り方の相談だけで完成品は見つからなかった。

## 4. 色パレット棚

| 名前 | ソフト | 作者・国 | 画面の形 | 画像 | 製品URL | 最終更新 | 使われ方 | たどった道 |
|---|---|---|---|---|---|---|---|---|
| Color4D | C4D | Vidar Nelson | 色の輪+RGB/HSV/CMYK/LAB スライダー+上に色見本の列、.ASE 読込 | ◯ https://lesterbanks.com/lxb_metal/wp-content/uploads/2014/10/Color4D-color-managment-plugin-for-cinema-4d.jpg | https://github.com/vidarn/color4d | 2014(R15) | 当時 $10、ソース公開 | 「Farbpalette」検索 |
| Colorize | C4D | Arttu Rautio | 右端に縦の色見本の列。Xpresso ノードを色分け | ◯ https://lesterbanks.com/lxb_metal/wp-content/uploads/2019/09/Free-Colorize-Plugin-for-C4D-Lets-You-Create-Pallets.jpg | https://lesterbanks.com/2019/09/free-colorize-plugin-for-c4d-lets-you-create-pallets/ | 2019 | 無料 | 同上 |
| Viewport Color Palette | C4D | Antro Nero | 決まった配色セットから色を配る | × https://public-files.gumroad.com/cmw08at5zj8asw2q32py882othjj | https://antronero.gumroad.com/l/Viewport-color-palette-plugin | C4D 2025 対応 | €15 | 同上 |
| Node Color Lab | Houdini | Manuel Tausch(od|force で公開) | ノード種類ごとの色の表、選んでクリック | ◯ https://lesterbanks.com/lxb_metal/wp-content/uploads/2015/11/Houdini-Node-Color-Lab.jpg | https://lesterbanks.com/?p=38888 | 2015〜2016 | od|force 投稿 | 「Houdini color palette」検索 |
| TNT Color Palette | Houdini | ms3nethra | 分類つき色見本の浮き窓。ノード・枠・付箋に色 | × https://public-files.gumroad.com/log0wbco4b4csnqi3vecmrenkf3c | https://github.com/ms3nethra/tntColorPalette | 不明 | 無料 | 同上 |
| Pigment.O | Krita | (ポルトガル、推測) | 絵の具の混ざり方をまねる色選び。Picker と Sampler の2ドッカー | -(og 画像は掲示板の共通ロゴ) | https://krita-artists.org/t/pigment-o-plugin/4531 | 継続 | スレッド46ページ超 | 「Krita colour docker」検索 |
| PS_PaletteTools | Toon Boom Harmony | dpotekhin(ロシア語の名前、推測) | パレット用ボタン集 | -(README に絵なし) | https://github.com/dpotekhin/ToonBoomHarmonyScripts | 不明(作者は「多くは古い」と注記) | 21 スター | 「Harmony ease script」検索 |

## 5. 検索・見本グリッド(メニューや一覧の代わり)

| 名前 | ソフト | 作者・国 | 画面の形 | 画像 | 製品URL | 最終更新 | 使われ方 | たどった道 |
|---|---|---|---|---|---|---|---|---|
| Project Manager | 3ds Max | Kstudio(旧ソ連圏、推測) | 左にフォルダ木、右に模型の見本絵グリッド、下に言葉で探す欄(「ガラスの立方体の机」で探せる) | ◯ https://digitalproduction.com/wp-content/uploads/2026/08/7o4wzfdkc-q-00-00-20-3d-kstudio-52-project-manager--the-asset-browser-that-understands-you-microsoft-broke-windows-defender-while-trying-to-patch-a-zero-day-exploit.png / ◯ https://3d-kstudio.com/wp-content/uploads/2014/02/Project-Manager-4-AI-Asset-Manager-3D-Models-Browser-800x400.jpg | https://3d-kstudio.com/product/project-manager/ | v4.01, 2026-08 | 2014年から続く。$60 | ロシア語「менеджер ассетов」→ 名前 |
| CameraManager | 3ds Max | vsakulv(3ddd.ru) | カメラを色つきグループの帯に分け、各カメラを見本絵で並べる。ダブルクリックで切替 | ◯ https://b5.3ddd.ru/media/images/tinymce_images/34e21630fc6b99757b0150b369d6f5d6.png | https://3ddd.ru/blog/post/delius-skriptom-cameramanager-dlia-3ds-max-2024-2025 | 2026-07-21 | 2,187 閲覧、22 いいね | 3ddd.ru 内検索 |
| Buli Commander | Krita | Grum999(フランス語圏、推測) | Krita の「開く」窓の置きかえ。2画面のファイル管理+大きな見本絵 | ◯ https://krita-artists.org/uploads/default/optimized/3X/6/3/63a2b7390f79341bb5d57636637bc1f209934b88_2_1024x576.png | https://krita-artists.org/t/bulicommander/11612 | v0.9.2b。リポジトリは保存のみ(更新停止) | 掲示板で「一番」と言う人あり、有志の修正版あり | 名前で検索 |
| Searcher | Houdini | 不明 | どの操作・メニュー項目も文字で探して Enter で実行(あいまい検索) | -(取得拒否) | https://www.artstation.com/marketplace/p/Kx1v/searcher-houdini-command-pallete-add-on | 不明 | 有料 $15〜 | 「Houdini tab menu replacement」検索 |

## 6. 層・アウトライナーのまとめと折りたたみ

| 名前 | ソフト | 作者・国 | 画面の形 | 画像 | 製品URL | 最終更新 | 使われ方 | たどった道 |
|---|---|---|---|---|---|---|---|---|
| Outliner | 3ds Max | Pier Janssen(オランダ、outliner.pjanssen.nl) | 階層モードと層モード。層の入れ子、ドラッグで層移動 | -(scriptspot 取得拒否) | https://www.scriptspot.com/3ds-max/scripts/outliner | 2.1.5(2012〜2014)。更新停止 | 3ddd.ru で「標準の Layer Explorer より便利」と勧められる、polycount 多数 | 3ddd.ru のロシア語スレ「менеджер слоёв」→ scriptspot |
| Label Plugin | C4D | Florian Wagner(ドイツ語の名前、推測) | オブジェクトマネージャに目印(しおり)。大きな階層の開閉、ビューに目印を出して押すと飛ぶ | ×(宣伝の絵) https://lesterbanks.com/lxb_metal/wp-content/uploads/2017/04/New-Labels-Plugin-for-C4D-Makes-Object-Management-Easy.jpg | https://lesterbanks.com/?p=46093 | 2017 | 投げ銭 | 「Objekt-Manager Ordner einfärben」検索 |
| CameraManager | 3ds Max | vsakulv | (5 と同じ)色帯のグループで折りたたみ | ◯(5 と同じ) | 5 と同じ | 2026-07 | 5 と同じ | 5 と同じ |

## 7. タブ・サイドバーの整理

(全部 Blender。他のソフトでは見つからず)

| 名前 | 作者 | 画面の形 | 画像 | 製品URL | 使われ方 |
|---|---|---|---|---|---|
| Ultimate N-Panel Organizer | 不明 | 使わないタブを隠す、名前変え、順番、モードごとの設定 | × https://assets.superhivemarket.com/store/product/250862/image/xlarge-bf41b5c88d424a7e00595dbc7ab2bab1.png | https://superhivemarket.com/products/ultimate-n-panel-organizer | Blender 4.5+ |
| Clean Group Manager | 不明 | 複数のアドオンを1つのタブにまとめる、1つだけ表示モード | ×(機能の小アイコンだけ) https://assets.superhivemarket.com/store/product/262711/image/xlarge-46b667b6ca5695cd5430e3b2249a8ca7.png | https://superhivemarket.com/products/clean-group-manager-add-on-for-blender-4 | Blender 4.2+ |
| N-Panel SideOrder | 不明 | タブをつまんで並べかえ、ABC順ボタン、動かせないタブは暗く | × https://assets.superhivemarket.com/store/product/263600/image/xlarge-987f426b1ecde9bd975181354a05c0ef.jpg | https://superhivemarket.com/products/n-panel-sideorder | - |
| SUPERTABs | 不明 | タブとサブグループに入れ直す | - | https://superhivemarket.com/products/supertabs/faq | - |
| Simple N-Panel | Chipp Walters | キー1つで全タブの一覧メニュー | - | https://chippwalters.gumroad.com/l/rjtea | $10、Blender 5.0 対応 |
| Quick N-Panel | cveld | サイドバーを小さな検索つきメニューに置きかえ | - | https://superhivemarket.com/products/cveld-quicknpanel | - |
| Easy Filter | onion365 | チェック一覧で見せるアドオンだけ選ぶ | - | https://superhivemarket.com/products/easy-filter-onion365 | Blender 5.2.2+ |

7本が同じ悩み(アドオンでタブがあふれる)に答えている。3本見ても新しい形は出なくなった(隠す/まとめる/並べかえる/一覧で飛ぶ、の4つだけ)。

## 8. 3x3 基準点(アンカー・ピボット)グリッド

| 名前 | ソフト | 作者・国 | 画面の形 | 画像 | 製品URL | 最終更新 | 使われ方 | たどった道 |
|---|---|---|---|---|---|---|---|---|
| SpeedPivot | 3ds Max | 不明 | カーソル位置に 3x3 グリッド+高さ選び = 27 か所。子にも効く切替 | -(ArtStation 取得拒否) | https://www.artstation.com/marketplace/p/klYD9/speedpivot-v1-0-fast-pivot-control-for-3ds-max | v1.0 | 有料 | 「3ds Max pivot 3x3」検索。今回唯一の本物の 3x3 |
| MW Quick Axis Center | C4D | ddingone | Center/+X/−X… のボタン表、子も含めた箱で計算 | ◯ https://public-files.gumroad.com/e3dizqscjcnplbn67f0ur5f6hrmx | https://ddingone.gumroad.com/l/oiguhi | 不明 | 無料、評価2件。「標準が面倒だから作った」 | 「Achse zentrieren」検索 |
| Local Pivot Align | 3ds Max | EvgScripts | Min/Center/Max を選び、軸ボタンを押す | △ 動画の絵 https://i.ytimg.com/vi/Ffhix3UU90w/hqdefault.jpg | https://evgscripts.gumroad.com/l/qdtumm | Max 2025.3 で確認 | 有料 | 同上 |
| Align Pivot(スクリプト集) | 3ds Max | Kstudio | 位置入力窓+中心へ/底へ のワンクリック | - | https://scriptspot.com/3ds-max/scripts/align-pivot-set-of-scripts-to-managing-pivots | 不明 | - | 同上 |
| MagicCenter | C4D | Nitro4D | 1クリックで軸を中心へ(修飾キーで子の扱い) | - | https://lesterbanks.com/tag/cinema-4d-magic-center-plugin/ | 2013 | 無料、仏語講座 Elephorm が「必須プラグイン」に挙げる | 同上 |

## その他の置きかえ

| 名前 | ソフト | 作者 | 何を置きかえたか | 画像 | URL |
|---|---|---|---|---|---|
| Vegasaur Quick Properties / Select Events | VEGAS Pro | Vegasaur | 標準のプロパティ窓の代わりに、貼りつけられる小窓で選んだクリップをまとめて変更(「自動適用」つき) | -(サイトの絵は箱の写真だけ) | https://www.vegasaur.com/ 、v4.0 の話: https://www.vegascreativesoftware.info/us/forum/vegasaur-4-0-come-out--126860 |

## わかったこと(短く)

- 一番そろったのはパイメニュー(9本)とイーズのプリセット棚(9本)。形はどれも同じ:「曲線の絵のボタン列」と「中心の輪+まわりに8前後の項目」。
- 見本絵グリッドは 3ds Max の Kstudio が古く強い。2026年に「言葉で探す」が加わり、グリッドの下に検索欄が一本、という形。
- 3x3 グリッドそのものは SpeedPivot(3ds Max)1本だけ。他は「中心/最小/最大」ボタンの表。
- タブ整理は Blender だけで7本。悩みが一番大きい場所。
- 本家の言語の掲示板からは、ほとんど届かなかった。ドイツ語・フランス語・ロシア語で書かれた作品ページは 3ddd.ru の CameraManager と、3ddd.ru のスレで Outliner が勧められていた事実くらい。人が言語で分かれるより、売り場(Gumroad/Superhive/krita-artists)に集まっている。
