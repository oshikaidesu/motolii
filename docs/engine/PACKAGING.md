# Getting the engine's parts to a user, on each system

What has to be in a folder a user receives, per system, and what is decided and what is not. [WINDOWS.md](WINDOWS.md) is about porting the code; this is about the libraries and programs the engine needs.

Only the Mac (Apple silicon) has been built. The Windows and Linux columns come from reading the projects' own documents (the keys in brackets are listed at the end); nothing in them has been run. Where a source could not be found, the cell says **unconfirmed**.

The licence is the constraint behind most rows: Motolii is Apache-2.0 or MIT, so it must not link GPL code. FFmpeg is therefore an LGPL build (no `--enable-gpl`, no `--enable-nonfree`, no libx264 or libx265), linked dynamically, with its source offered. That is what [engine/deps/ffmpeg.sh](../../engine/deps/ffmpeg.sh) builds [legal].

## The parts

| Part | Mac (done) | Windows x64 | Linux x64 |
|---|---|---|---|
| **FFmpeg 9.0.2**, LGPL | `deps/ffmpeg.sh`; `tools/bundle_ffmpeg.sh` makes a folder that runs from anywhere (`@rpath`, ad hoc signed) | MSYS2 + MSVC: `./configure --toolchain=msvc --enable-shared --disable-static --disable-autodetect --enable-mediafoundation` [plat] [cfg]. DLLs and `ffmpeg.exe` flat next to the app | Native gcc or clang, `--enable-shared --disable-static --enable-pic --disable-autodetect` [plat] [cfg]. `.so` files in `lib/`, each with RUNPATH `$ORIGIN` (RUNPATH is not inherited by a library's own dependencies) [ld.so] |
| **H.264 encoder** | `h264_videotoolbox` (measured) | `h264_mf` (MediaFoundation: a system API, no extra library; absent on Windows N editions [mfenc]); later `h264_nvenc` (MIT headers, NVIDIA driver at run time) [cfg] [nvh] | `h264_vaapi` (libva, MIT) [cfg] [libva-lic]; `h264_nvenc` as on Windows |
| **Alpha `.mov`** | ProRes 4444 | ProRes 4444 (FFmpeg's own, same everywhere; its LGPL status was not confirmed in a document) | same |
| **GStreamer** | Homebrew's, not yet relocatable | Official MSVC runtime installer (1.28.8) [gst-dl]; copy a minimum plugin set into the app folder; set `GST_PLUGIN_SYSTEM_PATH` to it and `GST_REGISTRY` to a writable file before `gst_init` [gst-run]. Plugin lookup is relative to the DLL "as long as the folder structure is unmodified" [gst-win]: whether a copied tree is supported is **unconfirmed** | Do not bundle in the first version: list the distribution's packages (`gstreamer1.0-plugins-base`, `-good`, `-bad`) as dependencies [gst-lin] |
| **Hardware video decode** | `vtdec` | `d3d11h264dec` (rank primary+1) [d3d11], `d3d12h264dec`, `nvh264dec`, `qsvh264dec` | `vah264dec` (needs a VA-API driver) [vah264], `nvh264dec` |
| **Software decode** | `avdec_*` (gst-libav) | `avdec_h264` only from a gst-libav built against our LGPL FFmpeg; whether it builds against FFmpeg 9 and whether it clashes with a same-named DLL of the GStreamer installer are **unconfirmed** [gstlibav] | same |
| **ONNX Runtime 1.31.1**, MIT | `deps/onnxruntime.sh` (SHA-256 pinned) | `onnxruntime-win-x64-1.31.1.zip`, 82.9 MB; needs the Visual C++ 2019 runtime [ort-inst] [ort-api]. Layout of this release **unconfirmed** | `onnxruntime-linux-x64-1.31.1.tgz`, 11.4 MB. Minimum glibc **unconfirmed**: read the highest `GLIBC_*` symbol of the library [ort-compat] |
| SQLite, LuaJIT, QuickJS-ng | Homebrew's | Not researched: small, permissively licensed; build from source in `deps/` like the others (static where possible) | same |
| **About / licences** | macOS's About panel shows `macos/Runner/Credits.rtf` | Draw our own page: `showLicensePage` is in the Material library and the app is a `WidgetsApp` (unconfirmed whether it throws, but it uses `MaterialLocalizations` and `Theme`) [about.dart]. `LicenseRegistry` is not Material: register FFmpeg, GStreamer, ONNX Runtime and the other native libraries with it [licenses.dart] | same |
| **Packaging** | `.app` (not distributable yet: 22 Homebrew libraries remain, mostly GStreamer's) | Zip of the Release folder, then Inno Setup or WiX; MSIX needs signing [fl-win] [msix-sign] | A tarball of `bundle/` first; AppImage or deb later [fl-lin] [fl-deploy-lin] |
| **Signing** | Developer ID and notarization: the owner's certificate (not done) | Authenticode: a certificate from a CA Windows knows; Azure Artifact Signing is about $10 a month but limited by country and organisation [msix-sign]; SmartScreen warns for weeks | None required by Flutter's documents |

## What the code does about the differences

- The H.264 encoder is chosen from what the running `ffmpeg` lists ([base/video_encoder.h](../../engine/base/video_encoder.h)): VideoToolbox, NVENC, QSV, AMF, MediaFoundation, VAAPI, OpenH264, libx264, in that order. Only VideoToolbox (`-q:v 68`) and libx264 (`-crf 17`) have a quality value that was measured, against each other with VMAF. The others get a bit rate and **must be measured the same way on their own system**.
- Hardware video decoders are skipped on the CPU path by GStreamer's own "hardware" flag, not by the name `vtdec`.
- OpenH264 (software, any system) is **not** in the first path. Cisco's patent cover for its binary needs: not bundled in the app, downloaded at install time, the user can turn it off, and a credit line where users control the codec [oh264bin] [oh264faq]. FFmpeg links it at load time, so an `ffmpeg` built with it will not start without the library [oh264enc] (inference).

## The FFmpeg checklist, and where Motolii stands

[legal] asks for: no `--enable-gpl` or `--enable-nonfree` (done); dynamic linking (done); the FFmpeg source offered (the release's URL and SHA-256 are in `SOURCE.txt` of the bundle; the release page must carry the source); the configure line kept (done: CONFIGURE.txt of the bundle); an About line "This software uses libraries from the FFmpeg project under the LGPLv2.1" (done on the Mac; **to do** elsewhere); no ban on reverse engineering in the licence terms (none). Patents are not part of the checklist; the page treats them apart and asks for care in commercial use.

## What could still bring in GPL

- Any FFmpeg option that turns `--enable-gpl` on (libx264, libx265, libxvid, libvidstab, frei0r, librubberband and others) or `--enable-nonfree` (libfdk_aac, `cuda_nvcc`, `cuda_sdk`) [cfg].
- A gst-libav linked to a GPL FFmpeg, or a GPL GStreamer plugin: GStreamer then becomes "for all practical purposes under the GPL itself" [gstlibav]. Ship only the plugins we pick. Whether the official Windows installer carries GPL plugins is **unconfirmed**.
- A distribution's own `libavcodec`, on Linux: its licence depends on how the distribution configured it.

## First steps, per system

**Windows.** Build FFmpeg as above and check that `-encoders` lists `h264_mf` and that the banner has no `--enable-gpl`. Make one flat folder (executable, Flutter's DLLs, the engine, FFmpeg's DLLs and programs, `onnxruntime.dll`, the Visual C++ runtime DLLs) and run it on a machine with an empty `PATH` [msdll] [fl-win]. Then GStreamer's minimum plugin set. Zip first; an installer and signing later.

**Linux.** Build in a container on the oldest distribution to be supported [appimage-bp]. `ldd` and `readelf -d` the result. Dependencies on the distribution's GStreamer packages. Tarball first.

## Code that is still Mac or POSIX only

| What | Where |
|---|---|
| The PATH separator `:` and `setenv` | [base/search_path.h](../../engine/base/search_path.h), `findProgram` in the app (`.exe` suffix too) |
| `popen`, `system`, `SIGPIPE` | the export in [stage/render/render_draw.cpp](../../engine/stage/render/render_draw.cpp), the datamosh |
| `.mm` files (Cocoa, IOSurface) | `stage/live.mm`, `stage/render/render_draw.mm`: see [WINDOWS.md](WINDOWS.md) |
| Apple frameworks in CMake, `arm64`, `sysctl hw.ncpu`, `--enable-videotoolbox` | [CMakeLists.txt](../../engine/CMakeLists.txt), [deps/ffmpeg.sh](../../engine/deps/ffmpeg.sh) |
| zsh scripts (21) | `engine/**/*.sh`: Windows needs another shell or CMake |
| `.mov` without alpha | HEVC from VideoToolbox |

## Not confirmed

The contents of the Windows and Linux ONNX Runtime archives and the Linux glibc floor; whether GStreamer's Windows runtime can be copied into an app folder; whether current gst-libav builds against FFmpeg 9; whether the official Windows GStreamer installer includes GPL plugins; a full MSVC build of FFmpeg 9.0.2 with the line above; OpenH264's Windows asset name and whether an installer-time download satisfies Cisco; Authenticode signing of loose files with Artifact Signing; Flatpak and Snap details; whether `showLicensePage` throws without Material.

## Sources

[legal] https://www.ffmpeg.org/legal.html · [plat] https://ffmpeg.org/platform.html · [cfg] https://raw.githubusercontent.com/FFmpeg/FFmpeg/master/configure · [mfenc] https://raw.githubusercontent.com/FFmpeg/FFmpeg/master/libavcodec/mfenc.c · [oh264enc] https://raw.githubusercontent.com/FFmpeg/FFmpeg/master/libavcodec/libopenh264enc.c · [nvh] https://github.com/FFmpeg/nv-codec-headers · [libva-lic] https://raw.githubusercontent.com/intel/libva/master/COPYING · [oh264bin] https://www.openh264.org/BINARY_LICENSE.txt · [oh264faq] https://www.openh264.org/faq.html · [msdll] https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-search-order · [ld.so] https://man7.org/linux/man-pages/man8/ld.so.8.html · [fl-win] https://docs.flutter.dev/platform-integration/windows/building · [fl-lin] https://docs.flutter.dev/platform-integration/linux/building · [fl-deploy-lin] https://docs.flutter.dev/deployment/linux · [gst-dl] https://gstreamer.freedesktop.org/download/ · [gst-win] https://gstreamer.freedesktop.org/documentation/installing/on-windows.html · [gst-lin] https://gstreamer.freedesktop.org/documentation/installing/on-linux.html · [gst-run] https://gstreamer.freedesktop.org/documentation/gstreamer/running.html · [d3d11] https://gstreamer.freedesktop.org/documentation/d3d11/d3d11h264dec.html · [vah264] https://gstreamer.freedesktop.org/documentation/va/vah264dec.html · [gstlibav] https://github.com/GStreamer/gst-libav · [ort-api] https://api.github.com/repos/microsoft/onnxruntime/releases/tags/v1.31.1 · [ort-inst] https://onnxruntime.ai/docs/install/ · [ort-compat] https://onnxruntime.ai/docs/reference/compatibility.html · [about.dart] https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/about.dart · [licenses.dart] https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/foundation/licenses.dart · [msix-sign] https://learn.microsoft.com/en-us/windows/msix/package/signing-package-overview · [appimage-bp] https://docs.appimage.org/reference/best-practices.html
