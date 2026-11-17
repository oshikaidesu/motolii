# 標準 UI の一部を置き換えたユーザー製パネル（日本語圏）

調べた日: 2026-10-17。BOOTH は商品 JSON（作者・公開日・画像）を直接取得。YMM4 は manjubox のプラグイン一覧と GitHub。

- 対象: ワンクリック実行・ランチャー型は外した。純正の一部（グラフエディタ、レイヤー一覧、エフェクト欄、色、ボーン選択、メニュー）の**代わりの画面**を持つものだけ。
- 「画像」= 商品ページ画像の直リンク（最大2枚）。BOOTH は 1 枚目が宣伝、2 枚目以降が本体という型が多い。目視したものだけ「◎本体」「△バナー内に本体」。残りは未目視。
- 「公開日」= BOOTH の初回公開日（最終更新日は取れない）。GitHub の更新日は API 制限で未取得。♡ = BOOTH のスキ数。
- 「作者の言葉」= 説明文のうち、標準 UI との比較・不満を書いた一文（無い場合は空）。

## グラフエディタ／速度グラフ → 触って曲げるカーブ板

標準グラフエディタの代わりに、小さな正方形のカーブを直接つまむ型（Flow と同型）。AE で6作者、Premiere・Resolve・Blender・YMM4 にも別作者。

