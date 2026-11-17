# 本体の UI の一部を「置き換える」自前パネル（英・露・西・葡の圏）

調べた日: 2026-10-17。ウェブのみ、読むだけ（ログインなし、何も入れていない）。

**集めたもの**: 本体の画面のどこか（グラフエディタ、タイムライン、層の一覧、アウトライナー、モディファイア欄、N パネル、メニュー、チャンネル欄）に不満があり、その場所を**別の形で描き直した**パネル。押せば終わるボタン棚（KBar 型）や一発スクリプトは外した（2 回目の指示どおり）。
**集め方**: 「instead of the graph editor」「alternative to the outliner」「replaces」「вместо стандартного」「melhor que o nativo」などの比べる言葉で探し、製品ページ（Superhive、Blender 公式の拡張サイト、GitHub、Gumroad、作者のサイト）まで行って画像の URL を取った。

## 先に断っておくこと

- **画像は一枚も目で見ていない**（「ダウンロードしない」の決まりのため）。どの画像かは、ページの説明文・alt・ファイル名・置き場所から選んだ。「主画像」は商品の一枚目で、パネルが写っているかは分からない。
- **aescripts.com と gregbenzphotography.com は読めない**（403）。Flow（AE）、Hierarchy editor、Lumenzia 本家の画像は取れていない。
- 西語・葡語の比べる言葉では、当たりがなかった。露語では Tabs Interface（roaoao）が当たった。作者の国が分かるのは数人だけ（「言語」の欄。推定は「推定」と書いた）。

---

## 1. グラフエディタの代わりに「触る 1 本の曲線」（Flow 型）

本家は AE の Flow。**Blender で少なくとも 5 人が同じ形を作り直している**のがいちばんはっきりした発見。

| 名前 | ホスト | 作者 | 何を置き換える | パネル画像 | ページ | 更新 |
|---|---|---|---|---|---|---|
| Flow | AE | Zack Lovatt / Rendertom | グラフエディタ → 曲線 1 本＋プリセットの棚（間の仕切りは引っぱれる） | aescripts のため取れず | https://aescripts.com/flow/ ／紹介 https://motionarray.com/learn/after-effects/flow-after-effects-extension-review/ | — |
| Flow - Animation Curve Editor | Blender | Superhive の出品者 | 同じ（「AE 風のイージングを Blender に」と紹介文） | 主画像 https://assets.superhivemarket.com/store/product/254109/image/xlarge-e406f838101e2cb64a7e13b8ac62b274.jpg 、ほか https://assets.superhivemarket.com/store/productimage/1225163/image/xlarge-1e5dc13163a7535e6fecdf0fc5fdc958.jpg | https://superhivemarket.com/products/flow---animation-curve-editor | Blender 5.0 以降 |
| Zeeks Flow | Blender | Zeek | グラフエディタの上に 3 次ベジェの曲線を重ねて描く（「AE の Flow から」と明記） | https://extensions.blender.org/media/images/78/78a81a6620929bb85c26e47b49d3be7b1a6fa28430025cded4263633fa368d1b.png （一枚目）、https://extensions.blender.org//media/thumbnails/72/72306d4cbfc6dc46d99f75f72fd09ef5cf4488566a1155b42288f2666a99eb0c_1920x1080.webp | https://extensions.blender.org/add-ons/zeeks-flow/ | Blender 4.2 以降、無料 |
| 無料の Flow 風アドオン（80.lv の記事） | Blender | — | 同じ | 記事の表紙 https://cdn.80.lv/api/upload/meta/47550/images/69cd005e129ef/contain_1200x630.jpg | https://80.lv/articles/free-blender-add-on-inspired-by-after-effects-flow | — |
| Graphi / Graphi Pro | Blender | — | 横の欄に曲線エディタ、黄色い取っ手を引く | https://assets.superhivemarket.com/cache/6d58e5cb0afe452ebe3ce8435ae2bfdb.gif （主画像の動く絵）、https://assets.superhivemarket.com/store/productimage/1261825/image/xlarge-ca4186d247400ad0e76445d9d3db8df0.png | https://superhivemarket.com/products/graphi | — |
| Bezier Curve Editor | Blender | IcedDog | タイムラインからイージングを編集 | 未取得 | （検索の要約のみ） | 無料 |
| Relative Ease | Blender | Fede Parodi | 曲線ではなく「効き具合」の滑り棒 | 表紙 https://public-files.gumroad.com/bbi9fsn5vrmeov73h7not8f17wmy | https://fedeparodi.gumroad.com/l/relative-ease | — |
| AnimAide | Blender | aresdevo | グラフエディタ横の欄にイーズの道具 | 未取得 | https://www.blendernation.com/2019/07/31/animaide-free-add-on-for-blender-2-80-to-manipulate-keys-on-an-fcurve/ | 3.6 まで。開発停止 |
| Ease and Wizz | AE | Ian Haigh | イーズの種類をパネルで選ぶ（式で動く） | 未取得 | https://www.provideocoalition.com/ease_and_wizz/ | 古い |

