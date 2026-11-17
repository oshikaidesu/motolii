# スペイン語圏の自作パネル（標準画面を置き換えたもの）

調べた日: 2026-10-17。ウェブ検索と、ページ・画像の取得だけ。サインインはしていない。

## 結果のまとめ

- 見つかったパネルは 14 個（目標は 20）。国がはっきりしているのは 8 個で、残り 6 個は名前やページの言葉から「スペイン語圏らしい」という段階。
- 国がはっきりしている作者は、スペインの Adrian Pueyo（Nuke）、スペインの Miquel Campos（Maya の mGear）、アルゼンチンの Juan Pablo Bouza（Blender の BlenRig）。
- スペイン語圏の作者はリグピッカー（体の絵の上にボタンを並べる画面）に集中していた。BlenRig、mGear、Rig UI Pro の 3 つ。
- 「ワイヤー／ノードを探す画面」の置き換えもあった。Stamps の検索パネルと、nth_Hotbox。
- カラーパレット棚、レイヤーのグループ化、3x3 アンカーグリッドについては、スペイン語圏の作者だと確かめられたものは見つからなかった。似た道具はあるが、作者はベルリンなど別の国だった。
- 作者の国を確かめるのは難しかった。検索エンジンは「Argentina / México」のような国名の条件を効かせてくれなかった。aescripts の作者一覧は 403 で開けなかった。

## 言葉の一覧（先に集めたもの）

| スペイン語 | 意味 |
|---|---|
| panel de curvas / curvas de animación / suavizado (easing) | イーズカーブの盤 |
| en lugar del editor de gráficos / sin el graph editor / adiós al graph editor | グラフエディタの代わり |
| menú circular / menú radial / menú de pastel (pie) / hotbox | 円形メニュー |
| selector de personaje / selector de controles / picker de huesos | リグピッカー |
| paleta de colores / muestras de color / estante de colores | 色の棚 |
| buscador de efectos / búsqueda rápida / buscador de nodos | 検索窓 |
| agrupar capas / carpetas de capas / organizar capas | レイヤーのまとめ |
| ordenar pestañas / panel lateral (N panel) / limpiar la interfaz | タブ・サイドバーの整理 |
| punto de anclaje / mover el ancla / cuadrícula 3x3 | アンカーの 3x3 |
| mejor que el nativo / alternativa a / inspirado en | 標準より良い／代わりに／〜に倣った |
| script gratis / complemento / addon / panel acoplable (ScriptUI) | 道具の呼び方 |

## 1. イーズカーブの盤（グラフエディタの代わり）

| 名前 | ホスト | 作者 | 国 | 画面の画像 | 製品／リポジトリ | 最終更新 | 使われている証拠 | 見つけた経路 |
|---|---|---|---|---|---|---|---|---|
| AnimAide（curveTools のスライダー群） | Blender | Ares Deveaux（aresdevo） | 未確認（元 DreamWorks・Blue Sky・Laika のアニメーター） | https://aresdevo.github.io/animaide/images/animaide.jpg | https://github.com/aresdevo/animaide | 開発停止。Blender 3.6 まで対応 | GitHub で星 795、フォーク 74。BlenderNation の紹介記事もある | 「menú circular」で探した次に、アニメーション用アドオンを検索して見つけた |
| AniMate Pro（Time Warp のピン盤） | Blender | Nacho de Andrés（Not That NDA） | スペイン系の名前、今はオランダに住む（LinkedIn より） | https://www.animate-pro.org/media/time-warp.jpg | https://www.animate-pro.org/ | ページに記載なし | Gumroad と Superhive で評価 4.94。DreamWorks・Disney のアニメーターが推薦 | 「from Spain」などでアニメ用アドオンを広く検索 |
| Quick Animator（9 方向の矢印と IN/OUT カーブ） | After Effects | Eje in Motion | 未確認（名前がスペイン語で「軸」の意味） | https://cdn.prod.website-files.com/646a43f1492ea69c3425c467/67ba26373e839270d81a82ec_Quick%20Animator.webp（表紙画像。パネルそのものかは未確認） | https://www.ejeinmotion.com/after-effects-scripts | 記載なし | 記載なし。$20 | Gumroad でスペイン語の言葉を検索 |

比べたもの: スペイン語でイーズ盤を探すと、Lord of the Eases や Binzii_FastEase（日本の Booth）が出てくる。どちらもスペイン語圏の作者ではないので表には入れていない。

## 2. 円形メニュー／ホットボックス

