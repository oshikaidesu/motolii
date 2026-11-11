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

find_package(PkgConfig REQUIRED)
pkg_check_modules(GSTREAMER REQUIRED IMPORTED_TARGET gstreamer-1.0 gstreamer-app-1.0 gstreamer-video-1.0 gstreamer-pbutils-1.0)
# FFmpeg's libraries are the LGPL-only build deps/ffmpeg.sh makes, never Homebrew's (it has GPL parts: libx264, libx265).
if(NOT EXISTS ${THIRD_PARTY}/ffmpeg_lgpl/lib/pkgconfig/libavcodec.pc)
  message(FATAL_ERROR "third_party/ffmpeg_lgpl is not built: run engine/deps/ffmpeg.sh")
endif()
set(ENV{PKG_CONFIG_PATH} "${THIRD_PARTY}/ffmpeg_lgpl/lib/pkgconfig")
pkg_check_modules(FFMPEG REQUIRED IMPORTED_TARGET libavformat libavcodec libavutil)
execute_process(COMMAND brew --prefix OUTPUT_VARIABLE HOMEBREW OUTPUT_STRIP_TRAILING_WHITESPACE COMMAND_ERROR_IS_FATAL ANY)

# ---- Sources with flags of their own: each reads another project's internal headers, built as that project builds.

# ThorVG's path operators, read with ThorVG's internal headers.
add_library(thorvg_path_operators OBJECT stage/canvas/thorvg_path_operators.cpp)
set_target_properties(thorvg_path_operators PROPERTIES CXX_STANDARD 17)
target_compile_options(thorvg_path_operators PRIVATE -fno-rtti -fno-exceptions)
target_compile_definitions(thorvg_path_operators PRIVATE TVG_STATIC)
target_include_directories(thorvg_path_operators PRIVATE ${THORVG}/build_dawn ${THORVG}/inc ${THORVG}/src/common
  ${THORVG}/src/renderer ${THORVG}/src/renderer/gpu_engine ${THORVG}/src/renderer/gpu_engine/wg ${THORVG}/src/loaders/lottie ${DAWN_INCLUDES})

# Skia's path operations (its Boolean).
add_library(skia_path_operations OBJECT stage/canvas/skia_path_operations.cpp stage/canvas/skia_svg_edit.cpp)
target_compile_options(skia_path_operations PRIVATE -fno-rtti -fno-exceptions)
target_compile_definitions(skia_path_operations PRIVATE NDEBUG)
target_include_directories(skia_path_operations PRIVATE ${SKIA} ${THORVG}/inc)

# AbsentMotion's own motion, scene, easing and text sources as they are, and our adapter to them.
add_library(absent_motion OBJECT community/absent_motion/absent_drawing.cpp community/absent_motion/absent_ends.cpp community/absent_motion/absent_motion.cpp
  ${ABSENT_MOTION}/motion.cpp ${ABSENT_MOTION}/scene.cpp ${ABSENT_MOTION}/easing.cpp ${ABSENT_MOTION}/textanim.cpp)
target_compile_options(absent_motion PRIVATE -fno-rtti -fvisibility=hidden)
target_compile_definitions(absent_motion PRIVATE NDEBUG)
target_include_directories(absent_motion PRIVATE ${SKIA} ${ABSENT_MOTION})

# The flash check: EA's IRIS, in IRIS's own C++17 (its log lines pass runtime format strings, which C++20 refuses).
add_library(video_flash_check OBJECT media/video_flash_check.cpp)
set_target_properties(video_flash_check PROPERTIES CXX_STANDARD 17)
target_include_directories(video_flash_check PRIVATE ${IRIS}/IRIS/include ${IRIS}/IRIS/utils/include
  ${IRIS}/spdlog/include ${IRIS}/json/single_include ${IRIS}/opencv_out/include/opencv4)

