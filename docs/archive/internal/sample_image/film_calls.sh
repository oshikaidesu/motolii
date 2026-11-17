#!/bin/zsh
# Writes the shell calls that make the film: dark_discs.mp4 filling the frame, seven rows of red letters over it, each
# row a text split into letters with shelves/expressions/away_from_dark.js reading the video.
#   ./film_calls.sh <out.mp4> [still.png at-seconds] | (cd engine/out/filament_webgpu && BACKEND=webgpu ../edit_wgpu new.motolii)
here=${0:a:h}; root=${here:h:h:h}
font=$root/engine/third_party/filament_src/assets/fonts/Roboto-Medium.ttf
print "add film $here/dark_discs.mp4"
print "set 1 scale_x ${FILL:-3.2107}"; print "set 1 scale_y ${FILL:-3.2107}"
words=("LETTERS READ" "THE VIDEO" "UNDER THEM" "AND LEAVE" "THE DARK" "FOR WHERE" "IT IS LIGHT")
for row in {1..7}; do
  n=$((row + 1))
  print "add text $font"
  print "say $n text ${words[$row]}"
  print "set $n size 0.13"
  print "set $n y $(( (4 - row) * 0.38 ))"
  print "say $n fill ff2a2a"
  print "say $n split letters"
  print "later fx_file $n $root/shelves/expressions/away_from_dark.js"
  print "set $n js_video 1"
  [[ -n $REACH ]] && print "set $n js_reach $REACH"
  [[ -n $PUSH ]] && print "set $n js_push $PUSH"
done
[[ -n $2 ]] && print "at $3" && print "still $2"
[[ -n $1 && $1 != - ]] && print "export $1"
