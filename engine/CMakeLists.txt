# The engine: out/libmotolii.dylib (what the app loads) and out/edit_wgpu (the same calls from a shell).
#
#   ./build.sh                    fetches and builds the dependencies (deps/), then runs this
#   cmake -S . -B out/cmake -G Ninja && cmake --build out/cmake      this alone, once the dependencies exist
#
# Every .cpp and .mm under the module folders is compiled by itself. The dependencies are not built here: each
# deps/<library>.sh fetches one into third_party/ and builds it with that library's own build system.
cmake_minimum_required(VERSION 3.24)
project(motolii LANGUAGES C CXX OBJCXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_OBJCXX_STANDARD 20)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)   # out/cmake/compile_commands.json, for clangd and clang-tidy
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()
set(CMAKE_CXX_FLAGS_RELEASE "-O2")      # asserts stay on, as the engine has always been built
set(CMAKE_OBJCXX_FLAGS_RELEASE "-O2")

set(ENGINE ${CMAKE_CURRENT_SOURCE_DIR})
set(THIRD_PARTY ${ENGINE}/third_party)
set(FILAMENT ${THIRD_PARTY}/filament_src)
set(FILAMENT_SDK ${FILAMENT}/out/wgpu_install)
set(DAWN_INCLUDES ${FILAMENT}/third_party/dawn/include ${FILAMENT}/out/wgpu/third_party/dawn/gen/include)
set(THORVG ${THIRD_PARTY}/thorvg_src)
set(SKIA ${THIRD_PARTY}/skia_src)
set(ABSENT_MOTION ${THIRD_PARTY}/AbsentMotion/app/src/main/cpp)
set(IRIS ${THIRD_PARTY}/iris)
set(JOLT ${THIRD_PARTY}/physics/JoltPhysics)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GSTREAMER REQUIRED IMPORTED_TARGET gstreamer-1.0 gstreamer-app-1.0 gstreamer-video-1.0 gstreamer-pbutils-1.0)
pkg_check_modules(FFMPEG REQUIRED IMPORTED_TARGET libavformat libavcodec libavutil)
execute_process(COMMAND brew --prefix OUTPUT_VARIABLE HOMEBREW OUTPUT_STRIP_TRAILING_WHITESPACE COMMAND_ERROR_IS_FATAL ANY)

# ---- Sources with flags of their own: each reads another project's internal headers, built as that project builds.

# ThorVG's path operators, read with ThorVG's internal headers.
add_library(thorvg_path_operators OBJECT stage/canvas/thorvg_path_operators.cpp)
set_target_properties(thorvg_path_operators PROPERTIES CXX_STANDARD 17)
target_compile_options(thorvg_path_operators PRIVATE -fno-rtti -fno-exceptions)
target_compile_definitions(thorvg_path_operators PRIVATE TVG_STATIC)
target_include_directories(thorvg_path_operators PRIVATE ${ENGINE} ${THORVG}/build_dawn ${THORVG}/inc ${THORVG}/src/common
  ${THORVG}/src/renderer ${THORVG}/src/renderer/gpu_engine ${THORVG}/src/renderer/gpu_engine/wg ${THORVG}/src/loaders/lottie ${DAWN_INCLUDES})

# Skia's path operations (its Boolean).
add_library(skia_path_operations OBJECT stage/canvas/skia_path_operations.cpp)
target_compile_options(skia_path_operations PRIVATE -fno-rtti -fno-exceptions)
target_compile_definitions(skia_path_operations PRIVATE NDEBUG)
target_include_directories(skia_path_operations PRIVATE ${ENGINE} ${SKIA} ${THORVG}/inc)

