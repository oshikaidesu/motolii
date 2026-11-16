// Converts Hydra code (hydra-synth, by Olivia Jack and others, AGPL-3.0) into
// an ISF effect.
//
// Hydra is not part of this repository. shelves/extensions/hydra/get.sh
// downloads the npm package into a separate folder. This file runs that package
// in its own QuickJS runtime: the Hydra code goes in and the ISF text comes
// out. Hydra's generator-factory.js produces the GLSL, so neither WebGL nor a
// web page is needed.
//
// Every number in a Hydra chain is passed as a function, which makes Hydra emit
// it as a uniform. Each such uniform becomes a parameter of the ISF effect. A
// value that changes over time, such as a function of time or an array, is
// sampled every HYDRA_STEP seconds by Hydra's own code. The samples become the
// keyframes of that parameter and can be edited like any other keyframes.
#include "community/hydra/hydra_isf.h"

#include <quickjs.h>

#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

#include "base/file_read.h"
#include "shelf/shelf_folders.h"

namespace motolii {

namespace {

// Returns the contents of the file at `file`, or an empty string if it cannot
// be read.
std::string hydra_text(const std::string& file) {
  return read_text(file);
}
// QuickJS module-name normalizer. Resolves `name` relative to the directory of
// the importing module `base` and returns the result as a newly allocated
// string.
char* hydra_name(JSContext* cx, const char* base, const char* name, void*) {
  return js_strdup(cx, (std::filesystem::path(base).parent_path() / name)
                           .lexically_normal()
                           .string()
                           .c_str());
}
// QuickJS module loader. Reads the file `name` from disk and compiles it as a
// module without running it. Returns nullptr if compilation fails.
JSModuleDef* hydra_load(JSContext* cx, const char* name, void*) {
  const std::string src = hydra_text(name);
  JSValue built = JS_Eval(cx, src.c_str(), src.size(), name,
                          JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
  if (JS_IsException(built)) return nullptr;
  auto* m = (JSModuleDef*)JS_VALUE_GET_PTR(built);
  JS_FreeValue(cx, built);
  return m;
}

// JavaScript module that runs inside QuickJS, in hydra_make.js beside this
// file. The caller sets the globals __code (the Hydra source), __seconds and
// __step first. On success the module sets __isf (the ISF text) and
// __parameters, and sets __moving to the list of time-varying parameters. On
// failure it sets __why to the error text. Read once; the text is small.
const std::string& hydra_make() {
  static const std::string text =
      read_text(doc_engine("community/hydra/hydra_make.js"));
  return text;
}

}  // namespace

// See hydra_isf.h. Runs the Hydra code in a fresh QuickJS runtime that is
// destroyed before returning, so no state is shared between calls.
bool hydra_isf(const std::string& folder, const std::string& code,
               double seconds, std::string& isf,
               std::vector<HydraParameter>& parameters, std::string& why) {
  const std::filesystem::path src = std::filesystem::path(folder) / "src";
  std::error_code wrong;
  if (!std::filesystem::exists(src / "generator-factory.js", wrong))
    return why =
               "Hydra is a part of its own and is not there: run "
               "shelves/extensions/hydra/get.sh",
           false;
  JSRuntime* rt = JS_NewRuntime();
  JSContext* cx = JS_NewContext(rt);
  JS_SetModuleLoaderFunc(rt, hydra_name, hydra_load, nullptr);
  JSValue g = JS_GetGlobalObject(cx);
  JS_SetPropertyStr(cx, g, "__code",
                    JS_NewStringLen(cx, code.c_str(), code.size()));
  JS_SetPropertyStr(cx, g, "__seconds", JS_NewFloat64(cx, seconds));
  JS_SetPropertyStr(cx, g, "__step", JS_NewFloat64(cx, HYDRA_STEP));
  const std::string name = (src / "motolii.js").string();
  const std::string& make = hydra_make();
  JSValue ran = JS_Eval(cx, make.c_str(), make.size(), name.c_str(),
                        JS_EVAL_TYPE_MODULE);
  if (JS_IsException(ran)) {
    JSValue e = JS_GetException(cx);
    const char* s = JS_ToCString(cx, e);
    why = s ? s : "Hydra could not be read";
    JS_FreeCString(cx, s), JS_FreeValue(cx, e);
  }
  JS_FreeValue(cx, ran);
  for (JSContext* job; JS_ExecutePendingJob(rt, &job) > 0;) {
  }
  // Returns the string value of the global `n`, or an empty string if it is not
  // a string.
  const auto said = [&](const char* n) {
    JSValue v = JS_GetPropertyStr(cx, g, n);
    std::string out;
    if (JS_IsString(v)) {
      const char* s = JS_ToCString(cx, v);
      if (s) out = s;
      JS_FreeCString(cx, s);
    }
    JS_FreeValue(cx, v);
    return out;
  };
  if (why.empty()) why = said("__why");
  isf = said("__isf");
  // Copy the time-varying parameters from the JavaScript array into
  // `parameters`.
  JSValue moving = JS_GetPropertyStr(cx, g, "__moving");
  if (JS_IsArray(moving)) {
    int64_t n = 0;
    JS_GetLength(cx, moving, &n);
    for (int64_t i = 0; i < n; ++i) {
      JSValue one = JS_GetPropertyInt64(cx, moving, i),
              word = JS_GetPropertyStr(cx, one, "name"),
              keys = JS_GetPropertyStr(cx, one, "keys");
      HydraParameter k;
      if (const char* s = JS_ToCString(cx, word))
        k.name = s, JS_FreeCString(cx, s);
      int64_t m = 0;
      JS_GetLength(cx, keys, &m);
      for (int64_t j = 0; j < m; ++j) {
        double v = 0;
        JSValue at = JS_GetPropertyInt64(cx, keys, j);
        JS_ToFloat64(cx, &v, at);
        JS_FreeValue(cx, at);
        k.keys.push_back(v);
      }
      parameters.push_back(std::move(k));
      JS_FreeValue(cx, keys), JS_FreeValue(cx, word), JS_FreeValue(cx, one);
    }
  }
  JS_FreeValue(cx, moving), JS_FreeValue(cx, g);
  JS_FreeContext(cx), JS_FreeRuntime(rt);
  if (isf.empty() && why.empty()) why = "Hydra gave nothing";
  return !isf.empty();
}

}  // namespace motolii
