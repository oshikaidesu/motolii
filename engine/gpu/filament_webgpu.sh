#!/bin/zsh
# One of the renderer's pictures (ring, poster, blocks, shapes) on Filament's WebGPU (Dawn) backend, beside the usual Metal
# build (which is not touched). Needs deps/filament.sh first (the WebGPU-enabled Filament and its matc).
#   ./gpu/filament_webgpu.sh ring                 builds ../out/<name>_wgpu and runs it on WebGPU:  ../out/filament_webgpu/out/<name>.png
#   BACKEND=metal ./gpu/filament_webgpu.sh ring   the same program on Metal, to compare
set -e
cd "$(dirname "$0")/.."
source tools/build_lock.sh; build_lock "$@"   # (the machine's one build lock, taken here: tools/build_lock.sh)
n=${1:-ring}
SRC=third_party/filament_src
SDK=$SRC/out/wgpu_install
MATC=$SRC/out/wgpu/tools/matc/matc
mkdir -p out/filament_webgpu/out
# (the rooms' light, made once by Filament's own cmgen from its environments, as poster.sh and blocks.sh make them with the SDK's)
[ -f out/small_studio/small_studio_ibl.ktx ] && [ -f out/lightroom/lightroom_ibl.ktx ] || (cd $SRC/out/wgpu && ninja cmgen > /dev/null)
[ -f out/small_studio/small_studio_ibl.ktx ] || $SRC/out/wgpu/tools/cmgen/cmgen -q -x out/small_studio --format=ktx --size=512 $SRC/third_party/environments/studio_small_02_2k.hdr
[ -f out/lightroom/lightroom_ibl.ktx ] || $SRC/out/wgpu/tools/cmgen/cmgen -q -x out/lightroom --format=ktx --size=512 $SRC/third_party/environments/lightroom_14b.hdr
for d in lightroom small_studio graffiti_shelter_2k studio_small_02_2k venetian_crossroads_2k parking_garage_2k pillars_2k; do [ -d out/$d ] && ln -sfn ../../$d out/filament_webgpu/out/$d 2> /dev/null; done; true
for f in effected effected_world effected_solid thick_glass far_side far_look bubble poster own_glass flat blade matte floor_lit solid_cloth solid_subsurface shape points solid_image sketch; do
    [ -f materials/$f.mat ] || continue
    [ out/filament_webgpu/$f.filamat -nt materials/$f.mat ] && [ out/filament_webgpu/$f.filamat -nt materials/studio.glsl ] && [ out/filament_webgpu/$f.filamat -nt materials/spectrum.glsl ] && [ out/filament_webgpu/$f.filamat -nt materials/matte.glsl ] && [ out/filament_webgpu/$f.filamat -nt materials/blend_way.glsl ] && [ out/filament_webgpu/$f.filamat -nt materials/deep.glsl ] && [ out/filament_webgpu/$f.filamat -nt materials/deep_vertex.glsl ] && continue
    shade=lit; [ $f = flat ] && shade=unlit
    $MATC -a webgpu -a metal -p desktop -TBLENDING=transparent -TCUT=opaque -TSHADE=$shade -o out/filament_webgpu/$f.filamat materials/$f.mat > out/filament_webgpu/$f.log 2>&1 ||
        $MATC -g -a webgpu -a metal -p desktop -TBLENDING=transparent -TCUT=opaque -o out/filament_webgpu/$f.filamat materials/$f.mat > out/filament_webgpu/$f.log 2>&1 ||
        echo "no WebGPU material: $f (out/filament_webgpu/$f.log)"
    [ $f = floor_lit ] && { $MATC -a webgpu -a metal -p desktop -TBLENDING=transparent -TCUT=masked -o out/filament_webgpu/floor_lit_matte.filamat materials/floor_lit.mat > out/filament_webgpu/floor_lit_matte.log 2>&1 ||
        echo "no WebGPU material: floor_lit_matte"; }   # (the same, cut by a matte: what the matte leaves out is not rendered, materials/matte.glsl)
    [ $f = solid_image ] && { $MATC -a webgpu -a metal -p desktop -TSHADE=unlit -DFLAT -o out/filament_webgpu/solid_image_flat.filamat materials/solid_image.mat > out/filament_webgpu/solid_image_flat.log 2>&1 ||
        echo "no WebGPU material: solid_image_flat"; }   # (the same, unlit)
    { [ $f = effected ] || [ $f = effected_world ]; } && for way in add multiply screen; do   # (a thing with effects of its own lies on what is behind as it says too, as flat's ways)
        $MATC -a webgpu -a metal -p desktop -TBLENDING=$way -DLAY_$way -o out/filament_webgpu/${f}_$way.filamat materials/$f.mat > out/filament_webgpu/${f}_$way.log 2>&1 || echo "no WebGPU material: ${f}_$way"
    done
    [ $f = flat ] && for way in add multiply screen opaque; do   # (the ways a sheet lies on what is behind it: Filament's own blending; opaque: the colour behind everything, rendered before the solid things)
        $MATC -a webgpu -a metal -p desktop -TBLENDING=$way -TSHADE=unlit -DLAY_$way -o out/filament_webgpu/flat_$way.filamat materials/flat.mat > out/filament_webgpu/flat_$way.log 2>&1 || echo "no WebGPU material: flat_$way"
    done
    [ $f = flat ] && for way in transparent add multiply screen; do   # (the same in the lamps' light; a soft edge's shine goes with it, Filament's fade: transparent keeps a highlight whole)
        blend=$way; [ $way = transparent ] && blend=fade
        $MATC -a webgpu -a metal -p desktop -TBLENDING=$blend -TSHADE=lit -DLIT -DLAY_$way -o out/filament_webgpu/flat_lit_$way.filamat materials/flat.mat > out/filament_webgpu/flat_lit_$way.log 2>&1 || echo "no WebGPU material: flat_lit_$way"
    done
    [ $f = flat ] && for wear in wear:lit:WEAR:fade cloth:cloth:CLOTH:fade subsurface:subsurface:SUBSURFACE:fade lacquer:lit:LACQUER:fade bubble:lit:BUBBLE:transparent glass:unlit:GLASS:transparent; do   # (a material a flat thing wears, its image its colour: document/evaluate/material.h doc_material, stage/render/render_stage.h flat_laid)
        parts=(${(s.:.)wear})
        lit=-DLIT; [ $parts[2] = unlit ] && lit=
        $MATC -a webgpu -a metal -p desktop -TBLENDING=$parts[4] -TSHADE=$parts[2] $lit -D$parts[3] -o out/filament_webgpu/flat_$parts[1].filamat materials/flat.mat > out/filament_webgpu/flat_$parts[1].log 2>&1 || echo "no WebGPU material: flat_$parts[1] (out/filament_webgpu/flat_$parts[1].log)"
    done
    [ $f = bubble ] && { $MATC -a webgpu -a metal -p desktop -DWORN -o out/filament_webgpu/bubble_worn.filamat materials/bubble.mat > out/filament_webgpu/bubble_worn.log 2>&1 || echo "no WebGPU material: bubble_worn"; }   # (a thing wearing Bubble: stage/render/render_layers.h solid_wear)
