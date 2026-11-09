# Alight の Range を測った（2026-11-07）

Alight Motion 6.2.60（Android エミュレーター）。Linear Repeat に円を 1 つ、Count 11、Position X 1600。
Range Transform の Offset Y を 400 にし、各コピーがどれだけ下がったかを、そのコピーの真下の縦一列の黄色で読んだ。
下がった量 ÷ 400 が、そのコピーへの効き具合（0〜1）。誤差は ±0.01 ほど。

Alight の説明書（guide.alightmotion.com/effects/linear-repeat など）は、Repeat 系も Text Transform も「Under Construction」。
だから全部、実測。

絵は docs/internal/reports/alight_motion/alight_range/ に置いた（reports の絵は .gitignore で git に入れない決まり。作り直すのは下の表の数字から）。

![実測](alight_range/weights.png)

![Alight の画面：既定のまま](alight_range/alight_ramp.jpg)

## 答え 1：Range は何をしているか

**コピーの住所**
n 個のコピーの i 番目（0 から数える）は、住所 u = (i + 1.5) / (n + 1) を持つ。
- Count 11 は 1.5/12 〜 11.5/12。Count 5 は 1.5/6 〜 5.5/6。Count 3 も Count 2 も同じ式に乗った。
- 先頭に 1 枠分、空きがある。だから既定の RAMP で、1 匹目は 0 ではなく 0.12 から始まる。

**効き具合**
x = (u − Start + Phase) / (End − Start)、0〜1 に切る。
| つまみ | 既定 | 測った形 |
|---|---|---|
| Start・End | 0%・100% | x の 0 と 1 の場所 |
| Phase | 0% | 範囲を丸ごと前へずらす。端で折り返さない（TRIANGLE で Phase 30% にしても、はみ出た所は 0） |
| Shape RAMP（既定） | | w = x |
| Shape SQUARE | | 範囲の中は 1、外は 0。縁にかかるコピーは半分（Start 30%・End 70% で 0.4） |
| Shape TRIANGLE | | w = 1 − \|2x − 1\| |
| Shape SMOOTH | | w = exp(−20 (x − 0.5)²)。釣鐘。端でもほぼ 0（0.007） |
| Ease In・Ease Out | 0% | 3 次ベジェ。取っ手の長さ = % の半分。Ease Out 100% と 50% は誤差 0.004 以下、Ease In 100% は 0.02 以下 |
| Overlap | 0% | 住所の式が u = (i + 1.5 + 1.5·ov) / (n + 1 + 2·ov) に変わる（ov は 0〜1）。坂がなだらかになる。TRIANGLE・SMOOTH の山は、Count 11 だと 5 番目と 6 番目の間から 5 番目へ、半コピー左に寄る |
| Invert | 切 | w → 1 − w |
| Random Order | 切 | 同じ効き具合のまま、誰が何番目かを並べ替える |

Overlap の式は測った 3 点（0%・50%・100%）と Count 3・11 に合わせた物。なぜこの形なのかは分からない。

**After Effects との対応**（After Effects の範囲セレクタは CS4 のマニュアル p.375、manualsdir.com/manuals/753844）
| After Effects | Alight |
|---|---|
| Start・End・Offset | Start・End・Phase |
| Shape：Square・Ramp Up・Ramp Down・Triangle・Round・Smooth | Shape：SQUARE・RAMP・SMOOTH・TRIANGLE、Ramp Down は Invert |
| Ease High・Ease Low | Ease Out・Ease In |
| Smoothness（Square の時の移り変わり） | Overlap（に近い。同じかは未確認） |
| Randomize Order・Random Seed | Random Order・Seed |

Alight の Range は、After Effects の範囲セレクタを、ほぼそのままカードに写した物。

## 答え 2：時間はどこから来るか

Repeat 系のカードには、コピーごとに時間をずらすつまみが無い（Count・Position・Range Transform・Fill Color・Range・
Interpolation & Easing・Random Order だけ）。効き具合は、その時刻のつまみの値だけで決まる。
だから「順に出る」は、Start・End・Phase のどれかにキーを打って、範囲を時間で動かして作るしかない。
After Effects の文字アニメーターと同じやり方。キーの打ち方そのものは今回は試していない。

## 答え 3：Alight は分かりづらさを隠しているか

隠していない。中身も単位（%）も After Effects と同じ。違うのは、カードの束に畳んで、普段は閉じていることだけ。
しかも、先頭の 1 枠の空き・Overlap が山をずらすこと・SQUARE の縁が半分になることは、画面のどこにも出ない。
測らないと分からない。

## Motolii に持ち帰る事

- **グループの仕様（docs/internal/notes/GROUP_FOCUS_new.md）とのずれ**
  - Alight では、時間は「範囲にキー」、配り方は「Shape と Ease」で、別々のつまみ。
  - Motolii の仕様では、時間は stagger の行のキー、配り方は Min・Max と区間イージング。
  - 「区間イージングが配る曲線」と書いた所は、Alight と同じ物を指していない。Alight の Ease は時間ではなく、コピーの並びに沿った坂の曲げ方。
- **Scatter Repeat（engine/community/absent_motion/absent_motion.cpp の scatter_repeat）は Alight と違う**
  - 住所は k / (n − 1)。先頭の空きが無い。
  - 坂は RAMP だけ。Shape・Ease・Overlap・Invert は無い。
  - この表の式で埋められる。AbsentMotion の `Ranged()`（Linear・Grid・Radial が使う）も同じく RAMP と単純なイーズだけ。

## 測り方の道具

scratchpad に置いた使い捨て（am.sh：画面を叩く・撮る・読む、put.sh：数字の欄に打つ、knob.sh：つまみを名前で探して打つ、
w.py：撮った絵から 11 個の効き具合を読む）。エミュレーターは AVD Tablet_API35、縦 1200×2400・密度 320 にして測った。
