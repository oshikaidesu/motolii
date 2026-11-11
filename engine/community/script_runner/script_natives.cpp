// What the JavaScript of a script is given besides its own file: the names a
// Cavalry file expects, the easings, and the native functions that read a film,
// run waiting jobs, read a picture and read another layer's value.
#include "community/script_runner/script_natives.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>

#include "community/p5/web_audio_stand.h"
#include "community/script_runner/script_runner.h"
#include "community/sites/adapter.h"
#include "community/subtitles/subtitles.h"
#include "media/sound_level.h"
#include "media/video_frames_for_scripts.h"
#include "motion/easing_curves.h"
#include "motion/easing_names.h"
namespace motolii {

JSValue bezier_ease(JSContext* cx, JSValueConst, int argc, JSValueConst* a) {
  double p[5] = {0, 0, 1, 1, 0};
  for (int i = 0; i < argc && i < 5; ++i) JS_ToFloat64(cx, &p[i], a[i]);
  return JS_NewFloat64(cx, interp_bezier(p[0], p[1], p[2], p[3], p[4]));
}


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

namespace {
// The numbers of typed array `v` when it is of `kind` (quickjs.h's
// JSTypedArrayEnum), and how many; null otherwise.
void* numbers_in(JSContext* cx, JSValueConst v, int kind, size_t* count) {
  if (JS_GetTypedArrayType(v) != kind) return nullptr;
  size_t from = 0, bytes = 0, each = 0, all = 0;
  JSValue held = JS_GetTypedArrayBuffer(cx, v, &from, &bytes, &each);
  if (JS_IsException(held)) return JS_FreeValue(cx, JS_GetException(cx)), nullptr;
  uint8_t* at = JS_GetArrayBuffer(cx, &all, held);
  JS_FreeValue(cx, held);
  *count = each ? bytes / each : 0;
  return at ? at + from : nullptr;
}
const SoundRead* film_sound(JSContext* cx, JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* file = (const std::string*)at;
  return file->empty() ? nullptr : sound_of(*file, true);
}

// What web_audio_stand.h asks for of the sound a sketch is given (the address
// of its file's path in `data`): __sound_wave(array, seconds) fills a
// Float32Array with the samples up to that second, the oldest first, and
// __sound_seconds() gives how long the sound is.
JSValue film_sound_wave(JSContext* cx, JSValueConst, int argc, JSValueConst* a,
                        int, JSValueConst* data) {
  size_t n = 0;
  double seconds = 0;
  float* to = argc >= 1 ? (float*)numbers_in(cx, a[0], JS_TYPED_ARRAY_FLOAT32,
                                             &n)
                        : nullptr;
  if (argc >= 2) JS_ToFloat64(cx, &seconds, a[1]);
  if (to) sound_wave(film_sound(cx, data), seconds, to, (int)n);
  return JS_UNDEFINED;
}
JSValue film_sound_seconds(JSContext* cx, JSValueConst, int, JSValueConst*, int,
                           JSValueConst* data) {
  const SoundRead* r = film_sound(cx, data);
  return JS_NewFloat64(cx, r ? (double)r->wave.size() / sound_rate : 0.0);
}
// __analyser(wave, smooth, tau): one asking of an AnalyserNode
// (media/sound_level.h's analyser_asked): `wave` a Float32Array of fftSize
// samples, `smooth` a Float64Array of half as many.
JSValue analyser_ask(JSContext* cx, JSValueConst, int argc, JSValueConst* a) {
  size_t n = 0, half = 0;
  double tau = 0.8;
  const float* wave = argc >= 2 ? (const float*)numbers_in(
                                      cx, a[0], JS_TYPED_ARRAY_FLOAT32, &n)
                                : nullptr;
  double* smooth =
      wave ? (double*)numbers_in(cx, a[1], JS_TYPED_ARRAY_FLOAT64, &half)
           : nullptr;
  if (argc >= 3) JS_ToFloat64(cx, &tau, a[2]);
  if (smooth && n >= 32 && n <= 32768 && !(n & (n - 1)) && half == n / 2)
    analyser_asked(wave, (int)n, tau, smooth);
  return JS_UNDEFINED;
}

}  // namespace

std::string sketch_hears(JSContext* cx, const std::string& src,
                         const std::string& p5, const std::string* film) {
  bool names = false;
  for (const char* heard : {"loadSound", "p5.SoundFile", "p5.FFT",
                            "p5.Amplitude", "p5.PeakDetect", "AudioContext"})
    names = names || src.find(heard) != std::string::npos;
  std::ifstream addon(std::filesystem::path(p5).parent_path() / "addons" /
                      "p5.sound.min.js");
  if (!names || !addon) return "";
  std::stringstream text;
  text << addon.rdbuf();
  const std::string sound = text.str();
  JSValue g = JS_GetGlobalObject(cx),
          of = JS_NewInt64(cx, (int64_t)(intptr_t)film);
  JS_SetPropertyStr(cx, g, "__sound_wave",
                    JS_NewCFunctionData(cx, film_sound_wave, 2, 0, 1, &of));
  JS_SetPropertyStr(cx, g, "__sound_seconds",
                    JS_NewCFunctionData(cx, film_sound_seconds, 0, 0, 1, &of));
  JS_SetPropertyStr(cx, g, "__analyser",
                    JS_NewCFunction(cx, analyser_ask, "__analyser", 3));
  JS_FreeValue(cx, of), JS_FreeValue(cx, g);
  std::string wrong;
  const auto run = [&](const char* text, size_t size, const char* name) {
    JSValue ran = JS_Eval(cx, text, size, name, JS_EVAL_TYPE_GLOBAL);
    if (JS_IsException(ran) && wrong.empty()) {
      JSValue e = JS_GetException(cx);
      const char* said = JS_ToCString(cx, e);
      wrong = std::string(name) + " did not start: " + (said ? said : "?");
      if (said) JS_FreeCString(cx, said);
      JS_FreeValue(cx, e);
    }
    JS_FreeValue(cx, ran);
  };
  run(web_audio_stand, std::char_traits<char>::length(web_audio_stand),
      "web_audio_stand");
  run(sound.c_str(), sound.size(), "p5.sound.min.js");
  return wrong;
}

}  // namespace motolii