# Shaders turned into WGSL by Filament's glslang and Dawn's Tint (ISF's GLSL, AviUtl2's HLSL).
add_library(isf_translation OBJECT community/isf/isf.cpp community/isf/isf_compile.cpp community/isf/isf_head.cpp community/isf/isf_translate.cpp)
add_library(aviutl_translation OBJECT community/aviutl/aviutl.cpp)
target_compile_definitions(aviutl_translation PRIVATE ENABLE_HLSL)
foreach(translation isf_translation aviutl_translation)
  target_compile_definitions(${translation} PRIVATE TINT_BUILD_SPV_READER=1 TINT_BUILD_WGSL_WRITER=1 TINT_BUILD_WGSL_READER=1)
  target_include_directories(${translation} PRIVATE
  ${FILAMENT}/third_party/libassimp/contrib/rapidjson/include ${HOMEBREW}/opt/sqlite/include
  ${FILAMENT}/third_party/glslang ${FILAMENT}/third_party/spirv-tools/include ${FILAMENT}/libs/filamat/src
  ${FILAMENT}/third_party/dawn ${FILAMENT}/third_party/dawn/include ${FILAMENT}/out/wgpu/third_party/dawn/gen)
endforeach()

# ---- Other projects' libraries, each named once and linked by the module that uses it.

# Filament with its WebGPU backend, and our interop built inside Filament's own build (gpu/CMakeLists.txt).
add_library(filament_libraries INTERFACE)
target_link_directories(filament_libraries INTERFACE ${FILAMENT_SDK}/lib/arm64)
target_link_libraries(filament_libraries INTERFACE
  ${FILAMENT}/out/wgpu/filament/motolii_probe/libmotolii_interop.a
  gltfio gltfio_core dracodec matp filament backend webgpu_dawn bluegl bluevk filabridge filaflat utils geometry smol-v
  ibl ktxreader stb uberzlib zstd shaders perfetto abseil meshoptimizer camutils image basis_transcoder uberarchive
  matdbg filamat civetweb viewer z
  "-framework Cocoa" "-framework SceneKit" "-framework ModelIO" "-framework Metal" "-framework CoreVideo"
  "-framework QuartzCore" "-framework IOSurface" "-framework IOKit" "-framework AVFoundation" "-framework CoreMedia"
  "-framework CoreGraphics" "-framework Accelerate")
add_library(skia_libraries INTERFACE)
target_link_libraries(skia_libraries INTERFACE ${SKIA}/out/path/libpathops.a ${SKIA}/out/path/libskia.a)

# ---- What every module is compiled with.

add_library(motolii_flags INTERFACE)
target_compile_options(motolii_flags INTERFACE -ffp-contract=off $<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc>)
target_compile_definitions(motolii_flags INTERFACE SQLITE_ENABLE_SESSION SQLITE_ENABLE_PREUPDATE_HOOK)
target_include_directories(motolii_flags INTERFACE
  # Libraries Filament carries in its source tree, used under their own names: <rapidjson/...>, <zstd.h>,
  # <stb_truetype.h>, <cgltf.h>.
  ${FILAMENT}/third_party/libassimp/contrib/rapidjson/include ${FILAMENT}/third_party/zstd/lib
  ${FILAMENT}/third_party/stb ${FILAMENT}/third_party/cgltf
  ${FILAMENT_SDK}/include ${THORVG}/inc ${THORVG}/src/loaders/lottie ${DAWN_INCLUDES}
  ${THIRD_PARTY}/libtess2/Include ${THIRD_PARTY}/curve_fit_nd/c ${SKIA} ${ABSENT_MOTION}
  ${THIRD_PARTY}/thermion_frame/include ${THIRD_PARTY}/qdtsne/include ${THIRD_PARTY}/scipy_lsap
  ${HOMEBREW}/opt/sqlite/include ${HOMEBREW}/opt/luajit/include/luajit-2.1 ${HOMEBREW}/opt/quickjs-ng/include
  ${THIRD_PARTY}/onnxruntime/include)

# ---- Modules: one target a folder, lowest first. A module lists the modules it includes headers from; CMake refuses
# a cycle between them. To add a file, add it to its module below.

# Small parts every module may use (JSON).
add_library(motolii_base INTERFACE)

# Adapter: absent motion code run as it is.
add_library(motolii_community_absent_motion STATIC $<TARGET_OBJECTS:absent_motion>)
target_link_libraries(motolii_community_absent_motion PUBLIC skia_libraries)
# Only part of AbsentMotion is compiled: what its scene.cpp would call to draw a whole scene is never reached, and
# the linker has to drop it before it looks for those functions.
target_link_options(motolii_community_absent_motion PUBLIC -Wl,-dead_strip)

