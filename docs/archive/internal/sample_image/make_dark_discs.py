#!/usr/bin/env python3
"""Make dark_discs.mp4: a light, textured background with three dark discs.

1080 x 1920, 60 fps, 600 frames (10 s), H.264 yuv420p. Every frame is a pure
function of its number n (time n/60 s), and the whole film loops after 10 s.

    python3 make_dark_discs.py [output.mp4]
"""
import os
import subprocess
import sys

import numpy as np

FFMPEG = "/opt/homebrew/bin/ffmpeg"
W, H = 1080, 1920
FPS = 60
FRAMES = 600
SOFT_EDGE = 40.0  # px, centred on the disc radius

# radius, centre (cx, cy), amplitude (ax, ay), turns in 10 s (fx, fy), phase (px, py)
DISCS = [
    (240.0, (540.0, 960.0), (280.0, 620.0), (2, 1), (0.0, 1.5708)),
    (210.0, (540.0, 640.0), (310.0, 300.0), (1, 2), (1.0, 2.0)),
    (255.0, (540.0, 1290.0), (270.0, 300.0), (3, 2), (4.0, 0.5)),
]

BACKGROUND_TINT = np.array([0.012, 0.0, -0.020], dtype=np.float32)  # slightly warm
DISC_COLOUR = np.array([0.035, 0.040, 0.055], dtype=np.float32)  # luma about 0.04


def disc_positions(n):
    """Centre and radius of every disc in frame n: [(x, y, radius), ...]."""
    u = 2.0 * np.pi * n / FRAMES
    out = []
    for radius, (cx, cy), (ax, ay), (fx, fy), (px, py) in DISCS:
        out.append((cx + ax * np.sin(fx * u + px), cy + ay * np.sin(fy * u + py), radius))
    return out


_xs = np.arange(W, dtype=np.float32)
_ys = np.arange(H, dtype=np.float32)
# Static part of the background luma: a diagonal gradient and a fine grain.
_base = (
    0.88
    + 0.05 * ((_ys[:, None] / (H - 1)) * 1.4 + (_xs[None, :] / (W - 1)) * 0.6 - 1.0)
    + np.random.default_rng(0).uniform(-0.006, 0.006, (H, W)).astype(np.float32)
).astype(np.float32)


def frame(n):
    """Frame n as uint8 RGB, shape (H, W, 3)."""
    u = 2.0 * np.pi * n / FRAMES
    # Slowly drifting soft waves, so the background reads as footage.
    luma = _base + 0.03 * np.outer(
        np.sin(2.0 * np.pi * _ys / 900.0 - u), np.sin(2.0 * np.pi * _xs / 700.0 + u)
    ).astype(np.float32)

    cover = np.zeros((H, W), dtype=np.float32)  # 1 inside a disc, 0 outside
    for x, y, radius in disc_positions(n):
        reach = radius + SOFT_EDGE / 2.0
        x0, x1 = max(0, int(x - reach)), min(W, int(x + reach) + 2)
        y0, y1 = max(0, int(y - reach)), min(H, int(y + reach) + 2)
        dist = np.sqrt((_ys[y0:y1, None] - y) ** 2 + (_xs[None, x0:x1] - x) ** 2)
        e = np.clip((dist - (radius - SOFT_EDGE / 2.0)) / SOFT_EDGE, 0.0, 1.0)
        inside = 1.0 - e * e * (3.0 - 2.0 * e)
        part = cover[y0:y1, x0:x1]
        part[:] = 1.0 - (1.0 - part) * (1.0 - inside)

    rgb = (luma[:, :, None] + BACKGROUND_TINT) * (1.0 - cover[:, :, None]) + DISC_COLOUR * cover[
        :, :, None
    ]
    return (np.clip(rgb, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8)


def encoder(path, fps, crf):
    """An ffmpeg process that takes raw RGB frames of W x H on stdin."""
    return subprocess.Popen(
        [
            FFMPEG, "-y", "-hide_banner", "-loglevel", "error",
            "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(fps), "-i", "-",
            "-an", "-vf", "scale=out_color_matrix=bt709:out_range=tv,format=yuv420p",
            "-c:v", "libx264", "-preset", "medium", "-crf", str(crf),
            "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
            "-color_range", "tv", "-movflags", "+faststart", path,
        ],
        stdin=subprocess.PIPE,
    )


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "dark_discs.mp4")
    out = encoder(path, FPS, 12)
    for n in range(FRAMES):
        out.stdin.write(frame(n).tobytes())
    out.stdin.close()
    if out.wait() != 0:
        sys.exit("ffmpeg failed")
    print(path)


if __name__ == "__main__":
    main()
