# エフェクト実行パイプライン設計 — 共有 GPU ノード・自動融合・タイト領域・AudioLink バス

> 原則：棚のシェーダー（WGSL / ISF / TSL）は元のコードのまま動かし、表現の自由やはみ出しを一切握りつぶさず、エンジン側の実行基盤だけで多段エフェクトを 60fps 圏内へ押し込む。

シェーダー作者向けのヘッダディレクティブ一覧は [shelves/README.ja.md](../../shelves/README.ja.md) を参照。

---

## 確定アーキテクチャ（実装済み）

### 1. Stage 横断の GPU ノード共通化（`StageFxCache`）
- **シェーダー共有（`compiled`）**：複数レイヤーや同一エフェクトの重ね掛けで、`Program`・`DescriptorSetLayout`・`BufferObject` をエフェクトファイルごとに 1 つだけコンパイル・共有する。同一フレーム内の複数描画は共有 `BufferObject` 上の単調スロット割当（`slotFrame` / `nextSlot`）でユニフォームを分離する。レイヤーごとのコピーシェーダーも `s.place_copy` の 1 本に統一。
- **一時テクスチャ・RenderTarget プール**：
  - 全レイヤーの `DEPTH24`（`screen_pool_depth`）、エフェクト連鎖用のピンポン `scratch`（`PooledLayerSlot`）、非永続 ISF 中間ターゲット（`PooledTarget`、RGBA8 / RGBA16F）を Stage 共通プールから都度借りて即返却する。
  - **制約（罠）**：`st.shot`（`Renderer::render(v)` の出力先）は Filament のフレームグラフ追跡と競合するため、同一フレーム内で別レイヤーと共有してはならない。各レイヤーは `st.shot` と最終出力 `st.between[0]` のみを所有し、`DEPTH24`・`scratch`・非永続 ISF ターゲットを共有する。
  - プールは貸出中の生ポインタ安定性のため `std::deque` で保持し、一定フレーム未使用の古いサイズを自動回収する。
- **最終 ISF コピーパス省略（`directFinal`）**：最終パスが非永続かつ出力と同サイズのターゲットへ向く ISF は、直接出力先 `to` へ描画して全画面コピー 1 パスを省く。

### 2. 連続ポイントワイズ WGSL の自動 1 パス融合
- 1 ピクセル入力・1 ピクセル出力（非ループ・単一テクスチャ・単一サンプリング）の WGSL を静的解析（`screen_analyze_pointwise`）で自動検出し、隣接するノード列を **1 本の WGSL シェーダー（`StageFxCache::fused`）** に自動結合する。
- **対応形式**：SkSL 変換済み WGSL だけでなく、`screen_framed` を通る通常のユーザー作 WGSL・TSL 生成 WGSL（`frame_sample` / `frame_level`＋任意の `@location(0)` UV 名）も自動的に対象になる。
- **色空間変換の畳み込み**：先頭ステップが融合対象なら `linear → sRGB` を、末尾ステップが融合対象なら `sRGB → linear` を同一シェーダー内へ畳み込み、VRAM 往復を消す。
- 融合シェーダーが Dawn に拒否された場合は、個別パス実行へ安全にフォールバックする。

### 3. パラメータ一括評価と 2 重評価の排除
- コンパイル時にユニフォームメンバを `FieldKind` へ事前分類し、ドキュメント参照キー（`js_<stem>_<param>`＋インスタンス ID）も 1 回だけ事前計算して毎フレームのパス解析・文字列生成を排除する。
- `s.aim` 内の単一 `d.lock` 下でレイヤーの全エフェクトパラメータを一括取得し（`Field::paramVal`）、描画フェーズ（多パス ISF の全パス含む）はロックなしで参照する。
- 静止キャッシュ判定で詰めた `paramBuf` は破壊せずハッシュ化し、キャッシュミス時はそのまま `screen_draw_fused` / `screen_parameters` へ流用する。

### 4. 実滲み半径ベースのタイト領域化・カリング・ゼロ強度バイパス
- **はみ出しを切らない原則との両立**：各シェーダーを `SpillKind`（`Zero` / `FixedPx` / `ParamPx` / `Unbounded`）へ分類する。
  - **自動解析**：透明領域（`alpha == 0`）を保持するフィルタ、および WGSL 上で滲み半径が厳密に上界されるブラー・グローを自動検出する。未知のシェーダーや `--spill` / `--alpha` / ジェネレータは安全側（`Unbounded`＝従来の全画面 `doc_fx_sides`）に倒す。
  - **作者ディレクティブ**：WGSL の `// --pad:...` / `// --bypass:<param>`（ISF JSON は `"PAD"` / `"BYPASS"`）により、カスタムシェーダーも 1 行でタイト領域化とゼロ強度バイパスに参加できる。
- **64px 量子化と `frameRect` 不変性**：有界スタックの余白は 64px 刻みで量子化し、ブラー半径アニメーションやレイヤー移動中のテクスチャ再確保を防ぐ。ISF（`hasFrameRect`）を含むスタックは `room` を既定マージンに保って `RENDERSIZE` を不変に保ちつつ `e.sides` のみ実滲み半径＋画面上限へ絞る。
- **ドメイン・カリング**：マット参照元でないレイヤーが `opacity <= 0` または（有界スタックで）滲み込みの矩形がステージ外なら、シートを非表示にしてオフスクリーン描画・エフェクト全段をスキップする。
- **静止レイヤー出力キャッシュ**：`usesTime` 解析（`time` / `frame` / `clip_time` が本文で実際に読まれるか）と全入力状態ハッシュにより、未変更レイヤーは `st.between[0]` を再利用して 0 パスで返す。

