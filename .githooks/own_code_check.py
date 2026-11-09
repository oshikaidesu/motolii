#!/usr/bin/env python3
# Code of our own is the dear way; code that is already somewhere is the free one. And nothing a person uses goes
# away unsaid. Two rules on a commit, both read from its message (git-interpret-trailers(1) form, `Key: value`):
#
# 1. LINES OF OUR OWN. A commit that leaves a file of ours (app/lib Dart, engine C++ and materials) longer than it
#    found it must say where it looked first and why each place fell short. Counted file by file: lines deleted from
#    one file do not pay for lines added to another, so nothing is bought by deleting something else. A commit that
#    hands the work to what exists and lengthens no file of ours is asked nothing.
#      Own-lines: +N                  N as this check measured it
#      Looked-in-repo: PATH           a file of others' code here (shelves/ or engine/community/), in the tree; when
#                                     .githooks/what_exists.py finds files like the added lines, one of those
#      Repo-falls-short: ...          why that file does not do it
#      Looked-in-library: NAME        a library already linked or depended on (engine/deps/*.sh, engine/third_party/,
#                                     app/pubspec.yaml, Brewfile)
#      Library-falls-short: ...       why it does not do it
#      Looked-on-web: https://...     an implementation outside (a repository, a package, a paper's code)
#      Web-falls-short: ...           why it is not brought in
#      Fails-without: ...             the command that fails without these lines, and what it prints
#    The three reasons must differ from each other.
#    (The trade of a ratchet's `bump`, which wants its reason in the commit message: github.com/imbue-ai/ratchets.)
#
# 2. WHAT A PERSON USES. A commit that takes away a name the tables declare (a card, a value, a command, a C call, a
#    window command, a menu item), or deletes a file of ours or a behaviour on the shelves, must name each one:
#      Removes: NAME, NAME, ...       every name or path taken away (several lines may share them)
#      Now-done-by: PATH | NAME | nothing: WHY     where a person gets it now (a file here, a linked library), or why not
#    (On 2026-11-10 a ledger of lines was met by deleting the stage, the timeline and the shelves' panels.)
#
# 3. THE LEAD'S WORD, for a worker. A session working in a worktree under .claude/worktrees/ may not leave a file of
#    ours longer than it found it unless the lead has granted that file to that worktree. Asking is a round trip in
#    which nothing of the worker's moves, and the lead refuses what could have been handed over; the free way asks no
#    one. The door (.claude/hooks/own_code_sign.py) holds the same line before the first edit; here it holds for
#    lines written any other way (a shell, a script).
#      own_code_check.py --grant WORKTREE PATH WHY...   the lead grants PATH (a file, or a folder ending in /) to WORKTREE
#      own_code_check.py --grants                       what is granted
#    Grants are kept in the repository's own git folder (git rev-parse --git-common-dir), which every worktree shares
#    and no commit carries.
#
#   own_code_check.py MESSAGE_FILE   the commit-msg hook (.githooks/commit-msg): what is staged, the message being written
#   own_code_check.py --range A..B   CI (.github/workflows/checks.yml): every commit made since this rule came in
# A merge is not asked: the commits it brings were.
import os, re, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
try:
    from what_exists import nearest
except Exception:   # (a branch cut before what_exists.py: no search, the rest holds)
    nearest = None

OWN = re.compile(r'^(app/lib/.+\.dart|engine/(?!third_party/|out/).+\.(h|cpp|mm|mat|glsl))$')
OTHERS_HERE = ('shelves/', 'engine/community/')
KEYS = ['Own-lines', 'Looked-in-repo', 'Repo-falls-short', 'Looked-in-library', 'Library-falls-short',
        'Looked-on-web', 'Web-falls-short', 'Fails-without']
TRAILER = re.compile(r'^(' + '|'.join(KEYS + ['Removes', 'Now-done-by']) + r'):[ \t]*(.*\S)[ \t]*$', re.M)
# Where a name a person uses is declared, and how it is written there.
DECLARED = [('a card', 'engine/document/card_table.h', r'\{"([^"]+)",\s*"[^"]*"'),
            ('a value', 'engine/document/kinds.h', r'\{"([a-z_0-9]+)",\s*"'),
            ('a command', 'engine/entry/calls_later.h', r'\bc == "([a-z_]+)"'),
            ('a call', 'engine/entry/motolii.h', r'\b(motolii_[a-z_0-9]+)\s*\('),
            ('a window command', 'app/lib/workspace/commands/keymap.dart', r"'([a-z]+\.[A-Za-z]+)'"),
            ('a menu item', 'app/lib/workspace/commands/menu_bar.dart', r"item\('([^']+)'")]
