#!/bin/sh
# Stop / StopFailure hook (.claude/settings.json). A session working in a worktree under .claude/worktrees/ (a worker)
# may not stop with work left uncommitted: the stop is refused once with the reason, so it commits first (AGENTS.md
# 後始末: a session once left 244 changes uncommitted on main and vanished). Whenever a worker does stop, the person
# is told by a macOS notification, so no stop goes unseen. The main checkout (the lead) is left alone.
# Source: code.claude.com/docs/en/hooks (Stop: {"decision":"block","reason":…}, stop_hook_active), osascript(1).
input=$(cat)
dir=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$dir" ] || dir=$PWD
top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
case "$top" in */.claude/worktrees/*) ;; *) exit 0 ;; esac
name=${top##*/}
event=$(printf '%s' "$input" | jq -r '.hook_event_name // "Stop"')
again=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')
left=$(git -C "$top" status --porcelain | wc -l | tr -d ' ')
ahead=$(git -C "$top" rev-list --count main..HEAD 2>/dev/null || echo '?')
tell() { osascript -e "display notification \"$2\" with title \"Motolii: $1\" sound name \"Glass\"" >/dev/null 2>&1; }
if [ "$event" = "Stop" ] && [ "$left" -gt 0 ] && [ "$again" != "true" ]; then
    printf '{"decision":"block","reason":"%s files are uncommitted in %s. Commit them on your branch (hooks must pass), then report. A worker never stops with uncommitted work (AGENTS.md 後始末)."}\n' "$left" "$name"
    exit 0
fi
if [ "$event" = "StopFailure" ]; then tell "$name failed" "The worker stopped on an error. $left uncommitted, $ahead commits on its branch."
elif [ "$left" -gt 0 ]; then tell "$name stopped dirty" "Stopped with $left files still uncommitted, $ahead commits on its branch."
else tell "$name stopped" "$ahead commits on its branch, nothing uncommitted."
fi
exit 0
