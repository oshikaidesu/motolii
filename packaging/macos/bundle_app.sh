#!/bin/zsh
# Packages a self-contained macOS Motolii.app bundle:
# - Copies libmotolii.dylib + all non-system dependent dylibs (Homebrew, FFmpeg LGPL, ONNX Runtime) into Contents/Frameworks
# - Rewrites every install name & dependency load path to @loader_path/<name>
# - Bundles filament_webgpu materials/skyboxes, runtime JS shims, and shelves/ into Contents/Resources
# - Ad-hoc signs the relocated bundle and verifies zero external Homebrew/repo dylib references remain
# Usage: packaging/macos/bundle_app.sh [source.app] [dest.app]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_APP="${1:-$REPO_ROOT/app/build/macos/Build/Products/Release/Motolii.app}"
DST_APP="${2:-$REPO_ROOT/app/build/release/Motolii.app}"

if [ ! -d "$SRC_APP" ]; then
  echo "error: source app not found at $SRC_APP" >&2
  exit 1
fi

ENGINE_DYLIB="$REPO_ROOT/engine/out/libmotolii.dylib"
if [ ! -f "$ENGINE_DYLIB" ]; then
  echo "error: engine library not found at $ENGINE_DYLIB (run engine/build.sh lib first)" >&2
  exit 1
fi

echo "==> Creating self-contained bundle: $DST_APP"
rm -rf "$DST_APP"
mkdir -p "$(dirname "$DST_APP")"
ditto "$SRC_APP" "$DST_APP"

FRAMEWORKS="$DST_APP/Contents/Frameworks"
RESOURCES="$DST_APP/Contents/Resources"
mkdir -p "$FRAMEWORKS" \
         "$RESOURCES/engine/out" \
         "$RESOURCES/engine/third_party/js/p5" \
         "$RESOURCES/engine/third_party/anime"

# 1. Copy libmotolii.dylib + recursively collect & rewrite all non-system dylib dependencies
cp -f "$ENGINE_DYLIB" "$FRAMEWORKS/libmotolii.dylib"
chmod 755 "$FRAMEWORKS/libmotolii.dylib"

python3 - "$FRAMEWORKS" "$REPO_ROOT" <<'PY'
import os, shutil, subprocess, sys
from pathlib import Path

frameworks = Path(sys.argv[1])
repo_root = Path(sys.argv[2])

search_dirs = [
    frameworks,
    repo_root / "engine/out",
    repo_root / "engine/third_party/onnxruntime/lib",
    repo_root / "engine/third_party/ffmpeg_lgpl/lib",
    Path("/opt/homebrew/lib"),
    Path("/usr/local/lib"),
]

def is_system(dep: str) -> bool:
    return (
        dep.startswith("/System/")
        or dep.startswith("/usr/lib/")
        or dep.startswith("@executable_path/")
        or dep.startswith("@loader_path/")
    )

def resolve_dep(dep: str, parent_dir: Path) -> Path | None:
    if dep.startswith("@rpath/"):
        name = dep[len("@rpath/"):]
        for d in [parent_dir, *search_dirs]:
            cand = d / name
            if cand.exists():
                return cand.resolve()
        return None
    p = Path(dep)
    if p.exists():
        return p.resolve()
    name = p.name
    for d in [parent_dir, *search_dirs]:
        cand = d / name
        if cand.exists():
            return cand.resolve()
    return None

def list_deps(binary: Path) -> list[str]:
    out = subprocess.check_output(["otool", "-L", str(binary)], text=True)
    deps = []
    for line in out.splitlines()[1:]:
        line = line.strip()
        if not line:
            continue
        dep = line.split(" (", 1)[0]
        if Path(dep).name == binary.name and dep.startswith("@"):
            continue
        deps.append(dep)
    return deps

# Map bundled filename -> original resolved parent dir for transitive resolution
queue: list[tuple[Path, Path]] = [(frameworks / "libmotolii.dylib", repo_root / "engine/out")]
processed: set[str] = set()

while queue:
    target, orig_dir = queue.pop(0)
    if target.name in processed:
        continue
    processed.add(target.name)

    # Set clean install id
    subprocess.run(["install_name_tool", "-id", f"@loader_path/{target.name}", str(target)], check=True)

    for dep in list_deps(target):
        if is_system(dep):
            continue
        resolved = resolve_dep(dep, orig_dir)
        if resolved is None:
            print(f"warning: unresolved dependency {dep} of {target.name}", file=sys.stderr)
            continue
        dep_name = Path(dep).name if not dep.startswith("@") else dep.split("/")[-1]
        dst = frameworks / dep_name
        if not dst.exists():
            shutil.copy2(resolved, dst)
            os.chmod(dst, 0o755)
            queue.append((dst, resolved.parent))
        subprocess.run(
            ["install_name_tool", "-change", dep, f"@loader_path/{dep_name}", str(target)],
            check=True,
        )

