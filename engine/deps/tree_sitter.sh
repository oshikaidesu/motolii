#!/bin/zsh
# tree-sitter (https://github.com/tree-sitter/tree-sitter, v0.27.2, MIT, Max Brunsfeld) and its JavaScript grammar
# (https://github.com/tree-sitter/tree-sitter-javascript, v0.25.0, MIT): fetched once into third_party (kept out of git,
# their LICENSE files with them) and built into out/ts_*.o, for js_returned.cpp. Called by edit.sh and build_lib.sh.
cd "$(dirname "$0")/.."
fetch() {   # (name, tag, the commit that tag is: what was read is what is built)
    [ -d third_party/$1 ] || git clone -q --depth 1 --branch $2 https://github.com/tree-sitter/$1.git third_party/$1 2> /dev/null || return 1
    [ "$(git -C third_party/$1 rev-parse HEAD)" = $3 ] || { echo "third_party/$1 is not $2 ($3)"; return 1; }
}
fetch tree-sitter v0.27.2 3fb7be49145acfb07e33b61ed5689e2b6771b2e9 || exit 1
fetch tree-sitter-javascript v0.25.0 44c892e0be055ac465d5eeddae6d3e194424e7de || exit 1
T=third_party/tree-sitter/lib J=third_party/tree-sitter-javascript/src
mkdir -p out
[ out/ts_lib.o -nt $T/src/lib.c ] || clang -c -std=c11 -O2 -I$T/include -I$T/src $T/src/lib.c -o out/ts_lib.o || exit 1
[ out/ts_js_parser.o -nt $J/parser.c ] || clang -c -std=c11 -O2 -I$J $J/parser.c -o out/ts_js_parser.o || exit 1
[ out/ts_js_scanner.o -nt $J/scanner.c ] || clang -c -std=c11 -O2 -I$J $J/scanner.c -o out/ts_js_scanner.o || exit 1
