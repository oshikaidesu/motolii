#!/usr/bin/env python3
# Does each file of ours include only what its layer may? The map is engine/layers.txt (read its head for the
# format); this reads the #include lines of our .h, .cpp and .mm and nothing else, so it needs no compiler.
# An include the map does not allow is counted for its pair of modules against tools/check_layers_ledger.txt: a
# count may fall, never rise, and a pair that is not listed has to be clean. An exception the map gives an end to
# ("until") is listed and passes.
#
#   python3 engine/tools/check_layers.py           each include against the map, then "ok", or the pairs over their count
#   python3 engine/tools/check_layers.py --write   the ledger lowered to today's counts (it never adds or raises)
import os, re, subprocess, sys
from collections import Counter, defaultdict

from ledger import settle

ROOT = os.path.realpath(os.path.join(os.path.dirname(__file__), '..'))
MAP, LEDGER = 'layers.txt', 'tools/check_layers_ledger.txt'
os.chdir(ROOT)

order, allowed, refused, until, bad = [], {}, defaultdict(list), defaultdict(dict), []
for line in open(MAP).read().splitlines():
    said = re.match(r'(\S+?)(?: until ([^:]+))?:(.*)$', line.split('#')[0].strip())
    if not said: continue
    module, when, names = said.group(1), said.group(2), said.group(3).split()
    if when:
        until[module].update({name: when for name in names})
        continue
    if 'not' in names:
        refused[module] = [name.lstrip('<') for name in names[names.index('not') + 1:]]
        names = names[:names.index('not')]
    bad += [f'{MAP}: {module} names {name}, which is not a module above its line (the map is lowest first)' for name in names if name != '*' and name not in order]
    allowed[module] = set(order) if '*' in names else set(names)
    order.append(module)
bad += [f'{MAP}: the exception of {module} names {name}, which is no module' for module in until for name in until[module] if name[0] != '<' and name not in order]


def module_of(path):
    return max((m for m in order if path == m or path.startswith(m + '/')), key=len, default=None)


listed = subprocess.run(['git', 'ls-files', '-co', '--exclude-standard'], capture_output=True, text=True).stdout.split('\n')
files = {f for f in listed if f.endswith(('.h', '.cpp', '.mm')) and not f.startswith(('third_party/', 'out/')) and os.path.exists(f)}
against, excepted, between = defaultdict(list), Counter(), 0
for f in sorted(files):
    here = module_of(f)
    if not here:
        bad.append(f'{f}: in no module of {MAP}. Add a line for its folder, where it belongs in the order.')
        continue
    for quote, path in re.findall(r'^[ \t]*#[ \t]*(?:include|import)[ \t]*(["<])([^">]+)[">]', open(f, encoding='utf-8', errors='replace').read(), re.M):
        if quote == '<':
            pair = next(((here, '<' + prefix) for prefix in refused[here] if path.startswith(prefix)), None)
            there = pair and pair[1]
        else:   # (from engine/, as we write them, or beside the file that includes it; anything else is not ours)
            path = path if path in files else os.path.normpath(os.path.join(os.path.dirname(f), path))
            there = module_of(path) if path in files else None
            between += bool(there and there != here)
            pair = (here, there) if there and there != here and there not in allowed[here] else None
        if pair and there in until[here]: excepted[(*pair, until[here][there])] += 1
        elif pair: against[pair].append(f'{f} includes {path}')

ledger, over, lower = settle(LEDGER, {pair: len(lines) for pair, lines in against.items()}, '--write' in sys.argv[1:], 'check_layers.py')
print(f'{len(order)} modules in {MAP}, {len(files)} files, {between} includes from one module to another')
for (here, there, when), n in sorted(excepted.items()):
    print(f'allowed until {when}: {here} -> {there}: {n}')
for pair, lines in sorted(against.items()):
    print(f'against the map: {pair[0]} -> {pair[1]}: {len(lines)} (the ledger allows {ledger.get(pair, 0)})' + ''.join('\n    ' + line for line in lines))
if over:
    bad.append('Over the ledger: ' + ', '.join(f'{here} -> {there}' for here, there in over) + f'. A module includes only what its line in engine/{MAP} names. '
               'Include a header of a module it may, move the code to the layer that may include both, or, when the included module is lower in the map, add it to the line.')
sys.exit('\n'.join(bad + lower) if bad or lower else print('ok'))
