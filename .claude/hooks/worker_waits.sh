#!/bin/sh
# Notification hook (.claude/settings.json): when any session of this project waits for the person (a permission
# prompt, a question, idle), a macOS notification names the worktree, so a worker held at a prompt is never left
# waiting unseen (a shelf worker sat at a permission prompt on 2026-11-09 and nobody knew).
# Source: code.claude.com/docs/en/hooks (Notification: notification_type, message), osascript(1).
input=$(cat)
# Also in the user's own settings for older sessions: one notification per session and wait (see worker_stop.sh).
once="${TMPDIR:-/tmp}/motolii-hook-$(printf '%s' "$input" | jq -r '(.session_id // "x") + "-wait-" + (.notification_type // "")')"
find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'motolii-hook-*' -mmin +1 -exec rmdir {} + 2>/dev/null
mkdir "$once" 2>/dev/null || exit 0
dir=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$dir" ] || dir=$PWD
top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || top=$dir
name=${top##*/}
kind=$(printf '%s' "$input" | jq -r '.notification_type // "waiting"')
msg=$(printf '%s' "$input" | jq -r '.message // ""' | tr '"\\' "'/" | cut -c1-120)
osascript -e "display notification \"$msg\" with title \"Motolii: $name waits ($kind)\" sound name \"Ping\"" >/dev/null 2>&1
exit 0
