# UAT を通す順

[uat_scenarios.md](uat_scenarios.md) の 448 行を、同じ 1 つの部品を直せば一緒に通るまとまりに分け、軽い順に並べた。上から 1 段ずつ取る。

重さは 2026-11-13 の main（UAT を取り消した後）のコードを読んで決めた。動かしてはいない。物差しは 3 つ。

- **軽**：部品は既にある。Dart か棚のファイルを数本直すだけ。依存もエンジン（C++）も触らない。
- **中**：エンジンに手を入れるか、ライブラリを 1 つ足す。ただし今ある仕組みの延長。
- **重**：新しい仕組み、外の実装の新しい組み込み、OS や配布、この Mac に無い環境（Windows・Linux・iPhone・署名）が要る。

「通りそう」は、コードを読む限り通りそうな行。手で確かめるまでは通ったことにしない。

## 段 0：手で通して確かめるだけ

コードを読む限り部品が揃っている行。直す前に、まず手で通す。通らなかった行は、その節のまとまりへ回す。

3 6 7 14 15 18–26 28 29 32 36 38–45 47 48 52–54 56–58 61 63–66 68–71 73–75 77 83–88 92 93 116 120 124 125 128 134 136 148 150 166 173 174 176 178–180 182–184 186 187 197 211 238 240–242 245 246 250 252 260 266 304 307 313 314 327 332–341 355 360 363 366 368 372 378 390 393 395 418 419 428 443 446–448 453

## 軽：Dart か棚だけ

| 段 | まとまり | 通す行 | 直す 1 か所 | 通りそう |
|---|---|---|---|---|
| 1 | 動きの決まりの文書を、コードに合わせる | 188–191 | `docs/app/GESTURES.md`（文書だけ） | — |
| 2 | 右クリックのメニュー | 153 155 157 160 161 162（149 159 は要確認） | `widgets/context_menu.dart`（`PressOutside` ほか） | 152 154 156 158 410 |
| 3 | 棚のタイルを 1 つの見た目に | 129 279–287 | `shelf/shelf_looks.dart` の `shelfLooks`・`shelf/shelf_tile.dart` | — |
| 4 | セーフエリアを各サービスの形で | 217 374 375 | `stage/view_painter.dart` の `_safe` | — |
| 5 | ツールチップとタブのアイコン | 139 411 435–441 | `widgets/controls.dart` の `IconPress`・`window/panes.dart` の `leading` | — |
| 6 | 選んだ全部に掛ける | 381 382 383 384 389 403 | `workspace.dart` の `eachPicked` | 379 380 386 391 |
| 7 | 数値の欄 | 300 301（131 は要確認） | `widgets/number_field_state.dart` の `_typed`・`_commit` | 130 132 133 298 299 |
| 8 | ステージで選ぶ・棚から運ぶ | 121 122 145 146 | `state/art_scene.dart` の `hit`・`stage/stage.dart` | 123 126 127 |
| 9 | 再生の操作 | 108 115 118 151 | `commands/keymap.dart`・`stage/view_painter.dart` | 119 |
| 10 | クリッピングマスクをタイムラインから | 344 345 346 348 349 352 353 | `timeline/row_flags.dart`・`timeline/timeline_labels.dart` | — |
| 11 | コードの見た目を Code タブに揃える | 268–275 277 | `shelf/code_field.dart` を Agent の返事と差分でも使う | 276 278 |
| 12 | 書き出しパネル | 12 99 102 104 105 373 | `top_bar/render_button.dart` | 51 106 218 219 342 |
| 13 | ダイアログ・名前・探す欄の決まり | 113 138 302 406 408 409 | `widgets/modal_card.dart` ほか、行ごと | 9 137 |
| 14 | Agent に渡す物と見せる物 | 198 199 201 202 257 258 265 | `agent/layer_code.dart`・`agent/agent_pane.dart` | 147 170 200 |
| 15 | ピックウィップ | 259 263 | 今ある `--picture@` の口 | 261 262 |
| 16 | ホーム | 94 98 | `bridge/engine_paths.dart`・`workspace.dart` | 95 96 |
| 17 | ばらの軽い行 | 17 34 89 169 177 228 229 239 243 244 248 251 308 310 315 329 331 370 425 427 431 | 行ごと | — |

## 中：エンジンか、ライブラリ 1 つ

ファイルの持ち込みは段 18 の 1 か所が鍵で、ここが通ると他の段の「落とす」行（97 223 328 など）が開く。

AGENTS.md 原則 1「既存を最大限そのまま解放する」の軸で、独自実装よりまず外部実装を繋ぐ候補を書く。候補はクロスプラットフォーム（macOS・Windows・Linux の 3 つで動く）のものを先に選ぶ。OS 固有の API（CoreText・Photos.framework・NSDocument など）はどうしても要る時にだけ、`部品の中` を差し替えやすい口を通して使う（原則 6「交換・削除しやすく」）。

