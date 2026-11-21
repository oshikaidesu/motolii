# After Effects 資産の持ち込みガイド

[English](AFTER_EFFECTS.md)

After Effects で使い慣れたプラグイン・エクスプレッション・Lottie データを、そのまま Motolii のプロジェクトに持ち込むためのガイドです。

---

## 1. ネイティブ After Effects プラグイン（`.plugin` / `.aex`）

Motolii は [aexlo](https://github.com/potistudio/aexlo) を使った隔離ワーカープロセス経由で、サードパーティ製 After Effects プラグインを直接実行できます。エディタ本体とは別プロセスで動くため、プラグインがハング・クラッシュしても Motolii 本体は落ちません。

> **ライセンスについて：** Motolii 本体にはサードパーティ製プラグインのバイナリを一切同梱しません。ご自身で所有・入手したプラグインを、それぞれのライセンスに従って配置してご利用ください。

### 導入手順（再起動不要）

以下のユーザーフォルダ内 `ae_plugins/` にプラグインを配置（またはシンボリックリンク）します。

- **macOS（Apple Silicon）：** `~/Library/Application Support/Motolii/ae_plugins/`（`.plugin` バンドル）
- **Windows（x64・実験的対応）：** `%APPDATA%\Motolii\ae_plugins\`（`.aex` ファイル）
- **任意のフォルダに変更する場合：** 環境変数 `MOTOLII_OWN` で指定したフォルダ配下の `ae_plugins/`

#### おすすめ：既存の AE プラグインフォルダをシンボリックリンクする

プラグイン本体を複製する必要はありません。macOS ならベンダーごとのフォルダをそのままリンクできます：

```bash
mkdir -p "$HOME/Library/Application Support/Motolii/ae_plugins"
ln -s "/Applications/Adobe After Effects 2025/Plug-ins/Plugin Everything" \
      "$HOME/Library/Application Support/Motolii/ae_plugins/Plugin Everything"
```

`ae_plugins/` の下にサブフォルダを作ると、Effects タブの左リストに自動的に**パック（Pack）**としてまとまります。

> ※ Adobe 標準の `Plug-ins/Effects` フォルダ丸ごとのリンクは非推奨です（Adobe 独自の非公開 API に依存する組み込みエフェクトはプローブ時にスキップされます）。サードパーティ製フォルダや個別のプラグインを配置してください。

### Effects タブでの使い方

1. 左ドックの **Effects** タブを開きます。
2. 配置したプラグインは **After Effects** カテゴリおよびサブフォルダ名の **Pack** に表示されます。
3. 自動付与されるタグで素早く絞り込めます：
   - `#ae` — After Effects プラグイン全般
   - `#cpu` / `#gpu` — プラグインが宣言する実行パス
   - `#image` — 他レイヤーをマップ／入力として受け取るプラグイン
4. タイルをダブルクリックするかレイヤー（または Stage）へドラッグすると適用されます。スライダー・チェックボックス・ポップアップ・2D/3D ポイント・カラー・グループ・レイヤー選択などのパラメータは **Inspector** に自動生成されます。

### 動作するプラグインの傾向と現在の制限

| 状態 | 対象となるプラグインの例 |
|---|---|
| **そのまま動きやすい** | 2D スタイライズ・色調補正・グロー・歪み・色収差・アニメ／セル FX・グリッチ・ジェネレーター系（例：Deep Glow 2、Quick Chromatic Aberration 3、Satori BlockSwap、Zink Tools の 2D / Anime FX 系、HaloGlow など） |
| **一部対応** | 他レイヤー参照系（Inspector のレイヤー選択から渡せます）、コンプカメラなしでもフォールバック描画する 3D 系 |
| **現時点では非対応** | Adobe 独自の組み込みエフェクト、未実装の AEGP ホスト API（コンプカメラ参照・テキストドキュメント操作・独自モーダル UI 等）が必須のもの、異 OS バイナリ（macOS 上での `.aex` や Windows 上での `.plugin`） |

### パフォーマンスのコツ

- ネイティブ AE プラグインは隔離ワーカー経由で RGBA8 画像を受け渡すため、軽量なプラグイン（`BlockSwap`・`ZT_ASCIIArt` 等）は 60 fps 余裕で動きますが、重い CPU 処理（ボリューム光や大半径 CPU ブラー等）は AE 本家と同じく 1 フレームあたり数十〜数百 ms かかります。
- 同じレイヤー上に、GPU ネイティブの Motolii シェーダー（同梱の **Halo Glow**・ISF・WGSL など）と AE プラグインを自由な順番で重ね掛けできます。
- よく使う表現を 60 fps・OS 非依存の GPU エフェクトにしたい場合は、**Agent** タブから ACP エージェントに `.wgsl` シェーダー化を依頼することもできます。

### トラブルシューティング

- **macOS で Web から落とした `.plugin` が一覧に出ない：** 未署名のダウンロードファイルに付く macOS の隔離属性（quarantine）が原因です。以下を実行して解除してください：
  ```bash
  xattr -dr com.apple.quarantine "$HOME/Library/Application Support/Motolii/ae_plugins"
  ```
- **特定のプラグインでフリーズする／変化しない：** 1 フレーム 5 秒を超えた場合はワーカーを自動終了し、元画像を安全にパススルーします（エディタ本体は止まりません）。
- **プローブキャッシュをリセットしたい：** メタデータキャッシュは `~/Library/Caches/Motolii/ae_plugins/` に保存されています。このフォルダを削除すると次回再スキャンされます。

---

## 2. After Effects エクスプレッション

lottie-web の `ExpressionManager` を QuickJS-ng のバイトコードとして実行しているため、Web やチュートリアルの式を書き換えずにそのまま動かせます。

- **直接貼り付け：** レイヤーを選択して `⌘V`（例：`wiggle(2, 50)`）、または **Code** タブの **+ New expression** から記述。
- **棚に保存：** 式だけを書いた `.js` を `~/Library/Application Support/Motolii/expressions/` に配置。1 行目に `// --property:position`（または `rotation` / `scale` / `opacity`）で適用先プロパティを指定できます。
- **主な対応機能：** `thisComp`・`thisLayer`・`thisProperty`・`valueAtTime`・`loopOut` / `loopIn`（`cycle` / `pingpong` / `offset` / `continue`）・`wiggle`・`linear`・`ease`・`sampleImage`・`fromWorld`・キーフレーム参照・他レイヤー参照。
- **Code タブ支援：** 入力補完、再生ヘッド位置での評価値プレビュー、エラー行表示、Motolii での対応状況付き AE **Functions** リスト。

---

## 3. Lottie アニメーション（`.json`）

Bodymovin で書き出した `.json` を Stage または Timeline へドラッグ＆ドロップするだけで配置できます。

- **ThorVG** が直接再生し、埋め込みエクスプレッションも **JerryScript** でランタイム評価されます（ベイク不要）。
- キーフレーム・イージング・パス・親子付け・プリコンポジション・タイムリマップ・ループ・マット・ブレンドモード、さらに Motolii 独自の 3D レイヤー＆カメラ拡張に対応しています。

---

## 4. 同梱の GPU ネイティブエフェクトとの併用

Motolii には 1,300 以上のオープンソース GPU エフェクト（ISF・WGSL・AviUtl2・three.js TSL・AbsentMotion）が最初から同梱されており、MIT ライセンスのマルチスケールグロー **Halo Glow**（`shelves/effects/stylize/halo_glow.wgsl`）も GPU ネイティブ版としてそのまま使えます。書き出し時には、使用した同梱エフェクトの作者・ライセンス一覧がクレジットファイルとして自動出力されます。
