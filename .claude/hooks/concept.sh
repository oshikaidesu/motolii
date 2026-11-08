#!/bin/bash
# Print the spec's "いまの考え" block on every prompt. Claude Code's UserPromptSubmit hook adds plain stdout (exit 0)
# to Claude's context (https://code.claude.com/docs/en/hooks). The block lives in the spec, so it is changed there only.
cat >/dev/null
root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
sed -n '/<!-- いまの考え：ここから/,/<!-- いまの考え：ここまで/p' "$root/docs/notes/GROUP_FOCUS_new.md"
