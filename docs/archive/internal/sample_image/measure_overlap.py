#!/usr/bin/env python3
"""How much of the red lettering in an exported film lies over the dark areas
of the source video at the same moment.

    python3 measure_overlap.py <source_video> <exported_film> [--every N]

Letters: exported pixels with R - G > 100 and R - B > 100 (8-bit).
Dark:    source pixels with Rec. 709 luma below 0.30 of full scale.
Frames are paired by time, counted from each film's first frame: an exported
frame at time t is compared with the source frame on screen at t.
Exit status 2 when the film has no red pixels at all.
"""
import argparse
import bisect
import json
import subprocess
import sys

import numpy as np
from PIL import Image

FFMPEG = "/opt/homebrew/bin/ffmpeg"
FFPROBE = "/opt/homebrew/bin/ffprobe"
RED_MARGIN = 100
DARK_LUMA = 0.30


def probe(path):
    """(width, height, frames per second, start time of every frame in seconds)."""
    info = json.loads(
        subprocess.run(
            [
                FFPROBE, "-v", "error", "-select_streams", "v:0",
                "-show_entries", "stream=width,height,avg_frame_rate,r_frame_rate"
                ":stream_side_data=rotation:packet=pts_time",
                "-of", "json", path,
            ],
            check=True, capture_output=True, text=True,
        ).stdout
    )
    stream = info["streams"][0]
    width, height = stream["width"], stream["height"]
    for side in stream.get("side_data_list", []):
        if abs(int(side.get("rotation", 0))) % 180 == 90:  # ffmpeg turns these upright
            width, height = height, width
    fps = 0.0
    for key in ("avg_frame_rate", "r_frame_rate"):
        num, _, den = stream.get(key, "0/0").partition("/")
        if float(num) > 0 and float(den or 1) > 0:
            fps = float(num) / float(den or 1)
            break
    if fps <= 0:
        sys.exit(f"{path}: no frame rate")
    times = sorted(float(p["pts_time"]) for p in info.get("packets", []) if "pts_time" in p)
    times = [t - times[0] for t in times]
    return width, height, fps, times


def frames(path, width, height):
    """Every frame of the film in turn, as uint8 RGB arrays."""
    size = width * height * 3
    proc = subprocess.Popen(
        [
            FFMPEG, "-hide_banner", "-loglevel", "error", "-i", path, "-map", "0:v:0",
            "-fps_mode", "passthrough", "-f", "rawvideo", "-pix_fmt", "rgb24", "-",
        ],
        stdout=subprocess.PIPE,
    )
    try:
        while True:
            data = proc.stdout.read(size)
            if len(data) < size:
                return
            yield np.frombuffer(data, dtype=np.uint8).reshape(height, width, 3)
    finally:
        proc.kill()  # before closing the pipe, so a film left unfinished prints no errors
        proc.stdout.close()
        proc.wait()


def time_of(index, times, fps):
    return times[index] if index < len(times) else index / fps


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("source_video")
    parser.add_argument("exported_film")
    parser.add_argument("--every", type=int, default=6, metavar="N",
                        help="measure every Nth exported frame (default 6)")
    args = parser.parse_args()
    if args.every < 1:
        parser.error("--every must be at least 1")

    src_w, src_h, src_fps, src_times = probe(args.source_video)
    out_w, out_h, out_fps, out_times = probe(args.exported_film)
    src_end = (src_times[-1] if src_times else 0.0) + 1.0 / src_fps
    tolerance = 0.01 / src_fps

    source = frames(args.source_video, src_w, src_h)
    src_index = -1
    src_frame = None

    measured = 0
    letter_pixels = 0
    on_dark_pixels = 0
    worst = None

    for index, film in enumerate(frames(args.exported_film, out_w, out_h)):
        if index % args.every:
            continue
        t = time_of(index, out_times, out_fps)
        if t >= src_end - tolerance:
            break
        # The source frame on screen at t: the last one that starts at or before t.
        if src_times:
            want = max(0, bisect.bisect_right(src_times, t + tolerance) - 1)
        else:
            want = int(t * src_fps + 0.01)
        while src_index < want:
            src_frame = next(source, None)
            if src_frame is None:
                break
            src_index += 1
        if src_frame is None:
            break

        rgb = film.astype(np.int16)
        letters = (rgb[..., 0] - rgb[..., 1] > RED_MARGIN) & (rgb[..., 0] - rgb[..., 2] > RED_MARGIN)
        luma = src_frame @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
        dark = luma < DARK_LUMA * 255.0
        if dark.shape != letters.shape:
            dark = np.asarray(Image.fromarray(dark).resize((out_w, out_h), Image.NEAREST))

        count = int(letters.sum())
        on_dark = int((letters & dark).sum())
        print(f"t={t:.3f} letters={count} on_dark={on_dark}")
        measured += 1
        letter_pixels += count
        on_dark_pixels += on_dark
        if count:
            worst = max(worst or 0.0, on_dark / count)

    if letter_pixels == 0:
        print(f"SUMMARY frames={measured} letter_pixels=0 on_dark_pixels=0 "
              "overlap=nan worst_frame_overlap=nan")
        sys.exit(2)
    print(f"SUMMARY frames={measured} letter_pixels={letter_pixels} "
          f"on_dark_pixels={on_dark_pixels} overlap={on_dark_pixels / letter_pixels:.4f} "
          f"worst_frame_overlap={worst:.4f}")


if __name__ == "__main__":
    main()
