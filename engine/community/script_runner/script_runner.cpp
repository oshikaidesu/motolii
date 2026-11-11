// script_runner.h's Script: QuickJS-ng behind each(), with what each dialect
// needs evaluated before the file (Cavalry's names, the easings, leva's
// folder(), After Effects expressions, p5.js and the libraries a sketch names).
#include "community/script_runner/script_runner.h"

#include <algorithm>
#include <fstream>
#include <memory>
#include <sstream>
#include <thread>

#include "community/after_effects/ae_expr.h"
#include "community/p5/p5_mesh.h"
#include "community/p5/p5_stand.h"
#include "community/p5/p5_three.h"
#include "community/quickjs/script_leva.h"
#include "community/script_runner/script_natives.h"
#include "community/sites/adapter.h"
#include "community/subtitles/subtitles.h"
#include "media/video_frames_for_scripts.h"

namespace motolii {

struct Script::Own {
  Script::LayerReader reads;  // what layerValue() asks
  JSRuntime* rt = nullptr;
  JSContext* cx = nullptr;
  JSValue each = JS_UNDEFINED, parameters = JS_UNDEFINED, at = JS_UNDEFINED;
  std::string trouble, file, src;
  bool whole = false;   // no each(): the whole file says every copy at once, as
                        // a Canvalry distribution (a PointCloud)
  bool sketch = false;  // a p5.js sketch (p5_stand.h)
  std::string made_p5, made_film;  // what it was made with, for its helpers
  // Scripts of the same file, one QuickJS runtime each, that lay a share of
  // many copies on threads of their own (copies()).
  std::vector<std::unique_ptr<Script>> helpers;
  bool relates = false;  // a relation's relate() and no draw(): it lays copies
                         // too, all at once (__copies_by_relate)
  FilmRead film;         // what its createCapture and createVideo see
  std::unique_ptr<Subtitles> subtitles;  // an .ass file's, drawn by libass
  std::vector<SketchLine> lines;         // its lines that draw
  JSAtom said[12] = {};  // the names each() says a copy by, made atoms once
                         // (JS_GetPropertyStr makes and frees one at every
                         // read: quickjs-ng quickjs.c)
};
static const char* const script_copy_names[12] = {
    "x",        "y",      "z",       "size",    "rotate",  "rotate_x",
    "rotate_y", "colour", "opacity", "scale_x", "scale_y", "scale_z"};

Script::Script(const std::string& file, const std::string& p5,
               const std::string& film)
    : own(new Own) {
  std::ifstream in(file);
  std::stringstream code;
  code << in.rdbuf();
  const std::string
      form = adapter_form(code.str()),
      src = adapter_js(
          code.str(),
          form);  // (a form from the net told as a sketch: adapter.h)
  own->rt = JS_NewRuntime();
  JS_SetMemoryLimit(own->rt,
                    2ull << 30);  // (a sketch keeps its frames: 100,000
                                  // rectangles a frame are 1.5 GB a second. It
                                  // stops with an error, not with the machine)
  own->cx = JS_NewContext(own->rt);
  own->file = file, own->src = src, own->made_p5 = p5, own->made_film = film;
  const std::string ways = ways_prelude();
  JS_FreeValue(own->cx, JS_Eval(own->cx, ways.c_str(), ways.size(), "ways",
                                JS_EVAL_TYPE_GLOBAL));
  JS_FreeValue(own->cx, JS_Eval(own->cx, cavalry_prelude,
                                std::char_traits<char>::length(cavalry_prelude),
                                "cavalry", JS_EVAL_TYPE_GLOBAL));
  JS_FreeValue(own->cx, JS_Eval(own->cx, rows_prelude, strlen(rows_prelude),
                                "rows", JS_EVAL_TYPE_GLOBAL));
  JS_FreeValue(
      own->cx,
      JS_Eval(own->cx, leva_prelude, strlen(leva_prelude), "leva",
              JS_EVAL_TYPE_GLOBAL));  // (folder(), as its parameters object
                                      // says its folds: script_leva.h)
  if (src.find("AE.compile") !=
      std::string::npos) {  // (an After Effects expression the recipe holds:
                            // read once with acorn, third_party/js/acorn, then
                            // only called: ae_expr.h)
    const std::filesystem::path where =
        std::filesystem::path(p5).parent_path().parent_path() / "acorn" /
        "acorn.js";
    std::ifstream lib(where);
    std::stringstream text;
    text << lib.rdbuf();
    const std::string acorn = text.str();
    if (!lib || acorn.empty())
      own->trouble = "acorn is not where it is stored: " + where.string();
    else {
      JS_FreeValue(own->cx, JS_Eval(own->cx, acorn.c_str(), acorn.size(),
                                    "acorn.js", JS_EVAL_TYPE_GLOBAL));
      JS_FreeValue(own->cx, JS_Eval(own->cx, ae_prelude,
                                    std::char_traits<char>::length(ae_prelude),
                                    "ae_expr", JS_EVAL_TYPE_GLOBAL));
    }
  }
  const bool sketch = own->sketch = !p5.empty() && script_is_sketch(src);
  if (sketch) {
    std::ifstream lib(p5);
    std::stringstream all;
    all << lib.rdbuf();
    const std::string p5js = all.str();
    JS_FreeValue(own->cx, JS_Eval(own->cx, p5_before,
                                  std::char_traits<char>::length(p5_before),
                                  "p5_before", JS_EVAL_TYPE_GLOBAL));
    JS_FreeValue(own->cx, JS_Eval(own->cx, p5js.c_str(), p5js.size(),
                                  "p5.min.js", JS_EVAL_TYPE_GLOBAL));
    for (const char* stand : {p5_after, p5_three, p5_mesh})
      JS_FreeValue(own->cx, JS_Eval(own->cx, stand,
                                    std::char_traits<char>::length(stand),
                                    "p5_after", JS_EVAL_TYPE_GLOBAL));
    if (const std::string needs = adapter_library(form); !needs.empty()) {
      std::ifstream one(std::filesystem::path(p5).parent_path().parent_path() /
                        needs);
      std::stringstream text;
      text << one.rdbuf();
      const std::string lib = adapter_library_text(form, text.str());
      JS_FreeValue(own->cx, JS_Eval(own->cx, lib.c_str(), lib.size(),
                                    needs.c_str(), JS_EVAL_TYPE_GLOBAL));
    }
    if (script_pushes(src) && src.find("d3.") != std::string::npos)
      for (const char* lib :
           {"d3-binarytree", "d3-quadtree", "d3-octree",
            "d3-force-3d"}) {  // (a relation that pushes with d3's forces,
                               // third_party/js; the other two it says it needs
                               // only run forceSimulation, which the world does
                               // for it: document/evaluate/world.h)
        std::ifstream one(
            std::filesystem::path(p5).parent_path().parent_path() / lib /
            (std::string(lib) + ".min.js"));
        std::stringstream text;
        text << one.rdbuf();
        const std::string read = text.str();
        JS_FreeValue(own->cx, JS_Eval(own->cx, read.c_str(), read.size(), lib,
                                      JS_EVAL_TYPE_GLOBAL));
      }
    for (const std::string& needs : adapter_needs(
             code.str())) {  // (a library from the net: fetched by the adapter,
                             // it stands beside the sketch)
      std::ifstream one(std::filesystem::path(file).parent_path() /
                        std::filesystem::path(file).stem() / needs);
      std::stringstream text;
      text << one.rdbuf();
      const std::string lib = text.str();
      JS_FreeValue(own->cx, JS_Eval(own->cx, lib.c_str(), lib.size(),
                                    needs.c_str(), JS_EVAL_TYPE_GLOBAL));
    }
    if (!film.empty() && (src.find("createCapture") != std::string::npos ||
                          src.find("createVideo") != std::string::npos ||
                          src.find("loadImage") != std::string::npos))
      own->film.open(
          film, 320);  // (as much of it as a webcam sketch reads, and light)
    JS_SetContextOpaque(own->cx, &own->film);
    own->film.beside = (std::filesystem::path(file).parent_path() /
                        std::filesystem::path(file).stem())
                           .string();
    JSValue g = JS_GetGlobalObject(own->cx);
    JS_SetPropertyStr(own->cx, g, "__film_next",
                      JS_NewCFunction(own->cx, film_next, "__film_next", 0));
    JS_SetPropertyStr(own->cx, g, "__image_read",
                      JS_NewCFunction(own->cx, image_read, "__image_read", 1));
    JS_SetPropertyStr(own->cx, g, "__jobs",
                      JS_NewCFunction(own->cx, jobs_run, "__jobs", 0));
    JSValue reader = JS_NewInt64(own->cx, (int64_t)(intptr_t)&own->reads);
    JS_SetPropertyStr(
        own->cx, g, "layerValue",
        JS_NewCFunctionData(own->cx, layer_value, 3, 0, 1, &reader));
    JS_FreeValue(own->cx, reader);
    if (form == "subtitles") {
      own->subtitles = std::make_unique<Subtitles>(code.str());
      JSValue size = JS_NewArray(own->cx),
              them =
                  JS_NewInt64(own->cx, (int64_t)(intptr_t)own->subtitles.get());
      JS_SetPropertyUint32(own->cx, size, 0,
                           JS_NewInt32(own->cx, own->subtitles->width()));
      JS_SetPropertyUint32(own->cx, size, 1,
                           JS_NewInt32(own->cx, own->subtitles->height()));
      JS_SetPropertyStr(own->cx, g, "__subtitles_size", size);
      JS_SetPropertyStr(
          own->cx, g, "__subtitles_frame",
          JS_NewCFunctionData(own->cx, subtitles_frame, 1, 0, 1, &them));
      JS_FreeValue(own->cx, them);
    }
    JS_FreeValue(own->cx, g);
  }
  std::string body = src;
  if (sketch) {
    std::string marked = sketch_marked(src, &own->lines);
    JSValue told = JS_Eval(own->cx, marked.c_str(), marked.size(), file.c_str(),
                           JS_EVAL_TYPE_GLOBAL | JS_EVAL_FLAG_COMPILE_ONLY);
    if (JS_IsException(told))
      JS_FreeValue(own->cx, JS_GetException(own->cx)),
          own->lines.clear();  // (a file this reader misread runs as it is, its
                               // lines not told)
    else
      body = std::move(marked);
    JS_FreeValue(own->cx, told);
  }
  const std::string run = sketch ? body + "\n;\n" + p5_start : src;
  JSValue ran = JS_Eval(own->cx, run.c_str(), run.size(), file.c_str(),
                        JS_EVAL_TYPE_GLOBAL);
  if (sketch)
    for (JSContext* job = nullptr; JS_ExecutePendingJob(own->rt, &job) > 0;) {
    }  // (an async setup(), as p5 2 sketches are, goes on to its end)
  if (JS_IsException(ran)) {
    JSValue e = JS_GetException(own->cx);
    JSValue stack = JS_GetPropertyStr(own->cx, e, "stack");
    const char* s = JS_ToCString(own->cx, e);
    const char* where =
        JS_IsString(stack) ? JS_ToCString(own->cx, stack) : nullptr;
    own->trouble = std::string("the script ") + file + ": " + (s ? s : "?") +
                   (where ? std::string(" ") + where : "");
    JS_FreeCString(own->cx, s), JS_FreeValue(own->cx, e);
    if (where) JS_FreeCString(own->cx, where);
    JS_FreeValue(own->cx, stack);
  }
  JS_FreeValue(own->cx, ran);
  JSValue g = JS_GetGlobalObject(own->cx);
  own->each = JS_GetPropertyStr(own->cx, g, "each");
  JS_FreeValue(own->cx, g);
  own->whole = !JS_IsFunction(own->cx, own->each);
  own->relates = src.find("function relate") != std::string::npos &&
                 src.find("function draw") == std::string::npos;
  own->parameters = JS_NewObject(own->cx), own->at = JS_NewObject(own->cx);
}
Script::~Script() {
  if (!own->cx) return;
  JS_FreeValue(own->cx, own->each), JS_FreeValue(own->cx, own->parameters),
      JS_FreeValue(own->cx, own->at);
  for (JSAtom a : own->said)
    if (a != JS_ATOM_NULL) JS_FreeAtom(own->cx, a);
  JS_FreeContext(own->cx), JS_FreeRuntime(own->rt);
}
bool Script::ok() const { return own->trouble.empty(); }
void Script::reads(LayerReader read) { own->reads = std::move(read); }
bool Script::sketch() const { return own->sketch; }
bool Script::lays() const {
  return own->cx && (own->relates || (!own->whole && !own->sketch));
}
static std::string script_said(JSContext* cx, const char* js) {
  JS_UpdateStackTop(JS_GetRuntime(
      cx));  // (asked on whichever thread asks, as numbers() below: quickjs.h,
             // "should be called when changing thread")
  JSValue out = JS_Eval(cx, js, strlen(js), "sketch", JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(out)) {  // (its draw() has failed where it is asked: said
                              // here, and it goes on as far as it got)
    JSValue e = JS_GetException(cx), stack = JS_GetPropertyStr(cx, e, "stack");
    const char *m = JS_ToCString(cx, e),
               *where = JS_IsString(stack) ? JS_ToCString(cx, stack) : nullptr;
    std::fprintf(stderr, "the sketch, asked %.40s: %s\n%s\n", js, m ? m : "?",
                 where ? where : "");
    if (where) JS_FreeCString(cx, where);
    JS_FreeCString(cx, m), JS_FreeValue(cx, stack), JS_FreeValue(cx, e);
  }
  const char* s = JS_IsException(out) ? nullptr : JS_ToCString(cx, out);
  const std::string said = s ? s : "";
  if (s) JS_FreeCString(cx, s);
  JS_FreeValue(cx, out);
  return said;
}
std::string Script::said(const std::string& js) {
  return own->sketch && ok() ? script_said(own->cx, js.c_str()) : "";
}
std::vector<uint8_t> Script::bytes(const std::string& js) {
  std::vector<uint8_t> out;
  if (!own->sketch || !ok()) return out;
  script_said(own->cx, js.c_str());
  JSValue g = JS_GetGlobalObject(own->cx),
          a = JS_GetPropertyStr(own->cx, g, "__bytes");
  size_t from = 0, bytes = 0, each = 0, size = 0;
  JSValue buffer = JS_GetTypedArrayBuffer(own->cx, a, &from, &bytes, &each);
  if (const uint8_t* p = JS_IsException(buffer)
                             ? nullptr
                             : JS_GetArrayBuffer(own->cx, &size, buffer))
    out.assign(p + from, p + from + bytes);
  JS_FreeValue(own->cx, buffer), JS_FreeValue(own->cx, a),
      JS_FreeValue(own->cx, g);
  return out;
}
int Script::most() {
  return own->sketch && ok()
             ? std::atoi(script_said(own->cx, "__most()").c_str())
             : 0;
}
std::string Script::shape() {
  return own->sketch && ok() ? script_said(own->cx, "__shape()") : "";
}
bool Script::flat() {
  return own->sketch && ok() && script_said(own->cx, "__2d") == "true";
}
float Script::density() {
  return own->sketch && ok()
             ? (float)std::atof(script_said(own->cx, "pixelDensity()").c_str())
             : 1.f;
}
int Script::width() {
  return own->sketch && ok() ? std::atoi(script_said(own->cx, "width").c_str())
                             : 0;
}
int Script::height() {
  return own->sketch && ok() ? std::atoi(script_said(own->cx, "height").c_str())
                             : 0;
}
std::vector<int> Script::lines() const {
  std::vector<int> all;
  for (const SketchLine& l : own->lines) all.push_back(l.line);
  return all;
}
std::vector<double> Script::paints(int frame, int had, int pic) {
  return numbers("__paints(" + std::to_string(frame) + "," +
                 std::to_string(had) + "," + std::to_string(pic) + ")");
}
std::vector<double> Script::numbers(const std::string& js) {
  JS_UpdateStackTop(
      own->rt);  // (asked on whichever thread asks: a question's isolate may
                 // work out a relation the hand's has not, as anime_ease below)
  JSValue out =
      JS_Eval(own->cx, js.c_str(), js.size(), "sketch", JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(out) &&
      own->trouble.empty()) {  // (its draw() has failed: it stays as it was,
                               // and says so once)
    JSValue e = JS_GetException(own->cx);
    const char* s = JS_ToCString(own->cx, e);
    own->trouble =
        std::string("the sketch ") + own->file + ": " + (s ? s : "?");
    std::fprintf(stderr, "%s\n", own->trouble.c_str());
    JS_FreeCString(own->cx, s), JS_FreeValue(own->cx, e);
  }
  size_t at = 0, bytes = 0, unit = 0, size = 0;
  JSValue buffer = JS_IsException(out) ? JS_EXCEPTION
                                       : JS_GetTypedArrayBuffer(
                                             own->cx, out, &at, &bytes, &unit);
  std::vector<double> all;
  if (const uint8_t* data = JS_IsException(buffer)
                                ? nullptr
                                : JS_GetArrayBuffer(own->cx, &size, buffer)) {
    const double* from = (const double*)(data + at);
    all.assign(from, from + bytes / sizeof(double));
  }
  JS_FreeValue(own->cx, buffer), JS_FreeValue(own->cx, out);
  return all;
}
const std::string& Script::trouble() const { return own->trouble; }

std::vector<ScriptCopy> Script::copies(
    int n, double t, const std::map<std::string, double>& numbers,
    const std::map<std::string, std::string>& words, double unit,
    const std::vector<ScriptCopy>& before) {
  std::vector<ScriptCopy> all((size_t)std::max(n, 0));
  if (!ok()) return all;
  if (own->relates) {  // (a relation's relate(): the copies laid so far are
                       // its things, told at once; what it says of each goes
                       // on top of that copy, as each() does)
    parameters(numbers, words);
    JSValue g = JS_GetGlobalObject(own->cx);
    JS_SetPropertyStr(own->cx, g, "__k", JS_DupValue(own->cx, own->parameters));
    JS_FreeValue(own->cx, g);
    std::ostringstream js;
    js.precision(17);
    js << "__copies_by_relate(" << n << ',' << t << ",__k,[";
    for (int i = 0; i < n; ++i) {
      const ScriptCopy c =
          (size_t)i < before.size() ? before[(size_t)i] : ScriptCopy{};
      js << c.x << ',' << c.y << ',' << c.z << ',' << c.size << ',' << c.rotate
         << ',' << c.rotate_x << ',' << c.rotate_y << ',' << c.opacity << ',';
    }
    js << "])";
    const std::vector<double> said = this->numbers(js.str());
    if (said.size() != (size_t)n * 8) return all;
    for (size_t i = 0; i < (size_t)n; ++i) {
      ScriptCopy& c = all[i];
      const double* v = &said[i * 8];
      c.x = v[0], c.y = v[1], c.z = v[2], c.size = v[3], c.rotate = v[4],
      c.rotate_x = v[5], c.rotate_y = v[6], c.opacity = v[7];
    }
    return all;
  }
  if (!own->whole) {  // (the parameters told once, then each copy asked)
    const auto tell = [&](Script& s) {
      s.parameters(numbers, words);
      JS_SetPropertyStr(
          s.own->cx, s.own->parameters, "px",
          JS_NewFloat64(s.own->cx,
                        unit));  // (k.px: a pixel of the document in the
                                 // stage's units, so an expression written in
                                 // After Effects' pixels says where)
    };
    const auto lay = [&](Script& s, int from, int to) {
      for (int i = from; i < to; ++i)
        all[(size_t)i] =
            s.ask(i, n, t,
                  (size_t)i < before.size() ? before[(size_t)i] : ScriptCopy{});
    };
    tell(*this);
    // Many copies are shared among threads, each asking a Script of its own:
    // one QuickJS runtime runs on one thread at a time. 1,000 copies take
    // 0.6 ms on one thread (Apple M4, docs/design/next_expressions.md), so a
    // thread gets at least that many. A sketch's each() reads the frames its
    // draw() made in order, and a script that reads other layers asks the
    // document, held by this thread: both stay on this thread.
    constexpr int kCopiesAThread = 1000;
    int parts =
        own->sketch || own->reads
            ? 1
            : std::min<int>(
                  (int)std::max(1u, std::thread::hardware_concurrency()),
                  n / kCopiesAThread);
    while (parts > 1 && (int)own->helpers.size() < parts - 1)
      own->helpers.push_back(
          std::make_unique<Script>(own->file, own->made_p5, own->made_film));
    for (int p = 1; p < parts; ++p)
      if (!own->helpers[(size_t)p - 1]->ok()) parts = 1;
    std::vector<std::thread> threads;
    for (int p = 1; p < parts; ++p)
      threads.emplace_back([&, p] {
        Script& h = *own->helpers[(size_t)p - 1];
        tell(h);
        lay(h, n * p / parts, n * (p + 1) / parts);
      });
    lay(*this, 0, parts > 1 ? n / parts : n);
    for (std::thread& one : threads) one.join();
    for (int p = 1; p < parts; ++p)
      if (const std::string& why = own->helpers[(size_t)p - 1]->trouble();
          !why.empty())
        own->trouble = why;
    return all;
  }
  JSContext* cx = own->cx;
  JS_UpdateStackTop(own->rt);
  JSValue g = JS_GetGlobalObject(cx);
  for (const auto& [name, v] : numbers)
    JS_SetPropertyStr(cx, g, name.c_str(), JS_NewFloat64(cx, v));
  for (const auto& [name, w] : words)
    JS_SetPropertyStr(cx, g, name.c_str(), JS_NewString(cx, w.c_str()));
  JS_SetPropertyStr(cx, g, "time", JS_NewFloat64(cx, t)),
      JS_SetPropertyStr(cx, g, "frame", JS_NewFloat64(cx, t * 60.0));
  JS_FreeValue(cx, g);
  JSValue out = JS_Eval(cx, own->src.c_str(), own->src.size(),
                        own->file.c_str(), JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(out)) {
    JSValue e = JS_GetException(cx);
    const char* s = JS_ToCString(cx, e);
    own->trouble = std::string("the script threw: ") + (s ? s : "?");
    JS_FreeCString(cx, s), JS_FreeValue(cx, e);
    return all;
  }
  const auto list =
      [&](const char* name,
          auto put) {  // (a cloud's points or sizes, each an {x, y})
        JSValue a = JS_GetPropertyStr(cx, out, name);
        int64_t len = 0;
        if (JS_IsArray(a)) JS_GetLength(cx, a, &len);
        for (int64_t i = 0; i < len && i < n; ++i) {
          JSValue p = JS_GetPropertyUint32(cx, a, (uint32_t)i),
                  x = JS_GetPropertyStr(cx, p, "x"),
                  y = JS_GetPropertyStr(cx, p, "y");
          double px = 0, py = 0;
          JS_ToFloat64(cx, &px, x), JS_ToFloat64(cx, &py, y);
          put(all[(size_t)i], px, py);
          JS_FreeValue(cx, x), JS_FreeValue(cx, y), JS_FreeValue(cx, p);
        }
        JS_FreeValue(cx, a);
        return len;
      };
  const int64_t built = list("points", [&](ScriptCopy& c, double x, double y) {
    c.x = x * unit, c.y = y * unit;
  });
  list("sizes", [](ScriptCopy& c, double x, double) { c.size = x; });
  for (int64_t i = built; i < n; ++i)
    all[(size_t)i].size =
        0;  // (copies past the cloud's last point are not seen)
  JS_FreeValue(cx, out);
  return all;
}

void Script::parameters(const std::map<std::string, double>& numbers,
                        const std::map<std::string, std::string>& words) {
  JSContext* cx = own->cx;
  for (const auto& [name, v] : numbers)
    JS_SetPropertyStr(cx, own->parameters, name.c_str(), JS_NewFloat64(cx, v));
  for (const auto& [name, w] : words)
    JS_SetPropertyStr(cx, own->parameters, name.c_str(),
                      JS_NewString(cx, w.c_str()));
  leva_colours(
      cx, own->parameters, numbers,
      words);  // (k.tint "#rrggbb", as leva returns a colour: script_leva.h)
}
ScriptCopy Script::ask(
    int i, int n, double t,
    const ScriptCopy&
        at) {  // (each(), the parameters as last told; at: where this copy lies
               // so far, its fifth: one object, told again for each copy)
  ScriptCopy c;
  JSContext* cx = own->cx;
  JS_UpdateStackTop(own->rt);
  if (own->said[0] == JS_ATOM_NULL)
    for (int k = 0; k < 12; ++k)
      own->said[k] = JS_NewAtom(cx, script_copy_names[k]);
  JS_SetProperty(cx, own->at, own->said[0], JS_NewFloat64(cx, at.x)),
      JS_SetProperty(cx, own->at, own->said[1], JS_NewFloat64(cx, at.y)),
      JS_SetProperty(cx, own->at, own->said[2], JS_NewFloat64(cx, at.z));
  JSValue args[5] = {JS_NewInt32(cx, i), JS_NewInt32(cx, n),
                     JS_NewFloat64(cx, t), JS_DupValue(cx, own->parameters),
                     JS_DupValue(cx, own->at)};
  JSValue out = JS_Call(cx, own->each, JS_UNDEFINED, 5, args);
  JS_FreeValue(cx, args[3]), JS_FreeValue(cx, args[4]);
  if (JS_IsException(out)) {
    JSValue e = JS_GetException(cx);
    const char* s = JS_ToCString(cx, e);
    own->trouble = std::string("each() threw: ") + (s ? s : "?");
    JS_FreeCString(cx, s), JS_FreeValue(cx, e);
    return c;
  }
  double* const to[12] = {&c.x,       &c.y,        &c.z,        &c.size,
                          &c.rotate,  &c.rotate_x, &c.rotate_y, &c.colour,
                          &c.opacity, &c.scale_x,  &c.scale_y,  &c.scale_z};
  for (int k = 0; k < 12; ++k) {
    JSValue v = JS_GetProperty(cx, out, own->said[k]);
    if (JS_IsNumber(v)) JS_ToFloat64(cx, to[k], v);
    JS_FreeValue(cx, v);
  }
  JS_FreeValue(cx, out);
  return c;
}

}  // namespace motolii
