#!/bin/zsh
# Builds and runs the document module's tests and the canvas module's, inside the machine's build lock.
cd ${0:a:h}/../../../engine
source tools/build_lock.sh; build_lock "$@"
cmake --build out/cmake --target motolii_document_test motolii_stage_canvas_test 2>&1 | grep -E "error|FAILED" | head -10
ctest --test-dir out/cmake -R '^(Cards|TextOutline|DocCards|Card)' 2>&1 | grep -E "tests passed|tests failed|No tests|Failed|\*\*\*" | head -12
build_unlock
