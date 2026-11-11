# What Motolii's build asks of Homebrew (Homebrew Bundle:  brew bundle).  Xcode, Python 3, Flutter 3.47.2 and Rust (cargo) are not from here.
# To build: engine/build.sh
brew "cmake"
brew "ninja"
brew "meson"
brew "pkgconf"
# What builds the Rust inside the engine from CMake (community/css: CSS animations, Blitz and Stylo)
brew "corrosion"
# What the editor links: films (GStreamer), the document (SQLite), AviUtl's scripts (LuaJIT), effects and recipes (QuickJS-ng).
# (The shelves' maps telling how alike pictures look use ONNX Runtime, which engine/deps/onnxruntime.sh fetches.)
brew "gstreamer"
brew "sqlite"
brew "luajit"
brew "quickjs-ng"
# What pasted subtitles are drawn with: ASS and SSA, karaoke included (community/subtitles)
brew "libass"
# What the editor runs: writing a film (ffmpeg makes the mp4, render_draw.h's film)
brew "ffmpeg"
# (not the build: shelves/effects/sources/from_three.py, which makes effects from three.js shaders, wants naga on PATH: brew install naga-cli)
# What the checks run, not the build: the C++ formatter (.clang-format) and the C++ tests (engine/**/*_test.cpp, ctest)
brew "clang-format"
brew "googletest"