# Adapter: quickjs code run as it is.
add_library(motolii_community_quickjs STATIC
  community/quickjs/script.cpp
  community/quickjs/script_leva.cpp)
target_link_libraries(motolii_community_quickjs PUBLIC motolii_flags)
target_link_directories(motolii_community_quickjs PUBLIC ${HOMEBREW}/opt/quickjs-ng/lib)
target_link_libraries(motolii_community_quickjs PUBLIC qjs)
target_link_options(motolii_community_quickjs PUBLIC -Wl,-rpath,${HOMEBREW}/opt/quickjs-ng/lib)

# Adapter: subtitles and lyrics as they are written: FFmpeg reads them, libass draws them.
add_library(motolii_community_subtitles STATIC
  community/subtitles/subtitles.cpp
  community/subtitles/subtitles_from_ffmpeg.cpp)
target_link_libraries(motolii_community_subtitles PUBLIC motolii_flags PkgConfig::FFMPEG)
target_include_directories(motolii_community_subtitles PRIVATE ${HOMEBREW}/opt/libass/include)
target_link_directories(motolii_community_subtitles PUBLIC ${HOMEBREW}/opt/libass/lib)
target_link_libraries(motolii_community_subtitles PUBLIC ass)
target_link_options(motolii_community_subtitles PUBLIC -Wl,-rpath,${HOMEBREW}/opt/libass/lib)

# Adapter: CSS animations from CodePen on a text layer's letters. Blitz and Stylo, in Rust (community/css/Cargo.toml),
# built by Cargo through Corrosion (corrosion-rs.github.io); Stylo is the patched copy deps/stylo.sh fetches.
find_package(Corrosion REQUIRED)
corrosion_import_crate(MANIFEST_PATH community/css/Cargo.toml CRATE_TYPES staticlib LOCKED)
add_library(motolii_community_css INTERFACE)
target_link_libraries(motolii_community_css INTERFACE motolii_css)

# Adapter: after effects code run as it is.
add_library(motolii_community_after_effects STATIC
  community/after_effects/lottie_slots.cpp)
target_link_libraries(motolii_community_after_effects PUBLIC motolii_flags motolii_base motolii_community_quickjs)

# Interop with Filament's WebGPU backend; its sources are built inside Filament's own build (gpu/CMakeLists.txt).
add_library(motolii_gpu INTERFACE)

# Where the shelves are on disk.
add_library(motolii_shelf STATIC
  shelf/shelf_folders.cpp)
target_link_libraries(motolii_shelf PUBLIC motolii_flags)

# Adapter: sites code run as it is.
add_library(motolii_community_sites STATIC
  community/sites/adapter.cpp
  community/sites/adapter_net.cpp
  community/sites/adapter_shadertoy.cpp
  community/sites/adapter_shadertoy_json.cpp)
target_link_libraries(motolii_community_sites PUBLIC motolii_flags motolii_base motolii_community_subtitles)
target_link_libraries(motolii_community_sites PUBLIC PkgConfig::GSTREAMER)   # adapter_net.cpp fetches with GLib

# Adapter: three code run as it is.
add_library(motolii_community_three STATIC
  community/three/solid_three.cpp
  community/three/three_isf.cpp)
target_link_libraries(motolii_community_three PUBLIC motolii_flags motolii_base)

# Adapter: isf code run as it is.
add_library(motolii_community_isf STATIC $<TARGET_OBJECTS:isf_translation>)
target_link_libraries(motolii_community_isf PUBLIC filament_libraries motolii_base motolii_community_sites motolii_community_three)

# Adapter: playcanvas code run as it is.
add_library(motolii_community_playcanvas STATIC
  community/playcanvas/splatfx.cpp)
target_link_libraries(motolii_community_playcanvas PUBLIC motolii_flags motolii_community_quickjs)

# Filament: the scene, cameras, lights, 3D files.
add_library(motolii_stage_render STATIC
  stage/render/gltf_model.cpp
  stage/render/point_cloud.cpp
  stage/render/render_draw.cpp
  stage/render/render_draw.mm
  stage/render/render_layers.cpp
  stage/render/render_shapes.cpp
  stage/render/render_stage.cpp)
