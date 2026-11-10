# docs — どれを読むか

*Which document is for whom, by reader: using the app, bringing an expression, fixing the window, fixing the engine. The two documents at this folder's root are for anyone fixing either side. `internal/` is the author's notes and research and can be skipped.*

## 読む人ごと

| 読む人 | 開く所 | 中身 |
|---|---|---|
| 使う人 | [`using/`](using/) | [`screen_tour.ja.md`](using/screen_tour.ja.md)（[English](using/screen_tour.md)）：画面のタブごとの絵と使い方。[`make_intro_movie.md`](using/make_intro_movie.md)：README の頭の 8 秒を作る命令（貼れば `~/Movies/Motolii/mv.mp4` ができる）。入口はリポジトリの [`README.ja.md`](../README.ja.md) |
| 表現を持ち込む人 | [`../shelves/README.ja.md`](../shelves/README.ja.md) | 見つけたファイルをどの棚に置くか。持ち込む人は `shelves/` だけを読めば足りるので、docs には置かない |
| アプリ（Flutter）を直す人 | [`app/`](app/) | `BRIDGE.md`：アプリとエンジンの境目。`DESIGN.md`：見た目の決まり。`skins/`：見た目の引き継ぎ（`HANDOFF.md`）。入口は [`app/README.md`](../app/README.md) |
| エンジン（C++）を直す人 | [`engine/`](engine/) | `WINDOWS.md`：エンジンを Windows で組むには何が要るか（まだ組んでいない。ソースを読んで分かった事と分からない事）。入口は [`engine/README.md`](../engine/README.md) |
| アプリとエンジンのどちらを直す人も | この直下 | [`ARCHITECTURE.md`](ARCHITECTURE.md)：全体の作り（アプリ・エンジン・描画・動画のつながり）。最初に読む。[`TESTING.md`](TESTING.md)：試験の決まり（両方の試験が載っているので、どちらかの下には置かない） |

## そのほか

| 場所 | 誰向け | 中身 |
|---|---|---|
| [`pictures/`](pictures/) | — | README とガイドが載せる絵と動画（画面の写真・作例の gif） |
| [`internal/`](internal/) | 作者だけ（読まなくてよい） | 作者のやること・採点表と、他のアプリと Motolii の画面を調べた記録。フォルダごとの表は [`internal/README.md`](internal/README.md) |

## 日本語と英語

決まりは 1 つ：**使う人と持ち込む人が最初に開く入口だけ、日本語と英語の 2 枚にする。それ以外の自前の文書は 1 枚で、日本語で書いた物は題のすぐ下に英語の要約を斜体で 1 段落置く。**

- 2 枚の物（英語の `X.md` と日本語の `X.ja.md`）：直下の [`README`](../README.ja.md)、[`shelves/README`](../shelves/README.ja.md)、[`.github/CONTRIBUTING`](../.github/CONTRIBUTING.ja.md)、[`using/screen_tour`](using/screen_tour.ja.md)。使う人と持ち込む人は日本語を読むとは限らないので、最初の 1 枚は全文を両方で持つ。
- 1 枚の物：`app/`・`engine/`・`docs/` の README と、ほかの自前の文書。直す人はコードの英語のコメントを読む人なので、要約で行き先が分かれば足りる。2 枚目は、片方だけ直されて食い違う写しになる。
- 決まりの外：他人の文書（棚の中身・`engine/third_party/`）は配られた言葉のまま。`internal/` は作者のメモなので日本語だけ。Issue のひな型は GitHub が 1 枚しか出さないので、1 枚の中に両方を並べる。

手伝い方は [`.github/CONTRIBUTING.ja.md`](../.github/CONTRIBUTING.ja.md)（[English](../.github/CONTRIBUTING.md)）。
