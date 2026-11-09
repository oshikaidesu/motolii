#!/bin/zsh
# The C++ checked without building (no lock, nothing written): clang++ -fsyntax-only on the library's one translation
# unit (library/motolii.mm, which reads every header of ours it uses) with the flags it is built with, taken from
# compile_commands.json (deps/compile_commands.sh writes it when it is missing). Errors printed, the exit status clang's.
#   ./engine/check_syntax.sh                 the library      ./engine/check_syntax.sh community/aviutl/aviutl.cpp   another unit
cd "$(dirname "$0")"
[ -f compile_commands.json ] || ./deps/compile_commands.sh > /dev/null || exit 1
unit=${1:-library/motolii.mm}
args=("${(@f)$(python3 -c '
import json, sys
for u in json.load(open("compile_commands.json")):
    if u["file"] == sys.argv[1]: print("\n".join(a for a in u["arguments"][1:] if a not in ("-c", sys.argv[1]))); break
else: sys.exit("not a unit in compile_commands.json: " + sys.argv[1])' $unit)}") || exit 1
clang++ -fsyntax-only -Wno-everything ${args[@]} $unit && echo "ok: $unit"
