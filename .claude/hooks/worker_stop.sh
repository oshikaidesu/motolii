#!/bin/sh
# Stop hook (.claude/settings.json): a session in a worktree under .claude/worktrees/ may not stop with work left
# uncommitted; the stop is refused once with the reason (AGENTS.md 後始末). The main checkout is left alone.
# Source: code.claude.com/docs/en/hooks (Stop: {"decision":"block","reason":…}, stop_hook_active).
input=$(cat)
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0
dir=$(printf '%s' "$input" | jq -r '.cwd // empty')
top=$(git -C "${dir:-$PWD}" rev-parse --show-toplevel 2>/dev/null) || exit 0
case "$top" in */.claude/worktrees/*) ;; *) exit 0 ;; esac
left=$(git -C "$top" status --porcelain | wc -l | tr -d ' ')
[ "$left" -gt 0 ] && printf '{"decision":"block","reason":"%s files are uncommitted in %s. Commit them on your branch, then report (AGENTS.md 後始末)."}\n' "$left" "${top##*/}"
exit 0
