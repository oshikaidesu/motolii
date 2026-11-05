# weighs/ — 重み×変化のプリセット

*Presets for weigh.h, one JSON file each: a stack of effects, each a weight (which copies, how much, when) times a change (what value, by how much). Given to a thing with `say <thing> weigh <the JSON on one line>` (edit.sh) — a window will list this folder as it lists `animators/`. The three here are the shape of Texton (BOOTH's lyric-motion panel for After Effects): a travel, a duration, an offset across the letters, an ease, in and out.*

| ファイル | 何か | Texton のつまみとの対応 |
|---|---|---|
| `Slide In.weigh` | 文字が右から順に来て、Back.out で収まる。来る間に不透明に（右に 0.3 置いて、イーズで 0.3 戻す：CSS の「まず値、次に規則」） | 距離 = `x` の `value`、時間 = Time の `b`、文字ごとのずれ = `delay`、イーズ = Remap の `way`、方向 = `target` を `y` に |
| `Fast Blink.weigh` | 文字が順に、点いて消えて点いて消えて点く | Set の連続。後の行が勝つ（CSS と同じ） |
| `Rise Out.weigh` | 終わりの 0.9 秒前から、順に上へ抜けて消える | Out = Time の `a` を負に（物の終わりから数える）。イーズは `bezier x1 y1 x2 y2`（キーと同じ曲線） |

単位：`x`・`y`・`z` は舞台の単位（copy_x と同じ）、時間は秒、物の始まりから。逆順は Index を `"a":1,"b":0`。往復は同じ target に正負の Add を Time をずらして 2 行。
