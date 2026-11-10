#!/usr/bin/env python3
# A ledger: the counts of known faults, which may fall and never rise. Tab-separated lines "count, key, key"; its "#"
# lines are its head and are kept. tools/check_headers.py and tools/check_layers.py keep one each.
import os


def settle(path, now, write, tool):
    # `now` is {(key, key): count} as counted today. With `write` the ledger is lowered to it: no line is added and no
    # count raised (an empty ledger is filled once). Returns the ledger, the keys now over it, and what to say when
    # a count fell and the ledger was not lowered.
    lines = open(path).read().splitlines() if os.path.exists(path) else []
    ledger = {tuple(keys): int(n) for n, *keys in (line.split('\t') for line in lines if line and not line.startswith('#'))}
    if write:
        ledger = {key: min(n, now[key]) for key, n in ledger.items() if now.get(key)} if ledger else dict(now)
        open(path, 'w').write('\n'.join([line for line in lines if line.startswith('#')] + ['\t'.join((str(n), *key)) for key, n in sorted(ledger.items())]) + '\n')
    over = [key for key, n in sorted(now.items()) if n > ledger.get(key, 0)]
    lower = [f'{" ".join(key)}: {now.get(key, 0)} now, the ledger still says {n}' for key, n in sorted(ledger.items()) if now.get(key, 0) < n]
    if lower:
        lower.append(f'Lower the ledger so the count cannot come back: python3 engine/tools/{tool} --write, and commit engine/{path}.')
    return ledger, over, lower
