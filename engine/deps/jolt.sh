#!/bin/zsh
# Jolt Physics (Jorrit Rouwe, MIT), 5.6.1: rigid bodies that fall, touch and pile up (community/jolt/). Fetched once into
# third_party/physics/JoltPhysics and built with its own CMake as one static library, installed with the CMake package
# our CMakeLists.txt finds: third_party/physics/JoltPhysics/Build/install.
# Built as Release because our CMakeLists.txt is: the package tells its users which of Jolt's switches the library was
# built with, by the user's own build type, and the two must agree (RegisterTypes.h, VerifyJoltVersionID).
# CROSS_PLATFORM_DETERMINISTIC is Jolt's own switch for the same result on every machine (Docs/Architecture.md,
# "Deterministic Simulation").
#   ./deps/jolt.sh
set -e
cd "$(dirname "$0")/.."
source tools/build_lock.sh; build_lock "$@"   # (the machine's one build lock, taken here: tools/build_lock.sh)
J=$PWD/third_party/physics/JoltPhysics
[ -d $J ] || { mkdir -p $J && git init -q $J && git -C $J -c core.hooksPath=/dev/null fetch -q --depth 1 https://github.com/jrouwe/JoltPhysics a4b24c3fadd7eade0435f27e9d6a07564273eb5f && git -C $J checkout -q FETCH_HEAD; }
[ -f $J/Build/install/lib/libJolt.a ] || {
  cmake -S $J/Build -B $J/Build/out -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$J/Build/install \
    -DCROSS_PLATFORM_DETERMINISTIC=ON -DINTERPROCEDURAL_OPTIMIZATION=OFF -DTARGET_UNIT_TESTS=OFF -DTARGET_HELLO_WORLD=OFF \
    -DTARGET_PERFORMANCE_TEST=OFF -DTARGET_SAMPLES=OFF -DTARGET_VIEWER=OFF \
    -DJPH_USE_DX12=OFF -DJPH_USE_VK=OFF -DJPH_USE_MTL=OFF > /dev/null   # (its hair on GPU compute shaders, which need dxc: not used)
  cmake --build $J/Build/out --target install > /dev/null
}
