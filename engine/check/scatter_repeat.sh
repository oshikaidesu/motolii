#!/bin/zsh
# Scatter Repeat (Alight Motion's; effects/scatter_repeat.am, made in absent_motion.cpp scatter_repeat) on a small white
# circle, against what Alight Motion 6.2.60 showed of it (reports/alight_checklist.md): Count copies lie in a disc of Radius
# about where the circle stood, and the circle itself stays at the middle as it does with the other repeats (the owner,
# 11/7: easier to read so); a copy keeps its place when Count grows; Evolution moves the copies smoothly; Range Transform's
# Scale on those in the Range. Stills, the blobs counted by python. (Count 1 lays nothing yet: one copy is not drawn apart
# from the thing, as Linear Repeat's one is not.)
#   ./check/scatter_repeat.sh      (KEEP=dir ./check/scatter_repeat.sh keeps the stills there)
cd "$(dirname "$0")/.."
W=${KEEP:-$(mktemp -d)}
mkdir -p $W
A=$PWD/effects/scatter_repeat.am P=js_scatter_repeat_
run() {   # (name, then the calls after it is on: Count 20, Radius 300 in the document's pixels, 640 across, unless said)
    local name=$1; shift
    print -l "add shape circle" "set 1 size 0.06" "set 1 duration 5" "say 1 fill ffffff" "later fx_file 1 $A" "$@" "at 0" "still $W/$name.png" | SIZE=640x360 ./edit.sh $W/$name.motolii > $W/$name.log 2>&1
}
print -l "add shape circle" "set 1 size 0.06" "set 1 duration 5" "say 1 fill ffffff" "at 0" "still $W/none.png" | SIZE=640x360 ./edit.sh $W/none.motolii > $W/none.log 2>&1
run n2 "set 1 ${P}count 2" "set 1 ${P}radius 150"
run n3 "set 1 ${P}count 3" "set 1 ${P}radius 150"
run n5 "set 1 ${P}count 5" "set 1 ${P}radius 150"
run e5 "set 1 ${P}count 5" "set 1 ${P}radius 150" "set 1 ${P}evolution 0.5"
run small "set 1 ${P}count 5" "set 1 ${P}radius 50"
run range "set 1 ${P}count 10" "set 1 ${P}radius 150" "set 1 ${P}rangeScale 0.3" "set 1 ${P}rangeEnd 0.5"
python3 - $W <<'PY'
import sys, numpy as np
from PIL import Image
from scipy import ndimage as ndi
W = sys.argv[1]
def blobs(name):
    a = np.asarray(Image.open(f'{W}/{name}.png').convert('L')).astype(int)
    m = np.abs(a - a[2, 2]) > 60   # (the corner is the ground)
    lab, n = ndi.label(m)
    c = ndi.center_of_mass(m, lab, range(1, n + 1)) if n else []
    s = ndi.sum(m, lab, range(1, n + 1)) if n else []
    return [(float(x), float(y), float(z)) for (y, x), z in zip(c, s)]
mid = (320.0, 180.0)
def d(p, q): return float(np.hypot(p[0] - q[0], p[1] - q[1]))
none, n2, n3, n5, e5, small, rng = (blobs(n) for n in 'none n2 n3 n5 e5 small range'.split())
R = 150   # (the document is 640 across, as the still: Radius 150 is 150 px of it)
ok = []
def check(name, good, why): ok.append(good); print(f'{name}: ' + ('yes' if good else 'NO') + f' ({why})')
def copies(b): return [p for p in b if d(p, mid) > 3]
def old(b): return [p for p in b if d(p, mid) <= 3]
check('the circle alone is one blob at the middle', len(none) == 1 and d(none[0], mid) < 3, f'{len(none)} blobs')
check('Count 2, 3, 5 each keep the circle at the middle and lay Count copies about it', all(len(old(b)) == 1 and len(copies(b)) == n for b, n in ((n2, 2), (n3, 3), (n5, 5))), f'{len(n2)}, {len(n3)}, {len(n5)} blobs')
check('every copy is inside the disc of Radius', all(d(p, mid) <= R + 3 for p in copies(n5)), f'farthest {max(d(p, mid) for p in copies(n5)):.1f} of {R} px')
check('a copy keeps its place when Count grows', all(any(d(p, q) < 1.5 for q in n3) for p in n2) and all(any(d(p, q) < 1.5 for q in n5) for p in n3), 'Count 2 in 3 in 5')
check('Evolution moves every copy and leaves the circle', len(old(e5)) == 1 and all(min(d(p, q) for q in copies(n5)) > 1.5 for p in copies(e5)), f'{len(copies(e5))} copies')
check('a smaller Radius keeps the copies nearer', max(d(p, mid) for p in copies(small)) <= 50 + 3 and max(d(p, mid) for p in copies(n5)) > 60, f'{max(d(p, mid) for p in copies(small)):.1f} against {max(d(p, mid) for p in copies(n5)):.1f} px')
sizes = sorted(s for _, _, s in rng)
check('Range Scale 0.3 over half the copies makes those smaller', len(rng) >= 6 and sizes[0] < 0.5 * sizes[-1], f'smallest {sizes[0]:.0f}, largest {sizes[-1]:.0f} px' if sizes else 'none')
print('all: ' + ('yes' if all(ok) else 'NO'))
PY
[ -z "$KEEP" ] && rm -rf $W
