// Builds a layer's 3D shape by running a three.js shape script in QuickJS.
//
// three.js is MIT licensed (github.com/mrdoob/three.js, r186). The library is
// build/three.core.js plus two of its examples, under third_party/js/three.
//
// A shape script lives in solids/*.js. Its parameters are declared in its
// header comment, as for a preset script (see script.h), and it exports
// `solid(k)`, which returns a BufferGeometry. The script is run unmodified, the
// same way three_isf.cpp runs a three.js effect, and the geometry's typed
// arrays are copied out into a SolidMesh.
//
// A single QuickJS runtime is shared by all calls, because loading
// three.core.js takes about 24 ms. Modules it has loaded are cached by name.
#include "community/three/solid_three.h"

#include <quickjs.h>

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <map>
#include <mutex>
#include <sstream>
#include <string>
#include <vector>

namespace motolii {

namespace {

// Returns the whole contents of `file`, or an empty string if it cannot be
// read.
std::string solid_text(const std::string& file) {
  std::ifstream in(file);
  std::stringstream all;
  all << in.rdbuf();
  return all.str();
}

}  // namespace

// See solid_three.h.
bool solid_is(const std::string& file) {
  return std::filesystem::path(file).extension() == ".js" &&
         solid_text(file).find("export function solid") != std::string::npos;
}
// See solid_three.h.
bool solid_reads(const std::string& file) {
  return solid_text(file).find("k.alpha") != std::string::npos;
}

namespace {

// QuickJS module-name normalizer. Resolves the import `name` found in the
// module `base` to a full path. The bare name 'three' maps to the three.core.js
// beside the importing file, as in the import map of three.js's
// examples/*.html. Relative names are resolved against the importing file's
// directory.
char* solid_name(JSContext* cx, const char* base, const char* name, void*) {
  const std::filesystem::path dir = std::filesystem::path(base).parent_path();
  const std::filesystem::path to =
      std::string(name) == "three" ? dir / "three.core.js"
      : name[0] == '.'             ? dir / name
                                   : std::filesystem::path(name);
  return js_strdup(cx, to.lexically_normal().string().c_str());
}
// QuickJS module loader. Compiles the module at the path `name` without running
// it. Returns null if the file does not compile.
JSModuleDef* solid_load(JSContext* cx, const char* name, void*) {
  const std::string src = solid_text(name);
  JSValue built = JS_Eval(cx, src.c_str(), src.size(), name,
                          JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
  if (JS_IsException(built)) return nullptr;
  auto* m = (JSModuleDef*)JS_VALUE_GET_PTR(built);
  JS_FreeValue(cx, built);
  return m;
}

// JavaScript run after the shape script is imported. It calls solid(k) and
// leaves the result in globals as flat typed arrays: __pos, __nrm, __uv, __idx
// and
// __repeat. Normals are computed if the geometry has none, and an
// unindexed geometry gets a sequential index. On failure it sets __why.
const char* const solid_wrap = R"(
const k = globalThis.__k;
if (globalThis.__cover) k.alpha = { width: k.coverW, height: k.coverH, values: new Uint8Array(globalThis.__cover) };
try {
    const g = solid(k), n = g.attributes.position ? g.attributes.position.count : 0;
    if (n && !g.attributes.normal) g.computeVertexNormals();
    globalThis.__pos = n ? Float32Array.from(g.attributes.position.array) : new Float32Array(0);
    globalThis.__nrm = n ? Float32Array.from(g.attributes.normal.array) : new Float32Array(0);
    globalThis.__uv = n && g.attributes.uv ? Float32Array.from(g.attributes.uv.array) : new Float32Array(2 * n);
    globalThis.__idx = g.index ? Uint32Array.from(g.index.array) : Uint32Array.from({ length: n }, (_, i) => i);
    globalThis.__repeat = !!g.userData.repeat;
} catch (e) { globalThis.__why = String(e) + ' ' + (e.stack || ''); }
)";

// Copies the typed array held in the global property `name` of `g` into `into`,
// reinterpreting its bytes as T. `into` is left unchanged if the property is
// not a typed array.
template <typename T>
void solid_array(JSContext* cx, JSValue g, const char* name,
                 std::vector<T>& into) {
  JSValue a = JS_GetPropertyStr(cx, g, name);
  size_t from = 0, bytes = 0, each = 0, size = 0;
  JSValue buffer = JS_GetTypedArrayBuffer(cx, a, &from, &bytes, &each);
  if (const uint8_t* p = JS_IsException(buffer)
                             ? nullptr
                             : JS_GetArrayBuffer(cx, &size, buffer))
    into.assign((const T*)(p + from), (const T*)(p + from + bytes));
  JS_FreeValue(cx, buffer), JS_FreeValue(cx, a);
}

}  // namespace

// See solid_three.h. The runtime and context are created on first use and are
// guarded by a mutex, so calls from several threads are serialized.
bool solid_three(const std::string& file,
                 const std::map<std::string, double>& numbers,
                 const std::map<std::string, std::string>& words, double wide,
                 double high, const std::vector<uint8_t>& cover, int coverW,
                 int coverH, SolidMesh& out, std::string& why) {
  static std::mutex lock;
  static JSRuntime* rt = nullptr;
  static JSContext* cx = nullptr;
  static int built = 0;
  std::lock_guard<std::mutex> hold(lock);
  if (!rt)
    rt = JS_NewRuntime(), cx = JS_NewContext(rt),
    JS_SetModuleLoaderFunc(rt, solid_name, solid_load, nullptr);
  JSValue g = JS_GetGlobalObject(cx), k = JS_NewObject(cx);
  for (const auto& [n, v] : numbers)
    JS_SetPropertyStr(cx, k, n.c_str(), JS_NewFloat64(cx, v));
  for (const auto& [n, w] : words)
    JS_SetPropertyStr(cx, k, n.c_str(), JS_NewString(cx, w.c_str()));
  JS_SetPropertyStr(cx, k, "w", JS_NewFloat64(cx, wide)),
      JS_SetPropertyStr(cx, k, "h", JS_NewFloat64(cx, high));
  JS_SetPropertyStr(cx, k, "coverW", JS_NewInt32(cx, coverW)),
      JS_SetPropertyStr(cx, k, "coverH", JS_NewInt32(cx, coverH));
  JS_SetPropertyStr(cx, g, "__k", k);
  JS_SetPropertyStr(
      cx, g, "__cover",
      cover.empty() ? JS_UNDEFINED
                    : JS_NewArrayBufferCopy(cx, cover.data(), cover.size()));
  JS_SetPropertyStr(cx, g, "__why", JS_NewString(cx, ""));
  const std::string code =
      "import { solid } from '" +
      std::filesystem::absolute(file).lexically_normal().string() + "';\n" +
      solid_wrap;
  // Each call evaluates the wrapper as a module with a fresh name. The shape
  // script itself is imported by path, so it is loaded only once.
  const std::string name = "<solid " + std::to_string(++built) + ">";
  JSValue ran =
      JS_Eval(cx, code.c_str(), code.size(), name.c_str(), JS_EVAL_TYPE_MODULE);
  for (JSContext* job; JS_ExecutePendingJob(rt, &job) > 0;) {
  }
  if (JS_IsException(ran)) {
    JSValue e = JS_GetException(cx);
    const char* s = JS_ToCString(cx, e);
    why = std::string("the shape's module: ") + (s ? s : "?");
    JS_FreeCString(cx, s), JS_FreeValue(cx, e);
  } else if (JSValue w = JS_GetPropertyStr(cx, g, "__why");
             const char* s = JS_ToCString(cx, w)) {
    why = s;
    JS_FreeCString(cx, s), JS_FreeValue(cx, w);
  }
  JS_FreeValue(cx, ran);
  out = SolidMesh{};
  if (why.empty()) {
    solid_array(cx, g, "__pos", out.pos), solid_array(cx, g, "__nrm", out.nrm),
        solid_array(cx, g, "__uv", out.uv),
        solid_array(cx, g, "__idx", out.idx);
    JSValue r = JS_GetPropertyStr(cx, g, "__repeat");
    out.repeat = JS_ToBool(cx, r) > 0;
    JS_FreeValue(cx, r);
  }
  JS_FreeValue(cx, g);
  return why.empty();
}

}  // namespace motolii
