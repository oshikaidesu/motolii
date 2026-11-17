# アニメ・MV・VTuber 制作の自作パネル（日本以外：中国・台湾・韓国）

調べた日: 2026-10-17。約25分。見たのは「標準の画面に不満で、その一部を置き換えたパネル」。
探した場所: Bilibili 検索（ブラウザ1タブ）、知乎、GitHub（少しだけ）、Web 検索。
入れなかった所: Naver（ブラウザで開けない）、知乎の一部（403）、Bilibili の動画情報API（弾かれた）。
このため 韓国・台湾 はほぼ取れていない。中国（Bilibili / GitHub）が中心。

記号: 画=表紙画像を自分の目で見てパネルが写っていると確認済み。 未=画像未確認。
「汉化」=海外製の中国語訳（置き換えた人は別）。中国オリジナルと分けて書く。

## 1. ことばの表（各コミュニティが使う呼び名）

| 意味 | 中国語（簡体） | 台湾（繁体） | 韓国語 |
|---|---|---|---|
| イージング板 | 缓动面板、缓动曲线、缓入缓出、关键帧缓动、速度曲线 | 緩動、緩入緩出、速度曲線 | 이징 패널、이징 커브、키프레임 이징 |
| パイメニュー | 饼菜单、饼状菜单、自由饼菜单、智能饼菜单 | 圓餅選單、環形選單 | 파이 메뉴、파이메뉴 |
| リグ選び | 骨骼选择器、控制器、表情面板、拾取器 | 骨架選擇器 | 리그 피커、본 선택 |
| 色棚 | 色板、色卡、配色板、调色板 | 色票、調色盤 | 팔레트、컬러세트、색상 세트 |
| 検索・サムネ一覧 | 快寻、快捷搜索、脚本管理器、网格模式 | 搜尋、腳本管理 | 검색、썸네일 |
| レイヤーのまとめ | 图层分组、图层筛选、折叠、标签颜色 | 圖層群組、圖層篩選 | 레이어 그룹、레이어 정리 |
| パネル整理 | N面板管理、面板整合、侧栏精简、工具箱、工作台 | 面板整理、工具列 | 패널 정리、툴바 |
| 3x3 アンカー | 锚点、九宫格、锚点面板 | 錨點、九宮格 | 앵커 포인트、기준점 |
| 「代わりに」を示す語 | 代替自带、平替、替代、自制、自用、免费分享、国产脚本 | 外掛、自製、取代內建 | 직접 만든、무료 배포、대체 |
| 配る場所 | B站视频简介/网盘、飞书文档、GitHub | 巴哈姆特、FB社團 | 네이버 블로그、포스타입、클립 스튜디오 ASSETS |

## 2. 機能ごとの表

### 2-1. イージング板（グラフエディタの代わり）

| 名前 | ホスト | 作者 / 国 | 画像 | ページ | 更新 | 使われ方 | 来た道 |
|---|---|---|---|---|---|---|---|
| 关键帧缓动AE脚本 | AE | AE脚本大师 / 中国 | 未 https://i1.hdslb.com/bfs/archive/12c360953ea9297e4e1c60f898b8cd19b7a21db0.jpg | https://www.bilibili.com/video/BV1TUJD63Etc/ | 2026-10 | 再生2（出たばかり） | B站「AE缓动脚本 自制」 |
| Binzii_FastEase!（再生ヘッド位置で山を動かす、25/50/75/100%ボタン） | AE | Binzii / 国不明（Booth・Payhip） | 未 | https://booth.pm/ko/items/8512637 ・ https://payhip.com/b/jprkg | 不明 | 無料版あり | 韓国語検索「이징 패널」 |
| 参考: Kease / Flow の汉化版が B站で再生2.2万・9千 | AE | 汉化: 影视后期系统教学、LookAE | 未 https://i1.hdslb.com/bfs/archive/0b7b97a8a98dff1b23f422c586415f8d04cac3bd.jpg | https://www.bilibili.com/video/BV1Qi2yBbEpX/ | 2025-12 | 再生2.2万 | 同上 |

所見: 中国では「自作の緩動板」はほぼ無く、海外製（Flow・Kease・Ease and Wizz）の汉化が主役。

### 2-2. パイメニュー

