#!/usr/bin/env python3
# The hand-written window has one budget: the newline count of app/lib/**/*.dart. A file whose first lines contain
# ffigen's "AUTO GENERATED FILE" is not part of it (app/lib/bridge/motolii_bindings.dart). The number in
# dart_lines.txt is that count for the tree being committed: the number is kept true, neither above the count (spare
# lines would fill back up) nor below it. Whether it may rise is no longer decided here: a file of ours that gets
# longer pays in the commit message (.githooks/own_code_check.py), which a count of lines could not ask. (The rule
# "it may not rise" of 2026-11-10 01:09 was met by deleting the stage, the timeline and the shelves; the owner had
# them put back the same day.)
#   dart_budget.py              the index (pre-commit)
#   dart_budget.py --all [BASE] HEAD (CI, .github/workflows/checks.yml)
import subprocess, sys

LEDGER = '.githooks/dart_lines.txt'
MARK = b'AUTO GENERATED FILE'


def git(*a, data=None):
    return subprocess.run(['git', *a], input=data, capture_output=True).stdout


def paths(rev):
    raw = git('ls-tree', '-r', '--name-only', '-z', rev) if rev else git('ls-files', '--cached', '-z')
    return [p for p in raw.decode().split('\0') if p.startswith('app/lib/') and p.endswith('.dart')]


def blobs(rev, names):
    spec = [f'{rev}:{p}' if rev else f':{p}' for p in names]
    raw = git('cat-file', '--batch', data=''.join(s + '\n' for s in spec).encode())
    out, i = [], 0
    for _ in spec:
        j = raw.index(b'\n', i)
        head = raw[i:j].split()
        if head[-1] == b'missing':
            out.append(b'')
            i = j + 1
        else:
            n = int(head[-1])
            out.append(raw[j + 1:j + 1 + n])
            i = j + 1 + n + 1
    return out


def count(rev):
    names = paths(rev)
    return sum(b.count(b'\n') for b in blobs(rev, names) if MARK not in b[:200])


def ceiling(rev):
    """The number written in the ledger at `rev` ('' is the index); None if that tree has no ledger."""
    spec = f'{rev}:{LEDGER}' if rev else f':{LEDGER}'
    raw = subprocess.run(['git', 'cat-file', '-e', spec], capture_output=True)
    if raw.returncode != 0:
        return None
    text = git('cat-file', '-p', spec).decode()
    nums = [int(s) for line in text.splitlines() if (s := line.strip()) and not s.startswith('#')]
    if len(nums) != 1:
        return 'bad'
    return nums[0]


if sys.argv[1:2] == ['--all']:
    base = sys.argv[2] if len(sys.argv) > 2 else ''
    if base and git('rev-parse', '-q', '--verify', base + '^{commit}').strip() == b'':
        print(f'dart budget: base {base} is not in this clone; checking the count only', file=sys.stderr)
        base = ''
    rev, old_rev = 'HEAD', base
else:
    rev, old_rev = '', 'HEAD'

now, was = ceiling(rev), ceiling(old_rev) if old_rev else None
have = count(rev)
bad = []
if now is None:
    bad.append(f'{LEDGER} is missing; write {have}')
elif now == 'bad':
    bad.append(f'{LEDGER}: one number, the newline count')
else:
    if have > now:
        bad.append(f'{have} newlines in app/lib (a generated binding aside); {LEDGER} says {now}')
    elif have < now:
        bad.append(f'{LEDGER} says {now} but the tree has {have}; write {have}, spare lines would fill back up')

if bad:
    print('dart budget refused this commit (rule: the count of hand-written Dart is kept true, .githooks/README.md):\n  '
          + '\n  '.join(bad), file=sys.stderr)
    sys.exit(1)
