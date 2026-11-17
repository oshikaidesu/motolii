#!/bin/zsh
# The adapter's own tests (cargo test), inside the machine's build lock.
cd ${0:a:h}
source ../../../engine/tools/build_lock.sh; build_lock "$@"
export CARGO_TARGET_DIR=$PWD/target
(cd ../../../engine/community/css && cargo test --release 2>&1 | grep -E "^test |test result|panicked|error" | head -20)
build_unlock
