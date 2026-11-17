#!/bin/zsh
# A text layer, no fill, a white stroke, its trim keyed from 1 to 0 over 2 s, drawn at five moments; then its words
# changed and drawn again. Says how many layers there are and how much of each picture is lit.   ./trim_on_text.sh <tag>
A=/Users/member_ottoto/motolii/docs/internal/text_path
F=/Users/member_ottoto/motolii/engine/third_party/filament_src/assets/fonts/Roboto-Medium.ttf
tag=$1
cd /Users/member_ottoto/motolii/engine/out/filament_webgpu
{ printf 'add text %s\nsay 1 text MOTOLII\nset 1 size 0.15\nsay 1 fill none\nsay 1 stroke ffffff\nset 1 stroke_width 4\nkey 1 trim 0 1\nkey 1 trim 2 0\n' "$F"
  for t in 0.0 0.5 1.0 1.5 2.0; do printf 'at %s\nstill %s\n' $t "$A/tt_${tag}_$t.png"; done
  printf 'say 1 text TRIMMED\nat 1.0\nstill %s\nlist\n' "$A/tt_${tag}_words.png"; } \
  | SIZE=1920x1080 BACKEND=webgpu ../edit_wgpu "$A/tt_${tag}_$(date +%s).motolii" 2>&1 | grep "NOT done\| kind at" | cut -c1-150
python3 - <<PY
from PIL import Image
import os
for t in ('0.0','0.5','1.0','1.5','2.0','words'):
    f='$A/tt_${tag}_%s.png' % t
    if not os.path.exists(f): print(t, 'no picture'); continue
    im=Image.open(f).convert('L'); print(t, 'lit', sum(1 for v in im.getdata() if v>40), 'box', im.point(lambda v:255 if v>40 else 0).getbbox())
PY