紹介文の言葉: Flow の曲線は「AE のグラフエディタに似ているが、いくつか大事な点が良くなっている」（Motion Array の紹介記事）。

## 2. AE の中に別のタイムライン（Railcut 型）

| 名前 | ホスト | 作者 | 何を置き換える | パネル画像 | ページ | 更新 |
|---|---|---|---|---|---|---|
| Railcut | AE | Jake Bartlett（Jake In Motion） | AE のタイムライン → Premiere 風の段ごとの切り貼り。AE が正本のまま、編集は AE の操作に直して戻す | https://docs.jakeinmotion.com/images/timeline-overview.png （説明書「The Timeline」の頁の図）、製品頁の絵 https://kajabi-storefronts-production.kajabi-cdn.com/kajabi-storefronts-production/file-uploads/sites/2147716500/images/fb006d004e5b7117d1b7423f6f608b0d.png | https://jakeinmotion.com/railcut ／説明書 https://docs.jakeinmotion.com/railcut/ | v1.1.0（2026-05-11） |

同じ形の作り直しは見つからなかった（時間内）。

## 3. AE の層の一覧で「まとめて畳む」（プリコンポの代わり）

Adobe には 2022 年から「タイムラインにフォルダを」という要望（113 件の書き込み）があり、まだ入っていない。そのため作り直しが多い。

| 名前 | 作者 | やり方 | パネル画像 | ページ | 更新 |
|---|---|---|---|---|---|
| Hierarchy editor | aescripts | タイムラインを親子の木に描き直す | 取れず | aescripts（403） | — |
| Layers Pane Plus | dony（donyaep） | 層の一覧の別版（層づくり・並べ・分け・親子付け） | 表紙 https://public-files.gumroad.com/g1jdanwxqjn9kfxfqzfknr181ns7 | https://donyaep.gumroad.com/l/ianbo | v3.1.0（2025-08-15） |
| Layer Groups | — | 層はそのまま、まとめて隠す/出す、焼く/戻すボタン | 取れず | https://lesterbanks.com/2016/06/layer-groups-management-effects/ | 2021 に販売終了の書き込み |
| Layer Manager / Layer Storage | Tony Pinkevych | まとまりをパネルに保存、隠す・単独・孤立 | 取れず | （紹介記事のみ） | — |
| Layer Manager 3 | — | 大量の層を一発で表示・非表示 | 取れず | — | — |
| Dugr | Rainbox（Duduf, 仏） | タグでまとめ、パネルに一覧 | **頁は賭博広告に乗っ取られている。開かないこと**（rainboxprod.coop） | — | — |
| Free Compose / Zorro / Workflower 2 | aescripts | ヌルと空シェイプで囲む／タグ／まとめ＋層道具 | 取れず | aescripts（403） | — |
| GM FoldLayers | — | プラグイン、タイムライン上で開閉。Adobe の要望スレで一番名前が出る | 取れず | https://community.adobe.com/t5/idea-after-effects/folders-in-after-effects-timeline/idi-p/13229562 | — |

## 4. Blender のアウトライナー・モディファイア欄・N パネルの置き換え

