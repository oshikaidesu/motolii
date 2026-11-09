#!/usr/bin/env python3
# A file of our own over 500 lines holds more than one job: split it by what each part is for (the owner's rule,
# "500行を超えたら責任を分離させる"). Files already over on 2026-11-09 are in .githooks/over_500.txt with the count they
# had; they may shrink, never grow, and that ledger may only be lowered. A new file named `name_2.dart` (a number
# for a name) is refused: it cuts by line count, not by job. Run by the pre-commit hook; or by hand.
import re, subprocess, sys

OWN = re.compile(r'^(engine/(?!third_party/)[^/]+/[^/]+\.(h|cpp|mm)|engine/(?!third_party/).+\.js|shelves/(?!aviutl_scripts/).+\.js|app/lib/.+\.dart)$')
NUMBERED = re.compile(r'_\d+\.(dart|h|cpp|mm|js)$')
LIMIT = 500
LEDGER = '.githooks/over_500.txt'


def git(*a):
    return subprocess.run(['git', *a], capture_output=True, text=True).stdout


def ledger(text):
    out = {}
    for line in text.splitlines():
        if line.strip() and not line.startswith('#'):
            n, path = line.split(' ', 1)
            out[path] = int(n)
    return out


before = ledger(git('show', f'HEAD:{LEDGER}'))
for line in git('diff', '--cached', '-M', '--name-status', '--diff-filter=R').splitlines():   # (a file moved keeps its allowance)
    _, old, new = line.split('\t')
    if old in before:
        before[new] = before.pop(old)
now = ledger(git('show', f':{LEDGER}')) or before
bad = []
for path, n in now.items():
    if path not in before and before:
        bad.append(f'{LEDGER}: {path} was added; the ledger only shrinks')
    elif before and n > before[path]:
        bad.append(f'{LEDGER}: {path} raised {before[path]} -> {n}; the ledger only shrinks')

for status_path in git('diff', '--cached', '--name-status', '--diff-filter=ACMR').splitlines():
    parts = status_path.split('\t')
    status, path = parts[0], parts[-1]
    if not OWN.match(path):
        continue
    text = git('show', f':{path}')
    if 'AUTO GENERATED FILE' in text[:200]:
        continue
    lines = text.count('\n')
    allowed = now.get(path, LIMIT)
    if lines > allowed:
        bad.append(f'{path}: {lines} lines (allowed {allowed}). Split it by job, not by count.')
    if status.startswith('A') and NUMBERED.search(path):
        bad.append(f'{path}: a number is not a name. Name the new file after the one job it does.')

if bad:
    print('size check refused this commit:\n  ' + '\n  '.join(bad), file=sys.stderr)
    sys.exit(1)
