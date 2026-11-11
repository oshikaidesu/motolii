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
// __bezier(x1, y1, x2, y2, u): a cubic Bezier easing at progress u, solved by
// the same interp_bezier as a key's stretch (motion/easing_curves.h). Given to
// a script that holds an After Effects expression, so ae_expr.h's ease(),
// easeIn() and easeOut() are three sets of control points and no solver of
// their own.
JSValue bezier_ease(JSContext* cx, JSValueConst, int argc, JSValueConst* a);
// A picture its sketch came with, by the name it gives it: only the last part
// of that name, only from that folder.
JSValue image_read(JSContext* cx, JSValueConst, int, JSValueConst* a);
// __text_read(name): a file its sketch came with, as text, by the last part of
// the name it gives (as image_read reads its pictures), or null. What fetch()
// reads in p5_stand.h, and so p5.js's loadTable, loadJSON and loadStrings.
JSValue text_read(JSContext* cx, JSValueConst, int, JSValueConst* a);
// __subtitles_frame(ms, scale): the frame of the subtitles `data` points at
// (community/subtitles), drawn `scale` times as large as the file is written
// for, as {x, y, w, h, data: RGBA}, or null when nothing is shown then.
JSValue subtitles_frame(JSContext* cx, JSValueConst, int, JSValueConst* a, int,
                        JSValueConst* data);

// Gives a sketch that listens p5.sound itself: when the text `src` names
// something of p5.sound or of Web Audio that hears (loadSound, p5.FFT,
// p5.Amplitude, an AudioContext) and p5.sound's file lies where the p5
// distribution has it, addons/p5.sound.min.js beside the p5.js at `p5`, that
// file is run as it is on community/p5/web_audio_stand.h. What it hears is the
// sound of the video or sound file at `*film` (empty: silence), which must
// stay where it is for as long as `cx` lives; the file's sound is read whole
// the first time it is asked for, and waited for. To be called after p5.js
// has been run. Without the file, or for a sketch that names none of these,
// nothing is done and p5_stand.h's silent names stand. Returns what went
// wrong, or an empty string.
std::string sketch_hears(JSContext* cx, const std::string& src,
                         const std::string& p5, const std::string* film);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_SCRIPT_RUNNER_SCRIPT_NATIVES_H_
