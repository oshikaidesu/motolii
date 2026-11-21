// Parses and strips WESL-style UI attributes on WGSL uniform structs.
#include "community/quickjs/wgsl_attributes.h"

#include <cctype>
#include <cstdlib>
#include <regex>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

namespace motolii {

namespace {

bool is_ident(char c) {
  return std::isalnum((unsigned char)c) || c == '_';
}

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

// Finds the byte span [start, end) of the next UI attribute token in `code`
// starting from `from`, leaving standard WGSL @group(0) bindings untouched.
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
    while (j < code.size() && is_ident(code[j])) ++j;
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
          if (code[p] == '(')
            ++depth;
          else if (code[p] == ')')
            --depth;
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

// Extracts the `{ ... }` body of `struct <name>` without compiling a per-call
// regex.
std::string find_struct_body(const std::string& code, const std::string& name) {
  size_t pos = 0;
  while ((pos = code.find("struct", pos)) != std::string::npos) {
    if (pos > 0 && is_ident(code[pos - 1])) {
      pos += 6;
      continue;
    }
    size_t p = pos + 6;
    if (p >= code.size() || !std::isspace((unsigned char)code[p])) {
      pos = p;
      continue;
    }
    while (p < code.size() && std::isspace((unsigned char)code[p])) ++p;
    if (code.compare(p, name.size(), name) != 0) {
      pos = p;
      continue;
    }
    p += name.size();
    if (p < code.size() && is_ident(code[p])) {
      pos = p;
      continue;
    }
    while (p < code.size() && std::isspace((unsigned char)code[p])) ++p;
    if (p < code.size() && code[p] == '{') {
      const size_t close = code.find('}', p + 1);
      if (close != std::string::npos) return code.substr(p + 1, close - p - 1);
    }
    pos = p;
  }
  return "";
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
  static const std::regex kUniformRe(
      R"(var\s*<\s*uniform\s*>\s+\w+\s*:\s*(\w+))");
  std::vector<ScriptParameter> out;
  std::smatch um;
  std::string struct_name = "Knobs";
  if (std::regex_search(code, um, kUniformRe)) struct_name = um[1].str();
  const std::string body = find_struct_body(code, struct_name);
  if (body.empty()) return out;

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
      while (pos < body.size() && is_ident(body[pos])) ++pos;
      if (pos < body.size() && body[pos] == '(') {
        int d = 1;
        ++pos;
        while (pos < body.size() && d > 0) {
          if (body[pos] == '(')
            ++d;
          else if (body[pos] == ')')
            --d;
          ++pos;
        }
      }
      continue;
    }
    // Parse `fieldName: fieldType,`
    size_t n0 = pos;
    while (pos < body.size() && is_ident(body[pos])) ++pos;
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

}  // namespace motolii