| 名前 | ホスト | 作者 / 国 | 画像 | ページ | 更新 | 使われ方 | 来た道 |
|---|---|---|---|---|---|---|---|
| Plasticity 汉化与饼菜单编辑器（自作・無料） | Plasticity | 亮锅不服LAO / 中国 | 未 | https://www.bilibili.com/video/BV1RatSzQEKs/ | 2025-08 | 再生1.1万 | B站「Blender插件 饼菜单 自制」 |
| 支持 Blender 5.0 的饼菜单 | Blender | 萧瑟TX / 中国 | 未 | https://www.bilibili.com/video/BV1FqCeBMEfY/ | 2025-11 | 再生4924 | 同上 |
| Blender最全的隐藏功能饼菜单 | Blender | 摘星陈的插件仓库 / 中国 | 未 | https://www.bilibili.com/video/BV1xXKo6REdS/ | 2026-06 | 再生874 | 同上 |
| PieMaster 自由饼菜单（任意機能を入れられる） | Blender | 作者不明（紹介: 希汐大魔王・blender插件） | 未 | https://www.bilibili.com/video/BV15nYK6fEpW/ ・ https://www.bilibili.com/video/BV1u17L6zE9y/ | 2026-06〜09 | 再生1194+476 | 同上 |
| 参考: Pie Menu Editor（露 roaoao 作）の汉化・Fork 版が多数 | Blender | 郭吉军插件汉化、三叔… | 未 | https://www.bilibili.com/video/BV1n7421T743/ | 2024〜2026 | 汉化動画が多数 | Web検索 |

### 2-3. リグ／パラメータ選び（キャラ絵にボタン）

| 名前 | ホスト | 作者 / 国 | 画像 | ページ | 更新 | 使われ方 | 来た道 |
|---|---|---|---|---|---|---|---|
| MikuMikuRig（MMD モデルにコントローラ生成） | Blender | LaoBro / 中国 | 未 https://github.com/958261649/Miku_Miku_Rig/blob/main/preview/QQ%E6%88%AA%E5%9B%BE20210616125213.png | https://github.com/LaoBro/Miku_Miku_Rig | 2025-06 | ★610 | GitHub「blender插件」 |
| mmd-controller（表情面板をドラッグ、四肢 IK/FK を1行ずつ切替） | Blender | yming9525-ux / 中国 | 未（README に画像なし） | https://github.com/yming9525-ux/mmd-controller | 2026-08 | ★1 | GitHub「表情 面板 blender」 |
| LAPLACE Persona の Live2D 参数编辑器（VTube Studio の代わり、web 製、無料、Cubism 5.3 対応） | 独立アプリ（VTS 置換） | LAPLACE / 中国 | 未 | https://www.bilibili.com/video/BV1BAtd6dEPE/ ・ https://www.bilibili.com/opus/1230407301696847876 | 2026 | alpha、完成度約50%と作者 | B站→Web検索 |

所見: 「キャラ絵の上にボタン」型（ピッカー）は中国でも見つからず。表情はスライダー列、手足は行の表。

### 2-4. 色棚

| 名前 | ホスト | 作者 / 国 | 画像 | ページ | 更新 | 使われ方 | 来た道 |
|---|---|---|---|---|---|---|---|
| Coco Color 颜色博物馆（配色板・グラデ色卡・ブランド色） | AE | 小董内容研究所（董老师）/ 中国 | 未 | https://www.bilibili.com/video/BV1av4y1C7ET/ | 2023-01 | 再生9560。同作者の「十款Ae脚本」は5.8万 | B站「AE 色板 脚本」 |
| 韓国作家の Clip Studio カラーセット／自動彩色オートアクション（素材として配布） | Clip Studio | 韓国の作家（ASSETS） | 未 | https://assets.clip-studio.com/en-us/detail?id=1917730 | 不明 | ASSETS 配布 | 韓国語検索「컬러세트」 |

注: Clip Studio は標準の色セット枠に「中身」を配る形。パネル自体の置き換えではない。

### 2-5. 検索箱／サムネ一覧（メニューやリストの代わり）

