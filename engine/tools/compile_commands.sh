#!/bin/zsh
# engine/compile_commands.json for an editor's clangd (clangd.llvm.org/installation#project-setup) and for the checks
# that compile nothing (check_syntax.sh, tools/check_file.sh, tools/check_link.py): each .cpp and .mm of ours with the
# flags it is built with.
#   entry/motolii.mm, and the .cpp compiled on its command line: the flags of build.sh and gpu/filament_webgpu.sh
#   a .cpp one of those two scripts compiles by itself (isf.cpp, thorvg_path_operators.cpp, ...): the flags of its line
#   the interop of gpu/CMakeLists.txt, built inside Filament's build: the flags CMake recorded there
# Then each header gets the context its unit reads it in (tools/clangd_context.py). Nothing is built. Run after the
# dependencies are fetched (build.sh once), from anywhere:
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
python3 - "$PWD" $TP $HB ${flags[@]} <<'PY'
import json, os, re, shlex, subprocess, sys
root, fetched, homebrew, flags = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
own = [f for f in subprocess.run(['git', 'ls-files', '*.mm', '*.cpp'], capture_output=True, text=True, cwd=root).stdout.split()
       if not f.startswith('third_party/')]
# (a unit one of the two scripts compiles by itself: the words between `clang++` and its path on that line, each $NAME
# as the scripts set it, NAME=third_party/<folder>; read from the fetched third_party when this checkout has none)
scripts = open('build.sh').read() + open('gpu/filament_webgpu.sh').read()
names = {name: path if os.path.exists(path) else fetched + path[len('third_party'):]
         for name, path in re.findall(r'^\s*(\w+)=(third_party/\S+)', scripts, re.M)}
names.update(PWD=root, HB=homebrew)


def own_line(unit):
    line = re.search(r'clang\+\+ (.*?) ' + re.escape(unit) + ' ', scripts)
    try:
        return line and [word for word in shlex.split(re.sub(r'\$(\w+)', lambda name: names[name.group(1)], line.group(1))) if word != '-c']
    except KeyError as name:
        sys.exit(f'compile_commands.sh: {unit} is compiled with ${name.args[0]}, which neither script sets as NAME=third_party/<folder>')


# (the interop: Filament's own CMake build compiles it, in the folder its patch names motolii_probe, and recorded its flags)
interop, recorded = None, os.path.join(fetched, 'filament_src/out/wgpu/compile_commands.json')
for entry in json.load(open(recorded)) if os.path.exists(recorded) else []:
    if '/motolii_probe/' in entry.get('output', ''):
        words = shlex.split(entry['command'])[1:]
        interop = [word for at, word in enumerate(words) if word not in ('-c', '-o', entry['file']) and words[at - 1] != '-o']
        break
in_filament = [f for f in own if f.startswith('gpu/') and re.search(r'\b' + re.escape(f[4:]), open('gpu/CMakeLists.txt').read())]
if not interop:
    print(f'compile_commands.sh: no flags for {" ".join(in_filament)} in {recorded}: they get the library\'s and cannot be checked', file=sys.stderr)
units = {f: own_line(f) or (interop if f in in_filament else None) or flags for f in own}
json.dump([{'directory': root, 'file': f, 'arguments': ['clang++', *units[f], '-c', f]} for f in own], open('compile_commands.json', 'w'), indent=1)
print(f'compile_commands.json: {len(own)} units, {sum(units[f] is not flags for f in own)} of them with flags of their own')
PY
python3 tools/clangd_context.py   # (each header of ours: the context its unit reads it in)
