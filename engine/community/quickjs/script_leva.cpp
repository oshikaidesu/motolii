#include "community/quickjs/script_leva.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <map>
#include <string>

#include <quickjs.h>

const char* leva_prelude = "function folder(schema, settings) { return { __folder: true, schema: schema, settings: settings || {} }; }";

namespace {

// JavaScript source of a function that converts the parameter object into header lines.
// A folder becomes a group named by its key. A color becomes three numbers named _x, _y and
// _z, each from 0 to 1 and labeled r, g and b, as an ISF color is, so the card shows them as
// one color. A missing step is computed as normalize() in leva's Number plugin computes it.
const char* leva_told = R"((function (all) {
  var lines = [];
  function digits(x) { var n = Math.abs(+String(x).replace('.', '')); if (n === 0) return 0.01; while (n !== 0 && n % 10 === 0) n /= 10;
    return Math.max(Math.pow(10, Math.floor(Math.log10(Math.abs(x))) - (Math.floor(Math.log(n) / Math.LN10) + 1)), 0.001); }   // (leva's utils/math.ts getStep)
  function stepOf(v, min, max, step) {   // (leva's plugins/Number/number-plugin.ts normalize)
    if (!step) {
      if (isFinite(min)) step = isFinite(max) ? +(Math.abs(max - min) / 100).toPrecision(1) : +(Math.abs(v - min) / 100).toPrecision(1);
      else if (isFinite(max)) step = +(Math.abs(max - v) / 100).toPrecision(1);
    }
    return step || digits(v) / 10;
  }
  function nice(name) {   // (a key shown as Godot's inspector shows a property: String::capitalize, core/string/ustring.cpp)
    var up = function (c) { return c !== c.toLowerCase(); }, low = function (c) { return c !== c.toUpperCase(); }, digit = function (c) { return c >= '0' && c <= '9'; };
    var out = '', start = 0;
    for (var i = 1; i < name.length; i++) {   // (_separate_compound_words: aA, AAa, 2Aa, 2aa, A2, a2)
      var p = name[i - 1], c = name[i], next = name[i + 1] || '';
      if ((low(p) && up(c)) || ((up(p) || digit(p)) && up(c) && low(next)) || (digit(p) && low(c) && low(next)) || ((up(p) || low(p)) && digit(c)))
        out += name.substring(start, i) + ' ', start = i;
    }
    out = (out + name.substring(start)).replace(/[\s_-]/g, ' ').toLowerCase().trim();
    return out.split(' ').filter(function (w) { return w.length > 0; }).map(function (w) { return w[0].toUpperCase() + w.substring(1); }).join(' ');
  }
  function one(name, v, fold) {
    if (v && v.__folder) {
      lines.push('// --group:' + name);
      for (var n in v.schema) one(n, v.schema[n], name);
      lines.push(fold ? '// --group:' + fold : '// --group');
      return;
    }
    var s = v !== null && typeof v === 'object' && !Array.isArray(v) ? v : { value: v }, x = s.value, label = s.label || nice(name);   // (leva's own label: as written)
    if (s.options) {
      var words = Array.isArray(s.options) ? s.options.slice() : Object.keys(s.options).map(function (k) { return s.options[k]; });
      var at = words.indexOf(x);
      if (at > 0) words.unshift(words.splice(at, 1)[0]);   // (as it comes: the head's first word)
      lines.push('// --select@' + name + ':' + label + ',' + words.join(','));
    } else if (typeof x === 'boolean') lines.push('// --check@' + name + ':' + label + ',' + (x ? 1 : 0));
    else if (typeof x === 'string' && /^#[0-9a-f]{6}$/i.test(x))
      ['r', 'g', 'b'].forEach(function (c, i) { lines.push('// --track@' + name + '_' + 'xyz'[i] + ':' + label + ' ' + c + ',0,1,' + parseInt(x.substr(1 + 2 * i, 2), 16) / 255 + ',0.001'); });
    else if (typeof x === 'number') {
      var lo = typeof s.min === 'number' ? s.min : typeof s.max === 'number' ? Math.min(s.max - 10, x) : Math.min(0, x);
      var hi = typeof s.max === 'number' ? s.max : Math.max(lo + 10, x);
      lines.push('// --track@' + name + ':' + label + ',' + lo + ',' + hi + ',' + x + ',' + stepOf(x, s.min, s.max, s.step));
    }
  }
  for (var n in all) one(n, all[n], '');
  return lines.join('\n');
}))";

}  // namespace

