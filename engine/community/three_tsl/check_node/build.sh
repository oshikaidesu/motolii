#!/bin/zsh
# The check (check.ts): Shader Lab's effects drawn by their author's own runtime on Dawn, in Node. Not part of Motolii.
#   ./community/three_tsl/check_node/build.sh && node out/tsl/check_node.mjs <type,type|layers.json> <picture.rgba> <w> <h> <out.rgba>
set -e
cd "$(dirname "$0")"
# The pointer passes read globalThis.motoliiTarget when a host names a point (engine/deps/patches/shader-lab/slab_target.patch).
patch -p1 -N -r - -d ../../../third_party/tsl/basementstudio__shader-lab < ../../../deps/patches/shader-lab/slab_target.patch >/dev/null || true
P=$(cd ../../../third_party/tsl/basementstudio__shader-lab/packages/shader-lab-react && pwd)
# (its pattern atlas finds its SVGs from where its published build sits: dist/src/renderer, pattern-atlas.ts:6-55)
NODE_PATH=$PWD/node_modules npx --prefix .. esbuild check.ts --bundle --format=esm --platform=node --outfile=../../../out/tsl/check_node.mjs \
  --tsconfig=../../../third_party/tsl/basementstudio__shader-lab/tsconfig.json --external:webgpu --external:@napi-rs/canvas \
  --external:typescript --log-level=error "--define:import.meta.url=\"file://$P/dist/src/renderer/pattern-atlas.js\""
