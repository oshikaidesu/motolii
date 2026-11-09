#!/usr/bin/env python3
# Nothing the window cannot reach may pile up again (docs/internal/notes/noise_cut.md: 4,000 lines were cut once).
#   card_check.py's way:  reach_check.py            what is staged (the index): the pre-commit hook
#                         reach_check.py --all      the commit checked out (HEAD): CI, .github/workflows/checks.yml
#                         reach_check.py --rev REV  another commit (`--rev noise-archive-2026-11-09`: before the cut)
# rule 1: a motolii_* function engine/entry/motolii.h declares that the window never names. The window is app/ (its
#         Dart, and the Swift or C++ runner that opens the native texture), without the ffigen copy of the header
#         (app/lib/bridge/motolii_bindings.dart) and without the tests; and engine/stage/snapshot.h, the copy of the
#         document the window reads each frame, which calls motolii_* itself. Comments do not count; strings do (Dart
#         hands 'motolii_desk_front' to the runner by name).
# rule 2: a public class, mixin or enum in app/lib that no code outside its own body names: not another file, not the
#         rest of its own file (a State made by createState there is reached). Comments and string text do not count.
import re, subprocess, sys

HEADER = 'engine/entry/motolii.h'
BINDINGS = 'app/lib/bridge/motolii_bindings.dart'
SNAPSHOT = 'engine/stage/snapshot.h'
WINDOW_FILES = ('.dart', '.swift', '.cc', '.cpp', '.h', '.mm', '.m')
NOT_WINDOW = ('app/test/', 'app/integration_test/', BINDINGS)
# Debt: what may stand unreached for now, each with why; the line goes when the reason does.
OWED = {
    # edit.sh's `effect` puts an effect on at the stage's moment (docs/using/make_intro_movie.md runs it); the window
    # asks later('effect') with its own moment. It goes when edit.cpp asks the same way.
    'motolii_now',
    # the Inspector is being rebuilt on one card rule (card_check.py); what it leaves standing goes with that work
    'app/lib/inspector/inspector_small.dart Cap',
    'app/lib/inspector/inspector_small.dart LinkMark',
    'app/lib/inspector/rows/inspector_rows.dart AxisHeader',
}
SAY = 'nothing in the window reaches this; wire it to a menu/dock/card or delete it'
IDENT = re.compile(r'[A-Za-z_$][\w$]*')
C_COMMENT = re.compile(r'//[^\n]*|/\*.*?\*/', re.S)
DECL = re.compile(r'^[ \t]*(?:(?:abstract|sealed|base|final|interface|mixin)\s+)*(class|mixin|enum)\s+([A-Z][\w$]*)', re.M)


def git(*a, data=None):
    return subprocess.run(['git', *a], input=data, capture_output=True).stdout


if sys.argv[1:2] == ['--all']:
    rev = 'HEAD'
elif sys.argv[1:2] == ['--rev'] and len(sys.argv) > 2:
    rev = sys.argv[2]
else:
    rev = ''   # the index
listing = git('ls-tree', '-r', '--name-only', '-z', rev) if rev else git('ls-files', '--cached', '-z')
paths = [p for p in listing.decode().split('\0') if p]
window = [p for p in paths if p.startswith('app/') and p.endswith(WINDOW_FILES) and not p.startswith(NOT_WINDOW)]
if HEADER not in paths:
    sys.exit(0)   # (a tree from before the header was there)


def read(names):
    """Each path's text at `rev` (or in the index), by one `git cat-file --batch`."""
    out = git('cat-file', '--batch', data=''.join(f'{rev}:{p}\n' for p in names).encode())
    texts, at = {}, 0
    for p in names:
        head_end = out.index(b'\n', at)
        head = out[at:head_end].split()
        if head[-1] == b'missing':
            at = head_end + 1
            continue
        size = int(head[-1])
        texts[p] = out[head_end + 1:head_end + 1 + size].decode('utf-8', 'replace')
        at = head_end + 1 + size + 1
    return texts


