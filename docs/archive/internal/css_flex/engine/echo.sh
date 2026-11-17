#!/bin/zsh
# One text layer with the flex CSS, the shelf's slide-in (delay) and one trail effect of the shelf, exported as a film
# (frames drawn in order), and two frames taken from it.   ./echo.sh <effect file> <name>
A=/Users/member_ottoto/motolii/docs/internal/css_flex/engine
F=/Users/member_ottoto/motolii/engine/third_party/filament_src/assets/fonts/Roboto-Medium.ttf
S=/Users/member_ottoto/motolii/shelves
effect=$1
name=$2
cd /Users/member_ottoto/motolii/engine/out/filament_webgpu
printf 'add text %s\nsay 1 text FLEXBOX\nset 1 size 0.08\nsay 1 split letters\nlater fx_file 1 %s\nlater fx_file 1 %s\nlater fx_file 1 %s\nexport %s\n' \
  "$F" "$A/between.css" "$S/expressions/slide_in.js" "$effect" "$A/film_$name.mp4" \
  | BACKEND=webgpu ../edit_wgpu "$A/film_${name}_$(date +%s).motolii" 2>&1 | grep "NOT"
for t in 0.3 0.5; do
  ffmpeg -loglevel error -y -ss $t -i "$A/film_$name.mp4" -frames:v 1 "$A/film_${name}_$t.png"
  python3 -c "
from PIL import Image
im = Image.open('$A/film_${name}_$t.png').convert('L')
print('$name t=$t: pixels lit in the text band', sum(1 for v in im.crop((0, 900, 1080, 1020)).getdata() if v > 12))"
done
