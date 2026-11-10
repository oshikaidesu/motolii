// script.h's groundwork: shelf files found, a sketch's drawing lines marked,
// the header read for parameters, and anime.js's easings on QuickJS-ng.
#include "community/quickjs/script.h"

#include <dlfcn.h>
#include <quickjs.h>
#include <sys/stat.h>

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <istream>
#include <map>
#include <mutex>
#include <set>
#include <sstream>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

namespace motolii {

static std::vector<std::string> split(const std::string& s, char by) {
  std::vector<std::string> out;
  std::stringstream in(s);
  for (std::string one; std::getline(in, one, by);) {
    const size_t a = one.find_first_not_of(' '), b = one.find_last_not_of(' ');
    out.push_back(a == std::string::npos ? "" : one.substr(a, b - a + 1));
  }
  return out;
}

std::string script_shelf_file(const std::string& file) {
  std::error_code wrong;
  if (file.find('/') == std::string::npos ||
      std::filesystem::exists(file, wrong))
    return file;
  // For each shelf kind, a map from file name to full path. Filled on first
  // use.
  static std::map<std::string, std::map<std::string, std::string>> by;
  for (std::filesystem::path p = std::filesystem::path(file).parent_path();
       !p.empty() && p != p.parent_path(); p = p.parent_path()) {
    const std::string kind = p.filename().string();
    if (kind != "effects" && kind != "create" && kind != "relations" &&
        kind != "expressions" && kind != "solids" && kind != "looks" &&
        kind != "recipes" && kind != "animators")
      continue;
    // A project saved before the shelves were renamed names the old folders:
    // recipes is now create and animators is now expressions.
    const std::string now = kind == "recipes"     ? "create"
                            : kind == "animators" ? "expressions"
                                                  : kind;
    if (!by.count(now)) {
      Dl_info lib{};
      dladdr((const void*)&script_shelf_file, &lib);
      const auto shelf = std::filesystem::weakly_canonical(
                             lib.dli_fname ? lib.dli_fname : ".", wrong)
                             .parent_path()
                             .parent_path()
                             .parent_path() /
                         "shelves" / now;
      auto& names = by[now];
      for (const auto& e :
           std::filesystem::recursive_directory_iterator(shelf, wrong))
        names.emplace(e.path().filename().string(), e.path().string());
    }
    const auto at =
        by[now].find(std::filesystem::path(file).filename().string());
    return at == by[now].end() ? file : at->second;
  }
  return file;
}
std::vector<std::string> script_files(const std::string& word) {
  std::vector<std::string> all;
  std::istringstream each(word);
  const auto ends = [](const std::string& w) {
    if (w.find(".anm2") != std::string::npos ||
        w.find(".obj2") != std::string::npos)
      return true;
    for (const char* e : {".wgsl", ".fs", ".js", ".mjs", ".json", ".am"})
      if (w.size() >= strlen(e) &&
          w.compare(w.size() - strlen(e), std::string::npos, e) == 0)
        return true;
    return false;
  };
  for (std::string w; each >> w;) {
    if (!all.empty() && all.back().find('/') != std::string::npos &&
        !ends(all.back()))
      all.back() += " " + w;
    else
      all.push_back(w);
  }
  for (std::string& f : all) f = script_shelf_file(f);
  return all;
}

// (what stands in a string or a comment is not a call; a name after a dot is
// another canvas's, a createGraphics': image() says where that shows; a name
// followed by a { is a method of the sketch's own)
std::string sketch_marked(const std::string& src,
                          std::vector<SketchLine>* lines) {
  static const std::set<std::string> draws{
      "rect",  "square",     "ellipse",    "circle",    "arc",    "line",
      "point", "triangle",   "quad",       "bezier",    "curve",  "image",
      "text",  "background", "beginShape", "box",       "sphere", "plane",
      "cone",  "cylinder",   "torus",      "ellipsoid", "model"};
  const auto word = [](char c) {
    return std::isalnum((unsigned char)c) || c == '_' || c == '$';
  };
  std::string out, last;
  int line = 1, seen = 0;
  for (size_t i = 0; i < src.size();) {
    const char c = src[i];
    if (c == '\n') ++line;
    if (c == '/' && i + 1 < src.size() && src[i + 1] == '/') {
      const size_t end = std::min(src.find('\n', i), src.size());
      out.append(src, i, end - i), i = end;
    } else if (c == '/' && i + 1 < src.size() && src[i + 1] == '*') {
      const size_t end = std::min(src.find("*/", i + 2), src.size() - 2) + 2;
      line +=
          (int)std::count(src.begin() + (long)i, src.begin() + (long)end, '\n');
      out.append(src, i, end - i), i = end;
    } else if (c == '"' || c == '\'' || c == '`') {
      size_t end = i + 1;
      while (end < src.size() && src[end] != c &&
             (c == '`' || src[end] != '\n'))
        end += src[end] == '\\' ? 2 : 1;
      end = std::min(end + 1, src.size());
      line +=
          (int)std::count(src.begin() + (long)i, src.begin() + (long)end, '\n');
      out.append(src, i, end - i), i = end;
    } else if (word(c)) {
      size_t end = i;
      while (end < src.size() && word(src[end])) ++end;
      const std::string name = src.substr(i, end - i);
      size_t next = end;
      while (next < src.size() && (src[next] == ' ' || src[next] == '\t'))
        ++next;
      const size_t before = out.find_last_not_of(" \t\r\n");
      bool mark = next < src.size() && src[next] == '(' && draws.count(name) &&
                  last != "function" &&
                  (before == std::string::npos || out[before] != '.');
      if (mark) {
        int deep = 0;
        size_t close = next;
        for (; close < src.size(); ++close) {
          if (src[close] == '(')
            ++deep;
          else if (src[close] == ')' && --deep == 0)
            break;
        }
        size_t after = close + 1;
        while (after < src.size() && std::isspace((unsigned char)src[after]))
          ++after;
        mark = after >= src.size() || src[after] != '{';
      }
      if (mark) {
        out += "__at(" + std::to_string(line) + "," + name +
               ")";  // (a word as it was, so a line before it with no semicolon
                     // still ends there)
        if (lines && seen != line) lines->push_back({line, name}), seen = line;
      } else
        out += name;
      last = name, i = end;
    } else {
      if (!std::isspace((unsigned char)c)) last.clear();
      out += c, ++i;
    }
  }
  return out;
}
std::vector<ScriptParameter> script_header_parameters(std::istream& from) {
  std::vector<ScriptParameter> parameters;
  std::string
      group;  // (AviUtl2's --group:Name[,open] gathers the parameters after it,
              // a bare --group ends it: docs/design/aviutl2_converter.md)
  for (std::string line; std::getline(from, line);) {
    if (line.rfind("//", 0) != 0) {
      if (line.find_first_not_of(" \t\r") == std::string::npos) continue;
      break;
    }  // (the head ends where code begins)
    if (const size_t g = line.find_first_not_of(" \t", 2);
        g != std::string::npos && line.compare(g, 7, "--group") == 0 &&
        (g + 7 == line.size() || line[g + 7] == ':' || line[g + 7] == '\r')) {
      const size_t colon = line.find(':', g);
      group = line.substr(colon == std::string::npos ? line.size() : colon + 1);
      group = group.substr(
          0, group.find(','));  // (its open or closed at first: Motolii's fold
                                // is closed at first)
      group.erase(0, group.find_first_not_of(" \t")),
          group.erase(group.find_last_not_of(" \t\r") + 1);
      continue;
    }
    const size_t dash = line.find("--"), at = line.find('@'),
                 colon = line.find(':');
    if (dash == std::string::npos || at == std::string::npos ||
        colon == std::string::npos || !(dash < at && at < colon))
      continue;
    ScriptParameter k;
    k.kind = line.substr(dash + 2, at - dash - 2),
    k.name = line.substr(at + 1, colon - at - 1);
    if (k.kind == "macro") {  // (label[,as it comes] -> name low high, name low
                              // high: script.h)
      const size_t to = line.find("->", colon);
      const std::vector<std::string> head = split(
          line.substr(colon + 1, to == std::string::npos ? std::string::npos
                                                         : to - colon - 1),
          ',');
      if (head.empty() || head[0].empty() || k.name.empty() ||
          to == std::string::npos)
        continue;
      for (const std::string& one : split(line.substr(to + 2), ',')) {
        std::istringstream w(one);
        ScriptParameter::Turned t;
        if (w >> t.name >> t.low >> t.high) k.turns.push_back(t);
      }
      k.kind = "track", k.label = head[0], k.low = 0, k.high = 1, k.step = 0.01,
      k.usual = head.size() >= 2 ? std::atof(head[1].c_str()) : 0;
      parameters.push_back(
          k);  // (in no group, wherever its line is: a macro stands out)
      continue;
    }
    const std::vector<std::string> said = split(line.substr(colon + 1), ',');
    if (said.empty() || k.name.empty()) continue;
    k.label = said[0];
    if (k.kind == "track" && said.size() >= 4) {
      k.low = std::atof(said[1].c_str()), k.high = std::atof(said[2].c_str()),
      k.usual = std::atof(said[3].c_str());
      k.step = said.size() >= 5 ? std::atof(said[4].c_str()) : 0;
    } else if (k.kind == "check") {
      k.low = 0, k.high = 1,
      k.usual = said.size() >= 2 ? std::atof(said[1].c_str()) : 0, k.step = 1;
    } else if (k.kind ==
               "picture") {  // (another thing's picture read as one of its
                             // images: the thing, by its number)
      k.low = 0, k.high = 1e9, k.usual = 0, k.step = 1;
    } else if (k.kind == "sound" &&
               said.size() >=
                   3) {  // (another thing's sound read as an ISF audio input:
                         // the thing, by its number; fft or wave, how many)
      k.low = 0, k.high = 1e9, k.usual = 0, k.step = 1,
      k.words = said[1] + " " + said[2];
    } else if (k.kind == "select" && said.size() >= 2) {
      for (size_t i = 1; i < said.size(); ++i)
        k.words += (i > 1 ? " " : "") + said[i];
    } else
      continue;
    k.group = group;
    parameters.push_back(k);
  }
  // (a macro first on its card, Ableton's above the Rack; what it turns folded
  // away, said to be turned)
  std::stable_partition(
      parameters.begin(), parameters.end(),
      [](const ScriptParameter& k) { return !k.turns.empty(); });
  for (const ScriptParameter& m : parameters)
    for (const ScriptParameter::Turned& t : m.turns)
      for (ScriptParameter& k : parameters)
        if (k.name == t.name && k.turns.empty() && k.by.empty()) {
          k.by = m.name, k.label += " ← " + m.label;
          if (k.group.empty()) k.group = "Advanced";
        }
  return parameters;
}

void script_first(const std::string& file,
                  std::vector<ScriptParameter>& parameters) {
  static std::mutex hold;
  static std::map<std::string,
                  std::pair<long long, std::map<std::string,
                                                std::map<std::string, double>>>>
      read;  // (each folder's first.tsv, as it was when last written)
  const size_t slash = file.find_last_of('/');
  if (slash == std::string::npos) return;
  const std::string table = file.substr(0, slash) + "/first.tsv",
                    name = file.substr(slash + 1);
  struct stat st{};
  const long long when =
      stat(table.c_str(), &st) == 0
          ? (long long)st.st_mtimespec.tv_sec * 1000000000LL +
                st.st_mtimespec.tv_nsec
          : -1;
  std::lock_guard<std::mutex> one(hold);
  auto& [stamp, values] = read[table];
  if (stamp != when) {
    stamp = when, values.clear();
    std::ifstream in(table);
    for (std::string line; std::getline(in, line);) {
      const std::vector<std::string> w = split(line, '\t');
      if (w.size() >= 3 && !w[0].empty() && w[0][0] != '#')
        values[w[0]][w[1]] = std::atof(w[2].c_str());
    }
  }
  const auto own = values.find(name);
  if (own == values.end()) return;
  for (ScriptParameter& k : parameters)
    if (const auto v = own->second.find(k.name); v != own->second.end())
      k.usual = v->second;
}

// anime.js's easings (third_party/anime, MIT) run as they are: one QuickJS
// context for the whole library, the bundle read once from where the library
// keeps it, and each ease said made once and kept by what it says. irregular()
// draws its points with Math.random: while an ease is made, anime.js's own
// seeded one stands in, its seed from the words, so the same words give the
// same curve every time.
static const char anime_prelude[] = R"(
var __eases = {};
function __ease(said) {
  var built = __eases[said];
  if (built) return built;
  var seed = 0;
  for (var i = 0; i < said.length; i++) seed = (seed * 31 + said.charCodeAt(i)) | 0;
  var r = anime.utils.createSeededRandom(seed), ownRandom = Math.random;
  Math.random = function () { return r(0, 1, 6); };
  try { with (anime.eases) { with (anime) { built = eval('(' + said + ')'); } } } finally { Math.random = ownRandom; }   // (anime's own linear(), steps()... before eases.linear)
  if (built && typeof built.ease === 'function') built = built.ease;   // (a spring: its ease)
  if (typeof built !== 'function') throw new Error(said + ': not an ease of anime.js');
  return __eases[said] = built;
}
function __ease_at(said, u) { return __ease(said)(Math.min(1, Math.max(0, u))); }
)";
double anime_ease(const std::string& bundle, const std::string& said, double u,
                  std::string* trouble) {
  static std::mutex one;
  static JSRuntime* rt = nullptr;
  static JSContext* cx = nullptr;
  static JSValue at = JS_UNDEFINED;
  static std::string why;
  std::lock_guard<std::mutex> held(one);
  if (!rt) {
    rt = JS_NewRuntime(), cx = JS_NewContext(rt);
    std::ifstream in(bundle);
    std::stringstream code;
    code << "globalThis.setImmediate = function () { return 0; }; "
            "globalThis.clearImmediate = function () {};\n"
         << in.rdbuf() << anime_prelude;
    const std::string src = code.str();
    JSValue ran =
        JS_Eval(cx, src.c_str(), src.size(), "anime", JS_EVAL_TYPE_GLOBAL);
    if (!in || JS_IsException(ran))
      why = "anime.js is not where it is stored: " + bundle;
    JS_FreeValue(cx, ran);
    JSValue g = JS_GetGlobalObject(cx);
    at = JS_GetPropertyStr(cx, g, "__ease_at");
    JS_FreeValue(cx, g);
  }
  if (!why.empty()) {
    if (trouble) *trouble = why;
    return u;
  }
  JS_UpdateStackTop(rt);  // (asked on whichever thread asks: the hand's on the
                          // stage, the window's to draw a curve. QuickJS
                          // measures its stack from where it last was told)
  JSValue args[2] = {JS_NewStringLen(cx, said.c_str(), said.size()),
                     JS_NewFloat64(cx, u)};
  JSValue out = JS_Call(cx, at, JS_UNDEFINED, 2, args);
  JS_FreeValue(cx, args[0]);
  double v = u;
  if (JS_IsException(out)) {
    JSValue e = JS_GetException(cx);
    const char* s = JS_ToCString(cx, e);
    if (trouble) *trouble = s ? s : "?";
    JS_FreeCString(cx, s), JS_FreeValue(cx, e);
  } else
    JS_ToFloat64(cx, &v, out);
  JS_FreeValue(cx, out);
  return v;
}

}  // namespace motolii
