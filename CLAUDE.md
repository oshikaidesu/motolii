# UI の確かめ方

UI デバッグの正本は `test/golden/`（ゴールデンテスト）。エンジン不要・画面アクセス不要で PNG が手に入る。
画面操作ツール（computer-use / Codex CUA）は実アプリのインタラクション（ドラッグ、タイムラインのスクラブ等）を見たいときだけ使う。

# 画面操作

画面操作（computer use）には **Cua Driver** (`cua-driver`) を使う。
組み込みの computer-use ツールやスクリーンショットベースの代替は使わない。

- コマンド: `cua-driver mcp`（stdio MCP サーバー）
- 許可: macOS のアクセシビリティ・画面収録は付与済み
- 方式: アクセシビリティツリー＋スクリーンショットのハイブリッド
- 対応: click / type / drag / scroll / 要素名指定
