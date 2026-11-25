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

$AeWorkerExe = Join-Path $EngineOut "motolii_ae_worker.exe"
if (Test-Path $AeWorkerExe) {
  Copy-Item -Force $AeWorkerExe $DstEngineOut
}

# Copy MSVC runtime DLLs so users without the VC++ Redistributable can launch immediately
$VcRedistDirs = @()
if ($env:VCToolsRedistDir) {
  $VcRedistDirs += Join-Path $env:VCToolsRedistDir "x64/Microsoft.VC143.CRT"
  $VcRedistDirs += Join-Path $env:VCToolsRedistDir "x64/Microsoft.VC142.CRT"
}
$VcRedistDirs += "C:\Windows\System32"
foreach ($dllName in @("vcruntime140.dll", "vcruntime140_1.dll", "msvcp140.dll", "msvcp140_1.dll", "msvcp140_2.dll", "concrt140.dll")) {
  foreach ($dir in $VcRedistDirs) {
    $cand = Join-Path $dir $dllName
    if (Test-Path $cand) {
      Copy-Item -Force $cand $DstDir
      break
    }
  }
}

# Copy GStreamer MSVC runtime DLLs & essential media plugins when GSTREAMER_1_0_ROOT_MSVC_X86_64 is present
if ($env:GSTREAMER_1_0_ROOT_MSVC_X86_64) {
  $GstBin = Join-Path $env:GSTREAMER_1_0_ROOT_MSVC_X86_64 "bin"
  if (Test-Path $GstBin) {
    Get-ChildItem -Path $GstBin -Filter "*.dll" | ForEach-Object {
      Copy-Item -Force $_.FullName $DstDir
    }
  }
  $GstPluginSrc = Join-Path $env:GSTREAMER_1_0_ROOT_MSVC_X86_64 "lib/gstreamer-1.0"
  if (Test-Path $GstPluginSrc) {
    $GstPluginDst = Join-Path $DstDir "gstreamer-1.0"
    New-Item -ItemType Directory -Path $GstPluginDst -Force | Out-Null
    $Plugins = @(
      "gstcoreelements.dll", "gstplayback.dll", "gsttypefindfunctions.dll",
      "gstisomp4.dll", "gstlibav.dll", "gstaudioconvert.dll",
      "gstaudioresample.dll", "gstvideoconvertscale.dll", "gstapp.dll",
      "gstwavparse.dll", "gstmediafoundation.dll", "gstwasapi.dll",
      "gstwasapi2.dll", "gstdirectsound.dll", "gstautodetect.dll",
      "gstaudiofx.dll", "gstvolume.dll", "gstaudioparsers.dll",
      "gstmatroska.dll", "gstogg.dll", "gstvorbis.dll", "gstopus.dll",
      "gstpng.dll", "gstjpeg.dll", "gstvideoparsersbad.dll",
      "gstspectrum.dll", "gstlevel.dll"
    )
    foreach ($plugin in $Plugins) {
      $src = Join-Path $GstPluginSrc $plugin
      if (Test-Path $src) {
        Copy-Item -Force $src $GstPluginDst
      }
    }
  }
}

# 2. Bundle Filament materials, IBL/skybox rooms, LGPL ffmpeg, runtime JS/data assets, and shelves/
$DstWebGpu = Join-Path $DstEngineOut "filament_webgpu"
New-Item -ItemType Directory -Path $DstWebGpu -Force | Out-Null
Get-ChildItem -Path (Join-Path $EngineOut "filament_webgpu") -Filter "*.filamat" | ForEach-Object {
  Copy-Item -Force $_.FullName $DstWebGpu
}
foreach ($room in @("small_studio", "studio", "lightroom", "studio_small_02_2k", "graffiti_shelter_2k", "parking_garage_2k", "pillars_2k", "venetian_crossroads_2k")) {
  $roomSrc = Join-Path $EngineOut $room
  if (Test-Path $roomSrc) {
    Copy-Item -Recurse -Force $roomSrc (Join-Path $DstEngineOut $room)
  }
}

foreach ($ffBin in @("ffmpeg.exe", "ffprobe.exe")) {
  $ffSrc = Join-Path $RepoRoot "engine/third_party/ffmpeg_lgpl/bin/$ffBin"
  if (Test-Path $ffSrc) {
    $ffDst = Join-Path $DstDir "engine/third_party/ffmpeg_lgpl/bin"
    New-Item -ItemType Directory -Path $ffDst -Force | Out-Null
    Copy-Item -Force $ffSrc $ffDst
  }
}

foreach ($relFile in @(
  "engine/third_party/js/p5/p5.min.js",
  "engine/third_party/anime/anime.umd.min.js",
  "engine/third_party/midi_roll/PianoRollSvg.js"
)) {
  $src = Join-Path $RepoRoot $relFile
  if (Test-Path $src) {
    $dst = Join-Path $DstDir $relFile
    New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
    Copy-Item -Force $src $dst
  }
}

foreach ($relDir in @(
  "engine/third_party/wordnet_ja",
  "engine/third_party/noto_sans_jp",
  "shelves"
)) {
  $src = Join-Path $RepoRoot $relDir
  if (Test-Path $src) {
    Copy-Item -Recurse -Force $src (Join-Path $DstDir $relDir)
  }
}

Write-Host "==> Done: $DstDir"
