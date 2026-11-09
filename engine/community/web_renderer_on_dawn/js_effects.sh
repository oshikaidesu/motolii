#!/bin/zsh
# A web effect's own renderer inside this process on Filament's Dawn device (js_effects.cpp): Motolii's QuickJS with
# JsRuntimeHost's Node-API (community/web_renderer_on_dawn/node_api_quickjs/build.sh made its sources), Dawn's dawn.node with deps/patches/dawn/dawn_lend.patch (out/wgpu).
# (libraries: the list gpu/filament_webgpu.sh links)
#   ./community/web_renderer_on_dawn/js_effects.sh <preset.json> <w> <h> <frames> <out.rgba>
set -e
cd "$(dirname "$0")/../.."
source tools/build_lock.sh; build_lock "$@"   # (the machine's one build lock, taken here: tools/build_lock.sh)
HB=${HOMEBREW_PREFIX:-$(brew --prefix)}   # (where Homebrew is: /opt/homebrew on Apple silicon)
SRC=third_party/filament_src
SDK=$SRC/out/wgpu_install
J=out/web_renderer_on_dawn/src/Node-API
Q=$HB/opt/quickjs-ng
(cd $SRC/out/wgpu && ninja motolii_interop third_party/dawn/dawn.node > /dev/null)
[ -d $J ] || ./community/web_renderer_on_dawn/node_api_quickjs/build.sh > /dev/null
(cd community/web_renderer_on_dawn && npx esbuild node_api_quickjs/shaders.ts --bundle --format=esm --platform=neutral '--external:qjs:*' --main-fields=module,main \
    '--define:process.env.NODE_ENV="production"' --outfile=../../out/web_renderer_on_dawn/shaders.mjs --log-level=warning)   # (the authors' built package, as it is)
clang++ -std=c++20 -O2 -w -DNAPI_VERSION=8 -I "$SDK/include" -I $SRC/third_party/dawn/include -I $SRC/out/wgpu/third_party/dawn/gen/include \
    -I $Q/include -I $J/Include/Shared -I $J/Include/Engine/QuickJS -I $J/Source -I gpu community/web_renderer_on_dawn/js_effects.cpp \
    $J/Source/js_native_api_quickjs.cc $J/Source/js_native_api_shared.cc $J/Source/env_quickjs.cc -L $Q/lib -lqjs -Wl,-rpath,$Q/lib \
    $SRC/out/wgpu/filament/motolii_probe/libmotolii_interop.a -Wl,-export_dynamic -L "$SDK/lib/arm64" \
    -lfilament -lbackend -lwebgpu_dawn -lbluegl -lbluevk -lfilabridge -lfilaflat \
    -lutils -lgeometry -lsmol-v -libl -lktxreader -lstb -luberzlib -lzstd \
    -lshaders -lperfetto -labseil -lmeshoptimizer -lcamutils -limage -lbasis_transcoder -luberarchive -lmatdbg -lfilamat -lcivetweb \
    -framework Cocoa -framework Metal -framework CoreVideo -framework QuartzCore -framework IOSurface -framework IOKit -lz -o out/js_effects
DAWN_NODE=$PWD/$SRC/out/wgpu/third_party/dawn/dawn.node EFFECT_JS=$PWD/out/web_renderer_on_dawn/shaders.mjs ./out/js_effects "$@"
