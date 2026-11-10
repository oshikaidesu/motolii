#include "community/p5/adapter_p5_shader.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <regex>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "base/json.h"
#include "community/hydra/hydra_isf.h"
#include "community/sites/adapter.h"

namespace {

// Rewrites GLSL ES as a browser accepts it into the form that isf.cpp reads.
// Removes #version, #extension and precision statements, and turns every in,
// out, attribute and varying declaration into a separate "varying" declaration
// on its own line.
std::string adapter_p5_glsl(const std::string& text) {
  std::string t = std::regex_replace(
      text,
      std::regex(
          R"(#version[^\n]*|#extension[^\n]*|\bprecision\s+\w+\s+\w+\s*;)"),
      "");
  return std::regex_replace(
      t,
      std::regex(
          R"((^|[;\n}])\s*(?:(?:flat|smooth|centroid)\s+)?(?:varying|attribute|in|out)\s+(?:(?:highp|mediump|lowp)\s+)?(\w+)\s+(\w+)\s*(\[[^\]]*\])?\s*;)"),
      "$1\nvarying $2 $3$4;\n");
}

}  // namespace

bool adapter_line(const std::vector<double>& keys) {
  if (keys.size() < 3) return false;
  const double by = (keys.back() - keys[0]) / (double)(keys.size() - 1);
  for (size_t i = 0; i < keys.size(); ++i)
    if (std::abs(keys[i] - keys[0] - by * (double)i) >
        1e-6 * (1.0 + std::abs(keys.back())))
      return false;
  return true;
}

