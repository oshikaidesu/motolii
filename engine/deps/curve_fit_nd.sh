#!/bin/zsh
# curve-fit-nd (Campbell Barton, BSD-3-Clause; Blender's extern/curve_fit_nd): a hand's points made one path of cubic
# Béziers within an error, its corners kept, as Blender's Draw Curve tool does (editcurve_paint.cc). Fetched once into
# third_party/curve_fit_nd, built as one static library: third_party/curve_fit_nd/build/libcurve_fit_nd.a.
#   ./deps/curve_fit_nd.sh
set -e
cd "$(dirname "$0")/.."
source tools/build_lock.sh; build_lock "$@"   # (the machine's one build lock, taken here: tools/build_lock.sh)
C=$PWD/third_party/curve_fit_nd
[ -d $C ] || { mkdir -p $C && git init -q $C && git -C $C -c core.hooksPath=/dev/null fetch -q --depth 1 https://github.com/ideasman42/curve-fit-nd 7b8611f66c7bf029a19eb86ce9e388e55fad5e6f && git -C $C checkout -q FETCH_HEAD; }
mkdir -p $C/build
[ -f $C/build/libcurve_fit_nd.a ] || (cd $C/build && cc -O2 -DNDEBUG -c -I ../c ../c/intern/*.c && ar rcs libcurve_fit_nd.a *.o)
