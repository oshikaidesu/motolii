#!/bin/zsh
# weigh.h in the document: a rect's 10 copies in a row, told a weigh value (JSON: Fade In, Time over Index), drawn by
# the real stage at three moments. At 0 s none is seen; at 0.5 s the left ones are and the right ones are not; at 2 s
# all are. Then a Distance weight lifts the middle copies and leaves the ends. Needs the inside built (edit.sh).
#   ./check/weigh_doc.sh
cd "$(dirname "$0")/.."
W=$(mktemp -d "${TMPDIR:-/tmp}/weigh.XXXX"); [ -n "$KEEP" ] && W=$PWD/out/weigh_keep_doc && rm -rf $W && mkdir -p $W   # (KEEP=1: left in out/ to look at; fresh, or the last run's document would still be in it)
fade='[{"target":"opacity","op":"Set","value":0},{"weight":{"kind":"Time","a":0,"b":0.5,"delay":1,"in":[{"kind":"Index"}]},"target":"opacity","op":"Set","value":1}]'
lift='[{"weight":{"kind":"Distance","at":[0,0,0],"a":0.03,"b":0.13},"target":"y","op":"Add","value":0.15}]'
printf 'add shape rect\nset 1 size 0.06\nsay 1 fill ffc850\nset 1 copies 10\nset 1 copy_x 0.09\nsay 1 weigh %s\nat 0\nstill %s/w0.png\nat 0.5\nstill %s/w1.png\nat 2\nstill %s/w2.png\nsay 1 weigh %s\nstill %s/w3.png\n' "$fade" $W $W $W "$lift" $W | ./edit.sh $W/weigh.motolii > $W/log.txt 2>&1
python3 -c "
from PIL import Image
def blobs(i):   # (the lit columns of a still, as runs of x: one run a copy; and the top of each)
    im = Image.open('$W/w%d.png' % i).convert('RGB'); w, h = im.size; px = im.load()
    lit = [any(px[x, y][0] > 180 and px[x, y][1] > 140 and px[x, y][2] < 120 for y in range(0, h, 4)) for x in range(w)]
    runs, x = [], 0
    while x < w:
        if lit[x]:
            x0 = x
            while x < w and lit[x]: x += 1
            mid = (x0 + x) // 2
            top = next((y for y in range(h) if px[mid, y][0] > 180 and px[mid, y][1] > 140 and px[mid, y][2] < 120), h)
            runs.append((x0, x, top))
        x += 1
    return runs
b0, b1, b2, b3 = blobs(0), blobs(1), blobs(2), blobs(3)
ok0 = len(b0) == 0
ok1 = 1 <= len(b1) <= 6 and b1[-1][1] < 0.5 * Image.open('$W/w2.png').size[0]   # (some, on the left half only)
ok2 = len(b2) == 10
ok3 = len(b3) == 10 and b3[5][2] < b3[0][2] - 10 and abs(b3[0][2] - b3[9][2]) < 4   # (the middle higher than the ends, the ends level)
print('weigh in the document, Fade In by Time over Index: ' + ('yes' if ok0 and ok1 and ok2 else 'NO (%d, %d, %d copies seen)' % (len(b0), len(b1), len(b2))))
print('weigh in the document, a Distance lifts the middle: ' + ('yes' if ok3 else 'NO (%s)' % (b3,)))
" || { echo "weigh in the document: NO (its log:)"; tail -20 $W/log.txt; }
[ -n "$KEEP" ] && echo $W || rm -rf $W
