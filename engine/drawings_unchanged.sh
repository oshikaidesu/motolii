#!/bin/zsh
# Every shelf item draws as it did at an older commit (docs/TESTING.md, 今ある書類の見た目が変わらない). The engine at
# <old-commit> (built in a place of its own) and the engine of this checkout each draw every recipe of the Create shelf (make <name>) and every motion of the Effects shelf
# (a text MOTOLII in a font, given it as its script) on a fresh document, at 0.0, 0.7 and 1.9 seconds; each pair of
# pictures is compared with cmp, as the 11/8 old-and-new comparison was. Prints each that differs and how many matched;
# one only one side has is named and not compared. A call either side refuses, or a picture not made, stops the count
# from standing: it says which and ends with 2 (1: some differ; 0: all matched).
#   ./drawings_unchanged.sh ed4868cf1          (DRAWINGS_LIMIT=2 ./drawings_unchanged.sh ed4868cf1: the first two of each only)
# Nothing of the maker's own is read or written: MOTOLII_OWN is an empty folder of its own (document/doc_folders.h doc_folders), the
# documents are made in a temporary folder, and engine/out/skin.motolii is not opened.
old=${1:?usage: ./drawings_unchanged.sh <old-commit>}
cd "$(dirname "$0")"
source deps/build_lock.sh; build_lock "$@"   # (the machine's one build lock, taken here: deps/build_lock.sh)
here=$PWD
git rev-parse -q --verify "$old^{commit}" > /dev/null || { echo "no such commit: $old"; exit 1; }
tmp=$(mktemp -d -t drawings_unchanged) || exit 1
oldtree=$tmp/old
trap 'git -C "$here" worktree remove --force "$oldtree" 2> /dev/null; rm -rf "$tmp"' EXIT INT TERM
mkdir -p $tmp/own $tmp/docs $tmp/frames
export MOTOLII_OWN=$tmp/own   # (no maker's recipes, motions or looks: the library's alone, the same on both sides)

# The old engine: its commit checked out apart; the heavy sources not kept in git (third_party) are this checkout's,
# linked; what is built once and not from the engine's own files (out/*.o, materials, lights) copied, made again if older.
echo "building the engine at $old ..."
git -C "$here" worktree add --detach -q "$oldtree" "$old" || exit 1
for e in third_party/*(N); do [ -e $oldtree/engine/$e ] || ln -s ${e:A} $oldtree/engine/$e; done
mkdir -p $oldtree/engine/out/wgpu_kit/out
for f in out/*.o(N) out/wgpu_kit/*.filamat(N); do cp -p $f $oldtree/engine/$f; done
for d in lightroom small_studio graffiti_shelter_2k studio_small_02_2k venetian_crossroads_2k parking_garage_2k pillars_2k; do [ -d out/$d ] && cp -Rp out/$d $oldtree/engine/out/; done
engines=($oldtree/engine $here)
for e in $engines; do
    echo "" | (cd $e && ./edit.sh $tmp/docs/built.motolii) > $tmp/build.log 2>&1
    [ -x $e/out/edit_wgpu ] || { echo "the engine at $e could not be built:"; tail -20 $tmp/build.log; exit 1; }
done
echo "built; drawing ..."

# What each shelf has, on either side. One only one side has is not compared (nothing stands for it on the other): its
# name is said, as new since <old-commit> or gone since, and it neither counts as matched nor fails.
# (a document of each side's own: one the old engine made, the new one did not list from, and the list was the old's alone)
names() { echo recipes | (cd $engines[$1] && ./edit.sh $tmp/docs/names_$1.motolii) 2> /dev/null | sed 's/^  //' | cut -f1 | grep -v '^$'; }
typeset -A has   # (side and name: 1 where that side has it)
for side in 1 2; do
    for r in "${(@f)$(names $side)}"; do [ -n "$r" ] && has[${side}:recipe:${r}]=1; done
    for f in $engines[$side]/animators/*.js(N:t) $engines[$side]/../shelves/animators/*.js(N:t); do has[${side}:motion:${f}]=1; done
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
draw() {   # (side, item number, the calls that put it on, its name: a fresh document, each moment drawn; what was refused, or a picture not made, said)
    local e=$engines[$1] doc=$tmp/docs/$2_$1.motolii log=$tmp/docs/$2_$1.log sides=(old new)
    rm -f $doc
    { print -r -- "$3"; for t in $times; do print "at $t"; print "still $tmp/frames/$2_$1_$t.png"; done } | (cd $e && ./edit.sh $doc) > $log 2>&1
    grep -q 'NOT done' $log && refused+=("$4 on the $sides[$1] side: $(grep -m1 'NOT done' $log)")
    local said=("${(@f)3}")
    local sent=$(( ${#said} + 2 * ${#times} )) answered=$(grep -cE '^[a-z_]+: (done|NOT done)' $log)   # (an engine that stopped answers none of the rest, and says no NOT done: a font it could not read, 11/9)
    [ $answered -lt $sent ] && refused+=("$4 on the $sides[$1] side: the engine answered $answered of $sent calls: $(grep -vE '^(sampler|\[)' $log | tail -1)")
    for t in $times; do [ -s $tmp/frames/$2_$1_$t.png ] || refused+=("$4 on the $sides[$1] side: no picture at $t"); done
}
compare() {   # (item number, its name)
    for t in $times; do
        if [ -s $tmp/frames/$1_1_$t.png ] && cmp -s $tmp/frames/$1_1_$t.png $tmp/frames/$1_2_$t.png; then same=$((same + 1)); else differ+=("$2 at $t"); fi
    done
}
alone() {   # (kind, name): one side only has it
    [ -n "${has[1:${1}:${2}]}" ] && [ -n "${has[2:${1}:${2}]}" ] && return 1
    lone+=("$1 $2: ${${has[2:${1}:${2}]:+new since $old}:-gone since $old}, not compared")
}
n=0 compared=0
for r in $recipes; do
    n=$((n + 1))
    alone recipe $r && continue
    for side in 1 2; do draw $side r$n "make $r" "recipe $r"; done
    compare r$n "recipe $r"
    compared=$((compared + 1))
done
for f in $motions; do
    n=$((n + 1))
    alone motion $f && continue
    for side in 1 2; do draw $side m$n "add text $font
say 1 text MOTOLII
say 1 script $(ls $engines[$side]/animators/$f $engines[$side]/../shelves/animators/$f 2> /dev/null | head -1)" "motion ${f:r}"; done
    compare m$n "motion ${f:r}"
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
