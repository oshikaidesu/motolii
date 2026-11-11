#ifndef MOTOLII_COMMUNITY_SUBTITLES_SUBTITLES_H_
#define MOTOLII_COMMUNITY_SUBTITLES_SUBTITLES_H_

// Subtitles and timed lyrics drawn as they are written. FFmpeg tells what a
// text is and writes SRT, WebVTT, LRC and the other text formats it reads as
// ASS; libass draws ASS, karaoke and override tags included (ass.h in libass).
// The adapter in community/sites wraps such a file into a sketch that puts each
// frame on its canvas.

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace motolii {

// The FFmpeg demuxer its own probe reads `text` with (ass, srt, webvtt, lrc
// and the like), or "" when FFmpeg does not read it as subtitles.
std::string subtitles_format(const std::string& text);
// `text` written as an ASS file by FFmpeg, as `ffmpeg -i in.srt out.ass` writes
// it. ASS is returned as it is, "" what FFmpeg does not read as subtitles.
std::string subtitles_as_ass(const std::string& text);

class Subtitles {
 public:
  // `text` is the whole file, in any format subtitles_format() names.
  explicit Subtitles(const std::string& text);
  ~Subtitles();
  // False if libass could not read the text.
  bool read() const;
  // The size the file is written for (PlayResX, PlayResY in [Script Info]).
  int width() const;
  int height() const;
  struct Frame {
    int x = 0, y = 0, w = 0, h = 0;
    std::vector<uint8_t> rgba;  // straight alpha, w * h * 4
  };
  // The picture at `ms`, drawn `scale` times as large as the size the file is
  // written for, only over the box libass drew in. Empty when nothing is shown
  // then.
  Frame at(long long ms, double scale = 1) const;

 private:
  struct Own;
  std::unique_ptr<Own> own;
};

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_SUBTITLES_SUBTITLES_H_
