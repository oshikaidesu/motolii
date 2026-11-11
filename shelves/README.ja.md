# shelves/ — 見つけた表現を置く所

[English](README.md)

Motolii に最初から入っている表現と、見つけた表現を置く場所です。ファイルを置く人は、まず次の「見つけたファイルはどれか」を読んでください。

置くのは利用者のフォルダの中です（Mac は `~/Library/Application Support/Motolii/`、Windows は `%APPDATA%\Motolii\`、`MOTOLII_OWN` で変更可）。そこに下と同じ名前のフォルダを作ってファイルを置くと、再起動なしで同じ所に並びます。同じ名前のファイルなら、利用者の物が勝ちます。

## 見つけたファイルはどれか

上から見て、最初に当てはまる行のフォルダに置きます。フォルダは利用者のフォルダの中です（上のとおり）。

| 見つけた物 | 置く所 |
|---|---|
| ISF のシェーダー（`.fs`）、WGSL（`.wgsl`） | `effects/`（中の分類フォルダはどれでもよい） |
| 1 つの動きを、コピーや文字を 1 つずつ（`i` 番目に）決める JavaScript（`function each`） | `expressions/` |
| 文字を動かす CodePen のペンの CSS（`@keyframes`。Splitting.js の `.char`・`.word` を使うもの） | `expressions/`（`.css`。同じ名前の `.html` を隣に置くと、ペンの HTML として使う）。文字レイヤーに ⌘V で貼ってもよい |
| 複数のレイヤーを、お互いの位置を見ながらまとめて動かす JavaScript（`function relate`・`function force`） | `relations/` |
| 1 回で図形や絵を作る物（先頭に `// make` の行がある `.js`）、点を並べるスクリプト、p5.js のスケッチのファイル | `create/` |
| 動きの緩急の式（`.way`） | `ease/` |
| 値と効果のひとまとまり（`.motolii`） | `looks/` |
| 3D の形（`export function solid` を持つ `.js`） | `solids/` |
| アプリの見た目 | `skins/`（フォルダごと） |
| AviUtl2 のパッケージ | `aviutl_scripts/`（フォルダごと） |
| Shadertoy・GLSL Sandbox・twigl・Bonzomatic のシェーダー、p5.js・Dwitter・tixy・Turtletoy・Two.js・Paper.js・Hydra などのコード | **置かずに貼る**。コードをコピーして、アプリで ⌘V。Program タブに残ります（Hydra は先に `extensions/hydra/get.sh`） |

ファイルは頭の数行で自分の名前とつまみを言います。下の「頭の書き方」を見てください。

## `.js` の決まり

どの `.js` も、先頭の `//` の行（頭）に名前とつまみを書き、その後ろにコードを書きます。頭は、`//` で始まる行と空行が続く間です。コードの行が来たところで終わります。

### 動き：`expressions/`（`function each`）

コピー 1 つずつ、その位置と形を返します。

```js
// Rise: each copy lifts a little higher than the one before, and fades in
// --track@height:Height,0,2,0.5,0.01
function each(i, n, t, k) {
  return { y: k.height * i / Math.max(1, n - 1), opacity: Math.min(1, t * 2) };
}
```

