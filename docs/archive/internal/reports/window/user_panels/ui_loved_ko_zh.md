# 韓国・中国の作者が作った自作パネル（機能ごと）

調べた日: 2026-10-17。ウェブ検索のみ（サインインなし、ダウンロードなし、実行なし）。
途中で方針が変わった: 「UI がきれい」という褒め言葉ではなく、**同じ便利機能を別々の作者が何度も作り直しているか**を見る。

## 先に結論

- 中国の作者は多い。特に GitHub に 2026 年の新しいパネルがたくさんある（星 0〜7 が多い。説明に「AI が全部書いた」と書くものもある: Ae-ToolKit）。
- 何度も作り直されている機能（中国）: **字幕の読み込み 5 本**、**緩急カーブ 3 本**、**ボタン棚・ランチャー・窓しまい 4 本**、**Blender のパイメニュー 4 本**、**Figma の切り出し・寸法書き 7 本**。
- 韓国の作者は少ししか見つからなかった（4 本）。検索が Naver ブログ・크몽・클래스101 に届かない（Naver はこちらの道具から入れない）。motionist.kr も検索に出なかった。
- 見つからなかった機能: 韓国語の字母（자모）分割パネル、9 方向アンカー移動（中・韓）、中国・韓国発のリグのピッカー、中国発の輝度マスクパネル（英語の TK パネルが中国語表示を持つだけ）、色の一括置換（中国・韓国）。
- 画像の URL は README の中から取った。**絵を目で見て確かめてはいない**。「パネルの絵か」は README の説明文で判断した。
- Figma のプラグイン頁は画像 URL を取れなかった（頁が中身を返さない）。

画像 URL の書き方: `github.com/作者/リポジトリ/raw/HEAD/パス` は README の中の相対パスを直したもの。

---

## 1. 緩急カーブ（イージング）— 中国 3 本

| 名前 | 道具 | 作者 | 言語 | 画像 URL | 頁 | 最終更新 | 備考 |
|---|---|---|---|---|---|---|---|
| XLFlow（AE曲线工具） | AE（CEP） | xiaolinnnnnnn | 中 | README に画像なし | https://github.com/xiaolinnnnnnn/XLFlow | 2026-07-28 | ベジェ編集、弾むカーブ、プリセット、雲で共有、1 組のキーを多段に割る。道具棚に「反転・時間入替・静止・吸着」ボタン |
| Dalimao Curve | AE（AEGP 本体プラグイン） | pearlrice | 中 | 画像なし | https://github.com/pearlrice/AE_plugin_Dalimao_Curve | 2026-09-12 | ショートカットでカーブ面板を呼ぶ |
| Flow v1.5.2「帧速缓动」 | AE（CEP） | Vvv1940905115 | 中 | 画像なし | https://github.com/Vvv1940905115/Flow-v1.5.2 | 不明 | **注意**: 有料の Flow（renderTom / Zack Lovatt）の中国語化コピーに見える。作り直しではない |
| （比較）Bezier Curve Editor | AE | Vergil1000x | 英 | 画像なし | https://github.com/Vergil1000x/Bezier_Curve_Editor | 2025-04-23 | 「Flow のような無料版」と自称 |

## 2. 効果検索（ピンイン検索）— 中国 1 本

| 名前 | 道具 | 作者 | 言語 | 画像 URL | 頁 | 最終更新 | 備考 |
|---|---|---|---|---|---|---|---|
| 玄如意控制台 XFXConsole（xfxc） | AE | loyoi | 中 | https://github.com/loyoi/xfxc/raw/HEAD/output.gif （動く実演） | https://github.com/loyoi/xfxc | 2026-10-02 | ピンイン頭文字・全拼・漢字まぜて検索。Ctrl+Space で呼ぶ。効果・スクリプト・プリセット・書体を**ボタン棚**にもできる（無料は 1 枚 20 ボタン、買い切りで 128 枚） |
| （比較）FX Console の B站 解説 | AE | 董老师（解説者） | 中 | — | https://www.bilibili.com/video/BV19Y4y1R7P3/ | 不明 | 中国でも英語の FX Console が教えられている。ピンイン対応がないのが xfxc の出発点と読める |

## 3. ボタン棚・ランチャー・窓のしまい場所 — 中国 4 本

