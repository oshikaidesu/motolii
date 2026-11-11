#!/bin/zsh
# One collection's entry (tsl_textures.ts, ...) bundled by esbuild (bundle.mjs) with this folder's three.js (package.json) and run in
# QuickJS: its effects land as WGSL in engine/out/tsl/<collection>/, then each is checked by naga.   ./community/three_shading_language_to_shelf/run.sh tsl_textures
set -e
cd "$(dirname "$0")"
node bundle.mjs $1
n=$1; shift
qjs -m ../../out/tsl/$n.mjs "$@"
