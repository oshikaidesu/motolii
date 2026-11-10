#!/bin/zsh
# Every shelf item draws as it did at an older commit (docs/TESTING.md, 今ある書類の見た目が変わらない). The engine at
# <old-commit> (built in a place of its own) and the engine of this checkout each draw every recipe of the Create shelf (create <name>) and every motion of the Effects shelf
# (a text MOTOLII in a font, given it as its script) on a fresh document, at 0.0, 0.7 and 1.9 seconds; each pair of
# pictures is compared with cmp, as the 11/8 old-and-new comparison was. Prints each that differs and how many matched;
# one only one side has is named and not compared. A call either side refuses, or a picture not made, stops the count
# from standing: it says which and ends with 2 (1: some differ; 0: all matched).
#   ./drawings_unchanged.sh ed4868cf1          (DRAWINGS_LIMIT=2 ./drawings_unchanged.sh ed4868cf1: the first two of each only)
# Three parts, and only the first holds the build lock:
#   build    this checkout's engine, and the old one's unless its pictures are kept (below): each once, not once per picture
#   draw     the built engines (out/edit_wgpu) called directly; no build.sh in between, the lock let go
#   compare  cmp of two PNGs; nothing of the engine
# The old engine's pictures are kept in out/drawings/<old commit>-<time of out/deps.stamp>-<limit>: the same old commit is
# built and drawn once, then only this checkout is drawn. Only the newest such folder is kept; rm -rf out/drawings to forget.
# Nothing of the maker's own is read or written: MOTOLII_OWN is an empty folder of its own (document/scripts/folders.h doc_folders), the
# documents are made in a temporary folder, and engine/out/skin.motolii is not opened.
old=${1:?usage: ./drawings_unchanged.sh <old-commit>}
cd "$(dirname "$0")"
source tools/build_lock.sh; build_lock "$@"   # (the machine's one build lock, taken here: tools/build_lock.sh)
here=$PWD
oldhash=$(git rev-parse -q --verify "$old^{commit}") || { echo "no such commit: $old"; exit 1; }
tmp=$(mktemp -d -t drawings_unchanged) || exit 1
oldtree=$tmp/old
trap 'git -C "$here" worktree remove --force "$oldtree" 2> /dev/null; rm -rf "$tmp"' EXIT INT TERM
mkdir -p $tmp/own $tmp/docs $tmp/frames
export MOTOLII_OWN=$tmp/own   # (no maker's recipes, motions or looks: the library's alone, the same on both sides)

# (the old side's pictures change with what it was built from: the old commit, and the shared third_party as deps.stamp last saw it)
cache=$here/out/drawings/$oldhash-$(stat -f %m out/deps.stamp 2> /dev/null || echo 0)-${DRAWINGS_LIMIT:-all}
rm -rf $cache.part
kept=0; [ -f $cache/done ] && kept=1

