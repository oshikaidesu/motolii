#!/bin/zsh
# Stylo, the CSS engine of Servo and Firefox, which Blitz runs (community/css): the crate as published on crates.io, fetched
# into third_party/stylo_src with every patch in deps/patches/stylo/ applied:
#   stylo_bezier_epsilon.patch: a timing curve solved to 1e-7, as Chromium's kBezierEpsilon in
#     ui/gfx/geometry/cubic_bezier.cc, not to 1 / (200 * duration): letters land where Chrome puts them.
#   stylo_iteration_boundary.patch: at the end of an iteration the next one has begun (Web Animations 1, §4.8.4), within
#     Chromium's one microsecond (TimeTolerance, blink timing_calculations.cc), so a
#     frame landing on it shows the keyframes' start, as Chrome does.
# community/css/Cargo.toml takes it in place of the published crate ([patch.crates-io]). A copy made with other patches
# (their sums kept in it) is fetched again.
#   ./deps/stylo.sh
set -e
cd "$(dirname "$0")/.."
S=$PWD/third_party/stylo_src
P=(deps/patches/stylo/*.patch)
SUM=$(cat $P | shasum | cut -c1-16)
[ "$(cat $S/.patches 2>/dev/null)" = "$SUM" ] && exit 0
T=$(mktemp -d)
curl -sfL https://static.crates.io/crates/stylo/stylo-0.22.0.crate | tar -xz -C $T
for p in $P; do patch -s -p1 -d $T/stylo-0.22.0 < $p; done
echo $SUM > $T/stylo-0.22.0/.patches
rm -rf "${S:?}" && mv $T/stylo-0.22.0 $S && rmdir $T
