#ifndef MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_NATIVES_H_
#define MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_NATIVES_H_

// What script_runner.cpp gives the JavaScript of a script besides its file
// (defined in script_natives.cpp).
#include <quickjs.h>

#include <string>

namespace motolii {

// What a Cavalry distribution asks of Cavalry's JavaScript (the four names its
// 26 files use), so one runs as it is.
extern const char* cavalry_prelude;
// __relates() and __forces(): what a relation written as a file is told and
// says, all its things at once. A file with each() and no relate() runs on the
// layers as on copies.
extern const char* rows_prelude;

// ease(name, u): a way by its name (easing_names.h), the same expression as a
// key's stretch; not one of them: as it is.
std::string ways_prelude();

// The film's next picture, 1/60 s on: its size and its bytes.
JSValue film_next(JSContext* cx, JSValueConst, int, JSValueConst*);
// What a promise was waiting on came: it goes on.
JSValue jobs_run(JSContext* cx, JSValueConst, int, JSValueConst*);
// A picture its sketch came with, by the name it gives it: only the last part
// of that name, only from that folder.
JSValue image_read(JSContext* cx, JSValueConst, int, JSValueConst* a);
// layerValue(id, name, t, otherwise, copy): what the owner of the Script
// answers for another layer's value at time t (Script::reads), of its copy
// `copy` when given; `data` holds the address of that reader. NaN when no
// reader is set.
// __text_read(name): a file its sketch came with, as text, by the last part of
// the name it gives (as image_read reads its pictures), or null. What fetch()
// reads in p5_stand.h, and so p5.js's loadTable, loadJSON and loadStrings.
JSValue text_read(JSContext* cx, JSValueConst, int, JSValueConst* a);
// __subtitles_frame(ms, scale): the frame of the subtitles `data` points at
// (community/subtitles), drawn `scale` times as large as the file is written
// for, as {x, y, w, h, data: RGBA}, or null when nothing is shown then.
JSValue subtitles_frame(JSContext* cx, JSValueConst, int, JSValueConst* a, int,
                        JSValueConst* data);
JSValue layer_value(JSContext* cx, JSValueConst, int argc, JSValueConst* a, int,
                    JSValueConst* data);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_NATIVES_H_