print(f"Bundled and rewritten {len(processed)} dylibs in {frameworks}")
PY

# 2. Bundle GStreamer core plugins if present (for video/audio decoding in clean environments)
GST_PLUGINS_SRC="/opt/homebrew/lib/gstreamer-1.0"
if [ -d "$GST_PLUGINS_SRC" ]; then
  mkdir -p "$RESOURCES/gstreamer-1.0"
  # Copy essential media plugins only (keeps bundle compact while supporting mp4/mov/wav/png)
  for plugin in libgstcoreelements.dylib libgstplayback.dylib libgsttypefindfunctions.dylib \
                libgstisomp4.dylib libgstlibav.dylib libgstaudioconvert.dylib \
                libgstaudioresample.dylib libgstvideoconvertscale.dylib libgstapp.dylib \
                libgstwavparse.dylib libgstapplemedia.dylib; do
    if [ -f "$GST_PLUGINS_SRC/$plugin" ]; then
      cp -f "$GST_PLUGINS_SRC/$plugin" "$RESOURCES/gstreamer-1.0/"
    fi
  done
fi

# 3. Bundle Filament materials, IBL/skybox rooms, LGPL ffmpeg, tiny runtime JS libraries, and shelves/
echo "==> Copying filament_webgpu, IBL rooms, and shelves/ into Resources"
rm -rf "$RESOURCES/engine/out/filament_webgpu" "$RESOURCES/shelves"
ditto "$REPO_ROOT/engine/out/filament_webgpu" "$RESOURCES/engine/out/filament_webgpu"
for room_dir in small_studio studio lightroom studio_small_02_2k \
                graffiti_shelter_2k parking_garage_2k pillars_2k venetian_crossroads_2k; do
  if [ -d "$REPO_ROOT/engine/out/$room_dir" ]; then
    rm -rf "$RESOURCES/engine/out/$room_dir"
    ditto "$REPO_ROOT/engine/out/$room_dir" "$RESOURCES/engine/out/$room_dir"
  fi
done
if [ -f "$REPO_ROOT/engine/third_party/ffmpeg_lgpl/bin/ffmpeg" ]; then
  mkdir -p "$RESOURCES/engine/third_party/ffmpeg_lgpl/bin"
  cp -f "$REPO_ROOT/engine/third_party/ffmpeg_lgpl/bin/ffmpeg" "$RESOURCES/engine/third_party/ffmpeg_lgpl/bin/ffmpeg"
  chmod 755 "$RESOURCES/engine/third_party/ffmpeg_lgpl/bin/ffmpeg"
fi
[ -f "$REPO_ROOT/engine/third_party/js/p5/p5.min.js" ] && \
  cp -f "$REPO_ROOT/engine/third_party/js/p5/p5.min.js" "$RESOURCES/engine/third_party/js/p5/p5.min.js"
[ -f "$REPO_ROOT/engine/third_party/anime/anime.umd.min.js" ] && \
  cp -f "$REPO_ROOT/engine/third_party/anime/anime.umd.min.js" "$RESOURCES/engine/third_party/anime/anime.umd.min.js"
ditto "$REPO_ROOT/shelves" "$RESOURCES/shelves"

# 4. Verify zero Homebrew or local user paths remain in bundled dylib dependencies (indented lines from otool -L)
echo "==> Auditing bundled dylib load paths"
LEAKS=$(otool -L "$FRAMEWORKS"/*.dylib | grep -E $'^\t.*(/opt/homebrew/|/Users/|/usr/local/)' || true)
if [ -n "$LEAKS" ]; then
  echo "error: leaked non-relocatable dylib paths found:" >&2
  echo "$LEAKS" >&2
  exit 1
fi
echo "OK: 0 leaked external dylib paths."

# 5. Ad-hoc sign the bundle so macOS executes all rewritten dylibs cleanly
echo "==> Ad-hoc signing $DST_APP"
codesign --force --deep --sign - "$DST_APP"
echo "==> Done: $DST_APP ($(du -sh "$DST_APP" | awk '{print $1}'))"
