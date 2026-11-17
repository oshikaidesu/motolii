#!/bin/zsh
# Writes the shell calls that make the film: one text of five lines, red, split into lines, with
# shelves/expressions/fade_in.js, its Delay set to 1.3333 s: the Delay is across all the copies, so each of the five
# lines comes 0.33 s after the one before; each takes the 0.67 s the expression starts with.
#   ./film_calls.sh <out.mp4> [still.png at-seconds] | (cd engine/out/filament_webgpu && BACKEND=webgpu ../edit_wgpu new.motolii)
here=${0:a:h}; root=${here:h:h:h}
font=$root/engine/third_party/filament_src/assets/fonts/Roboto-Medium.ttf
print "add text $font"
print -r -- 'say 1 text '${WORDS:-'Every line\nof a text\nis a copy\nof its own\nand comes in turn'}
print "set 1 size ${SIZE:-0.16}"
print "say 1 fill ff2a2a"
print "say 1 split ${SPLIT:-lines}"
print "later fx_file 1 ${EXPRESSION:-$root/shelves/expressions/fade_in.js}"
[[ -z $EXPRESSION ]] && print "set 1 js_delay ${DELAY:-1.3333}"
[[ -n $2 ]] && print "at $3" && print "still $2"
[[ -n $1 && $1 != - ]] && print "export $1"
