#!/usr/bin/env python3
# What is already here that does this? Asked in words, on both sides of the app.
#   what_exists.py WORD...          by hand, both sides:  python3 .githooks/what_exists.py wave copies noise
#   what_exists.py --text SIDE      the words of a text on stdin (an edit, a diff): what it is most about. SIDE: engine | dart
#   nearest(top, text, side)        the same from Python (.claude/hooks/own_code_sign.py, .githooks/own_code_check.py)
# What is asked, read at its head each time (nothing is kept, so nothing goes stale):
#   engine side: every file that is a behaviour to run on the shelves and in the adapters (shelves/, engine/community/):
#                its name and what it says of itself (first comment, an ISF DESCRIPTION, a script's --about: and --track@)
#   dart side:   Flutter's own classes (widgets, gestures, painting, rendering, services, animation) and those of the
#                packages the app depends on, each by its name and its doc comment, found through the app's resolved
#                packages (app/.dart_tool/package_config.json); the engine's C calls with what each says
#                (engine/entry/motolii.h) and its cards with their values (engine/document/card_table.h); and the
#                app's own classes (app/lib), so a part we have is found before a second one is written
# The ranking is not ours: SQLite's FTS5 with its bm25() (sqlite.org/fts5.html, "The bm25() function"; Okapi BM25),
# words stemmed by its porter tokenizer, a thing's name weighing four times what it says.
# It answers a question; it does not find our copies by itself. Read over our own code 30 lines at a time it called
# 1,032 stretches in 191 of 196 files like something (2026-11-10): words alike are not the same behaviour. What is a
# copy is for a reader to say, with this as the reader's tool.
import json, os, re, sqlite3, subprocess, sys

# Files that are a behaviour to run (not its picture, its notes, its translations or a saved document).
RUNS = {'js', 'wgsl', 'fs', 'am', 'way', 'anm2', 'obj2', 'scn2', 'lua', 'h', 'cpp', 'ts'}
# Words of the languages themselves (C++ and Dart keywords and types): they say nothing of what is being made.
LANGUAGE = set('auto bool break case char class const continue default double dynamic else enum extends false final float '
               'import include inline late long namespace null nullptr override part required return short show signed '
               'sizeof static string struct super switch template this throw true typedef typename uint unsigned using '
               'void while with async await widget build context state std math size int64 uint32 list children child'.split())
MOST = 16   # (the words a text says most often are what it is about; the rest are how it is written)
CLASS = re.compile(r'((?:^[ \t]*///[^\n]*\n)+)(?:^[ \t]*@[^\n]*\n)*^(?:abstract |final |base |sealed |interface )*(?:mixin )?class ([A-Z]\w+)', re.M)


def split(text):
    """A text's words, lower case: fooBar and foo_bar are foo and bar; four letters or more."""
    return [w.lower() for w in re.findall(r'[A-Za-z]{4,}', re.sub(r'([a-z])([A-Z])', r'\1 \2', text).replace('_', ' '))]


def head(path):
    """What a file says of itself at its head, and the one line of that to show."""
    try:
        with open(path, 'rb') as f:
            raw = f.read(1500).decode('utf-8', 'replace')
    except OSError:
        return '', ''
    about = re.search(r'--about:(.*)', raw) or re.search(r'"DESCRIPTION"\s*:\s*"([^"]*)"', raw)
    first = next((l.strip().lstrip('/#-*{ ') for l in raw.split('\n') if l.strip().lstrip('/#-*{ ')), '')
    says = ' '.join(re.sub(r'--(track|check|select|label|absent)@?', ' ', l) for l in raw.split('\n')[:14])
    return says, (about.group(1).strip() if about else first)[:120]


def classes(root, where, folders=None):
    """(id, shown, name words, says, key) for each documented public class under root/lib."""
    rows = []
    base = os.path.join(root, 'lib')
    for at, _, files in os.walk(base):
        if folders and not any(os.path.relpath(at, base).startswith(os.path.join('src', f)) for f in folders):
            continue
        for f in files:
            if not f.endswith('.dart'):
                continue
            try:
                text = open(os.path.join(at, f), encoding='utf-8', errors='replace').read()
            except OSError:
                continue
            for doc, name in CLASS.findall(text):
                says = ' '.join(l.strip().lstrip('/ ') for l in doc.split('\n'))
                rows.append((f'{where}: {name}', says.split('. ')[0][:120], ' '.join(split(name)), says[:600], name))
    return rows


