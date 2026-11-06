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
#   5. On a ring: eight copies turned round an anchor off their middle (Turn all 360: Cinema 4D's Cloner, Radial), the
#      order from the first: its neighbours next, the one across the ring last, each side alike (the places the order
#      counts from are where the copies are drawn, not where their rows would be).
#   6. A group of things picked together (Cmd+G: a Null each of them goes with), keyed once as one thing (its opacity),
#      an order from the start: the left one first, the right one last, whatever order they were made in (a group's
#      things are read where they lie; the user, 11/6: the order freed from letters and copies onto any group).
#   7. The order's place free, its spread signed (as the Transform and Anchor cards are free; GSAP's from: an index and
#      [x, y], Cinema 4D's field moved freely among the clones): counted in their order from the one at the place; the
#      middle turned round, the ends first; between the middle two of four, both first; by place, the nearest first and
#      the farthest last, as far as each lies between (GSAP's distribute: the First to last the label says).
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
# 5. On a ring: where its first lies asked, then the order from there.
ring='add shape rect\nset 1 size 0.05\nset 1 anchor_y 6\nset 1 copies 8\nset 1 copy_turn 360\nset 1 stagger 1\n'
printf "$ring"'members 1\n' | ./edit.sh $W/ring.motolii > $W/ring_laid.txt 2>&1
first=$(grep -E '^0 ' $W/ring_laid.txt | head -1)
printf 'say 1 stagger_from point\nset 1 stagger_x %s\nset 1 stagger_y %s\nmembers 1\n' $(echo $first | cut -d' ' -f2) $(echo $first | cut -d' ' -f3) | ./edit.sh $W/ring.motolii > $W/ring.txt 2>&1
# 6. A group: the right one made first, the left, the middle; the group keyed as one, its order from the start.
# 7. The order's place is free and its sign turns it round (the user, 11/6: the Transform and Anchor cards are free;
#    the critique: an order was a list of words carried from Copies): five copies in a row, a place given, counted in
#    their order from the one there; the middle with the spread less than 0, the ends first (what edges said); four, the
#    place between the middle two, both first; by place, from between two, as far as each lies; an older word (start)
#    given a place, in their order from there.
row='add shape rect\nset 1 size 0.05\nset 1 copies 5\nset 1 copy_x 0.2\nset 1 stagger 1\n'
printf "$row"'say 1 stagger_from order\nset 1 stagger_x 0.2\nmembers 1\n' | ./edit.sh $W/o_from.motolii > $W/o_from.txt 2>&1
printf "$row"'set 1 stagger -1\nsay 1 stagger_from order\nset 1 stagger_x 0\nmembers 1\n' | ./edit.sh $W/o_turned.motolii > $W/o_turned.txt 2>&1
printf 'add shape rect\nset 1 size 0.05\nset 1 copies 4\nset 1 copy_x 0.2\nset 1 stagger 1\nsay 1 stagger_from order\nset 1 stagger_x 0\nmembers 1\n' | ./edit.sh $W/o_even.motolii > $W/o_even.txt 2>&1
printf "$row"'say 1 stagger_from place\nset 1 stagger_x -0.3\nmembers 1\n' | ./edit.sh $W/o_place.motolii > $W/o_place.txt 2>&1
printf "$row"'say 1 stagger_from start\nset 1 stagger_x 0.4\nmembers 1\n' | ./edit.sh $W/o_older.motolii > $W/o_older.txt 2>&1
printf 'add shape rect\nset 1 size 0.1\nset 1 x 0.6\nsay 1 fill ffc850\nadd shape rect\nset 2 size 0.1\nset 2 x -0.6\nsay 2 fill ffc850\nadd shape rect\nset 3 size 0.1\nsay 3 fill ffc850\nadd shape null\nset 1 parent 4\nset 2 parent 4\nset 3 parent 4\nkeys 4 opacity 0 0 0.2 1\nset 4 stagger 1\nsay 4 stagger_from start\nmembers 4\nat 0.6\nstill %s/held_mid.png\nat 2\nstill %s/held_rest.png\n' $W $W | ./edit.sh $W/held.motolii > $W/held.txt 2>&1
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
lit = sorted((a + b) // 2 for a, b in mid)   # (half way: those lit are the far end of the row, the near end not yet (by place, the nearest moves first, as First to last says))
ok4 = len(rest) >= 8 and 1 <= len(lit) < len(centre) and all(abs(x - y) <= 6 for x, y in zip(lit, centre[len(centre) - len(lit):]))
print('in depth, from a point at the far end: the far ones first: ' + ('yes' if ok4 else 'NO (lit %s of %s)' % ([(a + b) // 2 for a, b in mid], centre)))
ring = {}
for line in open('$W/ring.txt'):
    w = line.split()
    if len(w) == 5 and w[0].isdigit(): ring[int(w[0])] = [float(v) for v in w[1:]]
d = [ring[i][3] for i in range(8)] if len(ring) == 8 else []
spread = len({(round(ring[i][0], 3), round(ring[i][1], 3)) for i in ring}) == 8
ok5 = len(d) == 8 and spread and d[0] == 0 and abs(d[4] - 1) < 1e-6 and all(abs(d[k] - d[8 - k]) < 1e-6 for k in range(1, 4)) and d[1] < d[2] < d[3] < d[4]
print('on a ring, from the first: its neighbours next, the one across last, each side alike: ' + ('yes' if ok5 else 'NO (apart: %s, later: %s)' % (spread, [round(v, 3) for v in d])))
held = {}
for line in open('$W/held.txt'):
    w = line.split()
    if len(w) == 5 and w[0].isdigit(): held[int(w[0])] = [float(v) for v in w[1:]]
rest = runs('held_rest', yellow)
(w, h), px = load('held_mid')
red = [px[(a + b) // 2, h // 2][0] for a, b in rest]   # (each one's red at its middle, half way through: in, coming in, not yet)
left = len(held) == 3 and held[0][0] < held[1][0] < held[2][0] and [round(held[i][3], 3) for i in range(3)] == [0, 0.5, 1]
ok6 = left and len(rest) == 3 and red[0] > 240 and 20 < red[1] < 220 and red[2] < 20
print('a group of things picked together, keyed as one, from the start: the left one first, the right one last: ' + ('yes' if ok6 else 'NO (members %s, red %s of %s)' % (held, red, rest)))
def later(name):
    got = {}
    for line in open('$W/%s.txt' % name):
        w = line.split()
        if len(w) == 5 and w[0].isdigit(): got[int(w[0])] = float(w[4])
    return [round(got[i], 3) for i in sorted(got)]
want = {'o_from': [1, 0.667, 0.333, 0, 0.333], 'o_turned': [0, 0.5, 1, 0.5, 0], 'o_even': [1, 0.333, 0.333, 1], 'o_place': [0, 0, 0.333, 0.667, 1], 'o_older': [1, 0.75, 0.5, 0.25, 0]}
got = {k: later(k) for k in want}
ok7 = all(got[k] == v for k, v in want.items())
print('the place free and the spread signed: from the one there, the ends first turned round, both middles of four, by place between two, an older word given a place: ' + ('yes' if ok7 else 'NO (%s)' % {k: got[k] for k in want if got[k] != want[k]}))
" || { echo "group: NO (its logs:)"; tail -5 $W/*.txt; }
[ -n "$KEEP" ] && echo $W || rm -rf $W