target_link_libraries(motolii_stage_render PUBLIC motolii_flags motolii_base motolii_community_playcanvas)
target_link_libraries(motolii_stage_render PUBLIC filament_libraries)

# Screen effects.
add_library(motolii_stage_effects STATIC
  stage/effects/screen_fx.cpp
  stage/effects/screen_read.cpp
  stage/effects/screen_resources.cpp
  stage/effects/viewer_settings.cpp)
target_link_libraries(motolii_stage_effects PUBLIC motolii_flags motolii_base motolii_community_quickjs motolii_gpu motolii_shelf motolii_community_isf motolii_stage_render)

# Adapter: aviutl code run as it is.
add_library(motolii_community_aviutl STATIC
  community/aviutl/aviutl_fx.cpp
  community/aviutl/aviutl_load.cpp
  community/aviutl/aviutl_obj.cpp
  community/aviutl/aviutl_obj_draw.cpp
  community/aviutl/aviutl_obj_effect.cpp
  community/aviutl/aviutl_pixels.cpp
  community/aviutl/aviutl_run.cpp)
target_link_libraries(motolii_community_aviutl PUBLIC motolii_flags motolii_base motolii_community_quickjs motolii_gpu motolii_shelf motolii_stage_render motolii_stage_effects)
target_sources(motolii_community_aviutl PRIVATE $<TARGET_OBJECTS:aviutl_translation>)
target_link_directories(motolii_community_aviutl PUBLIC ${HOMEBREW}/opt/luajit/lib)
target_link_libraries(motolii_community_aviutl PUBLIC luajit-5.1)
target_link_options(motolii_community_aviutl PUBLIC -Wl,-rpath,${HOMEBREW}/opt/luajit/lib)

# Adapter: hydra code run as it is.
add_library(motolii_community_hydra STATIC
  community/hydra/hydra_isf.cpp)
target_link_libraries(motolii_community_hydra PUBLIC motolii_flags)

# Adapter: p5 code run as it is.
add_library(motolii_community_p5 STATIC
  community/p5/adapter_p5_shader.cpp)
target_link_libraries(motolii_community_p5 PUBLIC motolii_flags motolii_base motolii_community_sites motolii_community_hydra)

# Video, sound and MIDI, on GStreamer.
add_library(motolii_media STATIC
  media/midi_notes.cpp
  media/midi_roll.cpp
  media/sound_level.cpp
  media/sound_playback.cpp
  media/video_datamosh.cpp
  media/video_frame.cpp
  media/video_frames_for_scripts.cpp
  media/video_layer.cpp)
target_link_libraries(motolii_media PUBLIC motolii_flags motolii_base motolii_community_quickjs motolii_gpu motolii_stage_render)
target_sources(motolii_media PRIVATE $<TARGET_OBJECTS:video_flash_check>)
target_link_directories(motolii_media PUBLIC ${IRIS}/opencv_out/lib ${IRIS}/opencv_out/lib/opencv4/3rdparty)
target_link_libraries(motolii_media PUBLIC PkgConfig::GSTREAMER PkgConfig::FFMPEG ${IRIS}/lib/libiris.a
  opencv_features2d opencv_videoio opencv_imgcodecs opencv_imgproc opencv_core tegra_hal)

# Easing curves and Lottie motion.
add_library(motolii_motion STATIC
  motion/easing_curves.cpp
  motion/lottie_motion.cpp)
target_link_libraries(motolii_motion PUBLIC motolii_flags motolii_community_absent_motion)

# Adapter: script runner code run as it is.
add_library(motolii_community_script_runner STATIC
  community/script_runner/script_parameters.cpp
  community/script_runner/script_natives.cpp
  community/script_runner/script_runner.cpp)
target_link_libraries(motolii_community_script_runner PUBLIC motolii_flags motolii_community_quickjs motolii_community_after_effects motolii_community_sites motolii_community_three motolii_community_aviutl motolii_community_p5 motolii_community_subtitles motolii_media motolii_motion)


