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

#include "base/file_read.h"
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


// cavalry_prelude.js and rows_prelude.js sit beside this file and are read by
// script_runner.cpp when a QuickJS context is opened. The engine ships no
// Cavalry- or row-related JavaScript as C++ string literals: the source is
// those .js files. See the comments inside each for what they stand in for.

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
  const std::string text = read_text(file);
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
  const std::filesystem::path p5Dir = std::filesystem::path(p5).parent_path();
  const std::string sound = read_text(p5Dir / "addons" / "p5.sound.min.js");
  const std::string webAudio = read_text(p5Dir / "stand" / "web_audio_stand.js");
  if (!names || sound.empty() || webAudio.empty()) return "";
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
  run(webAudio.c_str(), webAudio.size(), "web_audio_stand");
  run(sound.c_str(), sound.size(), "p5.sound.min.js");
  return wrong;
}

}  // namespace motolii