| 名前 | 道具 | 作者 | 言語 | 画像 URL | 頁 | 最終更新 | 備考 |
|---|---|---|---|---|---|---|---|
| 收纳盒 AE-WindowSnap | AE | suchengxing | 中・英・日 | https://github.com/user-attachments/assets/cb2682ec-b350-43fe-aeca-e51c50366995 （中国語版）/ https://github.com/user-attachments/assets/137c1357-380b-4e3b-8921-87df2555f763 （英語版） | https://github.com/suchengxing/AE-WindowSnap | 2026-10-08 | 浮いたスクリプト窓をしまって呼び出す。星 7 |
| xfxc のボタン棚 | AE | loyoi | 中 | 上と同じ | 上と同じ | 2026-10-02 | 2 と同じもの |
| Ae-ToolKit | AE（CEP） | MYdesignTool | 中 | 画像なし | https://github.com/MYdesignTool/Ae-ToolKit | 2026-10-16 | 「プロジェクト整理・式の管理・スクリプト起動・完全オフライン」。説明に「全部 AI が書いた」 |
| ae-tools | AE | Simiely | 中 | 画像なし | https://github.com/Simiely/ae-tools | 2026-10-09 | 自作パネル集。中国語 JSX は UTF-8 BOM が要る、と書く |
| TimeAxisIndent | AE | Simiely | 中 | 画像なし | https://github.com/Simiely/TimeAxisIndent | 2026-10-08 | タイムラインのレイヤーを「字下げ」して見せる（動きは変えない）。**プリコンポーズしないで束ねる**欲求に近い |

## 4. 字幕（SRT 読み込み・時間合わせ）— 中国 5 本

| 名前 | 道具 | 作者 | 言語 | 画像 URL | 頁 | 最終更新 | 備考 |
|---|---|---|---|---|---|---|---|
| AE字幕助手 JZ_SubtitleHelper | AE | shawlj | 中 | README の画像はバッジだけ | https://github.com/shawlj/JZ_SubtitleHelper | 2024-07-13 | SRT/ASS/SSA/LRC/TXT、まとめ読み込み、遅らせ、行番号で範囲。星 23 |
| quickSRT | AE | msongz | 中・英 | https://tva2.sinaimg.com/large/006tNbRwgy1fw95v03wo4g30o20iuhas.gif | https://github.com/msongz/quickSRT | 2020-07-15 | AE の文字レイヤーから SRT を書き出す。星 26 |
| quickText | AE | msongz | 中・英 | http://ww1.sinaimg.cn/bmiddle/66e22e28jw1ene7pb7q0ig20c809xwod.gif | https://github.com/msongz/quickText | 2020-05-01 | 字幕レイヤーを素早く作る |
| Noniika | AE（CEP） | 435434 | 中 | 画像なし | https://github.com/435434/Noniika | 2026-10-04 | 選んだ素材から声を分けて文字起こし→文字レイヤー（無料） |
| 映词 LyricMotion | AE | guhechudaisuki | 中 | 画像なし | https://github.com/guhechudaisuki/LyricMotion-AE--- | 2026-10-04 | MAD/AMV 向け歌詞の動く組版。強調語、出入り、翻訳 |
| （韓国）なし | — | — | — | — | — | — | 韓国の作者の字幕パネルは見つからず |

## 5. 文字の分割（文字・語・行・字母）

| 名前 | 道具 | 作者 | 言語 | 画像 URL | 頁 | 最終更新 | 備考 |
|---|---|---|---|---|---|---|---|
| 歌词逐字散落动画 | AE | Simiely（ae-tools の中） | 中 | 画像なし | https://github.com/Simiely/ae-tools | 2026-10-09 | 一文字ずつ散らす動き |
| 映词 LyricMotion | AE | guhechudaisuki | 中 | 画像なし | 上の 4 | 2026-10-04 | 歌詞を語ごとに |
| （韓国）hangul-typing-animation | ウェブ用（AE ではない） | keisokoo | 韓 | — | https://github.com/keisokoo/hangul-typing-animation | 不明 | 字母に割って打ち込む動き。**AE の字母分割パネルは見つからず** |

## 6. 並べる・等間隔

| 名前 | 道具 | 作者 | 言語 | 画像 URL | 頁 | 最終更新 | 備考 |
|---|---|---|---|---|---|---|---|
| 等距位移 Equidistant-Displacer | AE | LYLnpc | 中 | 画像なし | https://github.com/LYLnpc/Equidistant-Displacer | 2026-09-24 | 選んだレイヤーを指定方向に等間隔、等角度で回して並べる。順番・X・Y で並べ替え |

## 7. プリコンポーズの解除・束ね — 韓国 1 本

| 名前 | 道具 | 作者 | 言語 | 画像 URL | 頁 | 最終更新 | 備考 |
|---|---|---|---|---|---|---|---|
| Un Precompose | AE 2024+ | wa13sans | 韓 | 画像なし（バッジのみ） | https://github.com/wa13sans/ae-un-precompose | 2026-09-14 | 無料、改変可、転売禁止。韓国語 UI のドッキングパネル |

## 8. 色を選ぶ