# ThorVG: 2D drawings placed in the scene.
add_library(motolii_stage_canvas STATIC
  stage/canvas/canvas_cache.cpp
  stage/canvas/canvas_change.cpp
  stage/canvas/canvas_cut.cpp
  stage/canvas/canvas_edge.cpp
  stage/canvas/canvas_flat.cpp
  stage/canvas/canvas_ramp.cpp
  stage/canvas/canvas_renderables.cpp
  stage/canvas/canvas_shape.cpp
  stage/canvas/canvas_sketch.cpp
  stage/canvas/canvas_type.cpp
  stage/canvas/image_pixels.cpp)
target_link_libraries(motolii_stage_canvas PUBLIC motolii_flags motolii_community_css motolii_community_absent_motion motolii_gpu motolii_shelf motolii_stage_render motolii_community_script_runner)
target_sources(motolii_stage_canvas PRIVATE $<TARGET_OBJECTS:thorvg_path_operators> $<TARGET_OBJECTS:skia_path_operations>)
target_link_libraries(motolii_stage_canvas PUBLIC ${THORVG}/build_dawn/src/libthorvg-1.a skia_libraries
  ${THIRD_PARTY}/libtess2/build/libtess2.a)

# A layer's own effect stack.
add_library(motolii_stage_layer_effects STATIC
  stage/layer_effects/layer_fx.cpp
  stage/layer_effects/layer_fx_place.cpp)
target_link_libraries(motolii_stage_layer_effects PUBLIC motolii_flags motolii_community_quickjs motolii_gpu motolii_community_three motolii_stage_render motolii_stage_effects motolii_community_aviutl motolii_stage_canvas)

# The project (SQLite): its values, edits, evaluation at a time.
add_library(motolii_document STATIC
  document/cards.cpp
  document/edit/arrange.cpp
  document/edit/easings_put.cpp
  document/edit/fx_put.cpp
  document/edit/hold.cpp
  document/edit/keys_put.cpp
  document/edit/layer_edit.cpp
  document/edit/parent.cpp
  document/edit/paths.cpp
  document/edit/elements.cpp
  document/edit/presets.cpp
  document/edit/relate.cpp
  document/edit/time_edit.cpp
  document/evaluate/camera.cpp
  document/evaluate/evaluate.cpp
  document/evaluate/evaluate_camera.cpp
  document/evaluate/evaluate_clipping.cpp
  document/evaluate/evaluate_copies.cpp
  document/evaluate/evaluate_layers.cpp
  document/evaluate/evaluate_lights.cpp
  document/evaluate/evaluate_materials.cpp
  document/evaluate/evaluate_scenes.cpp
  document/evaluate/evaluate_shape.cpp
  document/evaluate/fx_list.cpp
  document/evaluate/material.cpp
  document/evaluate/moment_fx.cpp
  document/evaluate/moment_fx_parts.cpp
  document/evaluate/place.cpp
  document/evaluate/place_joins.cpp
  document/evaluate/relations.cpp
  document/evaluate/layer_reads.cpp
  document/evaluate/shown.cpp
  document/evaluate/sketch.cpp
  document/evaluate/value_at.cpp
  document/evaluate/world.cpp
  document/marks.cpp
  document/match.cpp
  document/match/match_describe.cpp
  document/match/match_image.cpp
  document/match/match_layers.cpp
  document/match/match_light.cpp
  document/match/match_look.cpp
  document/match/match_models.cpp
  document/match/match_shape.cpp
  document/match/match_text.cpp
  document/match/match_video.cpp
  document/scripts/adapter.cpp
  document/scripts/expressions.cpp
  document/scripts/script_reads.cpp
  document/scripts/folders.cpp
  document/scripts/recipes.cpp
  document/scripts/scripts.cpp
  document/undo.cpp)
target_link_libraries(motolii_document PUBLIC motolii_flags motolii_base motolii_community_absent_motion motolii_community_css motolii_community_quickjs motolii_community_after_effects motolii_shelf motolii_community_sites motolii_community_three motolii_community_isf motolii_community_playcanvas motolii_stage_render motolii_stage_effects motolii_community_aviutl motolii_community_hydra motolii_community_p5 motolii_media motolii_motion motolii_community_script_runner motolii_stage_canvas motolii_stage_layer_effects)
target_link_libraries(motolii_document PUBLIC ${HOMEBREW}/opt/sqlite/lib/libsqlite3.dylib
  ${THIRD_PARTY}/curve_fit_nd/build/libcurve_fit_nd.a)