| 段 | まとまり | 通す行 | 直す 1 か所 | 外部実装の候補 |
|---|---|---|---|---|
| 18 | Finder からファイルを落とす・⌘V | 1 8 97 111 230 231 233 306 | ライブラリを 1 つ（`desktop_drop` か `super_clipboard`）→ `dock/media/media_commands.dart` | `desktop_drop` / `super_clipboard`（どちらも macOS・Windows・Linux 対応）（**8 行開く鍵**） |
| 19 | 書き出しの中身 | 5 100 101 103 140 215 216 247 376 | `engine/stage/render/render_draw.cpp` の ffmpeg の引数・`engine/entry/motolii.h` の書き出し | ffmpeg の引数を広げるだけ（ffmpeg は 3 つの OS で動く） |
| 20 | AE の式 | 16 356 357 | `engine/community/after_effects/ae_expr.h`（`posterizeTime`）・`script_runner.cpp`（止める口） | `ae_prelude.js` に `posterizeTime` を足す / lottie-web ExpressionManager の該当関数（QuickJS 上で OS 非依存） |
| 21 | フォントの棚の言語と名前 | 288–296 364 | `engine/entry/calls_files.cpp` の `motolii_font_tags` | HarfBuzz / FreeType の `name` テーブル読み（既に Skia 経由で入っている、3 つの OS で動く）。CoreText は使わない |
| 22 | グラデーションを線・縁取り・平面・エフェクトへ | 420–424 426 | `engine/stage/canvas/canvas_ramp.cpp` の `ramp_of` | Skia / ThorVG の gradient（どちらも 3 つの OS で動く） |
| 23 | クリッピングマスクのエンジン側 | 347 350 351 | `engine/document/evaluate/evaluate_clipping.cpp` | 既存の matte パスを広げる |
| 24 | 素材のエラーをアプリに出す | 141 163 164 165 167 168 171 305 | エンジンが作っているエラーの文を、スナップショットでアプリへ | 既存の `d.error` の文を取るだけ |
| 25 | 取り消しの名前 | 135 | `engine/document/undo.cpp` の `undo_step` に名前 | 名前を string で渡すだけ |
| 26 | エフェクトを描く範囲 | 442 445 449 454 | `engine/document/evaluate/moment_fx.cpp` | 既存の bounding box をそのまま使う |
| 27 | 拍で値を動かす | 46 49 50 371 365 | 式から拍を読む口（`engine/community/script_runner/`） | AE の `thisComp.timeToFrames` / Alight の BPM（式のレイヤーで OS 非依存） |
| 28 | 物理の形・眠り・つなぎ・焼き付け | 30 31 33 37 | `engine/community/jolt/rigid_bodies.cpp` | Jolt の既存 API（`SetSleep`, `Constraint`, `SaveState`、3 つの OS で動く） |
| 29 | 貼ったコードの見分け | 67 72 82 203 204 | `engine/community/sites/adapter.cpp` | 既存の adapter に site 判定を足す |
| 30 | 組版 | 27 367 369 | `engine/document/match/match_text.cpp` | HarfBuzz / Skia の既存機能（3 つの OS で動く） |
| 31 | 表現の作例のうちエンジンが要る物 | 78 354 358 359 361 362 | 行ごと | 行ごと |
| 32 | ばらの中の行 | 2 13 110 117 185 205 206 210 212 221 223 237 253–256 264 267 297 303 309 328 330 | 行ごと | 行ごと |

## 重：新しい仕組みか、外の環境

ここも外部実装を先に当てる。OS 固有のものは差し替えやすい口で分ける。

| まとまり | 行 | 外部実装の候補 |
|---|---|---|
| コードの書き換えを 1 回の取り消しに | 4 311 312 | CodeMirror 6 の `history` module（Code タブに既に入れた方向） |
| どこでも同じ選び方（1 つの選択の部品） | 385 387 388 392 394 396–402 404 412 | `app/lib/widgets/picks.dart` に 1 本化（Flutter の MultiSelectableController 系の pattern） |
| 窓の大きさを引いたままに（multi_split_view の比率の扱い） | 142 143 144 175 429 430 432 433 434 | multi_split_view 自体（3 つの OS で動く） |
| PSD・AI・SVG のグループ・Live2D | 55 60 316–326 | `ag-psd`（JS, QuickJS で動く, OS 非依存）・resvg（Rust, 3 つの OS）・Live2D Cubism Core（3 つの OS） |
| 配布・Windows・Linux・日本語の画面 | 109 112 114 192–196 225 227 405 407 413 414 415 416 417 | Flutter の各 OS 配布 + `flutter_localizations`（Dart/Flutter が 3 つの OS 揃える） |
| エフェクトを 1 回にまとめる・複製全体に掛ける | 444 450 451 452 | 既存の `evaluate_copies.cpp` を広げる |
| プロジェクトを OS に結ぶ（ダブルクリック・Quick Look・2 つの窓） | 172 222 226 234 249 | OS 固有の口は分ける：macOS = NSDocument、Windows = IFileDialog、Linux = GNOME/KDE の MIME。共通層を Dart か C++ の 1 インタフェースに |
| 写真アプリ・iPhone | 209 213 214 220 232 | OS 固有（macOS Photos.framework / Windows Phone Link / Linux は KDE Connect）。アプリから 1 つの「写真を貰う」口にし、中身を差し替え |
| 外へ引きずり出す | 235 236 | Flutter の drag-out は各 OS 対応のライブラリ（`super_drag_and_drop`、3 つの OS で動く） |
| パペット・奥行きの推定・流体 | 35 59 62 | MediaPipe Pose（3 つの OS）・MiDaS/Depth Anything の ONNX（`engine/third_party/onnxruntime` 既にある、3 つの OS）・Jos Stam の Stable Fluids 既存実装 |
| その他 | 10 76 107 181 207 208 224 343 377 | 行ごと |

残りの行（読む限り通りそう・要確認の物）は、上の表の「通りそう」と、[uat_scenarios.md](uat_scenarios.md) の各節を手で通して決める。
