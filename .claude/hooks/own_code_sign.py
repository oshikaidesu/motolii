#!/usr/bin/env python3
# PreToolUse hook on Edit|Write (.claude/settings.json). The first time in a session that code of our own is about to
# be written (app/lib Dart, engine C++ and materials), the edit is refused once and the reason is the sign at the door:
# what already exists under names like the ones being written, what the free way costs (nothing) and what the dear
# way costs (.githooks/own_code_check.py, shape_check.sh, dart_budget.py). The same edit sent again goes through.
# Why at the door and not at the commit: by the commit the lines are written and get defended. An agent told which
# interfaces already exist reused them 67.8% of the time against 30.0% untold, and given the whole source 29.2%
# (arXiv 2609.35357, as agentpatterns.ai/patterns/anti-patterns/cross-session-reimplementation reports it).
# Source: code.claude.com/docs/en/hooks (PreToolUse: hookSpecificOutput.permissionDecision "deny" and its reason,
# which is given to the model; stdin session_id, tool_input.file_path, new_string or content).
# Never in the way by accident: any error here exits 0 and the edit goes ahead.
import json, os, re, subprocess, sys, tempfile, time

DART = re.compile(r'^app/lib/.+\.dart$')
ENGINE = re.compile(r'^engine/(?!third_party/|out/).+\.(h|cpp|mm|mat|glsl)$')
# Files that are a behaviour to run (not its picture, its notes or its translations).
RUNS = {'js', 'wgsl', 'fs', 'vs', 'am', 'way', 'anm2', 'obj2', 'scn2', 'lua', 'motolii', 'h', 'cpp', 'ts'}
# Words of the languages themselves (C++ and Dart keywords and types): they say nothing of what is being made.
LANGUAGE = set('auto bool break case char class const continue default double dynamic else enum extends false final float '
               'import inline late long namespace null nullptr override part required return short show signed sizeof static '
               'string struct super switch template this throw true typedef typename uint unsigned using void while with '
               'async await widget build context state'.split())


def git(top, *a):
    return subprocess.run(['git', '-C', top, *a], capture_output=True, text=True).stdout


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

    # what is already here under a name like the words being written (file names only: a shelf file is named for what
    # it does), nearest first: how often the edit says the words of the file's name, then how much of that name it says
    text = ' '.join(str(asked.get(k, '')) for k in ('new_string', 'content'))
    said_words = [w.lower() for w in re.findall(r'[A-Za-z]{4,}', re.sub(r'([a-z])([A-Z])', r'\1 \2', text).replace('_', ' '))]
    often = {w: said_words.count(w) for w in set(said_words) - LANGUAGE}   # (what the edit says most is what it is about)
    words = set(often)
    others = [p for p in git(top, '-c', 'core.quotepath=off', 'ls-files', 'shelves', 'engine/community').splitlines()]
    shelf_count = sum(p.startswith('shelves/') for p in others)
    near = []
    for p in others:
        stem, kind = os.path.splitext(os.path.basename(p))
        if kind.lstrip('.') not in RUNS:
            continue
        name = set(re.findall(r'[a-z]{4,}', re.sub(r'([a-z])([A-Z])', r'\1 \2', stem).lower()))
        if hit := name & words:
            near.append((-sum(often[w] for w in hit), -len(hit) / len(name), p, sorted(hit)))
    near.sort()
    libs = sorted(os.path.basename(p)[:-3] for p in git(top, 'ls-files', 'engine/deps').split() if p.endswith('.sh'))
    lines = sum(1 for _ in open(os.path.join(top, rel), errors='replace')) if os.path.exists(os.path.join(top, rel)) else 0

    out = [f'Before the first line of our own in {rel} this session. Two ways from here; read once, then send the edit again if it is still the right one.',
           '',
           'THE FREE WAY: what already exists is run, not re-made. Nothing is asked of a commit that hands the work over and deletes as many lines as it adds.']
    if near:
        out.append(f'  Already here, named like what you are writing ({len(near)} files; the nearest):')
        for _, _, p, h in near[:12]:
            try: says = open(os.path.join(top, p), errors='replace').readline().strip().lstrip('/#-* ')[:110]
            except OSError: says = ''
            out.append(f'    {p}' + (f'   — {says}' if says else ''))
    else:
        out.append('  No file here is named like the words in this edit. Search by your own words before writing:')
    out.append(f'    git grep -il -e WORD -- shelves engine/community      ({shelf_count} shelf files, each one behaviour that runs as it is)')
    if area == 'engine':
        out += [f'  A new behaviour is one file dropped on a shelf (shelves/relations, expressions, effects, create, ease): no C++, no build.',
                f'  Linked already: {", ".join(libs)}; ThorVG, Skia, Filament, GStreamer, Jolt and QuickJS do paths, drawing, video, physics and scripts.']
    else:
        out += ['  A press, hover, slider, text field, menu or popover is naked_ui\'s (NakedButton, NakedToggle, NakedSlider, NakedTextField, NakedMenu, NakedPopover): already a dependency.',
                '  A card in the inspector is one row in engine/document/card_table.h; ValuesCard draws it with no Dart at all.']
    out += ['',
            'THE DEAR WAY: lines of our own. What they cost, each checked by a hook and by CI:',
            '  a commit that adds net own lines needs eight trailers in its message, each verified (.githooks/own_code_check.py): the count, a file here you looked at, a linked library, an https implementation, why each fell short, and the command that fails without the lines;']
    if area == 'engine':
        out.append(f'  the file must be as clang-format leaves it and stay at 500 lines or fewer ({rel}: {lines} now), and a layer kind may not be compared by name (.githooks/shape_check.sh);')
    else:
        ledger = next((l.split()[0] for l in open(os.path.join(top, '.githooks/dart_lines.txt')) if l.strip() and not l.startswith('#')), '?')
        out.append(f'  hand-written Dart may not grow at all ({ledger} lines, .githooks/dart_budget.py), and GestureDetector, Listener, MouseRegion, OverlayPortal and CustomPainter are refused (.githooks/shape_check.sh);')
    out.append('  and the reasons are read by a person or a judge, who is given the list above.')
    print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'deny',
                                             'permissionDecisionReason': '\n'.join(out)}}))


try:
    main()
except Exception:   # (a sign that cannot be read is no reason to stop the work)
    pass
