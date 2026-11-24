// Cavalry dialect: bare-object wrapping and whole-file PointCloud execution.
#include "community/script_runner/run_cavalry.h"

#include <string>
#include <string_view>

namespace motolii {

std::string wrap_cavalry_expression(JSContext* cx, const std::string& src,
                                    const std::string& file) {
  if (src.empty()) return src;
  // Strip leading comments and whitespace to find the first meaningful char.
  auto strip_head = [](std::string_view s) {
    while (!s.empty()) {
      char c = s.front();
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
        s.remove_prefix(1);
        continue;
      }
      if (s.size() >= 2 && s[0] == '/' && s[1] == '/') {
        auto nl = s.find('\n');
        if (nl == std::string_view::npos) {
          s.remove_prefix(s.size());
          break;
        }
        s.remove_prefix(nl + 1);
        continue;
      }
      if (s.size() >= 2 && s[0] == '/' && s[1] == '*') {
        auto end = s.find("*/", 2);
        if (end == std::string_view::npos) {
          s.remove_prefix(s.size());
          break;
        }
        s.remove_prefix(end + 2);
        continue;
      }
      break;
    }
    return s;
  };
  const auto head = strip_head(src);
  if (head.empty() || head.front() != '{' ||
      src.find("function each") != std::string::npos)
    return src;
  const std::string wrapped =
      "function each(index, count, time, value) { return (" + src + "\n); }";
  JSValue told = JS_Eval(cx, wrapped.c_str(), wrapped.size(), file.c_str(),
                         JS_EVAL_TYPE_GLOBAL | JS_EVAL_FLAG_COMPILE_ONLY);
  if (JS_IsException(told)) {
    JS_FreeValue(cx, JS_GetException(cx));
    return src;  // (the wrapped version is a syntax error: run the original,
                 // so the writer sees the real error)
  }
  JS_FreeValue(cx, told);
  return wrapped;
}

void run_cavalry_whole(JSContext* cx, JSRuntime* rt, const std::string& src,
                       const std::string& file,
                       const std::map<std::string, double>& numbers,
                       const std::map<std::string, std::string>& words, int n,
                       double t, double unit, std::vector<ScriptCopy>& all,
                       std::string& trouble) {
  JS_UpdateStackTop(rt);
  JSValue g = JS_GetGlobalObject(cx);
  for (const auto& [name, v] : numbers)
    JS_SetPropertyStr(cx, g, name.c_str(), JS_NewFloat64(cx, v));
  for (const auto& [name, w] : words)
    JS_SetPropertyStr(cx, g, name.c_str(), JS_NewString(cx, w.c_str()));
  const auto fps_it = numbers.find("fps");
  const double fps =
      fps_it != numbers.end() && fps_it->second > 0.0 ? fps_it->second : 60.0;
  JS_SetPropertyStr(cx, g, "time", JS_NewFloat64(cx, t)),
      JS_SetPropertyStr(cx, g, "frame", JS_NewFloat64(cx, t * fps));
  JS_SetPropertyStr(cx, g, "__hostT", JS_NewFloat64(cx, t));
  JS_FreeValue(cx, g);
  JSValue out =
      JS_Eval(cx, src.c_str(), src.size(), file.c_str(), JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(out)) {
    JSValue e = JS_GetException(cx);
    const char* s = JS_ToCString(cx, e);
    trouble = std::string("the script threw: ") + (s ? s : "?");
    JS_FreeCString(cx, s), JS_FreeValue(cx, e);
    return;
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
    all[(size_t)i].size = 0;  // (copies past the cloud's last point: not seen)
  JS_FreeValue(cx, out);
}

}  // namespace motolii
