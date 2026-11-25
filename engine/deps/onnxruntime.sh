#!/bin/zsh
# ONNX Runtime 1.31.1 (Microsoft, MIT): the project's own release for this OS and CPU, fetched once into third_party/onnxruntime
# (include/ and lib/). One shared library that carries its own dependencies (abseil, protobuf, onnx, re2), so nothing else
# is read at run time: Homebrew's build is 87 libraries. Used by entry/calls_map.cpp (the shelf maps).
# The releases (github.com/microsoft/onnxruntime/releases/tag/v1.31.1):
#   Mac Apple silicon  onnxruntime-osx-arm64-1.31.1.tgz       35.2 MB   (SHA-256 below: taken from the first download)
#   Linux x64          onnxruntime-linux-x64-1.31.1.tgz       10.9 MB   (no SHA-256 pinned yet)
#   Linux aarch64      onnxruntime-linux-aarch64-1.31.1.tgz    9.9 MB   (no SHA-256 pinned yet)
#   Windows x64        onnxruntime-win-x64-1.31.1.zip         79.1 MB   (not handled here: this script is zsh)
# A platform whose SHA-256 is not pinned stops with a message and fetches nothing.
#   ./deps/onnxruntime.sh
set -e
cd "$(dirname "$0")/.."
source tools/build_lock.sh; build_lock "$@"   # (the machine's one build lock, taken here: tools/build_lock.sh)
V=1.31.1
case "$(uname -s)-$(uname -m)" in
    Darwin-arm64)   name=osx-arm64;      SHA=2e1344a1926ee50eb25b38153cb6992c3567515aef0e677a1a520a1798896d6f ;;
    Linux-x86_64)   name=linux-x64;      SHA= ;;
    Linux-aarch64)  name=linux-aarch64;  SHA= ;;
    MSYS*-x86_64|MINGW*-x86_64)  name=win-x64;  SHA=5869e26bb25314375f2d5ef1877e3ea06b1543d6c710e6e4a1ec2f7177ab4b2c ;;
    *) echo "onnxruntime: no release is known for $(uname -s) $(uname -m) here"; exit 1 ;;
esac
OUT=$PWD/third_party/onnxruntime
[ -d $OUT/lib ] && exit 0
[ -n "$SHA" ] || { echo "onnxruntime-$name-$V.tgz: no SHA-256 is pinned for this platform yet: download it once, take 'shasum -a 256', and put it in deps/onnxruntime.sh"; exit 1; }
tmp=$(mktemp -d)
# -S: a failure says why (it used to end with a bare exit code). --retry: a download cut off is asked for again.
# A 404 here since 2026-11-17 is GitHub no longer having microsoft/onnxruntime at all; what was fetched before is
# unaffected. Another place to fetch from is a choice for a person: the SHA-256 above is of this file only.
kind=tgz; [[ $name == win-* ]] && kind=zip   # (Windows' release is a zip)
curl -fL -sS --retry 3 -o $tmp/ort.$kind https://github.com/microsoft/onnxruntime/releases/download/v$V/onnxruntime-$name-$V.$kind
actual=$({ shasum -a 256 $tmp/ort.$kind 2>/dev/null || sha256sum $tmp/ort.$kind; } | cut -d' ' -f1)
[ "$actual" = $SHA ] || { echo "onnxruntime-$name-$V.$kind: its SHA-256 is not the one this script knows"; rm -rf $tmp; exit 1; }
if [ $kind = zip ]; then
    (cd $tmp && unzip -q ort.zip) && mkdir -p $OUT && mv $tmp/onnxruntime-$name-$V/* $OUT/
else
    mkdir -p $OUT && tar -xzf $tmp/ort.tgz -C $OUT --strip-components 1
fi
rm -rf $tmp
