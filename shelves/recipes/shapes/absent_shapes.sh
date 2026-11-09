#!/bin/zsh
# AbsentMotion's shapes (Apache-2.0: github.com/Comett1225/AbsentMotion, fetched by engine/gpu/kit_wgpu.sh) on the Make
# shelf as recipes, am_<name>.js here: its own shapes.cpp, read as it is, built with Skia (engine/deps/skia.sh's libskia)
# beside the little of its scene it reads (absent_shapes/), each of its shapes.xml a path (from_absent_shapes.py).
# Run by hand when AbsentMotion's shapes change; nothing builds it. (in engine/ until 416fced3a.)
#   shelves/recipes/shapes/absent_shapes.sh
cd "$(dirname "$0")"
E=${0:a:h}/../../../engine
A=$E/third_party/AbsentMotion K=$E/third_party/skia_src W=$(mktemp -d)
[ -d $A/app ] || { echo "AbsentMotion is not in $A: build the engine once (engine/edit.sh; gpu/kit_wgpu.sh fetches it)"; exit 1; }
[ -f $K/out/path/libskia.a ] || $E/deps/skia.sh
cp $A/app/src/main/cpp/shapes.cpp $W/   # (apart from its own scene.h: the one beside the tool is read)
clang++ -std=c++20 -O1 -I absent_shapes -I $K absent_shapes/main.cpp $W/shapes.cpp $K/out/path/libskia.a -framework CoreFoundation -o $W/shapes || exit 1
rm -f am_*.js(N)
python3 from_absent_shapes.py $A/app/src/main/assets/shapes.xml $W/shapes .
rm -rf $W