| 名前 | 道具 | 作者 | 言語 | 画像 URL | 頁 | 最終更新 | 備考 |
|---|---|---|---|---|---|---|---|
| adobe-color-picker | AE・PS・AI のスクリプト用 | smallpath | 中（作者）・英 | https://raw.githubusercontent.com/Smallpath/AdobeColorPicker/master/_screenshot/Animation.gif | https://github.com/smallpath/adobe-color-picker | 2019-05-11 | 標準の色選びが悪いので作り直した、と題名。RGB/Hex/HSB。星 63 |
| （色の一括置換）なし | — | — | — | — | — | — | 中国・韓国とも見つからず |

## 9. プリセット・レイヤーの保存庫

| 名前 | 道具 | 作者 | 言語 | 画像 URL | 頁 | 最終更新 | 備考 |
|---|---|---|---|---|---|---|---|
| Sp_memory | AE | smallpath | 中 | README から取れず | https://github.com/smallpath/memory | 2019-02-10 | レイヤーを保存して呼び出す棚。星 69 |

## 10. 一発で作る・書き出す（AE）

| 名前 | 道具 | 作者 | 言語 | 画像 URL | 頁 | 最終更新 | 備考 |
|---|---|---|---|---|---|---|---|
| AE-Slicer | AE | bigxixi | 中・英 | https://raw.githubusercontent.com/bigxixi/ReadMe-Resources/master/AE-Slicer/aeslicerdemo.gif | https://github.com/bigxixi/AE-Slicer | 2019-02-25 | 一つのコンプに複数の切り出し枠、PNG で書き出す。星 20 |
| ECharts_Generator_For_AE | AE | jokerfree | 中 | https://github.com/user-attachments/assets/cf620912-03c5-4bef-bf6d-6773cd74b21e （出来上がりのグラフ。パネルではない） | https://github.com/jokerfree/ECharts_Generator_For_AE | 2026-09-13 | 一発でグラフを作る |
| AE_SpriteSheetBuilder | AE | inlet511 | 中 | 画像なし | https://github.com/inlet511/AE_SpriteSheetBuilder | 2026-10-09 | スプライトシート作り |
| emg_cammera | AE | j10ha0 | 中 | https://github.com/j10ha0/emg_cammera/raw/HEAD/out/img_nocontact_Apple_lc.jpg | https://github.com/j10ha0/emg_cammera | 2026-10-09 | カメラ関係。中身は未確認 |
| AE_LanguageSwitcher | AE | EricZhou05 | 中 | https://github.com/user-attachments/assets/76f709df-cbdd-4ffb-9b35-828635e8f23f | https://github.com/EricZhou05/AE_LanguageSwitcher | 2026-10-06 | AE の表示言語を一押しで切り替え |
| （ヌル・カメラ一発作成）なし | — | — | — | — | — | — | 中国・韓国の作者のものは見つからず |

## 11. Blender のパイメニュー・操作感 — 中国 4 本、韓国 2 本

| 名前 | 道具 | 作者 | 言語 | 画像 URL | 頁 | 最終更新 | 備考 |
|---|---|---|---|---|---|---|---|
| wxz_pie_menus | Blender 4.2+ | xz-blender | 中 | https://github.com/xz-blender/wxz_pie_menus/raw/HEAD/docs/readme/hero.svg （表紙。パネルかは不明） | https://github.com/xz-blender/wxz_pie_menus | 2026-10-15 | 自分の手癖のパイメニュー集。入れると設定・キーも書き換わる。星 6 |
| 红红子lab REDKOlab | Blender 4.0+ | ChimeRED | 中 | 画像なし | https://github.com/ChimeRED/redkolab | 2026-10-15 | 材質を空に・モディファイア適用/削除をパイ + N パネル + キー変更で |
| pme_preset | Blender（Pie Menu Editor 必要） | wen-yifeng | 中・英 | 画像なし | https://github.com/wen-yifeng/pme_preset | 不明 | パイ 80 個、9 モード。押す・長押し・引くで別メニュー |
| MACHIN3tools_zh-Hans | Blender | millionart | 中（翻訳） | 画像なし | https://github.com/millionart/MACHIN3tools_zh-Hans | 約 900 日更新なし | 英語のパイ集の中国語化 |
| BlanderToMaya | Blender 4.0+ | 9amechoung | 韓 | https://github.com/9amechoung/BlanderToMaya/raw/HEAD/docs/screenshot_rmb_menu.png （右クリックメニュー）/ .../docs/screenshot_layout.png | https://github.com/9amechoung/BlanderToMaya | 2026-10-14 | 「블렌더 ui 편의성을 마야처럼」= Blender の UI を Maya 風に（配置・メニュー・キー） |
| KoreanIME | Blender | kirumon | 韓 | 画像なし | https://github.com/kirumon/KoreanIME | 2021-10-14 | Blender で韓国語を打てるようにする（ボーン名も F2 で） |