# The frame handed to the app.
add_library(motolii_stage STATIC
  stage/live.mm)
target_link_libraries(motolii_stage PUBLIC motolii_flags motolii_gpu motolii_stage_render motolii_stage_effects)

# The playback cache.
add_library(motolii_preview STATIC
  preview/playback_cache.cpp)
target_link_libraries(motolii_preview PUBLIC motolii_flags motolii_community_quickjs motolii_shelf motolii_stage_render motolii_stage_canvas motolii_document motolii_stage)

# The C API the app calls (entry/motolii.h).
add_library(motolii_entry OBJECT
  entry/calls.cpp
  entry/calls_easing.cpp
  entry/calls_files.cpp
  entry/calls_find.cpp
  entry/calls_later.cpp
  entry/calls_map.cpp
  entry/calls_shelf.cpp
  entry/calls_sound.cpp
  entry/calls_time.cpp
  entry/export.cpp
  entry/render_thread.cpp
  entry/render_thread_loop.cpp
  entry/snapshot.cpp
  entry/window.cpp)
target_link_libraries(motolii_entry PUBLIC motolii_flags motolii_base motolii_shelf motolii_stage_render motolii_media motolii_motion motolii_stage_canvas motolii_document motolii_stage motolii_preview)
# ONNX Runtime is the release deps/onnxruntime.sh fetches: one library that carries its own dependencies.
if(NOT EXISTS ${THIRD_PARTY}/onnxruntime/lib)
  message(FATAL_ERROR "third_party/onnxruntime is not fetched: run engine/deps/onnxruntime.sh")
endif()
target_link_directories(motolii_entry PUBLIC ${THIRD_PARTY}/onnxruntime/lib)
target_link_libraries(motolii_entry PUBLIC onnxruntime)
target_link_options(motolii_entry PUBLIC -Wl,-rpath,${THIRD_PARTY}/onnxruntime/lib)

# ---- What each module can include. Headers are written by their path from this folder ("stage/render/render.h"), so
# one include folder for everybody would let a module include any other. Instead each module is compiled with a folder
# of its own, out/cmake/views/<module>/, that holds links to the headers of the module itself and of the modules it
# links to (and theirs), and to nothing else. An include of a module it did not declare does not compile.

