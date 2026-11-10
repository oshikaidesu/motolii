#ifndef MOTOLII_MEDIA_VIDEO_FLASH_CHECK_H_
#define MOTOLII_MEDIA_VIDEO_FLASH_CHECK_H_
// The check of a video for flashes and patterns that may cause seizures, done
// by EA's IRIS. video_flash_check.cpp is compiled as C++17 with IRIS's headers
// (see CMakeLists.txt), so this header uses nothing newer than that.

namespace motolii {

// Analyses `film` and writes the results into `folder`. Returns the path of the
// result JSON, or an empty string if the inputs are not regular files, the
// settings are missing, or the analysis fails. The returned pointer stays valid
// until the next call on the same thread. Any thread may call; the videos are
// analysed one at a time.
const char* video_flash_check(const char* film, const char* folder);

}  // namespace motolii

#endif  // MOTOLII_MEDIA_VIDEO_FLASH_CHECK_H_
