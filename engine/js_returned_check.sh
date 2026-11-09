#!/bin/zsh
# motolii_js_returned (js_returned.cpp) checked: a Repeater-shaped each() is read, the 0.3 of its x changed to 0.6 at the
# bytes it says, and (1) the file differs in those bytes alone, (2) it draws as the Repeater with Step X 0.6 does, compared
# with cmp at 0.0, 0.7 and 1.9 seconds as s2_check.sh compares. Before the change it draws as the Repeater as it comes.
#   ./js_returned_check.sh
cd "$(dirname "$0")"
echo "" | ./edit.sh /dev/null > /dev/null 2>&1   # (the library, built if it is not)
[ out/js_returned_check -nt js_returned_check.cpp ] && [ out/js_returned_check -nt out/libmotolii.dylib ] || clang++ -std=c++20 -O2 js_returned_check.cpp -Lout -lmotolii -Wl,-rpath,$PWD/out -o out/js_returned_check || exit 1
tmp=$(mktemp -d -t js_returned) || exit 1
trap 'rm -rf "$tmp"' EXIT INT TERM
export MOTOLII_OWN=$tmp/own && mkdir -p $MOTOLII_OWN   # (no maker's recipes: the library's alone, as s2_check.sh)
# The Repeater's each() (recipes/repeater.js) with its knobs as they come, but each written as a number
cat > $tmp/row.js <<'EOF'
function each(i, n, t, k) {
  const along = i - (n - 1) / 2;
  return {
    x: along * 0.3,   // Step X
    y: along * 0, z: along * 0, rotate: 0, rotate_x: i * 0, rotate_y: i * 0,
    size: Math.pow(1, i), scale_x: n > 1 ? Math.pow(1, i / (n - 1)) : 1,
  };
}
EOF
out/js_returned_check $tmp/row.js x 0.3 0.6 $tmp/row6.js || exit 1
bad=0
changed=$(cmp -l $tmp/row.js $tmp/row6.js | wc -l | tr -d ' ')
[ $(wc -c < $tmp/row.js) -eq $(wc -c < $tmp/row6.js) ] && [ "$changed" = 1 ] && [ "$(cmp -l $tmp/row.js $tmp/row6.js | awk '{print $1}')" = $(( $(grep -bo '0\.3' $tmp/row.js | head -1 | cut -d: -f1) + 3 )) ] \
    && echo "the file: one byte changed, the 3 of x's 0.3" || { echo "the file: changed elsewhere too"; diff $tmp/row.js $tmp/row6.js; bad=1; }
draw() {   # (name, the calls that put it on)
    rm -f $tmp/$1.motolii
    { print -r -- "$2"; for t in 0.0 0.7 1.9; do print "at $t"; print "still $tmp/$1_$t.png"; done } | ./edit.sh $tmp/$1.motolii > /dev/null 2>&1
}
draw as_it_comes "make Repeater"
draw row "make Repeater
say 1 fx $tmp/row.js"
draw step6 "make Repeater
set 1 js_StepX 0.6"
draw row6 "make Repeater
say 1 fx $tmp/row6.js"
same() { for t in 0.0 0.7 1.9; do [ -f $tmp/$1_$t.png ] && cmp -s $tmp/$1_$t.png $tmp/$2_$t.png || return 1; done; }
same row as_it_comes && echo "before: draws as the Repeater as it comes" || { echo "before: draws otherwise than the Repeater as it comes"; bad=1; }
same row6 step6 && echo "after: draws as the Repeater with Step X 0.6" || { echo "after: draws otherwise than Step X 0.6"; bad=1; }
same as_it_comes step6 && { echo "(but Step X 0.6 draws as 0.3 does: the check sees nothing)"; bad=1; }
exit $bad
