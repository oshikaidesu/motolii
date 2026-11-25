#!/bin/zsh
# psd_sdk (Molecular Matters GmbH, BSD 2-Clause): reads Photoshop .psd/.psb
# layer hierarchies, UTF-16 names, bounds, visibility, opacity, and pixel channels.
# Fetched once into third_party/psd_sdk, built as third_party/psd_sdk/build/libpsd_sdk.a.
#   ./deps/psd_sdk.sh
set -e
cd "$(dirname "$0")/.."
source tools/build_lock.sh; build_lock "$@"
L=$PWD/third_party/psd_sdk
[ -d $L ] || { mkdir -p $L && git init -q $L && git -C $L -c core.hooksPath=/dev/null fetch -q --depth 1 https://github.com/MolecularMatters/psd_sdk bfa117317e8bb15bfc9f76bad5800da603fddd1d && git -C $L checkout -q FETCH_HEAD; }
mkdir -p $L/build_lib
SRCS=(
  PsdAllocator.cpp
  PsdBlendMode.cpp
  PsdColorMode.cpp
  PsdDecompressRle.cpp
  PsdExport.cpp
  PsdFile.cpp
  PsdFixedSizeString.cpp
  PsdInterleave.cpp
  PsdLayerCanvasCopy.cpp
  PsdMallocAllocator.cpp
  PsdMemoryFile.cpp
  Psdminiz.cpp
  PsdParseColorModeDataSection.cpp
  PsdParseDocument.cpp
  PsdParseImageDataSection.cpp
  PsdParseImageResourcesSection.cpp
  PsdParseLayerMaskSection.cpp
  PsdPch.cpp
  PsdStringUtil.cpp
  PsdSyncFileReader.cpp
  PsdSyncFileWriter.cpp
)
if [ ! -f $L/build_lib/libpsd_sdk.a ]; then
  (cd $L/build_lib
   for s in $SRCS; do
     ${CXX:-c++} $CFLAGS -O2 -std=c++17 -Wno-deprecated-declarations -I ../src -c "../src/Psd/$s" -o "${s%.cpp}.o"
   done
   ${AR:-ar} rcs libpsd_sdk.a *.o)
fi