| 名前 | ホスト | 作者 | 国 | 画面の画像 | 製品／リポジトリ | 最終更新 | 使われている証拠 | 見つけた経路 |
|---|---|---|---|---|---|---|---|---|
| nth_Hotbox（よく使うノードを並べたパネル） | Nuke | Nacho Igea Luengo | スペインと推定（名前から。確定ではない） | Nukepedia に画像なし | https://www.nukepedia.com/tools/python/ui/nth_hotbox/ | 2021-06-15 | ダウンロード 150 | Nukepedia を検索。W_Hotbox（Wouter Gilsing）を簡単にしたものだと本人が書いている（前の道具からたどれる） |
| Modifier Pie Menu（モディファイア用の円形メニュー、V キー） | Blender | Juan Cruz Trejo | 未確認（ページがスペイン語） | なし（ページが 404 になった） | https://juanless2.gumroad.com/l/snntt（現在は 404） | 不明 | $10。数字は取れなかった | 「menú circular addon」の検索 |

止めた理由: 新しい資料を 3 つ見ても、自作の円形メニューは増えなかった。出てきたのは Pie Menu Editor、Better Pie Menus など、スペイン語圏ではない作者のものだった。

## 3. リグピッカー（体の絵の上にボタン）

| 名前 | ホスト | 作者 | 国 | 画面の画像 | 製品／リポジトリ | 最終更新 | 使われている証拠 | 見つけた経路 |
|---|---|---|---|---|---|---|---|---|
| mGear Anim Picker 2.0（SVG の形、スライダー、2D スライダー、裏の絵） | Maya | mGear チーム（中心は Miquel Campos） | スペイン | https://mgear4.readthedocs.io/en/master/_images/anim_picker.png ／ 編集画面 https://mgear4.readthedocs.io/en/master/_images/editor.png | https://mgear4.readthedocs.io/en/master/animPickerUserDocumentation.html | mGear 5.3（2026-10、CG Channel） | GitHub mgear-dev/mgear で星 406、フォーク 132。無料 | Miquel Campos の名前で検索 |
| mGear Synoptic（アニメーター用の画面とピッカー） | Maya | Miquel Campos ほか | スペイン | 未取得 | https://mgear4.readthedocs.io/en/stable/mgear/mgear.synoptic.tabs.visibility.html | 上と同じ | 上と同じ | 同じ説明書から |
| BlenRig の Rig Picker パネル（顔のピッカーもある） | Blender | Juan Pablo Bouza | アルゼンチン | https://studio.blender.org/files/b9/b99bbedb0ece3443aebd05469d76be17048eb1e4/b99bbedb0ece3443aebd05469d76be17048eb1e4.jpg（URL は 1 時間で切れる。元の記事から開き直すこと） | https://studio.blender.org/blog/blenrig-small-update-on-the-gui | 記事は 2015-12-22。BlenRig 6 は 2023 | Blender Studio の映画で使われた。BlenRig 6 の発表は BlenderNation に載った | BlenRig を作者の名前で検索 |
| Rig UI Pro（どんなアーマチュアにも使えるピッカー型パネル） | Blender | Nacho de Andrés | スペイン系、オランダ在住 | https://www.animate-pro.org/media/rigui-popup.jpg | https://www.animate-pro.org/ | 記載なし | 評価 4.94（AniMate と共通）。€40 | AniMate のページから |

ほかの国のもの（参考、表には入れていない）: Shelf Picker（Roberto Menicatti、名前からはイタリア）、dwpicker（ベルギー）、AnimSchool Picker（アメリカ）、Autour de Minuit の rig_picker（フランス）。

## 4. カラーパレット棚

スペイン語圏の作者のものは見つからなかった。出てきたのは ColorBob（ベルリン）、Ray Dynamic Color（Sander van Dijk）、ColorFlow（Théo Miranda）、Blender の Color Palette Pro などで、作者の国が違うか、わからないものだった。

## 5. 検索窓／結果の一覧（メニューやリストの代わり）

| 名前 | ホスト | 作者 | 国 | 画面の画像 | 製品／リポジトリ | 最終更新 | 使われている証拠 | 見つけた経路 |
|---|---|---|---|---|---|---|---|---|
| Stamps の Anchor Selection Panel（線の代わりに名前で検索してつなぐ。タグ・置き場所・使った回数で並べ替え） | Nuke | Adrian Pueyo（と Alexey Kuchinski） | スペイン | https://nukepedia.com/assets/img/users/adrianpueyo/Stamps/Stamps_v1.0_user_guide-012.jpg ／ 動く画像 https://nukepedia.com/assets/img/users/adrianpueyo/Stamps/sc1.gif | https://www.nukepedia.com/tools/gizmos/other/stamps/ ／ https://github.com/adrianpueyo/Stamps | 2026-03-24 | ダウンロード 7,380、評価 5（11 件）、GitHub で星 61。Trixter で使われている（ロゴあり） | Nukepedia の「便利な道具」の一覧から |

## 6. レイヤーのまとめ・たたみ

