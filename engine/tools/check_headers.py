#!/usr/bin/env python3
# What a header (and a .cpp's list of declarations) may not hold once each .cpp is compiled by itself. Today one unit
# reads every header, so none of this breaks anything yet; the day the unit is split, each of these is a duplicate
# symbol or a copy of state for every .cpp. Counted for each file and rule against tools/check_headers_ledger.txt: a
# count may fall, never rise, and a file that is not listed has to be clean.
#   guard            a header whose include guard is not #ifndef MOTOLII_<PATH>_H_ (its path from engine/, in capitals)
#   static-function  a static function with a body in a header: a copy, and a copy of its local statics, in every .cpp
#   definition       a function or variable defined in a header and not inline: defined twice by two .cpp
#   using-namespace  `using namespace` at file scope in a header: it reaches every file that includes it
#   mutable-static   a static variable that is not const in a header: every .cpp gets its own
#   prototype        a declaration in a .cpp or .mm of something another file defines: include its header instead
# The definitions are read by tools/function_census.py (ast-grep). Nothing is compiled.
#
#   python3 engine/tools/check_headers.py           the count of each rule, then "ok", or the files over their count
#   python3 engine/tools/check_headers.py --write   the ledger lowered to today's counts (it never adds or raises)
import os, re, sys
from collections import Counter, defaultdict

from function_census import OUTSIDE, ROOT, census, own_files, scan

LEDGER = 'tools/check_headers_ledger.txt'
RULES = ('guard', 'static-function', 'definition', 'using-namespace', 'mutable-static', 'prototype')

os.chdir(ROOT)
files, items = own_files(), census()
headers = [f for f in files if f.endswith('.h')]
found = []   # (rule, file, line, name)
for f in headers:
    guard = 'MOTOLII_' + re.sub(r'\W', '_', f[:-2]).upper() + '_H_'
    if not re.search(rf'^[ \t]*#[ \t]*ifndef[ \t]+{guard}[ \t]*\n[ \t]*#[ \t]*define[ \t]+{guard}[ \t]*$', open(f, encoding='utf-8', errors='replace').read(), re.M):
        found.append(('guard', f, 1, guard))
for f, by_rule in scan({'using': 'kind: using_declaration\nregex: ^using\\s+namespace\\b\n' + OUTSIDE}, headers).items():
    source = open(f, 'rb').read()
    found += [('using-namespace', f, source.count(b'\n', 0, a) + 1, ' '.join(source[a:b].decode().split())) for a, b in by_rule['using']]
defined = defaultdict(set)
for item in items:
    if item.kind in ('function', 'variable'): defined[item.file].update(item.name.split(','))
for item in items:
    header = item.file.endswith('.h')
    rule = ('static-function' if header and item.kind == 'function' and item.linkage == 'static' else
            'definition' if header and item.kind in ('function', 'variable') and item.linkage == 'external' else
            'mutable-static' if header and item.kind == 'variable' and item.linkage == 'static' else
            'prototype' if not header and item.kind == 'declaration' and not set(item.name.split(',')) & defined[item.file] else None)
    if rule: found.append((rule, item.file, item.line, item.name))

now = Counter(f[:2] for f in found)
lines = open(LEDGER).read().splitlines() if os.path.exists(LEDGER) else []
ledger = {(rule, f): int(n) for n, rule, f in (line.split('\t') for line in lines if line and not line.startswith('#'))}
if '--write' in sys.argv[1:]:
    ledger = {key: min(n, now[key]) for key, n in ledger.items() if now[key]} if ledger else dict(now)
    open(LEDGER, 'w').write('\n'.join([line for line in lines if line.startswith('#')] +
                                      [f'{n}\t{rule}\t{f}' for (rule, f), n in sorted(ledger.items(), key=lambda e: (RULES.index(e[0][0]), e[0][1]))]) + '\n')
for rule in RULES:
    print(f'{rule}: {sum(n for key, n in now.items() if key[0] == rule)} in {sum(key[0] == rule for key in now)} files')
bad = []
for (rule, f), n in sorted(now.items()):
    if n > ledger.get((rule, f), 0):
        bad.append(f'{f}: {rule} {n}, the ledger allows {ledger.get((rule, f), 0)}: ' + ', '.join(f'{name} (line {line})' for r, g, line, name in sorted(found) if (r, g) == (rule, f)))
if bad:
    bad.append(f'What each rule is for: the head of engine/tools/check_headers.py. A file that only moved: change its path in engine/{LEDGER} by hand.')
lower = [f'{f}: {rule} {now[(rule, f)]}, the ledger still says {n}' for (rule, f), n in sorted(ledger.items()) if now[(rule, f)] < n]
if lower:
    bad += lower + [f'Lower the ledger so the count cannot come back: python3 engine/tools/check_headers.py --write, and commit engine/{LEDGER}.']
sys.exit('\n'.join(bad) if bad else print('ok'))
