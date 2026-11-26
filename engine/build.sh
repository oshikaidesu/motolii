#!/bin/zsh
# The build: out/libmotolii.dylib (what the app loads) and out/edit_wgpu (the same calls from a shell).
#   ./build.sh        the dependencies (deps/; first time Filament from source, about 5 minutes on an M4), the
#                     materials (materials/build.sh), then CMake (CMakeLists.txt), which compiles what changed
#   ./build.sh lib    the same, only the library; then restart the app (a native library cannot be hot reloaded)
#   ./build.sh test   the same, then the C++ tests (ctest)
# On Windows: MSYS2's zsh inside the VS x64 developer prompt, with GStreamer's MSVC installer, vcpkg's x64-windows
# (sqlite3[session] luajit quickjs-ng gtest) and Corrosion said by GSTREAMER_1_0_ROOT_MSVC_X86_64, MOTOLII_LIBRARIES
# and MOTOLII_CORROSION (docs/archive/engine/WINDOWS.md):  set MSYS2_PATH_TYPE=inherit, then <msys64>\usr\bin\zsh engine/build.sh
set -e
cd "$(dirname "$0")"
source tools/build_lock.sh; build_lock "$@"   # one build at a time on this machine
if [[ $OSTYPE == (msys|cygwin)* ]]; then
    # What deps/ builds by hand is compiled for MSVC's runtime DLL, as Filament and the engine are.
    export CC=clang CXX=clang++ AR=llvm-ar CFLAGS=-fms-runtime-lib=dll MSYS=winsymlinks:nativestrict
    WINDOWS=(-DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DGSTREAMER=$(cygpath -ms "$GSTREAMER_1_0_ROOT_MSVC_X86_64")
             -DLIBRARIES=$(cygpath -m $MOTOLII_LIBRARIES) -DCorrosion_DIR=$(cygpath -m $MOTOLII_CORROSION)/lib/cmake/Corrosion)
fi

# Dependencies and materials: run when one of their scripts or sources is newer than the last run (out/deps.stamp).
# Each deps script fetches one library into third_party/ and builds it with its own build system.
mkdir -p out
if [ ! -f out/deps.stamp ] || [ -n "$(find build.sh deps gpu materials -newer out/deps.stamp -print -quit)" ]; then
    ./deps/filament.sh
    (cd third_party/filament_src/out/wgpu && ninja motolii_interop > /dev/null)   # gpu/CMakeLists.txt, built inside Filament's build
    THORVG=third_party/thorvg_src
    [ -f $THORVG/build_dawn/src/libthorvg-1.a ] || ./deps/thorvg.sh
    PKG_CONFIG_PATH=$THORVG/dawn_pc meson configure $THORVG/build_dawn -Dengines=cpu,wg -Dextra=lottie_exp   # meson falls back to the CPU engine alone when it reconfigures itself
    ninja -C $THORVG/build_dawn
    ./deps/libtess2.sh
    ./deps/psd_sdk.sh
    ./deps/jolt.sh
    ./deps/curve_fit_nd.sh
    ./deps/ffmpeg.sh
    # The one dependency the rest can be built without (entry/calls_map.cpp). When it is fetched later, delete
    # out/cmake/CMakeCache.txt so that CMake links it.
    ./deps/onnxruntime.sh || echo "onnxruntime: not fetched; this build is without the shelf maps' image likeness" >&2
    ./deps/iris.sh
    ./deps/midi_roll.sh
    [ -f third_party/skia_src/out/path/libpathops.a ] || ./deps/skia.sh
    ./deps/absent_motion.sh
    ./deps/stylo.sh
    ./deps/aexlo.sh

    ./materials/build.sh
    touch out/deps.stamp
fi

# Only the first time (no build.ninja yet). After that cmake --build (ninja) re-runs CMake itself when a
# CMakeLists.txt is newer, and re-globs the CONFIGURE_DEPENDS headers, so configuring again here is redundant.
[ -f out/cmake/build.ninja ] || cmake -S . -B out/cmake -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON $WINDOWS > /dev/null
# Windows looks for a DLL's own DLLs on PATH, not beside it: those not in GStreamer's folder go beside
# libmotolii.dll, a folder the runner puts on PATH with GStreamer's (app/windows/runner/main.cpp).
[[ $OSTYPE == (msys|cygwin)* ]] && cp -u third_party/onnxruntime/lib/*.dll(N) third_party/ffmpeg_lgpl/bin/*.dll(N) $MOTOLII_LIBRARIES/bin/*.dll(N) out/
case "$1" in
  lib)      cmake --build out/cmake --target motolii ;;
  test)     cmake --build out/cmake && ctest --test-dir out/cmake --output-on-failure ;;
  sanitize) cmake -S . -B out/cmake_san -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DMOTOLII_SANITIZE=ON $WINDOWS > /dev/null
            cmake --build out/cmake_san ;;
  *)        cmake --build out/cmake ;;
esac
build_unlock
