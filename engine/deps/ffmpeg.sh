#!/bin/zsh
# FFmpeg 9.0.2 (the FFmpeg project): the official release tarball, fetched once into third_party/ffmpeg_src (the SHA-256
# below was taken from the first download; the release is signed, the signature is not checked here) and built as shared
# libraries and the ffmpeg and ffprobe programs into third_party/ffmpeg_lgpl/.
# LGPL only (ffmpeg.org/legal.html, checklist items 1, 2 and 18): no --enable-gpl, no --enable-nonfree, no libx264 or libx265,
# shared and not static. H.264 and HEVC are written by Apple's VideoToolbox. Source and binaries match: no patches.
# The configure line is kept in third_party/ffmpeg_lgpl/CONFIGURE.txt (item 6).
#   ./deps/ffmpeg.sh
set -e
cd "$(dirname "$0")/.."
source tools/build_lock.sh; build_lock "$@"   # (the machine's one build lock, taken here: tools/build_lock.sh)
V=9.0.2
SHA=8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e
SRC=$PWD/third_party/ffmpeg_src
OUT=$PWD/third_party/ffmpeg_lgpl
if [ ! -d $SRC ]; then
    tmp=$(mktemp -d)
    curl -fL -s -o $tmp/ffmpeg.tar.xz https://ffmpeg.org/releases/ffmpeg-$V.tar.xz
    actual=$({ shasum -a 256 $tmp/ffmpeg.tar.xz 2>/dev/null || sha256sum $tmp/ffmpeg.tar.xz; } | cut -d' ' -f1)
    [ "$actual" = $SHA ] || { echo "ffmpeg-$V.tar.xz: its SHA-256 is not the one this script knows"; rm -rf $tmp; exit 1; }
    mkdir -p $SRC && tar -xf $tmp/ffmpeg.tar.xz -C $SRC --strip-components 1
    rm -rf $tmp
fi
# (--disable-autodetect: a library on this machine is used only when named here, so the build is the same on another one)
CONFIGURE=(--prefix=$OUT --disable-gpl --disable-nonfree --disable-autodetect --enable-shared --disable-static
           --disable-doc --disable-debug --disable-ffplay --enable-zlib)
case "$(uname -s)" in
    Darwin) CONFIGURE+=(--enable-videotoolbox --enable-audiotoolbox); cpus=$(sysctl -n hw.ncpu) ;;
    # (Linux: written from docs/engine/PACKAGING.md and NOT run: no Linux machine has built it. --enable-pic is what
    # FFmpeg's platform page asks for a shared build; an encoder, h264_vaapi or h264_nvenc, is added once one can be tried.)
    Linux)  CONFIGURE+=(--enable-pic); cpus=$(nproc) ;;
    MSYS*|MINGW*)   # (MSYS2's make and nasm, MSVC's cl: run inside the VS developer environment, see build.sh)
        OUT=$(cygpath -m $OUT)   # (E:/..., which the .pc files carry to Windows' own pkg-config)
        # (mfenc.c needs d3d11va's headers.) zlib is GStreamer's z.lib, under the name configure gives -lz with MSVC (zlib.lib)
        mkdir -p $SRC/zlib && cp $GSTREAMER_1_0_ROOT_MSVC_X86_64/lib/z.lib $SRC/zlib/zlib.lib
        GSTREAMER_SHORT=$(cygpath -ms "$GSTREAMER_1_0_ROOT_MSVC_X86_64")
        CONFIGURE=(--prefix=$OUT ${CONFIGURE[2,-1]} --toolchain=msvc --arch=x86_64 --enable-mediafoundation --enable-d3d11va
                   --extra-cflags=-I$(cygpath -m $GSTREAMER_SHORT/include) --extra-ldflags=-LIBPATH:$(cygpath -m $SRC/zlib))
        unset CFLAGS CC CXX AR   # (build.sh's are clang's, for deps/ built by hand: FFmpeg picks MSVC's itself)
        cpus=$NUMBER_OF_PROCESSORS ;;
    *) echo "ffmpeg: this script does not build on $(uname -s): see docs/engine/PACKAGING.md"; exit 1 ;;
esac
if [ ! -x $OUT/bin/ffmpeg ]; then
    (cd $SRC && ./configure $CONFIGURE > /dev/null && make -j1 > /dev/null && make install > /dev/null)
    mkdir -p $OUT && print -r -- "./configure $CONFIGURE" > $OUT/CONFIGURE.txt
    if [ -f $OUT/bin/avcodec.lib ]; then cp $OUT/bin/*.lib $OUT/lib/; fi   # (MSVC's import libraries, where the .pc files say)
fi