| 名前 | 何を置き換える | 作者 | 言語 | パネル画像 | ページ | 更新 |
|---|---|---|---|---|---|---|
| Modifier List | モディファイアの縦積み → 一覧＋選んだ 1 つだけ設定を出す。検索とお気に入り | Symstract | 英 | https://github.com/Symstract/modifier_list/blob/master/properties_editor_and_sidebar.png 、…/popup.png | https://github.com/Symstract/modifier_list | 2023-06-07、星 318 |
| Modifier Stack Manager | モディファイアの縦積み → 一覧（UI List） | — | 英 | https://extensions.blender.org/media/images/c2/c28eb058f8e6e7cf284008bfa9954cab7ff93d7ae2c2e25c74d7d18c92dd234e.png （一枚目） | https://extensions.blender.org/add-ons/modifer-stack-manager/ | 1.4.0（4.2 以降） |
| （本家の検討） | 同じ「上に一覧、下に設定」の案 | Blender 開発者 | 英 | — | https://projects.blender.org/blender/blender/issues/111538 | — |
| Tabs Interface | 画面全部のパネル → 順番固定のタブ | roaoao | 露（推定） | https://blenderartists.org/uploads/default/original/4X/b/2/7/b277e0d1fae7ba105b6d03e603c55efe2f52b59d.png （投稿の絵）、表紙 https://public-files.gumroad.com/84fllk65hwcwvecvk8o6n29wijjj | https://roaoao.gumroad.com/l/addon_tabs ／ https://blenderartists.org/t/blender-tabs-interface-clean-and-fast-blender-ui/682512 | 4.0 で確認済み。露語の紹介 https://vk.ru/@h360ru-interfeis-blender-top-2021 |
| N-Panel SideOrder | N パネルのタブを引っぱって並べ替え（本体がタブの位置を教えないので自分で上に描く） | — | 英 | 主画像 https://assets.superhivemarket.com/store/product/263600/image/xlarge-987f426b1ecde9bd975181354a05c0ef.jpg 、https://assets.superhivemarket.com/cache/0afa7a9bba0a84f905fbed017f2d22b7.webp | https://superhivemarket.com/products/n-panel-sideorder | 1.0.0 |
| N-Panels Pro | タブの名前替え・並べ替え・まとめ・検索 | — | 英 | 主画像 https://assets.superhivemarket.com/store/product/248422/image/xlarge-ee666e0e31e7872805f1a4f588d7c245.jpg 、動く絵 https://assets.superhivemarket.com/store/productimage/1154845/image/xlarge-26ebfd0ac649a3a4637cf0f0da600ee0.gif | https://superhivemarket.com/products/n-panels-pro---quick-re-order-groups--serch | — |
| N-Panel Tabs | 縦のタブ → 見出しの 1 つの選択肢 | — | 英 | 主画像 https://assets.superhivemarket.com/store/product/254222/image/xlarge-7e888812f3e1f97d2556d736f0e834c3.png 、https://assets.superhivemarket.com/cache/ce23fac5eb763a132f432c423c4b7500.gif | https://superhivemarket.com/products/n-panel-tabs | — |
| Quick Sidebar Switcher | タブ → 呼び出す小窓 | — | 英 | https://extensions.blender.org/media/images/e7/e70ae216b6008d92334919f8046aa24f06c407421c7e155ebbf8cea6c539a829.png 、「Add-on in action」 https://extensions.blender.org/media/thumbnails/e0/e05bc18650d79cc95b018aa4eb52955f2e280fbb1c82735b8a81a0be80e67617_640x360.webp | https://extensions.blender.org/add-ons/quick-sidebar-switcher/ | 1.4.0（2026-06） |
| Addon Board | N パネルのタブ → 別の画面（板）に移す | — | 英 | 主画像 https://assets.superhivemarket.com/store/product/265193/image/xlarge-031420a0841f6d623766585b012093a4.jpg | https://superhivemarket.com/products/addon-board | — |
| Clean Panels | 散らかった N パネルを整理 | — | 英 | https://assets.superhivemarket.com/cache/57612279a94d5c8d6a6dbc939ec1d307.gif （内容未確認） | https://superhivemarket.com/products/clean-panels | 93 人で星 5、レビュー「N パネル問題の答え」 |
| Simple N-Panel | タブ → A〜Z の小窓（♥ ボタン） | Chipp Walters | 英 | 未取得 | https://chippwalters.gumroad.com/l/rjtea | 5.0 まで |
| Outliner Pro | アウトライナーに整理の道具 | — | 英 | 主画像 https://assets.superhivemarket.com/store/product/222258/image/xlarge-9e1b6227d39cef167ee916c0fc0c388c.png | https://superhivemarket.com/products/outliner-pro | — |

