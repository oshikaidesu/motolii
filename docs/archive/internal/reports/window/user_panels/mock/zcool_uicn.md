# 中国のデザイナーによる制作アプリ UI のモック/概念デザイン 収集表（站酷・UI中国・花瓣・优设・Bilibili）

収集日: 2026-10-17（約25分）。並べ替え・評価・分類はしていない。見つけた順。

取得の事情（読む前に）:
- 站酷 (zcool.com.cn): このマシンからは検索ページも作品ページも「スライドして認証」画面になる。人間確認は解いていない。WebFetch も同じく暗号化された確認ページしか返らない（最初の1件だけ読めた）。img.zcool.cn の画像も 403。
  → 站酷の行は Bing 画像検索の結果（作品ページ URL・画像 URL・Bing の縮小画像）から作った。推荐/喜欢/收藏/浏览 の数は取れていない。
- 花瓣 (huaban.com): 「确认您是真人」のチェック画面。押していない。行は Bing 画像検索経由。
- UI中国 (ui.cn): curl は TLS 後に応答なし、WebFetch は証明書期限切れエラー。作品ページは開けていない。
- Bilibili: 検索は普通に開けた。再生数/弾幕数はそこから。
- 「確認済み」= その画像（Bing が作った同じ画像の縮小版、Bilibili は表紙そのもの）を取得して目で見て、制作系 UI が写っていると確かめたもの。「未確認」= 画像を見ていない、または UI でなかったもの。
- 証拠欄の「数値取れず」は站酷/花瓣の人間確認のため。

