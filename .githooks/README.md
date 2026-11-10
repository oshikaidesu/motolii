# .githooks

*The checks that refuse a commit, and the same ones CI runs on every push and pull request. Install once with `git config core.hooksPath .githooks`. When refused, look up the last line's `refused by .githooks/<file>` in the table below: what each refuses and how to fix it.*

コミットを断るのはここの検査。入れ方は 1 回だけ `git config core.hooksPath .githooks`。同じ検査を push と PR のたびに CI（[checks.yml](../.github/workflows/checks.yml)）も回す。

断られたら、最後の行 `refused by .githooks/<file>` の行をこの表で引く。断りの頭の `(rule: …)` が決まり、各行の `;` の後ろが直し方。

| ファイル | 何を断るか | 直し方 |
|---|---|---|
| [pre-commit](pre-commit) | 下の検査を順に回し、断った物の名前を出す。最初に負債の数（`debt: …`）を出すが、断りではない | 断った検査の行を見る |
| [pre-merge-commit](pre-merge-commit) | マージのコミットにも pre-commit と同じ検査 | 同上 |
| [commit-msg](commit-msg) | 件名の検査（subject_check.py）だけを回す | 同上 |
| [size_check.py](size_check.py) | 自前のファイル（`.dart` `.h` `.cpp` `.mm` `.js`）が 500 行を超える。新しいファイルに `name_2.dart` のような番号の名前 | 役目で分ける。名前を中身にする |
| [layout_check.py](layout_check.py) | [AGENTS.md](../AGENTS.md)「構成の目標」1・2・4・5・6：直下の余計な物、入口の README の表に無いフォルダ、git に入った `out/` `build/`、番号や「文字＋数字」の名前、1 フォルダ 40 本超え。もう 1 つ、[docs/README.md](../docs/README.md)「日本語と英語」：入口 4 つに `.en.md` が無い、日本語で書いた自前の `.md` の題の下に英語の要約が無い（`language:`） | 各行の `rule N:`・`language:` の後ろのとおり。フォルダを作ったら入口の README に 1 行 |
| [path_check.py](path_check.py) | 棚のファイルと自前の `.md` が書いている道（import・画像・リンク）の先が無い | 書いている所を直すか、動いたファイルを追う |
| [card_check.py](card_check.py) | Inspector のカードを Dart で手描きする二本目の道：値の鍵を文字列で書く（`'v_shadow_distance'`、`app/lib` 全体）、値の名前を文字列で書く（`'intensity'`、`app/lib/inspector`）。値の名前は `engine/document/card_table.h` から読む | 「declare it like an effect; the inspector reads it」：カードはエンジンの `card_table.h` に宣言し、`ValuesCard` が描く。ホストが値を手で読むのを今すぐ消せない時だけ、`OWED` に理由つきで 1 行 |
| [reach_check.py](reach_check.py) | アプリが届かない物：`engine/entry/motolii.h` の `motolii_*` で、アプリ（`app/` の Dart と Swift の実行部、`engine/stage/snapshot.h`）のどこも呼ばない物。`app/lib` の公開クラス・mixin・enum で、自分の宣言の外のどこからも呼ばれない物（コメントと文字列は数えない） | 「nothing in the window reaches this; wire it to a menu/dock/card or delete it」：メニュー・ドック・カードにつなぐか消す。消した前例と物差しは [noise_cut.md](../docs/internal/notes/noise_cut.md)。今すぐ消せない時だけ、`OWED` に理由つきで 1 行 |
| [shape_check.sh](shape_check.sh) | 外の番人を自前のコードに当てる。[ast-grep](https://ast-grep.github.io/) が [rules/](rules/) の形を断る：Dart の手書きの押し・ホバー・重ね（`GestureDetector`・`Listener`・`MouseRegion`・`OverlayPortal`）、手書きのジェスチャー認識、手描き（`CustomPainter`）、C++ でレイヤーの種類を名前で比べる枝（`== "camera"`）。規格（`app/lib/widgets/`）が包んでいる材料をパネルで直接書く（`NakedButton`・`NakedSlider`・`EditableText`・`TextPainter`）。押し・認識・手描きを自前で書いてよいのは規格のフォルダだけ。コミットではステージしたファイルだけ、CI では全部 | 押し・欄・スライダーは規格の部品（`package:motolii/panel.dart`）を使う。足りなければ規格に足す。絵は書体の字か SVG へ。種類は名前でなく性質を表から読む |
| [rules/](rules/)・[sgconfig.yml](sgconfig.yml) | ast-grep の規則（YAML 1 枚に 1 つ）と、その置き場を言う設定。規則を足すときは、落ちるのを見てから | 断られた行の `note:` を読む |
| [format_check.py](format_check.py) | `dart format` のままでない Dart（`dart` が無ければ飛ばす） | 表示されたコマンドを打つ |
| [own_code_check.py](own_code_check.py) | 今は走らない（commit-msg からも CI からも呼ばれない）。ファイルは残っているが、コミットを断らない。「先に仮コード」の決まりは、Claude Code の PreToolUse フック [.claude/hooks/own_code_sign.py](../.claude/hooks/own_code_sign.py) として AI の編集にだけ残る | — |
| [what_exists.py](what_exists.py) | 断らない。既にある物を言葉で引く道具：`python3 .githooks/what_exists.py wave copies`。エンジンの側は棚と `engine/community/` の動くファイル（名前と見出し）、Dart の側は Flutter 本体と依存パッケージの class（名前と説明）、エンジンの C の呼び出しとカード。SQLite の FTS5（bm25）で近い順に出す。入口の札（[.claude/hooks/own_code_sign.py](../.claude/hooks/own_code_sign.py)）と own_code_check.py が同じ物を使う。`--sketch`：動かなくてよい理想の仮コードを流すと、そこで呼んでいる名前を 1 つずつ「ある／近い物がある／無い」で返す（無いと出た物だけが自前で書く分）。自前の写しを自分で見つける道具ではない（全体に当てると 196 本中 191 本を「何かに似ている」と言った）：写しかどうかは読み手が決める | 書く前に引く |
| [subject_check.py](subject_check.py) | コミットの件名が 72 字を超える | 1 行目を短く。中身は空行の後の本文へ。書いた文は `git commit -e -F` で戻る |
| [over_500.txt](over_500.txt) | 負債の帳簿：2026-11-09 に既に 500 行を超えていたファイルと、その時の行数。増やす・足すと size_check.py が断る | 分けて小さくし、数を下げるか行を消す |
| [path_check_allow.txt](path_check_allow.txt) | 負債の帳簿：木に無くても通す道（組み立て時に取ってくる物・作る物）。それぞれ理由つき | 動いたファイルを隠すために足さない。取ってくる物が無くなったら消す |

コミットせずに試すには、直下で `python3 .githooks/<file>.py`。急ぎで検査を飛ばす `git commit --no-verify` は、CI で同じく落ちる。
