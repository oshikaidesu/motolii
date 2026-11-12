# Motolii

*Rules for anyone, person or AI, changing this repository: the aim (an expression found on the net, usable in your video at once), the layout every folder follows, how to check work, the author's principles, and cleaning up after yourself.*

## 目的

ネットで見つけたかっこいい表現を、自分の動画にすぐ使えること。
新しい表現のために開発者の対応を待たせない。

ユーザーが表現を使えるようになることが成果。
コード量や機能数は成果ではない。

## 現在の構成

- データ：SQLite
- 2D・文字：ThorVG
- 最終合成・3D：Filament
- 動画：GStreamer
- UI：Flutter（操作のみ）
- クロスプラットフォーム、60fps駆動

構成は現状の記録であり、守るべき目的ではない。
より良い既存実装があれば交換する。

## 構成の目標

読む人は 2 人いる。表現を持ち込む人は `shelves/` だけを見る。コードを直す人は `app/`・`engine/` を見る。どちらも 3 分で迷わないこと。

1. 直下に置くのは、入口 4 つ（`shelves/`・`app/`・`engine/`・`docs/`）と決まった文書（`README.md`・`README.ja.md`・`AGENTS.md`・`LICENSE-APACHE`・`LICENSE-MIT`・`THIRD_PARTY_NOTICES.md`・`Brewfile`）と、git と GitHub が読む `.` で始まる物（`.github/`・`.githooks/`・`.gitignore` など）だけ。
2. 入口ごとに README を 1 枚置き、その表に 2 段目のフォルダを全部 1 行ずつ載せる（`app/` は `lib/` の中まで）。表に無いフォルダは、無いのと同じ。
3. 他人のコードは、場所で見分けがつくようにする。そのまま持ち込んだ物は `shelves/`・`engine/third_party/`、それへの手直しは `engine/deps/patches/<lib>/`、動かすための口は `engine/community/` に置く。それ以外は全部自前。
4. 作った物（組み立て・テストの出力、調査の絵）は、`engine/out/`・`app/build/`・`docs/internal/` の外に出さない。
5. 名前だけで中身が分かるようにする。身内の言葉は作らず、After Effects・Filament・Flutter・Blender を使う人が知っている言葉を使う（例：他人のコードを動かす口は `adapter`）。番号の名前と 3 文字の略語は使わない。
6. 1 つのフォルダに置く自前のファイルは 40 本まで。超えたら役目で分ける（棚の中身は数えない）。
7. 言語の決まった置き場に従う（Flutter は `test/`・`integration_test/`・`tool/`、CMake はソースの外で組み立てる）。

## 働き方

来た人も AI も、最初の 3 分でこれだけ読めば動ける。

- 始める前に `git config core.hooksPath .githooks`。コミットのたびに、Dart が `dart format` のままかだけが確かめられる（[.githooks/README.md](.githooks/README.md)）。整形・解析・テストは push と PR のたびに CI（`.github/workflows/checks.yml`）が回す。
- 言葉：コードも文書も、アプリ・エンジン・レイヤー・プロジェクト・プレビューと、After Effects などと同じ言葉で呼ぶ。左のタブだけ「棚」（Blender の Asset Shelf）。古い言い方との対応は [renamed_words.md §1](docs/design/renamed_words.md)。
- 確かめるときは、錠の要らない静的な検査から始める。
  - Dart：`cd app && dart analyze lib`
  - C++：`./engine/check_syntax.sh`（CMake が各ソースに渡す指定で `clang++ -fsyntax-only`。何も書かない。`ok: <本数> sources` か、誤りとその行）
- テストの手順は [docs/TESTING.md](docs/TESTING.md)。
- 終わったと言えるのは、使う人に見える物（絵・画面・書き出したファイル）で示せた時だけ。そして、その検査が直す前には落ちるのを見た時だけ。

作者が決めた原則。破る変更は、理由が正しくても入れない。

1. ネットの表現は翻訳しない。貼られたコード（AE の式・Cavalry・p5.js・シェーダー）は、そのまま 1 回組んで動かす。同じ動きを C++ で真似して作らない（2026-11-08）。
2. 値を、出典なしに固定しない。灰色にもしない、拒みもしない。スライダーの範囲は表示のためで、入力を限らない。限るときは、同じ値を限っている出典を書く（2026-11-09）。
3. アプリの中に Web ページを埋めない。見た目の編集はコードから読み取り、編集をコードへ書き戻す。コードの写しを別に持たない（2026-11-09）。
4. 小さい頼みは、Motolii に既にある仕組みでそのまま済ませて止める。外の調べ物は、Motolii に何も無い時だけ（2026-11-09）。
5. Dart は見た目だけを持つ。押し・重ね・選択は、既に依存している実装に渡す。依存は足さない（例外：Agent パネルの ACP と返事の Markdown。`acpd`・`acpd_io`・`flutter_markdown_plus`、2026-11-12）。同じ手書きが何度も出るのは、分けたのではなく写しである。インスペクターではエフェクトのカード（`ValuesCard`）が正本で、それ以外のカード・数値・チップ・スイッチの手書きはそこへ畳む。まとめられるものはまとめ、消してよい。戻すなら git。5000 行は見た目の分量の目安であり、目標ではない（2026-11-10）。

## 後始末

初めて来た人が 3 分で読めない物は、置いた者の負債。どれも実際に起きた散らかしから決めた。

- 手を止める前にコミットする。未コミットのまま main に 244 件を置き去りにして消えたセッションがあった。
- 取り込み終わった worktree とブランチは、その場で消す。15 個が残っていた。
- パッチ・ビルド出力・調査資料を、ソースの隣に置かない。
- ビルドの錠（`/tmp/motolii-build.lock`）を数分を超えて握る作業は、始める前に理由と長さを報告する。誰かが待っていたら先に通す。この機械にしか無い物を片付けるために、他の全員を止めない。1 人が共有の Filament を作り直したせいで、他の 2 人が錠の前で待たされた。
- ビルドは、結果が出るときだけ回す。結果が出るとは、通るか落ちるかが先に決まっていて、落ちたら次にやることが変わること（例：`./engine/drawings_unchanged.sh <前のコミット>` で、絵が前と変わっていないか）。大きく書き換えている途中の「まだ起動するか見るだけ」のビルドはしない。次の書き換えで、その確かめは消える。ビルドは重く、同時に走らせると機械が落ちるので、錠（`engine/tools/build_lock.sh`）を取って 1 本ずつ、リードが回す。構文検査（`./engine/check_syntax.sh`）と Dart の解析・テストはビルドではないので、いつでも先に使う（2026-11-10）。
