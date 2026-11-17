#!/usr/bin/env python3
"""Does each of the 8 letters in a film rise with its own band of the test sound?

    python3 measure_bands.py <film.mp4> [--schedule tones_schedule.json] [--fps 60]

The film shows 8 red glyphs on black. Glyph i (left to right) should rise when
band i of tones.wav is sounding. This script knows nothing about the editor: it
decodes the frames with ffmpeg, finds the 8 glyph columns from the picture,
follows each glyph's height (centroid of its red pixels) over time, and
correlates that with the on/off schedule in tones_schedule.json.

PASS means all of:
  - every glyph's Pearson correlation with its own band is at least 0.8
  - for every glyph, its own band is the band it correlates with most
  - every glyph rises at least 20 px at some time
Exit code 0 on PASS, 1 on FAIL, 2 when the film cannot be read.
"""
import argparse
import json
import os
import subprocess
import sys

import numpy as np

GLYPHS = 8
MIN_OWN_CORRELATION = 0.8
MIN_RISE_PX = 20.0
STILL_PX = 1.0            # a glyph moving less than this is compression noise: it never moved
MAX_LAG_FRAMES = 15       # for the lag note only; the verdict is at zero lag


def probe(path):
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0",
         "-show_entries", "stream=width,height,avg_frame_rate",
         "-of", "json", path],
        capture_output=True, text=True, check=True).stdout
    stream = json.loads(out)["streams"][0]
    num, den = stream["avg_frame_rate"].split("/")
    fps = float(num) / float(den) if float(den) else 0.0
    return int(stream["width"]), int(stream["height"]), fps


