# UI デザインの外の評価軸（2026-10-17、英・日・韓・中で検索）

**きっかけ**：私の挙げた条件（揃っている、控えめ、色は意味だけ…）だと Excel が満点になる、とユーザーに指摘された。抜けていた軸を、外で探した。

## 見つかった軸

| 名前 | 軸 | 何が分かるか |
|---|---|---|
| **Lavie & Tractinsky（2004）** | **古典的**（整っている、明快）と **表現的**（独創的、魅力がある、洗練） | Excel は古典的では高く、表現的では低い。私の条件は古典的のほうしか見ていなかった |
| **VisAWI（Moshagen & Thielsch 2010）** | 単純さ、多様さ、色の豊かさ、作り込み（18問） | 使われることの多い、裏付けのある質問紙。4軸に分けて点を付けられる |
| **VISQUAL（Jylhä & Hamari 2020）** | 優れている／劣る、優美／荒い、活気／停滞、普通／奇抜、複雑／単純 | アイコンなど、GUI の部品1つずつに使える |
| **Apple Design Awards「Visuals and Graphics」** | 目を引く絵、腕のいい描き込み、質の高い動き、まとまりのある独自の見た目 | 実際の賞の基準（公式の採点表ではなく、発表文の言葉） |
| 中国の研究（浙江大学学報 2020） | 12の美しさの指標。釣り合い、比率、簡潔さ、呼応 | 計算で出す指標 |

## 測り方について分かったこと

- **見た目の複雑さが、美しさの判断を一番よく予測する**（複雑なほど低い）。
- **点を付けるより、2つを並べて「どちらが上か」を選ばせるほうが安定する。** 最近の AI デザインの評価（UI-Bench）でも、専門家に目隠しで2つを比べさせる方法が中心になっている。
- **計算で出す指標は補助に留める。** Aalto Interface Metrics（17の指標、ソースは公開されている）や UIClip（UI デザインを点数化するモデル）がある。ただし、人の判断のうち説明できるのは半分ほど（49%）まで。
- 日本語と韓国語では、UI 向けの尺度はほとんど見つからなかった。日本語では、デザインの評価語を選んだ研究（西藤・田川 1999）がある。

## 出典
- https://www.bgu.ac.il/en/researcher/noam-tractinsky/publications/327435009/
- https://anthonyhobday.com/blog/20221005.html
- https://webpages.tuni.fi/gamification/2020/06/26/visqual/
- https://link.springer.com/article/10.1007/s11257-020-09263-7
- https://sol.sbc.org.br/index.php/ihc/article/view/22254
- https://arxiv.org/pdf/2508.20410 （UI-Bench）
- https://arxiv.org/pdf/2404.12500 （UIClip）
- https://aaltodoc.aalto.fi/items/a5da620f-fcbc-4e88-b0f4-e4143fc7147f （AIM）
- https://www.zjujournals.com/eng/CN/10.3785/j.issn.1008-973X.2020.12.001
- https://www.apple.com/newsroom/2021/06/apple-announces-winners-of-the-2021-apple-design-awards
