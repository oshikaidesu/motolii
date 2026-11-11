#ifndef MOTOLII_COMMUNITY_SUBTITLES_SUBTITLES_H_
#define MOTOLII_COMMUNITY_SUBTITLES_SUBTITLES_H_

// ASS and SSA subtitles, karaoke and override tags included, drawn by libass as
// they are written (ass.h in libass). The adapter in community/sites wraps such
// a file into a sketch that puts each frame on its canvas.

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace motolii {

class Subtitles {
 public:
  // `text` is the whole .ass or .ssa file.
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
  // The picture at `ms`, only over the box libass drew in. Empty when nothing
  // is shown then.
  Frame at(long long ms) const;

 private:
  struct Own;
  std::unique_ptr<Own> own;
};

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_SUBTITLES_SUBTITLES_H_
