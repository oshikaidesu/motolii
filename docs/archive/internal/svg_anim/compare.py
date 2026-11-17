# Blitz against Chrome, svg-spinners: per element and time, each animated property's numbers within 1e-3 (relative above 1).
import json, re, sys, collections
b, c = json.load(open('blitz.json')), json.load(open('chrome/spinners.json'))
num = lambda s: [float(x) for x in re.findall(r'-?\d*\.?\d+(?:e-?\d+)?', s)] if s not in ('none', 'auto') else [s]
same = lambda p, q: len(p) == len(q) and all(x == y if isinstance(x, str) or isinstance(y, str) else abs(x - y) <= 1e-3 * max(1, abs(y)) for x, y in zip(p, q))
ok, bad = 0, collections.Counter()
ex = {}
for t in c:
    for i, (cb, cc) in enumerate(zip(b[t], c[t])):
        for p in cc:
            # only properties Chrome shows moving between the three times count as animated
            if len({c[u][i][p] for u in c}) == 1: continue
            if same(num(cb[p]), num(cc[p])): ok += 1
            else: bad[p] += 1; ex.setdefault(p, (t, i, cb[p], cc[p]))
print('agree', ok, 'differ', sum(bad.values()), dict(bad))
for p, e in ex.items(): print(p, e)
