# svg.rs's written transform of each element against Chrome's own (parent's getCTM inverse times the element's, ctm.json).
import json, os, re, xml.etree.ElementTree as ET
c = json.load(open('chrome/ctm.json'))
names = [f[:-4] for f in sorted(os.listdir('svg-spinners/svg-css')) if f.endswith('.svg')]
ok = bad = 0
for t in c:
    i = 0
    for n in names:
        root = ET.parse(f'write/{n}@{t}.svg').getroot()
        for e in root.iter():
            if e is root or e.tag.endswith('style'): continue
            ch = c[t][i]; i += 1
            m = e.get('transform')
            if ch is None or m is None: continue
            ours = [float(x) for x in re.findall(r'-?[\d.]+(?:e-?\d+)?', m)]
            if all(abs(a - b) <= 1e-3 * max(1, abs(b)) for a, b in zip(ours, ch)): ok += 1
            else:
                bad += 1
                if bad <= 6: print(t, n, e.tag.split('}')[1], [round(x, 4) for x in ours], [round(x, 4) for x in ch])
print('agree', ok, 'differ', bad)
