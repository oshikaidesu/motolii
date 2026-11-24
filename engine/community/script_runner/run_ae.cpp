// AE expression setup: loads lottie-web's ExpressionManager (pre-compiled to
// QuickJS bytecode) so that AE.compile() / AE.run() work in any script.
// AGENTS.md principle 2: existing implementations run as they are.
#include "community/script_runner/run_ae.h"

#include <cstdio>
#include <cstring>
#include <map>
#include <string>

#include "community/after_effects/lottie_bytecode.h"
#include "community/after_effects/lottie_canonical.h"
#include "community/script_runner/script_runner.h"
#include "community/script_runner/script_runner_own.h"

namespace motolii {

void setup_ae_expressions(JSRuntime* rt, JSContext* cx, std::string& trouble) {
  // Module loader: looks up the requested canonical name in the pre-compiled
  // bytecode table and returns its JSModuleDef. Every lottie module the shim
  // reaches was built into the table by lottie_precompile; a miss means the
  // graph changed since the build.
  auto loader = +[](JSContext* cx, const char* name, void*) -> JSModuleDef* {
    const std::string n = name;
    for (std::size_t i = 0; i < kLottieBytecodeCount; ++i) {
      if (n == kLottieBytecode[i].name) {
        JSValue m =
            JS_ReadObject(cx, kLottieBytecode[i].data, kLottieBytecode[i].size,
                          JS_READ_OBJ_BYTECODE);
        if (JS_IsException(m)) {
          std::fprintf(stderr, "lottie: JS_ReadObject failed for %s\n", name);
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
  JS_SetModuleLoaderFunc(rt, lottie_canonical, loader, nullptr);
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
    JS_FreeValue(cx, JS_Eval(cx, kDomStubs, std::strlen(kDomStubs),
                             "<lottie_dom_stubs>", JS_EVAL_TYPE_GLOBAL));
  }
  const LottieBytecodeEntry* shim = nullptr;
  for (std::size_t i = 0; i < kLottieBytecodeCount; ++i)
    if (std::string(kLottieBytecode[i].name) == kLottieShimCanonical) {
      shim = &kLottieBytecode[i];
      break;
    }
  if (!shim) {
    trouble = "lottie_shim bytecode not generated (re-run cmake)";
    return;
  }
  auto describe = [&](JSValue v) -> std::string {
    if (!JS_IsException(v) && !JS_IsError(v)) return "?";
    JSValue e = JS_IsException(v) ? JS_GetException(cx) : JS_DupValue(cx, v);
    const char* s = JS_ToCString(cx, e);
    std::string out = s ? s : "?";
    JSValue st = JS_GetPropertyStr(cx, e, "stack");
    if (!JS_IsUndefined(st) && !JS_IsException(st)) {
      const char* ss = JS_ToCString(cx, st);
      if (ss) {
        out += "\n";
        out += ss;
      }
      JS_FreeCString(cx, ss);
    }
    JS_FreeValue(cx, st);
    JS_FreeCString(cx, s);
    JS_FreeValue(cx, e);
    return out;
  };
  JSValue m = JS_ReadObject(cx, shim->data, shim->size, JS_READ_OBJ_BYTECODE);
  if (JS_IsException(m)) {
    trouble = "lottie_shim: JS_ReadObject failed: " + describe(m);
    return;
  }
  // JS_EvalFunction resolves the shim's imports (calling the loader for
  // each) and runs every reached module's top-level code in dependency
  // order.
  JSValue ran = JS_EvalFunction(cx, m);
  if (JS_IsException(ran))
    trouble = std::string("lottie_shim threw at load: ") + describe(ran);
  JS_FreeValue(cx, ran);
  for (JSContext* job; JS_ExecutePendingJob(rt, &job) > 0;) {
  }
}

// ---------------------------------------------------------------------------
// Script::text(): evaluates sourceText(t, k, value), the AE expression that
// says what a text layer reads.
// ---------------------------------------------------------------------------

std::string Script::text(double t, const std::map<std::string, double>& numbers,
                         const std::map<std::string, std::string>& words,
                         const std::string& typed) {
  if (!says_text() || !ok()) return typed;
  JSContext* cx = own->cx;
  JS_UpdateStackTop(own->rt);
  parameters(numbers, words);
  {
    JSValue g = JS_GetGlobalObject(cx);
    JS_SetPropertyStr(cx, g, "__hostK", JS_DupValue(cx, own->parameters));
    const auto it = numbers.find("time");
    JS_SetPropertyStr(cx, g, "__hostT",
                      JS_NewFloat64(cx, it != numbers.end() ? it->second : t));
    JS_FreeValue(cx, g);
  }
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
    if (const char* got = JS_ToCString(cx, out))
      said = got, JS_FreeCString(cx, got);
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

}  // namespace motolii
