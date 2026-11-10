# The engine: out/libmotolii.dylib (what the app loads) and out/edit_wgpu (the same calls from a shell).
#
#   ./build.sh                    fetches and builds the dependencies (deps/), then runs this
#   cmake -S . -B out/cmake -G Ninja && cmake --build out/cmake      this alone, once the dependencies exist
#
# Each folder of ours is a module with a target of its own that names the modules it depends on; every .cpp and .mm
# is compiled by itself. The dependencies are not built here: each
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
add_library(absent_motion OBJECT community/absent_motion/absent_drawing.cpp community/absent_motion/absent_ends.cpp community/absent_motion/absent_motion.cpp
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

# ---- What every module is compiled with.

add_library(motolii_flags INTERFACE)
target_compile_options(motolii_flags INTERFACE -ffp-contract=off $<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc>)
target_compile_definitions(motolii_flags INTERFACE SQLITE_ENABLE_SESSION SQLITE_ENABLE_PREUPDATE_HOOK
  JPH_CROSS_PLATFORM_DETERMINISTIC JPH_DEBUG_RENDERER JPH_OBJECT_LAYER_BITS=16 JPH_OBJECT_STREAM JPH_PROFILE_ENABLED)
target_include_directories(motolii_flags INTERFACE ${ENGINE}
  ${FILAMENT_SDK}/include ${THORVG}/inc ${THORVG}/src/loaders/lottie ${DAWN_INCLUDES}
  ${THIRD_PARTY}/libtess2/Include ${THIRD_PARTY}/curve_fit_nd/c ${SKIA} ${ABSENT_MOTION}
  ${THIRD_PARTY}/thermion_frame/include ${THIRD_PARTY}/qdtsne/include ${THIRD_PARTY}/scipy_lsap ${JOLT}
  ${HOMEBREW}/opt/sqlite/include ${HOMEBREW}/opt/luajit/include/luajit-2.1 ${HOMEBREW}/opt/quickjs-ng/include
  ${HOMEBREW}/opt/onnxruntime/include/onnxruntime)
target_link_libraries(motolii_flags INTERFACE PkgConfig::GSTREAMER PkgConfig::FFMPEG)

# ---- Modules: one target a folder, lowest first. A module lists the modules it includes headers from; CMake refuses
# a cycle between them. To add a file, add it to its module below.

# Small parts every module may use (JSON).
add_library(motolii_base INTERFACE)

# Adapter: absent motion code run as it is.
add_library(motolii_community_absent_motion INTERFACE)

# Adapter: quickjs code run as it is.
add_library(motolii_community_quickjs OBJECT
  community/quickjs/script.cpp
  community/quickjs/script_leva.cpp)
target_link_libraries(motolii_community_quickjs PUBLIC motolii_flags)

# Adapter: after effects code run as it is.
add_library(motolii_community_after_effects OBJECT
  community/after_effects/lottie_slots.cpp)
target_link_libraries(motolii_community_after_effects PUBLIC motolii_flags motolii_base motolii_community_quickjs)

# Interop with Filament's WebGPU backend; its sources are built inside Filament's own build (gpu/CMakeLists.txt).
add_library(motolii_gpu INTERFACE)

# Where the shelves are on disk.
add_library(motolii_shelf OBJECT
  shelf/shelf_folders.cpp)
target_link_libraries(motolii_shelf PUBLIC motolii_flags)

# Adapter: sites code run as it is.
add_library(motolii_community_sites OBJECT
  community/sites/adapter.cpp
  community/sites/adapter_net.cpp
  community/sites/adapter_shadertoy.cpp
  community/sites/adapter_shadertoy_json.cpp)
target_link_libraries(motolii_community_sites PUBLIC motolii_flags motolii_base)

# Adapter: three code run as it is.
add_library(motolii_community_three OBJECT
  community/three/solid_three.cpp
  community/three/three_isf.cpp)
target_link_libraries(motolii_community_three PUBLIC motolii_flags motolii_base)

# Adapter: isf code run as it is.
add_library(motolii_community_isf INTERFACE)
target_link_libraries(motolii_community_isf INTERFACE motolii_base motolii_community_sites motolii_community_three)

# Adapter: playcanvas code run as it is.
add_library(motolii_community_playcanvas OBJECT
  community/playcanvas/splatfx.cpp)
target_link_libraries(motolii_community_playcanvas PUBLIC motolii_flags motolii_community_quickjs)

# Filament: the scene, cameras, lights, 3D files.
add_library(motolii_stage_render OBJECT
  stage/render/gltf_model.cpp
  stage/render/point_cloud.cpp
  stage/render/render_draw.cpp
  stage/render/render_draw.mm
  stage/render/render_layers.cpp
  stage/render/render_stage.cpp)
target_link_libraries(motolii_stage_render PUBLIC motolii_flags motolii_community_playcanvas)

# Screen effects.
add_library(motolii_stage_effects OBJECT
  stage/effects/screen_fx.cpp
  stage/effects/viewer_settings.cpp)
target_link_libraries(motolii_stage_effects PUBLIC motolii_flags motolii_base motolii_community_quickjs motolii_gpu motolii_shelf motolii_community_isf motolii_stage_render)

# Adapter: aviutl code run as it is.
add_library(motolii_community_aviutl OBJECT
  community/aviutl/aviutl_fx.cpp
  community/aviutl/aviutl_load.cpp
  community/aviutl/aviutl_obj.cpp
  community/aviutl/aviutl_obj_draw.cpp
  community/aviutl/aviutl_obj_effect.cpp
  community/aviutl/aviutl_pixels.cpp
  community/aviutl/aviutl_run.cpp)
target_link_libraries(motolii_community_aviutl PUBLIC motolii_flags motolii_base motolii_community_quickjs motolii_gpu motolii_shelf motolii_stage_render motolii_stage_effects)

# Adapter: hydra code run as it is.
add_library(motolii_community_hydra OBJECT
  community/hydra/hydra_isf.cpp)
target_link_libraries(motolii_community_hydra PUBLIC motolii_flags)

# Adapter: p5 code run as it is.
add_library(motolii_community_p5 OBJECT
  community/p5/adapter_p5_shader.cpp)
target_link_libraries(motolii_community_p5 PUBLIC motolii_flags motolii_base motolii_community_sites motolii_community_hydra)

# Video, sound and MIDI, on GStreamer.
add_library(motolii_media OBJECT
  media/midi_notes.cpp
  media/midi_roll.cpp
  media/sound_level.cpp
  media/sound_playback.cpp
  media/video_datamosh.cpp
  media/video_frames_for_scripts.cpp
  media/video_layer.cpp)
target_link_libraries(motolii_media PUBLIC motolii_flags motolii_community_quickjs motolii_gpu motolii_stage_render)

# Easing curves and Lottie motion.
add_library(motolii_motion OBJECT
  motion/easing_curves.cpp
  motion/lottie_motion.cpp)
target_link_libraries(motolii_motion PUBLIC motolii_flags motolii_community_absent_motion)

# Adapter: script runner code run as it is.
add_library(motolii_community_script_runner OBJECT
  community/script_runner/script_parameters.cpp
  community/script_runner/script_runner.cpp)
target_link_libraries(motolii_community_script_runner PUBLIC motolii_flags motolii_community_quickjs motolii_community_after_effects motolii_community_sites motolii_community_three motolii_community_aviutl motolii_community_p5 motolii_media motolii_motion)

# Rigid bodies, on Jolt.
add_library(motolii_physics OBJECT
  physics/jolt.cpp)
target_link_libraries(motolii_physics PUBLIC motolii_flags)

# ThorVG: 2D drawings placed in the scene.
add_library(motolii_stage_canvas OBJECT
  stage/canvas/canvas_cache.cpp
  stage/canvas/canvas_edge.cpp
  stage/canvas/canvas_flat.cpp
  stage/canvas/canvas_renderables.cpp
  stage/canvas/canvas_sketch.cpp)
target_link_libraries(motolii_stage_canvas PUBLIC motolii_flags motolii_community_absent_motion motolii_gpu motolii_shelf motolii_stage_render motolii_community_script_runner)

# A layer's own effect stack.
add_library(motolii_stage_layer_effects OBJECT
  stage/layer_effects/layer_fx.cpp)
target_link_libraries(motolii_stage_layer_effects PUBLIC motolii_flags motolii_community_quickjs motolii_gpu motolii_community_three motolii_stage_render motolii_stage_effects motolii_community_aviutl motolii_stage_canvas)

# The project (SQLite): its values, edits, evaluation at a time.
add_library(motolii_document OBJECT
  document/cards.cpp
  document/edit/arrange.cpp
  document/edit/easings_put.cpp
  document/edit/fx_put.cpp
  document/edit/hold.cpp
  document/edit/keys_put.cpp
  document/edit/layer_edit.cpp
  document/edit/parent.cpp
  document/edit/paths.cpp
  document/edit/presets.cpp
  document/edit/relate.cpp
  document/edit/time_edit.cpp
  document/evaluate/camera.cpp
  document/evaluate/evaluate.cpp
  document/evaluate/fx_list.cpp
  document/evaluate/material.cpp
  document/evaluate/moment_fx.cpp
  document/evaluate/place.cpp
  document/evaluate/relations.cpp
  document/evaluate/shown.cpp
  document/evaluate/sketch.cpp
  document/evaluate/value_at.cpp
  document/evaluate/world.cpp
  document/marks.cpp
  document/match.cpp
  document/scripts/adapter.cpp
  document/scripts/expressions.cpp
  document/scripts/folders.cpp
  document/scripts/recipes.cpp
  document/scripts/scripts.cpp
  document/undo.cpp)
target_link_libraries(motolii_document PUBLIC motolii_flags motolii_community_absent_motion motolii_community_quickjs motolii_community_after_effects motolii_shelf motolii_community_sites motolii_community_three motolii_community_isf motolii_community_playcanvas motolii_stage_render motolii_stage_effects motolii_community_aviutl motolii_community_hydra motolii_community_p5 motolii_media motolii_motion motolii_community_script_runner motolii_physics motolii_stage_canvas motolii_stage_layer_effects)

# The frame handed to the app.
add_library(motolii_stage OBJECT
  stage/live.mm)
target_link_libraries(motolii_stage PUBLIC motolii_flags motolii_gpu motolii_stage_render motolii_stage_effects)

# The playback cache.
add_library(motolii_preview OBJECT
  preview/playback_cache.cpp)
target_link_libraries(motolii_preview PUBLIC motolii_flags motolii_community_quickjs motolii_shelf motolii_stage_render motolii_stage_canvas motolii_document motolii_stage)

# The C API the app calls (entry/motolii.h).
add_library(motolii_entry OBJECT
  entry/calls.cpp
  entry/calls_files.cpp
  entry/calls_find.cpp
  entry/calls_later.cpp
  entry/calls_map.cpp
  entry/calls_sound.cpp
  entry/calls_time.cpp
  entry/export.cpp
  entry/render_thread.cpp
  entry/render_thread_loop.cpp
  entry/snapshot.cpp
  entry/window.cpp)
target_link_libraries(motolii_entry PUBLIC motolii_flags motolii_base motolii_shelf motolii_stage_render motolii_media motolii_motion motolii_stage_canvas motolii_document motolii_stage motolii_preview)

# ---- The library: every module, and the sources with flags of their own.

add_library(motolii SHARED
  third_party/scipy_lsap/rectangular_lsap.cpp third_party/thermion_frame/FrameScheduler.cpp
  $<TARGET_OBJECTS:thorvg_path_operators> $<TARGET_OBJECTS:skia_path_operations> $<TARGET_OBJECTS:absent_motion>
  $<TARGET_OBJECTS:video_flash_check> $<TARGET_OBJECTS:shader_translation>)
target_link_libraries(motolii PRIVATE
  motolii_community_quickjs motolii_community_after_effects motolii_shelf motolii_community_sites motolii_community_three motolii_community_playcanvas 
  motolii_stage_render motolii_stage_effects motolii_community_aviutl motolii_community_hydra motolii_community_p5 motolii_media motolii_motion motolii_community_script_runner motolii_physics motolii_stage_canvas motolii_stage_layer_effects
  motolii_document motolii_stage motolii_preview motolii_entry)
set_target_properties(motolii PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${ENGINE}/out INSTALL_NAME_DIR "@rpath" BUILD_WITH_INSTALL_NAME_DIR ON)
target_link_directories(motolii PRIVATE ${FILAMENT_SDK}/lib/arm64 ${IRIS}/opencv_out/lib ${IRIS}/opencv_out/lib/opencv4/3rdparty
  ${HOMEBREW}/opt/luajit/lib ${HOMEBREW}/opt/quickjs-ng/lib ${HOMEBREW}/opt/onnxruntime/lib)
target_link_libraries(motolii PRIVATE
  ${HOMEBREW}/opt/sqlite/lib/libsqlite3.dylib luajit-5.1 qjs onnxruntime
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
  # Homebrew's googletest (Brewfile), not one another toolchain on PATH happens to carry.
  find_package(GTest REQUIRED CONFIG PATHS ${HOMEBREW}/opt/googletest NO_DEFAULT_PATH)
  include(GoogleTest)
  add_executable(motolii_test ${MOTOLII_TESTS})
  target_link_libraries(motolii_test PRIVATE motolii motolii_flags GTest::gtest_main)
  gtest_discover_tests(motolii_test)
endif()