| 名前 | ホスト | 作者 | 国 | 画面の画像 | 製品／リポジトリ | 最終更新 | 使われている証拠 | 見つけた経路 |
|---|---|---|---|---|---|---|---|---|
| Outliner Bookmarks（アウトライナーに栞を挟み、1 回のクリックでショットへ飛ぶ） | Blender | Nacho de Andrés | スペイン系、オランダ在住 | https://www.animate-pro.org/media/ob-bookmarks.jpg | https://www.animate-pro.org/ | 記載なし | €10。評価は AniMate と共通 | AniMate のページから |
| Stamps のタグ分け（ノードの線をタグごとにまとめる） | Nuke | Adrian Pueyo | スペイン | 5 と同じ | 5 と同じ | 2026-03-24 | 5 と同じ | 5 と同じ |

## 7. タブ・サイドバーの整理

| 名前 | ホスト | 作者 | 国 | 画面の画像 | 製品／リポジトリ | 最終更新 | 使われている証拠 | 見つけた経路 |
|---|---|---|---|---|---|---|---|---|
| AniMate Pro の Pop-Up Panels（サイドバーを開かずに、その場に必要な枠だけを出す） | Blender | Nacho de Andrés | スペイン系、オランダ在住 | 単独の画像は未取得 | https://www.animate-pro.org/ | 記載なし | モジュール 57 個、評価 4.94 | AniMate のページから |

参考: N Panel Sub Tabs、Clean Panels（Amandeep）、Go Panel（Blastframe）が出てきたが、どれもスペイン語圏の作者だとは確かめられなかった。

## 8. 3x3 アンカーグリッド

| 名前 | ホスト | 作者 | 国 | 画面の画像 | 製品／リポジトリ | 最終更新 | 使われている証拠 | 見つけた経路 |
|---|---|---|---|---|---|---|---|---|
| Power Shapes（アンカーと揃え、イーズの調整を 1 枚にまとめたパネル） | After Effects | Eje in Motion | 未確認（名前がスペイン語） | https://cdn.prod.website-files.com/646a43f1492ea69c3425c467/6997969f3ac687e13ba67d26_power-shapes-tutorial-thumbnail.webp（動画の表紙。パネルが写っているかは未確認） | https://www.ejeinmotion.com/after-effects-scripts | 記載なし | 無料。数字はない | Gumroad の検索 |

参考: Motion Tools Classic（Motion Design School）にもアンカーとイーズがあるが、スペイン語圏の作者ではない。

## その他: 標準パネルをはっきり置き換えたもの

| 名前 | ホスト | 作者 | 国 | 置き換えたもの | 画面の画像 | 製品／リポジトリ | 最終更新 | 使われている証拠 | 見つけた経路 |
|---|---|---|---|---|---|---|---|---|---|
| KnobScripter 3 | Nuke | Adrian Pueyo | スペイン | 標準のスクリプトエディタと「Manage User Knobs」の画面 | https://nukepedia.com/assets/img/users/adrianpueyo/KS3_overview.png ／ https://nukepedia.com/assets/img/users/adrianpueyo/KS3_Snippets.png | https://www.nukepedia.com/tools/python/ui/knobscripter/ ／ https://github.com/adrianpueyo/KnobScripter | 2026-03-24 | ダウンロード 3,976、評価 5（6 件）、GitHub で星 99。lesterbanks と CGPress で紹介 | 頼まれた中にあった Adrian Pueyo の名前から |
| Comma（自分でつながる点ノード。プリセットと見た目を選べる） | Nuke | Adrian Pueyo | スペイン | 標準の Dot ノード | 未取得 | https://www.nukepedia.com/tools/gizmos/other/comma/ | 2018-07-08 | 記載なし | Nukepedia を作者名で検索 |
| Loop and Wiggle（よく書く式をボタンにした小さなパネル） | After Effects | Friends in Motion（Gumroad の名前は juancarniz） | 未確認 | 式を手で打つこと | 未取得 | https://juancarniz.gumroad.com/l/LoopOutFriends | 記載なし | 記載なし | Gumroad でスペイン語の言葉を検索 |

## 見つからなかったもの・やり残し

- 調べていないホスト: C4D、Premiere、Resolve、Unity。どれも、スペイン語圏の作者が作った置き換えパネルにはたどり着けなかった。
- Domestika の講座の道具一覧: 講座のページでは道具の名前が出なかった。出てきたのは Duik や Particular などの一般的な名前だけ。
- 作者の国を確かめるのが一番の難所だった。次に開くとよい場所:
  - aescripts の作者ページ（このツールでは 403。ブラウザなら開ける見込み）
  - Superhive の販売者ページ
  - アルゼンチンの Pablo Vazquez が加わった Amaranth（Blender の便利道具集。8 つの機能からは外れるので表に入れていない）
- 確かめられなかった人: Ares Deveaux、Juan Cruz Trejo、Eje in Motion、juancarniz の国。
