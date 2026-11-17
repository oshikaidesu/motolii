# Building and running on Windows

How to build the engine (`engine/out/libmotolii.dll`) and the Flutter app (`app/windows/`) on Windows 11 (x64), and how the Windows port works.

## What you need

| Tool | What was checked | Notes |
|---|---|---|
| Visual Studio 2022 | Desktop development with C++ (MSVC x64 toolset, Windows 10/11 SDK) | `engine/build.sh` runs inside the **x64 Native Tools Command Prompt for VS 2022** so `cl`, `link` and the Windows SDK headers are on `PATH`. |
| LLVM | 23.1.5 (`win64`) on `PATH` | Needs `clang`, `clang++`, `clang-cl`, `llvm-ar`, `llvm-link` and `opt`. The engine and hand-built libraries in `engine/deps/` compile with `clang`/`clang++` targeting MSVC's runtime DLL (`-fms-runtime-lib=dll`); Skia and ThorVG use `clang-cl`; Filament and FFmpeg use MSVC's `cl`. |
| CMake, Ninja, Meson, Python 3 | CMake 4.2, Ninja 1.12+, Meson 1.x, Python 3 on `PATH` | In Windows `PATH` (`pip install ninja meson`). |
| Rust (`rustup`) | Default host `x86_64-pc-windows-msvc` (`cargo`, `rustc` on `PATH`) | Compiles `engine/community/css` (Blitz and Stylo) through Corrosion. |
| Corrosion | Installed via CMake (`CMAKE_INSTALL_PREFIX` set to `<corrosion-prefix>`) | Set `MOTOLII_CORROSION=<corrosion-prefix>` (must contain `lib/cmake/Corrosion`). |
| GStreamer (MSVC 64-bit) | 1.28.8 MSVC x86_64 runtime **and** development installers | Set `GSTREAMER_1_0_ROOT_MSVC_X86_64` to the root folder (the one holding `bin/`, `lib/`, `include/`). Also provides `pkg-config.exe`, `libass` (`ass.lib`) and `z.lib`. |
| vcpkg | `x64-windows` triplet: `sqlite3[session]`, `luajit`, `quickjs-ng`, `gtest` | `vcpkg install sqlite3[session]:x64-windows luajit:x64-windows quickjs-ng:x64-windows gtest:x64-windows`. Set `MOTOLII_LIBRARIES` to the `installed/x64-windows` folder. |
| MSYS2 | `zsh`, `make`, `nasm`, `patch`, `diffutils`, `unzip`, `curl`, `git` | `pacman -S zsh make nasm patch diffutils unzip`. Used to run `engine/build.sh` and `engine/deps/*.sh` (not MinGW compilers). |
| Windows Developer Mode (or elevated prompt) | Enabled in Windows Settings | `engine/build.sh` sets `MSYS=winsymlinks:nativestrict` and CMake creates symbolic links for module header views under `engine/out/cmake/views/`. |
| Flutter | 3.47.2+ (stable) on `PATH` | Builds and runs `app/windows/`. |

## Environment variables

Before building, make sure these three variables point to your installations (forward or back slashes both work; `engine/build.sh` converts them with `cygpath -m`):

```cmd
set GSTREAMER_1_0_ROOT_MSVC_X86_64=C:\gstreamer\1.0\msvc_x86_64
set MOTOLII_LIBRARIES=C:\vcpkg\installed\x64-windows
set MOTOLII_CORROSION=C:\corrosion
```

## Build the engine

Open **x64 Native Tools Command Prompt for VS 2022**, inherit the Windows `PATH` into MSYS2, and run `engine/build.sh` with MSYS2's `zsh`:

```cmd
set MSYS2_PATH_TYPE=inherit
C:\msys64\usr\bin\zsh engine/build.sh
```

