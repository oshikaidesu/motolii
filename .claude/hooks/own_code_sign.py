#!/usr/bin/env python3
# PreToolUse hook on Edit|Write and on Bash (.claude/settings.json): the door to code of our own (app/lib Dart,
# engine C++ and materials).
#   The lead (the main checkout): the first such edit of a session is refused once, and the reason is the sign at the
#     door: what already exists that is like the lines being written, what the free way costs (nothing) and what the
#     dear way costs. The same edit sent again goes through.
#   A worker (a worktree under .claude/worktrees/): an edit that would leave a file of ours longer than it is at HEAD
#     is refused every time, until the lead has granted that file to that worktree
#     (python3 .githooks/own_code_check.py --grant WORKTREE PATH WHY, from the main checkout). So the dear way begins
#     with a round trip in which nothing of the worker's moves, and the free way (hand the work over, lengthen nothing)
#     asks no one. A worker may not write the grant itself: an edit or a command that touches it is refused.
# Why at the door and not at the commit: by the commit the lines are written and get defended. An agent told which
# interfaces already exist reused them 67.8% of the time against 30.0% untold, and given the whole source 29.2%
# (arXiv 2609.35357, as agentpatterns.ai/patterns/anti-patterns/cross-session-reimplementation reports it).
# What is like the lines is asked of .githooks/what_exists.py (the shelves and adapters, ranked by SQLite's bm25);
# what a press is handed to is read from the naked_ui package the app resolves (app/.dart_tool/package_config.json).
# Source: code.claude.com/docs/en/hooks (PreToolUse: hookSpecificOutput.permissionDecision "deny" and its reason,
# which is given to the model; stdin session_id, tool_name, tool_input.file_path / new_string / content / command).
# Never in the way by accident: any error here exits 0 and the call goes ahead.
import json, os, re, subprocess, sys, tempfile, time

DART = re.compile(r'^app/lib/.+\.dart$')
ENGINE = re.compile(r'^engine/(?!third_party/|out/).+\.(h|cpp|mm|mat|glsl)$')
GRANTS = 'motolii-own-grants'


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


def granted(top, name, rel):
    common = git(top, 'rev-parse', '--path-format=absolute', '--git-common-dir').strip()
    try:
        rows = [l.rstrip('\n').split('\t') for l in open(os.path.join(common, GRANTS), encoding='utf-8')]
    except OSError:
        return False
    return any(len(r) >= 2 and r[0] == name and (rel == r[1] or (r[1].endswith('/') and rel.startswith(r[1]))) for r in rows)


def naked(top):
    """The widgets naked_ui has, by the names of its own files (naked_button.dart is NakedButton)."""
    try:
        packages = json.load(open(os.path.join(top, 'app/.dart_tool/package_config.json')))['packages']
        root = next(p['rootUri'] for p in packages if p['name'] == 'naked_ui').replace('file://', '')
        files = sorted(f[:-5] for f in os.listdir(os.path.join(root, 'lib/src')) if f.startswith('naked_') and f.endswith('.dart'))
        return [''.join(w.capitalize() for w in f.split('_')) for f in files if f != 'naked_widgets']
    except Exception:
        return []


