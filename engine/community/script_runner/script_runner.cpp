// script_runner.h's Script: QuickJS-ng behind each(), with what each dialect
// needs evaluated before the file (Cavalry's names, the easings, leva's
// folder(), After Effects expressions, p5.js and the libraries a sketch names).
#include "community/script_runner/script_runner.h"

#include <algorithm>
#include <fstream>
#include <memory>
#include <sstream>
#include <thread>

#include "base/file_read.h"
#include "community/after_effects/lottie_bytecode.h"
#include "community/after_effects/lottie_canonical.h"
#include "community/quickjs/script_leva.h"
#include "community/script_runner/project_reads.h"
#include "community/script_runner/script_natives.h"
#include "community/sites/adapter.h"
#include "community/subtitles/subtitles.h"
#include "community/three/tsl_each.h"
#include "media/video_frames_for_scripts.h"
#include "shelf/shelf_folders.h"

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
                        // a Canvalry distribution (a PointCloud)
  bool sketch = false;  // a p5.js sketch (p5_stand.h)
  std::string made_p5, made_film;  // what it was made with, for its helpers
  // Scripts of the same file, one QuickJS runtime each, that lay a share of
  // many copies on threads of their own (copies()).
  std::vector<std::unique_ptr<Script>> helpers;
  bool relates = false;  // a relation's relate() and no draw(): it lays copies
                         // too, all at once (__copies_by_relate)
  std::string wgsl;      // WGSL vertex shader built by tsl_each(); empty when
                         // the GPU path could not be built (CPU is the fallback)
  FilmRead film;         // what its createCapture and createVideo see
  std::unique_ptr<Subtitles> subtitles;  // an .ass file's, drawn by libass
  std::vector<SketchLine> lines;         // its lines that draw
  JSAtom said[17] = {};  // the names each() says a copy by, made atoms once
                         // (JS_GetPropertyStr makes and frees one at every
                         // read: quickjs-ng quickjs.c)
};
// The last five are a rigid body's, by Jolt Physics' names (script.h); force
// is a pair.
static const char* const script_copy_names[17] = {
    "x",        "y",        "z",      "size",          "rotate",
    "rotate_x", "rotate_y", "colour", "opacity",       "scale_x",
    "scale_y",  "scale_z",  "mass",   "gravityFactor", "restitution",
    "friction", "force"};

