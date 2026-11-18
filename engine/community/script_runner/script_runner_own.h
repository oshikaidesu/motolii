#ifndef MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_RUNNER_OWN_H_
#define MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_RUNNER_OWN_H_

// The private state of Script, shared among the .cpp files that define its
// methods (script_runner.cpp, run_p5.cpp).  Not part of the public interface.
#include <memory>
#include <string>
#include <vector>

#include "community/quickjs/script.h"
#include "community/script_runner/project_reads.h"
#include "community/script_runner/script_runner.h"
#include "community/subtitles/subtitles.h"
#include "media/video_frames_for_scripts.h"

namespace motolii {

struct Script::Own {
  ProjectReads project;  // what answers layerValue() and the like
  bool asks = false;     // its text names one of them: it asks the project,
                         // which the thread that calls it holds
  JSRuntime* rt = nullptr;
  JSContext* cx = nullptr;
  JSValue each = JS_UNDEFINED, parameters = JS_UNDEFINED, at = JS_UNDEFINED;
  JSValue text = JS_UNDEFINED;  // its sourceText(), when it has one
  std::string trouble, file, src;
  bool whole = false;   // no each(): the whole file says every copy at once, as
                        // a Cavalry distribution (a PointCloud)
  bool sketch = false;  // a p5.js sketch (p5_stand.h)
  std::string made_p5, made_film;  // what it was made with, for its helpers
  // Scripts of the same file, one QuickJS runtime each, that lay a share of
  // many copies on threads of their own (copies()).
  std::vector<std::unique_ptr<Script>> helpers;
  bool relates = false;  // a relation's relate() and no draw(): it lays copies
                         // too, all at once (__copies_by_relate)
  std::string wgsl;      // WGSL vertex shader built by tsl_each(); empty when
                     // the GPU path could not be built (CPU is the fallback)
  FilmRead film;  // what its createCapture and createVideo see
  std::unique_ptr<Subtitles> subtitles;  // an .ass file's, drawn by libass
  std::vector<SketchLine> lines;         // its lines that draw
  JSAtom said[17] = {};  // the names each() says a copy by, made atoms once
                         // (JS_GetPropertyStr makes and frees one at every
                         // read: quickjs-ng quickjs.c)
};

// The names each() says a copy by, in order.
extern const char* const script_copy_names[17];

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_RUNNER_OWN_H_
