#!/bin/zsh
# Builds and runs weigh_show.cpp on the Mac against the ThorVG this repo already builds (third_party/thorvg_src, by
# dawn_probe/tvg_on_dawn.sh: its CPU engine is in it beside the WebGPU one, so the Dawn it is built with is linked too).
# Frames go to out/weigh/NNN.ppm; ffmpeg makes them out/weigh.mp4 if it is there.
#   ./weigh_show.sh [stack.json] [seconds]
set -e
cd "$(dirname "$0")"
SRC=third_party/filament_src
SDK=$SRC/out/wgpu_install
THOR=third_party/thorvg_src
F=$SRC/third_party/libassimp/contrib/rapidjson/include
[ -f $THOR/build_dawn/src/libthorvg-1.a ] || ./dawn_probe/tvg_on_dawn.sh > /dev/null
mkdir -p out
clang++ -std=c++17 -O2 -DTVG_STATIC -I. -I$F -I$THOR/inc weigh_show.cpp $THOR/build_dawn/src/libthorvg-1.a \
    -L "$SDK/lib/arm64" -lwebgpu_dawn -framework Cocoa -framework Metal -framework QuartzCore -framework IOSurface -framework IOKit -Wl,-dead_strip -o out/weigh_show
./out/weigh_show "$@"
command -v ffmpeg > /dev/null && ffmpeg -y -loglevel error -framerate 60 -i out/weigh/%03d.ppm -pix_fmt yuv420p out/weigh.mp4 && echo out/weigh.mp4
