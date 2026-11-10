#ifndef MOTOLII_DOCUMENT_MATCH_MATCH_VIDEO_H_
#define MOTOLII_DOCUMENT_MATCH_MATCH_VIDEO_H_

// How doc_match builds a video layer, with its datamosh and its sound.

#include <string>

namespace motolii {

struct Doc;

// Returns the path of the datamosh of a video layer (video_datamosh.h): the
// video rendered again with the motion of another video poured in. Returns ""
// when mosh is off, there is no other video, or the result is not rendered yet.
// The layer then plays its own video meanwhile.
std::string doc_mosh(Doc& d, int layer);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_MATCH_MATCH_VIDEO_H_
