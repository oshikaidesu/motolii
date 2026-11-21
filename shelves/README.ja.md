# `shelves/` — 同梱アセットとユーザーコンテンツの配置ガイド

[English](README.md)

Motolii に同梱されているエフェクト・スクリプト・プリセット・スキンの配置場所と、自分で追加するファイルの配置ルールです。

カスタムファイルを追加する場合は、以下の**ユーザーフォルダ**内に同じ名前のフォルダを作成して配置してください：

- **macOS:** `~/Library/Application Support/Motolii/`
- **Windows:** `%APPDATA%\Motolii\`
- **変更する場合:** 環境変数 `MOTOLII_OWN` で任意のフォルダを指定可能

ユーザーフォルダにファイルを置くと再起動なしで即座に反映されます。同梱ファイルと同名の場合はユーザー側のファイルが優先されます。

## ファイル種別ごとの配置先

上から順に最初に一致する行のフォルダ（ユーザーフォルダ内）へ配置してください。

| ファイル・形式 | 配置先 |
|---|---|
| ISF シェーダー（`.fs`）、WGSL シェーダー（`.wgsl`） | `effects/`（サブフォルダ構成は自由） |
| ネイティブ After Effects プラグイン（macOS: `.plugin`、Windows: `.aex`） | `ae_plugins/`（配置またはシンボリックリンク。Motolii 本体には同梱しません） |
| AviUtl2 スクリプトパッケージ（`.anm2`・`.obj2`・`@` ファイル） | `aviutl_scripts/`（パッケージフォルダごと） |
| コピー／文字ごとのアニメーションスクリプト（`function each`） | `expressions/` |
| After Effects エクスプレッション（`wiggle(2, 50)`、`thisComp...` 等） | `expressions/`（式だけを書いた `.js`）。1 行目に `// --property:position`（`rotation` / `scale` / `opacity`）で対象プロパティを指定。省略時は 2 要素配列が位置、単一数値が回転になります |
| CodePen の CSS テキストアニメーション（`@keyframes`、Splitting.js の `.char`・`.word`） | `expressions/`（`.css`、必要に応じて同名の `.html` を併置）。テキストレイヤーへ直接 `⌘V` 貼り付けも可 |
| 複数レイヤー連動スクリプト（`function relate` / `function force`） | `relations/` |
| レイヤーレシピ（`// make` 行付き `.js`）、点配置スクリプト、p5.js スケッチ | `create/` |
| イージング数式プリセット（`.way`） | `ease/` |
| 保存したレイヤールック（`.motolii`） | `looks/` |
| 3D ジオメトリ生成スクリプト（`export function solid` を持つ `.js`） | `solids/` |
| UI スキン | `skins/`（フォルダごと） |
| three.js TSL ページ（`colorNode` や `positionNode` を持つマテリアル） | **貼り付け（`⌘V`）。** 色ノードはエフェクト、頂点変形ノードはジオメトリ変形ファイルとして選択レイヤー（未選択時は画面全体矩形）へ適用され、ユーザーフォルダの `programs/` に保存されます |
| Shadertoy・GLSL Sandbox・twigl・Bonzomatic・p5.js・Dwitter・tixy・Turtletoy・Two.js・Paper.js・Hydra | **ファイル配置ではなく `⌘V` で貼り付け。** Create タブの Code に保存されます（Hydra は初回のみ `extensions/hydra/get.sh` の実行が必要） |

