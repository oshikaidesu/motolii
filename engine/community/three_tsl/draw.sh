#!/bin/zsh
# Every converted effect that left what it needs to draw (engine/out/tsl/<collection>/<name>/) drawn on Dawn by
# gpu/tsl_on_dawn.cpp over one picture, and each collection's pictures put on one sheet: engine/out/tsl/<collection>.jpg
# (8 across, in the order of engine/out/tsl/<collection>.names.txt).
#   ./community/three_tsl/draw.sh <picture> [size]
P=${1:A}; cd "$(dirname "$0")/../../out/tsl"
N=${2:-256}
for c in */(/); do
  [ -d $c ] || continue
  rm -rf $c/_shots; mkdir -p $c/_shots; drawn=0; failed=0
  for d in $c*/(/); do
    [ -f $d/frag.wgsl ] || continue
    ffmpeg -v error -y -i $P -vf "scale=$N:$N:force_original_aspect_ratio=increase,crop=$N:$N" -pix_fmt rgba -f rawvideo $d/picture.rgba
    if ../tsl_on_dawn $d $N $N 2>/dev/null | grep -q PASS; then
      ffmpeg -v error -y -f lavfi -i color=black:s=${N}x$N -f rawvideo -pixel_format rgba -video_size ${N}x$N -i $d/drawn.rgba \
        -filter_complex "[0][1]overlay=format=auto" -frames:v 1 $c/_shots/$(basename $d).png && drawn=$((drawn+1))
    else failed=$((failed+1)); echo "$(basename $c)/$(basename $d)" >> draw_fail.txt; fi
  done
  n=$(ls $c/_shots | wc -l | tr -d ' ')
  ls $c/_shots | sed 's/\.png$//' > $(basename $c).names.txt   # (the sheet's order, left to right, top to bottom)
  [ $n -gt 0 ] && ffmpeg -v error -y -pattern_type glob -i "$c/_shots/*.png" -vf "tile=8x$(( (n + 7) / 8 )):padding=2" -frames:v 1 $(basename $c).jpg
  echo "$(basename $c): drawn $drawn, failed $failed"
done
