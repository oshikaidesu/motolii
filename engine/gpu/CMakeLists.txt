# Built inside Filament's own build (both need the engine's private headers):
#   cmake -DMOTOLII_PROBE_DIR=<this folder> ...   (see filament_dawn_compute.patch, build.sh)
# compute_interop.h and gpu_interop.h for programs built outside this build (filament_webgpu.sh)
add_library(motolii_door STATIC compute_interop.cpp gpu_interop.cpp screen_interop.cpp)
target_link_libraries(motolii_door PUBLIC filament)
# WebGPUPlatform.h includes Dawn's C++ header
target_include_directories(motolii_door PRIVATE ${EXTERNAL}/dawn/include ${CMAKE_BINARY_DIR}/third_party/dawn/gen/include)
