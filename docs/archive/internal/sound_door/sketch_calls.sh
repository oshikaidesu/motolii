#!/bin/zsh
# Writes the shell calls that make the film of a p5.sound sketch: tones.wav as a sound layer, and over it the sketch
# (as it comes: the example p5.sound's own reference gives for p5.FFT), scaled so its square canvas fills the width (measured: at 1.806 it is 1078 px wide, at 1.8094 it is 1080).
#   ./sketch_calls.sh <out.mp4> [still.png at-seconds] | (cd engine/out/filament_webgpu && BACKEND=webgpu ../edit_wgpu new.motolii)
here=${0:a:h}
print "add sound ${SOUND:-$here/tones.wav}"
print "add image ${SKETCH:-$here/p5_fft_example.js}"
print "set 2 scale_x ${FILL:-1.8094}"; print "set 2 scale_y ${FILL:-1.8094}"
[[ -n $2 ]] && print "at $3" && print "still $2"
[[ -n $1 && $1 != - ]] && print "export $1"