# BUILD. The old engine: its commit checked out apart; the heavy sources not kept in git (third_party) are this checkout's,
# linked; what is built once and not from the engine's own files (out/*.o, materials, lights) copied, made again if older.
engines=($oldtree/engine $here)
if (( ! kept )); then
    echo "building the engine at $old ..."
    git -C "$here" worktree add --detach -q "$oldtree" "$old" || exit 1
    for e in third_party/*(N); do [ -e $oldtree/engine/$e ] || ln -s ${e:A} $oldtree/engine/$e; done
    mkdir -p $oldtree/engine/out/filament_webgpu/out
    for f in out/*.o(N) out/filament_webgpu/*.filamat(N); do cp -p $f $oldtree/engine/$f; done
    for d in lightroom small_studio graffiti_shelter_2k studio_small_02_2k venetian_crossroads_2k parking_garage_2k pillars_2k; do [ -d out/$d ] && cp -Rp out/$d $oldtree/engine/out/; done
    # (the old commit's own materials are made here; the dependency scripts, which write the shared third_party that is
    # this checkout's and already built, are not run: the stamp tells build.sh so. If the materials fail, build.sh does all.)
    (cd $oldtree/engine && ./materials/build.sh && touch out/deps.stamp) > $tmp/build.log 2>&1
    (cd $oldtree/engine && ./build.sh) >> $tmp/build.log 2>&1
    [ -x $oldtree/engine/out/edit_wgpu ] || { echo "the engine at $oldtree/engine could not be built:"; tail -20 $tmp/build.log; exit 1; }
fi
./build.sh > $tmp/build.log 2>&1
[ -x $here/out/edit_wgpu ] || { echo "the engine at $here could not be built:"; tail -20 $tmp/build.log; exit 1; }
build_unlock   # (what is left only draws; nothing shared is written)
if (( kept )); then echo "built; the old side's pictures are kept ($cache); drawing ..."; else echo "built; drawing ..."; fi

# DRAW. edit.sh without its ./build.sh (that built again, once per document: done above, once).
run() {   # (engine folder, document)
    local doc=${2:a}
    (cd $1/out/filament_webgpu && BACKEND="${BACKEND:-webgpu}" ../edit_wgpu $doc 2>&1 | grep -v "FrameInfo's circular queue\|libvulkan\|BackendVk\|FEngine\|WebGPU adapter\|Backend feature")
}
idof() { print -rn -- "$1" | md5 -q; }   # (a name's picture files; the item's place in a list moves when the shelf does)

# What each shelf has, on either side. One only one side has is not compared (nothing stands for it on the other): its
# name is said, as new since <old-commit> or gone since, and it neither counts as matched nor fails.
# (a document of each side's own: one the old engine made, the new one did not list from, and the list was the old's alone)
names() { echo create_scripts | run $engines[$1] $tmp/docs/names_$1.motolii 2> /dev/null | sed 's/^  //' | cut -f1 | grep -v '^$'; }
typeset -A has   # (side and name: 1 where that side has it)
for side in 1 2; do
    if (( kept && side == 1 )); then
        for r in "${(@f)$(<$cache/recipes.txt)}"; do [ -n "$r" ] && has[1:recipe:${r}]=1; done
        for f in "${(@f)$(<$cache/motions.txt)}"; do [ -n "$f" ] && has[1:motion:${f}]=1; done
        continue
    fi
    for r in "${(@f)$(names $side)}"; do [ -n "$r" ] && has[${side}:recipe:${r}]=1; done
    for f in $engines[$side]/animators/*.js(N:t) $engines[$side]/../shelves/{animators,expressions}/*.js(N:t); do has[${side}:motion:${f}]=1; done
done
recipes=("${(@f)$(for k in ${(k)has}; do [[ $k = ?:recipe:* ]] && print -r -- ${k#?:recipe:}; done | sort -u)}")
motions=("${(@f)$(for k in ${(k)has}; do [[ $k = ?:motion:* ]] && print -r -- ${k#?:motion:}; done | sort -u)}")
keys=(${(k)has})
for side in 1 2; do listed=(${(M)keys:#${side}:recipe:*}); [ ${#listed} -gt 0 ] || { echo "the engine at $engines[$side] listed no recipes"; exit 2; }; done
[ -n "$DRAWINGS_LIMIT" ] && recipes=(${recipes[1,$DRAWINGS_LIMIT]}) motions=(${motions[1,$DRAWINGS_LIMIT]})   # (DRAWINGS_LIMIT=2: the first so many of each, to see that it runs)

# A motion is given to a text of letters the engine draws (a font, then its words), split by letter as its script
# splits it: "add text MOTOLII" alone is a file of that name, refused, and both sides drew nothing (11/9: 351 of 351
# matched with every motion's pictures empty on both sides)
font=$here/third_party/filament_src/assets/fonts/Roboto-Medium.ttf
[ -f $font ] || { echo "no font for the motions' text: $font"; exit 1; }

times=(0.0 0.7 1.9)
same=0 differ=() refused=() lone=()
frames=($cache.part/frames $tmp/frames)   # (side 1's: made here, then kept; or the kept ones)
(( kept )) && frames[1]=$cache/frames
mkdir -p $frames[1] $frames[2]
draw() {   # (side, item id, the calls that put it on, its name: a fresh document, each moment drawn; what was refused, or a picture not made, said)
    local e=$engines[$1] f=$frames[$1] doc=$tmp/docs/$2_$1.motolii log=$tmp/docs/$2_$1.log sides=(old new)
    rm -f $doc
    { print -r -- "$3"; for t in $times; do print "at $t"; print "still $f/$2_$t.png"; done } | run $e $doc > $log 2>&1
    grep -q 'NOT done' $log && refused+=("$4 on the $sides[$1] side: $(grep -m1 'NOT done' $log)")
    local said=("${(@f)3}")
    local sent=$(( ${#said} + 2 * ${#times} )) answered=$(grep -cE '^[a-z_]+: (done|NOT done)' $log)   # (an engine that stopped answers none of the rest, and says no NOT done: a font it could not read, 11/9)
    [ $answered -lt $sent ] && refused+=("$4 on the $sides[$1] side: the engine answered $answered of $sent calls: $(grep -vE '^(sampler|\[)' $log | tail -1)")
    for t in $times; do [ -s $f/$2_$t.png ] || refused+=("$4 on the $sides[$1] side: no picture at $t"); done
}
motion_calls() {   # (side, file): the calls that put a motion on the text
    print -r -- "add text $font
say 1 text MOTOLII
say 1 script $(ls $engines[$1]/animators/$2 $engines[$1]/../shelves/{animators,expressions}/$2 2> /dev/null | head -1)"
}
draw_side() {   # (side): every item that side has
    local r f
    for r in $recipes; do [ -n "${has[${1}:recipe:${r}]}" ] && draw $1 r_$(idof $r) "create $r" "recipe $r"; done
    for f in $motions; do [ -n "${has[${1}:motion:${f}]}" ] && draw $1 m_$(idof $f) "$(motion_calls $1 $f)" "motion ${f:r}"; done
    return 0
}
(( kept )) || draw_side 1
if (( ! kept && ${#refused} == 0 )); then   # (kept only when every old picture was made: the next run trusts them)
    for k in ${(k)has}; do [[ $k = 1:recipe:* ]] && print -r -- ${k#1:recipe:}; done | sort -u > $cache.part/recipes.txt
    for k in ${(k)has}; do [[ $k = 1:motion:* ]] && print -r -- ${k#1:motion:}; done | sort -u > $cache.part/motions.txt
    touch $cache.part/done
    for d in $here/out/drawings/*(N); do [ $d != $cache.part ] && rm -rf $d; done   # (only the newest is kept)
    mkdir -p $here/out/drawings && mv $cache.part $cache && frames[1]=$cache/frames
fi
draw_side 2

# COMPARE.
compare() {   # (item id, its name)
    for t in $times; do
        if [ -s $frames[1]/$1_$t.png ] && cmp -s $frames[1]/$1_$t.png $frames[2]/$1_$t.png; then same=$((same + 1)); else differ+=("$2 at $t"); fi
    done
}
alone() {   # (kind, name): one side only has it
    [ -n "${has[1:${1}:${2}]}" ] && [ -n "${has[2:${1}:${2}]}" ] && return 1
    lone+=("$1 $2: ${${has[2:${1}:${2}]:+new since $old}:-gone since $old}, not compared")
}
compared=0
for r in $recipes; do
    alone recipe $r && continue
    compare r_$(idof $r) "recipe $r"
    compared=$((compared + 1))
done
for f in $motions; do
    alone motion $f && continue
    compare m_$(idof $f) "motion ${f:r}"
    compared=$((compared + 1))
done

echo "$same of $(( compared * ${#times} )) matched ($compared compared of ${#recipes} recipes and ${#motions} motions, ${#times} moments each)"
for d in $differ; do echo "differs: $d"; done
for l in $lone; do echo "one side only: $l"; done
if [ ${#refused} -gt 0 ]; then   # (a picture of nothing on both sides would match: no count stands while one was not drawn)
    echo "NOT CHECKED: ${#refused} placement(s) refused or picture(s) not made; the count above does not stand:"
    for r in $refused; do echo "  refused: $r"; done
    exit 2
fi
[ ${#differ} -eq 0 ]
