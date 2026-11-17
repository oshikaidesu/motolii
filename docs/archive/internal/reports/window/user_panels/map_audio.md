# 音の道具の上で、使い手が自分の操作盤を作る文化 — 言葉と場所の地図

調べた日: 2026-10-17。ウェブ検索と数ページの読み取りだけ。サインインなし、ダウンロードなし。
途中で方針が変わった: 本体(ホスト)の公式指針は見ない。「使い手が盤を自作する = 本体に穴がある」として、
**よく名前が出る自作盤が、本体のどの穴を埋めていて、見た目の何が褒められているか** を中心にする。
「(未確認)」は私の記憶で、今回の検索では裏が取れていないもの。

---

## 1. 呼び名(自作の盤を何と呼ぶか)

| 本体 | 呼び名 |
|---|---|
| Ableton Live + Max for Live | device(デバイス)、M4L device、patch、pack。日: デバイス / 韓: 디바이스 / 中: 设备・插件 |
| Max/MSP 単体 | patch、presentation mode(見せる面) |
| REAPER | script(ReaScript)、GUI script、ImGui script、JSFX(自作エフェクト、面も描ける)、theme(外見そのものの着せ替え)、extension |
| VCV Rack | module、plugin(= module の束)、panel(モジュールの面の絵)、"dark panel / alternate panel" |
| Bitwig | Grid patch、preset、controller extension(DrivenByMoss など) |
| Reaktor(NI) | ensemble、instrument、block、macro |

## 2. 褒め言葉・けなし言葉(見つかったもの)

- 褒め: "clean UI"、"clear GUI"、"highly intuitive layout"(Bengal への評)、"looks native" / "as if they were native Live devices"(ValhallaWrapper への評)、"readable"、"space-efficient"、"balanced"、"functional"、"good looking"、"aesthetically pleasing"、"blank space"(余白)、"density"(VCV で「Fundamental の密度を真似ておけば外さない」)
- けなし: "ugly"("Max is very powerful, but ... UGLY" 2009 年の Ableton 掲示板)、"cluttered"、"visual noise"、"high contrast"(まぶしい白・黄・赤)、"dated / outdated"、"skeuomorphic"(本物の機械に似せすぎ。VCV では軽い悪口として使われる)、"3D gradient"、"eye candy"(飾りだけ)
- 論点の言葉: "flat vs skeuomorphic"、"dark panels"(VCV の「暗い面を優先」設定論争)、"minimal design may fool you"(見た目が素っ気なくても耳で判断しろ、MusicTech)
- 日本語・韓国語・中国語: まとめ記事はほぼ英語記事の翻訳か公式ブログの訳。UI を評する独自の言葉は今回は見つからず。中国語では「界面直观」(画面が直感的)が質問側の言葉として出るのみ。

## 3. 集まる場所・格付けの場

**Max for Live**
- maxforlive.com — 共有棚。2019 年頃で「約 4000」。今の数は未確認(トップは 403 で読めず)。人気・評価で並べ替え可能(未確認)
- Ableton 公式ブログ — ELPHNT の「無料デバイス探し」連載(英・日・中・西語版あり)が事実上のランキング
  https://www.ableton.com/en/blog/elphnt-searches-maxforlivecom-best-free-devices/
- まとめ記事: MusicTech「The 12 best Max for Live devices」 https://musictech.com/guides/buyers-guide/the-12-best-max-for-live-devices-in-2023 / Cymatics、audeobox、kmag の無料リスト
- 掲示板: Cycling '74 forum、forum.ableton.com、r/ableton、r/MaxForLive(名前のみ)
- YouTube: ELPHNT(デバイス紹介の定番)
- 売り場: Isotonik Studios、Gumroad、K-Devices、Max for Cats

