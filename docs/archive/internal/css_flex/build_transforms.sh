#!/bin/zsh
set -e
cd ${0:a:h}
source ../../../engine/tools/build_lock.sh; build_lock "$@"
export CARGO_TARGET_DIR=$PWD/target
(cd transforms_check && cargo build --release 2>&1 | grep -E "^(error|warning: unus)|Finished" -A8)
build_unlock