def sign(top, rel, area, text, first, name):
    """The sign at the door, as lines. `first`: its opening, for the lead or for a worker; `name`: the worker's worktree, '' the lead."""
    out = [first, '',
           'THE FREE WAY: what already exists is run, not re-made. Nothing is asked, of anyone, when the work is handed over and no file of ours gets longer.']
    like, count = [], 0
    try:
        sys.path.insert(0, os.path.join(top, '.githooks'))
        from what_exists import nearest
        like, count = nearest(top, text, area, skip=rel)
    except Exception:
        pass
    if like:
        where = 'files that run on the shelves and in the adapters' if area == 'engine' else 'classes of Flutter and the packages depended on, and calls and cards of the engine'
        out.append(f'  Already here and like the lines you are writing (of {count} {where}):')
        out += [f'    {i}   — {shown}' for i, shown, _ in like]
    else:
        out.append('  Nothing that exists is named like the words of this edit. Ask in your own words before writing:')
    out.append('    python3 .githooks/what_exists.py WORD...')
    if area == 'engine':
        third = os.path.join(top, 'engine/third_party')
        linked = sorted({os.path.basename(p)[:-3] for p in git(top, 'ls-files', 'engine/deps').split() if p.endswith('.sh')}
                        | {d for d in (os.listdir(third) if os.path.isdir(third) else []) if os.path.isdir(os.path.join(third, d))})
        out += ['  A new behaviour is one file dropped on a shelf (shelves/relations, expressions, effects, create, ease): no C++, no build.',
                f'  Linked or bundled already: {", ".join(linked)}.']
    else:
        have = naked(top)
        out += [f'  A press, a hover and what floats over the window are naked_ui\'s, already a dependency: {", ".join(have) if have else "its Naked* widgets"}.',
                '  A card in the inspector is one row in engine/document/card_table.h; ValuesCard draws it with no Dart at all.',
                '  What a person sees of the document (the preview, a layer, a key) is the engine\'s to draw and to tell; Dart places it.']
    lines = sum(1 for _ in open(os.path.join(top, rel), errors='replace')) if os.path.exists(os.path.join(top, rel)) else 0
    out += ['', 'THE DEAR WAY: lines of our own. What they cost:']
    if name:
        out += [f'  first, the lead\'s word, and it is a round trip: you ask in your report (the file, what the lines do, the files above and why none of them does it), you stop, and nothing of yours moves until the lead answers. The lead refuses what could have been handed over. Only the lead grants (python3 .githooks/own_code_check.py --grant {name} {rel} WHY, from the main checkout); a grant you write yourself is refused here and at the commit;']
    out += ['  a commit that leaves a file of ours longer needs eight trailers in its message, each verified (.githooks/own_code_check.py): the count, one of the files found like these lines, a linked library, an https implementation, why each fell short, and the command that fails without the lines;',
            '  lines deleted from another file do not pay for them, and a card, value, command, call, menu item or file taken away must be named with where a person gets it now;']
    if area == 'engine':
        out.append(f'  the file must be as clang-format leaves it and stay at 500 lines or fewer ({rel}: {lines} now), and a layer kind may not be compared by name (.githooks/shape_check.sh);')
    else:
        out.append('  GestureDetector, Listener, MouseRegion, OverlayPortal and CustomPainter may not appear in more places than now (.githooks/shape_check.sh);')
    out.append('  and the reasons are read by a person or a judge, who is given the same list.')
    return out


def main():
    said = json.load(sys.stdin)
    asked = said.get('tool_input') or {}
    if said.get('tool_name') == 'Bash':   # (a worker does not write its own grant)
        command = str(asked.get('command', ''))
        if (GRANTS in command or re.search(r'own_code_check\.py\s+--grant\b', command)) and worker_of(top_of(said.get('cwd') or os.getcwd())):
            deny('A grant is the lead\'s to give, from the main checkout. A worker asks for it in its report and goes on with what does not hang on the answer, or hands the work to what exists and needs none.')
        return
    path = asked.get('file_path') or ''
    if not path:
        return
    if GRANTS in path and worker_of(top_of(said.get('cwd') or os.getcwd())):   # (before anything else: the file lies in .git, in no worktree)
        return deny('A grant is the lead\'s to give, from the main checkout.')
    top = top_of(path)
    if not top:
        return
    name = worker_of(top)
    rel = os.path.relpath(os.path.abspath(path), top)
    area = 'dart' if DART.match(rel) and 'bindings' not in rel else 'engine' if ENGINE.match(rel) else ''
    if not area:
        return
    text = ' '.join(str(asked.get(k, '')) for k in ('new_string', 'content'))

    if name:   # (a worker: no file of ours longer than at HEAD without the lead's word)
        try:
            now = open(os.path.join(top, rel), encoding='utf-8', errors='replace').read()
        except OSError:
            now = ''
        if 'content' in asked:
            after = str(asked['content'])
        else:
            old, new = str(asked.get('old_string', '')), str(asked.get('new_string', ''))
            after = now.replace(old, new) if asked.get('replace_all') else now.replace(old, new, 1)
        was = git(top, 'show', f'HEAD:{rel}').count('\n')
        if after.count('\n') <= was or granted(top, name, rel):
            return
        return deny('\n'.join(sign(top, rel, area, text,
                                   f'Refused: this edit leaves {rel} longer than it is at HEAD ({was} lines, {after.count(chr(10))} after), and the lead has not granted that file to this worktree ({name}). Two ways from here.',
                                   name)))

    # the lead: once a session for each area; the first to make the folder is the first edit
    room = tempfile.gettempdir()
    for old in os.listdir(room):
        if old.startswith('motolii-own-') and time.time() - os.path.getmtime(os.path.join(room, old)) > 86400:
            try: os.rmdir(os.path.join(room, old))
            except OSError: pass
    key = re.sub(r'[^A-Za-z0-9_-]', '', f"{said.get('session_id', 'x')}-{said.get('agent_id', '')}-{area}")
    try:
        os.mkdir(os.path.join(room, 'motolii-own-' + key))
    except FileExistsError:
        return
    deny('\n'.join(sign(top, rel, area, text,
                        f'Before the first line of our own in {rel} this session. Two ways from here; read once, then send the edit again if it is still the right one.',
                        '')))


try:
    main()
except Exception:   # (a sign that cannot be read is no reason to stop the work)
    pass