先頭のコメント行で表示名とパラメータを宣言できます（[ヘッダディレクティブ](#ヘッダディレクティブ)参照）。

## `.js` スクリプトの仕様

すべての `.js` ファイルは先頭の連続した `//` コメント行（および空行）をヘッダとして扱い、最初のコード行でヘッダが終了します。

### モーションスクリプト：`expressions/`（`function each`）

コピーや文字 1 つずつ（`i` 番目）のトランスフォーム・スタイルを返します。

```js
// Rise: each copy lifts a little higher than the one before, and fades in
// --track@height:Height,0,2,0.5,0.01
function each(i, n, t, k) {
  return { y: k.height * i / Math.max(1, n - 1), opacity: Math.min(1, t * 2) };
}
```

| 項目 | 仕様 |
|---|---|
| 関数名 | `each`（通常スクリプトとして実行されるため `import` は使用不可） |
| `i` | 0 始まりのコピー番号 |
| `n` | 総コピー数。テキスト分割（Split）時は文字数・単語数・行数（`Lines` は改行ごとに 1 コピーとし、行の中央基準で回転・拡縮） |
| `t` | レイヤー開始からの経過秒数 |
| `k` | ヘッダ宣言パラメータ（`--track`・`--check` は数値、`--check` は `0`/`1`、`--select` は選択文字列）。組み込み値：`k.duration`（レイヤー長・秒、`<= 0` は未設定）、`k.round`（プロジェクト長・秒）、`k.px`（1 ピクセルのステージ単位長）、`k.wide` / `k.high`（コンポジション解像度）、`k.id`（レイヤー ID）、`k.time`（コンポジション現在時刻・秒） |
| `at`（第 5 引数・省略可） | レイヤースクリプトおよび先行エクスプレッションによる累積位置 `{ x, y, z }`（なければ `0`） |
| 戻り値オブジェクト | 読み取るキー：`x`, `y`, `z`（ステージ単位）、`size`, `scale_x`, `scale_y`, `scale_z`（`1` で等倍）、`rotate`, `rotate_x`, `rotate_y`（度）、`opacity`（`0..1`）、`colour`（3D 立体コピーの色）。未指定や非数値のキーは変更されません |
| 複数重ね時の合成 | 位置・回転は加算、`size`・`scale_*`・`opacity` は乗算、`colour` は最後の戻り値を採用 |
| 剛体物理（Jolt Physics） | `mass` を返すと Jolt Physics による 2D 剛体ボックスとして落下・衝突・積み上げをシミュレーションします。`mass: 0` はキーフレームに従う静的／キネマティック剛体（床など）。追加プロパティ：`force`（`[x, y]` ニュートン、複数式で合算）、`gravityFactor`、`restitution`、`friction`。スケールは `1 m = 100 px`。例：`rigid_body.js`・`wind.js` |
| 組み込みヘルパー | `ease(name, u)`（`u` は `0..1`。`SlowIn` / `SlowOut` / `SlowInSlowOut` / `VerySlowIn` / `VerySlowOut` / `SpringOut` / `SmallSpringOut` / `BounceOut` / `Overshoot`、未定義名は `u` を返す）。`animate(i, n, t, k, a)`（Cavalry Animator 互換、`a = { what, from, to, way }`、省略可 `out` / `random` / `seed`。ヘッダに `k.length`・`k.delay` の宣言が必要。例：`expressions/fade_in.js`）。`cavalry.random(low, high, seed, sequence)`。AE 式用：`AE.compile` / `AE.run`（例：`create/repeats/ae_stagger.js`） |
| 他レイヤー・音声 API | `layerValue(id, name, t, fallback, copy)`、`sampleImage(id, point, radius, postEffect, t)`、`fromWorld(id, point, t)`（詳細は下の「リレーション」参照）。`// --picture@video:Video` でカードからレイヤーを選択可能（`k.video` にレイヤー ID）。`layerValue(k.id, 'x', k.time, 0, i)` で適用前位置を参照可能（例：`expressions/away_from_dark.js`）。音声：`getByteFrequencyData(id, array, t)`・`getFloatFrequencyData(id, array, t)`・`getFloatTimeDomainData(id, array, t)`（`// --sound@sound:Sound,fft,512` と併用。例：`expressions/rise_to_sound.js`）。これら 6 関数を使うファイルはシングルスレッド実行になります |
| 使用不可 | p5.js のグローバル関数・定数（`sin`・`PI`・`random`・`noise`・`createVector` 等）。標準の `Math.*` を使用してください |

### リレーション：`relations/`（`function relate` / `function force`）

複数レイヤー（`things`）を一括で制御します。p5.js 環境で実行されるため、`sin`・`TWO_PI`・`lerp`・`constrain`・`noise`・`createVector`・`ease` 等が利用できます。

`relate` は更新したいプロパティの配列を返します：

```js
// Wave: X 座標に応じて各レイヤーを上下に波打たせる
// --track@height:Height,0,2,.45,0.01
// --track@speed:Speed,0,4,.6,0.01
function relate(things, t, k) {
  return things.map(a => ({ i: a.i, y: a.y + k.height * sin(a.x * 2 + t * k.speed * TWO_PI) }));
}
```

| 項目 | 仕様 |
|---|---|
| `things[i]` のプロパティ | `i`（インデックス）、`id`（レイヤー ID）、`w`・`h`（スケール込みの現在幅・高さ）、`near`（`0..1`：Falloff シェイプの重み、無ければ `1`）、`from`（参加時の `{ x, y }`、不明時は `NaN`。`a.x + target - a.from.x` でユーザー移動量を保持可能。例：`relations/Row.js`）、および `x`, `y`, `z`, `size`, `rotate`, `rotate_x`, `rotate_y`, `opacity` |
| `t`, `k` | コンポジション現在時刻（秒）と宣言パラメータ。`// --picture@leader:Leader` で対象レイヤーを選択可能（`k.leader` がレイヤー ID、未選択時 `0`） |
| `layerKeys(id, name)`, `layerNamed(name)` | レイヤー `id` のプロパティ `name` のキーフレーム時刻配列（昇順、無ければ `[]`）／名前からレイヤー ID を取得（無ければ `0`） |
| `layerValue(id, name, t, fallback, copy)` | 時刻 `t` のレイヤー `id` の値（`x`, `y`, `z`, `size`, `rotate`, `rotate_x`, `rotate_y`, `opacity`、リレーション適用後）を返します（キー未設定時は `fallback`、例：`relations/Follow.js`）。`copy`（0 始まり）指定時はテキスト文字などの中心座標を返します（例：`relations/Letter.js`）。対象外プロパティは `NaN` |
| `sampleImage(id, point, radius, postEffect, t)` | After Effects 互換の `sampleImage`。レイヤー `id` のピクセル座標 `point`（`[0, 0]` が左上ピクセル中心）周辺 `radius`（`[rx, ry]`、省略時 `0.5 px`）のアルファ加重平均 `[r, g, b, a]`（`0..1`）を返します。画像は元ファイル、動画は時刻 `t` のフレームを参照（範囲外や他種別は `[0, 0, 0, 0]`）。`postEffect` は引数として受け取りますが現状はエフェクト適用前を参照します |
| `fromWorld(id, point, t)` | ステージ単位の座標（`[x, y]` または `[x, y, z]`）を時刻 `t` におけるレイヤー `id` のピクセル座標に変換します（`sampleImage` へ渡す用途）。画像を持たないレイヤーでは `[NaN, NaN]` |
| `getByteFrequencyData`, `getFloatFrequencyData`, `getFloatTimeDomainData` | Web Audio API の `AnalyserNode`（[W3C 仕様](https://www.w3.org/TR/webaudio-1.1/#AnalyserNode)）互換関数。引数 `(id, array, t)` で動画・音声レイヤーの音を解析します。周波数ビン 1024 本（`i` 番目 = `i × 23.4375 Hz`、`48 kHz`・`fftSize = 2048` 相当）、バイト値は `-100 dB..-30 dB` を `0..255` にマッピング。時間波形は直近 2048 サンプル（`-1..1`）。同一時刻では常に同一結果を返し、非表示・無音時は 0 |
| `lag` パラメータ | `lag` という名前の track を宣言すると、各レイヤーの Strength 評価時刻を順に `lag` 秒ずつずらします（例：`relations/Group.js`） |
| 戻り値 | `{ i, ...変更プロパティ }` の配列。何も返さない場合は `things` への破壊的変更をそのまま反映 |
| Falloff 重み付け | 引数 3 つ（`things, t, k`）のときは結果の差分に自動で `near` を掛けます |
| 第 4 引数（状態保持） | `relate(things, t, k, was)` とすると前フレームの戻り値（`i` で参照、初回は `null`）を受け取ります。この場合 `near` は自動適用されないため自前で掛けてください（例：`relations/stay.js`）。`t = 0` から 60 fps で逐次シミュレーションされます |

`force` は `d3-force` 形式で `things` を直接更新します（戻り値なし）：

```js
// Spring: 元の位置へ減衰バネで引き戻す
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

`force` では `vx`・`vy`・`vz`（速度）、`home`（基準位置 `{ x, y, z }`）、`index` が追加されます。読み戻されるのは `x`, `y`, `z`, `size`, `rotate`, `rotate_x`, `rotate_y`, `opacity`, `vx`, `vy`, `vz` で、独自に追加したプロパティも次フレームに引き継がれます。コード内で `d3.` を参照すると `d3-force-3d` が有効になります（例：`relations/collide.js`）。60 fps で逐次シミュレーションされます。

### レシピ：`create/`（`// make` コマンド）

1 行目に名前、続けてレイヤー生成とプロパティ設定のコマンドを 1 行ずつ記述します（コード本体は省略可能）。

```js
// White Flash: 再生ヘッド位置で 0.4 秒間フラッシュする
// make shape rect
// here
// say fill ffffff
// fit fill
// set duration 0.4
// key opacity 0 1
// key opacity 0.4 0
```

ヘッダの後ろに `function each(...)` を書くと、このファイル自体が最初のレイヤーのスクリプトとして設定されます：

```js
// Bobbing Row: 5 つの円が位相をずらして上下に揺れる
// make shape circle
// say fill ffd166
// set size 0.1
// set copies 5
// --track@height:Height,0,1,0.3,0.01
function each(i, n, t, k) {
  return { x: (i - (n - 1) / 2) * 0.3, y: k.height * Math.sin(t * 4 + i) };
}
```

| コマンド | 意味 |
|---|---|
| `make <種別> <値>` | 最初のレイヤーを生成（必ず先頭コマンドにする）。シェイプ：`make shape rect`（`rect` / `circle` / `polygon` / `star` / `line` / `ring` / `arc` / `arrow` / `squircle` / `cog` / `path` / `spiral` / `chamfer` / `null`）、立体：`make solid cube`（`ring` / `gem` / `cube` / `ball` / `sketch`）、画像：`make picture <パス>` |
| `then <種別> <値>` | 追加レイヤーを生成。以降の `set`・`say`・`key` はこのレイヤーに適用 |
| `set <プロパティ> <数値>` | 数値プロパティを設定（名称は `engine/document/kinds.h`、スクリプトパラメータは `js_<名前>`）。特殊値：`first`（最初のレイヤー ID）、`before`（直前のレイヤー ID）、`behind`（最初のレイヤーの直下順） |
| `say <プロパティ> <文字列>` | 文字列プロパティを設定（`fill ff3366`、`path M 0 0 ...`、`copy_fill ...`）。`script` では `this`（このファイル自身）、別レシピ名（例：`Repeater`）、棚パス（`expressions/wave.js`）を指定可能 |
| `here` | 現在の再生ヘッド位置を開始時刻にする（省略時は `t = 0`）。`key` の時刻はこの開始点からの相対秒 |
| `fit fit` / `fit fill` / `fit stretch` | コンポジションに合わせて収める／覆う／引き伸ばす |
| `key <プロパティ> <秒> <数値>` | 指定秒にキーフレームを設定 |

注意点：
- ヘッダ内の説明コメントはコマンドキーワード（`make`・`then`・`set`・`say`・`here`・`fit`・`key`）で始めないようにしてください（それ以外の行は無視されます）。
- `function each` を含むファイルは Create タブの Expression にも表示されます。
- `// make` を持たず `function draw`・`function setup`・`createCanvas` を含む p5.js スケッチは、ファイル名を使って自動的にレシピ化されます。

### p5.js スケッチ

```js
function setup() { createCanvas(400, 400); }
function draw() {
  background(20);
  circle(200 + 100 * sin(frameCount / 30), 200, 60);
}
```

- ブラウザなしで p5.js 1.11.13 をそのまま 60 fps で逐次実行します。
- 2D 描画はコンポジションに合わせた画像レイヤーになり、`WEBGL` の `box`・`sphere`・`plane`・`ellipsoid`・`cylinder`・`cone`・`torus` は 3D 立体のコピーになります。
- 各描画行ごとに強度スライダー（例：`circle 3`）が自動生成されます。
- `loadImage` はスケッチと同名の隣接フォルダ（`Fire.js` なら `Fire/`）からファイル名のみで読み込みます。
- `p5.sound` は `engine/third_party/js/p5/addons/p5.sound.min.js`（リポジトリ非同梱）を配置すると動作し、下位レイヤーの動画・音声を Chrome 互換の `p5.FFT` / `p5.Amplitude` 値で解析します。クリック開始型スケッチには自動で 1 回クリックを送信し、書き出し時はスケッチ側のオシレーター音はミュートされます。

### イージングプリセット：`ease/`（`.way`）

1 行目に名前、2 行目以降に数式を記述します：

```
// Snappy: 初速が速く、後半をなめらかに着地させる
a + (b - a) * bezier(u, .2, 0, 0, 1)
```

変数：`a`（始点値）、`b`（終点値）、`u`（進行度 `0..1`）、`p1`〜`p4`（数値引数）。`u = 0` で `a`、`u = 1` で `b` になる式にしてください。`bezier(u, x1, y1, x2, y2)` と `way('名前', u)` が利用できます。

### その他の形式

- **After Effects エクスプレッション（`expressions/`）：** 式のみを書いた `.js`。`index`・`textIndex` は 1 始まり。値は AE 準拠（左上原点ピクセル・Y 下向き、時計回り度数、スケール／不透明度はパーセント）。`effect("ラベル")("Slider")`、裸の `position`・`rotation`・`scale`・`opacity`・`transform`、`valueAtTime(t)`、`loopOut()` / `loopIn()`（`cycle` / `pingpong` / `offset` / `continue`）、`thisComp.layer("名前")`（`transform` / `sampleImage` / `fromWorld`）に対応。`index`・`textIndex`・`textTotal` を参照する式はコピー／文字単位、それ以外はレイヤー全体に作用します。
- **3D 立体（`solids/`）：** `export function solid(k)` で three.js の `BufferGeometry` を返します（`k` にはパラメータと `k.w`・`k.h` が入ります。例：`solids/Box.js`）。
- **WGSL フラグメントエフェクト（`effects/*.wgsl`）：** ヘッダでパラメータを宣言し、`fn fs_main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f` で色を返します。入力は `texture_2d<f32>`、パラメータは単一の `var<uniform>` 構造体。構造体に `time`・`frame`・`aspect`・`resolution`・`width`・`height` があると自動供給されます（例：`effects/glitch/rgbshift.wgsl`）。
- **ISF シェーダー（`effects/*.fs`）：** Vidvox ISF 形式をそのまま配置できます。
- **WGSL コンピュート頂点変形（`@compute` を持つ `effects/*.wgsl`）：** 同じレイヤーの `solids/` メッシュ頂点を毎フレーム変形します（平面レイヤーは自動的に `solids/Plane.js` に載ります）。グループ 0 のバインディング：`0` `f32` uniform 構造体（先頭 `time`、以降 `--track@` 宣言順）、`2` 元頂点（`array<f32>`, xyz）、`4` UV（uv）、`6` 出力頂点、`8` 元法線（xyz）、`10` 出力法線（0 の点は元法線を維持）、`12` 元接線（xyzw）。使用するバインディングのみ宣言可能。エントリポイントは `@compute @workgroup_size(64)`、`global_invocation_id.x` が頂点番号（例：`effects/geometry/tg_simple_points.wgsl`）。

## ヘッダディレクティブ

1 行目は `// 名前: 説明` と書きます（最初の `:` の前が表示名になります。ヘッダ無し、`.fs`、裸の p5.js スケッチはファイル名を使用）。

パラメータは 1 行につき 1 つ `// --<種別>@<変数名>:<ラベル>,...` と書きます（コードからは `k.<変数名>` で参照、`@` と `:` は必須）：

| ディレクティブ | 意味 |
|---|---|
| `// --track@名前:ラベル,最小,最大,初期値,刻み` | 数値スライダー（刻みは省略可） |
| `// --check@名前:ラベル,初期値` | チェックボックス（`0` または `1`） |
| `// --select@名前:ラベル,選択肢1,選択肢2,...` | ドロップダウン（先頭が初期値、`k.名前` は選択文字列） |
| `// --picture@名前:ラベル` | 他レイヤーの画像入力（エフェクト専用） |
| `// --sound@名前:ラベル,fft,512` | 音声レイヤー選択（`k.名前` がレイヤー ID、未選択は `0`。ISF では `fft` / `wave` 音声入力を設定） |
| `// --group:グループ名` … `// --group` | 折り畳み可能なパラメータグループ |
| `// --macro@名前:ラベル,初期値 -> 対象 最小 最大, ...` | 単一の `0..1` スライダーで複数パラメータを連動制御 |
| `// --label:カテゴリ` | 棚のカテゴリ名（`create/` ではパックの区切り） |
| `// --about:説明` | Effects タブに表示する説明文 |
| `// --tag:タグ1 タグ2` | 検索タグを追加（例：`#basic`）。ファイルから自動抽出されるタグに結合されます |

先頭の `const knobs = { distance: 2, ... }`（leva 記法）も読み込みに対応しています。

## ホットリロード

フォルダへ保存すると再起動なしで即座に一覧へ現れます。適用中のファイルを上書き保存すると、プレビューにもリアルタイム反映されます。

- `effects/`・`ae_plugins/`・`aviutl_scripts/`：**Effects** タブに表示。
- `create/`：**Create** タブの Recipes に表示。
- `expressions/`・`relations/`：**Create** タブの Expression に表示（リレーションはグループや複数選択レイヤーを連動させ、単一レイヤーではコピーや文字に作用します）。

## フォルダ一覧

| フォルダ | 表示先 | 対象ファイル | 表示名 |
|---|---|---|---|
| `effects/` | Effects タブ | `.fs`（ISF）・`.wgsl`・`.js`（three.js）・`.mjs`・`.json`（Filament 設定） | 1 行目の `// 名前:` またはファイル名（`.fs` は常にファイル名） |
| `ae_plugins/` | Effects タブ（サブフォルダがパックになる） | `.plugin`（macOS）・`.aex`（Windows）※ユーザー配置／シンボリックリンク専用 | ファイル名 stem（`_` を空白化） |
| `aviutl_scripts/` | Effects タブ（パッケージがパックになる） | AviUtl2 パッケージ（`.anm2`・`.obj2`・`@` ファイル） | スクリプト名と `--label:`。パック名はフォルダ名の `__` 以降 |
| `create/` | Create タブ（Recipes。`function each` 付きは Expression にも表示） | `.js` | 1 行目の `// 名前:`（ヘッダなし p5 スケッチはファイル名） |
| `expressions/` | Create タブ（Expression） | `.js`・`.css` | 1 行目の `// 名前:` |
| `relations/` | Create タブ（Expression） | `.js` | 1 行目の `// 名前:` またはファイル名 |
| `looks/` | Effects / Looks タブ | `.motolii` ＋ `.png` サムネイル | ファイル名そのまま |
| `solids/` | レイヤーが参照する 3D ジオメトリ | `.js`（`export function solid`） | 1 行目の `// 名前:` |
| `ease/` | Ease 棚 | `.way` | 1 行目の `// 名前:` またはファイル名 |
| `workspaces/` | トップバーの Code ワークスペース | `code.layout` | `Code`（`Standard` は `app/lib/workspace/workspace_panes.dart` に定義） |
| `skins/` | `View › Skin` メニュー | フォルダ（`theme.xml`・画像・フォント。詳細は [`skins/README.ja.md`](skins/README.ja.md)） | フォルダ名 |
| `extensions/` | 補助スクリプト（棚には非表示） | `hydra/get.sh` | — |

旧フォルダ名（`recipes/`・`animators/`・`ways/`）に置かれたファイルも後方互換のため引き続き読み込まれます。

## サブフォルダ構成

`effects/` と `create/` は再帰的に読み込まれます。サブフォルダ名は管理用で UI には表示されず、プロジェクトはファイル名で参照を解決するため、サブフォルダ間でファイルを移動しても既存プロジェクトは壊れません。

`effects/` のサブフォルダは [After Effects の Effects & Presets カテゴリ](https://helpx.adobe.com/after-effects/desktop/apply-effects-and-animation-presets/effects-and-animation-presets/effect-list.html)に準拠しています：

| サブフォルダ | AE カテゴリ | 用途 |
|---|---|---|
| `blur/` | Blur & Sharpen | ぼかし・シャープ |
| `color/` | Color Correction | 色調・明るさ補正 |
| `distort/` | Distort | 歪み・ワープ |
| `generate/` | Generate | 波形・模様・図形などの生成 |
| `stylize/` | Stylize | ハーフトーン・グロー・輪郭・ルック |
| `transition/` | Transition | トランジション |
| `key/` | Keying & Matte | キーイング・マット |
| `utility/` | Utility | アルファ操作・カラーバー・タイムコード等の補助 |
| `move/` | *(該当なし)* | 時間による移動・揺れ・繰り返し（AE では式で扱う領域） |
| `geometry/` | *(該当なし)* | 形状・3D 変形・反転（ISF の `Geometry Adjustment`） |
| `glitch/` | *(該当なし)* | データモッシュ・VHS・RGB ずれ（ISF の `Glitch`） |
| `sources/` | *(メタデータ)* | パック別ライセンス・変換スクリプト・サンプル画像・AviUtl 対応表（257 本のヘッダが参照するため改名不可） |

`create/` のサブフォルダ：

| サブフォルダ | 用途 |
|---|---|
| `shapes/` | 単一シェイプ（AbsentMotion シェイプ） |
| `cavalry/` | 点配置スクリプト（Cavalry Distribution） |
| `repeats/` | Repeater / Duplicator 系プリセット |
| `over_footage/` | 映像オーバーレイ（トラッキング枠・フラッシュ・ポスター） |

## ほぼ空に見えるフォルダについて

- `extensions/hydra/` は `get.sh` のみを配置しています。Hydra（`hydra-synth`）は AGPL-3.0 のためリポジトリや配布物に含めず、`get.sh` でユーザーフォルダの `extensions/hydra/` へ取得して読み込みます。
- `ease/` はサンプル 1 件（`snappy.way`）のみ同梱しています。自作プリセットはユーザーフォルダの `ease/` に追加してください。

## 命名規約

プロジェクトファイルはエフェクトやレシピをファイル名で解決するため、**一度公開したファイル名は改名しないでください**（表示名がヘッダから取得されるファイルも含みます）。

- `// 名前:` ヘッダを持つファイル（`effects/` の `.js`/`.wgsl`、`create/`、`expressions/`、`relations/`、`solids/`、`ease/`）：元の出所のファイル名を維持します（`solids/` はスネークケース、`create/shapes/am_*` は AbsentMotion 由来）。
- ファイル名がそのまま表示名になるファイル（`looks/`、`effects/*.fs`、ヘッダなしの p5.js スケッチや `relations/`）：空白と大文字を含めて読みやすく命名します。
- `aviutl_scripts/`：AviUtl2 カタログの `<作者>__<パッケージ>/` 形式とし、中身は配布形式のまま `LICENSE` と `SOURCE.txt` を添えます。
- 共有ヘルパー部品（例：`face_uv.js`）は `shelves/` ではなく `engine/community/` 側に配置します（`shelves/` にはユーザーに 1 項目として見えるアセットのみ置きます）。

## `shelves/` 外のデータ

- フォールバックフォント（Noto Sans JP）、フォントプレビュー文（`gflanguages`）、日英検索辞書（日本語 WordNet）は `engine/third_party/` にライセンス付きで配置しています。ユーザーフォルダの `fonts/`・`words/` に置いたファイルが追加読み込みされます。
- 各フォルダの読み込み実装箇所は [`docs/ARCHITECTURE.md#where-the-shelves-are-read`](../docs/ARCHITECTURE.md#where-the-shelves-are-read) を参照してください。
- アセット生成スクリプト（`effects/sources/`・`create/shapes/absent_shapes.sh`）は手動実行用で、ビルドからは呼ばれません。
