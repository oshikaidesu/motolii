// Building the GLSL of an ISF file and the header the app reads: the ISF
// built-ins become GLSL macros, each image a texture and a sampler, the
// parameters one uniform struct, the passes and inputs "// --..." lines.
#include "community/isf/isf_translate.h"

#include <map>
#include <regex>

namespace motolii {

std::string isf_wgsl(const std::string& text, const std::string& name,
                     std::string& why, std::string vertex) {
  IsfHead parsed;
  if (!isf_read_head(text, parsed))
    return why = "no ISF head (a JSON comment at the top)", "";
  const rapidjson::Value& head = parsed.json;
  std::string body = parsed.body;

  std::vector<std::string> targets, passLines;
  // For each pass target: whether its width and its height are absolute sizes
  // rather than a share of the frame.
  std::map<std::string, std::pair<bool, bool>> setSize;
  if (head.HasMember("PASSES") && head["PASSES"].IsArray())
    for (const auto& p : head["PASSES"].GetArray()) {
      const std::string t = isf_str(p, "TARGET");
      std::string w, h;
      if (!isf_pass_size(p, "WIDTH", "WIDTH", w) ||
          !isf_pass_size(p, "HEIGHT", "HEIGHT", h))
        return why = "a pass's size it cannot say", "";
      if (!t.empty() &&
          std::find(targets.begin(), targets.end(), t) == targets.end())
        targets.push_back(t);
      if (!t.empty()) setSize[t] = {w.rfind("a", 0) == 0, h.rfind("a", 0) == 0};
      const bool persistent =
                     p.HasMember("PERSISTENT") && isf_num(p["PERSISTENT"], 0),
                 fine = p.HasMember("FLOAT") && isf_num(p["FLOAT"], 0);
      passLines.push_back("// --pass@" + t + ":" + (persistent ? "1" : "0") +
                          "," + (fine ? "1" : "0") + "," + w + "," + h);
    }

  const rapidjson::Value& inputs = *parsed.inputs;
  const std::vector<std::string>& imageNames = parsed.images;
  // An ISF file without image inputs is a generator (ISF_Spec distinguishes
  // sources, filters and transitions). On a layer it paints only where the
  // layer is, like After Effects' Preserve Underlying Transparency. The layer's
  // own image is still bound at binding 0, as the interop expects.
  const std::string inputName =
      imageNames.empty() ? "inputImage"
      : std::find(imageNames.begin(), imageNames.end(), "inputImage") !=
              imageNames.end()
          ? "inputImage"
          : imageNames[0];
  // Other image inputs: each is the image of another layer, chosen on the
  // effect card, and is bound after the images of the passes.
  std::vector<std::string> others;
  for (const std::string& other : imageNames)
    if (other != inputName) others.push_back(other);
  // Audio inputs are images as the spec says, bound after the other images.
  for (const auto& i : inputs.GetArray())
    if (isf_str(i, "TYPE") == "audio" || isf_str(i, "TYPE") == "audioFFT")
      others.push_back(isf_str(i, "NAME"));

  const std::map<std::string, std::string> kinds = {
      {"float", "float"}, {"bool", "int"},     {"long", "int"},
      {"event", "int"},   {"point2D", "vec2"}, {"color", "vec4"}};
  std::string glsl = "#version 450\n";
  // Each image becomes a texture and a sampler named after it. The names are
  // put in front of ISF's macros by pasting. A name that the shader also uses
  // for a variable of its own is left alone. Only the input image can also be
  // used by its bare name.
  std::vector<std::string> read = {inputName};
  read.insert(read.end(), targets.begin(), targets.end());
  for (size_t k = 0; k < read.size(); ++k)
    glsl += "layout(set = 0, binding = " + std::to_string(2 * k) +
            ") uniform texture2D isf_tex_" + read[k] +
            ";\nlayout(set = 0, binding = " + std::to_string(2 * k + 1) +
            ") uniform sampler isf_smp_" + read[k] + ";\n";
  for (size_t k = 0; k < others.size(); ++k)
    glsl +=
        "layout(set = 0, binding = " + std::to_string(2 * (read.size() + k)) +
        ") uniform texture2D isf_tex_" + others[k] +
        ";\nlayout(set = 0, binding = " +
        std::to_string(2 * (read.size() + k) + 1) +
        ") uniform sampler isf_smp_" + others[k] + ";\n";
  // The parameter struct also holds the values of the layer: clip_time is the
  // seconds into the layer and clip_length is how long it lasts
  // (engine/document/evaluate/moment_fx.h). The frame has neither.
  glsl += "layout(set = 0, binding = " +
          std::to_string(2 * (read.size() + others.size())) +
          ") uniform Parameters {\n  float time;\n  vec2 resolution;\n  float "
          "frame;\n  float isf_rate;\n  float passindex;\n  float clip_time;\n "
          " float clip_length;\n  vec4 frameRect;\n  vec4 passRect;\n";
  // On/off parameters. They are stored as int because WGSL keeps no bool in a
  // uniform. Uses of the name in the shader are rewritten to read as a bool,
  // except where the name is a member of a color such as .r.
  std::vector<std::string> switches;
  std::string lines;
  for (const auto& k : inputs.GetArray()) {
    const std::string t = isf_str(k, "TYPE"), n = isf_str(k, "NAME");
    if (!kinds.count(t)) continue;
    const bool onoff = t == "bool" || t == "event";
    glsl += "  " + kinds.at(t) + " " + n + (onoff ? "_on" : "") + ";\n";
    if (onoff) switches.push_back(n);
    std::string label = isf_str(k, "LABEL", n);
    std::replace(label.begin(), label.end(), ',', ' ');
    const auto at = [&](const char* key, int i, double fallback) {
      if (!k.HasMember(key)) return fallback;
      const rapidjson::Value& v = k[key];
      return v.IsArray() ? (i < (int)v.Size()
                                ? isf_num(v[(rapidjson::SizeType)i], fallback)
                                : fallback)
                         : isf_num(v, fallback);
    };
    char line[256];
    if (onoff)
      std::snprintf(line, sizeof line, "// --check@%s_on:%s,%d\n", n.c_str(),
                    label.c_str(), (int)at("DEFAULT", 0, 0)),
          lines += line;
    else if (t == "float" || t == "long") {
      // The choices of a long are its VALUES (ISF_Spec). Its range runs from
      // the smallest to the largest of them.
      double lo = at("MIN", 0, 0), hi = at("MAX", 0, 1);
      if (t == "long" && k.HasMember("VALUES") && k["VALUES"].IsArray() &&
          !k["VALUES"].Empty()) {
        lo = hi = isf_num(k["VALUES"][0], 0);
        for (const auto& v : k["VALUES"].GetArray())
          lo = std::min(lo, isf_num(v, lo)), hi = std::max(hi, isf_num(v, hi));
      }
      std::snprintf(line, sizeof line, "// --track@%s:%s,%g,%g,%g,%g\n",
                    n.c_str(), label.c_str(), lo, hi, at("DEFAULT", 0, 0),
                    t == "long" ? 1.0 : 0.001),
          lines += line;
    } else
      for (int i = 0; i < (t == "point2D" ? 2 : 4); ++i)
        std::snprintf(line, sizeof line,
                      "// --track@%s_%c:%s %c,%g,%g,%g,0.001\n", n.c_str(),
                      "xyzw"[i], label.c_str(),
                      (t == "point2D" ? "xyzw" : "rgba")[i], at("MIN", i, 0),
                      at("MAX", i, 1), at("DEFAULT", i, 0)),
            lines += line;
  }
  for (const std::string& n : others) glsl += "  vec4 isf_other_" + n + ";\n";
  glsl += "};\n";
  for (const std::string& n : switches)
    for (std::string* t : {&body, &vertex})
      *t = std::regex_replace(*t, std::regex("(^|[^.\\w])" + n + "\\b"),
                              "$1(" + n + "_on != 0)");
  // ISF coordinates run up from the bottom left, as WebGL's do (ISF_Spec).
  // WebGPU coordinates run down from the top left. The coordinate, the pixel's
  // own and every image read are flipped alike, so an image read at a location
  // stays as it was.
  glsl +=
      "layout(location = 0) in vec2 isf_FragNormCoord_down;\nlayout(location = "
      "0) out vec4 isf_FragColor;\n";
  // Coordinates and reads are relative to the frame: 0 to 1 over the layer,
  // continuing beyond it where the image is larger. This follows After Effects,
  // which separates width and height from its buffer, and which gives points in
  // the layer's own space (PF_InData). Cutting what the effect draws beyond the
  // frame is the host's job, as with SkImageFilters::Crop after each effect.
  glsl +=
      "#define isf_here ((isf_FragNormCoord_down - passRect.xy) / "
      "passRect.zw)\n#define isf_FragNormCoord vec2(isf_here.x, 1.0 - "
      "isf_here.y)\n#define isf_up(c) vec2((c).x, 1.0 - (c).y)\n";
  glsl +=
      "#define isf_in(r, i, c) textureLod(i, isf_up(c) * (r).zw + (r).xy, "
      "0.0)\n#define isf_in_pixel(r, i, c) isf_in(r, i, (c) / "
      "RENDERSIZE)\n#define isf_in_here(r, i) isf_in(r, i, "
      "isf_FragNormCoord)\n";
  for (const std::string& n : others) {
    std::string label = n;
    // For an audio input: its kind and how many values it wants (MAX; when
    // absent, as many as are read).
    std::string sound;
    for (const auto& i : inputs.GetArray())
      if (isf_str(i, "NAME") == n)
        label = isf_str(i, "LABEL", n),
        sound = isf_str(i, "TYPE") == "audioFFT" ? ",fft,"
                : isf_str(i, "TYPE") == "audio"  ? ",wave,"
                                                 : "",
        sound += sound.empty()
                     ? ""
                     : std::to_string((
                           int)(i.HasMember("MAX") ? isf_num(i["MAX"], 0) : 0));
    std::replace(label.begin(), label.end(), ',', ' ');
    lines += (sound.empty() ? "// --picture@" : "// --sound@") + n + ":" +
             label + sound + "\n";
    // Read through ISF's macros like the other images.
    read.push_back(n);
  }
  for (const std::string& n : others)
    glsl +=
        "#define " + n + " sampler2D(isf_tex_" + n + ", isf_smp_" + n + ")\n";
  glsl += "#define " + inputName + " sampler2D(isf_tex_" + inputName +
          ", isf_smp_" + inputName + ")\n";
  // ISF_Spec defines DATE.w as the seconds of the day. Here it is the project's
  // own time, a clock that runs as the video does like Alight Motion's
  // Timecode.
  glsl +=
      "#define TIME time\n#define RENDERSIZE resolution\n#define TIMEDELTA "
      "(1.0 / isf_rate)\n#define FRAMEINDEX int(frame)\n#define PASSINDEX "
      "int(passindex)\n#define DATE vec4(0.0, 0.0, 0.0, TIME)\n";
  // VVISF's names for the rect and size of an image. Each is as large as the
  // frame here.
  for (const std::string& n : read)
    glsl += "#define isf_img_" + n + " sampler2D(isf_tex_" + n + ", isf_smp_" +
            n + ")\n#define _" + n +
            "_imgRect vec4(0.0, 0.0, RENDERSIZE)\n#define _" + n +
            "_imgSize RENDERSIZE\n#define _" + n + "_flip false\n";
  // ISF 1's name for isf_FragNormCoord, which VVISF still accepts.
  glsl += "#define vv_FragNormCoord isf_FragNormCoord\n";
  glsl +=
      "#define IMG_NORM_PIXEL(i, c) texture(i, c)\n#define IMG_PIXEL(i, c) "
      "texture(i, (c) / RENDERSIZE)\n";
  glsl +=
      "#define IMG_THIS_NORM_PIXEL(i) texture(i, isf_FragNormCoord)\n#define "
      "IMG_THIS_PIXEL(i) texture(i, isf_FragNormCoord)\n#define IMG_SIZE(i) "
      "RENDERSIZE\n";
  body = std::regex_replace(
      body,
      std::regex(
          R"((\bIMG_(?:NORM_PIXEL|PIXEL|THIS_PIXEL|THIS_NORM_PIXEL|SIZE)\s*\(\s*)(\w+))"),
      "$1isf_img_$2");
  glsl +=
      "#define gl_FragColor isf_FragColor\n#define texture2D texture\n#define "
      "varying //\n";
  glsl +=
      "#define texture(i, c) textureLod(i, isf_up(c) * frameRect.zw + "
      "frameRect.xy, 0.0)\n#define gl_FragCoord vec4(isf_here.x * "
      "RENDERSIZE.x, (1.0 - isf_here.y) * RENDERSIZE.y, gl_FragCoord.zw)\n";
  // textureSize and texelFetch address the frame part of an image too. WGSL
  // samples with derivatives only where every pixel takes the same path, so
  // these read the top level anywhere.
  glsl +=
      "#define textureSize(i, l) ivec2(vec2(textureSize(i, l)) * frameRect.zw "
      "+ 0.5)\n#define isf_fetch(i, p, l) texelFetch(i, ivec2(p) + "
      "ivec2(frameRect.xy * RENDERSIZE / passRect.zw + 0.5), l)\n";
  // A custom vertex shader: what it passes on, mostly neighbouring coordinates,
  // is computed at each pixel before the pixel's own work. The result is the
  // same because the coordinates are linear across the frame.
  if (!vertex.empty()) {
    const std::regex said(
        R"(^[ \t]*(?:varying|out|in)[ \t]+(\w+)[ \t]+(\w+)([ \t]*\[[^\]]*\])?[ \t]*;)",
        std::regex::multiline);
    // Each varying by name: its type, and the array size when it is an array.
    std::map<std::string, std::string> handed;
    for (const std::string* t : {&vertex, &body})
      for (std::sregex_iterator m(t->begin(), t->end(), said), end; m != end;
           ++m)
        handed[(*m)[2].str() + (*m)[3].str()] = (*m)[1];
    vertex = std::regex_replace(std::regex_replace(vertex, said, ""),
                                std::regex(R"(\bvoid\s+main\s*\()"),
                                "void isf_vs_main(");
    body = std::regex_replace(std::regex_replace(body, said, ""),
                              std::regex(R"(\bvoid\s+main\s*\()"),
                              "void isf_fs_main(");
    glsl +=
        "#define isf_vertShaderInit()\nvec4 isf_vs_position;\n#define "
        "gl_Position isf_vs_position\n";
    for (const auto& [n, type] : handed) glsl += type + " " + n + ";\n";
    vertex = std::regex_replace(
        vertex,
        std::regex(
            R"(\b(IMG_(?:NORM_PIXEL|PIXEL|THIS_PIXEL|THIS_NORM_PIXEL|SIZE)\s*\(\s*)(\w+))"),
        "$1isf_img_$2");
    body = std::regex_replace(vertex, std::regex(R"(^[ \t]*#version.*$)"), "") +
           "\n" + body + "\nvoid main() { isf_vs_main(); isf_fs_main(); }\n";
  }
  // Some files (for example Sashimono's) define their own flip of a pixel
  // number. That definition is kept and its reads go through the frame.
  const std::regex flipped(
      R"(#define\s+texelFetch\s*\(\s*t\s*,\s*p\s*,\s*l\s*\)\s*texelFetch\b)");
  const bool turns = std::regex_search(body, flipped);
  body = std::regex_replace(
      std::regex_replace(body, flipped,
                         "#define isf_turned(t, p, l) isf_fetch"),
      std::regex(R"(\btexelFetch\s*\()"), turns ? "isf_turned(" : "isf_fetch(");
  // Images that are not the frame: the other inputs, each at the rect given by
  // its uniform, and targets with an absolute size, whose absolute sides cover
  // the whole image.
  std::map<std::string, std::string> apart;
  for (const std::string& n : others) apart[n] = "isf_other_" + n;
  for (const auto& [n, set] : setSize)
    if (set.first || set.second)
      apart[n] = std::string("vec4(") + (set.first ? "0.0" : "frameRect.x") +
                 ", " + (set.second ? "0.0" : "frameRect.y") + ", " +
                 (set.first ? "1.0" : "frameRect.z") + ", " +
                 (set.second ? "1.0" : "frameRect.w") + ")";
  for (const auto& [n, r] : apart) {
    body = std::regex_replace(
        body, std::regex(R"(\bIMG_NORM_PIXEL\s*\(\s*isf_img_)" + n + R"(\b)"),
        "isf_in(" + r + ", isf_img_" + n);
    body = std::regex_replace(
        body, std::regex(R"(\bIMG_PIXEL\s*\(\s*isf_img_)" + n + R"(\b)"),
        "isf_in_pixel(" + r + ", isf_img_" + n);
    body = std::regex_replace(
        body,
        std::regex(R"(\bIMG_THIS(?:_NORM)?_PIXEL\s*\(\s*isf_img_)" + n +
                   R"(\b)"),
        "isf_in_here(" + r + ", isf_img_" + n);
    body = std::regex_replace(
        body,
        std::regex(R"(\btexture(?:2D)?\s*\(\s*(?:isf_img_)?)" + n + R"(\b)"),
        "isf_in(" + r + ", isf_img_" + n);
  }
  // A generator: its last pass is as transparent as the layer under it
  // (Preserve Underlying Transparency).
  if (imageNames.empty())
    body = std::regex_replace(body, std::regex(R"(\bvoid\s+main\s*\()"),
                              "void isf_source_main(") +
           "\nvoid main() { isf_source_main(); if (PASSINDEX == " +
           std::to_string(std::max<int>((int)passLines.size() - 1, 0)) +
           ") isf_FragColor.a *= texture(" + inputName +
           ", isf_FragNormCoord).a; }\n";
  glsl += "#line 1\n" +
          std::regex_replace(body, std::regex(R"(^[ \t]*#version.*$)"), "");

  const std::string wgsl = isf_compile(glsl, why);
  if (wgsl.empty()) return "";

  const std::string credit = isf_str(head, "CREDIT");
  std::string top = "// " + name + ": " + name + ".fs, ISF" +
                    (credit.empty() ? "" : ", " + credit) +
                    ", made WGSL in Motolii (glslang, Tint)\n";
  // Shelf: uses the shelf's own category names where the ISF categories say the
  // same thing.
  if (head.HasMember("CATEGORIES") && head["CATEGORIES"].IsArray() &&
      !head["CATEGORIES"].Empty() && head["CATEGORIES"][0].IsString()) {
    std::string all, shelf = head["CATEGORIES"][0].GetString();
    for (const auto& c : head["CATEGORIES"].GetArray())
      if (c.IsString()) all += std::string(c.GetString()) + " ";
    for (const char* own :
         {"Glitch", "Distort", "Color", "Film", "Light", "Time", "Stylize"})
      if (all.find(own) != std::string::npos) {
        shelf = own;
        break;
      }
    // Vidvox names such as "Geometry Adjustment" and "Halftone Effect" are
    // shortened to "Geometry" and "Halftone", like the other names. The shelf
    // mapping above already turns "Distortion Effect" into Distort. Tabs are
    // removed so that each kind is one chip.
    shelf.erase(0, shelf.find_first_not_of(" \t")),
        shelf.erase(shelf.find_last_not_of(" \t") + 1);
    for (const std::string tail : {" Effect", " Adjustment"})
      if (shelf.size() > tail.size() &&
          shelf.compare(shelf.size() - tail.size(), tail.size(), tail) == 0)
        shelf.resize(shelf.size() - tail.size());
    // A transition (ISF_Spec: it has startImage, endImage and progress) goes on
    // one shelf whatever its wipe or dissolve style, as After Effects keeps its
    // transitions under Transition. Once applied, it runs from the playhead
    // (doc_fx_file).
    if (std::find(imageNames.begin(), imageNames.end(), "startImage") !=
            imageNames.end() &&
        std::find(imageNames.begin(), imageNames.end(), "endImage") !=
            imageNames.end() &&
        std::any_of(inputs.GetArray().begin(), inputs.GetArray().end(),
                    [&](const rapidjson::Value& i) {
                      return isf_str(i, "NAME") == "progress";
                    }))
      shelf = "Transition";
    top += "// --label:" + shelf + "\n";
  }
  // The description is kept so that the shelf can find the effect by it.
  if (std::string about = isf_str(head, "DESCRIPTION"); !about.empty()) {
    std::replace(about.begin(), about.end(), '\n', ' ');
    top += "// --about:" + about + "\n";
  }
  for (const std::string& p : passLines) lines += p + "\n";
  return top + lines + "\n" + wgsl;
}

}  // namespace motolii
