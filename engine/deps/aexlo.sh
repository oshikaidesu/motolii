#!/bin/zsh
# aexlo (potistudio, MIT): After Effects plugin (.plugin / .aex) runtime, pinned to one commit in third_party/aexlo_src
# with patches in deps/patches/aexlo/ applied:
#   downsample.patch: exposes PluginInstance::set_downsample(num, den) for Half-resolution preview rendering.
# Builds the isolated worker binary out/motolii_ae_worker (community/after_effects_plugin/) so a misbehaving or hanging
# native plugin cannot crash or freeze the editor.
#   ./deps/aexlo.sh
set -e
cd "$(dirname "$0")/.."
source tools/build_lock.sh; build_lock "$@"
SRC=$PWD/third_party/aexlo_src
COMMIT=4733ffdf966d9fea3a4d7dea4dfb1b8a65ca6178
PATCHES=(deps/patches/aexlo/*.patch(N))
SUM="${COMMIT}:$([ ${#PATCHES} -gt 0 ] && cat $PATCHES | { shasum 2>/dev/null || sha256sum; } | cut -c1-16 || echo none)"
if [ ! -d "$SRC" ] || [ "$(cat "$SRC/.patches" 2>/dev/null)" != "$SUM" ]; then
  if [ ! -d "$SRC/.git" ]; then
    rm -rf "${SRC:?}"
    mkdir -p "$SRC"
    git init -q "$SRC"
    git -C "$SRC" -c core.hooksPath=/dev/null fetch -q --depth 1 https://github.com/potistudio/aexlo.git "$COMMIT"
  fi
  git -C "$SRC" checkout -q -f FETCH_HEAD
  for p in $PATCHES; do patch -s -p1 -d "$SRC" < "$p"; done
  echo "$SUM" > "$SRC/.patches"
fi
EXT=""
[[ $OSTYPE == (msys|cygwin)* ]] && EXT=".exe"
OUT="$PWD/out/motolii_ae_worker${EXT}"
WORKER_DIR="$PWD/community/after_effects_plugin"
if [ ! -f "$OUT" ] || [ -n "$(find "$WORKER_DIR/Cargo.toml" "$WORKER_DIR/src" "$SRC/.patches" -newer "$OUT" -print -quit)" ]; then
  TOOLCHAIN=""
  if command -v rustup >/dev/null 2>&1; then
    rustup toolchain list | grep -q '^1\.99\.0' && TOOLCHAIN="+1.99.0"
  fi
  (cd "$WORKER_DIR" && cargo ${TOOLCHAIN:+$TOOLCHAIN} build --release --target-dir "$PWD/../../out/aexlo_target" >/dev/null)
  cp "$PWD/out/aexlo_target/release/motolii_ae_worker${EXT}" "$OUT"
fi
build_unlock
