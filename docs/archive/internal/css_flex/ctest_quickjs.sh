#!/bin/zsh
# Builds and runs the quickjs module's tests inside the machine's build lock.
cd ${0:a:h}/../../../engine
source tools/build_lock.sh; build_lock "$@"
cmake --build out/cmake --target motolii_community_quickjs_test 2>&1 | grep -E "error|FAILED" | head -10
ctest --test-dir out/cmake -R '^ScriptFiles' 2>&1 | grep -E "Test +#|tests passed|tests failed|No tests" | head
build_unlock
