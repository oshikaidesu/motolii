#!/bin/zsh
# ONNX Runtime 1.32.0 (Microsoft, MIT): the project's own release for this OS and CPU, fetched once into third_party/onnxruntime
# (include/ and lib/). One shared library that carries its own dependencies (abseil, protobuf, onnx, re2), so nothing else
# is read at run time: Homebrew's build is 87 libraries. Used by entry/calls_map.cpp (the shelf maps).
# The releases (github.com/microsoft/onnxruntime/releases/tag/v1.32.0; 1.31.1's are no longer given: 404):
#   Mac Apple silicon  onnxruntime-osx-arm64-1.32.0.tgz       36.9 MB   (SHA-256 below: taken from the first download)
#   Linux x64          onnxruntime-linux-x64-1.32.0.tgz                 (no SHA-256 pinned yet)
#   Linux aarch64      onnxruntime-linux-aarch64-1.32.0.tgz             (no SHA-256 pinned yet)
#   Windows x64        onnxruntime-win-x64-1.32.0.zip                   (not handled here: this script is zsh)
# A platform whose SHA-256 is not pinned stops with a message and fetches nothing.
#   ./deps/onnxruntime.sh
set -e
cd "$(dirname "$0")/.."
source tools/build_lock.sh; build_lock "$@"   # (the machine's one build lock, taken here: tools/build_lock.sh)
V=1.32.0
case "$(uname -s)-$(uname -m)" in
    Darwin-arm64)   name=osx-arm64;      SHA=8ddca23f532b9d4fbb279ba9b08dab6c0ac94fdc9aec2eb44a1db7049216c043 ;;
    Linux-x86_64)   name=linux-x64;      SHA= ;;
    Linux-aarch64)  name=linux-aarch64;  SHA= ;;
    *) echo "onnxruntime: no release is known for $(uname -s) $(uname -m) here"; exit 1 ;;
esac
OUT=$PWD/third_party/onnxruntime
[ -d $OUT/lib ] && exit 0
[ -n "$SHA" ] || { echo "onnxruntime-$name-$V.tgz: no SHA-256 is pinned for this platform yet: download it once, take 'shasum -a 256', and put it in deps/onnxruntime.sh"; exit 1; }
tmp=$(mktemp -d)
# -S: a failure says why (it used to end with a bare exit code). --retry: a download cut off is asked for again.
curl -fL -sS --retry 5 --retry-all-errors -o $tmp/ort.tgz https://github.com/microsoft/onnxruntime/releases/download/v$V/onnxruntime-$name-$V.tgz
[ "$(shasum -a 256 $tmp/ort.tgz | cut -d' ' -f1)" = $SHA ] || { echo "onnxruntime-$name-$V.tgz: its SHA-256 is not the one this script knows"; rm -rf $tmp; exit 1; }
mkdir -p $OUT && tar -xzf $tmp/ort.tgz -C $OUT --strip-components 1
rm -rf $tmp
