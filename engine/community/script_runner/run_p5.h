#ifndef MOTOLII_COMMUNITY_SCRIPT_RUNNER_RUN_P5_H_
#define MOTOLII_COMMUNITY_SCRIPT_RUNNER_RUN_P5_H_

// Sets up a p5.js sketch in a QuickJS context: loads p5.js, the stand-ins,
// p5.sound, adapter libraries, d3-force, film/subtitles natives.
// Also defines the Script methods that ask a running sketch (said, answers,
// bytes, most, shape, flat, density, width, height, lines, paints, numbers).

#include <quickjs.h>

#include <filesystem>
#include <memory>
#include <string>
#include <vector>

#include "community/subtitles/subtitles.h"
#include "media/video_frames_for_scripts.h"

namespace motolii {

// Loads p5.js, the stand-ins, adapter libraries, d3-force and the natives a
// sketch needs (film, images, subtitles) into `cx`.  `src` is the adapted
// source, `code` the original file text, `form` its adapter_form, `file` the
// file path, `p5` the path to p5.min.js, `film_path` the video path (may be
// empty).  `film` and `subtitles` are filled in; `trouble` is set on error.
void setup_p5_sketch(JSContext* cx, const std::string& src,
                     const std::string& code, const std::string& form,
                     const std::string& file, const std::string& p5,
                     const std::string& film_path, FilmRead& film,
                     std::unique_ptr<Subtitles>& subtitles,
                     std::string& trouble);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_SCRIPT_RUNNER_RUN_P5_H_
