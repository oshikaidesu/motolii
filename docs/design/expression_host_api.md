# Expression Host API

Motolii のエクスプレッションは、**短く形が揃った JS ホスト API** と **After Effects 式のコピペそのまま** の 2 通りの書き方でプロジェクト全体へアクセスできる。

- 型定義（形の正本）: [motolii_host.d.ts](../../engine/community/script_runner/motolii_host.d.ts)
- JS ホスト実装: [host_prelude.js](../../engine/community/script_runner/host_prelude.js)
- AE 式ランタイム: [lottie_shim.js](../../engine/community/after_effects/lottie_shim.js)
- プロジェクト接続: [script_reads.cpp](../../engine/document/scripts/script_reads.cpp)

---

## 1. Motolii JS API（推奨）

`each(i, n, t, k)` の中で `layer()`・`stage`・`audio`・`midi` をそのまま使える。時刻を省略すると自動で現在のプロジェクト時刻が使われ、時間ずらしは `.at(t)` でチェーンできる。

```js
// 別レイヤーの 0.1 秒前を追従 + スケール・エフェクト値・ビート・音声に連動
function each(i, n, t, k) {
  const lead = layer("Leader").at(stage.time - 0.1);
  const pulse = Math.sin(stage.beat * Math.PI * 2) * 0.05;
  const glow = layer("Photo").fx("Bright", "bright");
  return {
    x: lead.x,
    y: lead.y + pulse,
    size: 1 + audio.bass * 0.3 + glow * 0.2,
  };
}
```

```js
// 自分自身・親子・バウンディング・テキスト・カメラ・MIDI
function each(i, n, t, k) {
  const me = layer();                         // 引数省略 = 自分のレイヤー
  const w = me.bounds ? me.bounds.width : 0;  // コンポピクセル幅
  const chars = layer("Title").text.length;
  const cam = stage.camera();                 // { eye, look, up, fov, distance, id }
  const note = midi("Lead");                  // { vel, pitch, gate, bpm }
  return { x: (i - chars / 2) * 0.1, size: 1 + note.vel * 0.5 };
}
```

### 主なオブジェクトの形（抜粋・詳細は `motolii_host.d.ts`）

- **`layer(ref?, t?)`**: `ref` は省略（自分）、レイヤー名、レイヤー ID、`0`（ステージ）。
  - 空間・変形: `.x`, `.y`, `.z`, `.pos`, `.size`, `.scale`, `.scaleX/Y/Z`, `.anchor`, `.rotate`, `.rotateX/Y`, `.opacity`, `.bounds`
  - 構造・文字列: `.id`, `.exists`, `.name`, `.kind`, `.text`, `.index`, `.parent`, `.children`, `.start`, `.duration`
  - 任意プロパティ・エフェクト・変換: `.at(t)`, `.copy(i)`, `.get(prop, fallback?)`, `.word(prop)`, `.keys(prop)`, `.fx(effect, param, fallback?)`, `.toWorld(p)`, `.fromWorld(p)`, `.sample(p, r?, post?)`
- **`stage`**: `.time`, `.fps`, `.frame`, `.width`, `.height`, `.duration`, `.px`, `.bpm`, `.bpmFrom`, `.beat`, `.layers`, `.self`, `.camera(t?)`, `.toScreen(p, t?)`, `.get(prop)`, `.word(prop)`
- **`audio` / `audio(ref?, t?)`**: 省略時はステージ全体のアクティブ音声を自動ミックス。
  - `.bass`, `.lowMid`, `.highMid`, `.treble`, `.rms`（0..1、AudioLink と同一 4 バンド分割）
  - `.bands(t?)`, `.spectrum(out?, t?)`, `.wave(out?, t?)`, `.at(t)`
- **`midi` / `midi(source?, channel?, t?)`**: `.vel` (0..1), `.pitch` (0..127), `.gate` (0|1), `.bpm`。`source` は省略（自レイヤーの `.mid`）・レイヤー名・ID・ファイルパス。

---

## 2. After Effects 式（コピペそのまま）

生の AE 式（`// --property:position|rotation|scale|opacity` を任意指定）でも `AE.compile(...)` でも、`thisComp`・`thisLayer`・`transform`・`effect`・`text`・`sourceRectAtTime`・`toWorld`/`fromWorld`・`sampleImage`・キーフレームが自動で実プロジェクトに結線される。

```js
// そのまま貼れる AE 式の例
thisComp.layer("Leader").transform.position.valueAtTime(time - 0.1)
```

```js
// --property:rotation
loopOut("pingpong")
```

```js
// 他レイヤーのエフェクト値やテキストを参照
thisComp.layer("Photo").effect("Bright")("bright") * 90
```

- `thisComp.frameDuration`・`timeToFrames`・`framesToTime` は実プロジェクトの `frame_rate`（デフォルト 60）を使用。
- 既存の `AE.comp(spec, [customLayers])` と `ctx.effect` を渡すレシピはそのまま優先される。

---

## 3. 座標系・スレッド・制約

- **座標系**: `layer().x/y/z`・`toWorld`・`stage.camera()` は Motolii のステージ単位（中心原点・Y 上向き）。AE 式内の `position`・`sourceRectAtTime()`・`layer().bounds`・`stage.toScreen()` はコンポピクセル（左上原点・Y 下向き）。`fromWorld` / `toWorld` は画像・動画ではソースピクセル、シェイプ・テキストではコンポピクセルを基準に互いに逆変換になる。
- **再帰とスレッド安全**: `layerValue` 系の相互参照は深さ 4 で打ち切る。ホスト API や AE 式を参照するスクリプトは `Script` 側で自動的にドキュメント所有スレッド上での実行に固定される（`project_reads_give` の `asks` 判定）。
- **低レベル互換関数**: `layerValue` / `layerKeys` / `layerNamed` / `getByteFrequencyData` 等は内部プリミティブおよび既存スクリプト互換として維持される。新規スクリプトでは上の `layer()`・`stage`・`audio`・`midi` または AE 式を使う。
- **既知の範囲外**:
  - `sampleImage` は画像/動画のソースピクセルを CPU で読むため、`postEffect = true`（GPU エフェクト適用後の読み戻し）は未対応。
  - `each()` が書き戻せる対象は `ScriptCopy` の 17 項目（位置・サイズ・スケール・回転・色・不透明度・剛体物理パラメータ）に限られる。
