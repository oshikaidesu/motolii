// What the JavaScript of a script is given besides its own file: the names a
// Cavalry file expects, the easings, and the native functions that read a film,
// run waiting jobs, read a picture and read another layer's value.
#include "community/script_runner/script_natives.h"

#include <fstream>
#include <sstream>

#include "community/script_runner/script_runner.h"
#include "community/sites/adapter.h"
#include "community/subtitles/subtitles.h"
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

// What a relation written as a file is told and says: all its things at once,
// as arrays of numbers (document/evaluate/world.cpp). Every script has it, not
// only a p5.js sketch, so a file written for copies runs on layers too.
const char* rows_prelude = R"(
var __was = {};
function __relate() {   // (a file's relate(); a file written for copies, with each(i, n, t, k), runs on layers too: layer n of the row is copy n, and what each() says goes on top of where the layer is as it does on a copy, places and turns added, size and opacity multiplied: document/scripts/expressions.cpp)
  if (typeof relate === 'function') return relate;
  return (things, t, k) => things.map((a, n) => {
    const e = each(n, things.length, t, k, a) || {}, add = name => a[name] + (+e[name] || 0), times = name => a[name] * (e[name] === undefined ? 1 : +e[name]);
    return { i: a.i, x: add('x'), y: add('y'), z: add('z'), rotate: add('rotate'), rotate_x: add('rotate_x'), rotate_y: add('rotate_y'), size: times('size'), opacity: times('opacity') };
  });
}
function __copies_by_relate(n, t, k, laid) {   // (a relation's relate() on the copies of one layer: the copies laid so far are its things, as layers are a relation's; it says where each goes, and what goes back is the change, places and turns added, size and opacity multiplied, as each() says it: the way round of __relate())
  const names = ['x', 'y', 'z', 'size', 'rotate', 'rotate_x', 'rotate_y', 'opacity'], many = names.length, by = [];
  const things = [];
  for (let i = 0; i < n; ++i) { const o = { i, w: 0, h: 0, id: 0, near: 1, from: { x: NaN, y: NaN } }; names.forEach((name, j) => o[name] = laid[i * many + j]); things.push(o); }
  (relate(things, t, k) || things).forEach((o, m) => by[o && o.i !== undefined ? o.i : m] = o);
  const out = new Float64Array(many * n);
  for (let i = 0; i < n; ++i) names.forEach((name, j) => {
    const was = laid[i * many + j], is = by[i] && by[i][name], to = typeof is === 'number' && isFinite(is) ? is : was;
    out[i * many + j] = name === 'size' || name === 'opacity' ? (was ? to / was : 1) : to - was;
  });
  return out;
}
function __relates(all, t, k, rel, frame, awake) {   // (a relation written as a file: its relate() told all its things at once, document/evaluate/relations.h; what it leaves out stays as it was. Its Falloff weighs what it says, as Cavalry's does a Behaviour's Strength; one that remembers is told it as near and weighs it itself, as MASH's Python node reads getFalloff)
  const names = ['x', 'y', 'z', 'size', 'rotate', 'rotate_x', 'rotate_y', 'opacity'], many = names.length, by = [], relate = __relate(), solves = relate.length > 3, cached = __was[rel] = __was[rel] || [];
  const things = all.map((v, i) => { const o = { i, w: v[many], h: v[many + 1], id: v[many + 2], near: v[many + 3], from: { x: v[many + 4], y: v[many + 5] } }; names.forEach((n, j) => o[n] = v[j]); return o; });   // (from: x and y where it showed when it joined, NaN where that is not known)
  if (awake) ((solves ? relate(things, t, k, (frame && cached[frame - 1]) || null) : relate(things, t, k)) || things).forEach((o, n) => by[o && o.i !== undefined ? o.i : n] = o);
  if (solves) cached[frame] = awake ? by : null;
  const out = new Float64Array(many * all.length);
  all.forEach((v, i) => names.forEach((n, j) => { const is = by[i] && by[i][n], to = typeof is === 'number' && isFinite(is) ? is : v[j]; out[i * many + j] = solves ? to : v[j] + (to - v[j]) * v[many + 3]; }));
  return out;
}
function __forces(all, t, k, rel, frame, awake) {   // (a relation that pushes: its force() told its things as d3-force tells a force its nodes, each where it is and how fast; what it adds to their speed the world weighs and adds up, document/evaluate/world.h. What else it writes on a thing it finds there the next frame, as a particle's attributes, not to be changed for what is cached)
  const names = ['x', 'y', 'z', 'size', 'rotate', 'rotate_x', 'rotate_y', 'opacity', 'vx', 'vy', 'vz'], many = names.length, cached = __was[rel] = __was[rel] || [], had = frame && cached[frame - 1];
  const things = all.map((v, i) => { const o = Object.assign({}, had && had[i], { i, index: i, w: v[many], h: v[many + 1], id: v[many + 2], near: v[many + 3], home: { x: v[many + 4], y: v[many + 5], z: v[many + 6] } }); names.forEach((n, j) => o[n] = v[j]); return o; });
  if (awake) force(things, t, k);
  cached[frame] = things;
  const out = new Float64Array(many * all.length);
  all.forEach((v, i) => names.forEach((n, j) => { const is = things[i][n]; out[i * many + j] = typeof is === 'number' && isFinite(is) ? is : v[j]; }));
  return out;
}
function __asleep(rel, frame) { (__was[rel] = __was[rel] || [])[frame] = null; return new Float64Array(1); }
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
JSValue text_read(JSContext* cx, JSValueConst, int, JSValueConst* a) {
  const char* name = JS_ToCString(cx, a[0]);
  const std::filesystem::path file =
      std::filesystem::path(((FilmRead*)JS_GetContextOpaque(cx))->beside) /
      std::filesystem::path(name ? name : "").filename();
  JS_FreeCString(cx, name);
  std::error_code wrong;
  if (!std::filesystem::is_regular_file(file, wrong)) return JS_NULL;
  std::ifstream in(file, std::ios::binary);
  std::stringstream all;
  all << in.rdbuf();
  const std::string text = all.str();
  return JS_NewStringLen(cx, text.data(), text.size());
}
JSValue subtitles_frame(JSContext* cx, JSValueConst, int, JSValueConst* a, int,
                        JSValueConst* data) {
  int64_t at = 0;
  double ms = 0, scale = 1;
  JS_ToInt64(cx, &at, data[0]), JS_ToFloat64(cx, &ms, a[0]),
      JS_ToFloat64(cx, &scale, a[1]);
  const Subtitles::Frame f = ((const Subtitles*)at)->at((long long)ms, scale);
  if (f.rgba.empty()) return JS_NULL;
  JSValue o = JS_NewObject(cx);
  JS_SetPropertyStr(cx, o, "x", JS_NewInt32(cx, f.x)),
      JS_SetPropertyStr(cx, o, "y", JS_NewInt32(cx, f.y)),
      JS_SetPropertyStr(cx, o, "w", JS_NewInt32(cx, f.w)),
      JS_SetPropertyStr(cx, o, "h", JS_NewInt32(cx, f.h));
  JS_SetPropertyStr(cx, o, "data",
                    JS_NewArrayBufferCopy(cx, f.rgba.data(), f.rgba.size()));
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
