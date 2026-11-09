#!/usr/bin/env python3
# Do our own identifiers, or our .md, still use a dropped house word? The words, what replaces them and what stays:
# docs/internal/notes/rename_words.md §1 (rows), §2 (names that stay), §5 (this check's draft).
#   word_check.py         the lines the staged commit adds (pre-commit hook, like size_check.py)
#   word_check.py --all   every file of ours in the index (CI, .github/workflows/checks.yml)
# Counts per word go to stderr either way. FAIL below decides whether a hit stops the commit / the CI run.
import re, subprocess, sys
from collections import Counter, defaultdict

# The one switch. False: report only, exit 0 (the renames B1–B5 of the note's §4 are not on main yet).
# True: any hit exits 1 and refuses the commit (githooks(5): "Exiting with a non-zero status from this script
# causes the git commit command to abort"). Flip it in the commit that lands the last rename batch.
FAIL = False

# Identifier parts (snake/camel split) that are gone: §1 rows 1–5, 7–14, 16–20, 22–32.
DROPPED = {'thing', 'things', 'fact', 'facts', 'way', 'ways', 'goes', 'film', 'films', 'picture', 'pictures',
           'drawn', 'made', 'kept', 'told', 'tell', 'telling', 'moment', 'moments', 'hand', 'door', 'doors',
           'seat', 'seats', 'kit', 'knob', 'knobs', 'trouble', 'eye', 'wear', 'look', 'looks', 'desk'}
# Whole names that are gone where the word itself stays: row 6 `step` (`sqlite3_step` and the easing `Steps`
# keep it, §2 c) and row 21 hold / carry / let go (plain words elsewhere).
DROPPED_NAMES = {'doc_step', 'motolii_hand_step', 'motolii_hold', 'motolii_carry', 'motolii_let_go'}
# Old table names inside SQL strings (§3: the tables become layer / keyframe / easing / undo_step).
TABLES = re.compile(r'\b(?:from|into|update|join|table(?: if not exists)?|attach database \S+ as)\s+(?:\w+\.)?'
                    r'(step|fact|way|thing)\b', re.I)
# Names someone else's code gives, kept as they wrote it (§2). One line each, with whose name it is.
FOREIGN = {
    'lookAt',     # Filament Camera::lookAt(eye, center, up) (filament/include/filament/Camera.h), §2 a
    'IOKit',      # Apple's framework (developer.apple.com/documentation/iokit), linked by engine/gpu/*.sh
    'SceneKit',   # Apple's framework (developer.apple.com/documentation/scenekit), engine/stage/render/
}
# A name under another library's namespace is that library's (§2 a, b, e): tvg::Picture, filament::View, ui.Picture.
QUALIFIED = re.compile(r'\b(?:tvg|filament|utils|math)::\w+(?:::\w+)*|\bui\.\w+')
# Exact lines that must keep an old name on purpose (§3: `way()` stays callable, 'film'/'picture' accepted on input,
# the `fact` fallback of document/marks.h). (path, the line stripped, why) — added by the batch that writes the line.
ALIAS_LINES = {   # (B1: docs/internal/notes/rename_words.md §3)
    ('engine/document/undo.h', 'if (has("fact")) {',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', 'sql += "create table if not exists " + at + "thing(id integer primary key autoincrement);"',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', '"create table if not exists " + at + "way(name text primary key, goes text) without rowid;";',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', 'if (count("select count(*) from pragma_table_info(\'fact\', \'" + schema + "\') where name = \'way\'") == 0) sql += "alter table " + at + "fact add column way text;";   // (from before stretches had ways)',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', 'sql += "alter table " + at + "thing rename to layer;"',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', '"alter table " + at + "fact rename to keyframe;"',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', '"alter table " + at + "keyframe rename column thing to layer;"',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', '"alter table " + at + "keyframe rename column way to easing;"',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', '"alter table " + at + "way rename to easing;"',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', '"alter table " + at + "easing rename column goes to expression;"',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', '"update " + at + "keyframe set value = \'video\' where name = \'kind\' and value = \'film\';"',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', '"update " + at + "keyframe set value = \'image\' where name = \'kind\' and value = \'picture\';";',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', 'if (has("step")) sql += "alter table " + at + "step rename to undo_step; update " + at + "undo_step set change = null;";',
     'doc_upgrade: the old names it renames (§3)'),
    ('engine/document/undo.h', 'for (const char* name : {"easing", "way"}) sqlite3_create_function(d->file, name, 2, SQLITE_UTF8 | SQLITE_DETERMINISTIC, d, ease_by, nullptr, nullptr);',
     'way() still callable from old expressions and shelves/ease/*.way (§3)'),
    ('engine/document/layer_edit.h', 'else if (!strcmp(kind, "film")) kind = "video";   // (the kinds\' names before 2026-11-09, still taken: docs/internal/notes/rename_words.md §3)',
     'kinds film/picture still taken on input (§3)'),
    ('engine/document/layer_edit.h', 'else if (!strcmp(kind, "picture")) kind = "image";',
     'kinds film/picture still taken on input (§3)'),
    ('engine/document/marks.h', '|| sqlite3_prepare_v2(file, "select name, value from fact where thing = 0 and name in (\'wide\', \'high\')", -1, &rows, nullptr) == SQLITE_OK))',
     'a read-only old document read by its old names (§3)'),
    ('engine/document/presets.h', '&& sqlite3_exec(old, "select 1 from fact limit 0", nullptr, nullptr, nullptr) == SQLITE_OK) {',
     'telling an old preset file to bring it up to date (§3)'),
}
# The Japanese words of rows 33–35, as they appear in our .md. 物 and 中身 are everyday words ("作った物",
# "中身が分かる"), so only their quoted use as a term is the house word.
JAPANESE = re.compile(r'窓|書類|場面|「物」|「中身」')