set(VIEWS ${CMAKE_BINARY_DIR}/views)
get_property(modules DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
list(FILTER modules INCLUDE REGEX "^motolii_")
list(REMOVE_ITEM modules motolii_flags)

# motolii_stage_render -> stage/render, motolii_community_isf -> community/isf, motolii_document -> document
function(motolii_module_dir out module)
  string(REGEX REPLACE "^motolii_(community|stage)_" "\\1/" dir ${module})
  string(REGEX REPLACE "^motolii_" "" dir ${dir})
  set(${out} ${dir} PARENT_SCOPE)
endfunction()

# The headers a module owns: those under its folder, less those under the folder of a module inside it (stage/ and
# stage/render/).
foreach(module IN LISTS modules)
  motolii_module_dir(dir ${module})
  set(modules_inside "")
  foreach(other IN LISTS modules)
    motolii_module_dir(other_dir ${other})
    if(other_dir MATCHES "^${dir}/")
      list(APPEND modules_inside ${other_dir})
    endif()
  endforeach()
  file(GLOB_RECURSE headers CONFIGURE_DEPENDS RELATIVE ${ENGINE} ${ENGINE}/${dir}/*.h)
  foreach(inside IN LISTS modules_inside)
    list(FILTER headers EXCLUDE REGEX "^${inside}/")
  endforeach()
  set(headers_of_${module} ${headers})
endforeach()

foreach(module IN LISTS modules)
  set(todo ${module})
  set(reach "")
  while(todo)
    list(POP_FRONT todo next)
    if(NOT next IN_LIST reach)
      list(APPEND reach ${next})
      get_target_property(links ${next} INTERFACE_LINK_LIBRARIES)
      get_target_property(private_links ${next} LINK_LIBRARIES)
      foreach(link IN LISTS links private_links)
        if(link IN_LIST modules)
          list(APPEND todo ${link})
        endif()
      endforeach()
    endif()
  endwhile()
  set(view ${VIEWS}/${module})
  file(REMOVE_RECURSE ${view})
  file(MAKE_DIRECTORY ${view})
  file(CREATE_LINK ${THIRD_PARTY} ${view}/third_party SYMBOLIC)
  foreach(visible IN LISTS reach)
    foreach(header IN LISTS headers_of_${visible})
      get_filename_component(folder ${view}/${header} DIRECTORY)
      file(MAKE_DIRECTORY ${folder})
      file(CREATE_LINK ${ENGINE}/${header} ${view}/${header} SYMBOLIC)
    endforeach()
  endforeach()
  get_target_property(kind ${module} TYPE)
  if(NOT kind STREQUAL "INTERFACE_LIBRARY")
    target_include_directories(${module} PRIVATE ${view})
  endif()
endforeach()

# The sources that carry flags of their own are compiled for the module that links their objects.
foreach(pair thorvg_path_operators:motolii_stage_canvas skia_path_operations:motolii_stage_canvas
    absent_motion:motolii_community_absent_motion video_flash_check:motolii_media
    isf_translation:motolii_community_isf aviutl_translation:motolii_community_aviutl)
  string(REPLACE ":" ";" pair ${pair})
  list(GET pair 0 objects)
  list(GET pair 1 owner)
  target_include_directories(${objects} PRIVATE ${VIEWS}/${owner})
endforeach()

# ---- The library the app loads: the entry module's objects (the C API). Every other module is a static library
# reached through the dependencies the modules declare.

add_library(motolii SHARED
  third_party/scipy_lsap/rectangular_lsap.cpp third_party/thermion_frame/FrameScheduler.cpp)
target_link_libraries(motolii PRIVATE motolii_entry)
set_target_properties(motolii PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${ENGINE}/out INSTALL_NAME_DIR "@rpath" BUILD_WITH_INSTALL_NAME_DIR ON)

# ---- The shell: a project edited by one call a line (edit.sh).

add_executable(edit_wgpu entry/edit.cpp)
target_include_directories(edit_wgpu PRIVATE ${VIEWS}/motolii_entry)
target_link_libraries(edit_wgpu PRIVATE motolii)
set_target_properties(edit_wgpu PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${ENGINE}/out BUILD_RPATH "@executable_path")

# ---- Tests: <name>_test.cpp beside the code it tests. Each module has a test program of its own, linked with that
# module and the modules it declares and nothing else, so a module is judged without building the rest:
#   cmake --build out/cmake --target motolii_motion_test && ctest --test-dir out/cmake -R '^Easing'

include(CTest)
if(BUILD_TESTING)
  # Homebrew's googletest (Brewfile), not one another toolchain on PATH happens to carry.
  find_package(GTest REQUIRED CONFIG PATHS ${HOMEBREW}/opt/googletest NO_DEFAULT_PATH)
  include(GoogleTest)
  # motolii_module_tests(<module target> <glob> ...): the module's own tests.
  function(motolii_module_tests module)
    file(GLOB tests CONFIGURE_DEPENDS ${ARGN})
    if(tests)
      add_executable(${module}_test ${tests})
      target_link_libraries(${module}_test PRIVATE ${module} GTest::gtest_main)
      target_include_directories(${module}_test PRIVATE ${VIEWS}/${module})
      # Beside the library in out/: the engine finds the shelves and its own parts from where its code is loaded.
      set_target_properties(${module}_test PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${ENGINE}/out)
      gtest_discover_tests(${module}_test)
    endif()
  endfunction()
  foreach(folder base shelf motion media preview stage entry)
    motolii_module_tests(motolii_${folder} ${folder}/*_test.cpp)
  endforeach()
  foreach(folder absent_motion after_effects aviutl hydra isf p5 playcanvas quickjs script_runner sites three)
    motolii_module_tests(motolii_community_${folder} community/${folder}/*_test.cpp)
  endforeach()
  foreach(folder render canvas effects layer_effects)
    motolii_module_tests(motolii_stage_${folder} stage/${folder}/*_test.cpp)
  endforeach()
  motolii_module_tests(motolii_document document/*_test.cpp document/*/*_test.cpp)
endif()
