#!/usr/bin/env python3
# PreToolUse hook on Edit|Write and on Bash (.claude/settings.json): the door to code of our own (app/lib Dart,
# engine C++ and materials). The goal it serves: the less there is of ours to maintain, the better.
#   An edit that leaves a file of ours no longer than it is at HEAD goes through, asked nothing: handing work to what
#   exists and deleting is the free way.
#   An edit that would leave it longer is refused until a sketch has been asked for that file: the lines about to be
#   added, written as one wishes they could be (they need not run), given to
#       python3 .githooks/what_exists.py --sketch dart|engine FILE < sketch
#   which answers, for every name the sketch calls, whether it exists, has something near, or is nothing here, and
#   keeps the answer (in the shared git folder, motolii-sketches/). A wished-for name says what is wanted, so it
#   finds what exists better than finished code does. Only what comes back as nothing is ours to write.
#   A worker (a worktree under .claude/worktrees/) needs, besides, the lead's grant of that file
#   (python3 .githooks/own_code_check.py --grant WORKTREE PATH WHY, from the main checkout).
#   Nobody writes a kept sketch or a grant by hand: an edit or a command that touches them is refused.
# Why at the door and not at the commit: by the commit the lines are written and get defended. An agent told which
# interfaces already exist reused them 67.8% of the time against 30.0% untold (arXiv 2609.35357, as
# agentpatterns.ai/patterns/anti-patterns/cross-session-reimplementation reports it).
# Source: code.claude.com/docs/en/hooks (PreToolUse: hookSpecificOutput.permissionDecision "deny" and its reason,
# which is given to the model; stdin tool_name, tool_input.file_path / new_string / content / command, cwd).
# Never in the way by accident: any error here exits 0 and the call goes ahead.
import json, os, re, subprocess, sys, time

DART = re.compile(r'^app/lib/.+\.dart$')
ENGINE = re.compile(r'^engine/(?!third_party/|out/).+\.(h|cpp|mm|mat|glsl)$')
GRANTS, SKETCHES = 'motolii-own-grants', 'motolii-sketches'


def git(top, *a):
    return subprocess.run(['git', '-C', top, *a], capture_output=True, text=True).stdout


def deny(reason):
    print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'deny',
                                             'permissionDecisionReason': reason}}))


def top_of(path):
    at = path if os.path.isdir(path) else os.path.dirname(os.path.abspath(path))
    while at != '/' and not os.path.isdir(at):
        at = os.path.dirname(at)
    return git(at, 'rev-parse', '--show-toplevel').strip()


def worker_of(top):
    return top.rsplit('/.claude/worktrees/', 1)[1].split('/')[0] if '/.claude/worktrees/' in top else ''


def common(top):
    return git(top, 'rev-parse', '--path-format=absolute', '--git-common-dir').strip()


def granted(top, name, rel):
    try:
        rows = [l.rstrip('\n').split('\t') for l in open(os.path.join(common(top), GRANTS), encoding='utf-8')]
    except OSError:
        return False
    return any(len(r) >= 2 and r[0] == name and (rel == r[1] or (r[1].endswith('/') and rel.startswith(r[1]))) for r in rows)


def sketched(top, rel):
    """Was a sketch asked for this file, within the last day?"""
    try:
        return time.time() - os.path.getmtime(os.path.join(common(top), SKETCHES, rel.replace('/', '__'))) < 86400
    except OSError:
        return False


def main():
    said = json.load(sys.stdin)
    asked = said.get('tool_input') or {}
    here = top_of(said.get('cwd') or os.getcwd())
    if said.get('tool_name') == 'Bash':
        command = str(asked.get('command', ''))
        if SKETCHES in command and 'what_exists.py' not in command:
            deny('A kept sketch is written by what_exists.py --sketch alone, when it has been asked.')
        elif (GRANTS in command or re.search(r'own_code_check\.py\s+--grant\b', command)) and worker_of(here):
            deny('A grant is the lead\'s to give, from the main checkout. A worker asks for it in its report, or hands the work to what exists and needs none.')
        return
    path = asked.get('file_path') or ''
    if not path:
        return
    if SKETCHES in path or (GRANTS in path and worker_of(here)):   # (before anything else: they lie in .git, in no worktree)
        return deny('This is kept by its own tool (what_exists.py --sketch; the lead\'s own_code_check.py --grant), not written by hand.')
    top = top_of(path)
    if not top:
        return
    rel = os.path.relpath(os.path.abspath(path), top)
    side = 'dart' if DART.match(rel) and 'bindings' not in rel else 'engine' if ENGINE.match(rel) else ''
    if not side:
        return
    try:
        now = open(os.path.join(top, rel), encoding='utf-8', errors='replace').read()
    except OSError:
        now = ''
    if 'content' in asked:
        after = str(asked['content'])
    else:
        old, new = str(asked.get('old_string', '')), str(asked.get('new_string', ''))
        after = now.replace(old, new) if asked.get('replace_all') else now.replace(old, new, 1)
    own = lambda text: sum(1 for l in text.split('\n') if not re.match(r'\s*(//|import |export |part )', l))   # (an import points at what exists; a comment is not code)
    was, will = own(git(top, 'show', f'HEAD:{rel}')), own(after)
    if will <= was:
        return   # (no longer than at HEAD: the free way)
    name = worker_of(top)
    if not sketched(top, rel):
        return deny(f'Refused: this edit leaves {rel} longer than it is at HEAD ({was} lines, {will} after), and no sketch has been asked for it.\n'
                    'Before a file of ours grows, write what you are about to add as you wish it could be written: call whatever names you would '
                    'like to exist; it need not run. Then ask what exists:\n'
                    f'    python3 .githooks/what_exists.py --sketch {side} {rel} < YOUR_SKETCH_FILE     (the sketch file goes in your scratch folder, not in the repository)\n'
                    'Read the answer. A name that exists, or that has something near, is used as it is: hand the work to it and write less. Only what '
                    'comes back as "nothing here does this" is ours to write. Then send this edit again; it goes through once the sketch has been asked.\n'
                    'An edit that leaves the file no longer than at HEAD needs none of this: handing work over and deleting is asked nothing.\n'
                    'What the added lines cost at the commit (eight trailers, each checked): .githooks/README.md, own_code_check.py.'
                    + (f'\nYou are a worker ({name}): besides the sketch, the lead must grant this file to your worktree; ask in your report, with the sketch\'s answer.' if name else ''))
    if name and not granted(top, name, rel):
        return deny(f'Refused: {rel} would grow and the lead has not granted it to this worktree ({name}). Ask in your report: the file, what the lines do, '
                    'and the sketch\'s answer (what came back as nothing). The lead grants it or names the thing to hand the work to. Nothing of yours '
                    'moves while you wait; the free way (lengthen nothing) asks no one.')


try:
    main()
except Exception:   # (a door that cannot be read is no reason to stop the work)
    pass
