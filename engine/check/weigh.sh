#!/bin/zsh
# weigh.h, the weight × change model (After Effects' text animators, Cinema 4D's Effectors, CSS's rules as one shape):
# its three presets as JSON alone come out as those programs have them on a row of 10 copies. Needs only a C++17
# compiler and rapidjson's headers (the copy under third_party/filament_src that isf.cpp reads; RAPIDJSON= points
# elsewhere). No GPU, no document.
#   ./check/weigh.sh
cd "$(dirname "$0")/.."
mkdir -p out
rj=${RAPIDJSON:-third_party/filament_src/third_party/libassimp/contrib/rapidjson/include}
${CXX:-c++} -std=c++17 -O1 -Wno-deprecated-declarations -I. -I"$rj" check/weigh_check.cpp -o out/weigh_check || { echo "weigh.h builds: NO"; exit 1; }
./out/weigh_check
# Not said by the five weights: a comb along the row (CSS's :nth-child(odd), every third one). Kept out until a real
# motion needs it, so the set stays closed; when one does, it is one more weight (Index wrapped), not a new file.
