# スキンの作り方

[English](README.md)

**スキン**は Motolii の見た目（配色・フォント・角丸・余白・SVG アイコン・コントロール枠）だけを着せ替えるテーマフォルダです。エンジン側のプロジェクトデータや描画結果には影響しません。

作成したスキンフォルダは以下の `skins/` ディレクトリに配置します：
- **macOS:** `~/Library/Application Support/Motolii/skins/`
- **Windows:** `%APPDATA%\Motolii\skins\`
- **変更する場合:** `$MOTOLII_OWN/skins/`（旧配置先 `~/.motolii/skins/` も後方互換で読み込みます）

同梱スキンと同名のフォルダを置いた場合は、ユーザー側のスキンが優先されます。

## 同梱サンプル

このディレクトリ内のサンプルは **View › Skin** からそのまま選択できます：

| スキン名 | デザインの方向性 |
|---|---|
| `labs` | 白地＋黒文字・丸ピル・淡いアイコン。グレースケール全段と SVG アイコンを差し替えたフルカスタム例 |
| `lighttable` | ライトテーブル上のフィルム風。乳白色の背景・黒いバー・オレンジのアクセント |
| `paper` | 3 色と角丸 0 だけの最小構成サンプル |
| `poster` | スイス・グラフィックデザイン風。フラットな原色アクセントと太字グロテスク体 |
| `sheet` | 紙面と罫線のミニマルな構成。アクティブ状態のみ赤で強調 |
| `streets` | 高コントラストな黒背景・グリーンアクセント・角張りスタイル。Render ボタンとカードに専用 SVG 枠（`parts/frame.*.svg`）を使用 |

## フォルダ構成

```text
<ユーザーフォルダ>/skins/my_skin/
  theme.xml      # 色・寸法・フォント定義（これだけでスキンとして機能）
  parts/*.svg    # カスタム SVG アイコン／フレーム（任意）
  *.otf / *.ttf  # 同梱フォントファイル（任意）
  preview.png    # プレビュー用スクリーンショット（任意）
```

## 1. 最小構成のスキン

3 色指定するだけでアプリ全体の配色が変わります。背景・カード・罫線・補助テキストなどのグレースケール段階は `Background` と `Foreground` から自動補間され、明るい `Background` を指定すれば自動的にライトテーマになります。

```xml
<Motolii>
  <Theme>
    <Background Value="#f1ead9"/>
    <Foreground Value="#2b2118"/>
    <ChosenDefault Value="#e0452b"/>
    <Corner Value="0"/>
    <FontSans Value="Georgia"/>
  </Theme>
</Motolii>
```

この最小例が [paper/theme.xml](./paper/theme.xml) です。グレーの各段階やアイコンまで細かく作り込む例は [labs/theme.xml](./labs/theme.xml) を参照してください。

## 2. 適用とライブ編集

- **適用：** ユーザーフォルダの `skins/` にフォルダを置き、メニューの **View › Skin** から選択します（**Show Skins Folder** でフォルダを開き、**Default** で標準テーマに戻せます）。
- **ライブリロード：** 適用中の `theme.xml` を保存すると、アプリを再起動せず即座に反映されます。
- 未指定のキーにはデフォルト値が適用されます。全キーの一覧は [ROLES.md](ROLES.md) を参照してください。

## 3. 配色の指定

色は `#rrggbb` または透明度付き `#rrggbbaa` で記述します（全ロール名は [ROLES.md](ROLES.md) 参照）。

- **`Background` / `Foreground`：** パネルの背景色と基本文字色。中間グレー階調はこの 2 色から自動生成されます。
- **`Grey00`〜`Grey100`：** グレー階調を個別に上書きしたい場合に指定します（例：[labs/theme.xml](./labs/theme.xml)）。
- **`ChosenDefault` / `ControlOnForeground`：** 選択状態・アクティブ操作・Render ボタンなどのアクセントカラーと、その上に載る文字／アイコン色。
- **`Clip1`〜`Clip7`・`Keyframe`：** レイヤー種別ごとのカラー（1: シェイプ、2: テキスト、3: 画像・動画、4: カメラ、5: グループ、6: パーティクル、7: 音声）とキーフレーム色。
- **`Tone…`：** Inspector カードのカテゴリ別アクセントカラー。

## 4. 寸法・スケール

数値はすべて標準サイズ（`1.0`）に対する倍率です：

| キー | 対象 | 有効範囲 | 例 |
|---|---|---|---|
| `Corner` | 角丸の半径倍率 | `0`〜`10` | `0`（直角）、`3.5`（ピル型） |
| `Spacing` | 余白・間隔 | `0`〜`2` | `1.25`（ゆったり） |
| `Size` | コントロール全体のサイズ（行・バー・カード・アイコン） | `0.85`〜`1.5` | `1.15` |
| `TextScale` | テキストサイズ | `0.85`〜`1.3` | `1.08` |

範囲外の値は安全な上下限にクランプされ、不正な文字列・読めない色・存在しないフォント指定でもアプリはクラッシュせずデフォルト値にフォールバックします。

## 5. フォント

```xml
<FontSans Value="Avenir Next"/>
<FontMono Value="JetBrains Mono"/>
```

OS にインストール済みのフォントはファミリー名だけで指定できます。スキン専用のフォントファイルを同梱する場合は、スキンフォルダに `.ttf` / `.otf` を置いて `*File` を併記します：

```xml
<FontSans Value="Inter"/>
<FontSansFile Value="Inter.ttf"/>
```

## 6. カスタム SVG アイコン・フレーム

```xml
<Parts Value="parts"/>
```

指定したフォルダ内の `<アイコン名>.svg` が標準アイコンの代わりに描画されます（全アイコン ID は [PARTS.md](PARTS.md) 参照。例：`tp.play.svg`、`glyph.select.svg`）。

- `viewBox="0 0 24 24"` で作成してください。
- アイコン色はアプリ側で動的に着色されるため、SVG 内の塗り色は任意です。
- 未定義のアイコンは標準アイコンが使われるため、1 つだけ差し替えることも可能です。
- 配布しやすいよう、`theme.xml` からの相対パス指定を推奨します。

### 9 スライス・コントロールフレーム

`parts/frame.render.svg`（Render ボタン）や `parts/frame.card.svg`（Inspector カード）を置くと、四隅を維持したまま辺を伸縮する 9 スライス描画でコントロールの枠形状を差し替えられます（SVG の色をそのまま保持）。仕様は [PARTS.md](PARTS.md) を参照してください。

## 7. カスタム Forms（ヘッドレス UI・Dart）

XML・SVG だけでは変えられないコントロール構造（ボタン形状・トグル・カード構成）は、[naked_ui](https://pub.dev/packages/naked_ui) ベースのヘッドレス UI 層（`Forms`）で差し替えられます：

- **アプリ側が渡すデータとコールバック：** `lib/widgets/forms/forms.dart` の `ActionSpec`・`ChoiceSpec`・`SwitchSpec`・`CardSpec`
- **`naked_ui` が担う挙動：** 押下・ホバー・フォーカス・選択・アクセシビリティ
- **`Forms` サブクラスが担う描画：** ウィジェット構成の構築のみ（例：`lib/widgets/forms/poster_forms.dart`）

必須メソッドは `action`（Render ボタン）・`onOff`（トグル）・`card`（Inspector カード）の 3 つです。その他の部品（`segment`・`flag`・`chips`・`track`・`number` 等）は省略可能で、未実装時は標準 UI が使われます。`lib/widgets/forms/forms.dart` に登録し、`theme.xml` に `<Forms Value="<名前>"/>` を書くと適用されます（※カスタム `Forms` はアプリ本体へのコンパイルが必要なため、フォルダ配置のみで配布できるのは XML / SVG / フォントまでです）。

## 8. 対象外と現在の制限

- **スキンの対象外：** Stage プレビュー領域の描画内容、ドックのパネル配置、アプリ全体のズーム倍率（`~/.motolii/window.xml`）、編集動作。
- **テキストのはみ出し防止：** ラベルは `…` で省略せず自動で縮小・折り返し（最大 2 行）します。`TextScale` を大きくする場合は `Size` も同程度に上げると見やすく収まります。
- **アプリ内スキンエディタは未実装：** 現時点では `theme.xml` を直接編集します。

## 9. 配布と AI エージェント向けプロンプト例

スキンを配布するにはフォルダをそのまま zip 化してください。受け取った側は自分の `skins/` に展開して **View › Skin** から選ぶだけで適用できます。

AI コーディングエージェントにスキン作成を依頼する際のプロンプト例：

> `shelves/skins/README.md` と `shelves/skins/ROLES.md` を読んで、`~/Library/Application Support/Motolii/skins/<名前>/theme.xml` に「（希望する雰囲気）」のスキンを作成してください。`app/tool/live.sh` で画面を確認しながら、視認性やアクセントのコントラストに問題がなくなるまで調整してください。
