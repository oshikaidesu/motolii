#!/bin/zsh
# The three After Effects recipes (recipes/ae_ring.js, ae_grid.js, ae_stagger.js; an expression each, held as After Effects
# holds it) watched through motolii_path (check/ae_recipes.c): AE Ring (equal distances, 30 degrees apart, Turn turns,
# Radius scales), AE Grid (a constant step, Columns and Spacing, centred, the first row on top), AE Stagger (copy i is
# ease(t from Delay x i to Delay x i + Length): 0 before, 1 after, 0.5 half way, each later than the one before); only
# ratios and signs, never the conversion from After Effects' pixels to the stage's units. Needs the inside built (edit.sh).
#   ./check/ae_recipes.sh
cd "$(dirname "$0")/.."
rm -f out/ae_recipes.motolii out/ae_recipes_check
cc check/ae_recipes.c -Lout -lmotolii -lm -Wl,-rpath,$PWD/out -o out/ae_recipes_check || { echo "the AE recipes: NO (the check did not compile)"; exit 1; }
out=$(cd out/wgpu_kit && ../ae_recipes_check $PWD/../ae_recipes.motolii 2>&1); code=$?
print -r -- "$out" | grep -v "Vulkan\|BackendVk\|^ *at \|FEngine\|adapter\|feature\|^$" | awk '
    /^ok   /     { sub(/^ok   /, ""); print $0 ": yes"; next }
    /^FAIL [0-9]/ { print "the AE recipes held, all of them: NO (" $2 " did not)"; next }
    /^FAIL /     { sub(/^FAIL /, ""); print $0 ": NO"; next }
    /^PASS$/     { print "the AE recipes held, all of them: yes"; next }
    { print }'
rm -f out/ae_recipes.motolii
exit $code