メモ: N パネルの「タブが多すぎる」は 8 人が別々に解いている。やり方は 4 つ: 並べ替え／ひとつのタブにまとめる／小窓で呼ぶ／別の画面に移す。

## 5. メニューの代わりに「押している間だけ出る丸いメニュー」

Maya のホットボックスの形を、ほかのソフトの人たちが作り直している。いちばん広く作り直されている形。

| 名前 | ホスト | 作者 | 言語 | パネル画像 | ページ | 更新 |
|---|---|---|---|---|---|---|
| Pie Menu Editor（PME） | Blender | roaoao | 露（推定） | 主画像 https://assets.superhivemarket.com/store/product/70990/image/original-360a02bf5a387b0f7a9a9a423b87d387.png | https://superhivemarket.com/products/pie-menu-editor | v1.18.8 |
| MACHIN3tools | Blender | MACHIN3 | 英 | 公式頁に絵なし | https://machin3.io/MACHIN3tools/ | 1.12 |
| Pies Plus | Blender | razed | 英 | 表紙 https://public-files.gumroad.com/1ovflwh3dl3y6f7r4n9ohixvddnv | https://razed.gumroad.com/l/piesplus | — |
| PieMaster | Blender | BlenderArtists の投稿者 | 英 | https://blenderartists.org/uploads/default/optimized/4X/6/f/b/6fb9b863ec77f51cd405c4ccf059ed0567f3bdfa_2_1380x776.png | https://blenderartists.org/t/piemaster-addon/1640056 | 2026 |
| N-Panel Pie Menu | Blender | SpaceForceTeam | 英 | 主画像 https://assets.superhivemarket.com/store/product/265089/image/xlarge-06b6ba4c886b1bdc5bf5c49fe6afef3b.png | https://superhivemarket.com/products/n-panel-pie-menu | 3 週間前に公開 |
| Sculpt Pro Pie | Blender | ZA Studio | 英 | 「Hexagon layout」 https://assets.superhivemarket.com/cache/69224922fa53845970f8f9aa4db156f1.gif 、「Horizon」 https://assets.superhivemarket.com/cache/375fdb5f3163928c894d7af2241e8c41.gif | https://superhivemarket.com/products/sculpt-pro-pie | 3 か月前に公開 |
| Quick Pie & Favorites | Blender | — | 英 | 主画像 https://assets.superhivemarket.com/store/product/250280/image/xlarge-c167a918801cac3cb24c585c532bc71b.jpg | https://superhivemarket.com/products/quick-pie--favorites | — |
| wxz_pie_menus | Blender | xz-blender | 英 | https://github.com/xz-blender/wxz_pie_menus/blob/main/docs/readme/context-menu.gif | https://github.com/xz-blender/wxz_pie_menus | 2026-10-15 |
| AK_Pies | Blender | voodraizer | 露（推定） | なし | https://github.com/voodraizer/AK_Pies | 2024-09-16 |
| select-mode-pie | Blender | lucasfalcao3d | 葡（推定） | https://pictshare.net/30hnt7.png | https://github.com/lucasfalcao3d/select-mode-pie | 2019 |
| Wazou's pie menus | Blender | Wazou | 仏 | 未取得 | 露語の紹介記事に名前（Shift+S の代わり） | — |
| W_hotbox | Nuke | Wouter Gilsing | 英（蘭） | 「Merge を選んだ時」 http://www.nukepedia.com/images/users/WouterGilsing/introHotbox.png 、管理画面 http://www.nukepedia.com/images/users/WouterGilsing/manager_new.png | https://github.com/melmass/w_hotbox （本家は Nukepedia） | — |
| nth_Hotbox | Nuke | Nacho Igea | 西（推定） | 未取得 | https://www.nukepedia.com/python/ui/nth_hotbox | — |
| MWBP_MergeBox | Nuke | mattwbp | 英 | なし | https://github.com/mattwbp/MWBP_MergeBox | 2020 |
| hydra-renderers-radial-menu | Houdini | alexmajewski | 英 | https://github.com/user-attachments/assets/c2714771-5136-49e1-ac8d-2c7ab6b1ce17 | https://github.com/alexmajewski/hydra-renderers-radial-menu | 2025-03 |
| houdini_radial_menu | Houdini | EduardoJReyes | 西（推定） | なし | https://github.com/EduardoJReyes/houdini_radial_menu | 2026-02 |

