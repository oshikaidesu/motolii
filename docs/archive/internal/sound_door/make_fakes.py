#!/usr/bin/env python3
"""Make three fake films and check that measure_bands.py judges them rightly.

    python3 make_fakes.py

  fake_still.mp4     nothing moves                          -> must FAIL
  fake_right.mp4     glyph i rises with band i              -> must PASS
  fake_reversed.mp4  glyph i rises with band 9 - i          -> must FAIL

Same layout as the real film: 1080x1920, 60 fps, 10 s, H.264, 8 red (#ff2a2a)
shapes of unequal widths on black. Needs tones_schedule.json (make_tones.py).
Exit code 0 when all three verdicts are as expected.
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

WIDTH, HEIGHT, FPS, SECONDS = 1080, 1920, 60, 10
RED = np.array([255, 42, 42], np.float32)
GLYPH_HEIGHT = 160
BASE_LINE = 1100               # y of the glyphs' bottom edge at rest
GAP = 30
MAX_RISE = 200.0               # px for a band at full strength
ATTACK, RELEASE = 0.020, 0.050  # one-pole time constants; the tail is gone in ~150 ms
LATENCY = 1 / 60               # the analysis sees the sound one frame late
LEAK = 0.05                    # a neighbouring band lifts a glyph a little
SUPER = 4                      # supersampling for soft edges

HERE = os.path.dirname(os.path.abspath(__file__))


def glyph_sprites():
    """8 shapes, widths 40-130 px, as coverage (0..1) arrays GLYPH_HEIGHT tall."""
    def canvas(w):
        img = Image.new("L", (w * SUPER, GLYPH_HEIGHT * SUPER), 0)
        return img, ImageDraw.Draw(img)

    def done(img):
        w = img.width // SUPER
        return np.asarray(img.resize((w, GLYPH_HEIGHT), Image.LANCZOS), np.float32) / 255

    s, h = SUPER, GLYPH_HEIGHT * SUPER
    sprites = []

    img, d = canvas(40)                                   # a bar, like I
    d.rectangle([0, 0, 40 * s, h], fill=255)
    sprites.append(done(img))

    img, d = canvas(120)                                  # a ring, like O
    d.ellipse([0, 0, 120 * s - 1, h - 1], fill=255)
    d.ellipse([28 * s, 28 * s, 92 * s, h - 28 * s], fill=0)
    sprites.append(done(img))

    img, d = canvas(90)                                   # like T
    d.rectangle([0, 0, 90 * s, 30 * s], fill=255)
    d.rectangle([30 * s, 0, 60 * s, h], fill=255)
    sprites.append(done(img))

    img, d = canvas(110)                                  # a triangle, like A
    d.polygon([(55 * s, 0), (110 * s, h), (0, h)], fill=255)
    sprites.append(done(img))

    img, d = canvas(70)                                   # two parts side by side
    d.rectangle([0, 0, 28 * s, h], fill=255)
    d.rectangle([40 * s, 40 * s, 70 * s, h], fill=255)
    sprites.append(done(img))

    img, d = canvas(130)                                  # like L, wide foot
    d.rectangle([0, 0, 34 * s, h], fill=255)
    d.rectangle([0, h - 34 * s, 130 * s, h], fill=255)
    sprites.append(done(img))

    img, d = canvas(60)                                   # a slanted stroke
    d.polygon([(34 * s, 0), (60 * s, 0), (26 * s, h), (0, h)], fill=255)
    sprites.append(done(img))

    img, d = canvas(100)                                  # a disc
    d.ellipse([0, 30 * s, 100 * s - 1, 130 * s], fill=255)
    sprites.append(done(img))
    return sprites


def band_envelopes(bands):
    """Per band, per frame: 0..1 strength with attack, decay tail and latency."""
    over = 10
    rate = FPS * over
    t = np.arange(FPS * SECONDS * over) / rate - LATENCY
    env = np.zeros((len(bands), FPS * SECONDS))
    for b, band in enumerate(bands):
        on = np.array([any(a <= x < o for a, o in band["on"]) for x in t], float)
        v, out = 0.0, np.zeros(len(t))
        for i, target in enumerate(on):
            tau = ATTACK if target > v else RELEASE
            v += (target - v) * (1 - np.exp(-1 / (rate * tau)))
            out[i] = v
        env[b] = out[::over]
    return env


def write_film(name, rise):
    """rise[g, frame] in px. Encodes with ffmpeg; the sound is added if it exists."""
    sprites = glyph_sprites()
    total = sum(s.shape[1] for s in sprites) + GAP * (len(sprites) - 1)
    lefts, x = [], (WIDTH - total) // 2
    for s in sprites:
        lefts.append(x)
        x += s.shape[1] + GAP

    path = os.path.join(HERE, name)
    wav = os.path.join(HERE, "tones.wav")
    cmd = ["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
           "-s", f"{WIDTH}x{HEIGHT}", "-r", str(FPS), "-i", "-"]
    if os.path.exists(wav):
        cmd += ["-i", wav, "-c:a", "aac", "-b:a", "192k"]
    cmd += ["-c:v", "libx264", "-preset", "veryfast", "-crf", "20",
            "-pix_fmt", "yuv420p", path]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    for f in range(rise.shape[1]):
        cover = np.zeros((HEIGHT, WIDTH), np.float32)
        for g, s in enumerate(sprites):
            whole = int(np.floor(rise[g, f]))
            part = float(rise[g, f] - whole)
            top = BASE_LINE - GLYPH_HEIGHT - whole
            x0, x1 = lefts[g], lefts[g] + s.shape[1]
            # A rise between two whole pixels is a blend of the two.
            cover[top:top + GLYPH_HEIGHT, x0:x1] += (1 - part) * s
            cover[top - 1:top - 1 + GLYPH_HEIGHT, x0:x1] += part * s
        frame = (cover[:, :, None] * RED).round().astype(np.uint8)
        proc.stdin.write(frame.tobytes())
    proc.stdin.close()
    if proc.wait() != 0:
        sys.exit(f"ffmpeg failed writing {name}")
    return path


def main():
    with open(os.path.join(HERE, "tones_schedule.json")) as f:
        bands = json.load(f)["bands"]
    env = band_envelopes(bands)
    leaked = env.copy()
    leaked[1:] += LEAK * env[:-1]
    leaked[:-1] += LEAK * env[1:]

    films = [
        ("fake_still.mp4", np.zeros_like(env), 1),
        ("fake_right.mp4", MAX_RISE * leaked, 0),
        ("fake_reversed.mp4", MAX_RISE * leaked[::-1], 1),
    ]
    measure = os.path.join(HERE, "measure_bands.py")
    ok = True
    summary = []
    for name, rise, expected in films:
        path = write_film(name, rise)
        result = subprocess.run([sys.executable, measure, path],
                                capture_output=True, text=True)
        print(result.stdout, end="")
        print(result.stderr, end="", file=sys.stderr)
        verdict = {0: "PASS", 1: "FAIL"}.get(result.returncode, "ERROR")
        want = "PASS" if expected == 0 else "FAIL"
        as_expected = result.returncode == expected
        ok = ok and as_expected
        summary.append(f"{name}: {verdict} (expected {want})"
                       + ("" if as_expected else "   <- WRONG VERDICT"))
        print("-" * 72)
    print("\n".join(summary))
    print("the measure judges all three fakes as expected" if ok
          else "the measure is wrong on at least one fake")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
