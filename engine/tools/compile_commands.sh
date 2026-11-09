#!/bin/zsh
# engine/compile_commands.json for an editor's clangd (clangd.llvm.org/installation#project-setup): the library's one
# translation unit, entry/motolii.mm, with the flags build.sh and gpu/filament_webgpu.sh build it with, and each other .cpp
# of ours with the same; then each header the context its unit reads it in (tools/clangd_context.py). Nothing is
# built. Run after the dependencies are fetched (build.sh once), from anywhere:
#   ./tools/compile_commands.sh
set -e
cd "$(dirname "$0")/.."
# (third_party/ is fetched, not kept in git: a git worktree has only the few folders git keeps. What is missing here is
# read from the main checkout's engine/third_party/, found through git rev-parse --git-common-dir, where it was fetched)
TP=third_party
if [ ! -d $TP/filament_src ]; then
  TP="$(cd "$(git rev-parse --git-common-dir 2>/dev/null)/.." && pwd)/engine/third_party"
  [ -d $TP/filament_src ] || { echo "${0:t}: third_party が無い：先に ./engine/build.sh を 1 回走らせろ（deps/ が取ってきて組む）" >&2; exit 1; }
fi
HB=${HOMEBREW_PREFIX:-$(brew --prefix)}
eval "$(grep -m1 '^    RENDER_EXTRA=' build.sh | sed 's/ BUILDONLY=1.*//; s/^ *//')"   # (build.sh's own flags, as it builds the library)
SRC=$TP/filament_src; SDK=$SRC/out/wgpu_install; THOR=$TP/thorvg_src; SKIA=$TP/skia_src
flags=(-std=c++20 -fobjc-arc -I $SDK/include -I $THOR/inc -I $THOR/src/loaders/lottie -I $SRC/third_party/dawn/include
       -I $SRC/out/wgpu/third_party/dawn/gen/include -I $PWD -I $TP/libtess2/Include -I $TP/curve_fit_nd/c
       -I $SKIA -I $TP/AbsentMotion/app/src/main/cpp)   # (gpu/filament_webgpu.sh's, and the -I its .o files are built with)
if [ $TP != third_party ]; then   # (our #include "third_party/filament_src/..." read after -I $PWD, so a file of ours is never the main checkout's)
  mkdir -p out/fetched && ln -sfn $TP out/fetched/third_party && flags+=(-I $PWD/out/fetched)
fi
for t in ${=RENDER_EXTRA}; do   # (build.sh's $PWD/third_party/<x>: kept here if git keeps it, else the fetched one)
  case $t in -I*|-D*|-F*) [[ $t == -?$PWD/third_party/* && ! -e ${t[3,-1]} ]] && t=${t[1,2]}$TP/${t#-?$PWD/third_party/}; flags+=$t;; esac
done
python3 - "$PWD" ${flags[@]} > compile_commands.json <<'PY'
import json, subprocess, sys
root, flags = sys.argv[1], sys.argv[2:]
own = [f for f in subprocess.run(['git', 'ls-files', '*.mm', '*.cpp'], capture_output=True, text=True, cwd=root).stdout.split()
       if not f.startswith('third_party/')]
print(json.dumps([{'directory': root, 'file': f, 'arguments': ['clang++', *flags, '-c', f]} for f in own], indent=1))
PY
echo "compile_commands.json: $(grep -c '"file"' compile_commands.json) units"
python3 tools/clangd_context.py   # (each header of ours: the context its unit reads it in)
