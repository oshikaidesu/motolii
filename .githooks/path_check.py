#!/usr/bin/env python3
# Rule P: every path a shelf file or one of our .md names must lead somewhere, so a move can never quietly break it.
# The shelf files (shelves/, but aviutl_scripts/: those packages find theirs by AviUtl's own package.path) and the
# scripts that write them (engine/community/three_tsl/*_shelf.ts). Each path is resolved as its reader resolves it,
# against what is staged (or a commit's tree), never the disk:
#   import / export from / import() / require   from the file's folder (QuickJS's way; a .ts also as esbuild: .ts, .js,
#                                               /index.ts); a bare name: the package.json beside a .ts, or the allowlist
#   // --image@name:file, ISF "PATH": "file"    beside the effect (screen_fx.h)
#   {motolii}/...  in a look (.motolii)         from shelves/ (document/presets.h doc_look_roots)
#   './' '../' in quotes                        a .sh: from where its `cd "$(dirname "$0")..."` went; a .ts: its folder
#   shelves/... engine/... app/... docs/...     from the repository's root (a head saying where it was made from)
# And every .md of our own (not in an aviutl_scripts/ nor engine/third_party/: their authors'): [text](path),
# [name]: path and <img src="path">, from the .md's folder as GitHub resolves them ('/' from the root); a web address,
# mailto: or #anchor alone is skipped, and so is what sits in `code`.
# What is fetched or made at build time is in path_check_allow.txt, each with why.
#   pre-commit: the staged shelf files; all of them when a staged change deletes or renames anything.
#   --all [--rev REV]: every shelf file (of REV's tree), for CI and for trying it on a commit from the past.
import fnmatch, json, os, posixpath, re, sqlite3, subprocess, sys, tempfile, urllib.parse

HOOKS = os.path.dirname(os.path.abspath(__file__))
args = sys.argv[1:]
everything = '--all' in args
rev = args[args.index('--rev') + 1] if '--rev' in args else None


def git(*a, data=None):
    return subprocess.run(['git', *a], input=data, capture_output=True).stdout


def names(*a):
    return [p for p in git(*a, '-z').decode('utf-8', 'replace').split('\0') if p]


tree = names('ls-tree', '-r', '--name-only', rev) if rev else names('ls-files', '--cached')
files = set(tree)
folders = {posixpath.dirname(p) for p in tree}
for f in list(folders):
    while f:
        f = posixpath.dirname(f)
        folders.add(f)


def wanted(p):
    if p.endswith('.md'):   # (not the authors' own documents, whose links go into their repos)
        return '/aviutl_scripts/' not in '/' + p and not p.startswith('engine/third_party/')
    if p.startswith('shelves/'):
        return not p.startswith('shelves/aviutl_scripts/') and p.endswith(
            ('.js', '.mjs', '.wgsl', '.fs', '.am', '.way', '.motolii', '.sh', '.py'))
    return fnmatch.fnmatch(p, 'engine/community/three_tsl/*_shelf.ts')


if everything or rev:
    look = [p for p in tree if wanted(p)]
else:
    staged = names('diff', '--cached', '--name-only', '--diff-filter=ACMR')
    moved = names('diff', '--cached', '--name-only', '--diff-filter=DR')
    look = [p for p in (tree if moved else staged) if wanted(p)]

allow = []
for line in open(os.path.join(HOOKS, 'path_check_allow.txt'), encoding='utf-8'):
    pattern = line.split('#', 1)[0].strip()
    if pattern:
        allow.append(pattern)


def blobs(paths):   # (git cat-file --batch: one process for all)
    spec = ''.join(f'{rev or ""}:{p}\n' for p in paths).encode()
    out, at = git('cat-file', '--batch', data=spec), 0
    for p in paths:
        head_end = out.index(b'\n', at)
        size = int(out[at:head_end].split()[2])
        yield p, out[head_end + 1:head_end + 1 + size]
        at = head_end + 2 + size


def there(path, folder_too=False):
    path = posixpath.normpath(path)
    return path in files or (folder_too and path in folders)


def allowed(written, resolved):
    return any(fnmatch.fnmatch(written, a) or fnmatch.fnmatch(resolved, a) for a in allow)


packages = {}


def package_names(folder):   # (the dependencies of the package.json nearest above a .ts)
    while folder not in packages:
        pj = posixpath.join(folder, 'package.json')
        if pj in files:
            text = git('show', f'{rev or ""}:{pj}').decode('utf-8', 'replace')
            d = json.loads(text or '{}')
            packages[folder] = set(d.get('dependencies', {})) | set(d.get('devDependencies', {}))
        elif folder:
            packages[folder] = package_names(posixpath.dirname(folder))
        else:
            packages[folder] = set()
    return packages[folder]