| # | 題名（原文） | 何を描き直したか（アプリ/部分） | デザイナー | 画像 URL | ページ URL | 証拠（推荐/喜欢/收藏/浏览） | 変わった点（一行） | 状態 |
|---|---|---|---|---|---|---|---|---|
| 1 | Redesign 之酷家乐 macOS 客户端 | 酷家乐（ブラウザ3D室内設計ソフト）の macOS 版クライアント全体、タブ・ウィンドウ操作 | westwong0622 | https://img.zcool.cn/community/01dbcd5e724436a801216518a8c1ad.png | https://www.zcool.com.cn/article/ZMTExNjEyNA==.html | 浏览 1148 / 推荐 6 / 收藏 5（WebFetch で1回だけ読めた） | 3D ソフトを「Figma 並み」にする目標、タブを Chrome 式に常に上へ。途中で「全面改修は進まない、点で直す」に方針転換したと書いている | 未確認 |
| 2 | Blender主题设计——浅灰色主题 | Blender の全画面（テーマ配色） | 给我六个包子 | https://img.zcool.cn/community/031r4frqwcbozxb17jgkme73638.png | https://www.zcool.com.cn/work/ZNjQ3Njc3ODg=.html | 数値取れず | 暗い既定の Blender を薄灰の明るい画面に塗り替えた作品。縮小画像で Blender の 3D ビュー＋右パネルが見える | 確認済み |
| 3 | blender-机器人界面 | Blender の画面そのものを 3D の立体物として描いた絵 | 深夜数字 | https://img.zcool.cn/community/01e5be6147250811013e89433d2db4.jpg | https://www.zcool.com.cn/work/ZNTUzNDQ4OTY=.html | 数値取れず | パネルやスライダーが空中に浮かぶ立体の「Blender の部屋」。UI を操作画面でなく置物として見せる | 確認済み |
| 4 | 无界云剪-在线视频编辑器-视频剪辑工具-UI设计图 | ブラウザ動画編集ソフト（タイムライン付き）の UI 一式 | 馒头see | https://img.zcool.cn/community/0312ru9ptovcokcpxmmd8bp3634.png | https://www.zcool.com.cn/work/ZNjc5OTcyNDA=.html | 数値取れず | 表紙は紫の「工具无界，创意无限」のランディング。Web・多人数協同をうたう | 確認済み（表紙はLP、編集画面は未見） |
| 5 | Keebuilder室内3D编辑器 界面设计 | 室内 3D エディタ（家具配置） | Yy_Yang | https://img.zcool.cn/community/031683259225b34a801216a3e7ef44c.jpg | https://www.zcool.com.cn/work/ZMjE5NTk0MjQ=.html | 数値取れず | 「家装也能DIY，人人都是设计师」。iMac に載せた写真調の室内ビュー＋左右に細いパネル | 確認済み |
| 6 | 《万合大师》—感受来自未来的AfterEffects | 「未来の After Effects」と題した合成画面 | 星美男VFX | https://img.zcool.cn/community/013fa357c542800000012e7e39e823.JPG | https://www.zcool.com.cn/work/ZMTc5NjM3MzY=.html | 数値取れず | 縮小画像では実写の合成カット＋右に素材パネル。AE の未来像を名乗るが実体は VFX 作品紹介の可能性 | 確認済み（UIは一部） |
| 7 | Instant Cut（快剪辑APP） | スマホ動画編集アプリ、タイムライン | 不明（站酷） | https://img.zcool.cn/community/031bnleybcnjrgevhess2gl3934.png | https://www.zcool.com.cn/work/ZNjQ2NTYxMTI=.html | 数値取れず | 手書き筆記体の「Instant Cut」と縦画面の編集トラック、2022 | 確認済み |
| 8 | 剪映 - 视频剪辑软件 | 剪映（CapCut）PC 版のホーム画面 | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/09a380ed3fe1ff7997ad1f53b9b2a4126ee78a63251822-6bUhmV_fw658 | https://huaban.com/pins/4961299699 | 数値取れず | 黒地に「开始创作」「创作工具」「团队资产管理」のカード。公式画面の収集の可能性 | 確認済み |
| 9 | 剪映专业版——轻而易剪 上演大幕 | 剪映专业版（PC）の紹介ページ | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/fc30628d79db2faf4e35ea723aea8af3d257fbad65df65-eYytUZ_fw658 | https://huaban.com/pins/3731553758 | 数値取れず | 縦長の紹介ページ。画面の切り抜きを縦に並べる | 確認済み（小さい） |
| 10 | 第778天编辑器ui设计 | 汎用エディタ（画面・設定パネル） | 不明（花瓣ピン、日課作品） | https://gd-hbimg.huaban.com/57c975d76f69c162035bfcc17d6a584c127ee1a926035-en4H25_fw658 | https://huaban.com/pins/5151273383/ | 数値取れず | 778 日目の日課。白地に右インスペクタ、中央に共同編集の招待吹き出し | 確認済み |
| 11 | 工作流设计器zailab软件科幻节点ui ux设计师工作流联络中心 | ノードエディタ（ワークフロー設計） | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/7cde6d0e54c4e9d7cdae7958b7b4c39aa3cda18e6cf2d-vuNJtN_fw658 | https://huaban.com/pins/2139462308 | 数値取れず | 「WORK FLOW DESIGNER」。暗い格子の上に四角ノードと配線、SF 調 | 確認済み |
| 12 | 科技感软件界面-UI设计 | SF 調の業務ソフト | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/816f673d6aa0011b2573c94b1b763d0ac73d629f39cdb-wU4kIb_fw658webp | https://huaban.com/pins/4082711995 | 数値取れず | 青い HUD 枠で囲った操作画面。制作ソフトではないが「軍事 HUD 風のツール画面」の型 | 確認済み |
| 13 | 科幻风格软件界面UI | SF 調ソフト画面（地球背景） | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/4e5bbb448f8aa7d2d1c7b498a0011010951833558c7a0-uYfJrC_fw658webp | https://huaban.com/pins/6119107283 | 数値取れず | 宇宙写真の上に半透明パネル。映画小道具風 | 確認済み |
| 14 | 音频控制系统软件界面设计 | 音声ミキサー（ノブ・フェーダー） | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/3e3dbb972b561f5b7c46384014858c7c237317984d2ac-J4WRfD_fw658 | https://huaban.com/pins/1936180440/ | 数値取れず | 「DIGITAL PREAMPLIFIER」。青い発光ノブを並べた機材パネル調 | 確認済み |
| 15 | 音频编辑软件的用户界面 | 音声編集ソフトの波形トラック | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/6cef6a1a941585cb5b9b38e9df5d265813907b6521c20-IXX23j_fw658 | https://huaban.com/pins/5239033311 | 数値取れず | 4 本の波形が青く発光、トラックが光の帯だけで描かれる | 確認済み |
| 16 | 音频控制系统软件界面设计-花瓣网 | 音声制御ソフトの一覧画面 | 不明（花瓣ピン、14と同系列） | https://gd-hbimg.huaban.com/6153025b30eb596c984988a43b14ddc731aad433508a3-gQzFUJ_fw658webp | https://huaban.com/pins/6366729925 | 数値取れず | 14 と同じ発光枠の表形式画面 | 確認済み |
| 17 | 音频软件界面设计 | 音声ソフト（ProMatrix） | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/53fc980a9ce827e4f094a040aa3f61270fb7fae64d140-ZlZJaj_fw658webp | https://huaban.com/pins/4168739945 | 数値取れず | マトリクス配線表を立方体アイコンで並べる | 確認済み |
| 18 | 社交媒体音频音乐剪辑作曲播放app用户界面设计ui套件素材 | 音楽編集/作曲アプリ（DAW 風）UI キット | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/b4eecd23feb9c6a85a5d9eebf27b253c4c5449e1bafbb-ANJmwA_fw658webp | https://huaban.com/pins/5402171614 | 数値取れず | スマホ縦画面に DAW の鍵盤・トラックを詰め込んだ売り物キット | 確認済み（小さい） |
| 19 | 暗色系视频剪辑特效软件APP UI界面设计 .fig素材 | 動画編集＋エフェクトアプリ | 不明（花瓣ピン、素材） | https://gd-hbimg.huaban.com/f73a1168c39373fd4bd95b6d4c538260bf95b0c1ad71b-XWzaoG_fw658 | https://huaban.com/pins/5747140999 | 数値取れず | 暗色の縦長画面一覧。.fig 素材として販売 | 確認済み（小さい） |
| 20 | 铃声剪辑界面/APP | 着信音の音声切り出しアプリ（波形） | 田小川 | https://img.zcool.cn/community/0312d3556fb54ec0000013fced78ec7.jpg | https://www.zcool.com.cn/work/ZMTU2OTQ2MDQ=.html | 数値取れず | 赤の録音ボタンと波形の切り取り範囲だけの最小編集画面 | 確認済み |
| 21 | 智能剪辑－工具类APP | 自動編集アプリ | 谢卓思 | https://img.zcool.cn/community/017d7e5c050104a80121ab5d4e5a90.jpg | https://www.zcool.com.cn/work/ZMzE4NjE4NTY=.html | 数値取れず | 縮小画像は写真フィードと再生画面。タイムラインは見えない | 確認済み（編集画面は未見） |
| 22 | H编辑器 | H5（縦スクロール Web 広告）の編集器 | 周猫 | https://img.zcool.cn/community/019b675a93b955a8012192316bc5d2.jpeg | https://www.zcool.com.cn/work/ZMjYyMzA0ODg=.html | 数値取れず | 左に素材サムネ、中央に人物の大画像、右に色パレット | 確認済み |
| 23 | 详情页编辑器编辑界面飞机稿 | EC 詳細ページの編集器（レイヤー・カラーピッカー・文字） | sunny徐 | https://img.zcool.cn/community/03186a1576a08c50000012e7ee9cced.jpg | https://www.zcool.com.cn/work/ZMTY5MjUyMTY=.html | 数値取れず | 「飞机稿」（不採用案）と自称。PS 風の縦ツールバー＋色相環を Web に移した | 確認済み |
| 24 | 医疗三维可视化软件界面设计 | 医療 3D ビューア（ボリューム表示、3 面図） | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/cd50de17f9a88faca54de347d23c5cfcd8a3759f6584c-0gr3ha_fw658webp | https://huaban.com/pins/4869757220 | 数値取れず | 中央に半透明の肝臓 3D、右に断面 3 枚。3D ソフトの 4 分割ビューの医療版 | 確認済み |
| 25 | 图片编辑界面 | 画像編集アプリ | shinnago | https://img.zcool.cn/community/01443b5781c3fc0000018c1b751dc9.jpg | https://www.zcool.com.cn/work/ZMTcxOTg3MDA=.html | 数値取れず | 縦長の一覧画像で細部は読めない | 確認済み（小さい） |
| 26 | UI界面设计科技视频彩铃剪辑5G酷炫产品分析运营迭代 | 動画着信音の編集アプリ | 鱼虾酱子画 | https://img.zcool.cn/community/01edc45f8f09e611013f31109a1532.jpg | https://www.zcool.com.cn/work/ZNDg0MjYwNDQ=.html | 数値取れず | 斜めに並べた赤基調のスマホ画面群。編集画面は小さく判別できない | 確認済み（編集部分は不明） |
| 27 | 软件界面 | 業務ソフト（ダッシュボード） | 冯伟设计师 | https://img.zcool.cn/community/013bac61247d4311013f4720557fb4.jpg | https://www.zcool.com.cn/work/ZNTQ4MDQzNzY=.html | 数値取れず | 制作ソフトではない（円グラフと表）。検索語「剪辑软件 界面」で出たので記録 | 確認済み（対象外寄り） |
| 28 | papa应用软件界面设计 | 不明（縦長） | STZHANG | https://img.zcool.cn/community/01d9b15ab3dfb1a80120be14899603.png | https://www.zcool.com.cn/work/ZMjY3Njc0ODQ=.html | 数値取れず | 縦に細い一覧で中身は読めない | 未確認 |
| 29 | 节目播出系统软件UI | 放送の番組送出ソフト（時間割＝タイムラインの親戚） | CrazeCool | https://img.zcool.cn/community/0105045677b76f6ac725ad90642c7b.jpg | https://www.zcool.com.cn/work/ZMTQ0NzA1NDg=.html | 数値取れず | 縦長の暗い画面一覧。送出表の画面は小さすぎて読めない | 確認済み（小さい） |
| 30 | 推荐最近发现的一款很棒的国产剪辑软件 | 国産動画編集ソフトの紹介（記事） | carllyn | https://img.zcool.cn/community/01b1675c94bda8a801208f8b2d6fe5.png | https://www.zcool.com.cn/article/ZOTAzNzY0.html | 数値取れず | 縮小画像に「KAMI」と書いたクリップが格子状に並ぶタイムライン、右にスマホ縦プレビュー | 確認済み（実製品） |
| 31 | 编辑器（收藏夹） | 他人の作品を集めた「编辑器」コレクション。表紙は「互动视频 SAAS编辑器」 | 収集者不明 | https://img.zcool.cn/community/011b056078392211013e87f4df84fa.jpg | https://www.zcool.com.cn/collection/ZMzk2NDA0NDQ= | 数値取れず | 表紙はノート PC に載った暗い動画編集画面（左ツール、下タイムライン）。分岐動画の編集器 | 確認済み（表紙のみ） |
| 32 | 编辑器（收藏夹） | 別の「编辑器」コレクション。表紙は「WING 设计与交互过程与分析」 | 収集者不明 | https://img.zcool.cn/community/0315046585b6319a801219c77b4091a.jpg | https://www.zcool.com.cn/collection/ZMjgxMjUxNDg= | 数値取れず | 青地に暗いエディタ画面。中身の作品群は站酷の認証で開けず | 確認済み（表紙のみ） |
| 33 | 官网及插件设计合集 | 何かのプラグイン（パネル）と公式サイト | 章三疯 | https://img.zcool.cn/community/01a46c61759d8111013f22cfdabf8b.png | https://www.zcool.com.cn/work/ZNTU5NTIxNjQ=.html | 数値取れず | 縮小画像は暗地に小さなパネルが浮くだけ。どのホストの拡張かは不明 | 確認済み（小さい） |
| 34 | OC贴图节点编辑器对应名称详解 | Octane（C4D 用レンダラ）のノードエディタ説明図 | 知乎経由（花瓣ピン） | https://gd-hbimg.huaban.com/71032cf229fdd44c90b67b7f38f32b8967d8de3f8350-JpYIvR_fw658webp | https://huaban.com/pins/5984729150 | 数値取れず | 実ソフト画面に中国語の名札を貼った図。モックではないが「ノードに母語の名前を付ける」実例 | 確認済み（実製品） |
| 35 | UI-3D虚拟会议产品 | 3D 仮想会議（3D 空間の UI） | bella艺 | https://img.zcool.cn/community/6809355e720c6kgm7ss22r5697.png | https://www.zcool.com.cn/work/ZNzE4MDc4MTI=.html | 数値取れず | 縮小画像は宇宙背景のスマホ表紙「Fox ...」で 3D 会議画面は見えない | 未確認 |
| 36 | UI设计规范编辑器 | デザイン規約の編集ツール | Rulpes | https://img.zcool.cn/community/0310c3c58e45912a801219c77406535.jpg | https://www.zcool.com.cn/work/ZMjExOTgyOTY=.html | 数値取れず | 名前のみ。デザイナー向けツールをデザイナーが作る | 未確認 |
| 37 | 印象笔记windows客户端重设计UI软件界面 | Evernote Windows 版の再設計（制作系ではないが「既存デスクトップソフトの勝手改版」の型） | WJKevin（UI中国作品の花瓣転載） | https://gd-hbimg.huaban.com/2ba49cebb5b89cc422386666dbcb15abc2deb8d6258b38-zMpeYW_fw658 | https://huaban.com/pins/4529978901 | 数値取れず | 中国のデスクトップ改版コンセプトの典型例として記録 | 未確認 |
| 38 | PC端软件产品UI界面设计 | PC ソフト画面 | 张婷婷（68Design） | https://gd-hbimg.huaban.com/b1e7e7fca550ba66543493942ef7a751236f3dcabaf49-SVv8vS_fw658 | https://huaban.com/pins/3888932330 | 数値取れず | 名前のみ | 未確認 |
| 39 | 暗色风格企业软件界面设计 | 暗色の業務ソフト | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/d37cf3e97da905a6f8b74b2f28a7a1d6df7d29cd14da40-I87tra_fw658webp | https://huaban.com/pins/5592570750 | 数値取れず | 名前のみ | 未確認 |
| 40 | 近三个月的三维UI渲染作品 | UI 部品を 3D レンダーで見せる作品群 | 凹凸男846 | https://img.zcool.cn/community/011j6nwcaadbqfoj9einil3134.jpg | https://www.zcool.com.cn/work/ZNjY5MDI2MDg=.html | 数値取れず | 名前のみ | 未確認 |
| 41 | C4D建模3D版UI界面设计优秀案例分享 | UI を C4D で立体化した事例集 | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/e0d52e1e8bd346e15ddd712b7814becf578ce0ea154b6-nnh1dP_fw658 | https://huaban.com/pins/5110631055 | 数値取れず | 名前のみ | 未確認 |
| 42 | 9款C4D立体界面设计灵感 | 同上（立体の画面） | 不明（花瓣ピン） | https://gd-hbimg.huaban.com/762932c4438d8322b303e4fbdca47657cc51bb0f1c45e-TLZ9eg_fw658webp | https://huaban.com/pins/4098316705 | 数値取れず | 名前のみ | 未確認 |
| 43 | blender主题更换+UI颜色更改 | Blender のテーマ（全画面配色） | 又又的囤货铺 | https://i0.hdslb.com/bfs/archive/3882c2eba3a328f9de4009641111dc58c3b59c62.png | https://www.bilibili.com/video/BV1aC411p7VR/ | 再生 1万 / 弾幕 1 | 紫基調に塗り替えた Blender の実画面が表紙 | 確認済み |
| 44 | 2026年你还在用默认主题？Blender界面主题推荐！ | Blender テーマ（ピンク系など） | 笨学生只能这样咯 | https://i0.hdslb.com/bfs/archive/a9e2f199f9fda166a065de8f2569913c8f91513a.jpg | https://www.bilibili.com/video/BV1aMrkBGEng/ | 再生 3373 / 弾幕 4 | ピンクと緑灰の Blender 画面を 4 分割で並べ比べる | 確認済み |
| 45 | blender自定义主题，整一套自己独一无二的配色吧，blender粉色主题，blender绿色主题 | Blender テーマ自作 | blender布的 | https://i0.hdslb.com/bfs/archive/98f2bf428f88f4894effdb1f2dcaae3ff726f501.jpg | https://www.bilibili.com/video/BV1cv411N7Fg/ | 再生 9102 / 弾幕 1 | アニメ少女の絵を 3D ビューに置いた全面ピンクの Blender | 確認済み |
| 46 | Blender界面主题如何更改？一分钟教会你用上blender的二次元皮肤！ | Blender「二次元スキン」 | 笨学生只能这样咯 | https://i0.hdslb.com/bfs/archive/bb3589f4f1b4c7f5cf08460e0ee826e8c984bd30.jpg | https://www.bilibili.com/video/BV1aMrkBGEvm/ | 再生 2748 / 弾幕 0 | 「原始主题 → 粉色主题」の左右比較 | 確認済み |
| 47 | 「 Blender主题 」 Coffee&Milk | Blender テーマ（コーヒー色と乳白） | 账号已注销（退会済み） | https://i0.hdslb.com/bfs/archive/4e58e2fb9b9abcd139b3b42d50607519aabfc4ba.jpg | https://www.bilibili.com/video/BV1dK4y1F7qE/ | 再生 2162 / 弾幕 0 | 暗い茶と白い乳色の 2 テーマを筆記体ロゴ付きで見せる。ノード/グラフ画面も同色 | 確認済み |
| 48 | 【BLT更新】Blender界面美化！新增主题类资产(支持共享界面主题和启动图) | Blender のテーマ＋起動画像を「資産」として配る仕組み | 只剩一瓶辣椒酱 | https://i0.hdslb.com/bfs/archive/c2e1a2fa1bfc3378350b8d5c970c08143745f135.jpg | https://www.bilibili.com/video/BV1gq4y1d7VB/ | 再生 2.8万 / 弾幕 6 | テーマを素材ライブラリの 1 種類にする。表紙は猫耳キャラ＋暗い Blender 画面 | 確認済み |
| 49 | 动画《记忆管理局》剧中UI 概念•动效•音效设计 | アニメ劇中の架空ソフト UI（動き・効果音まで） | 记忆管理局 | https://i0.hdslb.com/bfs/archive/2b1dd468987e19bfeec397560fc5ca1d6e94b947.jpg | https://www.bilibili.com/video/BV12Jad6UEHs/ | 再生 10.1万 / 弾幕 134 | 作中の架空ツール画面を音まで設計。站酷にも同題の作品（ZNzQyNDkyNDg）あり。表紙は地図と赤い警告帯 | 確認済み |
| 50 | 记忆管理局 剧中UI｜动画UI美术概念・动效・音效设计（站酷版） | 49 と同じ作品の站酷投稿 | 记忆管理局 | （画像 URL 取れず） | https://www.zcool.com.cn/work/ZNzQyNDkyNDg=.html | 数値取れず（站酷の「相关推荐」に出た） | 49 の站酷側 | 未確認 |
| 51 | 为了不再剪视频，我做了这个... | 動画編集を不要にする自作ツール（動くもの） | riverisbuilding | https://i0.hdslb.com/bfs/archive/8d97ab48b297584ac7b1c8d08791763fa6b3cf03.jpg | Bilibili 検索「我设计了一个剪辑软件 界面」の結果（動画リンクは広告枠で取れず） | 再生 1536 / 弾幕 0 | 表紙は本人＋「做视频只管许愿」とアプリアイコン群。モックではなく実働ツール | 確認済み（UIでなく表紙） |
| 52 | 鸿蒙 NEXT，但是 PC 端 \| 鸿蒙 OS 电脑版概念宣传片 | OS（鸿蒙）の PC 版を想像した概念映像 | 戌犬朱狼_Lipus | https://i0.hdslb.com/bfs/archive/6b6491504b59ef03ac21466ff0fc28ad34687eb5.jpg | https://www.bilibili.com/video/BV1Z19AY7EAF/ | 再生 11.8万 / 弾幕 131 | 制作アプリでなく OS の概念映像。「存在しない PC 画面を映像で見せる」文化の例。表紙は「HarmonyOS NEXT PC / CONCEPT / LIPUS STUDIO」 | 確認済み（表紙） |
| 53 | 2024版Windows7概念设计宣传片 | Windows 7 の架空新版 | Windows动态 | https://i0.hdslb.com/bfs/archive/4cf7e949da47e5fd587a0d3f10ce66fbcf79b47b.jpg | https://www.bilibili.com/video/BV1dT4m1S75y/ | 再生 20.5万 / 弾幕 691 | 同上。OS 概念映像が数十万再生を集める | 未確認 |
| 54 | 剪辑家电影APP界面设计 | 映画/編集系アプリ | DPOOL | （画像 URL 取れず） | https://www.zcool.com.cn/work/ZMTgyMTY2Mjg=.html | 数値取れず（WebSearch で発見） | 名前のみ | 未確認 |
| 55 | 剪映capcut专业版5.9官方免费版自动生成字幕版 | 剪映专业版（作品欄に置かれた配布告知） | 朋友仔工作室 | （画像 URL 取れず） | https://www.zcool.com.cn/work/ZNzA2MTQyMTI=.html | 数値取れず | 作品欄なのに中身は配布告知。モックではない | 未確認 |
| 56 | 互动视频 SAAS编辑器（31 の表紙作品） | 分岐動画（インタラクティブ動画）編集器 | 不明 | 31 と同じ表紙画像 | 31 のコレクション内（個別ページは認証で開けず） | 数値取れず | 「互动视频 SAAS 编辑器」。下にタイムライン、左に縦ツール、紫の光の玉の背景 | 確認済み（表紙のみ） |
| 57 | UI界面-AE动效 | AE で作った UI 動き（AE 自体ではない） | 威哥94666 | （未取得） | https://www.zcool.com.cn/work/ZMjE3MzIwNjg=.html | 数値取れず | 検索語「AE 界面 重设计」で出た。AE の画面ではない | 未確認 |
| 58 | 视频会议中控界面设计ui | 会議室の映像中央制御パネル | 不明（花瓣ピン） | （未取得） | https://huaban.com/pins/4185848524 | 数値取れず | 映像ルーティング（マトリクス）を触る画面 | 未確認 |
</content>
</invoke>
| 59 | 【AE界面美化】如何改AE界面文字+数字颜色 | After Effects の画面の文字・数値の色（公式に無い着せ替え） | 猫汰シヤケ | https://i0.hdslb.com/bfs/archive/15c1a417be32f70bcc8d49549548d6542b548f8f.jpg | https://www.bilibili.com/video/BV1io4y1k71P/ | 再生 1.3万 / 弾幕 1 | AE のパネル文字をピンクに発光させ、背後にアニメ絵。AE を「着せ替える」 | 確認済み |
| 60 | 【碎碎念】如何在新版C4D上切换回旧版UI布局 | C4D の新旧ツールバー配置 | 米夏小雨 | https://i0.hdslb.com/bfs/archive/f790199e7ee96a3623ea4f1066c5154258634831.jpg | https://www.bilibili.com/video/BV1P34y1H7wq/ | 再生 1.2万 / 弾幕 1 | 新版 UI を拒んで旧版に戻す。表紙は C4D ツールバーを何段も重ねた比較 | 確認済み（実製品） |
| 61 | C4D2023界面设置指南：界面必须这么设置，否则根本没法用！C4D启动界面设置 | C4D 2023 の画面配置 | 好奇漫步 | https://i0.hdslb.com/bfs/archive/6b1e559aeae1c72c5244231f4583f8e0af9050be.jpg | https://www.bilibili.com/video/BV1kV41157BV/ | 再生 4.4万 / 弾幕 11 | 「こう設定しないと使えない」と断言する配置の処方箋。既定 UI への不満の証拠 | 確認済み（実製品） |
| 62 | 告别丑陋默认界面!TurboWarp美化教程换肤+必装插件 | TurboWarp（Scratch 系ブロック編集器）の着せ替え | SilvusEvans | https://i0.hdslb.com/bfs/archive/e7406371ee5771fc9f77639d52ec7c8baeaf0c56.jpg | https://www.bilibili.com/video/BV1KJhK6kEG3/ | 再生 2.3万 / 弾幕 5 | BEFORE/AFTER で白い既定画面を暗いネオン＋猫絵に。ブロック編集器も「醜い既定」と呼ばれる | 確認済み |
| 63 | 【UI交互动画】简约画面+流畅动效‼️软件宣传片很吸睛 | AI 動画生成ツールの画面を使った宣伝アニメ | 创意者视觉动画 | https://i0.hdslb.com/bfs/archive/2dd4c1be95dad4de5271af0cd1a11556c838dd88.jpg | https://www.bilibili.com/video/BV1dxpy6kEvD/ | 再生 143 / 弾幕 0 | 表紙は「Every idea has a film in it.」の一行入力欄だけの動画ツール画面。タイムラインの無い編集 UI | 確認済み |
| 64 | 请选出你的超大杯主题界面！我是选不出来了 | （ゲーム/アプリの）テーマ画面の選択 | 精致鸭鸭kiki | https://i0.hdslb.com/bfs/archive/4668be2618e85c96f2f886fa86c1fe7f744503d0.jpg | https://www.bilibili.com/video/BV1MEad6nEPk/ | 再生 11.2万 / 弾幕 86 | 制作アプリではない。「テーマ界面」を選ぶこと自体が娯楽になっている例として記録 | 未確認 |