メモ: 新しい Blender のパイ（N-Panel Pie、Sculpt Pro Pie）は本体のパイを使わず GPU で自分で描く。紹介文には「本体のパイより整った今風の見た目」とある。形も六角形や横一列が出てきて、円をやめ始めている。

## 6. 骨の名前の一覧の代わりに「体の絵から選ぶ」（リグのピッカー）

| 名前 | ホスト | 作者 | 言語 | パネル画像 | ページ | 更新 |
|---|---|---|---|---|---|---|
| dwpicker | Maya | Lionel Brouyère, Olivier Evers（DreamWall） | 英 | https://github.com/DreamWall-Animation/dwpicker/blob/main/screenshots/picker.gif 、同じ場所の editor.gif と createbuttons.gif | https://github.com/DreamWall-Animation/dwpicker | 2026-04-02、星 257 |
| picker | Maya | Alexander Zagoruyko | 露（推定） | https://user-images.githubusercontent.com/9614751/226429549-0582ae4a-92db-4aa0-a97c-8719848fdd07.png | https://github.com/azagoruyko/picker | 2025-08-10。ボタンの形を SVG で描ける |
| AD_Selector | Maya | artdanylov | 露または宇（推定） | https://github.com/artdanylov/AD_Selector/blob/main/screenshots/ads_1.png | https://github.com/artdanylov/AD_Selector | 2025-02-10 |
| martopicker | Maya | thornydre | 英 | なし | https://github.com/thornydre/martopicker | 2024-02 |
| MG-Picker Studio | Maya | Miguel Winfield | 英 | 公式サイトの証明書が壊れていて読めず | https://www.cgchannel.com/?p=73017 | — |
| AnimSchool Picker | Maya | AnimSchool | 英 | 未取得 | https://store.animschool.edu/animschool-picker/ | — |
| SearchNPick | Maya | — | 英 | 未取得 | https://www.cgtrader.com/3d-models/scripts-plugins/animation/searchnpick | ボタンの縁・角の丸み・押した時の色まで変えられる |
| Pickify | Maya | Ehsan Bayat | 英 | 未取得 | https://anim.works/?p=19349 | 紹介「最小限で今風、開いたまま作業できる」 |
| Animation Picker | Blender | StraySpark | 英 | 未取得 | https://www.strayspark.studio/docs/animation-picker | 1.0.0。Rigify と Auto-Rig Pro を読み取って自動で作る |
| Gampil Picker | Blender | — | 英 | 主画像 https://assets.superhivemarket.com/store/product/262105/image/xlarge-fb5a874783059ec3320e97bb99b3b011.png | https://superhivemarket.com/products/gampil-picker | 履歴あり |
| Flexi Picker | Blender | — | 英 | 主画像 https://assets.superhivemarket.com/store/product/243819/image/xlarge-6695a318524de7443edbab2f4b3a9480.png | https://superhivemarket.com/products/flexi-picker--smart-selection--layer-manager-for-blender | — |
| rig_picker | Blender | Autour de Minuit | 仏 | 未取得 | https://git.autourdeminuit.com/autour_de_minuit/rig_picker/src/branch/blender3.6 | 2022〜23 |

メモ: 12 本すべてが「人の形の絵の上にボタン」という同じ形に行き着いている。

## 7. Maya のチャンネル欄の置き換え

| 名前 | 作者 | 何を置き換える | パネル画像 | ページ | 更新 |
|---|---|---|---|---|---|
| Channel Box Plus | Robert Joosten | チャンネル欄に検索と、自分で足した項目の色分け | https://github.com/robertjoosten/maya-channel-box-plus/blob/master/docs/_images/channel-box-plus-example.gif | https://github.com/robertjoosten/maya-channel-box-plus | 2022-01、星 21 |
| sm_solo | smannimation | チャンネルのソロ | 未取得 | https://smannimation.gumroad.com/l/ppzMA | — |
| Modular channel box | Vii（Polycount） | 自分で組めるチャンネル欄 | 未取得 | https://polycount.com/discussion/comment/2806987 | 試験中 |

