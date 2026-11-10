#!/bin/zsh
# The C++ checked without building: clang's -fsyntax-only on every source of ours, with the flags CMake gives it
# (out/cmake/compile_commands.json, written by `cmake -S . -B out/cmake -G Ninja`). Nothing is written and no build
# lock is needed. Prints clang's errors; "ok: <count> sources" when there are none.
#   ./engine/check_syntax.sh                      every source
#   ./engine/check_syntax.sh document/undo.cpp    the sources whose path contains the word
cd "$(dirname "$0")"
[ -f out/cmake/compile_commands.json ] || cmake -S . -B out/cmake -G Ninja > /dev/null || exit 1
python3 - "$1" <<'PY'
import json, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
units = [u for u in json.load(open('out/cmake/compile_commands.json'))
         if '/third_party/' not in u['file'] and sys.argv[1] in u['file']]
def check(u):
    command = u['command'].split(' -o ')[0] + ' -fsyntax-only -Wno-everything ' + u['file']
    return subprocess.run(command, shell=True, cwd=u['directory'], capture_output=True, text=True).stderr
with ThreadPoolExecutor(8) as pool:
    errors = [e for e in pool.map(check, units) if e]
print('\n'.join(errors) if errors else f'ok: {len(units)} sources')
sys.exit(1 if errors else 0)
PY
