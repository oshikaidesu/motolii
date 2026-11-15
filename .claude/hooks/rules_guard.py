#!/usr/bin/env python3
# PreToolUse hook (.claude/settings.json): the rules that hold the code are the maker's to change, not Claude's.
# An edit by Claude Code to one of them, or a shell command that names one and is not a plain read, asks the maker
# first; a subagent or a worker in a worktree is refused. So breaking a rule cannot be done by rewriting the rule.
# Source: code.claude.com/docs/en/hooks (PreToolUse permissionDecision "ask" and "deny"; agent_id only in a subagent).
# Never in the way by accident: any error here exits 0.
import json, re, sys

HELD = ['app/tool/rules/import_engine.yml', 'app/tool/rules/import_disk.yml', 'app/tool/rules/engine_only_in_state.yml', 'app/tool/pubspec_allow.txt', 'app/tool/check_pubspec.py', '.githooks/pre-commit',
        '.github/workflows/checks.yml', '.claude/settings.json', '.claude/hooks/rules_guard.py']
READ = re.compile(r'\s*(cat|head|tail|grep|rg|wc|git\s+(diff|log|show|status|blame))\b[^>;&|`$]*')


def answer(said, held):
    worker = said.get('agent_id') or '/.claude/worktrees/' in (said.get('cwd') or '')
    print(json.dumps({'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'permissionDecision': 'deny' if worker else 'ask',
        'permissionDecisionReason': f'{held} は作り手が決める規則です。'
                                    + ('作業者は書き換えず、要る変更を報告に書く。' if worker else
                                       '書き換えてよいか作り手に確認します。規則を破る代わりに規則を変えない。')}}))


def main():
    said = json.load(sys.stdin)
    given = said.get('tool_input') or {}
    path = str(given.get('file_path') or given.get('notebook_path') or '')
    if path:
        for h in HELD:
            if path.endswith('/' + h) or path == h:
                return answer(said, h)
        return
    command = str(given.get('command') or '')
    for h in HELD:
        if h in command or h.rsplit('/', 1)[-1] in command:
            if not READ.fullmatch(command):
                return answer(said, h)
            return


try:
    main()
except Exception:
    pass
