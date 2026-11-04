# The font shelf's sample for a font of other letters than Latin (samples.json): for each script Google Fonts'
# gflanguages knows (googlefonts/lang, Apache-2.0: gflanguages-LICENSE.txt), the short sample of its most spoken
# language, as fonts.google.com shows a font in its own script (sample_text poster_sm; else styles, cut at a word).
# Most spoken first: a font of several scripts is shown in the one most read. With it, the first letters of that
# language's alphabet (exemplar_chars base, CLDR's): for a font with the letters but not the sample's marks.
#   python3 -I from_gflanguages.py <gflanguages/data> samples.json
import glob, json, re, sys

data, out = sys.argv[1:3]
def field(text, name):
    m = re.search(rf'^\s*{name}: "((?:[^"\\]|\\.)*)"', text, re.M)
    return m and re.sub(r'\\(.)', lambda e: ' ' if e.group(1) == 'n' else e.group(1), m.group(1))
names = {field(open(p).read(), 'id'): field(open(p).read(), 'name') for p in glob.glob(f'{data}/scripts/*.textproto')}
best = {}
for p in glob.glob(f'{data}/languages/*.textproto'):
    t = open(p).read()
    script, said = field(t, 'script'), field(t, 'poster_sm') or field(t, 'styles')
    if not script or script == 'Latn' or not said:
        continue
    people = int((re.search(r'^population: (\d+)', t, re.M) or [0, 0])[1])
    if len(said) > 28:
        said = said[:28].rsplit(' ', 1)[0] if ' ' in said[:28] else said[:14]
    some = []   # (CLDR writes a run as its ends, ꀀ-ꒌ, and a cluster in braces: the run's letters, no cluster)
    for k in (field(t, 'base') or '').split():
        some += [chr(c) for c in range(ord(k[0]), ord(k[2]) + 1)] if len(k) == 3 and k[1] == '-' else [] if '{' in k else [k]
    letters = ''.join(some[:8])
    if script not in best or people > best[script][0]:
        best[script] = (people, said.strip(), letters)
rows = sorted(best.items(), key=lambda kv: -kv[1][0])
json.dump([{'script': names.get(s, s), 'sample': said, 'letters': letters} for s, (_, said, letters) in rows], open(out, 'w'), ensure_ascii=False, indent=0)
print(len(rows), 'scripts')
