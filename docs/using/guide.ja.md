# Motolii ガイド

[English](guide.md)

Motolii の長い案内です。何ができるか、ビルドして開くまでの手順、画面の見方、最初の 1 本、ネットのエフェクトの追加、他のソフトとの違い、作り。短い版は [README](../../README.ja.md)、タブごとの紹介は [タブの紹介](screen_tour.ja.md)、ファイルの種類ごとの置き場所は [`shelves/README.ja.md`](../../shelves/README.ja.md) にあります。

## エフェクトとスクリプト

Motolii では、ほかのソフトや Web サイトで公開されているエフェクトを読み込めます。

例えば、Shadertoy のシェーダーや p5.js のスケッチは、コードをコピーして貼り付けることでレイヤーとして利用できます。読み込んだあとも、キーフレームを設定したり、ほかのエフェクトと組み合わせたりできます。

ISF、WGSL、AviUtl2 のスクリプトにも対応しています。ファイルを指定のフォルダに追加すると、アプリを再起動せずにエフェクト一覧へ反映されます。

新しく追加したエフェクトにはプレビューが自動生成されるため、名前だけでなく、実際の見た目を確認しながら選べます。

※ 対応形式のコードでも、すべてが正しく動作するわけではありません。動作検証の結果は[仕様](specifications.ja.md#対応形式と動作状況)にあります。

![配られている ISF の効果 8 本を写真と文字に掛けた所](../pictures/effects.jpg)

*配られている ISF の効果 8 本を、写真（パブリックドメイン）と文字に掛けた所。どれも作者のファイルのまま。*

## 編集操作

操作方法は Alight Motion を参考にしています。

文字や図形はプレビュー画面上で直接移動・変形できます。Animate を有効にすると、値の変更をキーフレームとして記録できます。キーフレーム間のイージングも調整できます。

エフェクトは動くサムネイルから探せます。追加したエフェクトも同じ一覧で管理できます。

また、2D と 3D を切り替える必要はなく、文字、画像、動画、3D モデルなどを同じシーンに配置できます。

## 映像制作

タイムライン上で素材を配置し、エフェクトやキーフレームを使ってアニメーションを制作できます。

動画や音声の読み込み、Lottie アニメーション、MIDI を利用したアニメーションにも対応しています。

完成した映像は MP4 形式で書き出せます。

![光る文字、回るピンクの輪、線の模様、色のずれ](../pictures/mv.gif)

*Motolii で作った 8 秒。組み立てた後に [`docs/using/make_intro_movie.ja.md`](make_intro_movie.ja.md) の命令を貼れば、同じ物が `~/Movies/Motolii/mv.mp4` にできます。*

## 動作環境と形式

確かめたのは Apple Silicon の Mac だけで、ソースからビルドします。動く形式（数えた結果つき）、書き出せる形式、速さは[仕様](specifications.ja.md)にあります。

## 試す前に

- **いま試すと良い人**：Apple Silicon の Mac があり、ターミナルにコマンドを貼ってビルドできる人。p5.js、Shadertoy、シェーダーのエフェクト、AviUtl2 のスクリプトを動画に使ってみたい人。
- **まだ待つと良い人**：普段の制作にすぐ使いたい人、Windows の人、アプリを入れるだけで使いたい人。

| | いまの状態 |
|---|---|
| 動く | [仕様](specifications.ja.md#形式ごとの詳しい様子)で「動きます」の物、自動保存と取り消し、再生（動画の音も鳴る）、MP4 への書き出し、タイムライン・インスペクタ・エフェクト一覧 |
| 一部 | AviUtl2 のスクリプト、Alight Motion の機能（数は下の「他のソフトとの違い」） |
| 知っている不具合 | コピーで作るレシピ（Iris・Weave など）のレイヤーに、画面用の `.wgsl` エフェクトをかけると絵が崩れる（シーン全体にかけるのは大丈夫） |
| まだ | Windows、配布できる `.app`（エンジンが Homebrew の部品を読むので、ビルドした Mac の外では動かない）、MIDI の音 |

## 使ってみる

### 要る物

| 物 | 版・大きさ | 入れ方 |
|---|---|---|
| Mac | Apple Silicon（確かめたのは M4、macOS 15.5） | — |
| Xcode | App Store の Xcode（画面のビルドに要る。Command Line Tools だけでは足りない）。10 GB を超えることがあり、ダウンロードに 30 分〜1 時間かかることもある | App Store。入れたら一度開いて追加の部品を入れ、`sudo xcodebuild -license accept` |
| Homebrew | — | [brew.sh](https://brew.sh/ja/) の 1 行 |
| Flutter | 3.47.2（stable）。約 2 GB | 下の「Flutter を入れる」 |
| Python 3 | macOS に付いている物（Xcode を入れると入る）でよい | — |
| 空き容量 | Xcode と Flutter のほかに約 10 GB（ビルド後で 8.1 GB） | — |
| ダウンロード量 | 約 1 GB（Filament のソース 635 MB、Skia 65 MB ほか。Homebrew の物は別） | — |
| 時間 | Xcode と Flutter を入れる所からなら 1〜2 時間（回線しだい）。それらがあれば初回 約 10 分（M4。Filament 約 5 分、エンジン 約 1〜2 分、画面 約 1〜3 分） | — |

確かめた Homebrew の版：GStreamer 1.28.8、SQLite 3.53.4、LuaJIT 2.1、QuickJS-ng 0.17.0、ffmpeg 9.0、cmake 4.1、ninja 1.13、meson 1.12。

### Flutter を入れる

```bash
git clone --depth 1 --branch 3.47.2 https://github.com/flutter/flutter.git ~/flutter
```

```bash
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zprofile && source ~/.zprofile
```

```bash
flutter doctor
```

`Xcode` と `macOS` の行に ✓ が付けば成功です（Android や Chrome の行は ✗ でかまいません）。FVM を使う人は `app/.fvmrc` に版が書いてあります。

### ビルドして開く

ターミナルで 1 つずつ貼ります。2 つ目からは、`motolii` のフォルダの中で（`cd motolii` した後で）走らせます。

```bash
git clone https://github.com/oshikaidesu/motolii.git
```

```bash
cd motolii
```

```bash
brew bundle
```

`Brewfile` の物（GStreamer・SQLite・ffmpeg・cmake など）が入ります。最後に `Homebrew Bundle complete!` と出れば成功です。

```bash
engine/build.sh
```

エンジンをビルドします。初回は Filament（WebGPU）をソースから組み（M4 で約 5 分）、ThorVG・Skia・libtess2 などをダウンロードします。`engine/out/libmotolii.dylib` ができれば成功です。

```bash
app/tool/live.sh
```

アプリが開きます（初回はビルドで 1〜3 分止まって見えます。ターミナルに流れる文字は気にしなくてかまいません）。プロジェクトファイルは `~/Movies/Motolii/Untitled.motolii`（自動で保存）、書き出した動画もその隣にできます。ウィンドウを閉じると終わり、ターミナルを閉じてもウィンドウは閉じます。次からは、新しいターミナルで `cd ~/motolii && app/tool/live.sh`（ホームのフォルダで `git clone` した時）。

### 画面の見方

![画面の 7 つの区画に番号を付けた図](../pictures/panels.jpg)

1. **上の帯**：プロジェクト名、画面サイズ、fps、長さ、取り消し・やり直し、Render（書き出し）。
2. **[左のタブ](screen_tour.ja.md#左のタブ)**：Media（素材）、Effects（エフェクト）、Fonts（書体）、Colors（色）、Create（図形とレシピ）、Program（貼ったコード）、Presets（保存した組み合わせ。まだ使えません）。
3. **[プレビュー（Stage）](screen_tour.ja.md#プレビューのタブ)**：見ながら置く・動かす所。左の縦の列が道具（選択・移動・図形・ペン・文字など）。上のタブで Camera View（カメラから見た仕上がり）に切り替えます。
4. **インスペクタ**：選んだレイヤーの値（Transform・Anchor・Blend・Fill など）。上に、そのレイヤーにかかっている関係が並びます。
5. **タイムライン**：レイヤーとキーフレーム、再生、マーカー、BPM。
6. **Ease**：キーフレームの間の動き方。右の列が曲線の見本です。
7. **[右下のタブ](screen_tour.ja.md#右下のタブ)**：Camera（レンズとピント）、Desk（道具）、Relations（複数のレイヤーをまとめて動かす）。

タブごとの絵と使い方は [タブの紹介](screen_tour.ja.md) にあります。

### 最初の 1 本（画面で）

<img src="../pictures/window_step1.jpg" alt="1：空のプロジェクト" width="560">

1. 左上のタブの 5 つ目（四角に ＋、**Create**）を押し、検索に `Iris` と打ちます。
2. **Iris** のタイルを押し、下の **Create** を押します。プレビューに色の輪が置かれ、タイムラインにレイヤーが 1 本増えます。
   <img src="../pictures/window_step2.jpg" alt="2：レシピ Iris を置いた所" width="560">
3. 輪を選んだまま、タブの 2 つ目（fx、**Effects**）に替えて `Glow` を探し、押して下の **Add** を押します。輪が光り、ボタンが **Remove**（外す）に変わります。
   <img src="../pictures/window_step3.jpg" alt="3：Glow をかけた所" width="560">
4. 右上の **Render** を押すと、書き出しのダイアログが出ます。名前（例 `first`）を入れて、ダイアログの **Render** を押します。
   <img src="../pictures/window_step4.jpg" alt="4：書き出しのダイアログ" width="560">
5. プロジェクトの隣に `first.mp4` ができ、上に `Written: first.mp4` と出ます。
   <img src="../pictures/window_step5.jpg" alt="5：書き出した所" width="560">

### ネットのエフェクトを 1 本追加する

Motolii の一番の使い方です。例として、[ISF-Files](https://github.com/Vidvox/ISF-Files) の `ASCII Art.fs`（Motolii には同梱していない物）を使います。

1. エフェクトのファイル（`.fs`）をダウンロードします。例：ISF-Files のページで `ISF/ASCII Art.fs` を開き、右上の **Download raw file**（↓ のボタン）を押します。
2. Finder で ⌘⇧G を押し、`~/Library/Application Support/Motolii/` と打って開きます。中に `effects` フォルダを作り（無ければ）、ファイルを入れます。
3. Effects タブに、すぐ出ます（再起動は要りません）。サムネイル（気球の写真にそのエフェクトをかけた見本）も数秒で自動で作られ、ポインタを乗せると動きます。既定の値では見た目が変わらない物には **NO CHANGE** と出ます。レイヤーを選んで、タイルを押し、下の **Add** を押します。
   ![Effects タブに ASCII Art が出た所](../pictures/drop_shelf.jpg)
4. プレビューでも書き出しでも、こうなります（写真に ASCII Art をかけた所）。
   ![写真に ASCII Art をかけて書き出した所](../pictures/drop_ascii.jpg)

WGSL（`.wgsl`）、Create のタイル（`.js` を `create/` に）、Expression のタイル（`.js` を `expressions/` に）、関係（`.js` を `relations/` に）、Ease のプリセット（`.way` を `ease/` に）、スキン（フォルダごと `skins/` に）、AviUtl2 のスクリプト（作者のフォルダごと `aviutl_scripts/` に）も同じように置けます。保存したファイル名の最後が `.fs` になっているか確かめてください（ブラウザが `.txt` を付けることがあります）。

p5.js と Shadertoy は、置かずに貼ります。作品のコードをコピーして、アプリで ⌘V。コードは Program タブに残ります。

### 次に：自分の素材で

- **プロジェクトのサイズ**：上の `1920 × 1080` を 2 回押して打ち直します（縦の MV なら `1080x1920`）。
- **曲を置く**：mp3・wav・m4a なども Media から **Place** で置けます（書き出しにも入ります）。
- **動画・写真を置く**：左のタブの 1 つ目（**Media**）で `Home` から自分のフォルダを開き、ファイルを選んで下の **Place**。動画の音は再生中に鳴り、書き出しにも入ります。
- **文字を置く**：プレビューの左の道具から **T** を選んでプレビューを押すと、文字のレイヤーができます。文字はインスペクタの文字欄で変えます。書体は左のタブの 3 つ目（**Fonts**）から。
- **動かす**：インスペクタの **Animate all** を入れてから、値（位置・大きさなど）を横にドラッグします。今の時刻にキーフレームが打たれます。時刻を変えてもう一度ドラッグすると、その間が動きます。動き方は下の **Ease** で選びます。
- **保存・開く**：保存は自動です（上に `Saved 時刻`）。新しいプロジェクトはメニューの **File › New Document**（⌘N）、同じフォルダの別のプロジェクトは **File › Open**。

<details>
<summary><b>最初の 1 本（コマンドで）</b></summary>

画面を使わずに、レシピで絵を作り、光（Glow）とシーン全体の RGB のずれ（`rgbshift.wgsl`）をかけて、8 秒の MP4 に書き出す例です。`engine/edit.sh` はプロジェクトファイルを開いて、1 行ずつの命令を受けます（`help` で一覧）。

```bash
engine/edit.sh $HOME/Movies/Motolii/first_cmd.motolii <<EOF
make Weave
effect 1 Glow
say 0 script $PWD/shelves/effects/glitch/rgbshift.wgsl
write $HOME/Movies/Motolii/first_cmd.mp4
EOF
```

![最初の 1 本：線の模様が波打ち、色がずれる](../pictures/first.gif)

- `make Weave`：レシピ「Weave」でレイヤー 1 を作る（`recipes` で一覧）。
- `effect 1 Glow`：レイヤー 1 にエフェクトをかける（`effects` で一覧）。
- `say 0 script …`：0（シーンそのもの）にシーン全体のエフェクトを置く。
- `write …`：MP4 に書き出す。
- 同じ命令をもう一度走らせると、同じプロジェクトにレイヤーがもう 1 つ増えます。やり直すなら先に `rm ~/Movies/Motolii/first_cmd.motolii`。

上の 8 秒の作例の命令は [`docs/using/make_intro_movie.ja.md`](make_intro_movie.ja.md)。

</details>

<details>
<summary><b>困ったら</b></summary>

| 出た事 | 直し方 |
|---|---|
| `flutter: command not found` | 上の「Flutter を入れる」の 2 行目をもう一度。別の場所なら `FLUTTER=/path/to/flutter app/tool/live.sh` |
| `brew: command not found` | [brew.sh](https://brew.sh/ja/) の 1 行で Homebrew を入れる |
| `xcrun: error` や、Xcode が無いと言われる | App Store で Xcode を入れ、一度開いて追加の部品を入れ、`sudo xcodebuild -license accept` |
| `No space left on device` | 空きを 10 GB 以上にしてから、止まったコマンドをもう一度 |
| `git clone` や `build.sh` がネットの途中で止まった | 同じコマンドをもう一度。直らなければ `engine/third_party/` の中の止まった物のフォルダを消してからもう一度 |
| `ld: library 'webgpu_dawn' not found` | `engine/build.sh` をもう一度（Filament を組む所から始まる） |
| アプリは開くがプレビューが黒い | エンジンをビルドしたか確かめる（`engine/out/libmotolii.dylib` があるか）。無ければ `engine/build.sh` |

それでも止まったら [Issue](https://github.com/oshikaidesu/motolii/issues) に、走らせたコマンドと出た文をそのまま貼ってください（ひな型があります）。使い方の質問は [Discussions](https://github.com/oshikaidesu/motolii/discussions) へ。日本語・英語のどちらでも。

</details>

<details>
<summary><b>更新する・消す</b></summary>

- 更新：`git pull` の後、`engine/build.sh` をもう一度（変わった所だけビルドし直します）。アプリは `app/tool/live.sh` がビルドし直します。
- 消す：`motolii` のフォルダを消します（ダウンロードした物とビルドした物は全部この中）。作ったプロジェクトと動画は `~/Movies/Motolii/` に残ります（別の所に置いた物はそこに）。Flutter は `~/flutter` を消します。`brew bundle` で入れた物は `brew uninstall` で。

</details>

## 他のソフトとの違い

<details>
<summary>表で比べる</summary>

| | Motolii | After Effects | Cavalry | Alight Motion | Blender | VDMX・TouchDesigner | Motion Canvas・Rive |
|---|---|---|---|---|---|---|---|
| 主な使い道 | MV の映像を作って書き出す | 映像の合成 | 2D のモーショングラフィックス | スマホで映像 | 3D 全般 | ライブの映像（演奏） | コードで映像（Motion Canvas）、アプリの中のアニメーション（Rive） |
| 2D と 3D | 一つのシーン（Filament） | 2D と 3D のレイヤー | 2D が中心 | 2D が中心 | 3D が中心 | 両方（組み方による） | 2D |
| 動く所 | macOS（Apple Silicon）だけ | Windows・macOS | Windows・macOS | iOS・Android | Windows・macOS・Linux | VDMX は macOS、TouchDesigner は Windows・macOS | ブラウザ・各種 |
| 成熟度 | 開発中、作者 1 人、リリース無し | 長く使われている | 製品 | 製品 | 長く使われている | 製品 | 使われている |
| 値段・ライセンス | 無料、Apache-2.0 か MIT | 有料 | 有料（無料版あり） | 有料（無料版あり） | 無料、GPL | 有料（無料版あり） | Motion Canvas は無料・MIT、Rive は無料版あり |

</details>

**違い**：ISF をそのまま読むソフトは他にもあります（VDMX・MadMapper）。Motolii の違いは、ISF・WGSL・AviUtl2 のエフェクト、p5.js と Shadertoy の貼り付け、Filament の 3D、タイムライン、MP4 の書き出しを一つにした組み合わせです。

**まだできない事**：ソフトとしての安定と機能の数は、これからです。配布できるアプリが無い事、Windows で動かない事、ライブで演奏する使い方は考えていない事。

**操作の手本が Alight Motion な訳**：スマホで MV を作る人が慣れている触り方を、まず全部なぞってから、その先へ行くためです。Alight Motion の効果 169 と機能 32 のうち、Motolii に有るのは 101、一部が 37、無いのが 62、未確認が 1 です（10 月末の数え、[`docs/design/alight_motion_map.md`](../design/alight_motion_map.md)）。

## 作り

```mermaid
flowchart LR
  W["アプリの画面<br/>Flutter（app）"] -- "C の呼び出し<br/>motolii.h" --> E["エンジン libmotolii.dylib<br/>（engine/）"]
  E --> F["Filament<br/>3D・最後の合成"]
  E --> T["ThorVG<br/>2D・文字"]
  E --> G["GStreamer・ffmpeg<br/>動画の読み込み・書き出し"]
  E --> S["SQLite<br/>プロジェクトファイル（.motolii）"]
  F --> D["Dawn（WebGPU）"]
  T --> D
  E -- "描いた絵をコピーせずに" --> W
```

画面は操作だけで、絵はエンジン（`engine/`）が描きます。Google の Filament はビルドの時にダウンロードします。エンジンの入口は [`engine/README.md`](../../engine/README.md)、全体の作りは [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) にあります。

## これから

1. 配布できる `.app`（Homebrew の部品を中に入れる）を作り、Releases に置く。
2. Windows 版。
3. AviUtl2 のスクリプトで足りない呼び出し（`obj.computeshader`、本体のエフェクトなど）と、TSL の表現をエフェクト一覧に。
4. Alight Motion の機能を揃える。
