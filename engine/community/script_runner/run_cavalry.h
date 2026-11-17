#ifndef MOTOLII_COMMUNITY_SCRIPT_RUNNER_RUN_CAVALRY_H_
#define MOTOLII_COMMUNITY_SCRIPT_RUNNER_RUN_CAVALRY_H_

// Cavalry-dialect helpers: wrapping a bare object literal as each(), and
// running a whole file that gives a PointCloud of copies at once.

#include <quickjs.h>

#include <cstdint>
#include <map>
#include <string>
#include <vector>

#include "community/quickjs/script.h"

namespace motolii {

// When `src` has no each() and its first meaningful token is '{', wraps it as
//   function each(index, count, time, value) { return (...); }
// so that a Cavalry expression pasted as-is runs.  Returns the wrapped body on
// success, or the original `src` when it does not apply or the wrapped version
// does not parse.  `cx` is used only for a trial parse (nothing is evaluated).
std::string wrap_cavalry_expression(JSContext* cx, const std::string& src,
                                    const std::string& file);

// Runs `src` as a whole file (the Cavalry PointCloud path), where the file
// puts its parameters as globals (n0, n1, ..., plus time and frame) and
// answers with { points: [{x,y},...], sizes: [{x,y},...] }.  `unit` converts
// pixels to stage units.  Fills `all` and sets `trouble` on error.
void run_cavalry_whole(JSContext* cx, JSRuntime* rt, const std::string& src,
                       const std::string& file,
                       const std::map<std::string, double>& numbers,
                       const std::map<std::string, std::string>& words,
                       int n, double t, double unit,
                       std::vector<ScriptCopy>& all, std::string& trouble);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_SCRIPT_RUNNER_RUN_CAVALRY_H_
