#!/bin/zsh
# A stagger's two new orders (GSAP's from: "random" and from: [x, y]): a rect's 10 copies in a row, Opacity keyed 0 to 1
# over 0.2 s and staggered 1 s. From a point at the row's middle, at 0.3 s the middle copies are seen and the ends are
# not; at random, by one seed and another, different copies are seen; from the start (as before), the left ones.
# Needs the inside built (edit.sh).
#   ./check/stagger_from.sh
cd "$(dirname "$0")/.."
W=$(mktemp -d "${TMPDIR:-/tmp}/stagger.XXXX"); [ -n "$KEEP" ] && W=$PWD/out/stagger_keep && rm -rf $W && mkdir -p $W
row='add shape rect\nset 1 size 0.06\nsay 1 fill ffc850\nset 1 copies 10\nset 1 copy_x 0.09\nset 1 stagger 1\nkeys 1 opacity 0 0 0.2 1\n'
printf "$row"'at 0.3\nstill %s/start.png\nsay 1 stagger_from point\nstill %s/point.png\nset 1 stagger_x 0.4\nstill %s/point_right.png\nsay 1 stagger_from random\nstill %s/random1.png\nset 1 seed 7\nstill %s/random2.png\n' $W $W $W $W $W | ./edit.sh $W/s.motolii > $W/log.txt 2>&1
python3 -c "
from PIL import Image
def seen(name):   # (which of the 10 copies are lit, left to right)
    im = Image.open('$W/%s.png' % name).convert('RGB'); w, h = im.size; px = im.load()
    lit = [any(px[x, y][0] > 180 and px[x, y][1] > 140 and px[x, y][2] < 120 for y in range(0, h, 4)) for x in range(w)]
    runs, x = [], 0
    while x < w:
        if lit[x]:
            x0 = x
            while x < w and lit[x]: x += 1
            runs.append((x0 + x) // 2); continue
        x += 1
    return runs
w = Image.open('$W/start.png').size[0]
start, point, right, r1, r2 = seen('start'), seen('point'), seen('point_right'), seen('random1'), seen('random2')
ok_start = 1 <= len(start) <= 5 and max(start) < w * 0.5
ok_point = 1 <= len(point) <= 5 and min(point) > w * 0.25 and max(point) < w * 0.75
ok_right = 1 <= len(right) <= 5 and min(right) > w * 0.5
ok_random = 1 <= len(r1) <= 8 and 1 <= len(r2) <= 8 and r1 != r2
print('stagger from the start, the left ones first: ' + ('yes' if ok_start else 'NO (%s of %d)' % (start, w)))
print('stagger from a point, the middle ones first: ' + ('yes' if ok_point else 'NO (%s of %d)' % (point, w)))
print('stagger from a point moved right, the right ones first: ' + ('yes' if ok_right else 'NO (%s of %d)' % (right, w)))
print('stagger at random, another seed another order: ' + ('yes' if ok_random else 'NO (%s / %s)' % (r1, r2)))
" || { echo "stagger_from: NO (its log:)"; tail -20 $W/log.txt; }
[ -n "$KEEP" ] && echo $W || rm -rf $W