def red_profiles(path, width, height):
    """Per frame and per pixel column: how many red pixels, and the sum of their y."""
    cmd = ["ffmpeg", "-v", "error", "-i", path, "-map", "0:v:0",
           "-fps_mode", "passthrough", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    size = width * height * 3
    ys = np.arange(height, dtype=np.float32)
    counts, ysums = [], []
    while True:
        buf = proc.stdout.read(size)
        if len(buf) < size:
            break
        frame = np.frombuffer(buf, np.uint8).reshape(height, width, 3)
        r = frame[:, :, 0].astype(np.int16)
        other = np.maximum(frame[:, :, 1], frame[:, :, 2])
        # #ff2a2a blended over black down to about 40% coverage still counts.
        red = ((r - other) >= 80).astype(np.float32)
        counts.append(red.sum(axis=0))
        ysums.append(ys @ red)
    proc.wait()
    if proc.returncode != 0:
        sys.exit(2)
    return np.array(counts, np.float64), np.array(ysums, np.float64)


def glyph_columns(column_total):
    """The 8 [x0, x1) column ranges holding red, left to right.

    A glyph made of side-by-side parts gives more than 8 runs; the narrowest
    gaps are closed until 8 remain.
    """
    occupied = column_total >= 0.005 * column_total.max()
    runs, x = [], 0
    while x < len(occupied):
        if occupied[x]:
            x1 = x
            while x1 < len(occupied) and occupied[x1]:
                x1 += 1
            runs.append([x, x1])
            x = x1
        else:
            x += 1
    while len(runs) > GLYPHS:
        gaps = [runs[i + 1][0] - runs[i][1] for i in range(len(runs) - 1)]
        i = int(np.argmin(gaps))
        runs[i][1] = runs[i + 1][1]
        del runs[i + 1]
    return runs


def pearson(a, b):
    a = a - a.mean()
    b = b - b.mean()
    denom = np.sqrt((a * a).sum() * (b * b).sum())
    # A glyph that never moves (or a band that never sounds) has no correlation.
    return float((a * b).sum() / denom) if denom > 0 else 0.0


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser()
    ap.add_argument("film")
    ap.add_argument("--schedule", default=os.path.join(here, "tones_schedule.json"))
    ap.add_argument("--fps", type=float, default=60.0,
                    help="frame n is taken to show the sound at n / fps seconds")
    args = ap.parse_args()

    with open(args.schedule) as f:
        bands = json.load(f)["bands"]
    if len(bands) != GLYPHS:
        print(f"schedule has {len(bands)} bands, expected {GLYPHS}")
        return 2

    width, height, film_fps = probe(args.film)
    counts, ysums = red_profiles(args.film, width, height)
    frames = len(counts)
    print(f"film: {args.film}")
    print(f"size {width}x{height}, {film_fps:.3f} fps, {frames} frames read")
    if abs(film_fps - args.fps) > 0.01:
        print(f"warning: film is {film_fps:.3f} fps but frame times use {args.fps:g} fps")
    if frames == 0 or counts.sum() == 0:
        print("no red pixels found")
        print("FAIL")
        return 1

    columns = glyph_columns(counts.sum(axis=0))
    print("glyph columns (x0-x1): " + "  ".join(f"{a}-{b}" for a, b in columns))
    if len(columns) != GLYPHS:
        print(f"found {len(columns)} glyph columns, expected {GLYPHS}")
        print("FAIL")
        return 1

    t = np.arange(frames) / args.fps
    on = np.array([[any(a <= x < b for a, b in band["on"]) for x in t]
                   for band in bands], dtype=np.float64)

    xs = np.arange(width, dtype=np.float64)
    table = np.zeros((GLYPHS, GLYPHS))
    largest_rise = np.zeros(GLYPHS)
    sideways = np.zeros(GLYPHS)
    unseen = np.zeros(GLYPHS, int)
    lag_note = [""] * GLYPHS
    for g, (x0, x1) in enumerate(columns):
        n = counts[:, x0:x1].sum(axis=1)
        seen = n >= 0.2 * np.median(n)          # frames where the glyph is there
        unseen[g] = int((~seen).sum())
        if seen.sum() < 2:
            continue
        y = ysums[seen, x0:x1].sum(axis=1) / n[seen]
        x = (counts[seen, x0:x1] @ xs[x0:x1]) / n[seen]
        # Resting position: the lowest the glyph ever sits on screen.
        rise = y.max() - y
        largest_rise[g] = rise.max()
        sideways[g] = x.max() - x.min()
        if largest_rise[g] < STILL_PX:
            continue
        for b in range(GLYPHS):
            table[g, b] = pearson(rise, on[b, seen])
        # Not part of the verdict: would the own band fit better a little later or earlier?
        # (The schedule is silent at both ends, so rolling it is a plain shift.)
        lags = range(-MAX_LAG_FRAMES, MAX_LAG_FRAMES + 1)
        shifted = [pearson(rise, np.roll(on[g], lag)[seen]) for lag in lags]
        k = int(np.argmax(shifted))
        lag_note[g] = (f"; best fit {shifted[k]:.3f} with the film "
                       f"{1000 * lags[k] / args.fps:+.0f} ms after the sound")

    print()
    print("correlation of each glyph's rise with each band's on/off schedule")
    print("         " + "".join(f"  band{b + 1}" for b in range(GLYPHS)))
    for g in range(GLYPHS):
        print(f"glyph {g + 1}  " + "".join(f"{table[g, b]:7.3f}" for b in range(GLYPHS)))

    own = np.diag(table)
    best = table.argmax(axis=1)
    # A row of all zeros has no best band.
    best_is_own = [(table[g].max() > 0 and best[g] == g) for g in range(GLYPHS)]
    print()
    for g in range(GLYPHS):
        note = "" if best_is_own[g] else "   <- best band is not its own"
        if unseen[g]:
            note += f"   ({unseen[g]} frames without this glyph left out)"
        best_name = str(best[g] + 1) if table[g].max() > 0 else "-"
        print(f"glyph {g + 1}: own band {own[g]:6.3f}, best band {best_name}, "
              f"largest rise {largest_rise[g]:7.1f} px, "
              f"sideways {sideways[g]:5.1f} px{lag_note[g]}{note}")

    print()
    print(f"min own-band correlation: {own.min():.3f}")
    print(f"glyphs whose best band is their own (of 8): {sum(best_is_own)}")
    print(f"min largest rise px: {largest_rise.min():.1f}")

    passed = (own.min() >= MIN_OWN_CORRELATION
              and all(best_is_own)
              and largest_rise.min() >= MIN_RISE_PX)
    print("PASS" if passed else "FAIL")
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