Script::Script(const std::string& file, const std::string& p5,
               const std::string& film)
    : own(new Own) {
  const std::string code = read_text(file);
  const std::string
      form = adapter_form(code),
      src = adapter_js(
          code,
          form);  // (a form from the net told as a sketch: adapter.h)
  own->rt = JS_NewRuntime();
  JS_SetMemoryLimit(own->rt,
                    2ull << 30);  // (a sketch keeps its frames: 100,000
                                  // rectangles a frame are 1.5 GB a second. It
                                  // stops with an error, not with the machine)
  own->cx = JS_NewContext(own->rt);
  // What JavaScript itself has is noted before anything of ours is added, so
  // that a script can be asked what its runtime adds (Script::answers).
  {
    const char plain[] =
        "globalThis.__plain = Object.getOwnPropertyNames(globalThis)";
    JS_FreeValue(own->cx, JS_Eval(own->cx, plain, strlen(plain), "plain",
                                  JS_EVAL_TYPE_GLOBAL));
  }
  own->file = file, own->src = src, own->made_p5 = p5, own->made_film = film;
  const std::string ways = ways_prelude();
  JS_FreeValue(own->cx, JS_Eval(own->cx, ways.c_str(), ways.size(), "ways",
                                JS_EVAL_TYPE_GLOBAL));
  // Motolii's own stand-ins for Cavalry and for a script written as a row of
  // numbers, loaded from the .js beside their call sites so engine does not
  // ship JavaScript as C++ string literals.
  for (const char* prelude : {"cavalry_prelude", "rows_prelude"}) {
    const std::string js = read_text(doc_engine(
        ("community/script_runner/" + std::string(prelude) + ".js").c_str()));
    JS_FreeValue(own->cx, JS_Eval(own->cx, js.c_str(), js.size(), prelude,
                                  JS_EVAL_TYPE_GLOBAL));
  }
  JS_FreeValue(
      own->cx,
      JS_Eval(own->cx, leva_prelude, strlen(leva_prelude), "leva",
              JS_EVAL_TYPE_GLOBAL));  // (folder(), as its parameters object
                                      // says its folds: script_leva.h)
  {  // The files a script came with: those of the folder named like it,
     // beside it (Fire/ for Fire.js). __text_read(name) gives one as text.
    JS_SetContextOpaque(own->cx, &own->film);
    own->film.beside = (std::filesystem::path(file).parent_path() /
                        std::filesystem::path(file).stem())
                           .string();
    JSValue g = JS_GetGlobalObject(own->cx);
    JS_SetPropertyStr(own->cx, g, "__text_read",
                      JS_NewCFunction(own->cx, text_read, "__text_read", 1));
    JS_FreeValue(own->cx, g);
  }
  if (src.find("AE.compile") !=
      std::string::npos) {  // AE 式は lottie-web の ExpressionManager が
                            // 解釈する (AGENTS.md 原則 2)。shim は
                            // community/after_effects/lottie_shim.js、vendor
                            // は third_party/js/lottie。ビルド時に lottie_shim
                            // とその import を QuickJS バイトコードに焼いて
                            // あり (community/after_effects/lottie_bytecode.h)、
                            // ここはそれを JS_ReadObject で読むだけ。
    // Module loader: looks up the requested canonical name in the pre-compiled
    // bytecode table and returns its JSModuleDef. Every lottie module the shim
    // reaches was built into the table by lottie_precompile; a miss means the
    // graph changed since the build.
    auto loader = +[](JSContext* cx, const char* name, void*) -> JSModuleDef* {
      const std::string n = name;
      for (std::size_t i = 0; i < kLottieBytecodeCount; ++i) {
        if (n == kLottieBytecode[i].name) {
          JSValue m = JS_ReadObject(cx, kLottieBytecode[i].data,
                                    kLottieBytecode[i].size,
                                    JS_READ_OBJ_BYTECODE);
          if (JS_IsException(m)) {
            std::fprintf(stderr, "lottie: JS_ReadObject failed for %s\n",
                         name);
            return nullptr;
          }
          auto* def = (JSModuleDef*)JS_VALUE_GET_PTR(m);
          JS_FreeValue(cx, m);
          return def;
        }
      }
      std::fprintf(stderr, "lottie: %s is not in the bytecode table\n", name);
      JS_ThrowReferenceError(cx, "lottie module not pre-compiled: %s", name);
      return nullptr;
    };
    JS_SetModuleLoaderFunc(own->rt, lottie_canonical, loader, nullptr);
    // DOM globals must be set BEFORE the shim's imports evaluate, since
    // lottie-web's utils/common.js reads navigator.userAgent at top-level
    // and throws under QuickJS otherwise — which silently kills the
    // shim module's top-level (import side effects are evaluated before
    // the shim body). Set the stubs with a plain-script eval first.
    {
      static const char* kDomStubs =
          "globalThis.navigator = globalThis.navigator || "
          "{ userAgent: '' };\n"
          "if (typeof globalThis.window === 'undefined') "
          "globalThis.window = null;\n"
          "if (typeof globalThis.document === 'undefined') "
          "globalThis.document = null;\n";
      JS_FreeValue(own->cx,
                   JS_Eval(own->cx, kDomStubs, std::strlen(kDomStubs),
                           "<lottie_dom_stubs>", JS_EVAL_TYPE_GLOBAL));
    }
    const LottieBytecodeEntry* shim = nullptr;
    for (std::size_t i = 0; i < kLottieBytecodeCount; ++i)
      if (std::string(kLottieBytecode[i].name) == kLottieShimCanonical) {
        shim = &kLottieBytecode[i];
        break;
      }
    if (!shim) {
      own->trouble = "lottie_shim bytecode not generated (re-run cmake)";
    } else {
      auto describe = [&](JSValue v) -> std::string {
        if (!JS_IsException(v) && !JS_IsError(v)) return "?";
        JSValue e = JS_IsException(v) ? JS_GetException(own->cx)
                                      : JS_DupValue(own->cx, v);
        const char* s = JS_ToCString(own->cx, e);
        std::string out = s ? s : "?";
        JSValue st = JS_GetPropertyStr(own->cx, e, "stack");
        if (!JS_IsUndefined(st) && !JS_IsException(st)) {
          const char* ss = JS_ToCString(own->cx, st);
          if (ss) {
            out += "\n";
            out += ss;
          }
          JS_FreeCString(own->cx, ss);
        }
        JS_FreeValue(own->cx, st);
        JS_FreeCString(own->cx, s);
        JS_FreeValue(own->cx, e);
        return out;
      };
      JSValue m = JS_ReadObject(own->cx, shim->data, shim->size,
                                JS_READ_OBJ_BYTECODE);
      if (JS_IsException(m)) {
        own->trouble = "lottie_shim: JS_ReadObject failed: " + describe(m);
      } else {
        // JS_EvalFunction resolves the shim's imports (calling the loader for
        // each) and runs every reached module's top-level code in dependency
        // order.
        JSValue ran = JS_EvalFunction(own->cx, m);
        if (JS_IsException(ran))
          own->trouble =
              std::string("lottie_shim threw at load: ") + describe(ran);
        JS_FreeValue(own->cx, ran);
        for (JSContext* job; JS_ExecutePendingJob(own->rt, &job) > 0;) {
        }
      }
    }
  }
  const bool sketch = own->sketch = !p5.empty() && script_is_sketch(src);
  const std::filesystem::path p5Stand =
      std::filesystem::path(p5).parent_path() / "stand";
  if (sketch) {
    const std::string p5js = read_text(p5);
    // The stand-ins live beside p5.min.js: third_party/js/p5/stand/*.js. Each
    // was a C++ raw string in p5_stand.h / p5_mesh.h / p5_three.h; moved out so
    // engine holds no JavaScript it does not run.
    const auto eval = [&](const char* name) {
      const std::string js = read_text(p5Stand / (std::string(name) + ".js"));
      JS_FreeValue(own->cx, JS_Eval(own->cx, js.c_str(), js.size(), name,
                                    JS_EVAL_TYPE_GLOBAL));
    };
    eval("p5_before");
    JS_FreeValue(own->cx, JS_Eval(own->cx, p5js.c_str(), p5js.size(),
                                  "p5.min.js", JS_EVAL_TYPE_GLOBAL));
    // p5.sound itself, for a sketch that listens (script_natives.h).
    if (const std::string wrong =
            sketch_hears(own->cx, src, p5, &own->made_film);
        !wrong.empty())
      own->trouble = wrong;
    for (const char* stand : {"p5_after", "p5_three", "p5_mesh"}) eval(stand);
    if (const std::string needs = adapter_library(form); !needs.empty()) {
      const std::string lib = adapter_library_text(
          form,
          read_text(std::filesystem::path(p5).parent_path().parent_path() /
                    needs));
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
        const std::string read_ = read_text(
            std::filesystem::path(p5).parent_path().parent_path() / lib /
            (std::string(lib) + ".min.js"));
        JS_FreeValue(own->cx, JS_Eval(own->cx, read_.c_str(), read_.size(), lib,
                                      JS_EVAL_TYPE_GLOBAL));
      }
    for (const std::string& needs :
         adapter_needs(code)) {  // (a library from the net: fetched by the
                                 // adapter, it stands beside the sketch)
      const std::string lib =
          read_text(std::filesystem::path(file).parent_path() /
                    std::filesystem::path(file).stem() / needs);
      JS_FreeValue(own->cx, JS_Eval(own->cx, lib.c_str(), lib.size(),
                                    needs.c_str(), JS_EVAL_TYPE_GLOBAL));
    }
    if (!film.empty() && (src.find("createCapture") != std::string::npos ||
                          src.find("createVideo") != std::string::npos ||
                          src.find("loadImage") != std::string::npos))
      own->film.open(
          film, 320);  // (as much of it as a webcam sketch reads, and light)
    JSValue g = JS_GetGlobalObject(own->cx);
    JS_SetPropertyStr(own->cx, g, "__film_next",
                      JS_NewCFunction(own->cx, film_next, "__film_next", 0));
    JS_SetPropertyStr(own->cx, g, "__image_read",
                      JS_NewCFunction(own->cx, image_read, "__image_read", 1));
    JS_SetPropertyStr(own->cx, g, "__jobs",
                      JS_NewCFunction(own->cx, jobs_run, "__jobs", 0));
    if (form == "subtitles") {
      own->subtitles = std::make_unique<Subtitles>(code);
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
          JS_NewCFunctionData(own->cx, subtitles_frame, 2, 0, 1, &them));
      JS_FreeValue(own->cx, them);
    }
    JS_FreeValue(own->cx, g);
  }
  // What any script may read of the project (project_reads.h).
  own->asks = project_reads_give(own->cx, src, &own->project);
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
  const std::string run =
      sketch ? body + "\n;\n" + read_text(p5Stand / "p5_start.js") : src;
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
  own->text = JS_GetPropertyStr(own->cx, g, "sourceText");
  JS_FreeValue(own->cx, g);
  // Try building a WGSL vertex shader for the GPU path; fall back to CPU when
  // the graph cannot be built (tsl_each.h, from_each.js).
  if (JS_IsFunction(own->cx, own->each)) {
    const std::string cavalry =
        read_text(doc_engine("community/script_runner/cavalry_prelude.js"));
    std::string wgsl_why;
    tsl_each(doc_engine("third_party/js/three").string(),
             doc_engine("community/three_shading_language_to_shelf").string(),
             cavalry, ways, src, own->wgsl, wgsl_why);
    if (std::getenv("MOTOLII_TSL_WHY") && !wgsl_why.empty())
      std::fprintf(stderr, "tsl_each: %s\n", wgsl_why.c_str());
  }
  // A file that only says a layer's text places no copy: each stays where it
  // is.
  own->whole = !JS_IsFunction(own->cx, own->each) && !says_text();
  own->relates = src.find("function relate") != std::string::npos &&
                 src.find("function draw") == std::string::npos;
  own->parameters = JS_NewObject(own->cx), own->at = JS_NewObject(own->cx);
}
Script::~Script() {
  if (!own->cx) return;
  JS_FreeValue(own->cx, own->text);
  JS_FreeValue(own->cx, own->each), JS_FreeValue(own->cx, own->parameters),
      JS_FreeValue(own->cx, own->at);
  for (JSAtom a : own->said)
    if (a != JS_ATOM_NULL) JS_FreeAtom(own->cx, a);
  JS_FreeContext(own->cx), JS_FreeRuntime(own->rt);
}
bool Script::ok() const { return own->trouble.empty(); }
const std::string& Script::wgsl() const { return own->wgsl; }
void Script::reads(LayerReader read) { own->project.value = std::move(read); }
void Script::reads_pictures(ImageSampler sample, PointMapper point) {
  own->project.sample = std::move(sample),
  own->project.point = std::move(point);
}
void Script::reads_keys(KeyReader keys, LayerFinder named) {
  own->project.keys = std::move(keys), own->project.named = std::move(named);
}
void Script::reads_sound(SoundReader sound) {
  own->project.sound = std::move(sound);
}
bool Script::sketch() const { return own->sketch; }
bool Script::says_text() const {
  return own->cx && JS_IsFunction(own->cx, own->text);
}
std::string Script::text(double t, const std::map<std::string, double>& numbers,
                         const std::map<std::string, std::string>& words,
                         const std::string& typed) {
  if (!says_text() || !ok()) return typed;
  JSContext* cx = own->cx;
  JS_UpdateStackTop(own->rt);
  parameters(numbers, words);
  JSValue args[3] = {JS_NewFloat64(cx, t), JS_DupValue(cx, own->parameters),
                     JS_NewStringLen(cx, typed.data(), typed.size())};
  JSValue out = JS_Call(cx, own->text, JS_UNDEFINED, 3, args);
  JS_FreeValue(cx, args[1]), JS_FreeValue(cx, args[2]);
  std::string said = typed;
  if (JS_IsException(out)) {
    JSValue e = JS_GetException(cx);
    const char* why = JS_ToCString(cx, e);
    own->trouble = std::string("sourceText() threw: ") + (why ? why : "?");
    if (why) JS_FreeCString(cx, why);
    JS_FreeValue(cx, e);
  } else if (!JS_IsUndefined(out) && !JS_IsNull(out)) {
    if (const char* got = JS_ToCString(cx, out)) said = got, JS_FreeCString(cx, got);
    // After Effects writes a line break in a text as \r; here it is \n.
    for (size_t at = 0; (at = said.find('\r', at)) != std::string::npos;)
      if (at + 1 < said.size() && said[at + 1] == '\n')
        said.erase(at, 1);
      else
        said[at] = '\n';
  }
  JS_FreeValue(cx, out);
  return said;
}
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
        own->sketch || own->asks
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
