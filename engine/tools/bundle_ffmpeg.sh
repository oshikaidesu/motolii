#!/bin/zsh
# A copy of the LGPL-only FFmpeg (deps/ffmpeg.sh) that runs from wherever it is put, for the app bundle: ffmpeg and ffprobe
# in <dest>/bin, the libraries in <dest>/lib, every library found by @rpath, so nothing names this checkout. Each file is
# signed ad hoc again (install_name_tool breaks the signature; Apple silicon refuses an unsigned one). With the copy go the
# LGPL text, the configure line and where the unmodified source is (ffmpeg.org/legal.html, items 3, 6 and 10).
# A Developer ID signature and notarization are the owner's to add: they need the owner's certificate.
#   ./tools/bundle_ffmpeg.sh <dest>
set -e
cd "$(dirname "$0")/.."
dest=${1:?usage: ./tools/bundle_ffmpeg.sh <dest folder>}
OUT=$PWD/third_party/ffmpeg_lgpl
SRC=$PWD/third_party/ffmpeg_src
[ -x $OUT/bin/ffmpeg ] || { echo "third_party/ffmpeg_lgpl is not built: run deps/ffmpeg.sh"; exit 1; }
rm -rf $dest && mkdir -p $dest/bin $dest/lib
for exe in ffmpeg ffprobe; do cp $OUT/bin/$exe $dest/bin/; done
for lib in $OUT/lib/lib*.dylib(.); do cp $lib $dest/lib/; done   # (the real files; the short names are made below)
for lib in $OUT/lib/lib*.dylib(@); do cp -P $lib $dest/lib/; done   # (the links: libavcodec.63.dylib, libavcodec.dylib)
chmod -R u+w $dest
# Every library names itself and the others by @rpath; the programs look in ../lib.
for f in $dest/lib/lib*.dylib(.) $dest/bin/*(.); do
    case $f in
        */lib/*) install_name_tool -id @rpath/${f:t} $f 2> /dev/null ;;
        *) install_name_tool -add_rpath @executable_path/../lib $f 2> /dev/null ;;
    esac
    for dep in $(otool -L $f | tail -n +2 | awk '{print $1}' | grep "^$OUT/lib/"); do
        install_name_tool -change $dep @rpath/${dep:t} $f 2> /dev/null
    done
done
for f in $dest/lib/lib*.dylib(.) $dest/bin/*(.); do codesign --force --sign - $f 2> /dev/null; done
cp $SRC/COPYING.LGPLv2.1 $dest/COPYING.LGPLv2.1
cp $OUT/CONFIGURE.txt $dest/CONFIGURE.txt
cat > $dest/SOURCE.txt <<EOF
FFmpeg $(sed -n 's/^V=//p' deps/ffmpeg.sh | head -1), unmodified (no patches), under the LGPL 2.1 or later (COPYING.LGPLv2.1).
Source: https://ffmpeg.org/releases/ffmpeg-$(sed -n 's/^V=//p' deps/ffmpeg.sh | head -1).tar.xz
SHA-256: $(sed -n 's/^SHA=//p' deps/ffmpeg.sh | head -1)
Configure line: CONFIGURE.txt (the paths in it are those of the machine that built it).
This software uses libraries from the FFmpeg project under the LGPLv2.1.
EOF