SELF = '.githooks/own_code_check.py'
LONGER = []   # (the files of ours the commit last measured leaves longer: own_lines)


def git(*a, data=None):
    return subprocess.run(['git', *a], input=data, capture_output=True).stdout.decode('utf-8', 'replace')


def worker():
    """The name of the worktree this is, when it is a worker's (.claude/worktrees/NAME); '' in the lead's checkout."""
    top = git('rev-parse', '--show-toplevel').strip()
    return top.rsplit('/.claude/worktrees/', 1)[1].split('/')[0] if '/.claude/worktrees/' in top else ''


def grants_file():
    common = git('rev-parse', '--path-format=absolute', '--git-common-dir').strip()
    return os.path.join(common, 'motolii-own-grants')


def granted(name, path):
    """Has the lead granted `path` to the worktree `name`?"""
    try:
        rows = [l.rstrip('\n').split('\t') for l in open(grants_file(), encoding='utf-8')]
    except OSError:
        return False
    return any(len(r) >= 2 and r[0] == name and (path == r[1] or (r[1].endswith('/') and path.startswith(r[1]))) for r in rows)


def generated(rev, path):
    """A file a tool writes (ffigen's bindings say AUTO GENERATED FILE at their head) is not ours to count."""
    return 'AUTO GENERATED FILE' in git('show', f'{rev}:{path}')[:400]


def own_lines(numstat, rev):
    """Lines of our own the commit adds: for each file of ours, added minus deleted where that is more than nothing.
    From `--numstat -M`; `rev`: where to read a file's head ('' the index)."""
    total, longer = 0, []
    for line in numstat.splitlines():
        parts = line.split('\t')
        if len(parts) < 3 or parts[0] == '-':
            continue
        path = re.sub(r'\{[^{}]* => ([^{}]*)\}', r'\1', parts[2]).replace('//', '/').split(' => ')[-1]
        if OWN.match(path) and not generated(rev, path) and int(parts[0]) > int(parts[1]):
            total += int(parts[0]) - int(parts[1])
            longer.append(path)
    LONGER[:] = longer
    return total


def taken_away(before, after, deleted):
    """[(what, name)] a person had at `before` and has not at `after` ('' the index); `deleted`: the files deleted."""
    gone = []
    for what, path, how in DECLARED:
        was = set(re.findall(how, git('show', f'{before}:{path}')))
        now = set(re.findall(how, git('show', f'{after}:{path}')))
        gone += [(what, n) for n in sorted(was - now)]
    for path in deleted:
        if OWN.match(path):
            gone.append(('a file of ours', path))
        elif path.startswith('shelves/'):
            gone.append(('a file on the shelves', path))
    return gone


def libraries(rev):
    """The names of what is already linked, bundled or depended on, read from the tree itself."""
    names = {'flutter'}
    for p in git('ls-tree', '-r', '--name-only', rev or 'HEAD', 'engine/deps/', 'engine/third_party/').split('\n'):
        if p.startswith('engine/deps/') and p.endswith('.sh'):
            names.add(os.path.basename(p)[:-3])
        elif p.startswith('engine/third_party/') and p.count('/') > 2:
            names.add(p.split('/')[2])
    in_deps = False
    for line in git('show', f'{rev}:app/pubspec.yaml').splitlines():
        if re.match(r'^\S', line):
            in_deps = line.startswith('dependencies:')
        elif in_deps and (m := re.match(r'^  ([a-z_0-9]+):', line)):
            names.add(m.group(1))
    names.update(re.findall(r'^brew "([^"]+)"', git('show', f'{rev}:Brewfile'), re.M))
    return {n.lower() for n in names}


def in_tree(rev, path):
    return bool(git('ls-tree', rev or 'HEAD', path).strip()) or (not rev and bool(git('ls-files', '--cached', path).strip()))


