#!/bin/zsh
# A document edited by calls, a line each on its input.   ./edit.sh out/first.motolii < calls.txt
# Two parts: the editing inside as a library with C calls (entry/motolii.h, entry/motolii.mm: films by GStreamer, the document's
# file, its undo and the working out of a stretch between keys by SQLite, 3D files by Filament's gltfio), and a shell that calls it
# (entry/edit.cpp), as a shell on a screen would.
doc=${1:a}; shift   # (the document's place as the caller said it, before this goes into engine/)
cd "$(dirname "$0")"
./build.sh || exit 1   # (built again only if something it is made of has changed since: build.sh)
cd out/filament_webgpu && BACKEND="${BACKEND:-webgpu}" ../edit_wgpu $doc "$@" 2>&1 | grep -v "FrameInfo's circular queue\|libvulkan\|BackendVk\|FEngine\|WebGPU adapter\|Backend feature"