IMPORT = re.compile(r'''(?:\bimport\b[^'"`;]*?\bfrom|\bexport\b[^'"`;]*?\bfrom|\bimport\s*\(?|\brequire\s*\()\s*(['"])([^'"\n]+)\1''')
IMAGE = re.compile(r'--image@[^:\s]+:([^\s]+)')
ISF_PATH = re.compile(r'"PATH"\s*:\s*"([^"]+)"')
RELATIVE = re.compile(r'''(['"])(\.\.?/[^'"\s$`{]*)\1''')
CD = re.compile(r'''^\s*cd\s+"\$\(dirname\s+"\$0"\)(/[^"]*)?"''')
REPO = re.compile(r'(?<![\w/.$~@-])((?:shelves|engine|app|docs)/[A-Za-z0-9_./@+-]*[A-Za-z0-9_])')
FX_ENDS = ('.wgsl', '.fs', '.js', '.mjs', '.json', '.am')
bad = []


def fx_words(value):   # (a word of many files, as script.h script_files splits it: a space inside a file's name is kept)
    all = []
    for w in value.split():
        last = all[-1] if all else ''
        if '/' in last and not ('.anm2' in last or '.obj2' in last or last.endswith(FX_ENDS)):
            all[-1] += ' ' + w
        else:
            all.append(w)
    return all


def refuse(where, line, target, why='not found'):
    bad.append(f'rule P: {where}:{line} → {target}: {why}')


LINK = re.compile(r'\]\(\s*(<[^>]+>|[^)\s]+)|^\s{0,3}\[[^\]]+\]:\s*(\S+)|<img\b[^>]*?\bsrc\s*=\s*["\']([^"\']+)', re.I | re.M)
WEB = re.compile(r'^[a-z][a-z0-9+.-]*:', re.I)   # (http:, https:, mailto:, data: ...)


def check_links(path, folder, text):
    fenced = False
    for n, line in enumerate(text.split('\n'), 1):
        if line.lstrip().startswith(('```', '~~~')):
            fenced = not fenced
        if fenced:
            continue
        for found in LINK.findall(re.sub(r'`[^`]*`', '', line)):
            written = next(w for w in found if w).strip('<>')
            target = urllib.parse.unquote(written.split('#', 1)[0].split('?', 1)[0])
            if not target or WEB.match(written):
                continue
            resolved = posixpath.normpath(target.lstrip('/') if target.startswith('/') else posixpath.join(folder, target))
            if not there(resolved, folder_too=True) and not allowed(written, resolved):
                refuse(path, n, resolved)


def check_relative(where, line, base, written, ts=False):
    resolved = posixpath.normpath(posixpath.join(base, written))
    tries = [resolved] + ([resolved + e for e in ('.ts', '.js', '/index.ts', '/index.js')] if ts else [])
    if any(there(t, folder_too=ts) for t in tries) or allowed(written, resolved):
        return
    refuse(where, line, resolved)


for path, blob in blobs(look):
    folder = posixpath.dirname(path)
    if path.endswith('.motolii'):   # (a look: SQLite; its words that name a file of the library's shelves)
        with tempfile.NamedTemporaryFile(suffix='.motolii') as t:
            t.write(blob)
            t.flush()
            try:
                db = sqlite3.connect(f'file:{t.name}?mode=ro', uri=True)
                rows = db.execute("select thing, name, value from fact where typeof(value) = 'text' and value like '%{motolii}/%'").fetchall()
                db.close()
            except sqlite3.Error as e:
                refuse(path, 'fact', '(the look)', f'not read: {e}')
                rows = []
        for thing, name, value in rows:
            for one in fx_words(value):
                if not one.startswith('{motolii}/'):
                    continue
                resolved = posixpath.normpath('shelves/' + one[len('{motolii}/'):])
                if not there(resolved) and not allowed(one, resolved):
                    refuse(path, f'thing {thing} {name}', resolved)
        continue
    text = blob.decode('utf-8', 'replace')
    if path.endswith('.md'):
        check_links(path, folder, text)
        continue
    ts, sh = path.endswith('.ts'), path.endswith('.sh')
    base = folder
    for n, line in enumerate(text.split('\n'), 1):
        if sh and (m := CD.match(line)):
            base = posixpath.normpath(folder + (m.group(1) or ''))
        if path.endswith(('.js', '.mjs', '.ts')):
            for _, written in IMPORT.findall(line):
                if written.startswith(('./', '../', '/')):
                    check_relative(path, n, folder, written, ts)
                elif ts:
                    top = '/'.join(written.split('/')[:2 if written.startswith('@') else 1])
                    if top not in package_names(folder) and not allowed(written, written):
                        refuse(path, n, written, 'not in package.json')
                elif not allowed(written, written):
                    refuse(path, n, written, 'not a file, nor given (path_check_allow.txt)')
        for written in IMAGE.findall(line) + (ISF_PATH.findall(line) if path.endswith('.fs') else []):
            check_relative(path, n, folder, written)
        if sh or ts:
            for _, written in RELATIVE.findall(line):
                if not IMPORT.search(line):
                    check_relative(path, n, base, written, ts=True)
        for written in REPO.findall(line):
            if not there(written, folder_too=True) and not allowed(written, written):
                refuse(path, n, written)

for b in bad:
    print(b)
if bad:
    print(f'path check refused this commit (rule: every path a shelf file or our .md names leads somewhere; .githooks/README.md):'
          f' {len(bad)} path(s) above lead nowhere. Fix each where it is named, or follow the file that moved;'
          f' only what is fetched or made at build time goes in .githooks/path_check_allow.txt, with why.', file=sys.stderr)
    sys.exit(1)
