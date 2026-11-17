#!/usr/bin/env python3
"""Do the 5 lines of a red text on black fade in one after another, top line first?

    measure_lines.py <film.mp4>

The film is read through ffmpeg only; nothing of the editor is used.  The 5 line
bands are found in the last frame (rows that contain red).  For every frame, a
band's visibility is its sum of redness divided by its sum in the last frame.

PASS needs all of:
  - 5 bands found;
  - the frames where the bands first reach 0.5 rise strictly from top to bottom;
  - each gap between neighbouring bands' 0.5 frames is 10 to 40 frames;
  - when a band reaches 0.5, the band below it is still under 0.25.

The last line printed is PASS or FAIL; the exit code is 0 or 1.
"""

import subprocess
import sys

import numpy as np

BANDS = 5
RED_PIXEL = 64  # redness of one pixel (R - max(G, B), 0..255) that makes its row a red row
MIN_GAP = 10  # frames; the lines are meant to start 1/3 s = 20 frames apart at 60 fps
MAX_GAP = 40
BELOW_STILL_HIDDEN = 0.25


def probe(film):
    """Width, height and frame rate of the first video stream."""
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0",
         "-show_entries", "stream=width,height,r_frame_rate", "-of", "csv=p=0", film],
        check=True, capture_output=True, text=True).stdout.strip()
    width, height, rate = out.split(",")[:3]
    num, _, den = rate.partition("/")
    return int(width), int(height), float(num) / float(den or 1)


def redness_by_row(film, width, height):
    """(frames x rows) sums of redness, and each row's strongest redness in the last frame."""
    decoder = subprocess.Popen(
        ["ffmpeg", "-v", "error", "-i", film, "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
        stdout=subprocess.PIPE)
    size = width * height * 3
    sums = []
    last_strongest = None
    while True:
        raw = decoder.stdout.read(size)
        if len(raw) < size:
            break
        rgb = np.frombuffer(raw, np.uint8).reshape(height, width, 3).astype(np.int16)
        redness = np.clip(rgb[:, :, 0] - np.maximum(rgb[:, :, 1], rgb[:, :, 2]), 0, None)
        sums.append(redness.sum(axis=1, dtype=np.int64))
        last_strongest = redness.max(axis=1)
    decoder.wait()
    return np.array(sums), last_strongest


def groups_of_rows(is_red):
    """Runs of neighbouring red rows as [top, bottom] (both rows included)."""
    groups = []
    for row, red in enumerate(is_red):
        if not red:
            continue
        if groups and groups[-1][1] == row - 1:
            groups[-1][1] = row
        else:
            groups.append([row, row])
    return groups


def merge_closest(groups, wanted):
    """Join the two groups with the fewest black rows between them until `wanted` remain."""
    groups = [list(g) for g in groups]
    while len(groups) > wanted:
        between = [groups[i + 1][0] - groups[i][1] for i in range(len(groups) - 1)]
        i = between.index(min(between))
        groups[i][1] = groups[i + 1][1]
        del groups[i + 1]
    return groups


def first_frame_at(visibility, level):
    reached = np.nonzero(visibility >= level)[0]
    return int(reached[0]) if len(reached) else None


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        print("FAIL")
        return 1
    film = sys.argv[1]
    width, height, rate = probe(film)
    sums, last_strongest = redness_by_row(film, width, height)
    print(f"film: {film}  {width}x{height}  {rate:g} fps  {len(sums)} frames")
    if len(sums) == 0:
        print("no frame could be read")
        print("bands found: 0")
        print("gaps (frames): -")
        print("FAIL")
        return 1

    groups = groups_of_rows(last_strongest >= RED_PIXEL)
    bands = merge_closest(groups, BANDS)
    print(f"groups of red rows in the last frame: {len(groups)}")

    failures = []
    if len(bands) != BANDS:
        print(f"bands found: {len(bands)}")
        print("gaps (frames): -")
        print(f"why: {BANDS} bands are needed")
        print("FAIL")
        return 1

    # visibility[band][frame], 1.0 in the last frame by construction
    visibility = []
    for top, bottom in bands:
        band = sums[:, top:bottom + 1].sum(axis=1).astype(np.float64)
        visibility.append(band / band[-1])
    half = [first_frame_at(v, 0.5) for v in visibility]
    most = [first_frame_at(v, 0.9) for v in visibility]

    print("band   top  bottom  first frame at 0.5  first frame at 0.9")
    for i, (top, bottom) in enumerate(bands):
        print(f"{i + 1:>4}  {top:>4}  {bottom:>6}  {half[i]:>18}  {most[i]:>18}")

    gaps = [half[i + 1] - half[i] for i in range(BANDS - 1)]
    below = [float(visibility[i + 1][half[i]]) for i in range(BANDS - 1)]
    print(f"bands found: {len(bands)}")
    print("gaps (frames): " + " ".join(str(g) for g in gaps))
    print("band below, when a band reaches 0.5: " + " ".join(f"{b:.2f}" for b in below))

    if any(g <= 0 for g in gaps):
        failures.append("the 0.5 frames do not rise strictly from the top band to the bottom band")
    if any(not MIN_GAP <= g <= MAX_GAP for g in gaps):
        failures.append(f"a gap is outside {MIN_GAP}..{MAX_GAP} frames")
    if any(b >= BELOW_STILL_HIDDEN for b in below):
        failures.append(f"a band below is already {BELOW_STILL_HIDDEN} visible or more "
                        "when the band above reaches 0.5")
    for why in failures:
        print(f"why: {why}")
    print("FAIL" if failures else "PASS")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
