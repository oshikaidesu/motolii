#!/bin/sh
# A checker that is not ours, on our own code:
#   ast-grep (ast-grep.github.io) with the rules in .githooks/rules/: shapes that may not be written (a press or a
#     picture by hand in Dart, a layer kind compared by name in C++). `ast-grep scan` exits 1 on a rule of severity error.
#   shape_check.sh          the files staged for this commit: the pre-commit hook. A staged file may hold no more
#                           refused shapes than it held at HEAD, so the count only falls
#   shape_check.sh --all    every own file of the checkout: CI (.github/workflows/checks.yml), or by hand
# When it is not installed it is skipped here and said so; CI has it.
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
        if [ "$1" = --all ]; then
            # shellcheck disable=SC2086
            ast-grep scan -c .githooks/sgconfig.yml $dart $cpp >&2 || bad=1
        else
            # a commit: a file may hold no more refused shapes than it held at HEAD (a new file: none). So a file
            # half cleaned can be committed and the count only falls (a ratchet: github.com/imbue-ai/ratchets).
            was_at=$(mktemp -d)
            refused() { ast-grep scan -c "$PWD/.githooks/sgconfig.yml" --json=stream "$1" 2>/dev/null | grep -c '"severity":"error"'; }
            for f in $dart $cpp; do
                now=$(refused "$f")
                mkdir -p "$was_at/$(dirname "$f")"
                if git show "HEAD:$f" > "$was_at/$f" 2>/dev/null; then was=$(refused "$was_at/$f"); else was=0; fi
                if [ "$now" -gt "$was" ]; then
                    ast-grep scan -c .githooks/sgconfig.yml "$f" >&2
                    echo "shape check: $f holds $now refused shapes, it held $was at HEAD; the count only falls" >&2
                    bad=1
                fi
            done
            rm -rf "$was_at"
        fi
    else
        echo "shape check: ast-grep is not installed (brew bundle); skipped here, CI runs it" >&2
    fi
fi
exit $bad
