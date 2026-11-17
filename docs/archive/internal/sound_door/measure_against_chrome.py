#!/usr/bin/env python3
"""Compares the film's letters with what Chrome's AnalyserNode reads of the same sound.

    python3 measure_against_chrome.py <film.mp4>

Each of the 8 letters is tracked as measure_bands.py tracks it. What it should do is worked out from
chrome_tones.json (chrome_tones.sh): for frame k, the mean of the bytes between the letter's two frequencies, both
ends counted (p5.sound's FFT.getEnergy), over 255, times the Maximum Height of 480 px that rise_to_sound.js starts
with. PASS means, for every letter: its rise over time correlates at least 0.98 with that curve, and its largest rise
is within 5 % of the curve's largest.
"""
import json, os, sys
import numpy as np
from measure_bands import probe, red_profiles, glyph_columns, pearson

here = os.path.dirname(os.path.abspath(__file__))
ref = json.load(open(os.path.join(here, "chrome_tones.json")))
apart = ref["rate"] / ref["fftSize"]
width, height, fps = probe(sys.argv[1])
counts, ysums = red_profiles(sys.argv[1], width, height)
columns = glyph_columns(counts.sum(axis=0))
frames = len(counts)
ok = len(columns) == 8
worst_r, worst_scale = 1.0, 0.0
for i, (a, b) in enumerate(columns):
    n = counts[:, a:b].sum(axis=1)
    y = np.where(n > 0, ysums[:, a:b].sum(axis=1) / np.maximum(n, 1), np.nan)
    rise = np.nanmax(y) - y
    low, high = round((20 + 247.5 * i) / apart), round((20 + 247.5 * (i + 1)) / apart)
    want = np.array([np.mean(ref["rows"][str(k)][low:high + 1]) / 255 * 480 if str(k) in ref["rows"] else 0.0
                     for k in range(frames)])
    r = pearson(np.nan_to_num(rise), want)
    scale = np.nanmax(rise) / want.max()
    off = np.nanmax(np.abs(np.nan_to_num(rise) - want))
    worst_r, worst_scale = min(worst_r, r), max(worst_scale, abs(scale - 1))
    print(f"letter {i + 1}: pitches {low}-{high}, correlation with Chrome {r:.4f}, largest rise {np.nanmax(rise):.1f} px"
          f" (Chrome {want.max():.1f} px), largest difference in any frame {off:.1f} px")
    ok = ok and r >= 0.98 and abs(scale - 1) <= 0.05
print(f"min correlation with Chrome: {worst_r:.4f}")
print(f"largest rise off Chrome's by at most: {worst_scale * 100:.1f} %")
print("PASS" if ok else "FAIL")
sys.exit(0 if ok else 1)
