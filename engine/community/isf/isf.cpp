// Converts ISF effect files into WGSL effect files. ISF is Vidvox's Interactive
// Shader Format: a GLSL fragment shader with a JSON header that describes its
// parameters. A converted file in an effects folder works like a .wgsl file.
//
// The GLSL is compiled to SPIR-V with glslang and converted to WGSL with Tint,
// both already part of the Filament build. The JSON header is read with
// rapidjson. The shader's own lines are kept. ISF built-ins (IMG_NORM_PIXEL,
// IMG_THIS_PIXEL, isf_FragNormCoord, TIME, RENDERSIZE, ...) are defined as
// plain GLSL macros. Each image is split into a texture and a sampler. The
// parameters are gathered into one uniform struct and declared in the output
// header as "// --track@..." lines, and the passes as "// --pass@..." lines.
// engine/community/quickjs/script.h reads them.
//
// The result is cached in ~/Library/Caches/Motolii/isf/<hash>.wgsl, named by a
// hash of the file's path, modification time and size. Extra image inputs are
// bound to the images of other layers (see engine/stage/effects/screen_fx.h),
// and audio inputs to the sound of other layers. A custom vertex shader is
// evaluated at each pixel.
#include "community/isf/isf.h"

#include <sys/stat.h>

#include <fstream>
#include <regex>

#include "community/isf/isf_translate.h"
#include "community/sites/adapter.h"
#include "community/three/three_isf.h"
#include "sca/builtinResource.h"
#include "src/tint/lang/wgsl/writer/writer.h"

