# Porting the engine to Windows

What it would take to build the engine on Windows, for a developer who has a Windows machine and wants to start.

The engine has not been built or run on Windows yet, and no Windows machine has been available. This document records what reading the sources and headers shows, what is still unknown, and the first steps once a machine is there.

The engine is Filament on Dawn (WebGPU), ThorVG, GStreamer, SQLite and ffmpeg.

## What should work as it is

| Part | Why | Where it was checked |
|---|---|---|
| Filament's WebGPU backend | It has a Windows platform class, which lets Dawn pick Vulkan or D3D12. | `engine/third_party/filament_src/filament/backend/src/webgpu/platform/WebGPUPlatformWindows.cpp` |
| Materials (`flat.mat`, `thick_glass.mat`, `matte.mat` and the rest), types and layering | They are built for WebGPU and have no Mac-only lines. | `engine/materials/` |
| ThorVG (After Effects art, pictures, text) | It draws on Dawn, which exists on Windows. It builds with meson. | `engine/deps/thorvg.sh` |
| 3D files (gltfio) | A Filament component. `gltf_model.h` has no OS-specific lines. | `engine/stage/render/gltf_model.h` |
| The project (SQLite), keyframes (GStreamer's controller) and the edit calls (`motolii.h`) | All plain C or C++. No OS-specific lines in `document.h` or `motolii.h`. | `engine/document/document.h`, `engine/entry/motolii.h` |
| Reading video (GStreamer's `decodebin3`; cutting, speed, reverse) | Only GStreamer's own interface is used. On Windows GStreamer picks the D3D12 or D3D11 hardware decoder parts itself. | `engine/media/video_layer.cpp` |
| Sound and export (ffmpeg) | The engine runs the command and picks the H.264 encoder from what that ffmpeg lists. Which ffmpeg to ship, and the libraries: [PACKAGING.md](PACKAGING.md). | `film` in `engine/stage/render/render_draw.h`, `engine/base/video_encoder.h` |

## What needs rewriting (Mac-only code)

| Part | Now | On Windows | What is known |
|---|---|---|---|
| Handing a decoded video frame to the GPU (`engine/media/video_layer.cpp`) | The hardware decoder's frame (an IOSurface) is shared into Dawn with `SharedTextureMemoryIOSurface`. | A D3D12 or D3D11 frame shared into Dawn with `SharedTextureMemoryD3D12Resource`, `D3D11Texture2D` or `DXGISharedHandle`. | Dawn has these interfaces: the feature names are in `webgpu.h` and `dawn/native/D3D12Backend.h`. The feature list the Filament patch requests (`engine/deps/patches/filament/filament_dawn_compute.patch`) needs the Windows feature names added. |
| Getting the decoded frame from GStreamer | The code reads an unpublished layout of GStreamer's memory. | GStreamer should have a public D3D12 header (`gst/d3d12`). | **Not confirmed.** The GStreamer installed on the Mac has no Windows headers, so the names could not be checked. If the header exists, this will be a cleaner (public) interface than the Mac one. |
| Color range of a frame (narrow or full) | Read from the frame's format (`420v` or `420f` on the Mac). | A D3D frame's format carries no range, so the range must be read from GStreamer's caps. | On the Mac the caps and the content disagreed. Whether they do on Windows is not known. |
| Writing a picture to a file (`shoot` in `engine/stage/render/render_draw.mm`) | Cocoa (`NSBitmapImageRep`). | Filament's `imageio`, or any PNG writer. | Not started. |
| Build | CMake, with Mac frameworks listed in `engine/CMakeLists.txt`, driven by `engine/build.sh` (zsh). | The same CMake file with a Windows branch, and a build script that is not zsh. | Not started. |
| `gpu_interop` (a way to put work into Filament's render queue) | Uses Filament's internal headers. | The same on every OS. | Needed so that ThorVG draws on Filament's device (`engine/gpu/gpu_interop.h`). |
| Frame timing | Thermion's `FrameScheduler` uses CVDisplayLink. | The same class uses DXGI on Windows (`engine/third_party/thermion_frame/`). | Not tried. |
| Showing the preview in the app | `engine/stage/live.h` draws into three IOSurface-backed CVPixelBuffers that a Flutter external texture reads (`app/macos/Runner/MainFlutterWindow.swift`). | A shared D3D11 texture handed to Flutter's Windows texture registrar. | See the unknowns below. The app has no `windows/` runner yet. |

## What is not known

- Whether to run Dawn on D3D12 or Vulkan. Video hand-over is more direct with D3D12, because a D3D12 frame can be passed as it is.
- Whether the two-plane format `R8BG8Biplanar420Unorm` (luma plus chroma) works the same way on Dawn's D3D12 backend. The feature `DawnMultiPlanarFormats` exists, but it has not been tried.
- How many videos the hardware decoder can read at the same time. On the Mac it is 59.
- How to give Flutter on Windows a moving picture without a copy. It will differ from the Mac code. Flutter's Windows embedder accepts a GPU surface in the form of a DXGI shared handle or an `ID3D11Texture2D` (BGRA8888 or RGBA8888).
- Which kind of D3D11 shared handle Dawn and Flutter can both open, and how to choose the same GPU on a laptop that has two.

## First step

Build one project without video (a mask, for example) on Windows and draw the same picture as on the Mac. Everything it needs is in the first table above, so if this fails, the cause is the build procedure.