def index(top):
    """The FTS5 table of everything that exists, and how many on each side."""
    db = sqlite3.connect(':memory:')
    db.execute("create virtual table thing using fts5(side unindexed, id unindexed, shown unindexed, key unindexed, name, says, tokenize='porter unicode61')")
    rows = []
    for p in subprocess.run(['git', '-C', top, '-c', 'core.quotepath=off', 'ls-files', 'shelves', 'engine/community'],
                            capture_output=True, text=True).stdout.splitlines():
        stem, kind = os.path.splitext(os.path.basename(p))
        if kind.lstrip('.') in RUNS:
            says, shown = head(os.path.join(top, p))
            rows.append(('engine', p, shown, stem, ' '.join(split(stem)), says))
    try:
        packages = {p['name']: p['rootUri'] for p in json.load(open(os.path.join(top, 'app/.dart_tool/package_config.json')))['packages']}
        spec = open(os.path.join(top, 'app/pubspec.yaml')).read().split('dependencies:')[1].split('dev_dependencies:')[0]
        for name in re.findall(r'^  ([a-z_0-9]+):', spec, re.M):
            root = packages.get(name, '').replace('file://', '')
            if not root:
                continue
            root = root if os.path.isabs(root) else os.path.normpath(os.path.join(top, 'app/.dart_tool', root))
            found = classes(root, 'flutter' if name == 'flutter' else f'package:{name}',
                            ('widgets', 'gestures', 'painting', 'rendering', 'services', 'animation') if name == 'flutter' else None)
            rows += [('dart', i, shown, key, words, says) for i, shown, words, says, key in found]
    except Exception:   # (packages not resolved here: the dart side is then the engine's calls and cards alone)
        pass
    # our own parts: every class the app already has, said or not (a part with no doc comment is listed by name alone)
    for p in subprocess.run(['git', '-C', top, 'ls-files', 'app/lib'], capture_output=True, text=True).stdout.splitlines():
        if not p.endswith('.dart') or 'bindings' in p:
            continue
        try:
            text = open(os.path.join(top, p), encoding='utf-8', errors='replace').read()
        except OSError:
            continue
        said = {name: ' '.join(l.strip().lstrip('/ ') for l in doc.split('\n')) for doc, name in CLASS.findall(text)}
        for name in re.findall(r'^(?:abstract |final |base |sealed |interface )*(?:mixin )?class ([A-Z]\w+)', text, re.M):
            rows.append(('dart', f'{p}: {name}', ('ours: ' + said.get(name, 'says nothing of itself'))[:120], name, ' '.join(split(name)), said.get(name, '')[:600]))
    try:
        calls = open(os.path.join(top, 'engine/entry/motolii.h'), errors='replace').read()
        for name, says in re.findall(r'\b(motolii_[a-z_0-9]+)\s*\([^;{]*\)\s*;\s*/\*(.*?)\*/', calls, re.S):
            says = ' '.join(says.split())
            rows.append(('dart', f'engine/entry/motolii.h: {name}', says[:120], name, ' '.join(split(name.replace('motolii_', ''))), says[:600]))
        cards = open(os.path.join(top, 'engine/document/card_table.h'), errors='replace').read()
        for title, values in re.findall(r'\{\s*"([^"]+)",\s*"([^"]*)"', cards):
            rows.append(('dart', f'engine/document/card_table.h: the {title} card', f'a card the engine declares: {values}'[:120], title, ' '.join(split(title)), values))
    except OSError:
        pass
    db.executemany('insert into thing values (?, ?, ?, ?, ?, ?)', rows)
    return db, {s: sum(r[0] == s for r in rows) for s in ('engine', 'dart')}


def nearest(top, text, side='engine', limit=12, words=None, least=2, made=None, skip=''):
    """[(id, what it says of itself, the words of the text it shares)], nearest first, and how many things were asked.
    `side`: 'engine', 'dart' or '' for both. `least`: a thing is shown only when it shares that many of the text's
    words; 1 is a search by hand, every match shown. `made`: an index() already made, for many questions."""
    if words is None:
        said = [w for w in split(text) if w not in LANGUAGE]
        words = sorted(set(said), key=lambda w: (-said.count(w), w))[:MOST]
    db, counts = made or index(top)
    count = counts.get(side, sum(counts.values()))
    if not words:
        return [], count
    ask = ' OR '.join(f'"{w}"' for w in words)
    alike = lambda w, have: w in have or any(h.startswith(w[:5]) and w.startswith(h[:5]) for h in have)   # (wave, waves, waving)
    found = []
    for s, i, shown, key, name, says in db.execute('select side, id, shown, key, name, says from thing where thing match ? '
                                                   'order by bm25(thing, 0, 0, 0, 0, 4.0, 1.0) limit 300', (ask,)):
        if (side and s != side) or (skip and i.startswith(skip + ':')):   # (`skip`: the file being written is not somewhere else to hand it)
            continue
        if least > 1 and re.search(r'(?<![A-Za-z_])' + re.escape(key) + r'(?![A-Za-z_])', text):
            continue   # (the text already names it: it is being used, not re-made)
        called, both = set(name.split()), set(split(name + ' ' + says))
        shares = [w for w in words if alike(w, both)]
        # shown when the text says a word the thing is called by, and shares `least` words with it in all: a thing is
        # named for what it does, and one word alike in a description is chance
        if len(shares) >= min(least, len(words)) and (least < 2 or any(alike(w, called) for w in words)):
            found.append((i, shown, shares))
            if len(found) == limit:
                break
    return found, count


if __name__ == '__main__':
    top = subprocess.run(['git', 'rev-parse', '--show-toplevel'], capture_output=True, text=True).stdout.strip()
    if sys.argv[1:2] == ['--text']:
        found, count = nearest(top, sys.stdin.read(), sys.argv[2] if len(sys.argv) > 2 else 'engine')
    else:
        found, count = nearest(top, '', '', words=[w.lower() for w in sys.argv[1:]], least=1)
    for i, shown, shares in found:
        print(f'{i}   — {shown}   ({", ".join(shares)})')
    print(f'{len(found)} shown of {count} things that exist', file=sys.stderr)
