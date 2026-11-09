# .githooks

*The checks that refuse a commit, and the same ones CI runs on every push and pull request. Install once with `git config core.hooksPath .githooks`. When refused, look up the last line's `refused by .githooks/<file>` in the table below: what each refuses and how to fix it.*

コミットを断るのはここの検査。入れ方は 1 回だけ `git config core.hooksPath .githooks`。同じ検査を push と PR のたびに CI（[checks.yml](../.github/workflows/checks.yml)）も回す。

断られたら、最後の行 `refused by .githooks/<file>` の行をこの表で引く。断りの頭の `(rule: …)` が決まり、各行の `;` の後ろが直し方。

| ファイル | 何を断るか | 直し方 |
|---|---|---|
| [pre-commit](pre-commit) | 下の 4 つを順に回し、断った物の名前を出す。最初に負債の数（`debt: …`）を出すが、断りではない | 断った検査の行を見る |
| [pre-merge-commit](pre-merge-commit) | マージのコミットにも pre-commit と同じ検査 | 同上 |
| [commit-msg](commit-msg) | 件名の検査を回す | 同上 |
| [size_check.py](size_check.py) | 自前のファイル（`.dart` `.h` `.cpp` `.mm` `.js`）が 500 行を超える。新しいファイルに `name_2.dart` のような番号の名前 | 役目で分ける。名前を中身にする |
| [layout_check.py](layout_check.py) | [AGENTS.md](../AGENTS.md)「構成の目標」1・2・4・5・6：直下の余計な物、入口の README の表に無いフォルダ、git に入った `out/` `build/`、番号や「文字＋数字」の名前、1 フォルダ 40 本超え。もう 1 つ、[docs/README.md](../docs/README.md)「日本語と英語」：入口 4 つに `.en.md` が無い、日本語で書いた自前の `.md` の題の下に英語の要約が無い（`language:`） | 各行の `rule N:`・`language:` の後ろのとおり。フォルダを作ったら入口の README に 1 行 |
| [path_check.py](path_check.py) | 棚のファイルと自前の `.md` が書いている道（import・画像・リンク）の先が無い | 書いている所を直すか、動いたファイルを追う |
| [format_check.py](format_check.py) | `dart format` のままでない Dart（`dart` が無ければ飛ばす） | 表示されたコマンドを打つ |
| [subject_check.py](subject_check.py) | コミットの件名が 72 字を超える | 1 行目を短く。中身は空行の後の本文へ。書いた文は `git commit -e -F` で戻る |
| [over_500.txt](over_500.txt) | 負債の帳簿：2026-11-09 に既に 500 行を超えていたファイルと、その時の行数。増やす・足すと size_check.py が断る | 分けて小さくし、数を下げるか行を消す |
| [path_check_allow.txt](path_check_allow.txt) | 負債の帳簿：木に無くても通す道（組み立て時に取ってくる物・作る物）。それぞれ理由つき | 動いたファイルを隠すために足さない。取ってくる物が無くなったら消す |

コミットせずに試すには、直下で `python3 .githooks/<file>.py`。急ぎで検査を飛ばす `git commit --no-verify` は、CI で同じく落ちる。
