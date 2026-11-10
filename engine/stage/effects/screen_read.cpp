// Reading an effect's file: the ISF or WGSL source is turned into the form
// Filament's driver takes, and the layout of its parameters, passes and
// targets is filled into the ScreenFx.

#include "stage/effects/screen_fx.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <map>
#include <regex>
#include <sstream>
#include <string>
#include <system_error>
#include <vector>

#include "community/isf/isf.h"
#include "community/quickjs/script.h"
#include "shelf/shelf_folders.h"

namespace motolii {

std::filesystem::file_time_type screen_stamp(const std::string& file) {
  std::error_code wrong;
  return std::filesystem::last_write_time(fx_source(file), wrong);
}

namespace {
// Rewrites the WGSL in `code` in place for a shader that does not know
// layerRect, so that it is told the layer's frame as an ISF effect is (see
// community/isf/isf.cpp): its uv and pixel coordinates are relative to the
// frame, and what it reads is read through the frame. The shader's own lines
// are kept and only names are changed, so a file written for a whole image
// works on a layer. Does nothing for a shader that reads a texture array or has
// no uniform struct or fragment entry point.
void screen_framed(std::string& code) {
  std::smatch parameters, way;
  if (code.find("texture_2d_array") != std::string::npos ||
      !std::regex_search(code, parameters,
                         std::regex(R"(var<uniform>\s+(\w+)\s*:\s*(\w+)\s*;)")))
    return;
  if (!std::regex_search(
          code, way,
          std::regex(
              R"(@fragment\s+fn\s+\w+\s*\([^)]*@location\(0\)\s+(\w+)\s*:\s*vec2(?:f|<f32>)[^)]*\)[^{]*\{)")))
    return;
  const std::string k = parameters[1], built = parameters[2], uv = way[1];
  std::string head = way.str();
  const bool pixel =
      std::regex_search(head, std::regex(R"(@builtin\(position\)\s+frag\s*:)"));
  head = std::regex_replace(
      std::regex_replace(head, std::regex("\\b" + uv + "(\\s*:)"),
                         uv + "_on$1"),
      std::regex(R"(\bfrag(\s*:))"), "frag_on$1");
  head += "\n    let " + uv + " = (" + uv + "_on - " + k + ".frameRect.xy) / " +
          k + ".frameRect.zw;\n";
  if (pixel)
    head += "    let frag = vec4f(" + uv + " * " + k +
            ".resolution, frag_on.zw);\n";
  const size_t at = (size_t)way.position(), end = at + (size_t)way.length();
  std::string out = code.substr(0, at) + head + code.substr(end);
  out = std::regex_replace(
      std::regex_replace(out, std::regex(R"(\btextureSampleLevel\s*\()"),
                         "frame_level("),
      std::regex(R"(\btextureSample\s*\()"), "frame_sample(");
  out = std::regex_replace(out, std::regex("struct\\s+" + built + "\\s*\\{"),
                           "struct " + built + " {\n    frameRect: vec4f,");
  std::smatch line;
  std::regex_search(out, line, std::regex(R"(var<uniform>[^;]*;)"));
  const std::string reads =
      "\nfn frame_level(t: texture_2d<f32>, s: sampler, c: vec2f, l: f32) -> "
      "vec4f { return textureSampleLevel(t, s, c * " +
      k + ".frameRect.zw + " + k +
      ".frameRect.xy, l); }\nfn frame_sample(t: texture_2d<f32>, s: sampler, "
      "c: vec2f) -> vec4f { return textureSample(t, s, c * " +
      k + ".frameRect.zw + " + k + ".frameRect.xy); }\n";
  code = out.substr(0, (size_t)line.position() + (size_t)line.length()) +
         reads + out.substr((size_t)line.position() + (size_t)line.length());
}
}  // namespace

bool screen_read(ScreenFx& fx, std::string& code) {
  // An ISF effect is converted to WGSL first.
  const std::string file = isf_file(fx.file);
  fx.source =
      isf_tags(fx_source(fx.file)).find("generator") != std::string::npos;
  if (file.empty())
    return fx.trouble =
               "the ISF effect could not be turned into WGSL: " + fx.file,
           false;
  std::ifstream in(file);
  if (!in) return fx.trouble = "there is no such file: " + fx.file, false;
  std::stringstream all;
  all << in.rdbuf();
  code = all.str();
  if (code.find("layerRect") == std::string::npos &&
      code.find("frameRect") == std::string::npos)
    screen_framed(code);
  const std::regex bound(
      R"(@group\(\s*\d+u?\s*\)\s*@binding\(\s*\d+u?\s*\)\s*var(<\s*uniform\s*>)?\s+(\w+)\s*:\s*([A-Za-z_][\w<>]*))");
  // Number of images read. Image k is bound at 2k, sampler k at 2k+1, and the
  // parameters after them all.
  int reads = 0;
  // The declarations sorted below by the binding number written in the source,
  // since Tint may emit them in any order.
  std::vector<std::smatch> said;
  // Counts texture_2d and texture_2d_array alike.
  for (std::sregex_iterator m(code.begin(), code.end(), bound), end; m != end;
       ++m)
    said.push_back(*m), reads += (*m)[3].str().rfind("texture_2d", 0) == 0;
  const auto number = [](const std::smatch& m) {
    const std::string all = m[0];
    return std::atoi(all.c_str() + all.find("@binding(") + 9);
  };
  std::vector<size_t> order(said.size());
  for (size_t i = 0; i < order.size(); ++i) order[i] = i;
  std::stable_sort(order.begin(), order.end(), [&](size_t a, size_t b) {
    return number(said[a]) < number(said[b]);
  });
  std::vector<int> given(said.size(), -1);
  std::string out, parametersType;
  int textureCount = 0, samplers = 0, uniforms = 0;
  for (size_t i : order) {
    const std::string type = said[i][3];
    int& binding = given[i];
    if (type.rfind("texture_2d_array", 0) == 0)
      fx.layered |= 1u << textureCount, binding = 2 * textureCount++;
    else if (type.rfind("texture_2d", 0) == 0)
      binding = 2 * textureCount++;
    else if (type == "sampler")
      binding = 2 * samplers++ + 1;
    else if (said[i][1].matched)
      binding = 2 * reads, ++uniforms, parametersType = type;
    if (binding < 0)
      return fx.trouble =
                 "the effect has a binding of a kind it cannot be given: " +
                 type,
             false;
  }
  auto at = code.cbegin();
  for (size_t i = 0; i < said.size(); ++i) {
    const std::smatch& m = said[i];
    const int binding = given[i];
    out.append(at, code.cbegin() + m.position());
    out += "@group(0) @binding(" + std::to_string(binding) + ") var" +
           (m[1].matched ? "<uniform>" : "") + " " + m[2].str() + ": " +
           m[3].str();
    at = code.cbegin() + m.position() + m.length();
  }
  out.append(at, code.cend());
  if (textureCount < 1 || samplers > textureCount || uniforms > 1)
    return fx.trouble =
               "an effect reads a texture or more, a sampler for each at most, "
               "and one struct of parameters at most",
           false;
  fx.textureCount = textureCount;
  // The passes, as declared in the leading comments: `//
  // --pass@target:persistent,fine,width,height`.
  std::istringstream lines(code);
  for (std::string line;
       std::getline(lines, line) && line.rfind("//", 0) == 0;) {
    // `// --history@frames:share`
    if (const size_t h = line.find("--history@"); h != std::string::npos) {
      fx.historyFrames = std::clamp(std::atoi(line.c_str() + h + 10), 2, 240);
      if (const size_t c = line.find(':', h); c != std::string::npos)
        fx.historyShare =
            std::clamp(std::atof(line.c_str() + c + 1), 0.05, 1.0);
      continue;
    }
    if (line.find("--spill") != std::string::npos) {
      fx.spill = true;
      continue;
    }
    if (line.find("--alpha") != std::string::npos) {
      fx.alpha = true;
      continue;
    }
    const size_t p = line.find("--pass@"), colon = line.find(':', p);
    if (p == std::string::npos || colon == std::string::npos) continue;
    const std::string name = line.substr(p + 7, colon - p - 7);
    std::vector<std::string> said;
    std::stringstream rest(line.substr(colon + 1));
    for (std::string one; std::getline(rest, one, ',');) said.push_back(one);
    if (said.size() < 4)
      return fx.trouble = "a pass said wrong: " + line, false;
    int target = -1;
    if (!name.empty()) {
      for (size_t k = 0; k < fx.targets.size(); ++k)
        if (fx.targets[k].name == name) target = (int)k;
      if (target < 0) {
        ScreenFx::Target t;
        t.name = name, t.persistent = said[0] == "1", t.fine = said[1] == "1";
        for (int side = 0; side < 2; ++side) {
          const std::string& w = said[(size_t)side + 2];
          if (!w.empty() && w[0] == 'a')
            t.points[side] = std::max(1, std::atoi(w.c_str() + 1)),
            t.share[side] = 0;
          else
            t.share[side] = w.size() > 1 ? std::atof(w.c_str() + 1) : 1.0;
        }
        fx.targets.push_back(t);
        target = (int)fx.targets.size() - 1;
      }
    }
    fx.passes.push_back(target);
  }
  fx.others.clear();
  fx.sounds.clear();
  // `file` is WGSL here (isf_file gave it), so its parameters are its header
  // lines.
  std::ifstream header(file);
  const std::vector<ScriptParameter> declared =
      script_header_parameters(header);
  for (const ScriptParameter& k : declared)
    if (k.kind == "picture" || k.kind == "sound") {
      fx.others.push_back(k.name), fx.sounds.push_back({});
      if (k.kind == "sound")
        fx.sounds.back() = {true, k.words.rfind("fft", 0) == 0,
                            std::atoi(k.words.c_str() + k.words.find(' ') + 1)};
    }
  fx.images.assign(fx.others.size(), "");
  std::istringstream head(code);
  for (std::string line;
       std::getline(head, line) && line.rfind("//", 0) == 0;) {
    const size_t h = line.find("--image@"), colon = line.find(':', h);
    if (h == std::string::npos || colon == std::string::npos) continue;
    fx.others.push_back(line.substr(h + 8, colon - h - 8)),
        fx.sounds.push_back({});
    fx.images.push_back(
        (std::filesystem::path(file).parent_path() / line.substr(colon + 1))
            .string());
  }
  if ((!fx.targets.empty() || !fx.others.empty()) &&
      (int)fx.targets.size() + 1 + (int)__builtin_popcount(fx.layered) +
              (int)fx.others.size() !=
          textureCount)
    return fx.trouble =
               "its passes' textures, its other images and the textures it "
               "reads do not agree",
           false;
  if (fx.layered && !fx.historyFrames)
    return fx.trouble =
               "it reads an array of past frames and its head does not ask for "
               "them (--history@frames:share)",
           false;
  code =
      std::regex_replace(out, std::regex(R"(\bfn\s+fs_main\s*\()"), "fn main(");
  // Computes each member's offset by WGSL's rule for a uniform: aligned to its
  // size, with a vec3 aligned as a vec4.
  if (!parametersType.empty()) {
    std::smatch body;
    if (!std::regex_search(
            code, body,
            std::regex("struct\\s+" + parametersType + "\\s*\\{([^}]*)\\}")))
      return fx.trouble = "no struct " + parametersType, false;
    const std::regex field(R"((\w+)\s*:\s*([\w<>]+))");
    const std::string inside = body[1];
    uint32_t end = 0, most = 4;
    for (std::sregex_iterator f(inside.begin(), inside.end(), field), stop;
         f != stop; ++f) {
      const std::string t = (*f)[2];
      const uint32_t n = t == "f32" || t == "i32" || t == "u32" ? 1
                         : t.find("vec2") == 0                  ? 2
                         : t.find("vec3") == 0                  ? 3
                         : t.find("vec4") == 0                  ? 4
                                                                : 0;
      if (!n)
        return fx.trouble =
                   "a parameter of a kind an effect cannot be given: " + t,
               false;
      const uint32_t align = n == 1 ? 4 : n == 2 ? 8 : 16;
      end = (end + align - 1) / align * align;
      fx.fields.push_back({(*f)[1], end, n, t == "i32" || t == "u32"});
      end += 4 * n, most = std::max(most, align);
    }
    fx.bytes = (end + most - 1) / most * most;
  }
  fx.parameters = declared;
  // Fill in the default values where the file's own declarations give none; see
  // shelves/effects/sources/fx_first.sh.
  script_first(fx.file, fx.parameters);
  return true;
}

}  // namespace motolii
