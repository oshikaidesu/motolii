#!/bin/zsh
# Writes the shell calls that make the film: tones.wav as a sound layer, and one row of eight red letters, a text split
# into letters with shelves/expressions/rise_to_sound.js reading the sound (20 to 2000 Hz, its sliders as they come).
#   ./film_calls.sh <out.mp4> [still.png at-seconds] | (cd engine/out/filament_webgpu && BACKEND=webgpu ../edit_wgpu new.motolii)
here=${0:a:h}; root=${here:h:h:h}
font=$root/engine/third_party/filament_src/assets/fonts/Roboto-Medium.ttf
print "add sound ${SOUND:-$here/tones.wav}"
print "add text $font"
print "say 2 text ${WORDS:-LOUDNESS}"
print "set 2 size ${SIZE:-0.22}"
[[ -n $SPACING ]] && print "set 2 letter_spacing $SPACING"
print "set 2 y ${Y:--0.6}"
print "say 2 fill ff2a2a"
print "say 2 split letters"
print "later fx_file 2 $root/shelves/expressions/rise_to_sound.js"
print "set 2 js_sound 1"
[[ -n $HEIGHT ]] && print "set 2 js_height $HEIGHT"
[[ -n $2 ]] && print "at $3" && print "still $2"
[[ -n $1 && $1 != - ]] && print "export $1"
