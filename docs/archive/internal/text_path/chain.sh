#!/bin/zsh
# The four on one text layer: a pen's flex CSS lays the letters out, the shelf's slide_in.js delays them one after
# another, the shelf's Comet Tails keeps the frames before, and the letters are drawn by their stroke alone with a trim
# opening. Exported as a film (frames in order); four frames taken.   ./chain.sh
A=/Users/member_ottoto/motolii/docs/internal/text_path
F=/Users/member_ottoto/motolii/engine/third_party/filament_src/assets/fonts/Roboto-Medium.ttf
S=/Users/member_ottoto/motolii/shelves
printf '%s\n' '[data-splitting] .word { display: flex; justify-content: space-between; width: 1500px; }' > "$A/between.css"
cd /Users/member_ottoto/motolii/engine/out/filament_webgpu
printf 'add text %s\nsay 1 text FLEXBOX\nset 1 size 0.12\nsay 1 split letters\nsay 1 fill none\nsay 1 stroke ffffff\nset 1 stroke_width 5\nkey 1 trim 0 1\nkey 1 trim 2.5 0\nlater fx_file 1 %s\nlater fx_file 1 %s\nlater fx_file 1 %s\nlist\nexport %s\n' \
  "$F" "$A/between.css" "$S/expressions/slide_in.js" "$S/effects/glitch/Comet Tails.fs" "$A/chain.mp4" \
  | SIZE=1920x1080 BACKEND=webgpu ../edit_wgpu "$A/chain_$(date +%s).motolii" 2>&1 | grep "NOT done\| kind at\| fx at" | cut -c1-110
for t in 0.4 0.8 1.4 2.6; do
  ffmpeg -loglevel error -y -ss $t -i "$A/chain.mp4" -frames:v 1 "$A/chain_$t.png"
  python3 -c "
from PIL import Image
im = Image.open('$A/chain_$t.png').convert('L')
print('t=$t: lit', sum(1 for v in im.getdata() if v > 40), 'box', im.point(lambda v: 255 if v > 40 else 0).getbbox())"
done
