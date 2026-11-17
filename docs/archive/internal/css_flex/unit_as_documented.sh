#!/bin/zsh
# The command docs/TESTING.md gives, inside the machine's build lock.
cd ${0:a:h}/../../..
source engine/tools/build_lock.sh; build_lock "$@"
cargo test --release --manifest-path engine/community/css/Cargo.toml --target-dir engine/out/cargo_test 2>&1 | grep -E "^test |test result|panicked|^error" | head
build_unlock
