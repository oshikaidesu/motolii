#!/usr/bin/env python3
"""Three fake films that show measure_lines.py tells the cases apart.

    make_fakes.py [folder for the films, default: next to this script]

  fake_together.mp4   all 5 lines fade in together          -> must FAIL
  fake_in_turn.mp4    line k starts at k/3 s, top first     -> must PASS
  fake_bottom_up.mp4  the same, but the bottom line first   -> must FAIL

Each film: 1080x1920, 60 fps, 4 s, red (#ff2a2a) text on black, H.264.
Exit code 0 only when all three verdicts are the expected ones.
"""

import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

WIDTH, HEIGHT, RATE, SECONDS = 1080, 1920, 60, 4
RED = (0xFF, 0x2A, 0x2A)
FADE = 2 / 3  # seconds for one line to become fully visible
STEP = 1 / 3  # seconds between one line's start and the next
# Lines of different lengths.  "since noon" has no tall letter, so the dot of its i
# is a row group of its own and the measure has to merge it.
LINES = ["Each line", "comes in", "since noon", "one after another", "to the end"]
FONTS = ["/System/Library/Fonts/Helvetica.ttc",
         "/System/Library/Fonts/Supplemental/Arial.ttf",
         "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]
HERE = os.path.dirname(os.path.abspath(__file__))


def line_masks():
    """One (top row, coverage 0..1 of the rows from there) per line."""
    font = None
    for path in FONTS:
        if os.path.exists(path):
            font = ImageFont.truetype(path, 110)
            break
    masks = []
    for i, text in enumerate(LINES):
        picture = Image.new("L", (WIDTH, HEIGHT), 0)
        draw = ImageDraw.Draw(picture)
        y = 560 + i * 170
        if font:
            draw.text((120, y), text, fill=255, font=font)
        else:  # no font on this machine: blocks the size of words
            x = 120
            for word in text.split():
                draw.rectangle([x, y, x + 55 * len(word), y + 90], fill=255)
                x += 55 * len(word) + 40
        coverage = np.asarray(picture, np.float32) / 255
        rows = np.nonzero(coverage.any(axis=1))[0]
        top, bottom = int(rows[0]), int(rows[-1])
        masks.append((top, coverage[top:bottom + 1]))
    return masks


def write_film(path, masks, starts):
    """starts[i]: the second at which line i begins to appear."""
    encoder = subprocess.Popen(
        ["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
         "-s", f"{WIDTH}x{HEIGHT}", "-r", str(RATE), "-i", "-",
         "-c:v", "libx264", "-pix_fmt", "yuv420p", path],
        stdin=subprocess.PIPE)
    red = np.array(RED, np.float32)
    for frame in range(RATE * SECONDS):
        t = frame / RATE
        picture = np.zeros((HEIGHT, WIDTH, 3), np.uint8)
        for (top, coverage), start in zip(masks, starts):
            opacity = min(max((t - start) / FADE, 0.0), 1.0)
            if opacity > 0:
                picture[top:top + len(coverage)] = (coverage[:, :, None] * opacity * red + 0.5)
        encoder.stdin.write(picture.tobytes())
    encoder.stdin.close()
    if encoder.wait() != 0:
        raise SystemExit(f"ffmpeg could not write {path}")


def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else HERE
    os.makedirs(folder, exist_ok=True)
    count = len(LINES)
    fakes = [
        ("fake_together.mp4", [STEP] * count, "FAIL"),
        ("fake_in_turn.mp4", [STEP * (k + 1) for k in range(count)], "PASS"),
        ("fake_bottom_up.mp4", [STEP * (count - k) for k in range(count)], "FAIL"),
    ]
    masks = line_masks()
    as_expected = True
    summary = []
    for name, starts, expected in fakes:
        path = os.path.join(folder, name)
        write_film(path, masks, starts)
        run = subprocess.run([sys.executable, os.path.join(HERE, "measure_lines.py"), path],
                             capture_output=True, text=True)
        lines = run.stdout.strip().splitlines()
        verdict = lines[-1] if lines else "(nothing printed)"
        print(f"--- {name}")
        print(run.stdout.rstrip())
        if run.stderr.strip():
            print(run.stderr.rstrip())
        ok = verdict == expected and run.returncode == (0 if expected == "PASS" else 1)
        as_expected = as_expected and ok
        summary.append(f"{name}: {verdict} (expected {expected}) {'ok' if ok else 'WRONG'}")
    print("--- verdicts")
    for line in summary:
        print(line)
    print("the measure tells the three apart" if as_expected
          else "the measure does NOT tell the three apart")
    return 0 if as_expected else 1


if __name__ == "__main__":
    sys.exit(main())
