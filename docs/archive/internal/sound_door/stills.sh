#!/bin/zsh
# Takes a still of the sketch for every fourth draw, k = 4, 8, ... 596, as <folder>/<k>.png. The sketch's draw k is what
# the film shows in frame k - 1, at second (k - 1) / 60: its first draw is the film's first frame.
#   ./stills.sh <folder> [path of edit_wgpu]
here=${0:a:h}; root=${here:h:h:h}; out=${1:a}; shell=${2:-$root/engine/out/edit_wgpu}
mkdir -p $out; cd $root/engine/out/filament_webgpu
{ $here/sketch_calls.sh -; for k in {4..596..4}; do print "at $(((k - 1) / 60.0))"; print "still $out/$k.png"; done } | BACKEND=webgpu $shell $out/stills_$$.motolii > /dev/null 2>&1
ls $out/*.png | wc -l
