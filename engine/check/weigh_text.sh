#!/bin/zsh
# weigh.h on real text: "TEXTON" split into its letters, given each of the three presets in weighs/ (Texton's shape:
# a travel, a duration, an offset across the letters, an ease, in and out), drawn by the real stage. Slide In: at 0.3 s
# the left letters are in and the right ones are not yet seen; at 1.5 s all six are, in a row. Rise Out (the thing
# lasting 3 s): at 2.55 s the left letters are gone and the right ones are rising. Needs the inside built (edit.sh).
#   ./check/weigh_text.sh
cd "$(dirname "$0")/.."
W=$(mktemp -d "${TMPDIR:-/tmp}/weigh.XXXX"); [ -n "$KEEP" ] && W=$PWD/out/weigh_keep_text && rm -rf $W && mkdir -p $W   # (KEEP=1: left in out/ to look at; fresh, or the last run's document would still be in it)
ln -sf "/System/Library/Fonts/Supplemental/Arial Black.ttf" $W/arial_black.ttf
slide=$(tr -d '\n' < "weighs/Slide In.weigh")
rise=$(tr -d '\n' < "weighs/Rise Out.weigh")
printf 'add text %s/arial_black.ttf\nsay 1 text TEXTON\nsay 1 fill ffc850\nset 1 size 0.25\nsay 1 split letters\nset 1 duration 3\nsay 1 weigh %s\nat 0.3\nstill %s/t0.png\nat 1.5\nstill %s/t1.png\nsay 1 weigh %s\nat 1.5\nstill %s/t2.png\nat 2.55\nstill %s/t3.png\n' $W "$slide" $W $W "$rise" $W $W | ./edit.sh $W/weigh_text.motolii > $W/log.txt 2>&1
python3 -c "
from PIL import Image
def blobs(i):   # (runs of lit columns: one a letter (T E X T O N: six); and each run's top)
    im = Image.open('$W/t%d.png' % i).convert('RGB'); w, h = im.size; px = im.load()
    lit = [any(px[x, y][0] > 180 and px[x, y][1] > 140 and px[x, y][2] < 120 for y in range(0, h, 3)) for x in range(w)]
    runs, x = [], 0
    while x < w:
        if lit[x]:
            x0 = x
            while x < w and lit[x]: x += 1
            mid = (x0 + x) // 2
            top = next((y for y in range(h) if px[mid, y][0] > 180 and px[mid, y][1] > 140 and px[mid, y][2] < 120), h)
            runs.append((x0, x, top)); continue
        x += 1
    return runs
w = Image.open('$W/t1.png').size[0]
b0, b1, b2, b3 = blobs(0), blobs(1), blobs(2), blobs(3)
ok_in = 1 <= len(b0) <= 4 and b0[-1][1] < 0.6 * w and 5 <= len(b1) <= 8 and max(abs(r[2] - b1[0][2]) for r in b1) < 60   # (a few on the left, then all (a letter may be two runs), level but for a letter's own height)
ok_out = 5 <= len(b2) <= 8 and 1 <= len(b3) < len(b2) and b3[0][0] > 0.35 * w   # (all; then fewer, only on the right: the left ones have risen and gone)
print('weigh on split text, Slide In (weighs/): ' + ('yes' if ok_in else 'NO (%d then %d letters: %s / %s)' % (len(b0), len(b1), b0, b1)))
print('weigh on split text, Rise Out from the end: ' + ('yes' if ok_out else 'NO (%d then %d letters: %s / %s)' % (len(b2), len(b3), b2, b3)))
" || { echo "weigh on split text: NO (its log:)"; tail -20 $W/log.txt; }
[ -n "$KEEP" ] && echo $W || rm -rf $W
