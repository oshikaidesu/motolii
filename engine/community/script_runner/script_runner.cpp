// script_runner.h's Script: QuickJS-ng behind each(), with what each dialect
// needs evaluated before the file (Cavalry's names, the easings, leva's
// folder(), After Effects expressions, p5.js and the libraries a sketch names).
// Dialect-specific setup lives in run_ae.cpp, run_p5.cpp and run_cavalry.cpp;
// sketch query methods live in run_p5.cpp.
#include "community/script_runner/script_runner.h"

#include <algorithm>
#include <fstream>
#include <memory>
#include <sstream>
#include <thread>

#include "base/file_read.h"
#include "community/quickjs/script_leva.h"
#include "community/script_runner/project_reads.h"
#include "community/script_runner/run_ae.h"
#include "community/script_runner/run_cavalry.h"
#include "community/script_runner/run_p5.h"
#include "community/script_runner/script_natives.h"
#include "community/script_runner/script_runner_own.h"
#include "community/sites/site_adapter.h"
#include "community/subtitles/subtitles.h"
#include "community/three/tsl_each.h"
#include "shelf/shelf_folders.h"

namespace motolii {

// The last five are a rigid body's, by Jolt Physics' names (script.h); force
// is a pair.
const char* const script_copy_names[17] = {
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
  // AE expressions (run_ae.cpp).
  setup_ae_expressions(own->rt, own->cx, own->trouble);
  const bool sketch = own->sketch = !p5.empty() && script_is_sketch(src);
  // p5.js sketch (run_p5.cpp).
  if (sketch)
    setup_p5_sketch(own->cx, src, code, form, file, p5, film, own->film,
                    own->subtitles, own->trouble);
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
  } else if (!src.empty()) {
    // Cavalry object-literal wrapping (run_cavalry.cpp).
    body = wrap_cavalry_expression(own->cx, src, file);
  }
  const std::string run =
      sketch ? body + "\n;\n" +
                   read_text(std::filesystem::path(p5).parent_path() / "stand" /
                             "p5_start.js")
             : body;
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
// Script::text() is defined in run_ae.cpp (sourceText is an AE expression).
bool Script::lays() const {
  return own->cx && (own->relates || (!own->whole && !own->sketch));
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
  // Cavalry PointCloud: the whole file says every copy at once
  // (run_cavalry.cpp).
  run_cavalry_whole(own->cx, own->rt, own->src, own->file, numbers, words, n, t,
                    unit, all, own->trouble);
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
// Script::ask() is defined in run_p5.cpp (the per-copy each() evaluation,
// alongside the other Script methods that call into the QuickJS runtime).

}  // namespace motolii