### 5. VRChat AudioLink 互換の Stage 共有音バス（`SharedAudioLink`）
- 従来の `--sound@`（`fft` / `wave`）を Stage 単位キャッシュ（`screen_pool_sound`）で共通化し、複数レイヤーからの重複 FFT・重複 GPU アップロードを排除。
- `// --sound@audioLink:AudioLink,audiolink,128`（ISF は `"TYPE": "audioLink"`）で、Stage 全体で 1 フレーム 1 回だけ更新される共有 `128×8 R16F` テクスチャ（4 バンド時間履歴・FFT・波形・RMS・ビート検出パルス）を供給。音声レイヤー未選択時はステージ全体の音ミックスへ自動接続する。
- `screen_framed` は `@binding(0)` の主入力テクスチャのみを `frameRect` 変換するため、AudioLink や LUT 等の補助テクスチャは `[0, 1]` UV のまま自然に読める。

### 6. フラット 2D 単体レイヤーの `renderLayer` バイパス
- **対象条件**（`moment_fx.cpp` で安全判定）：単一コピー（`doc_members == 1`）かつ正対配置（`e.world == true`）のフラット 2D `Canvas2D` レイヤーで、3D 厚み・ライト・wear マテリアル・三角形カット（`cut`）・別シート輪郭（`edgeLook`）・文字分割・エミッシブ・シザー・グループマスク親・斜行（skew）のいずれも無い場合（Live2D / PSD パーツ立ち絵・PNG / SVG / テキスト等の大半が該当）。
- **仕組み**：Filament の 3D `Renderer::render(v)` と per-layer `st.shot` テクスチャ確保を丸ごと省略し、ThorVG のストレート sRGB `Canvas2D::texture` を正規化矩形 `flatRect`（`flatWash` 対応）から WGSL 側へ直接読み込む。
  - 先頭が融合可能ポイントワイズ列なら `screen_draw_fused`（`foldFlat`）へ直接畳み込み、**`Renderer::render(v)` も `linear → sRGB` も `scratch` も無しで 1 パス完結**。
  - 先頭が非ポイントワイズ（ブラー等）なら Stage 共有の `screen_blit_flat` で sRGB へ 1 パス展開し、`toSrgb` を省く。
  - 全ステップが `--bypass` でスキップされた場合は `screen_blit_flat(..., toLinear=true)` で `st.between[0]` へ直接書き出す。
  - 8bit リニア中間テクスチャ（`st.shot`）を経由しないため、暗部アンチエイリアス縁の量子化劣化も消える。

### 7. `engine/gpu/screen_interop.cpp` の DescriptorSet キャッシュと動的オフセット
- ユニフォームバッファのバインディングに `DescriptorFlags::DYNAMIC_OFFSET` を付与し、描画時に `DescriptorSetOffsetArray({pass * parameterStride})` で動的オフセットを渡すことで、**同一テクスチャ・サンプラ・バッファの組に対する `DescriptorSet`（`WGPUBindGroup`）を全パス・全フレームで再利用**する。
- **4bit ハンドル世代衝突への安全対策**：テクスチャ破棄箇所（プール回収・リサイズ・レイヤー／キャッシュ破棄）で `interop::invalidate_textures` がグローバル世代（`gTextureGen`）を単調増加させ、キャッシュキーにも `Texture*`・`HwTexture` ID・寸法・バッファ ID を含めることで、再利用ハンドルによる誤参照を構造的に防ぐ。
- **ストールとヒープ確保の排除**：定常フレームでは `DescriptorSet` 破棄が 0 回になるため、従来の 1024 描画ごとの `engine->flushAndWait()` パイプライン停止が発生しなくなる。さらに `interop::parameters` の毎パス `calloc`/`free` を `std::shared_ptr<ParamPool>` のフリーリストへ置き換え、`Screen` 破棄後のドライバスレッド遅延コールバックでも安全に再利用する。

---

## 実装マップ

| 領域 | 主なファイル | 役割 |
|---|---|---|
| GPU インターオプ | `engine/gpu/screen_interop.h` / `.cpp` | `DYNAMIC_OFFSET`・`DescriptorSet` キャッシュ・`ParamPool`・`invalidate_textures` |
| GPU 共有キャッシュ・プール・音バス | `engine/stage/effects/screen_pool.h` / `.cpp` | `StageFxCache`・共有シェーダー・`screen_blit_flat`・テクスチャプール・共有 AudioLink |
| WGSL 解析・自動融合 | `engine/stage/effects/screen_fuse.cpp` | ポイントワイズ検出・1 パス融合（`foldFlat` 対応）・`usesTime`・`SpillKind`・`--pad`/`--bypass` |
| 読み込み・ISF 変換 | `engine/stage/effects/screen_read.cpp`, `engine/community/isf/isf_translate.cpp` | ディレクティブ解釈・`FieldKind` 事前解決・`screen_framed` 主入力限定化 |
| 実行・カリング・一括評価 | `engine/stage/layer_effects/layer_fx.cpp`, `engine/document/evaluate/moment_fx.cpp` | フラット 2D バイパス判定・遅延 `st.shot`・融合実行プラン・ゼロ強度バイパス・静止キャッシュ・ドメインカリング |
| タイト領域配置 | `engine/stage/layer_effects/layer_fx_place.cpp` | `boundPadPx` に基づく `room` / `e.sides` / `ortho` 計算 |
| モダン棚シェーダー | `shelves/effects/blur/Dual Kawase Blur.fs`, `Physical Bloom.fs`, `shelves/effects/stylize/AudioLink Pulse.wgsl` | SIGGRAPH 2015 Kawase・SIGGRAPH 2014 Jimenez Bloom・AudioLink 実装例 |
| 単体テスト | `engine/stage/effects/screen_fuse_test.cpp` | 解析・分類・ディレクティブ・ユーザー WGSL 自動融合の検証 |