## 8. Photoshop: チャンネルのメニューの代わりに輝度マスクのパネル

| 名前 | 作者 | 何を置き換える | パネル画像 | ページ |
|---|---|---|---|---|
| Lumenzia | Greg Benz | チャンネルからの手作業 → 暗部・中間・明部の 3 列のボタン（D/M/L の 1〜6）、ゾーン地図 | 紹介記事の図 https://improvephotography.com/wp-content/uploads/2016/11/screen-6.jpg （2016 年の記事なので古い版） | https://gregbenzphotography.com/lumenzia-v7-luminosity-masking-panel-for-photoshop （403） |
| Basic V6（TK の軽い版） | Tony Kuyper / goodlight | 同じ問題を別の並べ方で | https://goodlight.us/writing/basic-v6-panel/images/Basic-V6-base-panel.png （ファイル名が「base panel」） | https://goodlight.us/writing/basic-v6-panel/basic-v6.html |
| TK8 | Tony Kuyper | 同じ | 未取得（サイトの応答なし） | https://tkactions.com/ |
| Raya Pro / Easy Panel / Lumi32 | Jimmy McIntyre | 同じ | 未取得 | — |
| ARCPanel | 掲示板の利用者 | TK・Lumenzia・Raya より簡単にと作った | 未取得 | https://community.naturephotographers.network/t/luminosity-masking-panels/6841 |

紹介の言葉: Lumenzia のボタンは「どの明るさの幅を選ぶか、見てすぐ分かる」（Digital Photography School の紹介）。TK8 は「評判は高いが覚えるのが大変」（dpreview 掲示板）。

## 9. ほか（本体の欄を置き換えるもの）

| 名前 | ホスト | 作者 | 何を置き換える | パネル画像 | ページ | 更新 |
|---|---|---|---|---|---|---|
| KnobScripter | Nuke | Adrian Pueyo（西） | 本体のスクリプト編集欄 | https://user-images.githubusercontent.com/24983260/165090431-b179f3a0-8e22-4e92-b544-5d6f10e677fc.png | https://github.com/adrianpueyo/KnobScripter | 2026-03-23 |
| Stamps | Nuke | Adrian Pueyo（西） | ノード同士の長い線 → 名札で離れてつなぐ | https://github.com/adrianpueyo/Stamps/blob/master/stamps/stamps.png | https://github.com/adrianpueyo/Stamps | 2026-03-23 |
| Studio Library | Maya | Kurt Rathjen | ポーズの保存・呼び出しを、絵の並んだ棚に | https://github.com/krathjen/studiolibrary/blob/main/install.gif | https://github.com/krathjen/studiolibrary | 2026-09-23、星 401 |
| MOGRT customizer | Premiere | Atom X | Premiere 2025 で消えた「エッセンシャルグラフィックス」欄の代わり（利用者は消えたことに「ひどい変更」と怒っている） | 未取得 | https://dev.get-atomx.com/docs/en/customizer-pr | — |

---

## 外したもの（1 回目の表にあったもの）

アンカー 9 方向、KBar 型の起動棚（MoBar ほか）、FX Console 型の検索、色見本、文字分け、字幕（AutoSubs）。どれも押せば終わる道具で、本体の欄の置き換えではないため。

## 数のまとめ

| 置き換える場所 | 作り直した作者の数 | 画像が取れた数 |
|---|---|---|
| 丸いメニュー（Blender・Nuke・Houdini） | 16 | 10 |
| リグのピッカー（Maya・Blender） | 12 | 5 |
| N パネル・モディファイア欄・アウトライナー（Blender） | 12 | 11 |
| 曲線 1 本でイージング（AE・Blender） | 9（うち Blender 7） | 5 |
| AE の層の一覧で畳む | 10 | 0（表紙 1） |
| 輝度マスク（Photoshop） | 5 | 2 |
| チャンネル欄（Maya） | 3 | 1 |
| AE の中の別タイムライン | 1（Railcut） | 2 |

まだのこと: 画像を目で見ること。aescripts の各頁（Flow、Hierarchy editor）。Railcut と同じ形のほかの作り直し。西語・葡語の比べる言葉では当たりがなかったこと。
