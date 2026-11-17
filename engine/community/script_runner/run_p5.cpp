// p5.js sketch setup and the Script methods that ask a running sketch.
// AGENTS.md principle 2: p5.js itself runs the sketch; the engine loads it.
#include "community/script_runner/run_p5.h"

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <string>

#include "base/file_read.h"
#include "community/quickjs/script.h"
#include "community/script_runner/script_natives.h"
#include "community/script_runner/script_runner.h"
#include "community/script_runner/script_runner_own.h"
#include "community/sites/site_adapter.h"
#include "shelf/shelf_folders.h"

namespace motolii {

void setup_p5_sketch(JSContext* cx, const std::string& src,
                     const std::string& code, const std::string& form,
                     const std::string& file, const std::string& p5,
                     const std::string& film_path, FilmRead& film,
                     std::unique_ptr<Subtitles>& subtitles,
                     std::string& trouble) {
  const std::string p5js = read_text(p5);
  const std::filesystem::path p5Stand =
      std::filesystem::path(p5).parent_path() / "stand";
  // The stand-ins live beside p5.min.js: third_party/js/p5/stand/*.js. Each
  // was a C++ raw string in p5_stand.h / p5_mesh.h / p5_three.h; moved out so
  // engine holds no JavaScript it does not run.
  const auto eval = [&](const char* name) {
    const std::string js = read_text(p5Stand / (std::string(name) + ".js"));
    JS_FreeValue(cx, JS_Eval(cx, js.c_str(), js.size(), name,
                             JS_EVAL_TYPE_GLOBAL));
  };
  eval("p5_before");
  JS_FreeValue(cx, JS_Eval(cx, p5js.c_str(), p5js.size(), "p5.min.js",
                            JS_EVAL_TYPE_GLOBAL));
  // p5.sound itself, for a sketch that listens (script_natives.h).
  if (const std::string wrong =
          sketch_hears(cx, src, p5, &film_path);
      !wrong.empty())
    trouble = wrong;
  for (const char* stand : {"p5_after", "p5_three", "p5_mesh"}) eval(stand);
  if (const std::string needs = adapter_library(form); !needs.empty()) {
    const std::string lib = adapter_library_text(
        form,
        read_text(std::filesystem::path(p5).parent_path().parent_path() /
                  needs));
    JS_FreeValue(cx, JS_Eval(cx, lib.c_str(), lib.size(), needs.c_str(),
                             JS_EVAL_TYPE_GLOBAL));
  }
  if (script_pushes(src) && src.find("d3.") != std::string::npos)
    for (const char* lib :
         {"d3-binarytree", "d3-quadtree", "d3-octree",
          "d3-force-3d"}) {  // (a relation that pushes with d3's forces,
                             // third_party/js; the other two it says it needs
                             // only run forceSimulation, which the world does
                             // for it: document/evaluate/world.h)
      const std::string read_ = read_text(
          std::filesystem::path(p5).parent_path().parent_path() / lib /
          (std::string(lib) + ".min.js"));
      JS_FreeValue(cx, JS_Eval(cx, read_.c_str(), read_.size(), lib,
                                JS_EVAL_TYPE_GLOBAL));
    }
  for (const std::string& needs :
       adapter_needs(code)) {  // (a library from the net: fetched by the
                               // adapter, it stands beside the sketch)
    const std::string lib =
        read_text(std::filesystem::path(file).parent_path() /
                  std::filesystem::path(file).stem() / needs);
    JS_FreeValue(cx, JS_Eval(cx, lib.c_str(), lib.size(), needs.c_str(),
                             JS_EVAL_TYPE_GLOBAL));
  }
  if (!film_path.empty() &&
      (src.find("createCapture") != std::string::npos ||
       src.find("createVideo") != std::string::npos ||
       src.find("loadImage") != std::string::npos))
    film.open(film_path,
              320);  // (as much of it as a webcam sketch reads, and light)
  JSValue g = JS_GetGlobalObject(cx);
  JS_SetPropertyStr(cx, g, "__film_next",
                    JS_NewCFunction(cx, film_next, "__film_next", 0));
  JS_SetPropertyStr(cx, g, "__image_read",
                    JS_NewCFunction(cx, image_read, "__image_read", 1));
  JS_SetPropertyStr(cx, g, "__jobs",
                    JS_NewCFunction(cx, jobs_run, "__jobs", 0));
  if (form == "subtitles") {
    subtitles = std::make_unique<Subtitles>(code);
    JSValue size = JS_NewArray(cx),
            them = JS_NewInt64(cx, (int64_t)(intptr_t)subtitles.get());
    JS_SetPropertyUint32(cx, size, 0,
                         JS_NewInt32(cx, subtitles->width()));
    JS_SetPropertyUint32(cx, size, 1,
                         JS_NewInt32(cx, subtitles->height()));
    JS_SetPropertyStr(cx, g, "__subtitles_size", size);
    JS_SetPropertyStr(
        cx, g, "__subtitles_frame",
        JS_NewCFunctionData(cx, subtitles_frame, 2, 0, 1, &them));
    JS_FreeValue(cx, them);
  }
  JS_FreeValue(cx, g);
}

// ---------------------------------------------------------------------------
// Script methods that ask the running sketch.
// ---------------------------------------------------------------------------

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
std::string Script::answers(const std::string& js) {
  // Also once the script has failed: its context is still there, and what it
  // last did is what the Code tab asks of a failed expression.
  return own->cx ? script_said(own->cx, js.c_str()) : "";
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
  return own->sketch && ok()
             ? std::atoi(script_said(own->cx, "height").c_str())
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

// ---------------------------------------------------------------------------
// Script::ask(): calls each() for one copy, reading the result into a
// ScriptCopy.  Used by copies() for the per-copy path.
// ---------------------------------------------------------------------------

ScriptCopy Script::ask(
    int i, int n, double t,
    const ScriptCopy&
        at) {  // (each(), the parameters as last told; at: where this copy lies
               // so far, its fifth: one object, told again for each copy)
  ScriptCopy c;
  JSContext* cx = own->cx;
  if (!JS_IsFunction(cx, own->each)) return c;
  JS_UpdateStackTop(own->rt);
  if (own->said[0] == JS_ATOM_NULL)
    for (int k = 0; k < 17; ++k)
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
  double* const to[16] = {
      &c.x,        &c.y,        &c.z,      &c.size,           &c.rotate,
      &c.rotate_x, &c.rotate_y, &c.colour, &c.opacity,        &c.scale_x,
      &c.scale_y,  &c.scale_z,  &c.mass,   &c.gravity_factor, &c.restitution,
      &c.friction};
  for (int k = 0; k < 16; ++k) {
    JSValue v = JS_GetProperty(cx, out, own->said[k]);
    if (JS_IsNumber(v)) JS_ToFloat64(cx, to[k], v);
    JS_FreeValue(cx, v);
  }
  JSValue force = JS_GetProperty(cx, out, own->said[16]);
  if (JS_IsObject(force)) {
    double* const pair[2] = {&c.force_x, &c.force_y};
    for (uint32_t k = 0; k < 2; ++k) {
      JSValue v = JS_GetPropertyUint32(cx, force, k);
      if (JS_IsNumber(v)) JS_ToFloat64(cx, pair[k], v);
      JS_FreeValue(cx, v);
    }
  }
  JS_FreeValue(cx, force);
  JS_FreeValue(cx, out);
  return c;
}

}  // namespace motolii
