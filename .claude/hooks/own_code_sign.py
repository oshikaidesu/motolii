#!/usr/bin/env python3
# PreToolUse hook on Edit|Write (.claude/settings.json). The first time in a session that code of our own is about to
# be written (app/lib Dart, engine C++ and materials), the edit is refused once and the reason is the sign at the door:
# what already exists that is like the lines being written, what the free way costs (nothing) and what the dear way
# costs (.githooks/own_code_check.py, shape_check.sh, dart_budget.py). The same edit sent again goes through.
# Why at the door and not at the commit: by the commit the lines are written and get defended. An agent told which
# interfaces already exist reused them 67.8% of the time against 30.0% untold, and given the whole source 29.2%
# (arXiv 2609.35357, as agentpatterns.ai/patterns/anti-patterns/cross-session-reimplementation reports it).
# What is like the lines is asked of .githooks/what_exists.py (the shelves and adapters, ranked by SQLite's bm25);
# what a press is handed to is read from the naked_ui package the app resolves (app/.dart_tool/package_config.json).
# Source: code.claude.com/docs/en/hooks (PreToolUse: hookSpecificOutput.permissionDecision "deny" and its reason,
# which is given to the model; stdin session_id, tool_input.file_path, new_string or content).
# Never in the way by accident: any error here exits 0 and the edit goes ahead.
import json, os, re, subprocess, sys, tempfile, time

DART = re.compile(r'^app/lib/.+\.dart$')
ENGINE = re.compile(r'^engine/(?!third_party/|out/).+\.(h|cpp|mm|mat|glsl)$')


def git(top, *a):
    return subprocess.run(['git', '-C', top, *a], capture_output=True, text=True).stdout


def naked(top):
    """The widgets naked_ui has, by the names of its own files (naked_button.dart is NakedButton)."""
    try:
        packages = json.load(open(os.path.join(top, 'app/.dart_tool/package_config.json')))['packages']
        root = next(p['rootUri'] for p in packages if p['name'] == 'naked_ui').replace('file://', '')
        files = sorted(f[:-5] for f in os.listdir(os.path.join(root, 'lib/src')) if f.startswith('naked_') and f.endswith('.dart'))
        return [''.join(w.capitalize() for w in f.split('_')) for f in files if f != 'naked_widgets']
    except Exception:
        return []


def main():
    said = json.load(sys.stdin)
    asked = said.get('tool_input') or {}
    path = asked.get('file_path') or ''
    if not path:
        return
    at = os.path.dirname(os.path.abspath(path))
    while at != '/' and not os.path.isdir(at):
        at = os.path.dirname(at)
    top = git(at, 'rev-parse', '--show-toplevel').strip()
    if not top:
        return
    rel = os.path.relpath(os.path.abspath(path), top)
    area = 'dart' if DART.match(rel) and 'bindings' not in rel else 'engine' if ENGINE.match(rel) else ''
    if not area:
        return
    # once a session (and a subagent of it) for each area: the first to make the folder is the first edit
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

    out = [f'Before the first line of our own in {rel} this session. Two ways from here; read once, then send the edit again if it is still the right one.',
           '',
           'THE FREE WAY: what already exists is run, not re-made. Nothing is asked of a commit that hands the work over and lengthens no file of ours.']
    if area == 'engine':
        like, count = [], 0
        try:
            sys.path.insert(0, os.path.join(top, '.githooks'))
            from what_exists import nearest
            like, count = nearest(top, ' '.join(str(asked.get(k, '')) for k in ('new_string', 'content')))
        except Exception:
            pass
        if like:
            out.append(f'  Already here and like the lines you are writing (of {count} files that run on the shelves and in the adapters):')
            out += [f'    {p}   — {shown}' for p, shown, _ in like]
        else:
            out.append('  Nothing on the shelves is named like the words of this edit. Ask in your own words before writing:')
        out.append('    python3 .githooks/what_exists.py WORD...')
        linked = sorted({os.path.basename(p)[:-3] for p in git(top, 'ls-files', 'engine/deps').split() if p.endswith('.sh')}
                        | {d for d in (os.listdir(os.path.join(top, 'engine/third_party')) if os.path.isdir(os.path.join(top, 'engine/third_party')) else [])
                           if os.path.isdir(os.path.join(top, 'engine/third_party', d))})
        out += ['  A new behaviour is one file dropped on a shelf (shelves/relations, expressions, effects, create, ease): no C++, no build.',
                f'  Linked or bundled already: {", ".join(linked)}.']
    else:
        have = naked(top)
        out += [f'  A press, a hover and what floats over the window are naked_ui\'s, already a dependency: {", ".join(have) if have else "its Naked* widgets"}.',
                '  A card in the inspector is one row in engine/document/card_table.h; ValuesCard draws it with no Dart at all.',
                '  What a person sees of the document (the preview, a layer, a key) is the engine\'s to draw and to tell; Dart places it.']
    lines = sum(1 for _ in open(os.path.join(top, rel), errors='replace')) if os.path.exists(os.path.join(top, rel)) else 0
    out += ['',
            'THE DEAR WAY: lines of our own. What they cost, each checked by a hook and by CI:',
            '  a commit that leaves a file of ours longer needs eight trailers in its message, each verified (.githooks/own_code_check.py): the count, one of the files found like these lines, a linked library, an https implementation, why each fell short, and the command that fails without the lines;',
            '  lines deleted from another file do not pay for them, and a card, value, command, call, menu item or file taken away must be named with where a person gets it now;']
    if area == 'engine':
        out.append(f'  the file must be as clang-format leaves it and stay at 500 lines or fewer ({rel}: {lines} now), and a layer kind may not be compared by name (.githooks/shape_check.sh);')
    else:
        ledger = next((l.split()[0] for l in open(os.path.join(top, '.githooks/dart_lines.txt')) if l.strip() and not l.startswith('#')), '?')
        out.append(f'  hand-written Dart may not grow at all ({ledger} lines, .githooks/dart_budget.py), and GestureDetector, Listener, MouseRegion, OverlayPortal and CustomPainter are refused (.githooks/shape_check.sh);')
    out.append('  and the reasons are read by a person or a judge, who is given the same list.')
    print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'deny',
                                             'permissionDecisionReason': '\n'.join(out)}}))


try:
    main()
except Exception:   # (a sign that cannot be read is no reason to stop the work)
    pass