OWN_CODE = re.compile(r'^(engine/(?!third_party/|deps/|out/).*\.(h|cpp|mm|c|sh|py)|app/lib/.*(?<!_bindings)\.dart)$')
# Our .md: not the internal notes (records of how it was), not others' (third_party, deps, the contents of a shelf).
OWN_MD = re.compile(r'^(?!docs/internal/|engine/third_party/|engine/deps/|engine/out/|shelves/[^/]+/).*\.md$')
COMMENT = re.compile(r'//[^\n]*|/\*.*?\*/|^\s*#(?!include|define|!)[^\n]*', re.S | re.M)
CODE_SPAN = re.compile(r'`([^`\n]+)`')


def parts(ident):
    return [p.lower() for p in re.findall(r'[A-Z]?[a-z]+|[A-Z]+(?![a-z])', ident)]


def hits_in_code(text):
    """(word, the identifier or table that carries it) for every hit; comments may use plain English."""
    out = []
    for ident in re.findall(r'[A-Za-z_][A-Za-z0-9_]*', QUALIFIED.sub('', COMMENT.sub('', text))):
        if ident in FOREIGN:
            continue
        if ident in DROPPED_NAMES:
            out.append((ident, ident))
        out += [(w, ident) for w in parts(ident) if w in DROPPED]
    return out + [(m.lower(), 'table ' + m) for m in TABLES.findall(text)]


def hits_in_md(text):
    """Prose may say "the way" or "made"; code spans name our code, so they hold to the code's words.
    `door` is gone from prose too (§1: "door does not survive"), and the Japanese words of rows 33–35."""
    out = [h for span in CODE_SPAN.findall(text) for h in hits_in_code(span)]
    out += [('door', m) for m in re.findall(r'\b[Dd]oors?\b', CODE_SPAN.sub('', text))]
    return out + [(m, m) for m in JAPANESE.findall(text)]


def hits_in(path, text):
    allowed = {l for p, l, _ in ALIAS_LINES if p == path}
    text = '\n'.join(l for l in text.split('\n') if l.strip() not in allowed)
    return hits_in_md(text) if path.endswith('.md') else hits_in_code(text)


def git(*a):
    return subprocess.run(['git', *a], capture_output=True).stdout.decode('utf-8', 'replace')


def own(path):
    return bool(OWN_CODE.match(path) or OWN_MD.match(path))


found = defaultdict(list)   # path -> [(word, carrier)]
if '--all' in sys.argv[1:]:
    for path in filter(own, git('ls-files', '-z').split('\0')):
        try:
            text = open(path, encoding='utf-8', errors='replace').read()
        except OSError:
            continue
        found[path] += hits_in(path, text)
else:
    path = None
    for line in git('diff', '--cached', '-U0', '--diff-filter=ACMR', '--no-color').splitlines():
        if line.startswith('+++ '):
            path = line[6:] if own(line[6:]) else None
        elif path and line.startswith('+'):
            found[path] += hits_in(path, line[1:])
found = {p: h for p, h in found.items() if h}

if found:
    area = lambda p: 'md' if p.endswith('.md') else 'engine' if p.startswith('engine/') else 'app'
    count = defaultdict(Counter)       # word -> {area: hits}
    files = defaultdict(set)
    for p, hits in found.items():
        for w, _ in hits:
            count[w][area(p)] += 1
            files[w].add(p)
    print(f'{"word":<18}{"engine":>8}{"app":>7}{"md":>6}{"files":>7}', file=sys.stderr)
    for w in sorted(count, key=lambda w: -sum(count[w].values())):
        c = count[w]
        print(f'{w:<18}{c["engine"]:>8}{c["app"]:>7}{c["md"]:>6}{len(files[w]):>7}', file=sys.stderr)
    total = sum(len(h) for h in found.values())
    print(f'{"total":<18}{total:>28} in {len(found)} files', file=sys.stderr)
    if '--files' in sys.argv[1:] or (FAIL and '--all' not in sys.argv[1:]):
        for p, hits in sorted(found.items()):
            print(f'  {p}: {", ".join(sorted({c for _, c in hits})[:8])}', file=sys.stderr)
    if FAIL:
        print('word check refused this: a dropped house word (docs/internal/notes/rename_words.md §1; '
              'a name of someone else\'s goes into FOREIGN with whose it is)', file=sys.stderr)
        sys.exit(1)
    print('word check: report only (FAIL = False at the top of .githooks/word_check.py)', file=sys.stderr)