done
# ThorVG here is the one built against Dawn (deps/thorvg.sh makes it): it can draw on Filament's own device
# (stage/canvas/canvas.h), through the interop built inside Filament's build (gpu_interop.h).
THOR=third_party/thorvg_src
[ -f $THOR/build_dawn/src/libthorvg-1.a ] || ./deps/thorvg.sh > /dev/null
meson configure $THOR/build_dawn -Dengines=cpu,wg -Dextra=lottie_exp > /dev/null   # (left on: meson set up again by a changed source takes ThorVG's defaults, the CPU engine alone)
ninja -C $THOR/build_dawn > /dev/null
# (stage/canvas/thorvg_path_operators.cpp: ThorVG's own path operators, built as ThorVG builds them; libtess2: a flat shape cut into triangles, flat_mesh)
[ out/bend.o -nt stage/canvas/thorvg_path_operators.cpp ] || clang++ -c -std=c++17 -I $PWD -O2 -fno-rtti -fno-exceptions -DTVG_STATIC -I $THOR/build_dawn -I $THOR/inc -I $THOR/src/common -I $THOR/src/renderer -I $THOR/src/renderer/gpu_engine -I $THOR/src/renderer/gpu_engine/wg -I $THOR/src/loaders/lottie -I $SRC/third_party/dawn/include -I $SRC/out/wgpu/third_party/dawn/gen/include stage/canvas/thorvg_path_operators.cpp -o out/bend.o
./deps/libtess2.sh
./deps/curve_fit_nd.sh   # (doc_curve: a hand's way turned into a path of cubic Béziers, as Blender's Draw Curve)
./deps/jolt.sh   # (physics/jolt.cpp: Jolt, which build.sh links)
./deps/iris.sh   # (media/video_flash_check.cpp: EA's IRIS and the OpenCV it reads, which build.sh links)
# (media/video_flash_check.cpp built apart, in IRIS's own C++17: its log lines pass runtime format strings, which C++20's fmt refuses)
I=third_party/iris
[ out/flashes.o -nt media/video_flash_check.cpp ] && [ out/flashes.o -nt entry/motolii.h ] || clang++ -c -std=c++17 -I $PWD -O2 -I $I/IRIS/include -I $I/IRIS/utils/include -I $I/spdlog/include -I $I/json/single_include -I $I/opencv_out/include/opencv4 media/video_flash_check.cpp -o out/flashes.o
./deps/midi_roll.sh   # (media/midi_roll.cpp: bladeSk's PianoRollSvg.js, read as the MIDI view is rendered)
# (stage/canvas/skia_path_operations.cpp: Skia's own path operations, its Boolean: deps/skia.sh builds it)
SKIA=third_party/skia_src
[ -f $SKIA/out/path/libpathops.a ] || ./deps/skia.sh
[ out/skpath.o -nt stage/canvas/skia_path_operations.cpp ] || clang++ -c -std=c++20 -I $PWD -O2 -DNDEBUG -fno-rtti -fno-exceptions -I $SKIA -I $THOR/inc stage/canvas/skia_path_operations.cpp -o out/skpath.o
AM_SRC=third_party/AbsentMotion   # (AbsentMotion, Apache-2.0: pinned as deps/skia.sh pins Skia; a checkout that never had it, CI's, fetches it here)
[ -d $AM_SRC ] || { mkdir -p $AM_SRC && git init -q $AM_SRC && git -C $AM_SRC -c core.hooksPath=/dev/null fetch -q --depth 1 https://github.com/Comett1225/AbsentMotion.git 0f5d891b7e6fd7260ca6191b4eafef23141230c8 && git -C $AM_SRC checkout -q FETCH_HEAD; } || exit 1
# (community/absent_motion/absent_motion.cpp: AbsentMotion's own motion and text effects, its motion.cpp, scene.cpp, easing.cpp and textanim.cpp as they are, with
#  Skia's headers; what of scene.cpp draws or reads a whole scene is not reached and is stripped: hidden, -dead_strip below)
AM=third_party/AbsentMotion/app/src/main/cpp
for f in motion scene easing textanim; do [ out/am_$f.o -nt $AM/$f.cpp ] || clang++ -c -std=c++20 -I $PWD -O2 -DNDEBUG -fno-rtti -fvisibility=hidden -I $SKIA -I $AM $AM/$f.cpp -o out/am_$f.o; done
[ out/absent_motion.o -nt community/absent_motion/absent_motion.cpp ] && [ out/absent_motion.o -nt community/absent_motion/absent_motion.h ] || clang++ -c -std=c++20 -I $PWD -O2 -DNDEBUG -fno-rtti -fvisibility=hidden -I $SKIA -I $AM community/absent_motion/absent_motion.cpp -o out/absent_motion.o
[ out/absent_drawing.o -nt community/absent_motion/absent_drawing.cpp ] && [ out/absent_drawing.o -nt $AM/drawing.cpp ] || clang++ -c -std=c++20 -I $PWD -O2 -DNDEBUG -fno-rtti -fvisibility=hidden -I $SKIA -I $AM community/absent_motion/absent_drawing.cpp -o out/absent_drawing.o   # (its drawing.cpp read whole: community/absent_motion/absent_drawing.cpp)
[ out/absent_ends.o -nt community/absent_motion/absent_ends.cpp ] && [ out/absent_ends.o -nt $AM/styles.cpp ] || clang++ -c -std=c++20 -I $PWD -O2 -DNDEBUG -fno-rtti -fvisibility=hidden -I $SKIA -I $AM community/absent_motion/absent_ends.cpp -o out/absent_ends.o   # (its styles.cpp read whole: community/absent_motion/absent_ends.cpp)
(cd $SRC/out/wgpu && ninja motolii_interop > /dev/null)
clang++ -std=c++20 -fobjc-arc -O2 -I "$SDK/include" -I $THOR/inc -I $THOR/src/loaders/lottie -I $SRC/third_party/dawn/include -I $SRC/out/wgpu/third_party/dawn/gen/include -I $PWD ${RENDER_SRC:-entry/$n.mm} ${=RENDER_EXTRA} \
    $THOR/build_dawn/src/libthorvg-1.a out/bend.o out/skpath.o out/absent_motion.o out/absent_ends.o out/absent_drawing.o out/am_motion.o out/am_scene.o out/am_easing.o out/am_textanim.o $SKIA/out/path/libpathops.a $SKIA/out/path/libskia.a -I third_party/libtess2/Include third_party/libtess2/build/libtess2.a -I third_party/curve_fit_nd/c third_party/curve_fit_nd/build/libcurve_fit_nd.a $SRC/out/wgpu/filament/motolii_probe/libmotolii_interop.a -L "$SDK/lib/arm64" \
    -lfilament -lbackend -lwebgpu_dawn -lbluegl -lbluevk -lfilabridge -lfilaflat \
    -lutils -lgeometry -lsmol-v -libl -lktxreader -lstb -luberzlib -lzstd \
    -lshaders -lperfetto -labseil -lmeshoptimizer -lcamutils -limage -lbasis_transcoder -luberarchive -lmatdbg -lfilamat -lcivetweb -lviewer \
    -framework Cocoa -framework SceneKit -framework ModelIO -framework Metal -framework CoreVideo -framework QuartzCore -framework IOSurface -framework IOKit \
    -lz -Wl,-dead_strip -o out/${n}_wgpu
[ -n "$BUILDONLY" ] && exit 0
cd out/filament_webgpu
BACKEND="${BACKEND:-webgpu}" ../${n}_wgpu 2>&1 | grep -v "FrameInfo's circular queue\|libvulkan\|BackendVk"
