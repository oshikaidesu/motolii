#!/bin/zsh
# One file of ours checked alone, without building: does it compile with only what it includes itself?
# clang++ -fsyntax-only with the flags of the library's unit (entry/motolii.mm in compile_commands.json); a .cpp or .mm
# that is a unit there is checked with its own.
#   a header   as C++, included twice from a stub on stdin (the second time proves its include guard)
#   a .cpp     as C++; a static function it uses and never defines is an error (-Werror=undefined-internal)
#   a .mm      as Objective-C++, the same
# It writes nothing, so many can run at once. It does not make compile_commands.json either: when that is missing,
# run tools/compile_commands.sh once.
#   ./engine/tools/check_file.sh stage/canvas/canvas.h media/midi_roll.cpp    "ok: <file>" each, or clang's errors
#   ./engine/tools/check_file.sh -q $(git ls-files 'engine/*.h' ':!engine/third_party')
#                                                     one line a file and no errors, then "30 of 107 pass alone"
# Paths are from engine/ (a leading engine/ is dropped). The exit status is 1 when any file fails.
self=${0:A}
cd ${self:h:h}
quiet=0
if [[ $1 == -q ]]; then quiet=1; shift; fi
(( $# )) || { sed -n '2,13s/^# \{0,1\}//p' $self >&2; exit 2; }
[ -f compile_commands.json ] || { echo "${0:t}: no compile_commands.json: run ./engine/tools/compile_commands.sh once" >&2; exit 2; }

flags_of() {   # (the recorded flags of unit $1, one a line; nothing when it is not a unit there)
  python3 -c '
import json, sys
for u in json.load(open("compile_commands.json")):
    if u["file"] == sys.argv[1]: print("\n".join(a for a in u["arguments"][1:] if a not in ("-c", sys.argv[1]))); break' $1
}
library=("${(@f)$(flags_of entry/motolii.mm)}")
(( $#library > 1 )) || { echo "${0:t}: entry/motolii.mm is not a unit in compile_commands.json" >&2; exit 2; }

passed=0
for f in "$@"; do
  f=${${f#$PWD/}#engine/}
  [ -f $f ] || { echo "no such file: engine/$f" >&2; continue; }
  case $f in
    *.h)   said=$(printf '#include "%s"\n#include "%s"\n' $f $f | clang++ -fsyntax-only -Wno-everything -x c++ ${library[@]} - 2>&1) ;;
    *.cpp|*.mm)
      own=("${(@f)$(flags_of $f)}"); (( $#own > 1 )) || own=(${library[@]})
      [[ $f == *.mm ]] && lang=objective-c++ || lang=c++
      said=$(clang++ -fsyntax-only -Wno-everything -Werror=undefined-internal -x $lang ${own[@]} $f 2>&1) ;;
    *)     echo "not a .h, .cpp or .mm: $f" >&2; continue ;;
  esac
  if [ $? = 0 ]; then
    echo "ok: $f"; passed=$((passed + 1))
  elif (( quiet )); then
    echo "fails alone: $f"
  else
    print -r -- "$said"; echo "fails alone: $f"
  fi
done
(( $# > 1 )) && echo "$passed of $# pass alone"
(( passed == $# ))
