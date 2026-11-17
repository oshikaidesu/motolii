#!/usr/bin/env python3
"""Write tones.wav and tones_schedule.json: the test sound for measure_bands.py.

    python3 make_tones.py

20 Hz to 2000 Hz is cut into 8 equal bands on a linear scale. Each band gets a
sine tone at its centre, switched on and off by the schedule below. The
schedule was picked by a search (not kept) so that a letter following its own
band correlates strongly with that band's schedule and weakly with the others:

  - two on-stretches per band, 0.6 s to 1.0 s each. Long stretches matter: a
    0.4 s stretch loses much more correlation to attack/decay smoothing.
  - never more than two bands at once, so two tones at -6.2 dBFS cannot clip.
  - every band sounds alone for at least 0.4 s in one piece.
  - silence at 0-0.4 s, 5.5-5.9 s and 9.6-10 s.
  - no two schedules correlate above 0.25 (checked below).
"""
import json
import os
import wave

import numpy as np

SAMPLE_RATE = 48000
DURATION = 10.0
LOW_HZ, HIGH_HZ, BANDS = 20.0, 2000.0, 8
TONE_PEAK = 0.49         # -6.2 dBFS; two together reach 0.98 at most
FADE = 0.010             # seconds, raised cosine, inside the on-stretch

# [on, off] in seconds, band 1 first.
SCHEDULE = [
    [[1.0, 1.7], [7.3, 8.3]],
    [[3.9, 4.8], [7.0, 7.6]],
    [[1.4, 2.4], [8.8, 9.6]],
    [[2.8, 3.5], [6.3, 7.3]],
    [[2.1, 3.1], [8.3, 8.9]],
    [[3.2, 4.1], [8.9, 9.5]],
    [[4.6, 5.5], [8.0, 8.6]],
    [[0.4, 1.3], [5.9, 6.5]],
]


def longest_stretch(flags, step):
    best = run = 0
    for f in flags:
        run = run + 1 if f else 0
        best = max(best, run)
    return best * step


def check_schedule():
    step = 0.01
    t = (np.arange(int(round(DURATION / step))) + 0.5) * step
    on = np.array([[any(a <= x < b for a, b in runs) for x in t] for runs in SCHEDULE])
    together = on.sum(axis=0)
    assert together.max() == 2, "more than two bands at once would clip"
    assert longest_stretch(together == 0, step) >= 0.4, "no silent stretch"
    assert (together == 2).sum() * step >= 2.0, "too little time with two bands"
    for b, runs in enumerate(SCHEDULE):
        assert all(off - on_ >= 0.4 for on_, off in runs), f"band {b + 1}: short stretch"
        alone = longest_stretch(on[b] & (together == 1), step)
        assert alone >= 0.4, f"band {b + 1} is never alone for 0.4 s"
    c = np.corrcoef(on.astype(float))
    np.fill_diagonal(c, 0)
    assert np.abs(c).max() < 0.25, "two schedules are too alike"
    return np.abs(c).max(), (together == 0).sum() * step, (together == 2).sum() * step


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    worst, silent, double = check_schedule()

    width = (HIGH_HZ - LOW_HZ) / BANDS
    n = int(SAMPLE_RATE * DURATION)
    t = np.arange(n) / SAMPLE_RATE
    mix = np.zeros(n)
    bands = []
    for b, runs in enumerate(SCHEDULE):
        low = LOW_HZ + b * width
        centre = low + width / 2
        gate = np.zeros(n)
        for on, off in runs:
            up = np.clip((t - on) / FADE, 0, 1)
            down = np.clip((off - t) / FADE, 0, 1)
            gate += 0.5 - 0.5 * np.cos(np.pi * np.minimum(up, down))
        mix += TONE_PEAK * gate * np.sin(2 * np.pi * centre * t)
        bands.append({"band": b + 1, "low_hz": low, "high_hz": low + width,
                      "centre_hz": centre, "on": runs})

    peak = np.abs(mix).max()
    assert peak <= 1.0, "the sum clips"
    samples = np.round(mix * 32767).astype("<i2")
    with wave.open(os.path.join(here, "tones.wav"), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(np.repeat(samples, 2).tobytes())

    with open(os.path.join(here, "tones_schedule.json"), "w") as f:
        json.dump({"sample_rate": SAMPLE_RATE, "duration": DURATION,
                   "tone_peak": TONE_PEAK, "fade": FADE, "bands": bands}, f, indent=1)

    print(f"tones.wav: {DURATION:g} s, {SAMPLE_RATE} Hz, 16-bit stereo, "
          f"peak {20 * np.log10(peak):.2f} dBFS")
    print(f"silent {silent:.1f} s, two bands together {double:.1f} s, "
          f"largest correlation between two schedules {worst:.3f}")
    for band in bands:
        print(f"band {band['band']}: {band['centre_hz']:8.2f} Hz  on {band['on']}")


if __name__ == "__main__":
    main()