**REAPER**
- ReaPack — パッケージ係。「1,300 を超える REAPER 資源」 https://reapack.com/
- 主な棚: ReaTeam/ReaScripts(共同管理)、MPL、X-Raym、Sexan(GoranKovac)、nvk、ply
- 一覧: awesome-reaper(https://github.com/indiscipline/awesome-reaper)、X-Raym の Action List
- 外見: Reaper Stash(テーマ置き場)、テーマまとめ記事 https://emastered.com/blog/best-reaper-themes
- 掲示板: forum.cockos.com(ReaScript / Themes 板)、r/Reaper。ブログ: The REAPER Blog(reaper.blog)、Reapertips
- 部品: ReaImGui(Dear ImGui の REAPER 版、いまの GUI スクリプトの土台)、昔は Lokasenna GUI

**VCV Rack**
- VCV Library https://library.vcvrack.com/ — 公式で「2000+ modules」。プラグイン単位で何個入りか表示
- community.vcvrack.com — 見た目の論争スレが多い:
  - 「モジュールの見た目をどれくらい気にする?」 https://community.vcvrack.com/t/how-much-do-you-care-about-the-visual-design-of-rack-modules/10460
  - 「Prefer dark panels」提案 https://community.vcvrack.com/t/prefer-dark-panels-proposal/20071
  - 「Exploring Panel design」 https://community.vcvrack.com/t/exploring-panel-design/4984
- 作者が自分の作法を書いた例: amplified-futures の Design System https://github.com/dboles99/amplified-futures-vcv/wiki/Design-System

**Bitwig Grid**
- 公式の共有棚は見つからず。KVR 掲示板に「公式の交換場がほしい」という声。配布は Gumroad や Patreon の個人ばらばら。→ 自作文化は小さい
- 掲示板: KVR の Bitwig 板、r/Bitwig、elektronauts の Bitwig スレ

**Reaktor(もっと大きな自作棚)**
- Reaktor User Library — 約 6,560 件(楽器 3,855、エフェクト 968 など)。「最多ダウンロード」「最高評価」で全期間・直近 3 か月の並べ替えあり。今回見つけた中で一番はっきり数と格付けを持つ棚
  https://www.native-instruments.com/en/reaktor-community/reaktor-user-library/

## 4. 何度も名前が出る自作盤 — 埋めている穴 / 見た目で褒められている点

**Max for Live**
- MultiMap / Map8(Essentials)— 穴: 1 つのつまみで多数の値を動かせない / 見た目: 小さく畳める
- LFO・Envelope Follower・Shaper 等の変調器 — 穴: Live 本体に「何にでも挿せる変調」がない / 見た目: 波形がそのまま見える
- Granulator II(Robert Henke)— 穴: 本格的な粒の音作り / 見た目の評は出ず
- Inspired by Nature(Dillon Bastan)— 穴: 動きのある生成 / 見た目: 粒子 1 つ = 声 1 つ。飾りでなく中身が見える動き
- Bengal(Max for Cats)— 穴: 混成シンセ / 見た目: "highly intuitive layout"、"clear GUI"
- ValhallaWrapper — 穴: 外部プラグインが Live の顔をしていない / 見た目: "native Live devices" と見間違えるほど
- Volume Buddy、Kapture、Riff Generator、Drum Mapper、Polyrhythmus、Remote Pitch — 音量合わせ、状態の保存、作曲補助、多重リズム、一括移調など、本体の手間の穴 / 見た目の評は少ない("may look simple, don't underestimate")

**REAPER**
- テーマ全般(Rado、Hydra、FL 風・Ableton 風テーマ、nvk_THEME)— 穴: 標準の見た目が「好き嫌いが割れる」「使えるが地味」 / 見た目: 場所の使い方がうまい、メーターが見やすい、「他の DAW の顔になれる」
- nvk_SEARCH — 穴: エフェクト・操作・曲・トラックを一つの窓で探せない / 一窓に全部
- ParaNormal FX Router(Sexan)— 穴: 並列エフェクトの比較・独奏 / Sound on Sound が紹介
- ReaLearn(Helgoboss)— 穴: 手元の機材との結びつけ / 盤ごと作り込める
- Global Sampler(nvk 系の紹介記事で「誰もが入れるべき」)— 穴: 鳴った音をあとから拾えない
- (未確認・記憶)FX Devices(Bryan Chi)は「REAPER に Bitwig 風の横並びデバイス列を作る」スクリプトとして話題になった覚えがあるが、今回の検索では出ず

**VCV Rack**
- Fundamental(VCV 公式)— 基準。「この密度を真似れば外さない」
- Stoermelder PackOne(54 個)— 穴: モジュールの組み合わせの保存(STRIP)、何にでも MIDI を割り当てる(MIDI-CAT)など、本体の操作の穴
- MindMeld MixMaster — 穴: 本格的な卓がない / 見た目: 卓そのものの密度
- Lights Off — 穴: 暗い部屋で使えない / 灯りだけ光る
- 嫌われ例: Thexor(まぶしい配色)、Vult(絵を変えられない)、立体的なつまみ(古臭い)

## 5. 「よい盤とは何か」を書いた・測った例

- 測った例は見つからず。書いた例は次の通り(公式指針は今回の主眼から外したが、場所として記録)
  - Ableton「Max for Live Production Guidelines」(GitHub: Ableton/maxdevtools)— 横幅を最小に、Live のテーマに従え、等
  - VCV「Panel」マニュアル https://vcvrack.com/manual/Panel — 本物の機械のつもりで、親指が入る間隔、短いラベル、Fundamental の密度に合わせる
  - VCV 掲示板の論争 3 本(上記)が、使い手の本音の一番濃い場所
- 共通して出る芯: 「密度」「横幅を食わない」「本体の顔に揃う(native)」「中身が見える動き」「まぶしくない」

## 6. 未到達・次に見る場所

- maxforlive.com の現在の総数と人気順(403)
- Reddit・X・Threads・YouTube の題名そのもの(検索結果に出ず)
- 日韓中の SNS での褒め言葉(まとめ記事は英語の訳ばかり)
