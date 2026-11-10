#ifndef MOTOLII_BASE_VIDEO_ENCODER_H_
#define MOTOLII_BASE_VIDEO_ENCODER_H_
// Which H.264 encoder to ask ffmpeg for. The ffmpeg this engine runs is LGPL only (deps/ffmpeg.sh), so it has no libx264;
// each OS has its own: VideoToolbox on a Mac, MediaFoundation on Windows, VAAPI on Linux, NVENC / QSV / AMF on a
// graphics card, OpenH264 in software anywhere. So the choice is made from what that ffmpeg lists, not from the OS.
#include <cstdio>
#include <sstream>
#include <string>

namespace motolii {

// The first encoder of this list that `listing` (the text of `ffmpeg -hide_banner -encoders`) names as a video
// encoder; "" if none. A line is: six flag characters (the first is V for video), the name, a description.
inline std::string h264_encoder(const std::string& listing) {
  static const char* const wanted[] = {
      "h264_videotoolbox", "h264_nvenc", "h264_qsv",     "h264_amf",
      "h264_mf",           "h264_vaapi", "libopenh264", "libx264"};
  std::istringstream lines(listing);
  std::string line, found[8];
  while (std::getline(lines, line)) {
    std::istringstream words(line);
    std::string flags, name;
    if (!(words >> flags >> name) || flags.empty() || flags[0] != 'V') continue;
    for (int i = 0; i < 8; ++i)
      if (name == wanted[i]) found[i] = name;
  }
  for (const std::string& one : found)
    if (!one.empty()) return one;
  return "";
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

// The encoder of the ffmpeg that PATH finds first, asked once (popen; "" if there is no ffmpeg or it has none).
inline std::string h264_encoder_here() {
  static const std::string chosen = [] {
    std::string listing;
    if (FILE* from = popen("ffmpeg -hide_banner -encoders 2> /dev/null", "r")) {
      char block[4096];
      for (size_t n; (n = std::fread(block, 1, sizeof block, from)) > 0;)
        listing.append(block, n);
      pclose(from);
    }
    return h264_encoder(listing);
  }();
  return chosen;
}

}  // namespace motolii

#endif  // MOTOLII_BASE_VIDEO_ENCODER_H_