| 名前 | ホスト | 作者 | 画像 | 商品 | 公開日 | ♡ | 作者の言葉（説明文より） |
|---|---|---|---|---|---|---|---|
| 【After Effects スクリプト】MultiEase | AE | Nisaiのスクリプト置き場 | △バナー内に本体 [1](https://booth.pximg.net/b570614d-25fb-4aca-b84c-6bce1a2d2f52/i/3924629/5765e904-7757-429f-8926-32cfc823055f_base_resized.jpg) | https://booth.pm/ja/items/3924629 | 2022-07-10 | 1698 |  |
| 【AfterEffectsイージングスクリプト】NGS_EaseCraft | AE | nagisa-12-34 | [1](https://booth.pximg.net/64b27670-5527-4962-b6be-ffe39a4f8ede/i/7726008/fa16bf55-551a-436b-9378-c82584cc55b2_base_resized.jpg) [2](https://booth.pximg.net/64b27670-5527-4962-b6be-ffe39a4f8ede/i/7726008/a79adbef-df14-44ef-a5f4-72e0f511b32e_base_resized.jpg) | https://booth.pm/ja/items/7726008 | 2025-12-04 | 21 |  |
| 【After Effects プラグイン】Z EASEL／イーゼル｜感覚で描く、新しいイージング | AE | Z PLUG-IN STORE | [1](https://booth.pximg.net/6764a08b-4041-4f7e-8ec8-da0ee87f19d9/i/8754712/5b262ba9-3238-43d8-afb8-4ae3e9049bed_base_resized.jpg) [2](https://booth.pximg.net/6764a08b-4041-4f7e-8ec8-da0ee87f19d9/i/8754712/fc09c0dd-c1b2-4428-affe-e1e96afa0d21_base_resized.jpg) | https://booth.pm/ja/items/8754712 | 2026-08-24 | 27 |  |
| HL_Ezing | AE | はるくんのスクリプト屋さん | [1](https://booth.pximg.net/ae82b541-c3cd-4b32-abce-73bbf5780ef5/i/7511897/b459126c-373a-49e5-83df-20850dc2e7ec_base_resized.jpg) [2](https://booth.pximg.net/ae82b541-c3cd-4b32-abce-73bbf5780ef5/i/7511897/31811ed1-f9ca-45e5-8fda-0a0ea3625927_base_resized.jpg) | https://booth.pm/ja/items/7511897 | 2025-10-08 | 177 |  |
| 【After Effects スクリプト】Legato | AE | ROOM404 / XI | [1](https://booth.pximg.net/b3b4b8e6-b100-4c08-a3e9-09598fdb1ace/i/8627108/e2ad5940-5965-4c80-a5ba-c3e7290d8f41_base_resized.jpg) [2](https://booth.pximg.net/b3b4b8e6-b100-4c08-a3e9-09598fdb1ace/i/8627108/999ddbf9-28d8-4972-814e-b77292e7fc4d_base_resized.jpg) | https://booth.pm/ja/items/8627108 | 2026-07-18 | 19 |  |
| 【DaVinci Resolve / Fusionスクリプト】F-Ease Everything | Resolve | ブラマン | [1](https://booth.pximg.net/f427d359-b4cf-4bdc-8e97-e7810c82733e/i/8551038/ef7811c3-782d-4114-a5e2-8505cc4cfbeb_base_resized.jpg) [2](https://booth.pximg.net/f427d359-b4cf-4bdc-8e97-e7810c82733e/i/8551038/4e48b475-af9c-4cb1-8d4c-593524730f1e_base_resized.jpg) | https://booth.pm/ja/items/8551038 | 2026-06-28 | 39 |  |
| 【blender アドオン】Curve Editor_in_blender | Blender | 岡崎有希 | [1](https://booth.pximg.net/78345e80-9d6c-49ba-b86f-aa1aedc53ef5/i/7960811/19f4bd15-cc23-489a-b48a-ab4503e91975_base_resized.jpg) | https://booth.pm/ja/items/7960811 | 2026-02-08 | 87 | |
| [FREE]Easy Easy Ease[Blender] | Blender | Yzmo - 唯繕物置 | [1](https://booth.pximg.net/bd4b15dc-73c5-4ee4-8812-1dc8fa093790/i/6739684/e1882d41-b0ee-4fc0-9222-fdb805873644_base_resized.jpg) [2](https://booth.pximg.net/bd4b15dc-73c5-4ee4-8812-1dc8fa093790/i/6739684/c5bdb8cc-a35c-4282-afbc-64e86d3cfbcd_base_resized.jpg) | https://booth.pm/ja/items/6739684 | 2025-03-27 | 34 |  |
| ElasticBezierEasing | YMM4 | 左コントローラー | [1](https://github.com/user-attachments/assets/fddef2ad-66c0-48b7-9d0b-b0cb2e676edf) | https://github.com/leftcontroller0518/ElasticBezierEasing | 未取得 | - | |
| AiuCurver（ベジェ速度カーブ） | YMM4 | aiubr | 画像未取得 | https://ymm4-info.net/ymme/AiuCurver | 未取得 | - | |

## タイムライン／レイヤー一覧 → 畳める・絞れる一覧

プリコンポーズの代わりに「グループを畳む」一覧、ラベルで絞る一覧、Maya 風グループ。AEGroupPanel と同型。

| 名前 | ホスト | 作者 | 画像 | 商品 | 公開日 | ♡ | 作者の言葉（説明文より） |
|---|---|---|---|---|---|---|---|
| AEGroupPanel — プリコンポ不要のレイヤーグルーピング【After Effects / Mac専用】 | AE | BASH | [1](https://booth.pximg.net/d5f58f83-e0f5-4a04-8e97-b23c50b36083/i/8688577/d4e25adc-9e75-4bb7-9d0a-24efd59dc5d6_base_resized.jpg) [2](https://booth.pximg.net/d5f58f83-e0f5-4a04-8e97-b23c50b36083/i/8688577/bc0b3ce1-3eba-4cef-8d71-718023166efd_base_resized.jpg) | https://booth.pm/ja/items/8688577 | 2026-08-06 | 3 |  |
| Grupico - レイヤーのグループ化 / 整理整頓 | AE | gameanimation | [1](https://booth.pximg.net/db167d1f-4d23-4610-ba76-7360108313f8/i/7013286/fd9aa12c-9f03-4ad8-ae92-ffb7e335a29d_base_resized.jpg) [2](https://booth.pximg.net/db167d1f-4d23-4610-ba76-7360108313f8/i/7013286/2fb3174f-5494-4ee9-ba54-a7be756664d0_base_resized.jpg) | https://booth.pm/ja/items/7013286 | 2025-06-06 | 142 |  |
| AEスクリプト 「Label & Finder Bar」【検索機能つき】 | AE | 映像オタクのプラグイン屋 | [1](https://booth.pximg.net/6de1e5ad-ec72-4ca7-993f-7377159d5d43/i/8384799/2c2212ea-d026-4193-a328-8407e3d45e3a_base_resized.jpg) [2](https://booth.pximg.net/6de1e5ad-ec72-4ca7-993f-7377159d5d43/i/8384799/ed9de25e-d165-433a-9e39-78d6a487be1a_base_resized.jpg) | https://booth.pm/ja/items/8384799 | 2026-05-20 | 2 | 「標準の右クリックからラベル色変えるの、地味に面倒くさい…」 |
| 【After Effects スクリプト】再生ヘッドでレイヤー表示を管理する「Peek-a-boo」 | AE | こえだ | [1](https://booth.pximg.net/93d0be44-23a0-4950-930e-e6a735968aad/i/4139749/6218e728-3ad2-4757-99ab-5684c6c06c41_base_resized.jpg) | https://booth.pm/ja/items/4139749 | 2022-09-03 | 185 |  |
| タイムラインプラグイン | YMM4 | routersys | [1](https://booth.pximg.net/fbb3f708-264f-4f81-a449-cdcda40b4bd3/i/8313596/daed79fb-2f5d-412c-a0a0-ea9779265f88_base_resized.jpg) [2](https://booth.pximg.net/fbb3f708-264f-4f81-a449-cdcda40b4bd3/i/8313596/7d03fafa-c4fd-47e4-b37f-98749814ebc7_base_resized.jpg) | https://booth.pm/ja/items/8313596 | 2026-05-05 | 3 | YMM4 標準の TimelineView をそのままツールパネルに埋め込んで描画するため、異なるレイヤーやトラックを同時に参照しながら編集作業を進めることができます |
| Mayaライクなグループ化をBlenderで再現！『Maya Style Grouping』アドオン | Blender | yuchi shop | [1](https://booth.pximg.net/863e2fdc-4af4-4299-87f5-6844217b79e8/i/8030138/634cc61e-3412-45ff-8c86-9ee1ce5dc5f8_base_resized.jpg) | https://booth.pm/ja/items/8030138 | 2026-02-25 | 5 | Blender標準のコレクション機能とは別に、アウトライナー上での階層整理や、モデリング・リギング時のピボット管理を多用する方に強くおすすめします |
| Blender アウトライナー自動注視アドオン【Auto Focus Outliner】 | Blender | 空篝 | [1](https://booth.pximg.net/e48fde23-8aa5-45d1-a09d-f9bcd8a879f2/i/8151279/9b0e5194-d946-4f35-9938-57b8bee81a5c_base_resized.jpg) | https://booth.pm/ja/items/8151279 | 2026-04-01 | 0 | コレクションが増えてどこに何があるのか見つけるのが面倒だったので作りました |

## エフェクト＆プリセット欄 → 検索窓・プレビュー付きの棚

標準のエフェクト欄（英語名・ツリー）の代わり。日本語名・ローマ字で引ける版が日本独自。プレビュー付き棚は AE・YMM4 で複数。

| 名前 | ホスト | 作者 | 画像 | 商品 | 公開日 | ♡ | 作者の言葉（説明文より） |
|---|---|---|---|---|---|---|---|
| Japanese-effect-search | AE | kinomotokirin | [1](https://booth.pximg.net/99a9072c-752f-46a4-b9a7-1829c8c5ac58/i/7695646/f340c593-3097-4735-ad66-8c46c8cacc91_base_resized.jpg) [2](https://booth.pximg.net/99a9072c-752f-46a4-b9a7-1829c8c5ac58/i/7695646/bc92d6ef-0aa7-4c85-ac8c-d9db4fe15d57_base_resized.jpg) | https://booth.pm/ja/items/7695646 | 2025-11-26 | 54 |  |
| 【After Effects】FX Console - ローマ字対応 | AE | ROTO_Works | [1](https://booth.pximg.net/24c27eb2-29e1-477c-8b34-c80d68fd6d94/i/6176975/7d0b7739-1f7e-42d5-bbda-289385dbb8db_base_resized.jpg) [2](https://booth.pximg.net/24c27eb2-29e1-477c-8b34-c80d68fd6d94/i/6176975/ed53d531-c62e-4523-9bd4-e6772e29a37c_base_resized.jpg) | https://booth.pm/ja/items/6176975 | 2024-10-13 | 21 |  |
| 【After Effects スクリプト】EffectsDrive | AE | Terrible Junk Show | [1](https://booth.pximg.net/1d843c4b-3531-4a46-b486-ca2b639b8d6e/i/2590842/c0689fc4-f603-41d0-8bc8-2316df52e25c_base_resized.jpg) | https://booth.pm/ja/items/2590842 | 2020-12-10 | 38 |  |
| 【After Effects拡張機能】TextMotion Studio ─ プレビュー付きで管理できるテキストアニメー | AE | Sizuk Picture | [1](https://booth.pximg.net/f7156d78-cd5d-4975-9b55-d41f97e71a80/i/8697867/bf3c613d-2535-40a9-a550-7fe7903f5d7d_base_resized.jpg) [2](https://booth.pximg.net/f7156d78-cd5d-4975-9b55-d41f97e71a80/i/8697867/de79ae28-4c67-476f-9701-f7f4120e7e4b_base_resized.jpg) | https://booth.pm/ja/items/8697867 | 2026-08-11 | 260 |  |
| TemplateTube+プラグイン | YMM4 | かへんしき。の作業部屋 | [1](https://booth.pximg.net/60e7da4a-c37f-45bd-a943-c25d21717431/i/8626180/abc59dea-04fd-4206-ab89-33adc2a99878_base_resized.jpg) | https://booth.pm/ja/items/8626180 | 2026-07-18 | 20 | |
| 【無料】YMM4プレビュー付きテキストプリセットプラグイン | YMM4 | あづさまる | [1](https://booth.pximg.net/466f7437-a6d6-452a-826c-9f255e50596f/i/7856108/e881fbc2-7a08-4928-84e2-200d02ed50f7_base_resized.jpg) [2](https://booth.pximg.net/466f7437-a6d6-452a-826c-9f255e50596f/i/7856108/5ea4d9a3-de12-4272-9ba5-340933166520_base_resized.jpg) | https://booth.pm/ja/items/7856108 | 2026-01-11 | 269 |  |
| EffectBrowserToolPlugin | YMM4 | 左コントローラー | [1](https://github.com/user-attachments/assets/cc57b94c-58ba-42d1-a2a6-563a30331070) | https://github.com/leftcontroller0518/EffectBrowserToolPlugin | 未取得 | - | |
| エフェクトカテゴリカスタマイズ | YMM4 | てとら | 画像未取得 | https://github.com/tetra-te/EffectCategoryCustomizer | 未取得 | - | |

## スウォッチ／カラーピッカー → 並んだ色の棚

AE には色棚が無いので、パレットパネルを作る人が非常に多い（AE だけで6作者以上）。標準ピッカーの拡張・別窓スポイトも。

| 名前 | ホスト | 作者 | 画像 | 商品 | 公開日 | ♡ | 作者の言葉（説明文より） |
|---|---|---|---|---|---|---|---|
| カラーパレットスクリプト【Chromix】 | AE | simry | ◎本体 [2](https://booth.pximg.net/51ae51f0-aeb6-460d-a6dc-ccba8053cdb2/i/7431908/f1cb2ef7-5d5d-42a3-b1e1-6866069988cb_base_resized.jpg) | https://booth.pm/ja/items/7431908 | 2025-09-16 | 191 |  |
| 【After Effects スクリプト】ワンクリックで直接カラーを適用&一括修正できるカラーパレット | AE | Guild | ◎本体 [2](https://booth.pximg.net/4d2c0b27-c2c8-4372-bfb5-527bd8122c53/i/6775944/c2cd1241-4f9f-4e2b-80d8-7bd7dab04197_base_resized.jpg) | https://booth.pm/ja/items/6775944 | 2025-04-12 | 154 |  |
| Color Palette - After Effects Script | AE | そよの雑貨展 | [1](https://booth.pximg.net/ca89df0b-f961-4b65-8275-be30227eb2bd/i/4946867/4074729f-6a6d-44ae-8367-339daac73132_base_resized.jpg) | https://booth.pm/ja/items/4946867 | 2023-07-22 | 73 |  |
| Aeスクリプト『SHIG Color Pallet』 | AE | SHIGの素材倉庫 | [1](https://booth.pximg.net/07782ad0-d93a-4da2-af01-30be6694c002/i/8624865/7edf961a-44c9-4680-973a-d9c4400b1083_base_resized.jpg) [2](https://booth.pximg.net/07782ad0-d93a-4da2-af01-30be6694c002/i/8624865/f8cadb9e-0745-4517-8ac6-929109a98329_base_resized.jpg) | https://booth.pm/ja/items/8624865 | 2026-07-17 | 55 |  |
| HL_Colpal｜カラーパレットエクステンション | AE | はるくんのスクリプト屋さん | [1](https://booth.pximg.net/ae82b541-c3cd-4b32-abce-73bbf5780ef5/i/8468704/112248a2-bfae-458f-8977-521a131ce873_base_resized.jpg) [2](https://booth.pximg.net/ae82b541-c3cd-4b32-abce-73bbf5780ef5/i/8468704/bb004964-ceb1-4a31-ae77-a4ad2850a833_base_resized.jpg) | https://booth.pm/ja/items/8468704 | 2026-06-05 | 20 |  |
| Hex Color Palette【Blenderアドオン】【バージョン5.2以上推奨】 | Blender | もーしょん・スペース・スタジオ | [1](https://booth.pximg.net/252aad8e-18e6-4e4e-8ae1-12a0382b419b/i/8897369/ea11e8c5-0b86-4550-8b27-9d5f2b78563b_base_resized.jpg) [2](https://booth.pximg.net/252aad8e-18e6-4e4e-8ae1-12a0382b419b/i/8897369/c9d54ce5-7dd0-4915-854b-746b85d0243c_base_resized.jpg) | https://booth.pm/ja/items/8897369 | 2026-09-25 | 0 |  |
| 【Blender Add-on】Screen Color Picker - 別ウィンドウの色も取得できるスポイト機能 | Blender | Kui Creations | [1](https://booth.pximg.net/eacf7a10-0dc0-45db-a29f-6f7e011cea38/i/8527320/e1d5cb04-23a5-48a2-80a3-3ce496385496_base_resized.jpg) | https://booth.pm/ja/items/8527320 | 2026-06-20 | 7 | 標準のスポイトはBlenderの中の色しか取得できず、別ウィンドウで開いたリファレンス画像などから色を拾うことができませんでした |
| ColorPicker+ | YMM4 | 左コントローラー | [1](https://github.com/user-attachments/assets/2adccda4-f96e-4a6a-baeb-088008ee06d7) | https://github.com/leftcontroller0518/colorpicker_plus | 未取得 | - | |

## ビューポートでのボーン選択 → 体の絵から選ぶ

リグピッカー型。BOOTH では少ない（Bookyakuno の Rigi Picker が古株）。AviUtl の PSDToolKit は「PSD の絵を見ながらパーツを切り替える窓」で同じ発想。

| 名前 | ホスト | 作者 | 画像 | 商品 | 公開日 | ♡ | 作者の言葉（説明文より） |
|---|---|---|---|---|---|---|---|
| 【Rigi Picker】 Rigify や自分のリグのボーン選択を補助するピッカーアドオン【Blenderアドオン】 | Blender | Bookyakuno | [1](https://booth.pximg.net/06c7626c-3b33-4f13-b11b-a3dc8b20e21d/i/2385943/487bb960-dacf-49c8-b7bb-1167f8ef2497_base_resized.jpg) [2](https://booth.pximg.net/06c7626c-3b33-4f13-b11b-a3dc8b20e21d/i/2385943/995f1efc-9357-476f-90e8-57dfc0571e7d_base_resized.jpg) | https://booth.pm/ja/items/2385943 | 2020-09-19 | 101 |  |
| Simple Picker | Blender | 梅見月のお店 | [1](https://booth.pximg.net/ea2b4a7e-8e1d-44eb-b09f-678f1836e2bf/i/8689892/d4cd5345-b75d-4aee-80e1-e88158200635_base_resized.jpg) [2](https://booth.pximg.net/ea2b4a7e-8e1d-44eb-b09f-678f1836e2bf/i/8689892/97383529-f916-45d3-a53d-a89d29aa1128_base_resized.jpg) | https://booth.pm/ja/items/8689892 | 2026-08-07 | 0 |  |
| PSDToolKit（PSD 立ち絵の窓） | AviUtl/AviUtl2 | oov | 画像未取得 | https://github.com/oov/aviutl_psdtoolkit | 未取得 | - | |

## メニュー・タブ・設定画面 → 自分の並びに作り直す

Blender に集中：パイメニュー（既製・自作型）、N パネルのタブ並べ替え、ノード追加メニューの一覧化、ブラシ選び、テーマ編集。

| 名前 | ホスト | 作者 | 画像 | 商品 | 公開日 | ♡ | 作者の言葉（説明文より） |
|---|---|---|---|---|---|---|---|
| 【w_pie】よく使う機能を分類ごとにまとめたパイメニューアドオン【Blenderアドオン】 | Blender | Bookyakuno | [1](https://booth.pximg.net/06c7626c-3b33-4f13-b11b-a3dc8b20e21d/i/6020851/8f235722-8001-490f-b431-cd62f8885134_base_resized.jpg) [2](https://booth.pximg.net/06c7626c-3b33-4f13-b11b-a3dc8b20e21d/i/6020851/5421c1e6-be0a-4a5d-a0dc-c102326a5efa_base_resized.jpg) | https://booth.pm/ja/items/6020851 | 2024-08-18 | 46 |  |
| 【Blender Add-on】Custom Pie Menu - カスタムパイメニュー作成ツール | Blender | Kui Creations | [1](https://booth.pximg.net/eacf7a10-0dc0-45db-a29f-6f7e011cea38/i/8516083/a5382090-1270-4450-9340-9e86e16f582e_base_resized.jpg) [2](https://booth.pximg.net/eacf7a10-0dc0-45db-a29f-6f7e011cea38/i/8516083/aa88463e-66a9-41d5-9fb5-fff8d64e9589_base_resized.jpg) | https://booth.pm/ja/items/8516083 | 2026-06-18 | 7 |  |
| 【Blenderアドオン】PieCreator - 階層型カスタムメニュー作成ツール【無料】 | Blender | hinata-hugu29 | [1](https://booth.pximg.net/05984c74-52bf-47b2-9259-8c5686282822/i/8280707/ec8333e6-ccda-4b06-bd9d-6856fd317888_base_resized.jpg) [2](https://booth.pximg.net/05984c74-52bf-47b2-9259-8c5686282822/i/8280707/9fbfdf28-737a-438a-8495-a34437b53906_base_resized.jpg) | https://booth.pm/ja/items/8280707 | 2026-04-29 | 15 | **検索と解析**: Blender 標準のメニューや他アドオンのメニューを検索し、その構成要素（オペレーター、ラベル、アイコン）を瞬時にスキャンします |
| Simple Pie Menu – Custom Menus & Floating Buttons | Blender | Virtual Rain Development | [1](https://booth.pximg.net/3c87449f-49fc-4040-a4c6-3530448d0006/i/8799047/78503d71-97fc-4e6f-8b42-219e6cc86ba0_base_resized.jpg) [2](https://booth.pximg.net/3c87449f-49fc-4040-a4c6-3530448d0006/i/8799047/e943122b-ceec-44f2-befa-b5f995ee8715_base_resized.jpg) | https://booth.pm/ja/items/8799047 | 2026-09-24 | 1 |  |
| 【無料】BlenderのNパネル タブ並び替えアドオン - Sidebar Tweaks | Blender | laynts shop | [1](https://booth.pximg.net/10cc605a-88f0-49b6-99ca-71498783850b/i/8664195/88ccbcab-bb0b-4aaf-adb8-48215fe80d62_base_resized.jpg) [2](https://booth.pximg.net/10cc605a-88f0-49b6-99ca-71498783850b/i/8664195/a29d0367-955a-46db-9e3e-047e322182bd_base_resized.jpg) | https://booth.pm/ja/items/8664195 | 2026-07-30 | 9 |  |
| Quick TAB ｜ BlenderのNパネル「タブ地獄」を解消する  究極のインターフェース・アドオン  | Blender | hinata-hugu29 | [1](https://booth.pximg.net/05984c74-52bf-47b2-9259-8c5686282822/i/7833203/4a83bc85-2f40-4e68-9a12-2518b4150564_base_resized.jpg) [2](https://booth.pximg.net/05984c74-52bf-47b2-9259-8c5686282822/i/7833203/b3ce563f-30d4-4479-9b36-97f338315823_base_resized.jpg) | https://booth.pm/ja/items/7833203 | 2026-01-03 | 25 |  |
| 全ての追加ノードを一覧表示するメニューアドオン【Add Node Panel Menu / Blenderアドオン】 | Blender | Bookyakuno | [1](https://booth.pximg.net/06c7626c-3b33-4f13-b11b-a3dc8b20e21d/i/5299223/1f709126-6508-47bb-bfa7-9f871142bdea_base_resized.jpg) | https://booth.pm/ja/items/5299223 | 2023-11-29 | 24 |  |
| Quick Brush Selector【Blenderアドオン】 | Blender | sum studio | [1](https://booth.pximg.net/f1db9037-f99c-4a86-9c0b-b62221b72f52/i/6535509/4bb33c02-3587-4baa-b300-68671301752c_base_resized.jpg) [2](https://booth.pximg.net/f1db9037-f99c-4a86-9c0b-b62221b72f52/i/6535509/42b83d1a-c4df-4e49-86ee-892e6bafe960_base_resized.jpg) | https://booth.pm/ja/items/6535509 | 2025-01-28 | 4 |  |
| Live Theme Editor ｜ blenderのテーマ編集用アドオン | Blender | hinata-hugu29 | [1](https://booth.pximg.net/05984c74-52bf-47b2-9259-8c5686282822/i/7730578/2581f9ab-d91f-4e39-8338-b557c8d0a561_base_resized.jpg) | https://booth.pm/ja/items/7730578 | 2025-12-05 | 71 |  |

## Photoshop のスタイル・マスク周り

レイヤースタイル管理を木構造にしたパネル（Style Tree）。輝度マスク（Lumenzia 型）は日本の作者のものが見つからず、TK Panels・Lumenzia がそのまま使われている。

| 名前 | ホスト | 作者 | 画像 | 商品 | 公開日 | ♡ | 作者の言葉（説明文より） |
|---|---|---|---|---|---|---|---|
| 【Photoshop】レイヤースタイル管理の革新的プラグイン『Style Tree』 | Ps | YUTAの開発BOOTH | [1](https://booth.pximg.net/4e978fc0-b6e8-4c68-b669-230ffc7a950f/i/8887774/e90da7b4-c236-4b3c-ad97-470447553026_base_resized.jpg) [2](https://booth.pximg.net/4e978fc0-b6e8-4c68-b669-230ffc7a950f/i/8887774/993452c4-35b4-4ae6-a7a6-d953f039818d_base_resized.jpg) | https://booth.pm/ja/items/8887774 | 2026-10-08 | 11 | Photoshop標準のスタイルパネルに登録されているレイヤースタイルを、Style Treeへまとめて登録 |

## アンカーポイント欄 → 9点の押しボタン

AE 本体も 25.x で「Quick Set Anchor」（9点のポップオーバー）を標準化＝ユーザーパネルが吸収された例。Premiere にも同型。

| 名前 | ホスト | 作者 | 画像 | 商品 | 公開日 | ♡ | 作者の言葉（説明文より） |
|---|---|---|---|---|---|---|---|
| 【After Effects】複数レイヤーのアンカーポイントを9箇所へワンクリックで移動する拡張機能「AnchorMov | AE | FASCOM lab | [1](https://booth.pximg.net/a1934618-274b-4eb2-9c55-dc69d7872d9d/i/8899120/907ec7ff-ee97-49ea-9fbe-aa971c9ab14c_base_resized.jpg) [2](https://booth.pximg.net/a1934618-274b-4eb2-9c55-dc69d7872d9d/i/8899120/29b603f0-a4f3-45a8-b853-c6a351aa71f5_base_resized.jpg) | https://booth.pm/ja/items/8899120 | 2026-09-25 | 0 | アンカーポイントを手でドラッグして動かすのが面倒 |
| 【AfterEffect】アンカーポイントをクリックで設定する | AE | スターリット工房 | [1](https://booth.pximg.net/004f05a9-cf73-4c44-9e7e-10e44214914e/i/7755523/b97c8c82-c37b-4cfe-8bf2-f9fdab1cd687_base_resized.jpg) | https://booth.pm/ja/items/7755523 | 2025-12-13 | 5 |  |
| 【Premiere Pro/Win版】アンカーパネル / AnchorPanel | Pr | もけ太 | [1](https://booth.pximg.net/0776c594-9338-4e9d-bed6-db4946f1d6f6/i/8744523/1db16619-4c20-4f63-b286-4087b974420c_base_resized.jpg) | https://booth.pm/ja/items/8744523 | 2026-08-21 | 3 |  |
- Premiere の「GraphEasy（キーフレームのグラフ表示・編集）」booth.pm/ja/items/8347294 は検索に出たが商品ページが 404（削除済み）。
