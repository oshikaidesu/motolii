// What the JavaScript of a script is given besides its own file: the names a
// Cavalry file expects, the easings, and the native functions that read a film,
// run waiting jobs, read a picture and read another layer's value.
#include "community/script_runner/script_natives.h"

#include "community/script_runner/script_runner.h"
#include "community/sites/adapter.h"
#include "media/video_frames_for_scripts.h"
#include "motion/easing_names.h"
namespace motolii {

// What a Canvalry distribution asks of Cavalry's JavaScript (the four names its
// 26 files use), so one runs as it is.
const char* cavalry_prelude = R"(
var cavalry = {
  Point: function (x, y) { this.x = x; this.y = y; },
  PointCloud: function () { this.points = []; this.sizes = []; },
  random: function (low, high, seed, sequence) {
    var h = Math.imul((seed | 0) ^ 0x9E3779B9, 0x85EBCA6B) ^ Math.imul((sequence | 0) + 1, 0xC2B2AE35);
    h ^= h >>> 16; h = Math.imul(h, 0x7FEB352D); h ^= h >>> 15; h = Math.imul(h, 0x846CA68B); h ^= h >>> 16;
    return low + (high - low) * ((h >>> 0) / 4294967296);
  }
};
cavalry.PointCloud.prototype.appendPoint = function (p) { this.points.push(p); };
cavalry.PointCloud.prototype.appendSize = function (s) { this.sizes.push(s); };
// Cavalry's Animators, all of one shape: a value of each copy (a letter of a split text) from one number to another
// over a length of seconds, a way (ease), each copy later than the one before (or in a random order) by up to a delay;
// an In from when the thing begins, an Out to end just before it does. what: x, y, rotate_x, opacity, or print (the
// copies seen one after another, no way).
function animate(i, n, t, k, a) {
  var length = k.length || 40 / 60, delay = k.delay === undefined ? 20 / 60 : k.delay;
  var order = a.random ? cavalry.random(0, 1, a.seed || 50, i) : n > 1 ? i / (n - 1) : 0;
  var from = a.out ? Math.max(0, (k.duration > 0 ? k.duration : 4) - 1 / 60 - delay - length) : 0;
  if (a.what === 'print') {
    var seen = Math.min(1, Math.max(0, (t - from) / length)) * n;
    return { opacity: a.out ? (i < seen ? 0 : 1) : (i < seen ? 1 : 0) };
  }
  var u = Math.min(1, Math.max(0, (t - from - delay * order) / length));
  var out = {};
  out[a.what] = a.from + (a.to - a.from) * ease(a.way, u);
  return out;
}
)";

// ease(name, u): a way by its name (easing_names.h), the same expression as a
// key's stretch; not one of them: as it is.
std::string ways_prelude() {
  std::string js =
      "var ease = (function () { var pow = Math.pow, exp = Math.exp, cos = "
      "Math.cos, abs = Math.abs, pi = function () { return Math.PI; }; var w = "
      "{";
  for (const auto& one : named_ways)
    js +=
        std::string(one.name) + ": function (u) { return " + one.goes + "; }, ";
  return js +
         "}; return function (name, u) { u = Math.min(1, Math.max(0, u)); "
         "return w[name] ? w[name](u) : u; }; })();\n";
}

JSValue film_next(JSContext* cx, JSValueConst, int,
                  JSValueConst*) {  // (the film's next picture, 1/60 s
                                    // on: its size and its bytes)
  FilmRead* f = (FilmRead*)JS_GetContextOpaque(cx);
  if (!f->reader || !f->next()) return JS_NULL;
  JSValue o = JS_NewObject(cx);
  JS_SetPropertyStr(cx, o, "w", JS_NewInt32(cx, f->w)),
      JS_SetPropertyStr(cx, o, "h", JS_NewInt32(cx, f->h));
  JS_SetPropertyStr(cx, o, "data",
                    JS_NewArrayBufferCopy(cx, f->last.data(), f->last.size()));
  return o;
}
JSValue jobs_run(
    JSContext* cx, JSValueConst, int,
    JSValueConst*) {  // (what a promise was waiting on came: it goes on)
  for (JSContext* job = nullptr;
       JS_ExecutePendingJob(JS_GetRuntime(cx), &job) > 0;) {
  }
  return JS_UNDEFINED;
}
JSValue image_read(
    JSContext* cx, JSValueConst, int,
    JSValueConst*
        a) {  // (a picture its sketch came with, by the name it gives it: only
              // the last part of that name, only from that folder)
  const char* name = JS_ToCString(cx, a[0]);
  const std::filesystem::path file =
      std::filesystem::path(((FilmRead*)JS_GetContextOpaque(cx))->beside) /
      std::filesystem::path(name ? name : "").filename();
  JS_FreeCString(cx, name);
  std::error_code wrong;
  FilmRead f;
  if (!std::filesystem::is_regular_file(file, wrong) ||
      !f.open(file.string(), 0))
    return JS_NULL;
  JSValue o = JS_NewObject(cx);
  JS_SetPropertyStr(cx, o, "w", JS_NewInt32(cx, f.w)),
      JS_SetPropertyStr(cx, o, "h", JS_NewInt32(cx, f.h));
  JS_SetPropertyStr(cx, o, "data",
                    JS_NewArrayBufferCopy(cx, f.last.data(), f.last.size()));
  return o;
}
// layerValue(id, name, t, otherwise): what the owner of the Script answers for
// another layer's value at time t (Script::reads); `data` holds the address of
// that reader. NaN when no reader is set.
JSValue layer_value(JSContext* cx, JSValueConst, int argc, JSValueConst* a, int,
                    JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* reads = (const Script::LayerReader*)at;
  double layer = 0, t = 0, otherwise = 0;
  const char* name = argc >= 3 ? JS_ToCString(cx, a[1]) : nullptr;
  if (argc >= 3) JS_ToFloat64(cx, &layer, a[0]), JS_ToFloat64(cx, &t, a[2]);
  if (argc >= 4) JS_ToFloat64(cx, &otherwise, a[3]);
  const double v =
      name && *reads ? (*reads)((int)layer, name, t, otherwise) : std::nan("");
  if (name) JS_FreeCString(cx, name);
  return JS_NewFloat64(cx, v);
}

}  // namespace motolii