std::string leva_head(const std::string& src, std::string* trouble) {
    size_t open = std::string::npos;
    // Find the first declaration that is outside comments and strings.
    for (size_t i = 0; i < src.size() && open == std::string::npos; ++i) {
        if (src.compare(i, 2, "//") == 0) { i = src.find('\n', i); if (i == std::string::npos) break; continue; }
        if (src.compare(i, 2, "/*") == 0) { i = src.find("*/", i + 2); if (i == std::string::npos) break; ++i; continue; }
        if (src[i] == '"' || src[i] == '\'' || src[i] == '`') { const char q = src[i]; for (++i; i < src.size() && src[i] != q; ++i) if (src[i] == '\\') ++i; continue; }
        for (const char* decl : {"const", "let", "var"}) {
            const size_t n = strlen(decl);
            if (src.compare(i, n, decl) != 0 || (i > 0 && (std::isalnum((unsigned char)src[i - 1]) || src[i - 1] == '_' || src[i - 1] == '$'))) continue;
            size_t j = i + n;
            if (j >= src.size() || !std::isspace((unsigned char)src[j])) continue;
            while (j < src.size() && std::isspace((unsigned char)src[j])) ++j;
            if (src.compare(j, 5, "knobs") != 0) continue;
            j += 5;
            while (j < src.size() && std::isspace((unsigned char)src[j])) ++j;
            if (j >= src.size() || src[j] != '=') continue;
            for (++j; j < src.size() && std::isspace((unsigned char)src[j]); ++j) {}
            if (j < src.size() && src[j] == '{') open = j;
        }
    }
    if (open == std::string::npos) return "";
    int deep = 0;
    size_t close = open;
    // Find the matching closing brace, skipping strings and comments.
    for (; close < src.size(); ++close) {
        const char c = src[close];
        if (src.compare(close, 2, "//") == 0) { close = src.find('\n', close); if (close == std::string::npos) return ""; continue; }
        if (src.compare(close, 2, "/*") == 0) { close = src.find("*/", close + 2); if (close == std::string::npos) return ""; ++close; continue; }
        if (c == '"' || c == '\'' || c == '`') { for (++close; close < src.size() && src[close] != c; ++close) if (src[close] == '\\') ++close; continue; }
        if (c == '{') ++deep;
        else if (c == '}' && --deep == 0) break;
    }
    if (close >= src.size()) return "";
    const std::string js = std::string(leva_prelude) + ";\n" + leva_told + "(" + src.substr(open, close - open + 1) + ")";
    JSRuntime* rt = JS_NewRuntime();
    JSContext* cx = JS_NewContext(rt);
    JSValue out = JS_Eval(cx, js.c_str(), js.size(), "knobs", JS_EVAL_TYPE_GLOBAL);
    std::string head;
    if (JS_IsException(out)) {
        JSValue e = JS_GetException(cx);
        if (const char* said = JS_ToCString(cx, e)) { if (trouble) *trouble = said; JS_FreeCString(cx, said); }
        JS_FreeValue(cx, e);
    } else if (const char* said = JS_ToCString(cx, out)) head = said, JS_FreeCString(cx, said);
    JS_FreeValue(cx, out);
    JS_FreeContext(cx), JS_FreeRuntime(rt);
    return head;
}

void leva_colours(JSContext* cx, JSValue k, const std::map<std::string, double>& numbers, const std::map<std::string, std::string>& words) {
    for (const auto& [name, v] : numbers) {
        const std::string base = name.size() > 2 && name.compare(name.size() - 2, 2, "_x") == 0 ? name.substr(0, name.size() - 2) : "";
        const auto g = numbers.find(base + "_y"), b = numbers.find(base + "_z");
        if (base.empty() || g == numbers.end() || b == numbers.end() || numbers.count(base) || words.count(base)) continue;
        const auto byte = [](double c) { return (int)std::lround(std::clamp(c, 0.0, 1.0) * 255); };
        char hex[8];
        std::snprintf(hex, sizeof hex, "#%02x%02x%02x", byte(v), byte(g->second), byte(b->second));
        JS_SetPropertyStr(cx, k, base.c_str(), JS_NewString(cx, hex));
    }
}
