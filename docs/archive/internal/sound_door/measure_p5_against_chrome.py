#!/usr/bin/env python3
"""Compares a p5.sound sketch drawn by Motolii with the same sketch drawn by Chrome (chrome_p5.json, from chrome_p5.py).

    python3 measure_p5_against_chrome.py <folder of stills named <k>.png> 

Still <k>.png is the sketch's draw k (stills.sh makes them, at second (k - 1) / 60), 1080 wide, the sketch's square canvas filling the
width in the middle; it is compared with Chrome's draw k. Only every fourth k is compared: Chrome's offline rendering
can stop only every 128 samples, which is exactly k / 60 s when k is a multiple of four (3200 samples), and up to
2.6 ms late otherwise. Each picture is measured as chrome_p5.py measures Chrome's canvas: per pixel column, how high
magenta is painted (the bars of the spectrum: the pixels at least a quarter of the way from grey to magenta), and the mean height of the dark
line in the middle band (the wave). PASS means all of:
  - bars, over the columns where Chrome ever draws one, each compared with Chrome's nearest of that column and its
    two neighbours: mean difference at most 2 px, and 99 % within 8 px (the canvas is 1080 px for 255 steps, so
    8 px is about two steps);
  - wave, over the columns where both have a line: mean difference at most 2 px;
  - there are bars at all (their largest is at least half of Chrome's largest).
"""
import json, os, sys
import numpy as np
from PIL import Image

here = os.path.dirname(os.path.abspath(__file__))
ref = json.load(open(os.path.join(here, "chrome_p5.json")))["rows"]
W = 1080
ys = np.arange(W, dtype=np.float64)[:, None]
band = (ys > 0.3 * W) & (ys < 0.7 * W)
bars, wave, want_bars, want_wave = [], [], [], []
for k in range(4, 600, 4):
    name = os.path.join(sys.argv[1], f"{k}.png")
    if not os.path.exists(name) or str(k) not in ref: continue
    f = np.asarray(Image.open(name).convert("RGB")).astype(np.float64)
    f = f[(f.shape[0] - W) // 2:(f.shape[0] - W) // 2 + W]
    r, g, b = f[:, :, 0], f[:, :, 1], f[:, :, 2]
    dark = np.clip((220 - np.maximum(np.maximum(r, g), b)) / 200, 0, None) * band
    n = dark.sum(axis=0)
    bars.append(((r - g) / 255 > 0.25).sum(axis=0))
    wave.append(np.where(n > 0.5, (dark * ys).sum(axis=0) / np.maximum(n, 1e-9), -1))
    want_bars.append(ref[str(k)][2]); want_wave.append(ref[str(k)][3])
bars, wave, want_bars, want_wave = (np.array(a, np.float64) for a in (bars, wave, want_bars, want_wave))
cols = want_bars.max(axis=0) > 0.5
# A bar is 1.05 px wide, so about one in eighteen lies across two pixel columns, and which of the two shows it is
# the rasterizer's choice (Chrome's canvas and ThorVG choose differently). A column is therefore compared with
# Chrome's same column and the one on either side, and the nearest is taken.
near = np.stack([np.abs(bars - np.roll(want_bars, j, axis=1)) for j in (-1, 0, 1)]).min(axis=0)
d = near[:, cols]
both = (wave >= 0) & (want_wave >= 0)
dw = np.abs(wave - want_wave)[both]
print(f"frames compared: {len(bars)}; columns where Chrome draws bars: {int(cols.sum())}")
print(f"bars: mean difference {d.mean():.2f} px, within 8 px {100 * (d <= 8).mean():.2f} %, largest {d.max():.0f} px; largest bar here {bars.max():.0f} px, Chrome {want_bars.max():.0f} px")
print(f"wave: mean difference {dw.mean() if dw.size else float('nan'):.2f} px over {dw.size} points, largest {dw.max() if dw.size else float('nan'):.1f} px; a line in {100 * (wave >= 0).mean():.1f} % of columns here, Chrome {100 * (want_wave >= 0).mean():.1f} %")
ok = d.mean() <= 2 and (d <= 8).mean() >= 0.99 and dw.size > 0 and dw.mean() <= 2 and bars.max() >= 0.5 * want_bars.max()
print("PASS" if ok else "FAIL")
sys.exit(0 if ok else 1)