def dart_code(src):
    """Dart with its comments gone and each string's text gone (what ${...} and $name put in kept as code); and the
    strings' text apart. Every character keeps its place (a blank for one taken out), so spans stay true."""
    code, strings, i, n = [], [], 0, len(src)

    def blank(t):
        return re.sub(r'[^\n]', ' ', t)

    def body(i, stop_at_brace):
        depth = 0
        while i < n:
            if src.startswith('//', i):
                j = src.find('\n', i)
                j = n if j < 0 else j
                code.append(blank(src[i:j])); i = j; continue
            if src.startswith('/*', i):
                d, j = 1, i + 2
                while j < n and d:
                    d += 1 if src.startswith('/*', j) else -1 if src.startswith('*/', j) else 0
                    j += 2 if src.startswith(('/*', '*/'), j) else 1
                code.append(blank(src[i:j])); i = j; continue
            c, raw = src[i], False
            if c in 'rR' and src[i + 1:i + 2] in ('"', "'") and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] in '_$')):
                raw = True; code.append(' '); i += 1; c = src[i]
            if c in '"\'':
                q = src[i:i + 3] if src[i:i + 3] in ('"""', "'''") else c
                code.append(blank(q)); i = string(i + len(q), q, raw); continue
            if c == '{': depth += 1
            if c == '}':
                if stop_at_brace and depth == 0: return i
                depth -= 1
            code.append(c); i += 1
        return i

    def string(i, q, raw):
        text = []
        while i < n:
            if src.startswith(q, i):
                code.append(blank(q)); strings.append(''.join(text)); return i + len(q)
            c = src[i]
            if c == '\\' and not raw:
                code.append(blank(src[i:i + 2])); text.append(src[i:i + 2]); i += 2; continue
            if c == '$' and not raw and src[i + 1:i + 2] == '{':
                code.append('  '); i = body(i + 2, True); code.append(' '); i += 1; continue
            if c == '$' and not raw and (m := IDENT.match(src, i + 1)):
                code.append(' ' + m.group(0)); i = m.end(); continue
            code.append(blank(c)); text.append(c); i += 1
        strings.append(''.join(text))
        return i

    body(0, False)
    return ''.join(code), '\n'.join(strings)


texts = read([HEADER, SNAPSHOT] + window)
refused = []

# rule 1
declared = sorted(set(re.findall(r'\b(motolii_\w+)\s*\(', C_COMMENT.sub('', texts[HEADER]))))
named = set(re.findall(r'motolii_\w+', C_COMMENT.sub('', texts.get(SNAPSHOT, ''))))
dart = {}
for p in window:
    if p.endswith('.dart'):
        dart[p] = dart_code(texts.get(p, ''))
        named.update(re.findall(r'motolii_\w+', dart[p][0] + '\n' + dart[p][1]))
    else:
        named.update(re.findall(r'motolii_\w+', C_COMMENT.sub('', texts.get(p, ''))))
for f in declared:
    if f not in named and f not in OWED:
        refused.append(f'{HEADER}: {f}: {SAY}')

# rule 2
lib = {p: c for p, (c, _) in dart.items() if p.startswith('app/lib/')}
count = {p: {} for p in lib}
for p, c in lib.items():
    for w in IDENT.findall(c):
        count[p][w] = count[p].get(w, 0) + 1
for p, c in lib.items():
    for m in DECL.finditer(c):
        kind, name = m.group(1), m.group(2)
        if any(count[o].get(name) for o in lib if o != p):
            continue
        open_at, semi = c.find('{', m.end()), c.find(';', m.end())
        end = semi if 0 <= semi < open_at else open_at   # (`class A = B with C;` has no body)
        depth = 0
        for end in range(end, len(c)) if end == open_at else ():
            depth += c[end] == '{'
            depth -= c[end] == '}'
            if depth == 0:
                break
        own = len(re.findall(rf'(?<![\w$]){re.escape(name)}(?![\w$])', c[m.start():end + 1]))
        if count[p].get(name, 0) - own <= 0 and f'{p} {name}' not in OWED:
            line = c.count('\n', 0, m.start()) + 1
            refused.append(f'{p}:{line}: {kind} {name}: {SAY}')

if refused:
    print('reach check refused this commit (rule: the window reaches all we keep; .githooks/README.md):\n  '
          + '\n  '.join(refused), file=sys.stderr)
    sys.exit(1)
