#!/bin/zsh
# The group as its user sees it: many things moved by the same hand as one; the only new thing is the order (who moves
# first), and a preset is that multiplication kept (its keys, its way, its order), changed after by the same hand.
# Each check is one sentence of that, on the real stage:
#   1. By hand: a text split into its letters, one pair of keys on y (0.3 to 0 over 0.5 s) with one way (BounceOut), an
#      order from the centre: the middle letters land first, the outer ones come last (Texton's In, After Effects'
#      Range Selector from the centre, GSAP's from: "center").
#   2. Kept and dropped: that thing kept as a look and put on another text gives the same picture (a preset is the
#      multiplication kept: Texton's presets, After Effects' Animation Presets).
#   3. A preset from the shelf (Bounce In, Cavalry's Animator) is that multiplication too: once dropped, the same hand
#      changes its order (from the centre: the middle letters are down first).
#   4. In depth: copies laid into the picture, the order from a point at the far end: the far ones first (Cinema 4D's
#      Plain Effector Time Offset through a spherical field: the clones' own places, depth too).
# Needs the inside built (edit.sh).
#   ./check/group.sh            (KEEP=1 keeps the pictures in out/group_keep)
cd "$(dirname "$0")/.."
W=$(mktemp -d "${TMPDIR:-/tmp}/group.XXXX"); [ -n "$KEEP" ] && W=$PWD/out/group_keep && rm -rf $W && mkdir -p $W
F=$PWD/out/arial_black.ttf
letters='add text %s\nsay 1 fill ffffff\nset 1 size 0.12\nsay 1 split letters\n'
word() { sqlite3 $1 "update fact set value = 'TEXTON' where thing = 1 and name = 'text'"; }
# 1. By hand.
printf "$letters" $F | ./edit.sh $W/hand.motolii > $W/hand.txt 2>&1; word $W/hand.motolii
printf 'keys 1 y 0 0.3 0.5 0\nway 1 y 0 BounceOut\nset 1 stagger 0.6\nsay 1 stagger_from centre\nat 0.5\nstill %s/hand_mid.png\nat 2\nstill %s/rest.png\nlook save 1 %s/kept.motolii\n' $W $W $W | ./edit.sh $W/hand.motolii >> $W/hand.txt 2>&1
# 2. Kept and dropped on another text.
printf "$letters" $F | ./edit.sh $W/put.motolii > $W/put.txt 2>&1; word $W/put.motolii
printf 'look put 1 %s/kept.motolii\nat 0.5\nstill %s/put_mid.png\n' $W $W | ./edit.sh $W/put.motolii >> $W/put.txt 2>&1
kept=$(magick compare -metric AE -fuzz 2% $W/hand_mid.png $W/put_mid.png null: 2>&1 | cut -d' ' -f1)
# 3. Bounce In from the shelf, then its order changed by hand.
printf "$letters"'say 1 script %s/animators/bounce_in.js\n' $F $PWD | ./edit.sh $W/shelf.motolii > $W/shelf.txt 2>&1; word $W/shelf.motolii
printf 'say 1 stagger_from centre\nat 0.67\nstill %s/shelf_mid.png\nat 3\nstill %s/shelf_rest.png\n' $W $W | ./edit.sh $W/shelf.motolii >> $W/shelf.txt 2>&1
# 4. In depth: ten copies, each a step right and a step further in; the order from a point in the row's middle across
#    but at its far end in depth.
printf 'add shape rect\nset 1 space 3\nset 1 size 0.06\nsay 1 fill ffc850\nset 1 copies 10\nset 1 copy_x 0.09\nset 1 copy_z -0.15\nset 1 stagger 1\nkeys 1 opacity 0 0 0.2 1\nsay 1 stagger_from point\nset 1 stagger_z -0.675\nat 0.5\nstill %s/deep_mid.png\nat 3\nstill %s/deep_rest.png\n' $W $W | ./edit.sh $W/deep.motolii > $W/deep.txt 2>&1
python3 -c "
from PIL import Image
def load(name):
    im = Image.open('$W/%s.png' % name).convert('RGB'); return im.size, im.load()
def runs(name, lit):   # (the lit runs across, left to right: (first x, last x))
    (w, h), px = load(name)
    on = [any(lit(px[x, y]) for y in range(0, h, 2)) for x in range(w)]
    out, x = [], 0
    while x < w:
        if on[x]:
            x0 = x
            while x < w and on[x]: x += 1
            out.append((x0, x - 1)); continue
        x += 1
    return out
white = lambda p: p[0] > 200 and p[1] > 200 and p[2] > 200
yellow = lambda p: p[0] > 180 and p[1] > 140 and p[2] < 120
def letters(name):   # (the six letters at rest; joined ones cut into six even bands)
    r = runs(name, white)
    if len(r) != 6 and r:
        a, b = r[0][0], r[-1][1]; r = [(a + (b - a) * k // 6, a + (b - a) * (k + 1) // 6) for k in range(6)]
    return r
def heights(name, bands):   # (each letter's lit middle, down the picture; None where none is lit)
    (w, h), px = load(name); out = []
    for a, b in bands:
        ys = [y for x in range(a, b + 1, 2) for y in range(0, h, 2) if white(px[x, y])]
        out.append(sum(ys) / len(ys) if ys else None)
    return out
def middle_first(mid, rest):   # (the middle two lower than the outer two: landed first)
    bands = letters(rest)
    if len(bands) != 6: return False, 'no six letters at rest (%d)' % len(bands)
    y = heights(mid, bands)
    if y[2] is None or y[3] is None: return False, 'the middle letters not seen %s' % y
    outer = [v for v in (y[0], y[5]) if v is not None]
    return all(v < min(y[2], y[3]) - 6 for v in outer), 'down the picture %s' % ['-' if v is None else int(v) for v in y]
ok1, why1 = middle_first('hand_mid', 'rest')
print('by hand, one pair of keys and one way on the group, from the centre: the middle letters land first: ' + ('yes' if ok1 else 'NO (%s)' % why1))
print('kept as a look and put on another text, the same picture: ' + ('yes' if $kept < 500 else 'NO ($kept pixels apart)'))
ok3, why3 = middle_first('shelf_mid', 'shelf_rest')
print('Bounce In from the shelf, its order changed by the same hand (from the centre): ' + ('yes' if ok3 else 'NO (%s)' % why3))
rest, mid = runs('deep_rest', yellow), runs('deep_mid', yellow)
centre = sorted((a + b) // 2 for a, b in rest)
ok4 = len(rest) >= 8 and 1 <= len(mid) <= 4 and min((a + b) // 2 for a, b in mid) > centre[len(centre) // 2]
print('in depth, from a point at the far end: the far ones first: ' + ('yes' if ok4 else 'NO (lit %s of %s)' % ([(a + b) // 2 for a, b in mid], centre)))
" || { echo "group: NO (its logs:)"; tail -5 $W/*.txt; }
[ -n "$KEEP" ] && echo $W || rm -rf $W
