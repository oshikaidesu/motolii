#!/usr/bin/env python3
# What is already here that does this? The shelves and the adapters, asked in words.
#   what_exists.py WORD...        by hand:  python3 .githooks/what_exists.py wave copies noise
#   what_exists.py --text         the words of a text on stdin (an edit, a diff): what it is most about
#   nearest(top, text)            the same from Python (.claude/hooks/own_code_sign.py, .githooks/own_code_check.py)
# Every file that is a behaviour to run (shelves/, engine/community/) is read at its head: its name, and what it says
# of itself there (its first comment, an ISF file's DESCRIPTION, a script's --about: and --track@ lines). The ranking
# is not ours: SQLite's FTS5 with its bm25() (sqlite.org/fts5.html, "The bm25() function"; Okapi BM25), words stemmed
# by its porter tokenizer, the file's name weighing four times what it says. Nothing is kept: the index is made in
# memory each time (about 1,800 heads).
import os, re, sqlite3, subprocess, sys

# Files that are a behaviour to run (not its picture, its notes, its translations or a saved document).
RUNS = {'js', 'wgsl', 'fs', 'am', 'way', 'anm2', 'obj2', 'scn2', 'lua', 'h', 'cpp', 'ts'}
# Words of the languages themselves (C++ and Dart keywords and types): they say nothing of what is being made.
LANGUAGE = set('auto bool break case char class const continue default double dynamic else enum extends false final float '
               'import include inline late long namespace null nullptr override part required return short show signed '
               'sizeof static string struct super switch template this throw true typedef typename uint unsigned using '
               'void while with async await widget build context state std math size int64 uint32'.split())
MOST = 16   # (the words a text says most often are what it is about; the rest are how it is written)


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


def index(top):
    paths = subprocess.run(['git', '-C', top, '-c', 'core.quotepath=off', 'ls-files', 'shelves', 'engine/community'],
                           capture_output=True, text=True).stdout.splitlines()
    db = sqlite3.connect(':memory:')
    db.execute("create virtual table file using fts5(path unindexed, shown unindexed, name, says, tokenize='porter unicode61')")
    rows = []
    for p in paths:
        stem, kind = os.path.splitext(os.path.basename(p))
        if kind.lstrip('.') not in RUNS:
            continue
        says, shown = head(os.path.join(top, p))
        rows.append((p, shown, ' '.join(split(stem)), says))
    db.executemany('insert into file values (?, ?, ?, ?)', rows)
    return db, len(rows)


def nearest(top, text, limit=12, words=None, least=2):
    """[(path, what it says of itself, the words of the text it shares)], nearest first, and how many files were asked.
    `least`: a file is shown only when it shares that many of the text's words; 1 is a search by hand, every match shown."""
    if words is None:
        said = [w for w in split(text) if w not in LANGUAGE]
        words = sorted(set(said), key=lambda w: (-said.count(w), w))[:MOST]
    if not words:
        return [], 0
    db, count = index(top)
    ask = ' OR '.join(f'"{w}"' for w in words)
    found = []
    alike = lambda w, have: w in have or any(h.startswith(w[:5]) and w.startswith(h[:5]) for h in have)   # (wave, waves, waving)
    for path, shown, name, says in db.execute('select path, shown, name, says from file where file match ? order by bm25(file, 0, 0, 4.0, 1.0) limit 200', (ask,)):
        called, both = set(name.split()), set(split(name + ' ' + says))
        shares = [w for w in words if alike(w, both)]
        # shown when the text says a word the file is called by, and shares `least` words with it in all: a file is
        # named for what it does, and one word alike in a description is chance
        if len(shares) >= min(least, len(words)) and (least < 2 or any(alike(w, called) for w in words)):
            found.append((path, shown, shares))
    return found[:limit], count


if __name__ == '__main__':
    top = subprocess.run(['git', 'rev-parse', '--show-toplevel'], capture_output=True, text=True).stdout.strip()
    if sys.argv[1:2] == ['--text']:
        found, count = nearest(top, sys.stdin.read())
    else:
        found, count = nearest(top, '', words=[w.lower() for w in sys.argv[1:]], least=1)
    for path, shown, shares in found:
        print(f'{path}   — {shown}   ({", ".join(shares)})')
    print(f'{len(found)} shown of {count} files that run (shelves/, engine/community/)', file=sys.stderr)
