#!/bin/zsh
# Stylo, the CSS engine of Servo and Firefox, which Blitz runs (community/css): the crate as published on crates.io, fetched
# once into third_party/stylo_src, with deps/patches/stylo/stylo_bezier_epsilon.patch (a timing curve solved to 1e-7, as
# Chromium's kBezierEpsilon in ui/gfx/geometry/cubic_bezier.cc, not to 1 / (200 * duration): letters land where Chrome
# puts them). community/css/Cargo.toml takes it in place of the published crate ([patch.crates-io]).
#   ./deps/stylo.sh
set -e
cd "$(dirname "$0")/.."
S=$PWD/third_party/stylo_src
[ -d $S ] && exit 0
T=$(mktemp -d)
curl -sfL https://static.crates.io/crates/stylo/stylo-0.22.0.crate | tar -xz -C $T
patch -s -p1 -d $T/stylo-0.22.0 < deps/patches/stylo/stylo_bezier_epsilon.patch
mv $T/stylo-0.22.0 $S && rmdir $T
