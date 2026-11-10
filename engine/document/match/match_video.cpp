#include "document/match/match_video.h"

#include <string>

#include "document/cards.h"
#include "document/document.h"
#include "document/evaluate/value_at.h"
#include "media/video_datamosh.h"

namespace motolii {

std::string doc_mosh(Doc& d, int layer) {
  if (!doc_on(d, layer, "mosh") || doc_word(d, layer, "kind") != "video")
    return "";
  const int with = (int)doc_number(d, layer, "mosh_with", 0, 0);
  const std::string file = doc_word(d, layer, "file"),
                    other = with > 0 && with != layer
                                ? doc_word(d, with, "file")
                                : "";
  if (other.empty() || doc_word(d, with, "kind") != "video") return "";
  return mosh_file(file, doc_number(d, layer, "mosh_at", 0, 1), other);
}

}  // namespace motolii
