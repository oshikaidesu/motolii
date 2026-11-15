#!/usr/bin/env python3
# Rule I: only the places named in import_rules.txt reach past the window: the engine (package:motolii/bridge/), the
# disk and processes (dart:io), native memory (dart:ffi, package:ffi/). A panel reads the window's state and is told
# by aspect when it changes; it never asks the engine or the disk while it builds. As Chromium's DEPS and Bazel's
# visibility: allowed by a list, everything else refused, the list beside the code so loosening it is a diff.
# An import from before the rule is kept with '!' and counted; one that is gone must leave the list too.
# And app/pubspec.yaml depends on nothing the list does not name.
#   pre-commit: what is staged.   --all: the tree as it is on disk, for CI.
import os, re, subprocess, sys

HOOKS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HOOKS)
APP = 'app/'
everything = '--all' in sys.argv[1:]


def git(*a):
    return subprocess.run(['git', '-C', ROOT, *a], capture_output=True).stdout


reach, allow, kept, depends = [], [], set(), set()
for n, line in enumerate(open(os.path.join(HOOKS, 'import_rules.txt'), encoding='utf-8'), 1):
    words = line.split('#', 1)[0].split()
    if not words:
        continue
    match words:
        case ['reach', *prefixes] if prefixes:
            reach += prefixes
        case ['allow', where, *prefixes] if prefixes:
            allow.append((where, prefixes))
        case ['!', file, imported]:
            kept.add((file, imported))
        case ['depends', name]:
            depends.add(name)
        case _:
            sys.exit(f'import_rules.txt:{n}: not a rule: {line.strip()}')


staged = {}  # path: its staged text, read in one go
if not everything:
    blobs = [line.split(None, 3) for line in git('ls-files', '-s', f'{APP}lib', f'{APP}pubspec.yaml').decode().splitlines()]
    blobs = [(b[3], b[1]) for b in blobs if b[3].endswith(('.dart', '.yaml'))]
    out = subprocess.run(['git', '-C', ROOT, 'cat-file', '--batch'], input='\n'.join(h for _, h in blobs).encode(),
                         capture_output=True).stdout
    at = 0
    for path, _ in blobs:
        head_end = out.index(b'\n', at)
        size = int(out[at:head_end].split()[2])
        staged[path] = out[head_end + 1:head_end + 1 + size].decode('utf-8', 'replace')
        at = head_end + 1 + size + 1


def read(path):
    if everything:
        with open(os.path.join(ROOT, path), encoding='utf-8') as f:
            return f.read()
    return staged[path]


IMPORT = re.compile(r"^\s*(?:import|export)\s+'([^']+)'|^\s*if\s*\([^)]*\)\s*'([^']+)'", re.M)
if everything:
    files = [p for p in git('ls-files', '--cached', '-z', f'{APP}lib').decode().split('\0')
             if p.endswith('.dart') and os.path.exists(os.path.join(ROOT, p))]
else:
    files = [p for p in staged if p.endswith('.dart')]
wrong, seen = [], set()
for path in files:
    file = path[len(APP):]
    for a, b in IMPORT.findall(read(path)):
        imported = a or b
        if not any(imported.startswith(r) for r in reach):
            continue
        if any((file == w or file.startswith(w)) and any(imported.startswith(p) for p in ps) for w, ps in allow):
            continue
        seen.add((file, imported))
        if (file, imported) not in kept:
            wrong.append(f'! {file}  {imported}')

gone = sorted(kept - seen)
pubspec = read(f'{APP}pubspec.yaml')
listed = set()
for part in ('dependencies', 'dev_dependencies'):
    block = re.search(rf'^{part}:\n((?:[ \t].*\n|\n)*)', pubspec, re.M)
    listed |= set(re.findall(r'^  ([a-z_][a-z0-9_]*):', block.group(1), re.M)) if block else set()
strangers, unused = sorted(listed - depends), sorted(depends - listed)

if wrong:
    print('import_check: these reach past the window outside the places import_rules.txt allows.')
    print('Read the window\'s state instead (workspace/state, or a feed like workspace/inspector_feed).')
    print('Only the maker may add a line to import_rules.txt.\n' + '\n'.join(wrong))
if gone:
    print('import_check: these are no longer imported; take their lines out of import_rules.txt:')
    print('\n'.join(f'! {f}  {i}' for f, i in gone))
if strangers:
    print('import_check: app/pubspec.yaml depends on what import_rules.txt does not name: ' + ', '.join(strangers))
if unused:
    print('import_check: import_rules.txt names what app/pubspec.yaml no longer depends on: ' + ', '.join(unused))
if wrong or gone or strangers or unused:
    sys.exit(1)
if everything:
    print(f'import_check: {len(kept)} imports from before the rule remain (!)')
