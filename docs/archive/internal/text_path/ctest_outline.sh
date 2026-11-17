#!/bin/zsh
# Builds and runs the canvas module's text outline test inside the machine's build lock.
cd ${0:a:h}/../../../engine
source tools/build_lock.sh; build_lock "$@"
cmake --build out/cmake --target motolii_stage_canvas_test 2>&1 | grep -E "error|FAILED" | head -10
ctest --test-dir out/cmake -R '^TextOutline' --output-on-failure 2>&1 | grep -E "Test +#|tests passed|tests failed|No tests|Expected|contour|Skipped|size" | head -12
build_unlock
