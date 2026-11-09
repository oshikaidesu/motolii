#!/bin/sh
# Two checkers that are not ours, on our own code:
#   ast-grep (ast-grep.github.io) with the rules in .githooks/rules/: shapes that may not be written (a press or a
#     picture by hand in Dart, a layer kind compared by name in C++). `ast-grep scan` exits 1 on a rule of severity error.
#   clang-format (clang.llvm.org/docs/ClangFormat.html) with /.clang-format: the engine's C++ as the formatter leaves it,
#     160 wide like the Dart side. `--dry-run --Werror` writes nothing and exits 1 on a file it would change.
#   shape_check.sh          the files staged for this commit: the pre-commit hook
#   shape_check.sh --all    every own file of the checkout: CI (.github/workflows/checks.yml), or by hand
# A checker that is not installed is skipped here and said so; CI has both.
cd "$(git rev-parse --show-toplevel)" || exit 1
if [ "$1" = --all ]; then
    list() { git ls-files -- "$@"; }
else
    list() { git diff --cached --name-only --diff-filter=ACMR -- "$@"; }
fi
dart=$(list 'app/lib/*.dart')
cpp=$(list 'engine/*.h' 'engine/*.cpp' 'engine/*.mm' | grep -v -e '^engine/third_party/' -e '^engine/out/')
bad=0
if [ -n "$dart$cpp" ]; then
    if command -v ast-grep >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        ast-grep scan -c .githooks/sgconfig.yml $dart $cpp >&2 || bad=1
    else
        echo "shape check: ast-grep is not installed (brew bundle); skipped here, CI runs it" >&2
    fi
fi
if [ -n "$cpp" ]; then
    format=$(command -v clang-format || xcrun --find clang-format 2>/dev/null)
    if [ -n "$format" ]; then
        off=0
        for f in $cpp; do
            "$format" --dry-run --Werror "$f" >/dev/null 2>&1 || { off=$((off + 1)); echo "  $f" >&2; }
        done
        if [ "$off" -gt 0 ]; then
            echo "shape check: $off C++ file(s) above are not as clang-format leaves them; clang-format -i <file> (/.clang-format)" >&2
            bad=1
        fi
    else
        echo "shape check: clang-format is not installed (Xcode has it); skipped here, CI runs it" >&2
    fi
fi
exit $bad