| 項目 | 中身 |
|---|---|
| 関数の名前 | `each`（普通のスクリプトとして走るので、`import` は使えません） |
| `i` | このコピーの番号（0 から） |
| `n` | コピーの数。テキストでは、分割（Split）で分けた数：文字ごと・単語ごと・行ごと（Lines：テキスト自身の改行で切った 1 行が 1 コピー。行は自分の中央を軸に回り、拡大します） |
| `t` | レイヤーが始まってからの秒 |
| `k` | 頭で宣言したつまみ。`--track` と `--check` は数（check は 0 か 1）、`--select` は選んだ言葉。ほかに `k.duration`（レイヤーの長さ・秒。0 以下は未設定）、`k.round`（プロジェクトの長さ・秒）、`k.px`（プロジェクトの 1 ピクセルのステージの単位）、`k.id`（このレイヤーの番号）、`k.time`（プロジェクトの今の秒。`t` はレイヤーの始まりから数える） |
| `at`（5 つ目。省略可） | `at.x`・`at.y`・`at.z`：このコピーが、このレイヤーのスクリプトと前の expression で、ここまでに置かれた場所（無ければ 0） |
| 返す物 | オブジェクト。読む名前は `x`・`y`・`z`（ステージの単位）、`size`・`scale_x`・`scale_y`・`scale_z`（1 でそのまま）、`rotate`・`rotate_x`・`rotate_y`（度）、`opacity`（0〜1）、`colour`（立体のコピーの色）。書かなかった名前や数でない値は、そのままです |
| ほかの expression と重なる時 | 位置と角度は足し、`size`・`scale_*`・`opacity` は掛けます。`colour` は最後に返した物 |
| 使える関数 | `ease(名前, u)`（`u` は 0〜1。名前は `SlowIn` `SlowOut` `SlowInSlowOut` `VerySlowIn` `VerySlowOut` `SpringOut` `SmallSpringOut` `BounceOut` `Overshoot`。ほかの名前は `u` を返す）。`animate(i, n, t, k, a)`（Cavalry の Animator と同じ形。`a` は `{ what, from, to, way }`、ほかに `out`・`random`・`seed`。`k.length`・`k.delay` を読むので頭で宣言します。例：`expressions/fade_in.js`）。`cavalry.random(low, high, seed, sequence)`。After Effects の式は `AE.compile`・`AE.run`（例：`create/repeats/ae_stagger.js`） |
| ほかのレイヤーを読む | `layerValue(id, 名前, t, 無い時の値, コピー)`：レイヤー `id` の値（`x`・`y`・`z`・`size`・`rotate`・`rotate_x`・`rotate_y`・`opacity`）。`sampleImage(id, 点, 半径, postEffect, t)`：After Effects の `sampleImage`。レイヤー `id` の絵の、`点` のまわり `半径`（`[x, y]`。省くと半ピクセル）の四角の平均 `[赤, 緑, 青, アルファ]`（0〜1）。点はそのレイヤーのピクセル（`[0, 0]` は左上のピクセルの中心）。画像レイヤーはファイルを、動画レイヤーは `t` 秒に出ているコマを読みます。ほかのレイヤーと絵の外は `[0, 0, 0, 0]`。`postEffect` は受け取るだけで、まだ使いません（マスク・キー・エフェクトの前のファイルを読みます）。`fromWorld(id, 点, t)`：After Effects の `fromWorld`。ステージの点（ステージの単位）が、レイヤー `id` のどのピクセルかを返します。頭の `// --picture@video:Video` はカードで選ぶレイヤーで、`k.video` がその番号。`layerValue(k.id, 'x', k.time, 0, i)` は、このレイヤーのコピー `i` が、この expression が動かす前にいる場所です（例：`expressions/away_from_dark.js`。文字が下の動画を読みます）。`getByteFrequencyData(id, 配列, t)`・`getFloatFrequencyData(id, 配列, t)`・`getFloatTimeDomainData(id, 配列, t)`：レイヤー `id`（動画か音）の音を読みます。Web の `AnalyserNode` の同じ名前のメソッド（[W3C Web Audio API](https://www.w3.org/TR/webaudio-1.1/#AnalyserNode)）で、レイヤーの番号を先頭に、秒を最後に足したものです。1 つ目は `Uint8Array` に高さごとの強さ（0〜255）を、2 つ目は `Float32Array` に同じものをデシベルで入れます（バイトは −100 dB〜−30 dB）。高さは 1024 個で、`i` 番目は `i` × 23.4375 Hz。48,000 Hz のページで、初めの設定のままの `AnalyserNode`（`fftSize` 2048）に毎秒 60 回たずねた時の数です。短い配列には低い方から入ります。3 つ目は `Float32Array` に波の最新 2048 サンプル（−1〜1）を入れます。レイヤーが出ていない時と音が無い時は無音。同じ秒はいつも同じ数です。頭の `// --sound@sound:Sound,fft,512` はカードで選ぶ音のレイヤーで、`k.sound` がその番号（例：`expressions/rise_to_sound.js`。文字が 1 つずつ自分の高さの音で上がります）。この 6 つのどれかを書いたファイルは 1 スレッドで走ります |
| 使えない物 | p5.js の関数と定数（`sin`・`PI`・`random`・`noise`・`createVector` など）。`Math.sin` のように書きます |

### 関係：`relations/`（`function relate` か `function force`）

たくさんのレイヤー（`things`）を一度に受け取ります。p5.js が走るので、`sin`・`TWO_PI`・`lerp`・`constrain`・`noise`・`createVector`・`ease` などが使えます。

`relate` は新しい値を返します。

```js
// Wave: each goes up and down by where it stands along the row
// --track@height:Height,0,2,.45,0.01
// --track@speed:Speed,0,4,.6,0.01
function relate(things, t, k) {
  return things.map(a => ({ i: a.i, y: a.y + k.height * sin(a.x * 2 + t * k.speed * TWO_PI) }));
}
```

| 項目 | 中身 |
|---|---|
| `things` の 1 つ | `i`（番号）、`id`（レイヤーの番号）、`w`・`h`（今の幅と高さ、大きさを含む）、`near`（0〜1：関係の Falloff の形がどれだけ覆っているか。無ければ 1）、`x`・`y`・`z`・`size`・`rotate`・`rotate_x`・`rotate_y`・`opacity`（今の値） |
| `t`・`k` | 秒、つまみ（上と同じ） |
| 返す物 | `{ i, 変えたい値… }` の配列。書いた値だけが変わり、書かない値はそのまま。何も返さなければ、`things` を直接書き換えた結果を使います |
| 重み | 引数が 3 つの時、結果は `near` で薄められます |
| 4 つ目の引数 | `relate(things, t, k, was)`：前のフレームで返した物（`i` で引く。最初のフレームは `null`）。この時は `near` で薄めません（`near` は自分で使います。例：`relations/stay.js`）。1 フレーム前が要るので、最初から 60 フレーム毎秒で順に走ります |

`force` は押します（d3-force と同じ形）。返す物は無く、`things` を書き換えます。

```js
// Spring: each goes after where it would be left alone, past it and back
// --track@mass:Mass,.05,10,1,0.01
// --track@damping:Damping,0,30,4,0.01
// --track@limit:Speed Limit,0,60,60,0.1
function force(things, t, k) {
  const pull = 1 / (60 * k.mass), keep = 1 - k.damping / 60, most = k.limit / 60;
  things.forEach(a => {
    a.vx = (a.vx + (a.home.x - a.x) * pull) * keep, a.vy = (a.vy + (a.home.y - a.y) * pull) * keep, a.vz = (a.vz + (a.home.z - a.z) * pull) * keep;
    const s = sqrt(a.vx * a.vx + a.vy * a.vy + a.vz * a.vz);
    if (s > most) a.vx *= most / s, a.vy *= most / s, a.vz *= most / s;
  });
}
```

`force` の `things` は、上の値のほかに `vx`・`vy`・`vz`（速さ）、`home`（`x`・`y`・`z`：この関係が無い時の場所）、`index` を持ちます。読み戻されるのは `x`・`y`・`z`・`size`・`rotate`・`rotate_x`・`rotate_y`・`opacity`・`vx`・`vy`・`vz` です。自分で足した値は次のフレームも残ります。ファイルに `d3.` と書くと、d3-force-3d が使えます（例：`relations/collide.js`）。最初から 60 フレーム毎秒で順に走ります。

### レシピ：`create/`（`// make` の行）

先頭の行に名前、その下の行に「命令」を 1 行ずつ書きます。レイヤーを作って値を入れる手順です。コードは無くても構いません。

```js
// White Flash: the stage goes white for an instant where the playhead is, gone in 0.4 seconds
// make shape rect
// here
// say fill ffffff
// fit fill
// set duration 0.4
// key opacity 0 1
// key opacity 0.4 0
```

動きを自分で持つ時は、頭の後ろに `each` を書きます。そのファイルが、最初のレイヤーのスクリプトになります。

```js
// Bobbing Row: five dots that bob one after another
// make shape circle
// say fill ffd166
// set size 0.1
// set copies 5
// --track@height:Height,0,1,0.3,0.01
function each(i, n, t, k) {
  return { x: (i - (n - 1) / 2) * 0.3, y: k.height * Math.sin(t * 4 + i) };
}
```

| 命令 | 意味 |
|---|---|
| `make 種類 中身` | 最初のレイヤーを作る。必ず最初の命令にします（そうでないファイルは一覧に出ません）。`make shape rect`（`rect` `circle` `polygon` `star` `line` `ring` `arc` `arrow` `squircle` `cog` `path` `spiral` `chamfer` `null`）、`make solid cube`（`ring` `gem` `cube` `ball` `sketch`）、`make picture ファイルの道` |
| `then 種類 中身` | もう 1 つレイヤーを作る。以後の `set`・`say`・`key` はそのレイヤーに入る |
| `set 値 数` | 数の値を入れる。数の代わりに `first`（このレシピの最初のレイヤー）、`before`（1 つ前に作ったレイヤー）、`behind`（最初のレイヤーのすぐ下の順）も書けます。値の名前は `engine/document/kinds.h` の表（`size`・`copies`・`opacity`・`duration` など）。スクリプトのつまみは `js_つまみの名前` |
| `say 値 言葉` | 言葉の値を入れる（`fill ff3366`・`path M 0 0 …`・`copy_fill 色 色 …`）。`say script this` はこのファイルのコード、`say script Repeater` は名前で別のレシピ、`say script expressions/wave.js` は棚のファイル |
| `here` | 今のプレイヘッドから始める（無ければプロジェクトの頭から、一緒に回る）。`key` の秒はここから数えます |
| `fit fit` / `fit fill` / `fit stretch` | 絵に合わせる（収める・覆う・引き伸ばす） |
| `key 値 秒 数` | その秒に値のキーを打つ |

守ること：

- `//` の行は、`--` で始まる物（つまみ。次の節）、`--label:`、命令のどれかです。最初の `//` の行から、コードの前までの `//` の行は、命令として読まれます。説明の文を書く時は、命令の言葉（`make`・`then`・`set`・`say`・`here`・`fit`・`key`）で始まらないようにします。ほかの言葉で始まる行は読み飛ばされます。
- ファイルに `function each` がある物は、Create の Expression にも出ます。
- 先頭に `// make` が無く、`function draw`・`function setup`・`createCanvas` がある p5.js のスケッチは、名前をファイル名にして、そのまま 1 つのレシピになります。

### p5.js のスケッチ

```js
function setup() { createCanvas(400, 400); }
function draw() {
  background(20);
  circle(200 + 100 * sin(frameCount / 30), 200, 60);
}
```

- p5.js 1.11.13 がそのまま走ります（ブラウザは無し）。1 秒 60 フレームで、時間は前にだけ進みます。
- 2D は絵になり、プロジェクトに合わせて置かれます。`WEBGL` で描いた `box`・`sphere`・`plane`・`ellipsoid`・`cylinder`・`cone`・`torus` は、3D の立体のコピーになります。
- 描く行ごとに、その行の形の強さを決めるつまみ（`circle 3` のような名前）が 1 つできます。
- `loadImage` の絵は、ファイルと同じ名前のフォルダ（`Fire.js` なら `Fire/`）から、ファイル名だけで読みます。
- p5.sound は、そのファイルを p5 の隣に置くとそのまま走ります（`engine/third_party/js/p5/addons/p5.sound.min.js`。同じ p5 の配布物に入っています。このリポジトリには入れていません）。スケッチは、下にある動画・音のレイヤーを聞きます。`loadSound` はどのファイル名でもその音を返し、`p5.FFT` と `p5.Amplitude` は Chrome と同じ数で読みます。音はタイムラインの位置どおりです。クリックで音を始めるスケッチは、1 回だけクリックされます。スケッチが鳴らす音は書き出しには入らず、オシレーターは無音です。ファイルが無い時は、p5.sound の名前だけがあって無音です。

### 緩急：`ease/`（`.way`）

1 行目に名前、あとに式を書きます。

```
// Snappy: fast away from the first key, a long soft landing on the next
a + (b - a) * bezier(u, .2, 0, 0, 1)
```

`a` は最初のキーの値、`b` は次のキーの値、`u` は間をどこまで来たか（0〜1）、`p1`〜`p4` は数です。`u` が 0 の時は `a`、1 の時は `b` になる式にします。`bezier(u, x1, y1, x2, y2)` と `way('名前', u)` が使えます。

### その他

- `solids/`：`export function solid(k)` が three.js の BufferGeometry を返します。`k` はつまみと、`k.w`・`k.h`（物の幅と高さ）です。見本：`solids/Box.js`。
- `effects/` の `.wgsl`：頭の `--track@` でつまみを宣言し、`fn fs_main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f` で絵を返します。絵は `texture_2d<f32>`、つまみは 1 つの `var<uniform>` の構造体です。構造体に `time`・`frame`・`aspect`・`resolution`・`width`・`height` があれば、ステージが入れます。見本：`effects/glitch/rgbshift.wgsl`。
- `effects/` の `.fs`：ISF（Vidvox の形式）をそのまま置きます。

## 頭の書き方

頭の 1 行目は `// 名前: 説明`。名前は最初の `:` の前です。`.fs` 以外で 1 行目が無い物は、ファイル名が名前になります（`create/` の p5.js のスケッチも同じ）。

つまみは 1 行に 1 つ、`// --種類@名前:ラベル,…` と書きます。名前はコードから `k.名前` で読む名前です。`@` と `:` のどちらも要ります。要らない行（説明）は読み飛ばされます。

| 行 | 意味 |
|---|---|
| `// --track@名前:ラベル,最小,最大,初めの値,刻み` | 数。刻みは省略できます |
| `// --check@名前:ラベル,初めの値` | 入り切り（1 か 0） |
| `// --select@名前:ラベル,言葉1,言葉2,…` | 言葉から 1 つ。最初の言葉が初めの値。`k.名前` は選んだ言葉 |
| `// --picture@名前:ラベル` | 別のレイヤーの絵を読む（効果のみ） |
| `// --sound@名前:ラベル,fft,512` | カードで選ぶ、音を読むレイヤー。`k.名前` がその番号（無ければ 0）。ISF で書いた効果では、その効果の音の入力（`fft` か `wave`、値の数） |
| `// --group:名前` … `// --group` | 間のつまみを、その名前の畳める組にする |
| `// --macro@名前:ラベル,初めの値 -> つまみ 最小 最大, …` | 0〜1 のつまみ 1 つで、ほかのつまみを動かす |
| `// --label:言葉` | 一覧の分類の名前。`create/` では、閉じたパックの印 |
| `// --about:言葉` | 効果の説明（効果の一覧で使う） |
| `// --tag:言葉 言葉` | 効果の検索タグ（`#basic` で当たり前のものが出る）。ファイル自身から読み取るタグに足される |

つまみの代わりに、先頭の `const knobs = { distance: 2, … }`（leva の形）も読みます。

## 置いたあと

保存すると、すぐに出ます（再起動は要りません）。同じファイルを保存し直すと、絵にもすぐ効きます。

- `effects/`：Effects タブにタイルが出ます。レイヤーを選び、タイルを押して **Add**。
- `create/`：Create タブにタイルが出ます。押して **Create**。
- `expressions/`：Create タブの Expression。レイヤーを選んでタイルを押し、**Put on**（そのレイヤーに 1 枚のカードとして付き、つまみはインスペクターに出ます）。何も選ばなければ、新しい物を作ります。
- `relations/`：Create タブの Expression に、エクスプレッションと並んで出ます。グループを選ぶか、レイヤーを 2 つ以上選んで、タイルを押すと、まとめて動きます。1 つのレイヤーなら、そのコピーや文字が動きます。


## フォルダの一覧

| フォルダ | アプリのどこに出るか | 置くファイル | 出る名前 |
|---|---|---|---|
| `effects/` | Effects タブのタイル（レイヤーの効果・画面全体の効果） | `.fs`（ISF）・`.wgsl`・`.js`（three.js）・`.mjs`・`.json`（Filament の設定） | 1 行目の `// 名前:`、無ければファイル名。`.fs` はファイル名そのまま |
| `aviutl_scripts/` | Effects タブのタイル。パッケージ名がチップになる | AviUtl2 のパッケージ（`.anm2`・`.obj2`・`@` ファイル）をフォルダごと、手を入れずに | スクリプトの名前と `--label:`。パッケージ名はフォルダの `__` の後ろ |
| `create/` | Create タブの Recipes（1 回で絵を作る）。`function each` のある物は Expression に、`--label:Cavalry` など閉じたパックは Program タブに出る | `.js` | 1 行目の `// 名前: 何を作るか`。頭の無い p5 のスケッチはファイル名 |
| `expressions/` | Create タブの Expression（文字やレイヤーの出入りの動き、コピーを順に揺らす波。Cavalry の Animators と oscillator） | `.js`（`function each`） | 1 行目の `// 名前:` |
| `relations/` | Create タブの Expression に、エクスプレッションと並んで出る（たくさんのレイヤーを一度に動かす。グループか、いっしょに選んだレイヤーに付ける） | `.js` | 1 行目の `// 名前:`、無ければファイル名 |
| `looks/` | Effects タブのルックのタイル（レイヤーの値・効果・キーを名前で取っておいた物） | `.motolii` ＋ タイルの絵 `.png` | ファイル名そのまま（空白も大文字も） |
| `solids/` | レイヤーの効果カードの 3D の形（Alight Motion の Box・Torus など）。タイルはまだ無く、プロジェクトが名指した時に出る | `.js`（three.js の BufferGeometry を返す `export function solid`） | 1 行目の `// 名前:` |
| `ease/` | 下の Ease のタイル（キーとキーの間の動き方） | `.way`（式 1 行） | 1 行目の `// 名前:`、無ければファイル名 |
| `skins/` | View › Skin の一覧（アプリの見た目の着せ替え） | フォルダごと（`theme.xml` と、あれば絵・書体）。作り方は [`skins/README.md`](skins/README.md) | フォルダ名 |
| `extensions/` | 項目としては出ない。Hydra のコードを貼る前に 1 回だけ使う | `hydra/get.sh` | — |

前の名前（`recipes/`・`animators/`・`ways/`）のフォルダに置いた物も、そのまま読みます。

## 下のフォルダ

`effects/` と `create/` は、下のフォルダまで全部読みます。下のフォルダの名前は画面に出ず、置く人が場所を選ぶための物です。書類は効果やレシピをファイル名で探し直すので、下のフォルダを替えても書類は壊れません。

`effects/` の下は、After Effects の Effects & Presets の分類の名前に合わせています（[Adobe の効果の一覧](https://helpx.adobe.com/after-effects/desktop/apply-effects-and-animation-presets/effects-and-animation-presets/effect-list.html)）。AE に無い物は、なぜ別にしたかを書きます。

| フォルダ | AE の分類 | 置く物 |
|---|---|---|
| `blur/` | Blur & Sharpen | ぼかし・シャープ |
| `color/` | Color Correction | 色・明るさの補正 |
| `distort/` | Distort | 絵を歪める |
| `generate/` | Generate | 絵を作る（波形・模様・切り抜きの形） |
| `stylize/` | Stylize | 絵の見た目を変える（網点・光・縁） |
| `transition/` | Transition | 2 つの絵の切り替え |
| `key/` | Keying と Matte | 色や明るさで抜く・マスク |
| `utility/` | Utility | 見た目より道具の物（アルファ・カラーバー・時刻・タイムコード） |
| `move/` | 無い | 物そのものを時間で動かす（揺れ・繰り返し・回転）。AE では効果でなく式（`wiggle()`・`loopOut()`）でやる事なので、AE の分類に入る先が無い |
| `geometry/` | 無い | 形と 3D の立体・裏返し・回転。AE では Perspective と Generate に分かれる。名前は、ここにある ISF の効果自身が `CATEGORIES` に書く `Geometry Adjustment` から |
| `glitch/` | 無い | 壊れた映像の見た目（データモッシュ・VHS・RGB のずれ）。AE では Stylize と Time に散る。名前は、ここにある ISF の効果自身が `CATEGORIES` に書く `Glitch` から |
| `sources/` | 分類ではない | 効果の出どころ：各パックのライセンス、取り込んだ脚本、タイルを描く見本の写真、AviUtl の効果の対応表。棚の 257 本の効果の頭の出典の行がこの場所を出典として名指すので、名前は替えない |

`create/` の下は、利用者が手にする物の名前です。

| フォルダ | 置く物 |
|---|---|
| `shapes/` | 1 つの形（矢印・ハート・吹き出し…。AbsentMotion の形） |
| `cavalry/` | 点を曲線や立体に並べる配置（Canvalry の Distribution をそのまま） |
| `repeats/` | 1 つの物を何個も並べて、順に動かす模様（AE の Repeater、Cavalry の Duplicator） |
| `over_footage/` | 映像の上に重ねる物（動く物を追う枠・白いフラッシュ・ポスター） |

## 空に見えるフォルダ

- `extensions/hydra/` は `get.sh` しかありません。Hydra（hydra-synth）は AGPL-3.0 なので、このリポジトリにも配る物にも入れません。`get.sh` を走らせると利用者のフォルダの `extensions/hydra/` に取って来て、Motolii はそちらを読みます。消せば元のままです。Hydra のコードを貼る人が取りに来る物なので、ここに置いています。
- `ease/` は見本 1 つ（`snappy.way`）です。プリセットは利用者の持ち物なので、利用者のフォルダの `ease/` に置く物が本体です。

## 名前の決まり

ファイル名を直す前に、上の「出る名前」を見てください。書類は置いた物をファイル名で探すので、一度配ったファイルの名前は、出ない物でも替えません（`create/repeats/ae_grid.js` の `ae_` もそのまま）。

- 1 行目に `// 名前:` がある物（`effects/` の `.js`・`.wgsl`、`create/`、`expressions/`、`relations/`、`solids/`、`ease/`）：ファイル名は出ないので、形は問いません。今あるのは出どころの名前のままです（`solids/` は Alight Motion の名前の空白を `_` にした物、`create/shapes/am_*` は AbsentMotion の形）。
- ファイル名がそのまま出る物（`looks/`、`effects/` の `.fs`、頭の無い p5 のスケッチ `create/repeats/Cube Wave.js` など、`// 名前:` の無い `relations/`）：空白も大文字もそのまま書きます。ISF の `.fs` は配られた時の名前のままです。
- `aviutl_scripts/`：`<作者>__<パッケージ>/` で、AviUtl2 のカタログの作者名とパッケージ名です。中は配られた形のまま、`LICENSE` と `SOURCE.txt` を添えます。
- ここに置くのは 1 つで 1 項目になる物だけです。何かの部品（例：押し出した形の UV を作る `face_uv.js`）は、それを動かすコードの隣（`engine/community/three/`：棚の `solids/` を動かす `solid_three.cpp` の隣）に置きます。`face_uv.js` は Motolii が書いた部品で、持ち込んだ表現ではないので、棚ではなく `engine/` に置きます（AGENTS.md 構成の目標 3）。

## ここに無い物

- 字が足りない時の代わりの書体（Noto Sans JP）と Fonts タブの見本の文、Effects の検索で日本語を英語に引く表（日本語 WordNet）は、置いて増やす物ではなく中身が読むデータなので、ライセンスと一緒に `engine/third_party/` にあります。利用者のフォルダの `fonts/`・`words/` に置いた物は足されます。
- どのフォルダをどのコードが読むかは [`docs/ARCHITECTURE.md` の「棚を読む所」](../docs/ARCHITECTURE.md#棚を読む所)。
- 中身を作る脚本（`effects/sources/`・`create/shapes/absent_shapes.sh`）は手で走らせる物で、組み立ては呼びません。
