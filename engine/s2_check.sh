#!/bin/zsh
# TESTING.md S2: what has one script draws as it did. The engine at <old-commit> (built in a place of its own) and the
# engine of this checkout each draw every recipe of the Create shelf (make <name>) and every motion of the Effects shelf
# (a text given it as its script) on a fresh document, at 0.0, 0.7 and 1.9 seconds; each pair of pictures is compared
# with cmp, as the 11/8 old-and-new comparison was. Prints each that differs and how many matched.
#   ./s2_check.sh ed4868cf1          (S2_LIMIT=2 ./s2_check.sh ed4868cf1: the first two of each only)
# Nothing of the maker's own is read or written: MOTOLII_OWN is an empty folder of its own (doc_edit.h doc_folders), the
# documents are made in a temporary folder, and engine/out/skin.motolii is not opened.
old=${1:?usage: ./s2_check.sh <old-commit>}
cd "$(dirname "$0")"
here=$PWD
git rev-parse -q --verify "$old^{commit}" > /dev/null || { echo "no such commit: $old"; exit 1; }
tmp=$(mktemp -d -t s2_check) || exit 1
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

# What each shelf has, on either side (one only the other has is counted as differing: its name is said)
names() { echo recipes | (cd $1 && ./edit.sh $tmp/docs/names.motolii) 2> /dev/null | sed 's/^  //' | cut -f1 | grep -v '^$'; }
recipes=("${(@f)$( { names $oldtree/engine; names $here; } | sort -u)}")
motions=("${(@f)$( { ls $oldtree/engine/animators; ls animators; } | grep '\.js$' | sort -u)}")
[ -n "$S2_LIMIT" ] && recipes=(${recipes[1,$S2_LIMIT]}) motions=(${motions[1,$S2_LIMIT]})   # (S2_LIMIT=2: the first so many of each, to see that it runs)

times=(0.0 0.7 1.9)
same=0 differ=()
draw() {   # (side, item number, the calls that put it on: a fresh document, each moment drawn)
    local e=$engines[$1] doc=$tmp/docs/$2_$1.motolii
    rm -f $doc
    { print -r -- "$3"; for t in $times; do print "at $t"; print "still $tmp/frames/$2_$1_$t.png"; done } | (cd $e && ./edit.sh $doc) > /dev/null 2>&1
}
compare() {   # (item number, its name)
    for t in $times; do
        if [ -f $tmp/frames/$1_1_$t.png ] && cmp -s $tmp/frames/$1_1_$t.png $tmp/frames/$1_2_$t.png; then same=$((same + 1)); else differ+=("$2 at $t"); fi
    done
}
n=0
for r in $recipes; do
    n=$((n + 1))
    for side in 1 2; do draw $side r$n "make $r"; done
    compare r$n "recipe $r"
done
for f in $motions; do
    n=$((n + 1))
    for side in 1 2; do draw $side m$n "add text MOTOLII
say 1 script $engines[$side]/animators/$f"; done
    compare m$n "motion ${f:r}"
done

echo "$same of $(( (${#recipes} + ${#motions}) * ${#times} )) matched (${#recipes} recipes, ${#motions} motions, ${#times} moments each)"
for d in $differ; do echo "differs: $d"; done
[ ${#differ} -eq 0 ]
