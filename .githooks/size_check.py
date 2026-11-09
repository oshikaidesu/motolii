#!/usr/bin/env python3
# A file of our own over 500 lines holds more than one job: split it by what each part is for (the owner's rule,
# "500行を超えたら責任を分離させる"). Files already over on 2026-11-09 are in .githooks/over_500.txt with the count they
# had; they may shrink, never grow, and that ledger may only be lowered. A new file named `name_2.dart` (a number
# for a name) is refused: it cuts by line count, not by job.
#   size_check.py              what is staged (the index) against HEAD: the pre-commit hook, or by hand
#   size_check.py --all [BASE] every own file of the commit checked out (HEAD); the ledger and new names against BASE
#                              when given: CI (.github/workflows/checks.yml) on a pull request's tree
import re, subprocess, sys

OWN = re.compile(r'^(engine/(?!third_party/)[^/]+/[^/]+\.(h|cpp|mm)|engine/(?!third_party/).+\.js|shelves/(?!aviutl_scripts/).+\.js|app/lib/.+\.dart)$')
NUMBERED = re.compile(r'_\d+\.(dart|h|cpp|mm|js)$')
LIMIT = 500
LEDGER = '.githooks/over_500.txt'


def git(*a):
    return subprocess.run(['git', *a], capture_output=True, text=True).stdout


def blobs(specs):
    """The contents of many `rev:path` at once (git cat-file --batch), bytes; b'' for one that is missing."""
    raw = subprocess.run(['git', 'cat-file', '--batch'], input=''.join(s + '\n' for s in specs).encode(),
                         capture_output=True).stdout
    out, i = [], 0
    for _ in specs:
        j = raw.index(b'\n', i)
        head = raw[i:j].split()
        if head[-1] == b'missing':
            out.append(b'')
            i = j + 1
        else:
            n = int(head[2])
            out.append(raw[j + 1:j + 1 + n])
            i = j + 1 + n + 1
    return out


def ledger(text):
    out = {}
    for line in text.splitlines():
        if line.strip() and not line.startswith('#'):
            n, path = line.split(' ', 1)
            out[path] = int(n)
    return out


if sys.argv[1:2] == ['--all']:
    base = sys.argv[2] if len(sys.argv) > 2 else ''
    if base and git('rev-parse', '-q', '--verify', base + '^{commit}').strip() == '':
        print(f'size check: base {base} is not in this clone; checking sizes only', file=sys.stderr)
        base = ''
    old, new, diff = base, 'HEAD', [base, 'HEAD']
    changed = []
    added = set(git('diff', '--name-only', '--diff-filter=A', *diff).splitlines()) if base else set()
    for path in git('ls-tree', '-r', '--name-only', 'HEAD').splitlines():
        changed.append(('A' if path in added else 'M', path))
else:
    old, new, diff = 'HEAD', '', ['--cached']
    changed = [(p[0], p[-1]) for p in (l.split('\t') for l in git('diff', '--cached', '--name-status', '--diff-filter=ACMR').splitlines())]

before = ledger(git('show', f'{old}:{LEDGER}')) if old else {}
if old:
    for line in git('diff', *diff, '-M', '--name-status', '--diff-filter=R').splitlines():   # (a file moved keeps its allowance)
        _, was, now_at = line.split('\t')
        if was in before:
            before[now_at] = before.pop(was)
now = ledger(git('show', f'{new}:{LEDGER}')) or before
bad = []
for path, n in now.items():
    if path not in before and before:
        bad.append(f'{LEDGER}: {path} was added; the ledger only shrinks')
    elif before and n > before[path]:
        bad.append(f'{LEDGER}: {path} raised {before[path]} -> {n}; the ledger only shrinks')

own = [(status, path) for status, path in changed if OWN.match(path)]
for (status, path), text in zip(own, blobs([f'{new}:{path}' for _, path in own])):
    if b'AUTO GENERATED FILE' in text[:200]:
        continue
    lines = text.count(b'\n')
    allowed = now.get(path, LIMIT)
    if lines > allowed:
        bad.append(f'{path}: {lines} lines (allowed {allowed}). Split it by job, not by count.')
    if status.startswith('A') and NUMBERED.search(path):
        bad.append(f'{path}: a number is not a name. Name the new file after the one job it does.')

if bad:
    print('size check refused this commit:\n  ' + '\n  '.join(bad), file=sys.stderr)
    sys.exit(1)
