#!/usr/bin/env python3
# PreToolUse and PostToolUse hook on Bash (.claude/settings.json): what loads the machine goes through the lead.
# The machine has ten cores; with many agents at work, one build each takes it down (it did: the builds).
#   A build (engine/build.sh, edit.sh, drawings_unchanged.sh, a deps script, flutter build or run, live.sh, xcodebuild,
#     cmake --build, ninja): refused to every subagent and to every worker in a worktree. Only the lead's own call (the
#     main agent in the main checkout) runs one, so a build is the lead's to decide and there is one at a time.
#   Checks (dart analyze, flutter test, engine/check_syntax.sh) are not held here: they run at once, and flutter's own
#     lock (bin/cache/lockfile) makes two flutter commands wait for each other where they must.
#   Looking at the app goes one way, the fast one: app/tool/live.sh, run in the background (it stays while the window is
#     open; about 3 s from closed, a saved .dart reloads in a moment, engine/build.sh lib restarts it in place). flutter
#     run, a debug flutter build macos and opening a built Motolii.app are refused with that said; so is live.sh in the
#     foreground, which would hold the call until the window closes.
# Source: code.claude.com/docs/en/hooks (PreToolUse deny and its reason; agent_id is present only when
# the hook fires in a subagent; tool_input.command, cwd).
# Never in the way by accident: any error here exits 0 and the command goes ahead.
import json, os, re, subprocess, sys

BUILD = re.compile(r'(^|[\s;&|(/])(build\.sh|edit\.sh|drawings_unchanged\.sh|filament_webgpu\.sh|live\.sh)\b|engine/deps/\w+\.sh'
                   r'|\bflutter\s+(build|run)\b|\bxcodebuild\b|\bcmake\s+--build\b|(^|[\s;&|(])ninja\b')


def deny(reason):
    print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'deny',
                                             'permissionDecisionReason': reason}}))


LIVE = ('Look at the app with app/tool/live.sh, run in the background (run_in_background): about 3 s from closed, '
        'and it stays open. A .dart saved under app/lib reloads in the open window in a moment, state kept; '
        'engine/build.sh lib restarts it in place in about a second; a Swift change of macos/Runner needs it opened again '
        '(close the window, run live.sh again). When it prints "live.sh: open", look (a screenshot of the Motolii window). '
        'Running it again while the window is open only says so. ')
RUN = r'(?:^|[;&|(]|\b(?:then|do|else)\b)\s*(?:\w+=\S*\s+)*(?:(?:ba|z)?sh\s+)?'   # (where a command starts, not inside cat or grep)
SLOW = re.compile(RUN + r'(?:flutter\s+run\b|flutter\s+build\s+macos\b(?![^;&|]*--(?:profile|release))|open\s[^;&|]*Motolii\.app)')
LIVE_SH = re.compile(RUN + r'\S*live\.sh\b')


def main():
    said = json.load(sys.stdin)
    command = str((said.get('tool_input') or {}).get('command', ''))
    if not said.get('agent_id') and 'MOTOLII_BUILD_DRY=' not in command:
        if SLOW.search(command):
            return deny('This is the slow way to see the app (16-27 s, each time). ' + LIVE)
        if LIVE_SH.search(command) and not (said.get('tool_input') or {}).get('run_in_background'):
            return deny('live.sh runs until the window is closed, so in the foreground it holds this call and is cut off with the app. ' + LIVE)
    if BUILD.search(command) and 'MOTOLII_BUILD_DRY=' not in command:
        top = subprocess.run(['git', '-C', said.get('cwd') or os.getcwd(), 'rev-parse', '--show-toplevel'], capture_output=True, text=True).stdout
        if said.get('agent_id') or '/.claude/worktrees/' in top:
            return deny('A build is the lead\'s to run, one at a time: it loads every core, and with many agents at work it takes the machine down. '
                        'Do not build and do not wait for one. What is not a build: engine/check_syntax.sh, (cd app && dart analyze lib), '
                        '.githooks/shape_check.sh, python3 .githooks/*.py. If your task cannot be judged without a build, say in your report '
                        'what the build was to show; the lead decides.')
        return

try:
    main()
except Exception:
    pass
