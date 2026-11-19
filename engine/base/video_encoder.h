#ifndef MOTOLII_BASE_VIDEO_ENCODER_H_
#define MOTOLII_BASE_VIDEO_ENCODER_H_
// Which H.264 encoder to ask ffmpeg for. The ffmpeg this engine runs is LGPL only (deps/ffmpeg.sh), so it has no libx264;
// each OS has its own: VideoToolbox on a Mac, MediaFoundation on Windows, VAAPI on Linux, NVENC / QSV / AMF on a
// graphics card, OpenH264 in software anywhere. So the choice is made from what that ffmpeg lists, not from the OS.
#include <cstdio>
#include <sstream>
#include <string>
#include <vector>

#include "base/posix.h"  // (popen and null_device, Windows' too)

namespace motolii {

// The first encoder of `wanted` that `listing` (the text of `ffmpeg
// -hide_banner -encoders`) names as a video encoder; "" if none. A line is: six
// flag characters (the first is V for video), the name, a description.
inline std::string encoder_among(const std::string& listing,
                                 const std::vector<std::string>& wanted) {
  std::istringstream lines(listing);
  std::string line;
  std::vector<std::string> found(wanted.size());
  while (std::getline(lines, line)) {
    std::istringstream words(line);
    std::string flags, name;
    if (!(words >> flags >> name) || flags.empty() || flags[0] != 'V') continue;
    for (size_t i = 0; i < wanted.size(); ++i)
      if (name == wanted[i]) found[i] = name;
  }
  for (const std::string& one : found)
    if (!one.empty()) return one;
  return "";
}

// The H.264 encoder to use, of those `listing` names.
inline std::string h264_encoder(const std::string& listing) {
  return encoder_among(
      listing, {"h264_videotoolbox", "h264_nvenc", "h264_qsv", "h264_amf",
                "h264_mf", "h264_vaapi", "libopenh264", "libx264"});
}

// The HEVC encoder to use, in the same order: the system's own first
// (VideoToolbox, then a graphics card's, MediaFoundation on Windows, VAAPI on
// Linux), libx265 last.
inline std::string hevc_encoder(const std::string& listing) {
  return encoder_among(
      listing, {"hevc_videotoolbox", "hevc_nvenc", "hevc_qsv", "hevc_amf",
                "hevc_mf", "hevc_vaapi", "libx265"});
}

// The ffmpeg arguments that set an encoder's quality, with a space on each side. Only VideoToolbox (-q:v 68, measured
// against libx264 -crf 17 with VMAF, stage/render/render_draw.cpp) and libx264 are tuned: the others get a bit rate,
// `mbps` or 8 Mbit/s, and still have to be measured the same way on their own OS.
inline std::string h264_quality(const std::string& encoder, double mbps) {
  const std::string m = std::to_string(mbps > 0.0 ? mbps : 8.0) + "M";
  if (encoder == "h264_videotoolbox")
    return mbps > 0.0 ? " -b:v " + m + " -maxrate " + m + " " : " -q:v 68 ";
  if (encoder == "libx264")
    return mbps > 0.0 ? " -b:v " + m + " -maxrate " + m + " " : " -crf 17 ";
  return " -b:v " + m + " ";
}

// What the ffmpeg that PATH finds first lists with -encoders, asked once
// (popen; "" if there is no ffmpeg).
inline const std::string& encoders_here() {
  static const std::string listing = [] {
    std::string said;
    if (FILE* from = popen(
            (std::string("ffmpeg -hide_banner -encoders 2> ") + null_device)
                .c_str(),
            "r")) {
      char block[4096];
      for (size_t n; (n = std::fread(block, 1, sizeof block, from)) > 0;)
        said.append(block, n);
      pclose(from);
    }
    return said;
  }();
  return listing;
}

// The H.264 and HEVC encoders of that ffmpeg ("" if it has none).
inline std::string h264_encoder_here() { return h264_encoder(encoders_here()); }
inline std::string hevc_encoder_here() { return hevc_encoder(encoders_here()); }

}  // namespace motolii

#endif  // MOTOLII_BASE_VIDEO_ENCODER_H_
