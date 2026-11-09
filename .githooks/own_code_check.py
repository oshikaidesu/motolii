#!/usr/bin/env python3
# Code of our own is the dear way; code that is already somewhere is the free one.
# A commit that leaves more lines of our own than it found (app/lib Dart, engine C++ and materials: added minus
# deleted, over the whole commit) has to say, in its message, where it looked first and why each place fell short.
# A commit that hands the work to what exists and deletes as much as it adds says nothing: it is not asked.
# (The same trade as a ratchet's `bump`, which wants its reason in the commit message: github.com/imbue-ai/ratchets.)
#   own_code_check.py MESSAGE_FILE   the commit-msg hook (.githooks/commit-msg): what is staged, the message being written
#   own_code_check.py --range A..B   CI (.github/workflows/checks.yml): every commit made since this rule came in
# What the message must hold (git-interpret-trailers(1) form, `Key: value`, one a line), each checked:
#   Own-lines: +N                  N is the count this check measured: the lines of our own the commit adds, net
#   Looked-in-repo: PATH           a file of others' code already here (shelves/ or engine/community/); it must exist
#   Repo-falls-short: ...          why that file does not do it
#   Looked-in-library: NAME        a library already linked or depended on (engine/deps/*.sh, app/pubspec.yaml, Brewfile)
#   Library-falls-short: ...       why it does not do it
#   Looked-on-web: https://...     an implementation outside (a repository, a package, a paper's code)
#   Web-falls-short: ...           why it is not brought in
#   Fails-without: ...             the command that fails without these lines, and what it prints
# The three reasons must differ from each other. A merge is not asked: the commits it brings were.
import os, re, subprocess, sys

OWN = re.compile(r'^(app/lib/.+\.dart|engine/(?!third_party/|out/).+\.(h|cpp|mm|mat|glsl))$')
OTHERS_HERE = ('shelves/', 'engine/community/')
KEYS = ['Own-lines', 'Looked-in-repo', 'Repo-falls-short', 'Looked-in-library', 'Library-falls-short',
        'Looked-on-web', 'Web-falls-short', 'Fails-without']
TRAILER = re.compile(r'^(' + '|'.join(KEYS) + r'):[ \t]*(.*\S)[ \t]*$', re.M)
SELF = '.githooks/own_code_check.py'


def git(*a, data=None):
    return subprocess.run(['git', *a], input=data, capture_output=True).stdout.decode('utf-8', 'replace')


def generated(rev, path):
    """A file a tool writes (ffigen's bindings say AUTO GENERATED FILE at their head) is not ours to count."""
    return 'AUTO GENERATED FILE' in git('show', f'{rev}:{path}')[:400]


def net_own(numstat, rev):
    """Lines of our own added minus deleted, from `--numstat -M` output; `rev`: where to read a file's head ('' the index)."""
    total = 0
    for line in numstat.splitlines():
        parts = line.split('\t')
        if len(parts) < 3 or parts[0] == '-':
            continue
        path = re.sub(r'\{[^{}]* => ([^{}]*)\}', r'\1', parts[2]).replace('//', '/')   # (a rename's new name)
        path = path.split(' => ')[-1]
        if OWN.match(path) and not generated(rev, path):
            total += int(parts[0]) - int(parts[1])
    return total


def libraries(rev):
    """The names of what is already linked or depended on, read from the tree itself."""
    names = {'flutter'}
    for p in git('ls-tree', '-r', '--name-only', rev or 'HEAD', 'engine/deps/').split():
        if p.endswith('.sh'):
            names.add(os.path.basename(p)[:-3])
    in_deps = False
    for line in git('show', f'{rev}:app/pubspec.yaml').splitlines():
        if re.match(r'^\S', line):
            in_deps = line.startswith('dependencies:')
        elif in_deps and (m := re.match(r'^  ([a-z_0-9]+):', line)):
            names.add(m.group(1))
    names.update(re.findall(r'^brew "([^"]+)"', git('show', f'{rev}:Brewfile'), re.M))
    return {n.lower() for n in names}


def judge(message, net, rev):
    """What is wrong with `message` for a commit that adds `net` own lines; [] when nothing is."""
    said = {}
    for key, value in TRAILER.findall(message):
        said.setdefault(key, []).append(value)
    wrong = [f'{k}: is missing' for k in KEYS if k not in said]
    if said.get('Own-lines') and said['Own-lines'][0].lstrip('+') != str(net):
        wrong.append(f"Own-lines: says {said['Own-lines'][0]}, the commit adds +{net}")
    for path in said.get('Looked-in-repo', []):
        if not path.startswith(OTHERS_HERE):
            wrong.append(f'Looked-in-repo: {path} is not under {" or ".join(OTHERS_HERE)}')
        elif not git('ls-tree', rev or 'HEAD', path).strip() and not (not rev and git('ls-files', '--cached', path).strip()):
            wrong.append(f'Looked-in-repo: {path} is not in the tree')
    known = libraries(rev)
    for name in said.get('Looked-in-library', []):
        if name.split()[0].lower() not in known:
            wrong.append(f'Looked-in-library: {name.split()[0]} is not linked or depended on ({", ".join(sorted(known))})')
    for url in said.get('Looked-on-web', []):
        if not re.match(r'^https://[^\s/]+\.[^\s/]+/\S+$', url):
            wrong.append(f'Looked-on-web: {url} is not an https address of one implementation')
    reasons = [said[k][0].lower() for k in ('Repo-falls-short', 'Library-falls-short', 'Web-falls-short') if k in said]
    if len(set(reasons)) < len(reasons):
        wrong.append('the three falls-short reasons are the same sentence; each place fell short in its own way')
    return wrong


def refuse(where, net, wrong, fix):
    form = '\n'.join(f'    {k}: {"+" + str(net) if k == "Own-lines" else ""}' for k in KEYS)
    print(f'own code check refused (rule: lines of our own are paid for in the message; .githooks/README.md):\n'
          f'  {where} adds +{net} lines of our own (app/lib Dart, engine C++ and materials, added minus deleted).\n  '
          + '\n  '.join(wrong) +
          f'\nThe free way: hand the work to what exists (shelves/, engine/community/, a linked library) and delete'
          f' as many lines as you add; then nothing is asked.\nThe dear way: add these to the message, each true:\n{form}\n{fix}',
          file=sys.stderr)


if sys.argv[1:2] == ['--range']:
    failed = False
    for h in git('log', '--no-merges', '--format=%H', sys.argv[2]).split():
        if not git('ls-tree', h, SELF).strip():   # (made before this rule: history is not rewritten)
            continue
        net = net_own(git('show', '--numstat', '-M', '--format=', h), h)
        if net > 0 and (wrong := judge(git('log', '-1', '--format=%B', h), net, h)):
            refuse(h[:9], net, wrong, 'Reword it (git rebase -i, `reword`) and push again.')
            failed = True
    sys.exit(1 if failed else 0)

top = git('rev-parse', '--show-toplevel').strip()
if os.path.exists(os.path.join(git('rev-parse', '--git-dir').strip(), 'MERGE_HEAD')):
    sys.exit(0)
with open(sys.argv[1], encoding='utf-8', errors='replace') as f:
    message = '\n'.join(l for l in f.read().split('# ------------------------ >8')[0].split('\n') if not l.startswith('#'))
net = net_own(git('diff', '--cached', '--numstat', '-M'), '')
if net > 0 and (wrong := judge(message, net, '')):
    refuse('this commit', net, wrong, f'Your message is kept: git commit -e -F {sys.argv[1]}')
    sys.exit(1)