def judge(message, net, gone, like, rev):
    """What is wrong with `message` for a commit that adds `net` own lines and takes `gone` away; [] when nothing is.
    `like`: the files what_exists found like the added lines."""
    said = {}
    for key, value in TRAILER.findall(message):
        said.setdefault(key, []).append(value)
    wrong = []
    known = libraries(rev)
    if net > 0:
        wrong += [f'{k}: is missing' for k in KEYS if k not in said]
        if said.get('Own-lines') and said['Own-lines'][0].lstrip('+') != str(net):
            wrong.append(f"Own-lines: says {said['Own-lines'][0]}, the commit adds +{net}")
        looked = said.get('Looked-in-repo', [])
        for path in looked:
            if not path.startswith(OTHERS_HERE):
                wrong.append(f'Looked-in-repo: {path} is not under {" or ".join(OTHERS_HERE)}')
            elif not in_tree(rev, path):
                wrong.append(f'Looked-in-repo: {path} is not in the tree')
        if looked and like and not set(looked) & {p for p, _, _ in like}:
            wrong.append('Looked-in-repo: names none of the files found like these lines; look at one of them:\n      '
                         + '\n      '.join(f'{p}   — {shown}' for p, shown, _ in like))
        for name in said.get('Looked-in-library', []):
            if name.split()[0].lower() not in known:
                wrong.append(f'Looked-in-library: {name.split()[0]} is not linked or depended on ({", ".join(sorted(known))})')
        for url in said.get('Looked-on-web', []):
            if not re.match(r'^https://[^\s/]+\.[^\s/]+/\S+$', url):
                wrong.append(f'Looked-on-web: {url} is not an https address of one implementation')
        reasons = [said[k][0].lower() for k in ('Repo-falls-short', 'Library-falls-short', 'Web-falls-short') if k in said]
        if len(set(reasons)) < len(reasons):
            wrong.append('the three falls-short reasons are the same sentence; each place fell short in its own way')
    if gone:
        named = ' , '.join(said.get('Removes', []))
        unsaid = [f'{what}: {name}' for what, name in gone if not re.search(r'(?<![\w./-])' + re.escape(name) + r'(?![\w./-])', named)]
        if unsaid:
            wrong.append(f'Removes: does not name {len(unsaid)} of the {len(gone)} things this commit takes away:\n      ' + '\n      '.join(unsaid[:40])
                         + (f'\n      … and {len(unsaid) - 40} more' if len(unsaid) > 40 else ''))
        if 'Now-done-by' not in said:
            wrong.append('Now-done-by: is missing (a file here, a linked library, or `nothing: why`)')
        for where in said.get('Now-done-by', []):
            if where.lower().startswith('nothing:') and len(where) > len('nothing:') + 1:
                continue
            if not (where.startswith(OTHERS_HERE) and in_tree(rev, where)) and where.split()[0].lower() not in known:
                wrong.append(f'Now-done-by: {where} is neither a file in the tree under {" or ".join(OTHERS_HERE)}, a linked library, nor `nothing: why`')
    return wrong


def refuse(where, net, gone, wrong, fix):
    out = ['own code check refused (rule: lines of our own are paid for, and nothing goes away unsaid; .githooks/README.md):']
    if net > 0:
        out.append(f'  {where} adds +{net} lines of our own (app/lib Dart, engine C++ and materials; file by file, added minus deleted).')
    if gone:
        out.append(f'  {where} takes {len(gone)} thing(s) away from what a person uses.')
    out += ['  ' + w for w in wrong]
    if net > 0:
        out += ['The free way: hand the work to what exists (shelves/, engine/community/, a linked library) and lengthen no file of ours;'
                ' then nothing is asked. Search it: python3 .githooks/what_exists.py WORD...',
                'The dear way: add these to the message, each true:'] + [f'    {k}: {"+" + str(net) if k == "Own-lines" else ""}' for k in KEYS]
    if gone:
        out += ['To take something away, name it and say where a person gets it now:', '    Removes: ', '    Now-done-by: ']
    print('\n'.join(out + [fix]), file=sys.stderr)


def added_text(diff):
    return '\n'.join(l[1:] for l in diff.splitlines() if l.startswith('+') and not l.startswith('+++'))