- The first run fetches and builds the dependencies in `engine/deps/` (Filament with its Dawn D3D12 backend, ThorVG, Skia pathops, Jolt, libtess2, curve_fit_nd, FFmpeg 9.0.2 LGPL with Media Foundation and D3D11VA, ONNX Runtime `win-x64`, OpenCV + IRIS, AbsentMotion, Stylo), compiles the materials (`engine/materials/build.sh`), configures CMake in `engine/out/cmake`, copies runtime DLLs (ONNX Runtime, FFmpeg, `$MOTOLII_LIBRARIES/bin/*.dll`) into `engine/out/`, and builds `engine/out/libmotolii.dll` and `engine/out/edit_wgpu.exe`.
- To rebuild only `libmotolii.dll`: `C:\msys64\usr\bin\zsh engine/build.sh lib`
- To build and run the C++ tests: `C:\msys64\usr\bin\zsh engine/build.sh test`

## Build and run the app

From a normal command prompt or PowerShell (with `GSTREAMER_1_0_ROOT_MSVC_X86_64` set in your environment):

```cmd
cd app
flutter run -d windows
```

At startup, `app/windows/runner/main.cpp`:
1. Sets `HOME` from `USERPROFILE` if `HOME` is not set.
2. Prepends the nearest `engine/out` folder and `%GSTREAMER_1_0_ROOT_MSVC_X86_64%\bin` to `PATH` so Windows can resolve all dependent DLLs when loading `libmotolii.dll`.
3. Uses a UTF-8 active code page (`app/windows/runner/runner.exe.manifest`) so standard C narrow file calls read UTF-8 paths the same way as on macOS.

---

## How the Windows port works (and current limitations)

| Area | On macOS | On Windows | Status |
|---|---|---|---|
| Filament & Dawn (WebGPU) | Metal backend | D3D12 backend (`engine/deps/patches/filament/filament_webgpu_windows.patch`); `TransientAttachments` made optional because Dawn D3D12 does not support it | Works |
| Preview frame sharing (`engine/stage/live.h`) | 3 `CVPixelBuffer`s backed by `IOSurface` (`engine/stage/live_shared_mac.mm`, `app/macos/Runner/MainFlutterWindow.swift`) | 3 D3D12 textures exported as DXGI shared handles (`engine/stage/live_shared_windows.cpp`) and registered with `kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle` (`app/windows/runner/live_texture.cpp`) | Works (no CPU copy) |
| Decoded video frames (`engine/media/video_frame.cpp`) | Hardware decoder's `IOSurface` imported into Dawn via `SharedTextureMemoryIOSurface` | Uploaded through CPU memory (`video_show_copied`) | Works via CPU copy; direct D3D12 frame sharing (`SharedTextureMemoryDXGISharedHandle`) is a future step |
| Video export & flash check | FFmpeg with VideoToolbox; OpenCV with AVFoundation | FFmpeg built with MSVC, Media Foundation (`h264_mf`, `hevc_mf`) and D3D11VA (`engine/deps/ffmpeg.sh`); OpenCV built with Media Foundation (`engine/deps/iris.sh`) | Built and tested |
| Still image export | Cocoa (`NSBitmapImageRep` in `engine/stage/render/render_draw.mm`) | `stb_image_write` PNG writer (`engine/stage/render/render_draw_png.cpp`) | Works |
| System fonts & user folders | CoreText; `~/Library/Application Support/Motolii` | DirectWrite (`engine/entry/calls_fonts.cpp`); `%APPDATA%/Motolii` | Works |
| Paths across engine & app | `/` everywhere | Engine converts `std::filesystem::path` with `generic_string()`; app normalizes OS paths with `slashed` and checks `isRooted` (`app/lib/storage/host_platform.dart`) | Works |
| Host integration | `RecentDocuments`, Finder, `sips`, `df`, `afplay` | `SHAddToRecentDocs` (`app/windows/runner/flutter_window.cpp`), Explorer & PowerShell `FolderBrowserDialog` (`app/lib/storage/open_in_host.dart`), `cmd /c dir`, `gst-launch-1.0` | Works |
| `motolii/glass` & `motolii/sampler` | macOS window glass study & screen eyedropper | Return `NotImplemented` in `app/windows/runner/live_texture.cpp` | Not implemented on Windows yet |