#include "community/three/tsl_each.h"

#include <quickjs.h>

#include <filesystem>
#include <string>

#include "base/file_read.h"

namespace motolii {

namespace {

struct TslEachRun {
  std::filesystem::path three;
  std::filesystem::path writers;
};

// Module name normalizer: same resolution as tsl_shelf.cpp, plus 'acorn'.
char* each_name(JSContext* cx, const char* base, const char* name, void* held) {
  const TslEachRun& run = *(const TslEachRun*)held;
  const std::string n = name;
  std::string to;
  if (n == "three" || n == "three/webgpu")
    to = (run.three / "three.webgpu.js").generic_string();
  else if (n == "three/tsl")
    to = (run.three / "three.tsl.js").generic_string();
  else if (n == "acorn")
    to = (run.three.parent_path() / "acorn" / "acorn.mjs").generic_string();
  else if (n[0] == '.' || n[0] == '/') {
    std::filesystem::path p =
        n[0] == '/' ? std::filesystem::path(n)
                    : std::filesystem::path(base).parent_path() / n;
    if (p.extension().empty()) p += ".js";
    to = p.lexically_normal().generic_string();
  } else
    to = std::string("<absent ") + n + ">";
  return js_strdup(cx, to.c_str());
}

JSModuleDef* each_load(JSContext* cx, const char* name, void*) {
  const std::string n = name;
  std::string src;
  if (n.rfind("<absent ", 0) == 0)
    src =
        "const any=new Proxy(function(){},{get:(t,k)=>k===Symbol.toPrimitive?"
        "()=>0:any,apply:()=>any,construct:()=>any,set:()=>true});"
        "export default any;";
  else
    src = read_text(n);
  JSValue built = JS_Eval(cx, src.c_str(), src.size(), name,
                          JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
  if (JS_IsException(built)) return nullptr;
  auto* m = (JSModuleDef*)JS_VALUE_GET_PTR(built);
  JS_FreeValue(cx, built);
  return m;
}

std::string each_global(JSContext* cx, JSValue g, const char* key) {
  JSValue v = JS_GetPropertyStr(cx, g, key);
  const char* s = JS_IsString(v) ? JS_ToCString(cx, v) : nullptr;
  const std::string out = s ? s : "";
  if (s) JS_FreeCString(cx, s);
  JS_FreeValue(cx, v);
  return out;
}

}  // namespace

bool tsl_each(const std::string& three, const std::string& writers,
              const std::string& cavalry, const std::string& ease,
              const std::string& src, std::string& wgsl, std::string& why) {
  TslEachRun run{three, writers};
  JSRuntime* rt = JS_NewRuntime();
  JSContext* cx = JS_NewContext(rt);
  JS_SetModuleLoaderFunc(rt, each_name, each_load, &run);
  const std::string driver =
      "import { buildEach } from '" +
      (std::filesystem::path(writers) / "from_each.js").generic_string() +
      "';\n"
      "const r = buildEach(globalThis.__src, globalThis.__cavalry,"
      " globalThis.__ease);\n"
      "globalThis.__wgsl = r.wgsl || '';\n"
      "globalThis.__why = r.why || '';\n";
  JSValue g = JS_GetGlobalObject(cx);
  JS_SetPropertyStr(cx, g, "__src", JS_NewString(cx, src.c_str()));
  JS_SetPropertyStr(cx, g, "__cavalry", JS_NewString(cx, cavalry.c_str()));
  JS_SetPropertyStr(cx, g, "__ease", JS_NewString(cx, ease.c_str()));
  JSValue ran = JS_Eval(cx, driver.c_str(), driver.size(), "<tsl_each driver>",
                        JS_EVAL_TYPE_MODULE);
  for (JSContext* job; JS_ExecutePendingJob(rt, &job) > 0;) {
  }
  why.clear();
  if (JS_IsException(ran)) {
    JSValue e = JS_GetException(cx);
    const char* s = JS_ToCString(cx, e);
    why = std::string("driver: ") + (s ? s : "?");
    JS_FreeCString(cx, s);
    JS_FreeValue(cx, e);
  } else {
    why = each_global(cx, g, "__why");
    wgsl = each_global(cx, g, "__wgsl");
  }
  JS_FreeValue(cx, ran);
  JS_FreeValue(cx, g);
  JS_FreeContext(cx);
  JS_FreeRuntime(rt);
  return why.empty();
}

}  // namespace motolii