namespace motolii {

std::string fx_source(const std::string& f) {
  std::error_code wrong;
  if (std::filesystem::exists(f, wrong)) return f;
  static const std::regex copy(R"((.*)~[0-9]+(\.[^./]+)$)");
  std::smatch m;
  return std::regex_match(f, m, copy) ? m[1].str() + m[2].str() : f;
}

// Returns the tags of an ISF file, read from its header and body. See isf.h.
std::string isf_tags(const std::string& file) {
  std::ifstream in(file);
  const std::string text = adapter_isf(std::string(
      (std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>()));
  IsfHead head;
  if (!isf_read_head(text, head)) return "";
  const rapidjson::Value& passes = *head.passes;
  const bool sound = head.sound, transition = head.transition;
  const std::vector<std::string>& imageNames = head.images;
  // A pass kept from frame to frame: PERSISTENT in ISF_Spec, called Feedback by
  // Vidvox.
  bool feedback = false;
  for (const auto& p : passes.GetArray())
    feedback = feedback || (p.IsObject() && p.HasMember("PERSISTENT") &&
                            (p["PERSISTENT"].IsBool()
                                 ? p["PERSISTENT"].GetBool()
                                 : p["PERSISTENT"].IsNumber() &&
                                       p["PERSISTENT"].GetDouble() != 0));
  const std::string& body = head.body;
  // The uniforms of ISF_Spec's clock: a shader that reads them moves by itself.
  static const std::regex clock(R"(\b(TIME|TIMEDELTA|FRAMEINDEX|DATE)\b)");
  std::string tags;
  const auto tag = [&](bool on, const char* word) {
    if (on) tags += (tags.empty() ? "" : " ") + std::string(word);
  };
  tag(transition, "transition");
  // No image input: ISF_Spec's sources.
  tag(imageNames.empty(), "generator");
  tag(sound, "sound");
  // Shadertoy's Multipass.
  tag(passes.Size() > 1, "multipass");
  tag(feedback, "feedback");
  // The regex runs only where one of its words is present. See doc_wgsl_tags.
  tag((body.find("TIME") != std::string::npos ||
       body.find("FRAMEINDEX") != std::string::npos ||
       body.find("DATE") != std::string::npos) &&
          std::regex_search(body, clock),
      "time");
  // Another layer's image as input besides its own, like Shadertoy's Webcam, an
  // image from outside.
  tag(!transition && imageNames.size() > 1, "image");
  return tags;
}

namespace {

// The last WGSL made for each file, and why the file as it is now was not
// converted. A half-typed effect keeps drawing as it did before, as a
// half-typed script keeps what last ran in doc_script_of, and the effect card
// shows the reason through isf_trouble.
std::mutex isf_lock;
std::map<std::string, std::string> isf_good, isf_why;
// Records why the conversion failed and returns the last good output for the
// file, or "" if there is none.
std::string isf_fallback(const std::string& file, const std::string& why) {
  isf_why[file] =
      why.empty() ? std::string("it could not be turned into WGSL") : why;
  const auto good = isf_good.find(file);
  return good == isf_good.end() ? "" : good->second;
}
// Records a successful conversion, forgets any earlier failure, and returns
// `out`.
std::string isf_built(const std::string& file, const std::string& out) {
  isf_good[file] = out, isf_why.erase(file);
  return out;
}

}  // namespace

// See isf.h.
std::string isf_trouble(const std::string& asked) {
  std::lock_guard<std::mutex> hold(isf_lock);
  const auto why = isf_why.find(fx_source(asked));
  return why == isf_why.end() ? "" : why->second;
}
// See isf.h. Conversions are cached by the file's path, modification time and
// size.
std::string isf_file(const std::string& asked) {
  // A duplicated effect such as Glow~2.fs reads the content of Glow.fs
  // (engine/community/quickjs/ script.h).
  const std::string file = fx_source(asked);
  // A three.js effect is converted to ISF first (three_isf.cpp).
  if (std::filesystem::path(file).extension() != ".fs" && !three_is(file))
    return file;
  struct stat st{};
  if (stat(file.c_str(), &st) != 0) return "";
  const std::string key = "isf 15|" + file + "|" +
                          std::to_string(st.st_mtimespec.tv_sec) + "." +
                          std::to_string(st.st_mtimespec.tv_nsec) + "|" +
                          std::to_string(st.st_size);
  // What each file, as it is now, became: its last good output, or "" if it
  // could not be made.
  static std::map<std::string, std::string> built;
  std::lock_guard<std::mutex> hold(isf_lock);
  if (auto m = built.find(key); m != built.end()) return m->second;
  uint64_t hash = 1469598103934665603ull;
  for (unsigned char c : key) hash = (hash ^ c) * 1099511628211ull;
  const char* home = std::getenv("HOME");
  const std::filesystem::path dir =
      std::filesystem::path(home ? home : "/tmp") /
      "Library/Caches/Motolii/isf";
  char name[40];
  std::snprintf(name, sizeof name, "%016llx.wgsl", (unsigned long long)hash);
  const std::string out = (dir / name).string();
  std::error_code e;
  if (std::filesystem::exists(out, e)) return built[key] = isf_built(file, out);
  std::ifstream in(file);
  std::stringstream text;
  text << in.rdbuf();
  std::string why;
  if (std::filesystem::path(file).extension() == ".js") {
    const std::string isf = three_isf(file, why);
    if (isf.empty()) {
      std::fprintf(stderr, "the three.js effect %s is not taken: %s\n",
                   file.c_str(), why.substr(0, 600).c_str());
      return built[key] = isf_fallback(file, why);
    }
    text.str(isf);
  }
  const std::string stem = std::filesystem::path(file).stem().string();
  // The file's own vertex shader, if there is one beside it.
  std::stringstream vertex;
  if (std::ifstream vs(std::filesystem::path(file).replace_extension(".vs"));
      vs)
    vertex << vs.rdbuf();
  // Shadertoy and GLSL Sandbox shaders are accepted as they come (adapter.h).
  const std::string wgsl =
      isf_wgsl(adapter_isf(text.str()), stem, why, vertex.str());
  if (wgsl.empty()) {
    std::fprintf(stderr, "the ISF effect %s is not taken: %s\n", file.c_str(),
                 why.substr(0, 600).c_str());
    return built[key] = isf_fallback(file, why);
  }
  std::filesystem::create_directories(dir, e);
  std::ofstream(out + ".part") << wgsl;
  std::filesystem::rename(out + ".part", out, e);
  return built[key] = isf_built(file, out);
}

}  // namespace motolii
