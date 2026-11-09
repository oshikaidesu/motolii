#!/usr/bin/env python3
# The measurable rules of AGENTS.md 「構成の目標」, checked on what is staged (the index), not on the disk.
# A rule nobody checks is ignored: every one here was written after a session left that mess behind.
#   layout_check.py              the index as it is: the pre-commit hook after size_check.py, or by hand
#   layout_check.py --all [BASE] the commit checked out (HEAD); rule 5 on the files added since BASE when given:
#                                CI (.github/workflows/checks.yml) on a pull request's tree
import re, subprocess, sys
from collections import Counter

AREAS = ('shelves', 'app', 'engine', 'docs')
ROOT_FILES = re.compile(r'^(README\.md|README\.en\.md|AGENTS\.md|LICENSE-[^/]+|THIRD_PARTY_NOTICES\.md|Brewfile|\..+)$')
NOT_IN_TABLE = {'app/macos'}                 # Flutter's own platform folder (`flutter create`), not ours to describe
NOT_COUNTED = ('shelves/', 'engine/third_party/')   # shelf contents and others' code (rule 6 counts own files only)
NUMBERED = re.compile(r'_\d+\.[^/.]+$')
SIZE_CHECK_EXT = re.compile(r'\.(dart|h|cpp|mm|js)$')  # size_check.py already refuses numbered names of these
LIMIT = 40


def git(*a):
    return subprocess.run(['git', *a], capture_output=True).stdout.decode('utf-8', 'replace')


def paths(*a):
    return [p for p in git(*a, '-z').split('\0') if p]


if sys.argv[1:2] == ['--all']:
    base = sys.argv[2] if len(sys.argv) > 2 else ''
    if base and not git('rev-parse', '-q', '--verify', base + '^{commit}').strip():
        print(f'layout check: base {base} is not in this clone; rule 5 skipped', file=sys.stderr)
        base = ''
    tree = 'HEAD'
    files = paths('ls-tree', '-r', '--name-only', 'HEAD')
    added = paths('diff', '--name-only', '--diff-filter=A', base, 'HEAD') if base else []
else:
    tree = ''
    files = paths('ls-files', '--cached')
    added = paths('diff', '--cached', '--name-only', '--diff-filter=A')
bad = []

# rule 1: the root holds the 4 entrances and the fixed documents, nothing else
for top in sorted({p.split('/')[0] + ('/' if '/' in p else '') for p in files}):
    name = top.rstrip('/')
    if top.endswith('/') and (name in AREAS or name.startswith('.')):
        continue
    if not top.endswith('/') and ROOT_FILES.match(name):
        continue
    bad.append(f'rule 1: {top}: the root holds only {", ".join(a + "/" for a in AREAS)} and the fixed documents;'
               f' move it under the entrance it belongs to')

# rule 2: each entrance README names every folder in it (app/: also every folder in lib/)
def named(readme, folder):
    return re.search(r'(?<![\w.-])' + re.escape(folder) + '/', readme)

for area in AREAS:
    inside = [p for p in files if p.startswith(area + '/')]
    if not inside:
        continue
    readme_path = f'{area}/README.md'
    if readme_path not in files:
        bad.append(f'rule 2: {readme_path}: missing; write it with a table naming every folder in {area}/')
        continue
    readme = git('show', f'{tree}:{readme_path}')
    folders = sorted({p.split('/')[1] for p in inside if p.count('/') >= 2})
    wanted = [(f'{area}/{f}', f) for f in folders]
    if area == 'app':
        lib = sorted({p.split('/')[2] for p in inside if p.startswith('app/lib/') and p.count('/') >= 3})
        wanted += [(f'app/lib/{f}', f'lib/{f}') for f in lib]
    for full, short in wanted:
        if full not in NOT_IN_TABLE and not named(readme, short):
            bad.append(f'rule 2: {full}/: not in {readme_path}; add a row `{short}/` saying in one line what is in it')

# rule 4: what builds and tests make stays in engine/out, app/build, docs/internal, and out of git
for p in files:
    seg = next((s for s in p.split('/')[:-1] if s in ('out', 'build')), None)
    if seg:
        bad.append(f'rule 4: {p}: {seg}/ holds output; git rm --cached it and let the build make it again')

# rule 5: a number is not a name (new files only; size_check.py covers .dart .h .cpp .mm .js)
for p in added:
    if p.startswith(NOT_COUNTED) or SIZE_CHECK_EXT.search(p):
        continue
    if NUMBERED.search(p):
        bad.append(f'rule 5: {p}: a number is not a name; name the file after what is in it')

# rule 6: at most 40 own files directly in one folder
per_folder = Counter(p.rsplit('/', 1)[0] for p in files if '/' in p and not p.startswith(NOT_COUNTED))
for folder, n in sorted(per_folder.items()):
    if n > LIMIT:
        bad.append(f'rule 6: {folder}/: {n} own files (at most {LIMIT}); split them into folders by job')

if bad:
    print('layout check refused this commit (AGENTS.md 構成の目標):\n  ' + '\n  '.join(bad), file=sys.stderr)
    sys.exit(1)
