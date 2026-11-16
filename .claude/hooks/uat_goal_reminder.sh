#!/bin/bash
# UserPromptSubmit hook: every 20 user turns, remind of the UAT goal and the
# "work shape" lessons, so the session does not drift into tick-sized UI
# polish while an UAT bundle is open.
#
# The counter is stored at .claude/hooks/.turn_count. Reset it to 0 to force a
# reminder on the next turn, or delete it to start over.
set -e
d="$CLAUDE_PROJECT_DIR/.claude/hooks"
f="$d/.turn_count"
n=$(cat "$f" 2>/dev/null || echo 0)
n=$((n + 1))
echo "$n" > "$f"
if (( n % 20 == 0 )); then
  cat <<'EOF'
<uat-reminder>
20 ターンごとの UAT 目標リマインダー:
- 目標: docs/design/uat_scenarios.md と docs/design/uat_order.md の UAT を上の段から進める。必要なら UI/UX 改善も同じ流れで
- 「動く」の定義: analyze/build だけでなく、実際にアプリ (preview_start / computer-use / Simulator) で動かして見た
- 1 UAT まとまり = 1 本の仕事。途中の tick は沈黙でいい。tick を埋めるための微調整コミットは積まない
- /loop は進捗が止まった時に叩くためのもの。リズム作りではない
- 重い物でも将来に直結するなら手を伸ばす。迷ったら git で戻せることを思い出す
</uat-reminder>
EOF
fi
