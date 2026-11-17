#!/usr/bin/env python3
"""Make two stand-ins for an exported film, to show measure_overlap.py can fail and pass.

Both draw twenty red rectangles over dark_discs.mp4, at 30 fps:
  fake_static.mp4  the rectangles never move, so the discs pass over them
  fake_avoid.mp4   a rectangle whose centre is inside a disc is pushed straight
                   out to just beyond that disc's edge

    python3 make_fakes.py
"""
import os
import subprocess
import sys

import numpy as np

from make_dark_discs import FFMPEG, FRAMES, H, W, disc_positions, encoder

HERE = os.path.dirname(os.path.abspath(__file__))
RED = (0xFF, 0x2A, 0x2A)
RECT_W, RECT_H = 60, 90
CLEARANCE = 60.0  # px beyond the disc radius; clears the soft edge and the rectangle's corner
HOMES = [(x, y) for y in (420, 780, 1140, 1500) for x in (140, 340, 540, 740, 940)]


def avoid(x, y, discs):
    for _ in range(4):  # a push out of one disc can land in another
        moved = False
        for cx, cy, radius in discs:
            dx, dy = x - cx, y - cy
            dist = float(np.hypot(dx, dy))
            if dist < radius:
                if dist < 1e-6:
                    dx, dy, dist = 0.0, -1.0, 1.0
                scale = (radius + CLEARANCE) / dist
                x, y = cx + dx * scale, cy + dy * scale
                moved = True
        if not moved:
            break
    return x, y


def main():
    source = subprocess.Popen(
        [FFMPEG, "-hide_banner", "-loglevel", "error", "-i", os.path.join(HERE, "dark_discs.mp4"),
         "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
        stdout=subprocess.PIPE,
    )
    static = encoder(os.path.join(HERE, "fake_static.mp4"), 30, 18)
    avoiding = encoder(os.path.join(HERE, "fake_avoid.mp4"), 30, 18)
    size = W * H * 3
    for n in range(FRAMES):
        data = source.stdout.read(size)
        if len(data) < size:
            sys.exit(f"dark_discs.mp4 ended at frame {n}")
        if n % 2:  # 60 fps in, 30 fps out
            continue
        discs = disc_positions(n)
        for out, dodge in ((static, False), (avoiding, True)):
            picture = np.frombuffer(data, dtype=np.uint8).reshape(H, W, 3).copy()
            for x, y in HOMES:
                if dodge:
                    x, y = avoid(x, y, discs)
                x0, y0 = int(round(x - RECT_W / 2)), int(round(y - RECT_H / 2))
                picture[max(0, y0):max(0, y0 + RECT_H), max(0, x0):max(0, x0 + RECT_W)] = RED
            out.stdin.write(picture.tobytes())
    for out in (static, avoiding):
        out.stdin.close()
        if out.wait() != 0:
            sys.exit("ffmpeg failed")
    source.wait()


if __name__ == "__main__":
    main()
