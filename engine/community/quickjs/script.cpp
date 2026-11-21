// script.h's groundwork: shelf files found, a sketch's drawing lines marked,
// the header read for parameters, and anime.js's easings on QuickJS-ng.
#include "community/quickjs/script.h"

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
#include <regex>
#include <set>
#include <sstream>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

#include "base/file_read.h"
#include "shelf/shelf_folders.h"

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

std::string fx_entry_id(const std::string& entry) {
  if (entry.size() <= 7 || entry[6] != ':') return "";
  for (int i = 0; i < 6; ++i) {
    const char c = entry[i];
    if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))) return "";
  }
  return entry.substr(0, 6);
}

std::string fx_entry_path(const std::string& entry) {
  return fx_entry_id(entry).empty() ? entry : entry.substr(7);
}

std::string script_shelf_file(const std::string& file) {
  std::error_code wrong;
  if (file.find('/') == std::string::npos ||
      std::filesystem::exists(file, wrong))
    return file;
  // For each shelf kind, a map from file name to full path. Filled on first
  // use.
  // The app has more than one engine at work in one process (the workspace's
  // and the tile studio's), each on a thread of its own.
  static std::mutex one;
  std::lock_guard<std::mutex> hold(one);
  static std::map<std::string, std::map<std::string, std::string>> by;
  for (std::filesystem::path p = std::filesystem::path(file).parent_path();
       !p.empty() && p != p.parent_path(); p = p.parent_path()) {
    const std::string kind = p.filename().generic_string();
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
      // Found as doc_folders finds it, so the open app's hot-swapped copy of
      // the library (out/live/) reaches the same shelves.
      const auto shelf =
          (doc_engine("..") / "shelves" / now).lexically_normal();
      auto& names = by[now];
      for (const auto& e :
           std::filesystem::recursive_directory_iterator(shelf, wrong))
        names.emplace(e.path().filename().generic_string(),
                      e.path().generic_string());
    }
    const auto at =
        by[now].find(std::filesystem::path(file).filename().generic_string());
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
    for (const char* e : {".wgsl", ".fs", ".js", ".mjs", ".json", ".am",
                          ".css", ".plugin", ".aex"})
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
  // An effect's own ID stays in front of its file, which is found without it.
  for (std::string& f : all)
    if (const std::string id = fx_entry_id(f); id.empty())
      f = script_shelf_file(f);
    else
      f = id + ":" + script_shelf_file(f.substr(id.size() + 1));
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

namespace {

std::string wgsl_human_label(const std::string& name) {
  std::string out;
  for (size_t i = 0; i < name.size(); ++i) {
    const unsigned char c = (unsigned char)name[i];
    if (c == '_') {
      if (!out.empty() && out.back() != ' ') out += ' ';
      continue;
    }
    if (i > 0 && std::isupper(c) &&
        std::islower((unsigned char)name[i - 1]) && !out.empty() &&
        out.back() != ' ')
      out += ' ';
    out += (out.empty() || out.back() == ' ') ? (char)std::toupper(c) : (char)c;
  }
  return out.empty() ? name : out;
}

std::vector<double> parse_nums(const std::string& args) {
  std::vector<double> out;
  std::stringstream ss(args);
  for (std::string tok; std::getline(ss, tok, ',');) {
    const size_t a = tok.find_first_not_of(" \t\r\n");
    if (a == std::string::npos) continue;
    char* end = nullptr;
    const double v = std::strtod(tok.c_str() + a, &end);
    if (end != tok.c_str() + a) out.push_back(v);
  }
  return out;
}

std::string parse_quoted(const std::string& args) {
  const size_t q1 = args.find('"');
  if (q1 == std::string::npos) return "";
  const size_t q2 = args.find('"', q1 + 1);
  if (q2 == std::string::npos) return "";
  return args.substr(q1 + 1, q2 - q1 - 1);
}

// Finds the byte span (start, end) of the next UI attribute token in `code`
// starting from `pos`, leaving standard WGSL @group(0) bindings untouched.
bool next_wgsl_ui_attr(const std::string& code, size_t from, size_t& start,
                       size_t& end, std::string& attr_name,
                       std::string& attr_args) {
  static const char* const kAttrs[] = {"range", "toggle", "color", "point",
                                       "group", "label",  "auto"};
  for (size_t i = from; i < code.size(); ++i) {
    if (code[i] == '/' && i + 1 < code.size() && code[i + 1] == '/') {
      while (i < code.size() && code[i] != '\n') ++i;
      continue;
    }
    if (code[i] == '/' && i + 1 < code.size() && code[i + 1] == '*') {
      i += 2;
      while (i + 1 < code.size() && !(code[i] == '*' && code[i + 1] == '/'))
        ++i;
      if (i + 1 < code.size()) ++i;
      continue;
    }
    if (code[i] != '@') continue;
    size_t j = i + 1;
    while (j < code.size() &&
           (std::isalnum((unsigned char)code[j]) || code[j] == '_'))
      ++j;
    const std::string name = code.substr(i + 1, j - i - 1);
    bool matched = false;
    for (const char* k : kAttrs)
      if (name == k) matched = true;
    if (!matched) continue;
    size_t k = j;
    while (k < code.size() && (code[k] == ' ' || code[k] == '\t')) ++k;
    bool has_parens = false;
    std::string args;
    size_t close_pos = j;
    if (k < code.size() && code[k] == '(') {
      int depth = 1;
      bool in_str = false;
      size_t p = k + 1;
      while (p < code.size() && depth > 0) {
        if (code[p] == '"' && (p == 0 || code[p - 1] != '\\')) in_str = !in_str;
        if (!in_str) {
          if (code[p] == '(') ++depth;
          else if (code[p] == ')') --depth;
        }
        ++p;
      }
      if (depth != 0) continue;
      has_parens = true;
      args = code.substr(k + 1, p - k - 2);
      close_pos = p;
    }
    // Keep standard WGSL @group(0) intact; only treat @group("Name"), @group(),
    // or bare @group as a UI group directive.
    if (name == "group" && has_parens) {
      const size_t first = args.find_first_not_of(" \t\r\n");
      if (first != std::string::npos && args[first] != '"') continue;
    }
    start = i;
    end = close_pos;
    attr_name = name;
    attr_args = args;
    return true;
  }
  return false;
}

}  // namespace

std::string wgsl_strip_ui_attributes(const std::string& code) {
  std::string out = code;
  size_t pos = 0, start = 0, end = 0;
  std::string name, args;
  while (next_wgsl_ui_attr(out, pos, start, end, name, args)) {
    for (size_t i = start; i < end; ++i)
      if (out[i] != '\n' && out[i] != '\r') out[i] = ' ';
    pos = end;
  }
  return out;
}

std::vector<ScriptParameter> wgsl_attribute_parameters(
    const std::string& code) {
  std::vector<ScriptParameter> out;
  std::smatch um;
  std::string struct_name = "Knobs";
  if (std::regex_search(code, um,
                        std::regex(R"(var\s*<\s*uniform\s*>\s+\w+\s*:\s*(\w+))")))
    struct_name = um[1].str();
  std::smatch sm;
  if (!std::regex_search(
          code, sm,
          std::regex("struct\\s+" + struct_name + "\\s*\\{([^}]*)\\}")))
    return out;
  const std::string body = sm[1].str();

  std::string group, pending_label;
  std::string pending_kind, pending_args;
  size_t pos = 0;
  while (pos < body.size()) {
    while (pos < body.size() && std::isspace((unsigned char)body[pos])) ++pos;
    if (pos >= body.size()) break;
    if (body[pos] == '/' && pos + 1 < body.size() && body[pos + 1] == '/') {
      while (pos < body.size() && body[pos] != '\n') ++pos;
      continue;
    }
    if (body[pos] == '/' && pos + 1 < body.size() && body[pos + 1] == '*') {
      pos += 2;
      while (pos + 1 < body.size() && !(body[pos] == '*' && body[pos + 1] == '/'))
        ++pos;
      if (pos + 1 < body.size()) pos += 2;
      continue;
    }
    if (body[pos] == '@') {
      size_t start = 0, end = 0;
      std::string aname, aargs;
      if (next_wgsl_ui_attr(body, pos, start, end, aname, aargs) &&
          start == pos) {
        if (aname == "group") {
          group = parse_quoted(aargs);
        } else if (aname == "label") {
          pending_label = parse_quoted(aargs);
        } else if (aname == "range" || aname == "toggle" || aname == "color" ||
                   aname == "point") {
          pending_kind = aname;
          pending_args = aargs;
        }
        pos = end;
        continue;
      }
      // Skip any standard WGSL attribute (e.g. @align(16)).
      ++pos;
      while (pos < body.size() &&
             (std::isalnum((unsigned char)body[pos]) || body[pos] == '_'))
        ++pos;
      if (pos < body.size() && body[pos] == '(') {
        int d = 1;
        ++pos;
        while (pos < body.size() && d > 0) {
          if (body[pos] == '(') ++d;
          else if (body[pos] == ')') --d;
          ++pos;
        }
      }
      continue;
    }
    // Parse `fieldName: fieldType,`
    size_t n0 = pos;
    while (pos < body.size() &&
           (std::isalnum((unsigned char)body[pos]) || body[pos] == '_'))
      ++pos;
    const std::string fname = body.substr(n0, pos - n0);
    while (pos < body.size() && std::isspace((unsigned char)body[pos])) ++pos;
    if (fname.empty() || pos >= body.size() || body[pos] != ':') {
      ++pos;
      continue;
    }
    ++pos;
    while (pos < body.size() && std::isspace((unsigned char)body[pos])) ++pos;
    size_t t0 = pos;
    while (pos < body.size() && body[pos] != ',' && body[pos] != ';' &&
           body[pos] != '\n' && body[pos] != '/')
      ++pos;
    std::string ftype = body.substr(t0, pos - t0);
    while (!ftype.empty() && std::isspace((unsigned char)ftype.back()))
      ftype.pop_back();
    if (pos < body.size() && (body[pos] == ',' || body[pos] == ';')) ++pos;

    if (!pending_kind.empty()) {
      const std::string label =
          pending_label.empty() ? wgsl_human_label(fname) : pending_label;
      const auto nums = parse_nums(pending_args);
      if (pending_kind == "range" && nums.size() >= 2) {
        const int vec_n = ftype.rfind("vec2", 0) == 0   ? 2
                          : ftype.rfind("vec3", 0) == 0 ? 3
                          : ftype.rfind("vec4", 0) == 0 ? 4
                                                        : 1;
        const bool is_int = ftype == "i32" || ftype == "u32";
        const double step = nums.size() >= 3 ? nums[2] : (is_int ? 1.0 : 0.01);
        if (vec_n == 1) {
          ScriptParameter k;
          k.name = fname;
          k.label = label;
          k.kind = "track";
          k.low = nums[0];
          k.high = nums[1];
          k.step = step;
          k.usual = nums.size() >= 4 ? nums[3] : k.low;
          k.group = group;
          out.push_back(std::move(k));
        } else {
          const char* comp_name[4] = {"_x", "_y", "_z", "_w"};
          const char* comp_lbl[4] = {" X", " Y", " Z", " W"};
          for (int c = 0; c < vec_n; ++c) {
            ScriptParameter k;
            k.name = fname + comp_name[c];
            k.label = label + comp_lbl[c];
            k.kind = "track";
            k.low = nums[0];
            k.high = nums[1];
            k.step = step;
            k.usual = (size_t)(3 + c) < nums.size() ? nums[(size_t)(3 + c)]
                      : nums.size() >= 4            ? nums[3]
                                                    : k.low;
            k.group = group;
            out.push_back(std::move(k));
          }
        }
      } else if (pending_kind == "toggle") {
        ScriptParameter k;
        k.name = fname;
        k.label = label;
        k.kind = "check";
        k.low = 0;
        k.high = 1;
        k.step = 1;
        k.usual = (!nums.empty() && nums[0] != 0.0) ? 1.0 : 0.0;
        k.group = group;
        out.push_back(std::move(k));
      } else if (pending_kind == "color") {
        const int vec_n = ftype.rfind("vec4", 0) == 0 ? 4 : 3;
        const char* comp_name[4] = {"_x", "_y", "_z", "_w"};
        const char* comp_lbl[4] = {" R", " G", " B", " A"};
        for (int c = 0; c < vec_n; ++c) {
          ScriptParameter k;
          k.name = fname + comp_name[c];
          k.label = label + comp_lbl[c];
          k.kind = "track";
          k.low = 0;
          k.high = 1;
          k.step = 0.01;
          k.usual = (size_t)c < nums.size() ? nums[(size_t)c] : 1.0;
          k.group = group;
          out.push_back(std::move(k));
        }
      } else if (pending_kind == "point") {
        const char* comp_name[2] = {"_x", "_y"};
        const char* comp_lbl[2] = {" X", " Y"};
        for (int c = 0; c < 2; ++c) {
          ScriptParameter k;
          k.name = fname + comp_name[c];
          k.label = label + comp_lbl[c];
          k.kind = "track";
          k.low = 0;
          k.high = 1;
          k.step = 0.01;
          k.usual = (size_t)c < nums.size() ? nums[(size_t)c] : 0.5;
          k.group = group;
          out.push_back(std::move(k));
        }
      }
      pending_kind.clear();
      pending_args.clear();
      pending_label.clear();
    }
  }
  return out;
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
#ifdef _WIN32  // (no st_mtimespec: the file's time in 100 ns steps)
  std::error_code missing;
  const auto written = std::filesystem::last_write_time(table, missing);
  const long long when =
      missing ? -1 : (long long)written.time_since_epoch().count();
#else
  struct stat st{};
  const long long when =
      stat(table.c_str(), &st) == 0
          ? (long long)st.st_mtimespec.tv_sec * 1000000000LL +
                st.st_mtimespec.tv_nsec
          : -1;
#endif
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

// anime.js's easing wrapper lives in anime_prelude.js beside this file; see
// it for the header comment on how __ease / __ease_at build and cache ease
// functions from text. Read once, appended to the anime.js bundle.
static const std::string& anime_prelude() {
  static const std::string text =
      read_text(doc_engine("community/quickjs/anime_prelude.js"));
  return text;
}
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
    const std::string bundle_text = read_text(bundle);
    const std::string src =
        std::string(
            "globalThis.setImmediate = function () { return 0; }; "
            "globalThis.clearImmediate = function () {};\n") +
        bundle_text + anime_prelude();
    JSValue ran =
        JS_Eval(cx, src.c_str(), src.size(), "anime", JS_EVAL_TYPE_GLOBAL);
    if (bundle_text.empty() || JS_IsException(ran))
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