| 名前 | ホスト | 作者 / 国 | 画像 | ページ | 更新 | 使われ方 | 来た道 |
|---|---|---|---|---|---|---|---|
| 梦·N面板快寻（N パネルへ検索で一発移動） | Blender | 构筑梦师 / 中国 | 未 | https://www.bilibili.com/video/BV1GDpC6qEmQ/ | 2026-10 | 再生117（新しい） | B站「MMD blender 插件 面板 自制」 |
| n面板插件快捷搜索打开 | Blender | 浅-言 / 中国 | 未 https://i0.hdslb.com/bfs/archive/41487b676dd2b056bb6062a51124719077eee19e.jpg | https://www.bilibili.com/video/BV13eJ26NEqS/ | 2026-10 | 再生37 | B站「Blender N面板 整理 插件」 |
| 自制 AE 脚本管理器（ドラッグ並べ替え、画像を貼って見た目で探す、一括打包） | AE | 爱吃冬菇的蘑菇 / 中国 | 未 | https://www.bilibili.com/video/BV1vZgEzQEMx/ | 2025-07 | 再生2712 | B站「国产AE脚本 面板」 |
| AE脚本管家 V1.0（30以上の機能を持つスクリプト管理） | AE | 星美男 / 中国 | 未 | https://www.bilibili.com/video/BV1t5411f7H2/ | 2022-02 | 再生2.5万 | 同上 |

### 2-6. レイヤーのまとめ・たたみ

| 名前 | ホスト | 作者 / 国 | 画像 | ページ | 更新 | 使われ方 | 来た道 |
|---|---|---|---|---|---|---|---|
| 图层筛选器（検索欄＋種類チェックの格子＋ラベル色の一列、反選択） | AE | 雪域studio / 中国 | 画 https://i0.hdslb.com/bfs/archive/704fd31ba2aba0b7f5c426c311a70799d760031b.jpg | https://www.bilibili.com/video/BV1nXFwzREKn/ | 2026-02 | 再生864、無料 | B站「AE 图层分组 脚本」 |
| 玄如意 の「图层工具」（Alt で全属性を開閉、Ctrl で他をたたむ） | AE | 玄如意 / 中国 | 未 | https://ai.feishu.cn/wiki/Sxfcw2XldiRMXzkj9Ltc7FkencW | 2026（AE2020〜2026対応と記事） | 知乎の推薦記事で筆頭 | 知乎「2026 年了，国产AE 脚本推荐」 |

### 2-7. パネル／タブの整理

| 名前 | ホスト | 作者 / 国 | 画像 | ページ | 更新 | 使われ方 | 来た道 |
|---|---|---|---|---|---|---|---|
| 玄如意（自分用「主页」にボタンを寄せる、網格/リスト切替、ボタン組の切替） | AE | 玄如意 / 中国 | 未 | https://zhuanlan.zhihu.com/p/1987586670913159395 （教程 https://ai.feishu.cn/wiki/Sxfcw2XldiRMXzkj9Ltc7FkencW ） | 2026 | 知乎推薦 | 知乎 |
| N面板管理器 QAddons（插件分组・图标设置） | Blender | 亮锅不服LAO / 中国 | 画 https://i0.hdslb.com/bfs/archive/9c132b16af9f928fe4ff7ab5627117b2a27ec7dc.jpg | https://www.bilibili.com/video/BV1xfRqY8EQT/ | 2025-04 | 再生3425 | B站「Blender N面板 整理 插件」 |
| SIMPLE TABS（N パネルの改名・並べ替え・分組、縦書きタブを横に） | Blender | blender布的 / 中国（自作か紹介か未確認） | 未 https://i0.hdslb.com/bfs/archive/fdc27993e50bc549bb6d9145b4bfc440a0ec9da9.jpg | https://www.bilibili.com/video/BV1Rq6CB7ExK/ ・ https://www.bilibili.com/video/BV1ap6yB2E9D/ | 2026-01 | 再生1795+1418 | 同上 |
| MikuMikuToon（「侧栏精简」、N の Toon タブ1つに一键卡渲） | Blender | zhouhanjue / 中国 | 未 | https://github.com/zhouhanjue/MikuMikuToon | 2026-10 | ★38 | GitHub「blender插件」 |
| Paper二次元渲染助手（N パネル1枚にアニメ調描画の操作を集約） | Blender | Paper朱（PUBG11S1）/ 中国 | 未 | https://github.com/PUBG11S1/paperzhu-anime-helper | 2026-03 | ★89、紹介動画 再生9528 | GitHub→B站 |
| 工具箱大师（補帧ほか、免費） | AE | 小庄掌门 / 中国 | 未 | https://www.bilibili.com/video/BV1ewAgzkEXe/ ・ https://www.bilibili.com/video/BV1A5U5Y6Eo7/ | 2026-03 | 再生7770 | 知乎検索→B站 |
| Only Scripts（分镜・超分・補帧を1パネル） | AE | 蘇OrantLris / 中国 | 未 | https://www.bilibili.com/video/BV14chD6YEyq/ | 2026-09 | 再生3838 | B站「国产AE脚本 面板」 |
| 27Tools | AE | Nian7i / 中国 | 未 | https://www.bilibili.com/video/BV178JD6WEFL/ | 2026-10 | 再生17（新しい） | B站「AE 歌词 脚本 自制」 |
| Spine Hotkeys Editor v0.1（Spine のショートカット編集の代わり） | Spine | Voice-of-Shadow / 中国 | 未 https://i0.hdslb.com/bfs/archive/008c6a60c6bd19ba5e4c46b25396fdb0a01b42da.jpg | https://www.bilibili.com/video/BV1gRk5BcEt1/ | 2026-01 | 再生2028 | B站「Spine 插件 自制 工具」 |
| 参考: N Panel Sub Tabs「面板整合」汉化（海外製） | Blender | 汉化: 郭吉军 | 画 https://i0.hdslb.com/bfs/archive/12129a0c3f2ea68a74ecc4f6a8def26a0a64f6d7.jpg | https://www.bilibili.com/video/BV1gBYYzGEg5/ | 2025-08 | 再生4369 | 同上 |

