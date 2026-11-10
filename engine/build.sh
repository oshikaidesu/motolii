#!/bin/zsh
# The build: out/libmotolii.dylib (what the app loads) and out/edit_wgpu (the same calls from a shell).
#   ./build.sh        the dependencies (deps/; first time Filament from source, about 5 minutes on an M4), the
#                     materials (materials/build.sh), then CMake (CMakeLists.txt), which compiles what changed
#   ./build.sh lib    the same, only the library; then restart the app (a native library cannot be hot reloaded)
#   ./build.sh test   the same, then the C++ tests (ctest)
set -e
cd "$(dirname "$0")"
source tools/build_lock.sh; build_lock "$@"   # one build at a time on this machine

# Dependencies: each script fetches one library into third_party/ and builds it with its own build system.
./deps/filament.sh
(cd third_party/filament_src/out/wgpu && ninja motolii_interop > /dev/null)   # gpu/CMakeLists.txt, built inside Filament's build
THORVG=third_party/thorvg_src
[ -f $THORVG/build_dawn/src/libthorvg-1.a ] || ./deps/thorvg.sh > /dev/null
meson configure $THORVG/build_dawn -Dengines=cpu,wg -Dextra=lottie_exp > /dev/null   # meson falls back to the CPU engine alone when it reconfigures itself
ninja -C $THORVG/build_dawn > /dev/null
./deps/libtess2.sh
./deps/curve_fit_nd.sh
./deps/jolt.sh
./deps/iris.sh
./deps/midi_roll.sh
[ -f third_party/skia_src/out/path/libpathops.a ] || ./deps/skia.sh
./deps/absent_motion.sh

./materials/build.sh

cmake -S . -B out/cmake -G Ninja > /dev/null
case "$1" in
  lib)  cmake --build out/cmake --target motolii ;;
  test) cmake --build out/cmake && ctest --test-dir out/cmake --output-on-failure ;;
  *)    cmake --build out/cmake ;;
esac
build_unlock
