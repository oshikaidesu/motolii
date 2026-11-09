#!/bin/zsh
# Each effect's picture, for its tile on the Effects shelf: one sample (a hot air balloon, fx_sample.jpg, drifting slowly,
# and a white Aa over it) with the effect on. A whole-screen effect's is written beside it (distort/twirl.wgsl ->
# distort/twirl.png); a thing's effect (the inside's own, put on the Aa) as thing_<its value>.png in the folder its
# last one was in (doc_fx_put.h finds it in any folder: script_shelf_file); a new one in effects/ itself, to be put
# into its folder by hand as f8925af9c sorted them. Run by hand; nothing builds it. (in engine/ until 416fced3a.)
#   shelves/effects/sources/fx_tiles.sh [shelves/effects/distort/am_bulge.wgsl ...]
# fx_sample.jpg: "Mid-Hudson balloon festival 15" by Juliancolton, public domain (PD-self), Wikimedia Commons, cut square.
fx=(${${@:-${0:a:h}/../*/*.wgsl}:a})   # (as given, or every .wgsl on the shelf, before cd)
cd "$(dirname "$0")/../../../engine"
E=${PWD:h}/shelves/effects
doc=$(mktemp -d)/tiles.motolii
(( $# )) || { old=($E/*/thing_*.png(N)); rm -f $old; }   # (made again, none left from before; where each was is kept)
(( $# )) || things=$(echo effects | ./edit.sh $(mktemp -d)/list.motolii | grep "	")   # (the inside's own effects: name, value, ...)
{
    echo "add picture $E/sources/fx_sample.jpg"; echo "set 1 size 3.6"; echo "key 1 x 0 -0.1"; echo "key 1 x 2 0.1"
    echo "add text /System/Library/Fonts/Supplemental/Arial Black.ttf"; echo "say 2 text Aa"; echo "say 2 fill ffffff"; echo "set 2 size 1"; echo "set 2 y -0.55"
    echo "at 1.4"
    for f in $fx; do
        echo "say 0 script $f"
        n=$(sed -n 's/.*--history@\([0-9]*\).*/\1/p' $f | head -1)   # (an effect of what was: as many pictures before as its head says it keeps, one a frame)
        grep -q '"PERSISTENT": *\(true\|1\)' $f && n=84   # (an ISF that keeps its frame before (PERSISTENT): every frame from the start, as it plays)
        for (( k = ${n:-0}; k > 0; k-- )); do echo "at $(( 1.4 - k / 60.0 ))"; echo "still $doc.warm.png"; done
        echo "at 1.4"
        echo "still ${f:r}.png"
    done
    echo "say 0 script none"
    echo "at 1.9"; echo "still $doc.png"; echo "at 1.4"   # (the sample as it is, to tell a picture that shows nothing done)
    print -r -- "$things" | while IFS=$'\t' read -r name value _; do
        [[ -n $name ]] || continue
        echo "effect 2 $name"
        echo "at 1.9"   # (half a second on: what it does from where it is put, Trim Paths drawing on)
        at=${${(M)old:#*/thing_$value.png}:-$E/thing_$value.png}   # (its folder from before, else effects/ itself)
        echo "still $at"
        echo "at 1.4"
        echo "effect 2 $name"   # (off again: the next one alone)
    done
} | SIZE=512x512 ./edit.sh $doc | grep -v "^still: done\|^say: done\|^set: done\|^key: done\|^add: done\|^effect: done\|^thing "
for f in $E/thing_*.png(N) $E/*/thing_*.png(N); do cmp -s $f $doc.png && rm $f; done   # (the same as the sample: that effect is not seen on it, the shelf draws its own)
for f in $E/thing_*.png(N); do echo "new: $f (put it into its folder)"; done
for f in $fx $E/thing_*.png(N) $E/*/thing_*.png(N); do sips -Z 256 "${f:r}.png" >/dev/null; done   # (drawn at twice the tile, made small: the letters' edges stay clean)
