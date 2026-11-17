#!/bin/zsh
# Builds and runs the check inside the machine's build lock (engine/tools/build_lock.sh).
set -e
cd ${0:a:h}
source ../../../engine/tools/build_lock.sh; build_lock "$@"
export CARGO_TARGET_DIR=$PWD/target
(cd check && cargo build --release 2>&1 | tail -${LINES_SHOWN:-25})
build_unlock