bool adapter_p5_shader(const std::string& json, std::string& fs,
                       std::string& vs, std::vector<HydraParameter>& moving,
                       std::string& why) {
  rapidjson::Document all;
  if (all.Parse(json.c_str()).HasParseError() || !all.IsObject())
    return why = "this sketch's shader did not come out whole", false;
  if (!all.HasMember("vert") || !all.HasMember("frag") ||
      !all["vert"].IsString() || !all["frag"].IsString())
    return why =
               "this sketch's shaders are in files beside it: bring the .js "
               "with them",
           false;
  std::string vert = all["vert"].GetString(), frag = all["frag"].GetString();
  const rapidjson::Value& told = all["told"];
  const double width = all["width"].GetDouble(),
               height = all["height"].GetDouble(),
               density = all["density"].GetDouble();
  const std::string kind = all["kind"].GetString();
  // p5's own matrices flip y, so a sketch that uses them counts corner
  // coordinates from the top. Without them, coordinates count from the bottom.
  const bool down = adapter_has(vert, "uProjectionMatrix");
  std::string head, set, inputs;
  static const std::regex output(
      R"((^|[;\n}])\s*(?:layout\s*\([^)]*\)\s*)?out\s+(?:(?:highp|mediump|lowp)\s+)?vec4\s+(\w+)\s*;)");
  std::smatch said;
  if (std::regex_search(frag, said, output))
    head += "#define " + said[2].str() + " gl_FragColor\n",
        frag = std::regex_replace(frag, output, "$1");
  vert = adapter_p5_glsl(vert), frag = adapter_p5_glsl(frag);
  static const std::regex uniform(
      R"(\buniform\s+(?:(?:highp|mediump|lowp)\s+)?(\w+)\s+([^;]+);)"),
      each(R"((\w+)\s*(?:\[\s*(\d+)\s*\])?)");
  // Maps each uniform name to its type and its array length (0 if it is not an
  // array).
  std::map<std::string, std::pair<std::string, int>> names;
  for (std::string* t : {&vert, &frag}) {
    for (std::sregex_iterator u(t->begin(), t->end(), uniform), end; u != end;
         ++u) {
      const std::string list = (*u)[2];
      for (std::sregex_iterator n(list.begin(), list.end(), each); n != end;
           ++n)
        names[(*n)[1].str()] = {
            (*u)[1].str(),
            (*n)[2].matched ? std::atoi((*n)[2].str().c_str()) : 0};
    }
    *t = std::regex_replace(*t, uniform, "");
  }
  const auto number = [](double v) {
    char o[32];
    std::snprintf(o, sizeof o, "%.9g", v);
    return std::string(o);
  };
  const auto built = [&](const std::string& type, const std::vector<double>& v,
                         size_t from, size_t n) {
    std::string o = type + "(";
    for (size_t i = 0; i < n; ++i)
      o += (i ? "," : "") + number(from + i < v.size() ? v[from + i] : 0.0);
    return o + ")";
  };
  const auto parameter = [&](const std::string& name, const std::string& label,
                             const std::vector<double>& keys) {
    double low = keys[0], high = keys[0];
    for (const double k : keys)
      low = std::min(low, k), high = std::max(high, k);
    if (adapter_line(keys))
      low = std::min(low, adapter_line_end(keys)),
      high = std::max(high, adapter_line_end(keys));
    inputs += ",{\"NAME\":\"" + name + "\",\"LABEL\":\"" + label +
              "\",\"TYPE\":\"float\",\"DEFAULT\":" + number(keys[0]) +
              ",\"MIN\":" + number(std::min(0.0, low * 2)) +
              ",\"MAX\":" + number(std::max(1.0, high * 2)) + "}";
    if (low != high) moving.push_back({name, keys});
  };
  bool reads = false;
  // Names that isf.cpp already defines. A sketch uniform with one of these
  // names is renamed.
  static const std::set<std::string> taken = {
      "time",      "resolution",  "frame",     "passindex",
      "clip_time", "clip_length", "frameRect", "passRect"};
  for (const auto& [name, info] : names) {
    const auto& [type, row] = info;
    // The first sampler reads the input image, which is the layer the effect is
    // applied to, whether it is a video or an image. Later samplers read
    // nothing. p5's texture rows start at the top, so the read flips v (see
    // adapter_read).
    if (type.rfind("sampler", 0) == 0) {
      const std::regex read(R"(\b(?:texture2D|texture)\s*\(\s*)" + name +
                            R"(\s*,)");
      for (std::string* t : {&vert, &frag})
        *t = std::regex_replace(*t, read,
                                reads ? "adapter_none(" : "adapter_read(");
      reads = true;
      continue;
    }
    if (taken.count(name))
      head += "#define " + name + " adapter_own_" + name + "\n";
    head += type + " " + name + (row ? "[" + std::to_string(row) + "]" : "") +
            ";\n";
    const bool whole = type == "float" || type == "int" || type == "bool";
    const int wide = whole ? 1
                     : std::isdigit((unsigned char)type.back())
                         ? type.back() - '0'
                         : 1,
              size = type.rfind("mat", 0) == 0 ? wide * wide : wide;
    std::vector<std::vector<double>> samples;
    if (told.HasMember(name.c_str()) && told[name.c_str()].IsArray())
      for (const auto& s : told[name.c_str()].GetArray()) {
        std::vector<double> v;
        if (s.IsNumber())
          v.push_back(s.GetDouble());
        else if (s.IsArray())
          for (const auto& n : s.GetArray())
            v.push_back(n.IsNumber() ? n.GetDouble() : 0.0);
        if (!v.empty()) samples.push_back(v);
      }
    // The sketch never set this uniform. For p5's own matrices that means the
    // identity, because nothing transformed them.
    if (samples.empty()) {
      if (type.rfind("mat", 0) == 0 && !row) set += name + "=" + type + "(1.);";
      continue;
    }
    const std::vector<double>& first = samples[0];
    // An array uniform is set once, to the values of the first sample.
    if (row) {
      set += name + "=" + type + "[" + std::to_string(row) + "](";
      for (int i = 0; i < row; ++i)
        set += (i ? "," : "") +
               built(type, first, (size_t)(i * size), (size_t)size);
      set += ");";
      continue;
    }
    if (type.rfind("mat", 0) == 0) {
      set += name + "=" + built(type, first, 0, (size_t)size) + ";";
      continue;
    }
    bool still = true,
         stage = (type == "vec2" || type == "vec3" || type == "ivec2") &&
                 first.size() >= 2 && first[0] > 0;
    const double times = stage ? first[0] / width : 1.0;
    for (const auto& s : samples) {
      still = still && s == first;
      stage = stage && s.size() >= 2 && std::abs(s[0] / width - times) < 1e-6 &&
              std::abs(s[1] / height - times) < 1e-6;
    }
    // The uniform holds the sketch's canvas size, scaled by a constant. Replace
    // it with the size of the canvas the effect runs on, so that it follows the
    // project.
    if (stage) {
      const std::string size2 = "adapter_size()*" + number(times / density);
      set +=
          name + "=" +
          (type == "vec3" ? "vec3(" + size2 + "," +
                                number(first.size() > 2 ? first[2] : 1.0) + ")"
                          : type + "(" + size2 + ")") +
          ";";
      continue;
    }
    // A constant vec3 or vec4 with every component in [0, 1] is taken to be a
    // color and becomes a color parameter.
    if ((type == "vec3" || type == "vec4") && still &&
        std::all_of(first.begin(), first.end(),
                    [](double v) { return v >= 0.0 && v <= 1.0; })) {
      inputs += ",{\"NAME\":\"door_" + name + "\",\"LABEL\":\"" + name +
                "\",\"TYPE\":\"color\",\"DEFAULT\":[" + number(first[0]) + "," +
                number(first[1]) + "," + number(first[2]) + "," +
                number(first.size() > 3 ? first[3] : 1.0) + "]}";
      set += name + "=door_" + name + (type == "vec3" ? ".rgb;" : ";");
      continue;
    }
    std::string parts;
    for (int i = 0; i < size; ++i) {
      const std::string one =
          "door_" + name + (size > 1 ? "_" + std::to_string(i) : "");
      std::vector<double> keys;
      for (const auto& s : samples)
        keys.push_back(i < (int)s.size() ? s[(size_t)i] : 0.0);
      parameter(one, name + (size > 1 ? " " + std::to_string(i + 1) : ""),
                keys);
      parts += (i ? "," : "") + one;
    }
    set += name + "=" + type +
           (type == "bool" ? "(" + parts + ">.5);" : "(" + parts + ");");
  }
  const double lo = kind == "rect"    ? 0.0
                    : kind == "plane" ? -0.5
                                      : -1.0,
               hi = kind == "rect"    ? 1.0
                    : kind == "plane" ? 0.5
                                      : 1.0;
  std::string start =
      "adapter_told();vec2 adapter_uv=vec2(isf_FragNormCoord.x," +
      std::string(down ? "1.-isf_FragNormCoord.y" : "isf_FragNormCoord.y") +
      ");";
  if (adapter_has(vert, "aTexCoord")) start += "aTexCoord=adapter_uv;";
  if (adapter_has(vert, "aPosition"))
    start += "aPosition=vec3(" + number(lo) + "+adapter_uv*" + number(hi - lo) +
             ",0.);";
  if (adapter_has(vert, "aNormal")) start += "aNormal=vec3(0.,0.,1.);";
  vert = std::regex_replace(
      vert, std::regex(R"(\bvoid\s+main\s*\(\s*(?:void)?\s*\)\s*\{)"),
      "void main(){" + start);
  vs = "vec2 adapter_size(){return RENDERSIZE;}\n" + head +
       "vec4 adapter_none(vec2 a){return vec4(0.);}\nvec4 adapter_none(vec2 "
       "a,float b){return vec4(0.);}\n#define adapter_read(c) "
       "texture(inputImage,vec2((c).x,1.-(c).y))\nvoid adapter_told(){" +
       set + "}\n" + vert;
  fs = "/*{\"ISFVSN\":\"2\",\"DESCRIPTION\":\"p5.js\",\"CATEGORIES\":[\"p5."
       "js\"],\"INPUTS\":[" +
       (reads ? std::string("{\"NAME\":\"inputImage\",\"TYPE\":\"image\"}") +
                    inputs
        : inputs.empty() ? ""
                         : inputs.substr(1)) +
       "]}*/\n" + frag;
  return true;
}
