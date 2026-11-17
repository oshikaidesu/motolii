#!/bin/zsh
# Compares what Motolii's getByteFrequencyData reads of tone1000.wav with what Chrome's AnalyserNode reads of the same
# sound (chrome_analyser.json, from chrome_analyser.sh). Motolii has no way to print from a script, so probe_sound.js
# makes letter i stand as high as one pitch is strong and the numbers are read from a still.
#   ./compare_with_chrome.sh [path of edit_wgpu]     prints each row and the largest difference; exit 0 when within 3
here=${0:a:h}; root=${here:h:h:h}; shell=${1:-$root/engine/out/edit_wgpu}; tmp=$(mktemp -d)
font=$root/engine/third_party/filament_src/assets/fonts/Roboto-Medium.ttf
cd $root/engine/out/filament_webgpu
for k in 30 60 61 62 63 65 70 75 80 90 119 120 121 122 125 130 140 150 170; do
  printf 'add sound %s\nadd text %s\nsay 2 text HHHHHHHHHHHHHH\nset 2 size 0.05\nsay 2 fill ff2a2a\nsay 2 split letters\nlater fx_file 2 %s\nset 2 js_sound 1\nat %s\nstill %s\n' \
    $here/tone1000.wav $font $here/probe_sound.js $((k / 60.0)) $tmp/$k.png | (BACKEND=webgpu $shell $tmp/$k.motolii > /dev/null 2>&1)
done
python3 - $tmp $here/chrome_analyser.json <<'PY'
import sys, json, numpy as np
from PIL import Image
tmp, ref = sys.argv[1], json.load(open(sys.argv[2]))
worst = 0
for k in [30,60,61,62,63,65,70,75,80,90,119,120,121,122,125,130,140,150,170]:
    im = np.asarray(Image.open(f'{tmp}/{k}.png').convert('RGB')).astype(int)
    red = (im[:,:,0] > 150) & (im[:,:,1] < 90) & (im[:,:,2] < 90)
    xs = np.where(red.any(axis=0))[0]; groups = []; st = pv = xs[0]
    for x in xs[1:]:
        if x - pv > 3: groups.append((st, pv)); st = x
        pv = x
    groups.append((st, pv))
    ys = [np.where(red[:, a:b+1].any(axis=1))[0].mean() for a, b in groups]
    # The probe puts a letter at y = value - 0.5 in stage units; the last letter is the wave's peak, 0.5 while the
    # tone sounds and 0 in silence, which gives the scale: pixels per unit from two stills is not needed, the frame
    # is 1920 high and a unit is the height a video layer of scale 1 has, 1920 / 3.2107 px.
    unit = 1920 / 3.2107; rest = im.shape[0] / 2 + 0.5 * unit
    got = [round((rest - y) / unit * 255) for y in ys[:13]]
    want = ref['rows'][str(k)][:13]
    d = max(abs(a - b) for a, b in zip(got, want)); worst = max(worst, d) if k not in (60, 61, 62, 120, 121, 122) else worst
    print(k, 'motolii', got, 'chrome', want, 'diff', d)
print('largest difference outside the three frames from where the tone starts or stops (Chrome offline stops only every 128 samples, so it has heard up to 3 ms more there):', worst)
sys.exit(0 if worst <= 3 else 1)
PY