## 12. リグのピッカー（Maya・Blender）

中国・韓国の作者のものは見つからず。出てきたのは欧米の dwpicker、Universal Picker、azagoruyko/picker、aweControlPicker、Maya-UnPicker、AnimSchool Picker だけ。

## 13. Photoshop

| 名前 | 道具 | 作者 | 言語 | 画像 URL | 頁 | 最終更新 | 備考 |
|---|---|---|---|---|---|---|---|
| Cutterman | PS | 中国の作者（名前は頁になし） | 中 | 取れず | https://www.jb51.net/softs/301395.html （配布サイト） | 不明 | 切り出し書き出しパネル。中国の UI 設計者の定番 |
| sd-ppp | PS（UXP） | zombieyang | 中・英 | https://github.com/zombieyang/sd-ppp/raw/HEAD/static/index.gif | https://github.com/zombieyang/sd-ppp | 2026-02-05 | PS と ComfyUI をつなぐ。星 2183（今回いちばん大きい） |
| （輝度マスク）TK8/TK9 の中国語表示 | PS | Tony Kuyper（米） | 6 言語に中国語あり | — | https://exchange.adobe.com/apps/cc/83b6b487/tk-luminosity-mask | 不明 | 中国発の輝度マスクパネルは見つからず |

## 14. Figma — 中国 7 本（切り出し・寸法書き）、韓国 3 本（ハングル組版）

画像 URL は取れなかった（頁が中身を返さない）。

| 名前 | 作者 | 言語 | 頁 | 備考 |
|---|---|---|---|---|
| 切图助手 Slice Export Assistant | 中国の作者 | 中 | https://www.figma.com/community/plugin/1449333612592633194/slice-export-assistant | 多形式・多倍率、まとめて ZIP |
| 切图助手（专业版） | 同上 | 中 | https://www.figma.com/community/plugin/1471834428315619590/slice-export-assistant-pro | 中国語の切り出し名を英語に訳す |
| Quick cut | 中国の作者 | 中 | https://www.figma.com/community/plugin/1082599768180571893 | 一押しで切り出して画像置き場へ、URL を図の横に書く |
| 标记狮 MarkLion | 中国の会社 | 中 | https://www.figma.com/community/plugin/1185280615140158433/marklion | 一押しで寸法書き・切り出し |
| 智能设计标注 Magic Marker | 中国の作者 | 中 | https://www.figma.com/community/plugin/1582663372279333936/magic-marker | 説明・寸法の注記 |
| 设计标注 Design Mark | 中国の作者 | 中 | https://www.figma.com/community/plugin/1263797755133490918/design-mark | 手で寸法・間隔 |
| 腾讯 CoDesign | 腾讯 | 中 | https://www.figma.com/community/plugin/936456730265868414 | 寸法自動、切り出しまとめ取り |
| F2C | YY チーム | 中 | https://www.figma.com/community/plugin/1248187540929489451/f2c-figma-to-code-react-rn-vue-html-yy-d2c | 寸法・切り出し・コード生成 |
| Korean Text Wrapper | 韓国の作者 | 韓 | https://www.figma.com/community/plugin/1522764985687835106/korean-text-wrapper | ハングルを語の切れ目で折り返す（keep-all） |
| KoFont（한글 폰트 시스템） | 韓国の作者 | 韓 | https://www.figma.com/community/plugin/1649017989775821033/kofont | 韓国語名で書体を探す。太さ・大きさ・行間・字間を一か所で |
| 한글더미 | 韓国の作者 | 韓 | https://www.figma.com/community/plugin/1243208578746510514 | ハングルのダミー文 |

---

## 見えたこと（短く）

- 中国で何度も作り直される理由は「英語の名前で探せない」（ピンイン検索、言語切替、中国語化）と「字幕・歌詞」（B站 の MAD/字幕文化）。
- 韓国で目立つのは「ハングルの組版」（折り返し、書体名、入力）。AE の韓国作者パネルは検索に出にくい。
- 2026 年の中国の小さなリポジトリは、星 0 で AI 製と書くものが多い。数は「欲しい人が多い」印にはなるが、「使われている」印にはならない。
- 次にやるなら: B站 の動画題名と 淘宝 の出品を、ブラウザ 1 タブで直接見る（検索道具が中国サイトの中身を返さないため）。

## 出典

- GitHub の各リポジトリ（上の表の頁）、API で最終 push 日と星を読んだ。
- B站: https://www.bilibili.com/video/BV19Y4y1R7P3/
- jb51（Cutterman 配布頁）: https://www.jb51.net/softs/301395.html
- Adobe Exchange（TK）: https://exchange.adobe.com/apps/cc/83b6b487/tk-luminosity-mask
- Figma コミュニティの各頁（上の表）
