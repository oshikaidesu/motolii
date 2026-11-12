#include "community/three/tsl_shelf.h"

#include <quickjs.h>

#include <filesystem>
#include <fstream>
#include <map>
#include <regex>
#include <sstream>

namespace motolii {

namespace {

// What one conversion's module loader knows.
struct TslRun {
  std::filesystem::path three;
  std::string code;
  // What the code imports from a module that is not here (a page's controls,
  // its panel of sliders), by module: the names it asks for.
  std::map<std::string, std::string> absent;
  // The first promise the code left rejected: what went wrong inside an async
  // function of the page, which nothing else reports.
  std::string rejected;
};

const char* const kPasted = "<pasted tsl>";
const char* const kAbsent = "<absent ";

std::string tsl_text(const std::filesystem::path& file) {
  std::ifstream in(file);
  std::stringstream all;
  all << in.rdbuf();
  return all.str();
}

// QuickJS module-name normalizer: three.js's own names as its import map has
// them (three, three/webgpu, three/tsl), a relative name against the importing
// file with .js where it gives no extension, and any other module as one that
// is not here.
char* tsl_name(JSContext* cx, const char* base, const char* name, void* held) {
  const TslRun& run = *(const TslRun*)held;
  const std::string n = name;
  std::string to;
  if (n == kPasted)
    to = n;
  else if (n == "three" || n == "three/webgpu")
    to = (run.three / "three.webgpu.js").string();
  else if (n == "three/tsl")
    to = (run.three / "three.tsl.js").string();
  else if (n[0] == '.' || n[0] == '/') {
    std::filesystem::path p =
        n[0] == '/' ? std::filesystem::path(n)
                    : std::filesystem::path(base).parent_path() / n;
    if (p.extension().empty()) p += ".js";
    to = p.lexically_normal().string();
  } else
    to = kAbsent + n + ">";
  return js_strdup(cx, to.c_str());
}

// QuickJS module loader. The pasted code is the text in hand. A module that is
// not here is made of what the code asks of it: every name something that can
// be called, made and read without end, so the page's own setting-up of things
// that draw nothing goes through.
JSModuleDef* tsl_load(JSContext* cx, const char* name, void* held) {
  const TslRun& run = *(const TslRun*)held;
  const std::string n = name;
  std::string src;
  if (n == kPasted)
    src = run.code;
  else if (n.rfind(kAbsent, 0) == 0) {
    src =
        "const any=new Proxy(function(){},{get:(t,k)=>k===Symbol.toPrimitive?"
        "()=>0:any,apply:()=>any,construct:()=>any,set:()=>true});"
        "export default any;";
    const auto names = run.absent.find(n);
    if (names != run.absent.end()) src += names->second;
  } else
    src = tsl_text(n);
  JSValue built = JS_Eval(cx, src.c_str(), src.size(), name,
                          JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
  if (JS_IsException(built)) return nullptr;
  auto* m = (JSModuleDef*)JS_VALUE_GET_PTR(built);
  JS_FreeValue(cx, built);
  return m;
}

void tsl_rejected(JSContext* cx, JSValueConst, JSValueConst reason,
                  bool handled, void* held) {
  TslRun& run = *(TslRun*)held;
  if (handled || !run.rejected.empty()) return;
  const char* s = JS_ToCString(cx, reason);
  run.rejected = s ? s : "?";
  if (s) JS_FreeCString(cx, s);
}

std::string tsl_global(JSContext* cx, JSValue g, const char* name) {
  JSValue v = JS_GetPropertyStr(cx, g, name);
  const char* s = JS_IsString(v) ? JS_ToCString(cx, v) : nullptr;
  const std::string out = s ? s : "";
  if (s) JS_FreeCString(cx, s);
  JS_FreeValue(cx, v);
  return out;
}

}  // namespace

bool tsl_shelf(const std::string& three, const std::string& writers,
               const std::string& code, const std::string& name,
               std::string& effect, std::string& points, std::string& why) {
  TslRun run{three, code, {}};
  // import a, { b, c as d } from 'module': the names asked of each module.
  static const std::regex imports(
      R"(import\s+(?:[\w$]+\s*,\s*)?\{([^}]*)\}\s*from\s*['"]([^'"]+)['"])");
  static const std::regex one(R"(([\w$]+)(?:\s+as\s+[\w$]+)?)");
  for (std::sregex_iterator i(code.begin(), code.end(), imports), end; i != end;
       ++i) {
    const std::string list = (*i)[1].str();
    std::string& names = run.absent[kAbsent + (*i)[2].str() + ">"];
    for (std::sregex_iterator j(list.begin(), list.end(), one); j != end; ++j)
      if (names.find(" " + (*j)[1].str() + "=") == std::string::npos)
        names += "export const " + (*j)[1].str() + "=any;";
  }
  JSRuntime* rt = JS_NewRuntime();
  JSContext* cx = JS_NewContext(rt);
  JS_SetModuleLoaderFunc(rt, tsl_name, tsl_load, &run);
  JS_SetHostPromiseRejectionTracker(rt, tsl_rejected, &run);
  const std::string by =
      ": pasted three.js Shading Language, by three.js's own builder "
      "(engine/community/three/tsl_shelf.h)";
  // The page is stood in before the code's module is run: its imports of
  // three.js are the same modules from_page.js patched.
  const std::string driver =
      "import { stand, drawnMesh, made } from '" +
      (std::filesystem::path(writers) / "from_page.js").string() +
      "';\ntry {\n  stand();\n  await import('" + kPasted +
      "');\n  const mesh = drawnMesh();\n"
      "  if (!mesh) globalThis.__why = 'the code draws no mesh with a node "
      "material';\n  else {\n    const t = made(mesh, ['// ' + __name + __by, "
      "'// --label:Generate'], ['// ' + __name + ' Points' + __by, "
      "'// --label:3d']);\n    globalThis.__effect = t.effect || '';\n"
      "    globalThis.__points = t.points || '';\n  }\n"
      "} catch (e) { globalThis.__why = String(e) + ' ' + (e.stack || ''); }\n";
  JSValue g = JS_GetGlobalObject(cx);
  JS_SetPropertyStr(cx, g, "__name", JS_NewString(cx, name.c_str()));
  JS_SetPropertyStr(cx, g, "__by", JS_NewString(cx, by.c_str()));
  JSValue ran = JS_Eval(cx, driver.c_str(), driver.size(), "<tsl to shelf>",
                        JS_EVAL_TYPE_MODULE);
  for (JSContext* job; JS_ExecutePendingJob(rt, &job) > 0;) {
  }
  why.clear();
  if (JS_IsException(ran)) {
    JSValue e = JS_GetException(cx);
    const char* s = JS_ToCString(cx, e);
    why = std::string("the code's module: ") + (s ? s : "?");
    JS_FreeCString(cx, s), JS_FreeValue(cx, e);
  } else
    why = tsl_global(cx, g, "__why");
  if (!why.empty() && !run.rejected.empty()) why += ": " + run.rejected;
  effect = tsl_global(cx, g, "__effect"),
  points = tsl_global(cx, g, "__points");
  if (why.empty() && effect.empty() && points.empty())
    why = "the mesh's material has no colorNode and no positionNode";
  JS_FreeValue(cx, ran), JS_FreeValue(cx, g);
  JS_FreeContext(cx), JS_FreeRuntime(rt);
  return why.empty();
}

}  // namespace motolii
