#!/bin/zsh
# Rules over a collection, as three programs write them, each as the document's own data on the real stage, no code:
#   After Effects' text animator Fade In — a stagger (keys on Opacity, each copy later: doc_delay);
#   Cinema 4D's Cloner under a Plain Effector with a spherical Falloff — a behaviour giving y, through a falloff region
#     (a circle shape) with a soft edge: the middle copies lifted, the ends not (doc_given, doc_falloff_at);
#   CSS's cascade, the later rule over the earlier — two keys on one value (the later wins), a stagger on top.
# This is the acceptance for the one path "where × when × what" (docs/notes/GROUP_INSPECTOR.md): whatever is folded or
# cut in the engine, these stay yes. Needs the inside built (edit.sh).
#   ./check/rules.sh
cd "$(dirname "$0")/.."
W=$(mktemp -d "${TMPDIR:-/tmp}/rules.XXXX"); [ -n "$KEEP" ] && W=$PWD/out/rules_keep && rm -rf $W && mkdir -p $W
row='add shape rect\nset 1 size 0.06\nsay 1 fill ffc850\nset 1 copies 10\nset 1 copy_x 0.09\n'
# AE: Fade In, left to right over 1 s.
printf "$row"'set 1 stagger 1\nkeys 1 opacity 0 0 0.2 1\nat 0.3\nstill %s/ae.png\n' $W | ./edit.sh $W/ae.motolii > $W/ae.txt 2>&1
# C4D: a behaviour (any kind; its minimum and maximum the same: a Plain Effector) giving y 0.15, inside a circle at the
# row's middle (thing 3, not seen itself) with a soft edge: the Falloff.
printf "$row"'add behaviour random\nset 2 minimum 0.15\nset 2 maximum 0.15\nadd shape circle\nset 3 size 0.3\nset 3 visible 0\nset 2 region 3\nset 2 falloff_soft 0.15\nset 1 y_by 2\nstill %s/c4d.png\n' $W | ./edit.sh $W/c4d.motolii > $W/c4d.txt 2>&1
# CSS: opacity 0.5 for all (a key at 0), then 1 (a key at 0.1: the later wins), staggered so the left have it and the
# right still the earlier at 0.3 s.
printf "$row"'set 1 stagger 1\nkeys 1 opacity 0 0.5 0.1 1\nat 0.3\nstill %s/css.png\n' $W | ./edit.sh $W/css.motolii > $W/css.txt 2>&1
python3 -c "
from PIL import Image
def copies(name, lit=lambda p: p[0] > 230 and p[1] > 180 and p[2] < 120):   # (whole: ffc850; half-clear on black is 188 146 56 in sRGB)   # (each lit run across the middle rows: its middle x and top y)
    im = Image.open('$W/%s.png' % name).convert('RGB'); w, h = im.size; px = im.load()
    on = [any(lit(px[x, y]) for y in range(0, h, 4)) for x in range(w)]
    runs, x = [], 0
    while x < w:
        if on[x]:
            x0 = x
            while x < w and on[x]: x += 1
            mid = (x0 + x) // 2
            top = next((y for y in range(h) if lit(px[mid, y])), h)
            runs.append((mid, top)); continue
        x += 1
    return runs, w
ae, w = copies('ae'); c4d, _ = copies('c4d'); css, _ = copies('css')
dim, _ = copies('css', lambda p: 150 < p[0] < 215 and 110 < p[1] < 170 and p[2] < 90)   # (the half-clear ones)
ok_ae = 1 <= len(ae) <= 5 and max(x for x, y in ae) < w * 0.5
ok_c4d = len(c4d) == 10 and c4d[4][1] < c4d[0][1] - 10 and c4d[5][1] < c4d[9][1] - 10 and abs(c4d[0][1] - c4d[9][1]) < 4
dim = [x for x, y in dim if x > w * 0.4]   # (a bright copy's soft edge reads as dim too: only the right half counts)
ok_css = 1 <= len(css) <= 5 and max(x for x, y in css) < w * 0.5 and 4 <= len(dim) <= 10
print('AE Fade In as data (keys and a stagger): ' + ('yes' if ok_ae else 'NO (%s of %d)' % (ae, w)))
print('C4D Effector under a Falloff as data (a behaviour through a region): ' + ('yes' if ok_c4d else 'NO (%s)' % (c4d,)))
print('CSS cascade as data (the later key wins, staggered): ' + ('yes' if ok_css else 'NO (lit %s, dim %s)' % (css, dim)))
" || { echo "rules: NO (logs:)"; tail -5 $W/ae.txt $W/c4d.txt $W/css.txt; }
[ -n "$KEEP" ] && echo $W || rm -rf $W