所見: Blender の N パネル（右の縦タブ）が増えすぎ、という不満が中国で一番多い。答えの形は3つに収束: (a)分組＋アイコン (b)検索で飛ぶ (c)1つのタブに全部寄せる。

### 2-8. 3x3 アンカー格子

中国・台湾・韓国の自作は見つからず。B站で出るのは海外製 Motion Tools の「锚点面板」解説（_1hew、再生1.2万 https://www.bilibili.com/video/BV1Po4y1k7vW/ ）だけ。3件以上の新出典なしで打ち切り。

### 2-9. その他の置き換え（歌詞・字幕タイムライン、剪映）

| 名前 | ホスト | 作者 / 国 | 画像 | ページ | 更新 | 使われ方 | 来た道 |
|---|---|---|---|---|---|---|---|
| krc 歌詞でカラオケ字幕を作る AE スクリプト（自作） | AE | 求文问道 / 中国 | 未 | https://www.bilibili.com/video/BV1xK411C7Um/ | 2023-01 | 再生1690 | B站「AE 歌词 脚本 自制」 |
| haoone-app（剪映字幕の「平替」、話者分け・語ごとの時刻合わせ） | 独立アプリ（剪映の字幕機能の置換） | minghe36 / 中国 | 未 | https://github.com/minghe36/haoone-app | 2026-10 | ★628 | GitHub「剪映 字幕」 |
| pyJianYingDraft（剪映の草稿をコードで組む。字幕・文字キーも） | 剪映 / CapCut | GuanYixuan / 中国 | 未 | https://github.com/GuanYixuan/pyJianYingDraft | 2026 | GitHub で広く参照（pyCapCut に派生） | Web検索 |
| 阿瑞剪映插件（剪映の横に置く補助パネル） | 剪映 | 邪修阿瑞 / 中国 | 未 https://i0.hdslb.com/bfs/archive/95d4506e0868dae67fed90b0106973230a659f5c.jpg | https://www.bilibili.com/video/BV191HjzGE4Z/ | 2025-10 | 再生8860 | B站「剪映 插件 自制 工具 字幕」 |
| 剪映字幕の書き出し・音声合わせの小道具群（get-subtitle-from-JianYing ★24 ほか多数） | 剪映 | tanziczack 他 / 中国 | 未 | https://github.com/tanziczack/get-subtitle-from-JianYing | 2025-01 | ★24、同種が10件以上 | GitHub「剪映 字幕」 |
| VTS 16K 截图／録画プラグイン | VTube Studio | 宵夜97 / 中国 | 未 | https://www.bilibili.com/video/BV1Bg4y177Jg/ | 2023-04 | 再生4.1万 | B站「Live2D 插件 自制 工具」 |

## 3. まとめ（短く）

- 数: 中国オリジナル 約27件、参考（汉化・国不明）約5件。韓国・台湾のオリジナルは確認できず。
- 中国で一番多い置き換え先は「Blender の N パネル」と「AE のスクリプト一覧」。答えはどれも 分組＋アイコン／検索で飛ぶ／1枚に寄せる。
- イージング・パイ・アンカーは自作が少なく、海外製の汉化（Flow、Kease、Pie Menu Editor、Motion Tools）が使われている。
- 画像は3枚だけ自分の目で確認（图层筛选器、N面板管理器、面板整合）。他は動画の表紙で未確認。
- 次にやるなら: 韓国は Naver/포스타입 を開ける手段で、台湾は巴哈姆特で、もう一度。
