#include "community/quickjs/script_leva.h"

#include <quickjs.h>

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <map>
#include <string>

#include "base/file_read.h"
#include "shelf/shelf_folders.h"

namespace motolii {

const char* leva_prelude =
    "function folder(schema, settings) { return { __folder: true, schema: "
    "schema, settings: settings || {} }; }";

namespace {
// leva_told.js sits beside this file and is read by leva_head when the knob
// object is converted into header lines. The engine ships no leva-specific
// JavaScript as C++ string literals: the source is that .js file.
}  // namespace

std::string leva_head(const std::string& src, std::string* trouble) {
  size_t open = std::string::npos;
  // Find the first declaration that is outside comments and strings.
  for (size_t i = 0; i < src.size() && open == std::string::npos; ++i) {
    if (src.compare(i, 2, "//") == 0) {
      i = src.find('\n', i);
      if (i == std::string::npos) break;
      continue;
    }
    if (src.compare(i, 2, "/*") == 0) {
      i = src.find("*/", i + 2);
      if (i == std::string::npos) break;
      ++i;
      continue;
    }
    if (src[i] == '"' || src[i] == '\'' || src[i] == '`') {
      const char q = src[i];
      for (++i; i < src.size() && src[i] != q; ++i)
        if (src[i] == '\\') ++i;
      continue;
    }
    for (const char* decl : {"const", "let", "var"}) {
      const size_t n = strlen(decl);
      if (src.compare(i, n, decl) != 0 ||
          (i > 0 && (std::isalnum((unsigned char)src[i - 1]) ||
                     src[i - 1] == '_' || src[i - 1] == '$')))
        continue;
      size_t j = i + n;
      if (j >= src.size() || !std::isspace((unsigned char)src[j])) continue;
      while (j < src.size() && std::isspace((unsigned char)src[j])) ++j;
      if (src.compare(j, 5, "knobs") != 0) continue;
      j += 5;
      while (j < src.size() && std::isspace((unsigned char)src[j])) ++j;
      if (j >= src.size() || src[j] != '=') continue;
      for (++j; j < src.size() && std::isspace((unsigned char)src[j]); ++j) {
      }
      if (j < src.size() && src[j] == '{') open = j;
    }
  }
  if (open == std::string::npos) return "";
  int deep = 0;
  size_t close = open;
  // Find the matching closing brace, skipping strings and comments.
  for (; close < src.size(); ++close) {
    const char c = src[close];
    if (src.compare(close, 2, "//") == 0) {
      close = src.find('\n', close);
      if (close == std::string::npos) return "";
      continue;
    }
    if (src.compare(close, 2, "/*") == 0) {
      close = src.find("*/", close + 2);
      if (close == std::string::npos) return "";
      ++close;
      continue;
    }
    if (c == '"' || c == '\'' || c == '`') {
      for (++close; close < src.size() && src[close] != c; ++close)
        if (src[close] == '\\') ++close;
      continue;
    }
    if (c == '{')
      ++deep;
    else if (c == '}' && --deep == 0)
      break;
  }
  if (close >= src.size()) return "";
  const std::string told =
      read_text(doc_engine("community/quickjs/leva_told.js"));
  const std::string js = std::string(leva_prelude) + ";\n" + told + "(" +
                         src.substr(open, close - open + 1) + ")";
  JSRuntime* rt = JS_NewRuntime();
  JSContext* cx = JS_NewContext(rt);
  JSValue out =
      JS_Eval(cx, js.c_str(), js.size(), "knobs", JS_EVAL_TYPE_GLOBAL);
  std::string head;
  if (JS_IsException(out)) {
    JSValue e = JS_GetException(cx);
    if (const char* said = JS_ToCString(cx, e)) {
      if (trouble) *trouble = said;
      JS_FreeCString(cx, said);
    }
    JS_FreeValue(cx, e);
  } else if (const char* said = JS_ToCString(cx, out))
    head = said, JS_FreeCString(cx, said);
  JS_FreeValue(cx, out);
  JS_FreeContext(cx), JS_FreeRuntime(rt);
  return head;
}

void leva_colours(JSContext* cx, JSValue k,
                  const std::map<std::string, double>& numbers,
                  const std::map<std::string, std::string>& words) {
  for (const auto& [name, v] : numbers) {
    const std::string base =
        name.size() > 2 && name.compare(name.size() - 2, 2, "_x") == 0
            ? name.substr(0, name.size() - 2)
            : "";
    const auto g = numbers.find(base + "_y"), b = numbers.find(base + "_z");
    if (base.empty() || g == numbers.end() || b == numbers.end() ||
        numbers.count(base) || words.count(base))
      continue;
    const auto byte = [](double c) {
      return (int)std::lround(std::clamp(c, 0.0, 1.0) * 255);
    };
    char hex[8];
    std::snprintf(hex, sizeof hex, "#%02x%02x%02x", byte(v), byte(g->second),
                  byte(b->second));
    JS_SetPropertyStr(cx, k, base.c_str(), JS_NewString(cx, hex));
  }
}

}  // namespace motolii
