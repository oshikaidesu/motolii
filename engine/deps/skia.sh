#!/bin/zsh
# Skia's paths alone (its path ops, path effects, contour measure, stroker): the official source at the commit we use (on chrome/m149),
# fetched once into third_party/skia_src, built as fontTools' skia-pathops builds it (no GPU, fonts, images or PDF).
# Cavalry draws its shapes' paths with the same. Out comes third_party/skia_src/out/path/libskia.a.
#   ./deps/skia.sh
set -e
cd "$(dirname "$0")/.."
source tools/build_lock.sh; build_lock "$@"   # (the machine's one build lock, taken here: tools/build_lock.sh)
K=$PWD/third_party/skia_src
[ -d $K ] || { mkdir -p $K && git init -q $K && git -C $K -c core.hooksPath=/dev/null fetch -q --depth 1 https://skia.googlesource.com/skia 9bb16a741cdbcbde46a0d4caf8ac73f4d07a89e2 && git -C $K checkout -q FETCH_HEAD; }   # (chrome/m149 as it stood when fetched)
# On Windows: Windows' Python is python, and gn is told so; Skia is compiled by clang-cl for the runtime DLL, as the engine
# is; its objects are .obj and its library skia.lib, which is copied to the Mac's name.
PYTHON=python3 GN=() WINDOWS= O=o A=ar
if [[ $OSTYPE == (msys|cygwin)* ]]; then
    PYTHON=python GN=(--script-executable=$(command -v python)) O=obj A=$AR
    WINDOWS=" clang_win=\"$(cygpath -m ${$(command -v clang-cl):h:h})\" extra_cflags=[\"/MD\"]"
fi
[ -x $K/bin/gn ] || (cd $K && $PYTHON bin/fetch-gn > /dev/null)
[ -f $K/out/path/build.ninja ] || (cd $K && bin/gn gen out/path $GN --args='is_official_build=true is_debug=false skia_enable_pdf=false
    skia_enable_discrete_gpu=false skia_enable_ganesh=false skia_enable_graphite=false skia_enable_skottie=false skia_enable_skshaper=false
    skia_use_dng_sdk=false skia_use_expat=false skia_use_freetype=false skia_use_fontconfig=false skia_use_fonthost_mac=false skia_use_gl=false
    skia_use_harfbuzz=false skia_use_icu=false skia_use_libjpeg_turbo_encode=false skia_use_libjpeg_turbo_decode=false skia_use_libpng_encode=false
    skia_use_libpng_decode=false skia_use_libwebp_encode=false skia_use_libwebp_decode=false skia_use_piex=false skia_use_xps=false skia_use_zlib=false
    skia_enable_spirv_validation=false skia_use_lua=false skia_use_wuffs=false skia_enable_fontmgr_empty=true'"$WINDOWS" > /dev/null)
ninja -C $K/out/path skia pathops > /dev/null
[ -f $K/out/path/skia.lib ] && cp $K/out/path/skia.lib $K/out/path/libskia.a
$A rcs $K/out/path/libpathops.a $K/out/path/obj/src/pathops/*.$O   # (its path ops, a part of its own: union, difference, intersection, xor; Cavalry's Boolean)
