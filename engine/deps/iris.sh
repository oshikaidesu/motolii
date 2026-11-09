#!/bin/zsh
# IRIS (Electronic Arts, BSD-3-Clause): a film's flashes and patterns that may cause seizures (a failure: more than three
# flashes in any second, its README). Fetched once into third_party/iris at the commits we use, with what it reads:
# OpenCV 4.12.0 (Apache-2.0) built by its own CMake as a static library of the modules IRIS's code calls (core, imgproc,
# features2d for a header, videoio reading a film by the Mac's own AVFoundation), nothing else fetched or read by it;
# spdlog 1.15.3 and nlohmann/json 3.12.0 (MIT, headers only). IRIS's own CMake finds ffmpeg through vcpkg's FindFFMPEG,
# so its sources, the ones its CMakeLists lists, are built here as they are, against Homebrew's ffmpeg (Brewfile).
# Out come third_party/iris/lib/libiris.a and OpenCV's in third_party/iris/opencv_out (media/flashes.cpp; edit.sh and
# build_lib.sh link them). Measured on this Mac: 44 s for OpenCV, 31 s for IRIS (docs/internal/reports/alight_motion/alight_checklist.md, 11/4).
#   ./deps/iris.sh
set -e
cd "$(dirname "$0")/.."
source deps/build_lock.sh; build_lock "$@"   # (the machine's one build lock, taken here: deps/build_lock.sh)
R=$PWD/third_party/iris
fetch() { [ -d $R/$1 ] || { mkdir -p $R/$1 && git init -q $R/$1 && git -C $R/$1 -c core.hooksPath=/dev/null fetch -q --depth 1 $2 $3 && git -C $R/$1 checkout -q FETCH_HEAD; }; }
fetch IRIS https://github.com/electronicarts/IRIS d96978ac1107f3463b77f69a9c1b1ec5d45291a0
fetch spdlog https://github.com/gabime/spdlog 6fa36017cfd5731d617e1a934f0e5ea9c4445b13
fetch json https://github.com/nlohmann/json 55f93686c01528224f448c19128836e7df245f72
[ -f $R/opencv_out/lib/libopencv_core.a ] || {   # (its source and build only while it is made: what is kept is opencv_out)
    fetch opencv https://github.com/opencv/opencv 49486f61fb25722cbcf586b7f4320921d46fb38e
    cmake -S $R/opencv -B $R/opencv_build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$R/opencv_out -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_LIST=core,imgproc,features2d,videoio -DWITH_AVFOUNDATION=ON -DWITH_FFMPEG=OFF -DWITH_GSTREAMER=OFF -DVIDEOIO_ENABLE_PLUGINS=OFF \
        -DWITH_JPEG=OFF -DWITH_PNG=OFF -DWITH_TIFF=OFF -DWITH_WEBP=OFF -DWITH_OPENJPEG=OFF -DWITH_JASPER=OFF -DWITH_AVIF=OFF -DWITH_SPNG=OFF \
        -DWITH_JPEGXL=OFF -DWITH_OPENEXR=OFF -DWITH_IMGCODEC_HDR=OFF -DWITH_IMGCODEC_SUNRASTER=OFF -DWITH_IMGCODEC_PXM=OFF -DWITH_IMGCODEC_PFM=OFF \
        -DWITH_IMGCODEC_GIF=OFF -DWITH_OPENCL=OFF -DWITH_IPP=OFF -DWITH_KLEIDICV=OFF -DWITH_EIGEN=OFF -DWITH_LAPACK=OFF -DWITH_PROTOBUF=OFF \
        -DWITH_ITT=OFF -DWITH_ADE=OFF -DBUILD_ZLIB=OFF -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_opencv_apps=OFF \
        -DBUILD_DOCS=OFF -DBUILD_JAVA=OFF -DBUILD_opencv_python3=OFF > /dev/null
    ninja -C $R/opencv_build install > /dev/null
}
[ -f $R/lib/libiris.a ] || {
    mkdir -p $R/iris_build $R/lib
    (cd $R/iris_build && clang++ -c -std=c++17 -O2 -I$R/IRIS/include -I$R/IRIS/src -I$R/IRIS/utils/include -I$R/spdlog/include \
        -I$R/json/single_include -I$R/opencv_out/include/opencv4 $(pkg-config --cflags libavformat libavcodec) $R/IRIS/src/*.cpp $R/IRIS/utils/src/*.cpp)
    ar rcs $R/lib/libiris.a $R/iris_build/*.o
}