def like_these(diff):
    if nearest is None:
        return []
    try:
        return nearest(git('rev-parse', '--show-toplevel').strip(), added_text(diff), limit=8)[0]
    except Exception:
        return []


if sys.argv[1:2] == ['--grants']:
    try:
        sys.stdout.write(open(grants_file(), encoding='utf-8').read())
    except OSError:
        pass
    sys.exit(0)

if sys.argv[1:2] == ['--grant']:
    import time
    if worker():
        sys.exit('own code check: a grant is the lead\'s to give, from the main checkout; a worker asks for it in its report')
    if len(sys.argv) < 5:
        sys.exit('own code check: --grant WORKTREE PATH WHY...   (PATH a file of ours, or a folder ending in /)')
    name, path, why = sys.argv[2], sys.argv[3], ' '.join(sys.argv[4:])
    if not os.path.isdir(os.path.join(git('rev-parse', '--show-toplevel').strip(), '.claude/worktrees', name)):
        sys.exit(f'own code check: no worktree .claude/worktrees/{name}')
    if not (OWN.match(path) or (path.endswith('/') and path.startswith(('app/lib/', 'engine/')))):
        sys.exit(f'own code check: {path} is not a file of ours (app/lib Dart, engine C++ and materials) or a folder of them ending in /')
    with open(grants_file(), 'a', encoding='utf-8') as f:
        f.write('\t'.join([name, path, time.strftime('%Y-%m-%d %H:%M'), why.replace('\t', ' ').replace('\n', ' ')]) + '\n')
    print(f'granted to {name}: {path}   ({why})')
    sys.exit(0)

if sys.argv[1:2] == ['--range']:
    failed = False
    for h in git('log', '--no-merges', '--format=%H', sys.argv[2]).split():
        if not git('ls-tree', h, SELF).strip():   # (made before this rule: history is not rewritten)
            continue
        net = own_lines(git('show', '--numstat', '-M', '--format=', h), h)
        deleted = [l.split('\t', 1)[1] for l in git('show', '--name-status', '-M', '--diff-filter=D', '--format=', h).splitlines() if '\t' in l]
        gone = taken_away(f'{h}^', h, deleted)
        if net <= 0 and not gone:
            continue
        like = like_these(git('show', '-U0', '--format=', h, '--', 'app/lib', 'engine')) if net > 0 else []
        if wrong := judge(git('log', '-1', '--format=%B', h), net, gone, like, h):
            refuse(h[:9], net, gone, wrong, 'Reword it (git rebase -i, `reword`) and push again.')
            failed = True
    sys.exit(1 if failed else 0)

if os.path.exists(os.path.join(git('rev-parse', '--git-dir').strip(), 'MERGE_HEAD')):
    sys.exit(0)
with open(sys.argv[1], encoding='utf-8', errors='replace') as f:
    message = '\n'.join(l for l in f.read().split('# ------------------------ >8')[0].split('\n') if not l.startswith('#'))
net = own_lines(git('diff', '--cached', '--numstat', '-M'), '')
deleted = [l.split('\t', 1)[1] for l in git('diff', '--cached', '--name-status', '-M', '--diff-filter=D').splitlines() if '\t' in l]
gone = taken_away('HEAD', '', deleted)
ungranted = [p for p in LONGER if not granted(worker(), p)] if worker() else []
if ungranted:
    print('own code check refused (rule: a worker lengthens a file of ours only on the lead\'s word; .githooks/README.md):\n  '
          + '\n  '.join(f'{p}: longer than it was, and not granted to {worker()}' for p in ungranted) +
          '\nThe free way: hand the work to what exists and leave these files no longer; no one is asked. Search it:'
          ' python3 .githooks/what_exists.py WORD...\nThe dear way starts with a round trip in which nothing of yours moves:'
          ' ask the lead in your report (the file, what the lines do, the files what_exists finds and why none of them does it).'
          ' The lead grants it or tells you which file to hand the work to.', file=sys.stderr)
    sys.exit(1)
if net > 0 or gone:
    like = like_these(git('diff', '--cached', '-U0', '--', 'app/lib', 'engine')) if net > 0 else []
    if wrong := judge(message, net, gone, like, ''):
        refuse('this commit', net, gone, wrong, f'Your message is kept: git commit -e -F {sys.argv[1]}')
        sys.exit(1)
