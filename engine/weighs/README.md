# weighs/ — 重み×変化のプリセット

*Presets for weigh.h, one JSON file each: a list of lines, each answering where (which copies, how much), when (from when, over how long, each copy how much later) and what (which value, Set/Add/Mul, by how much; an ease). Given to a thing with `say <thing> weigh <the JSON on one line>` (edit.sh). The three here are the shape of Texton (BOOTH's lyric-motion panel for After Effects): a travel, a duration, an offset across the letters, an ease, in and out. A preset is a saved result, not the way in: a window makes these lines from the stage (where), the timeline (when) and the inspector (what).*

| ファイル | 何か | Texton のつまみとの対応 |
|---|---|---|
| `Slide In.weigh` | 文字が右から順に来て、Back.out で収まる。来る間に不透明に（右に 0.3 置いて、when で 0.3 戻す：CSS の「まず値、次に規則」） | 距離 = `x` の `value`、時間 = `over`、文字ごとのずれ = `stagger`、イーズ = `ease`、方向 = `target` を `y` に |
| `Fast Blink.weigh` | 文字が順に、点いて消えて点いて消えて点く | Set の連続。後の行が勝つ（CSS と同じ）。`over` 無しは一瞬 |
| `Rise Out.weigh` | 終わりの 0.9 秒前から、順に上へ抜けて消える | Out = `from` を負に（物の終わりから数える）。イーズは `bezier x1 y1 x2 y2`（キーと同じ曲線） |

単位：`x`・`y`・`z` は舞台の単位（copy_x と同じ）、時間は秒、物の始まりから。順番は `when` の `order`（where と同じ書き方：選ばれている物から先。無ければ行の最初の文字から。逆順は `{"kind":"Index","a":0,"b":1}`、ランダムは `{"kind":"Random","a":50}`、点から波紋は `{"kind":"Distance",...}`）。
