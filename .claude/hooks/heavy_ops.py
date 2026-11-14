#!/usr/bin/env python3
# PreToolUse hook on Bash (.claude/settings.json): what loads the machine goes through the lead.
# The machine has ten cores; with many agents at work, one build each takes it down (it did: the builds).
#   A build (engine/build.sh, edit.sh, drawings_unchanged.sh, a deps script, flutter build or run, live.sh, xcodebuild,
#     cmake --build, ninja): refused to every subagent and to every worker in a worktree. Only the lead's own call (the
#     main agent in the main checkout) runs one, so a build is the lead's to decide and there is one at a time.
#   Checks (dart analyze, flutter test, engine/check_syntax.sh) are not held here: they run at once, and flutter's own
#     lock (bin/cache/lockfile) makes two flutter commands wait for each other where they must.
# Source: code.claude.com/docs/en/hooks (PreToolUse deny and its reason; agent_id is present only when
# the hook fires in a subagent; tool_input.command, cwd).
# Never in the way by accident: any error here exits 0 and the command goes ahead.
import json, os, re, subprocess, sys

BUILD = re.compile(r'(^|[\s;&|(/])(build\.sh|edit\.sh|drawings_unchanged\.sh|filament_webgpu\.sh|live\.sh)\b|engine/deps/\w+\.sh'
                   r'|\bflutter\s+(build|run)\b|\bxcodebuild\b|\bcmake\s+--build\b|(^|[\s;&|(])ninja\b')
FLUTTER_DIRECT = re.compile(r'\bflutter\s+(build|run)\b')


def deny(reason):
    print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'deny',
                                             'permissionDecisionReason': reason}}))


def main():
    said = json.load(sys.stdin)
    command = str((said.get('tool_input') or {}).get('command', ''))
    if BUILD.search(command) and 'MOTOLII_BUILD_DRY=' not in command:
        top = subprocess.run(['git', '-C', said.get('cwd') or os.getcwd(), 'rev-parse', '--show-toplevel'], capture_output=True, text=True).stdout
        if said.get('agent_id') or '/.claude/worktrees/' in top:
            return deny('A build is the lead\'s to run, one at a time: it loads every core, and with many agents at work it takes the machine down. '
                        'Do not build and do not wait for one. What is not a build: engine/check_syntax.sh, (cd app && dart analyze lib), '
                        '.githooks/shape_check.sh, python3 .githooks/*.py. If your task cannot be judged without a build, say in your report '
                        'what the build was to show; the lead decides.')
        if FLUTTER_DIRECT.search(command):
            return deny('flutter run / flutter build ではなく app/tool/live.sh を使う。'
                        'Dart だけの変更なら 3 秒でウィンドウが開く。'
                        'ネイティブ（macos/、pubspec）が変わった時だけ Xcode が動く。'
                        'ホットリロードは SIGUSR1、ホットリスタートは SIGUSR2 を build/live.pid の PID に送る。')
        return

try:
    main()
except Exception:
    pass
