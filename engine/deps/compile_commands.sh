#!/bin/zsh
# engine/compile_commands.json for an editor's clangd (clangd.llvm.org/installation#project-setup): the library's one
# translation unit, library/motolii.mm, with the flags gpu/kit_wgpu.sh and edit.sh build it with, and each other .cpp
# of ours with the same; then each header the context its unit reads it in (deps/clangd_context.py). Nothing is
# built. Run after the dependencies are fetched (edit.sh once), from anywhere:
#   ./deps/compile_commands.sh
set -e
cd "$(dirname "$0")/.."
HB=${HOMEBREW_PREFIX:-$(brew --prefix)}
eval "$(grep -m1 '^    KIT_EXTRA=' edit.sh | sed 's/ BUILDONLY=1.*//; s/^ *//')"   # (edit.sh's own flags, as it builds the library)
SRC=third_party/filament_src; SDK=$SRC/out/wgpu_install; THOR=third_party/thorvg_src; SKIA=third_party/skia_src
flags=(-std=c++20 -fobjc-arc -I $SDK/include -I $THOR/inc -I $THOR/src/loaders/lottie -I $SRC/third_party/dawn/include
       -I $SRC/out/wgpu/third_party/dawn/gen/include -I $PWD -I third_party/libtess2/Include -I third_party/curve_fit_nd/c
       -I $SKIA -I third_party/AbsentMotion/app/src/main/cpp)   # (gpu/kit_wgpu.sh's, and the -I its .o files are built with)
for t in ${=KIT_EXTRA}; do case $t in -I*|-D*|-F*) flags+=$t;; esac; done
python3 - "$PWD" ${flags[@]} > compile_commands.json <<'PY'
import json, subprocess, sys
root, flags = sys.argv[1], sys.argv[2:]
own = [f for f in subprocess.run(['git', 'ls-files', '*.mm', '*.cpp'], capture_output=True, text=True, cwd=root).stdout.split()
       if not f.startswith('third_party/')]
print(json.dumps([{'directory': root, 'file': f, 'arguments': ['clang++', *flags, '-c', f]} for f in own], indent=1))
PY
echo "compile_commands.json: $(grep -c '"file"' compile_commands.json) units"
python3 deps/clangd_context.py   # (each header of ours: the context its unit reads it in)
