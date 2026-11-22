# Packages a self-contained Windows Release directory for Motolii (ready for Velopack `vpk pack`).
# Usage: pwsh packaging/windows/bundle_windows.ps1 [-SrcDir app/build/windows/x64/runner/Release] [-DstDir app/build/release/windows]
param(
  [string]$SrcDir = "",
  [string]$DstDir = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
if (-not $SrcDir) { $SrcDir = Join-Path $RepoRoot "app/build/windows/x64/runner/Release" }
if (-not $DstDir) { $DstDir = Join-Path $RepoRoot "app/build/release/windows" }

if (-not (Test-Path $SrcDir)) {
  throw "Flutter Windows Release directory not found: $SrcDir"
}

$EngineOut = Join-Path $RepoRoot "engine/out"
$EngineDll = Join-Path $EngineOut "libmotolii.dll"
if (-not (Test-Path $EngineDll)) {
  throw "Engine library not found: $EngineDll (run engine/build.sh lib first)"
}

Write-Host "==> Creating self-contained Windows release directory: $DstDir"
if (Test-Path $DstDir) { Remove-Item -Recurse -Force $DstDir }
New-Item -ItemType Directory -Path $DstDir -Force | Out-Null
Copy-Item -Recurse -Force (Join-Path $SrcDir "*") $DstDir

# 1. Copy libmotolii.dll + runtime DLLs beside motolii.exe and into engine/out
$DstEngineOut = Join-Path $DstDir "engine/out"
New-Item -ItemType Directory -Path $DstEngineOut -Force | Out-Null
Get-ChildItem -Path $EngineOut -Filter "*.dll" | ForEach-Object {
  Copy-Item -Force $_.FullName $DstDir
  Copy-Item -Force $_.FullName $DstEngineOut
}

# Copy GStreamer MSVC runtime DLLs & essential plugins when GSTREAMER_1_0_ROOT_MSVC_X86_64 is present
if ($env:GSTREAMER_1_0_ROOT_MSVC_X86_64) {
  $GstBin = Join-Path $env:GSTREAMER_1_0_ROOT_MSVC_X86_64 "bin"
  if (Test-Path $GstBin) {
    Get-ChildItem -Path $GstBin -Filter "*.dll" | ForEach-Object {
      Copy-Item -Force $_.FullName $DstDir
    }
  }
}

# 2. Bundle Filament materials, IBL/skybox rooms, LGPL ffmpeg, tiny runtime JS shims, and shelves/
$DstWebGpu = Join-Path $DstEngineOut "filament_webgpu"
Copy-Item -Recurse -Force (Join-Path $EngineOut "filament_webgpu") $DstWebGpu
foreach ($room in @("small_studio", "studio", "lightroom", "studio_small_02_2k", "graffiti_shelter_2k", "parking_garage_2k", "pillars_2k", "venetian_crossroads_2k")) {
  $roomSrc = Join-Path $EngineOut $room
  if (Test-Path $roomSrc) {
    Copy-Item -Recurse -Force $roomSrc (Join-Path $DstEngineOut $room)
  }
}
$FfmpegExe = Join-Path $RepoRoot "engine/third_party/ffmpeg_lgpl/bin/ffmpeg.exe"
if (Test-Path $FfmpegExe) {
  $FfmpegDst = Join-Path $DstDir "engine/third_party/ffmpeg_lgpl/bin"
  New-Item -ItemType Directory -Path $FfmpegDst -Force | Out-Null
  Copy-Item -Force $FfmpegExe $FfmpegDst
}

$P5Src = Join-Path $RepoRoot "engine/third_party/js/p5/p5.min.js"
if (Test-Path $P5Src) {
  $P5Dst = Join-Path $DstDir "engine/third_party/js/p5"
  New-Item -ItemType Directory -Path $P5Dst -Force | Out-Null
  Copy-Item -Force $P5Src $P5Dst
}
$AnimeSrc = Join-Path $RepoRoot "engine/third_party/anime/anime.umd.min.js"
if (Test-Path $AnimeSrc) {
  $AnimeDst = Join-Path $DstDir "engine/third_party/anime"
  New-Item -ItemType Directory -Path $AnimeDst -Force | Out-Null
  Copy-Item -Force $AnimeSrc $AnimeDst
}

Copy-Item -Recurse -Force (Join-Path $RepoRoot "shelves") (Join-Path $DstDir "shelves")
Write-Host "==> Done: $DstDir"