# AbsentMotion's own motion, scene, easing and text sources as they are, and our adapter to them.
file(GLOB ABSENT_MOTION_ADAPTER CONFIGURE_DEPENDS community/absent_motion/*.cpp)
add_library(absent_motion OBJECT ${ABSENT_MOTION_ADAPTER}
  ${ABSENT_MOTION}/motion.cpp ${ABSENT_MOTION}/scene.cpp ${ABSENT_MOTION}/easing.cpp ${ABSENT_MOTION}/textanim.cpp)
target_compile_options(absent_motion PRIVATE -fno-rtti -fvisibility=hidden)
target_compile_definitions(absent_motion PRIVATE NDEBUG)
target_include_directories(absent_motion PRIVATE ${ENGINE} ${SKIA} ${ABSENT_MOTION})

# The flash check: EA's IRIS, in IRIS's own C++17 (its log lines pass runtime format strings, which C++20 refuses).
add_library(video_flash_check OBJECT media/video_flash_check.cpp)
set_target_properties(video_flash_check PROPERTIES CXX_STANDARD 17)
target_include_directories(video_flash_check PRIVATE ${ENGINE} ${IRIS}/IRIS/include ${IRIS}/IRIS/utils/include
  ${IRIS}/spdlog/include ${IRIS}/json/single_include ${IRIS}/opencv_out/include/opencv4)

# Shaders turned into WGSL by Filament's glslang and Dawn's Tint (ISF's GLSL, AviUtl2's HLSL).
add_library(shader_translation OBJECT community/isf/isf.cpp community/aviutl/aviutl.cpp)
target_compile_definitions(shader_translation PRIVATE TINT_BUILD_SPV_READER=1 TINT_BUILD_WGSL_WRITER=1 TINT_BUILD_WGSL_READER=1)
set_source_files_properties(community/aviutl/aviutl.cpp PROPERTIES COMPILE_DEFINITIONS ENABLE_HLSL)
target_include_directories(shader_translation PRIVATE ${ENGINE}
  ${FILAMENT}/third_party/libassimp/contrib/rapidjson/include ${HOMEBREW}/opt/sqlite/include
  ${FILAMENT}/third_party/glslang ${FILAMENT}/third_party/spirv-tools/include ${FILAMENT}/libs/filamat/src
  ${FILAMENT}/third_party/dawn ${FILAMENT}/third_party/dawn/include ${FILAMENT}/out/wgpu/third_party/dawn/gen)

set(SOURCES_WITH_OWN_FLAGS
  ${ENGINE}/stage/canvas/thorvg_path_operators.cpp ${ENGINE}/stage/canvas/skia_path_operations.cpp
  ${ABSENT_MOTION_ADAPTER} ${ENGINE}/media/video_flash_check.cpp
  ${ENGINE}/community/isf/isf.cpp ${ENGINE}/community/aviutl/aviutl.cpp)

# ---- The library.

file(GLOB_RECURSE MOTOLII_SOURCES CONFIGURE_DEPENDS
  base/*.cpp shelf/*.cpp motion/*.cpp physics/*.cpp media/*.cpp media/*.mm preview/*.cpp preview/*.mm
  stage/*.cpp stage/*.mm document/*.cpp document/*.mm entry/*.cpp entry/*.mm
  community/after_effects/*.cpp community/aviutl/*.cpp community/hydra/*.cpp community/isf/*.cpp community/p5/*.cpp
  community/playcanvas/*.cpp community/quickjs/*.cpp community/sites/*.cpp community/three/*.cpp)
list(REMOVE_ITEM MOTOLII_SOURCES ${SOURCES_WITH_OWN_FLAGS} ${ENGINE}/entry/edit.cpp)
list(FILTER MOTOLII_SOURCES EXCLUDE REGEX "_test\\.cpp$")

add_library(motolii SHARED ${MOTOLII_SOURCES}
  third_party/scipy_lsap/rectangular_lsap.cpp third_party/thermion_frame/FrameScheduler.cpp
  $<TARGET_OBJECTS:thorvg_path_operators> $<TARGET_OBJECTS:skia_path_operations> $<TARGET_OBJECTS:absent_motion>
  $<TARGET_OBJECTS:video_flash_check> $<TARGET_OBJECTS:shader_translation>)
set_target_properties(motolii PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${ENGINE}/out INSTALL_NAME_DIR "@rpath" BUILD_WITH_INSTALL_NAME_DIR ON)
target_compile_options(motolii PRIVATE -ffp-contract=off $<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc>)
target_compile_definitions(motolii PRIVATE SQLITE_ENABLE_SESSION SQLITE_ENABLE_PREUPDATE_HOOK
  JPH_CROSS_PLATFORM_DETERMINISTIC JPH_DEBUG_RENDERER JPH_OBJECT_LAYER_BITS=16 JPH_OBJECT_STREAM JPH_PROFILE_ENABLED)
target_include_directories(motolii PRIVATE ${ENGINE}
  ${FILAMENT_SDK}/include ${THORVG}/inc ${THORVG}/src/loaders/lottie ${DAWN_INCLUDES}
  ${THIRD_PARTY}/libtess2/Include ${THIRD_PARTY}/curve_fit_nd/c ${SKIA} ${ABSENT_MOTION}
  ${THIRD_PARTY}/thermion_frame/include ${THIRD_PARTY}/qdtsne/include ${THIRD_PARTY}/scipy_lsap ${JOLT}
  ${HOMEBREW}/opt/sqlite/include ${HOMEBREW}/opt/luajit/include/luajit-2.1 ${HOMEBREW}/opt/quickjs-ng/include
  ${HOMEBREW}/opt/onnxruntime/include/onnxruntime)
target_link_directories(motolii PRIVATE ${FILAMENT_SDK}/lib/arm64 ${IRIS}/opencv_out/lib ${IRIS}/opencv_out/lib/opencv4/3rdparty
  ${HOMEBREW}/opt/luajit/lib ${HOMEBREW}/opt/quickjs-ng/lib ${HOMEBREW}/opt/onnxruntime/lib)
target_link_libraries(motolii PRIVATE
  PkgConfig::GSTREAMER PkgConfig::FFMPEG ${HOMEBREW}/opt/sqlite/lib/libsqlite3.dylib luajit-5.1 qjs onnxruntime
  # ThorVG (built against Dawn), Skia's path operations, libtess2, curve_fit_nd, Jolt, IRIS and its OpenCV
  ${THORVG}/build_dawn/src/libthorvg-1.a ${SKIA}/out/path/libpathops.a ${SKIA}/out/path/libskia.a
  ${THIRD_PARTY}/libtess2/build/libtess2.a ${THIRD_PARTY}/curve_fit_nd/build/libcurve_fit_nd.a
  ${JOLT}/jbuild/libJolt.a ${IRIS}/lib/libiris.a
  opencv_features2d opencv_videoio opencv_imgcodecs opencv_imgproc opencv_core tegra_hal
  # Filament with its WebGPU backend, and our interop built inside Filament's own build (gpu/CMakeLists.txt)
  ${FILAMENT}/out/wgpu/filament/motolii_probe/libmotolii_interop.a
  gltfio gltfio_core dracodec matp filament backend webgpu_dawn bluegl bluevk filabridge filaflat utils geometry smol-v
  ibl ktxreader stb uberzlib zstd shaders perfetto abseil meshoptimizer camutils image basis_transcoder uberarchive
  matdbg filamat civetweb viewer z
  "-framework Cocoa" "-framework SceneKit" "-framework ModelIO" "-framework Metal" "-framework CoreVideo"
  "-framework QuartzCore" "-framework IOSurface" "-framework IOKit" "-framework AVFoundation" "-framework CoreMedia"
  "-framework CoreGraphics" "-framework Accelerate")
target_link_options(motolii PRIVATE -Wl,-dead_strip
  -Wl,-rpath,${HOMEBREW}/opt/luajit/lib -Wl,-rpath,${HOMEBREW}/opt/quickjs-ng/lib -Wl,-rpath,${HOMEBREW}/opt/onnxruntime/lib)

# ---- The shell: a project edited by one call a line (edit.sh).

add_executable(edit_wgpu entry/edit.cpp)
target_include_directories(edit_wgpu PRIVATE ${ENGINE})
target_link_libraries(edit_wgpu PRIVATE motolii)
set_target_properties(edit_wgpu PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${ENGINE}/out BUILD_RPATH "@executable_path")

# ---- Tests: every <name>_test.cpp beside the code it tests, run by ctest.

include(CTest)
file(GLOB_RECURSE MOTOLII_TESTS CONFIGURE_DEPENDS
  base/*_test.cpp shelf/*_test.cpp motion/*_test.cpp physics/*_test.cpp media/*_test.cpp preview/*_test.cpp
  stage/*_test.cpp document/*_test.cpp entry/*_test.cpp community/*_test.cpp)
if(BUILD_TESTING AND MOTOLII_TESTS)
  find_package(GTest REQUIRED)
  include(GoogleTest)
  add_executable(motolii_test ${MOTOLII_TESTS})
  target_include_directories(motolii_test PRIVATE $<TARGET_PROPERTY:motolii,INCLUDE_DIRECTORIES>)
  target_compile_definitions(motolii_test PRIVATE $<TARGET_PROPERTY:motolii,COMPILE_DEFINITIONS>)
  target_link_libraries(motolii_test PRIVATE motolii GTest::gtest_main)
  gtest_discover_tests(motolii_test)
endif()
