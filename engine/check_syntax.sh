#!/bin/zsh
# The C++ checked without building (no lock, nothing written): clang++ -fsyntax-only on the library's one translation
# unit (library/motolii.mm, which reads every header of ours it uses) with the flags it is built with, taken from
# compile_commands.json (deps/compile_commands.sh writes it when it is missing). Errors printed, the exit status clang's.
#   ./engine/check_syntax.sh                 the library      ./engine/check_syntax.sh community/aviutl/aviutl.cpp   another unit
cd "$(dirname "$0")"
unit=${1:-library/motolii.mm}
read_args() {
  args=("${(@f)$(python3 -c '
import json, sys
for u in json.load(open("compile_commands.json")):
    if u["file"] == sys.argv[1]: print("\n".join(a for a in u["arguments"][1:] if a not in ("-c", sys.argv[1]))); break
else: sys.exit("not a unit in compile_commands.json: " + sys.argv[1])' $unit)}")
}
# (written again when missing, or when a third_party folder it names is gone: written in another checkout, or before the
# fetch. compile_commands.sh says in one line if third_party is in neither this checkout nor the main one)
stale=1
if [ -f compile_commands.json ]; then
  read_args || exit 1
  stale=0; for a in $args; do p=${a#-I}; [[ $p != -* && $p == *third_party/* && ! -e $p ]] && stale=1 && break; done
fi
if (( stale )); then ./deps/compile_commands.sh > /dev/null || exit 1; read_args || exit 1; fi
clang++ -fsyntax-only -Wno-everything ${args[@]} $unit && echo "ok: $unit"
