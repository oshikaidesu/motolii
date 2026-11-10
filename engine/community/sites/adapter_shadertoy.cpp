#include "community/sites/adapter_shadertoy.h"

#include <algorithm>
#include <map>
#include <regex>
#include <set>
#include <string>
#include <vector>

namespace {

// Returns `t` with its // and /* */ comments removed. A block comment is
// replaced by one space.
std::string adapter_bare(const std::string& t) {
  std::string out;
  for (size_t i = 0; i < t.size(); ++i) {
    if (t.compare(i, 2, "//") == 0) {
      while (i + 1 < t.size() && t[i + 1] != '\n') ++i;
    } else if (t.compare(i, 2, "/*") == 0) {
      if ((i = t.find("*/", i)) == std::string::npos) break;
      ++i, out += ' ';
    } else
      out += t[i];
  }
  return out;
}

// What a tab names at its top level, and the macros it defines.
// Collects the names a tab declares at its top level into `names`, and the
// macros it defines into `macros`.
void adapter_tab_names(const std::string& code, std::set<std::string>& names,
                       std::set<std::string>& macros) {
  const std::string t = adapter_bare(code);
  static const std::regex function(R"((\w+)\s*\()"),
      one(R"((\w+)\s*(?:\[[^\]]*\]\s*)?$)"), kind(R"(^\s*struct\s+(\w+))"),
      macro(R"(^\s*#\s*define\s+(\w+))");
  std::string head;
  // The depth of nested braces.
  int deep = 0;
  // True while only whitespace has been seen on the current line.
  bool fresh = true;
  // Records the name declared by the text gathered in `head`: a struct, a
  // function or variables. `opens` is true when that text ended at a '{'.
  const auto said = [&](bool opens) {
    std::smatch m;
    const size_t equals = head.find('='), paren = head.find('(');
    if (std::regex_search(head, m, kind))
      names.insert(m[1]);
    else if (head.find("precision") != std::string::npos) {
    } else if (paren != std::string::npos && (opens || paren < equals)) {
      if (std::regex_search(head, m, function)) names.insert(m[1]);
    } else if (!opens) {
      // A declaration statement. Take every name it declares, for example both
      // a and b in `const vec3 a = vec3(1.), b = vec3(2.);`.
      std::string part;
      int inner = 0;
      const auto take = [&] {
        const std::string name = part.substr(0, part.find('='));
        if (std::regex_search(name, m, one)) names.insert(m[1]);
        part.clear();
      };
      for (const char c : head) {
        inner += (c == '(') - (c == ')');
        if (c == ',' && !inner)
          take();
        else
          part += c;
      }
      take();
    }
    head.clear();
  };
  for (size_t i = 0; i < t.size(); ++i) {
    const char c = t[i];
    if (fresh && c == '#') {
      // A preprocessor line, including any continuation lines that end in a
      // backslash.
      size_t end = i;
      while ((end = t.find('\n', end)) != std::string::npos &&
             t[end - 1] == '\\')
        ++end;
      const std::string line =
          t.substr(i, end == std::string::npos ? end : end - i);
      std::smatch m;
      if (std::regex_search(line, m, macro)) macros.insert(m[1]);
      if (end == std::string::npos) break;
      i = end;
      continue;
    }
    fresh = c == '\n' || (fresh && (c == ' ' || c == '\t' || c == '\r'));
    if (c == '{' && !deep++)
      said(true);
    else if (c == '}')
      --deep;
    else if (!deep && c == ';')
      said(false);
    else if (!deep)
      head += c;
  }
}

}  // namespace

std::string adapter_toy_clean(const std::string& text) {
  // Any other uniform that is not a sampler loses its `uniform` keyword and
  // becomes a global variable. Nothing sets it here, so it stays 0, as it does
  // on the site.
  static const std::regex left(R"(\buniform\s+(?!sampler))");
  return std::regex_replace(
      std::regex_replace(
          text,
          std::regex(
              R"(#iChannel[0-9][^\n]*|#version[^\n]*|#define\s+(?:iTime|iResolution|iMouse)\b[^\n]*|\buniform\s+\w+\s+(?:iTime|iGlobalTime|iResolution|iMouse|iFrame|iDate|iTimeDelta|iFrameRate|iSampleRate|iChannelTime|iChannelResolution|iChannel[0-9]|time|resolution|mouse)\s*(?:\[\s*\d*\s*\])?\s*;)"),
          ""),
      left, "");
}

std::string adapter_tabs_isf(std::string common, std::vector<AdapterTab> tabs,
                             bool film, const std::string& about,
                             const std::string& credit) {
  const bool mouse =
      common.find("iMouse") != std::string::npos ||
      std::any_of(tabs.begin(), tabs.end(), [](const AdapterTab& t) {
        return t.code.find("iMouse") != std::string::npos;
      });
  // Names that ISF reserves for its own parameters (see community/isf/isf.cpp).
  // A tab cannot declare them either.
  static const std::set<std::string> taken = {
      "time",      "resolution",  "frame",     "passindex",
      "clip_time", "clip_length", "frameRect", "passRect"};
  // If Common refers to iChannel, its meaning differs from tab to tab, so
  // Common's code is copied into every tab.
  const bool apart = common.find("iChannel") != std::string::npos;
  if (apart)
    for (AdapterTab& t : tabs) t.code = common + t.code;
  std::vector<std::set<std::string>> names(tabs.size()), macros(tabs.size());
  std::map<std::string, int> many;
  std::set<std::string> shared, own;
  adapter_tab_names(common, own, shared);
  for (size_t k = 0; k < tabs.size(); ++k) {
    // Count how many tabs declare each name. A reserved name counts double, so
    // it is always renamed.
    adapter_tab_names(tabs[k].code, names[k], macros[k]);
    names[k].erase("mainImage");
    for (const std::string& n : names[k]) many[n] += taken.count(n) ? 2 : 1;
  }
  // Names that Common declares and ISF also reserves are renamed to
  // <name>_common. `first` holds the #define lines placed before the code and
  // `last` the matching #undef lines placed after it.
  std::string first, last;
  for (const std::string& n : own)
    if (taken.count(n))
      first += "#define " + n + " " + n + "_common\n",
          last += "#undef " + n + "\n";
  if (!shared.count("texelFetch"))
    first = "#define isf_fetch adapter_texelFetch\n" + first;
  std::string body;
  for (size_t k = 0; k < tabs.size(); ++k) {
    std::string before =
                    "#define mainImage adapter_tab_" + std::to_string(k) + "\n",
                after = "#undef mainImage\n";
    for (int n = 0; n < 4; ++n)
      before += "#define iChannel" + std::to_string(n) + " " +
                std::to_string(tabs[k].channel[n]) + "\n",
          after += "#undef iChannel" + std::to_string(n) + "\n";
    for (const std::string& n : names[k])
      if (many[n] > 1)
        before += "#define " + n + " " + n + "_" + std::to_string(k) + "\n",
            after += "#undef " + n + "\n";
    for (const std::string& n : macros[k])
      if (!shared.count(n) && !many.count(n)) after += "#undef " + n + "\n";
    // A tab that defines its own texelFetch, as WebGL1 does, replaces ISF's
    // version, which isf.cpp declares under the name isf_fetch.
    if (macros[k].count("texelFetch") && !shared.count("texelFetch"))
      before += "#undef isf_fetch\n",
          after += "#undef isf_fetch\n#define isf_fetch adapter_texelFetch\n";
    body += "\n// ---- " + tabs[k].name + " ----\n" + before + tabs[k].code +
            "\n" + after;
  }
  // For each buffer: a PASSES entry, and the cases of adapter_read and
  // adapter_pixel that read it.
  std::string passes, reads, pixels;
  for (size_t k = 0; k + 1 < tabs.size(); ++k) {
    passes += "{\"TARGET\":\"" + tabs[k].target +
              "\",\"PERSISTENT\":true,\"FLOAT\":true},";
    reads += "if(k==" + std::to_string(k + 1) + ")return texture(isf_img_" +
             tabs[k].target + ",p);";
    pixels += "if(k==" + std::to_string(k + 1) + ")return texelFetch(isf_img_" +
              tabs[k].target + ",p,0);";
  }
  if (film)
    reads += "if(k==0)return texture(isf_img_inputImage,p);",
        pixels += "if(k==0)return texelFetch(isf_img_inputImage,p,0);";
  // The generated main runs the tab that belongs to the current pass.
  std::string run;
  for (size_t k = 0; k < tabs.size(); ++k)
    run +=
        (k ? "else " : "") +
        std::string(tabs.size() > 1 ? "if(PASSINDEX==" + std::to_string(k) + ")"
                                    : "") +
        "adapter_tab_" + std::to_string(k) +
        "(adapter_out,floor(gl_FragCoord.xy)+.5);";
  // Comments on the generated text below.
  // adapter_given sets the Shadertoy uniforms. iMouse comes from a 2D point
  // input that the user can animate with keyframes. The mouse counts as pressed
  // whenever the point is not at (0, 0), and z and w follow Shadertoy's sign
  // convention for iMouse. adapter_smoothstep exists because Tint, the WebGPU
  // shader compiler, rejects smoothstep calls whose edges are known to be equal
  // at compile time, while a GPU draws them. After the tabs, texture is defined
  // the way isf.cpp defines it, so code that follows reads images as usual.
  return std::string("/*{\"ISFVSN\":\"2\",\"DESCRIPTION\":\"") + about + "\"," +
         (credit.empty() ? "" : "\"CREDIT\":\"" + credit + "\",") +
         "\"CATEGORIES\":[\"Shadertoy\"],\"INPUTS\":[" +
         (film ? "{\"NAME\":\"inputImage\",\"TYPE\":\"image\"}" : "") +
         (film && mouse ? "," : "") +
         (mouse ? "{\"NAME\":\"adapter_mouse\",\"LABEL\":\"Mouse\",\"TYPE\":"
                  "\"point2D\",\"DEFAULT\":[0,0]}"
                : "") +
         "]" + (tabs.size() > 1 ? ",\"PASSES\":[" + passes + "{}]" : "") +
         "}*/\n"
         "vec3 iResolution,iChannelResolution[4];float "
         "iTime,iGlobalTime,iTimeDelta,iFrameRate,iSampleRate,iChannelTime[4];"
         "int iFrame;vec4 iMouse,iDate;\n"
         "void "
         "adapter_given(){iResolution=vec3(RENDERSIZE,1.);iChannelResolution="
         "vec3[4](iResolution,iResolution,iResolution,iResolution);iTime="
         "iGlobalTime=TIME;iChannelTime=float[4](TIME,TIME,TIME,TIME);"
         "iTimeDelta=TIMEDELTA;iFrameRate=1./"
         "TIMEDELTA;iSampleRate=44100.;iFrame=FRAMEINDEX;iDate=DATE;" +
         (mouse ? "vec2 "
                  "m=adapter_mouse*RENDERSIZE;iMouse=m==vec2(0.)?vec4(0.):vec4("
                  "m,m.x,-m.y);"
                : "iMouse=vec4(0.);") +
         "}\n"
         "float adapter_smoothstep(float a,float b,float x){return "
         "smoothstep(a,b,x);}\nvec2 adapter_smoothstep(float a,float b,vec2 "
         "x){return smoothstep(a,b,x);}\nvec3 adapter_smoothstep(float a,float "
         "b,vec3 x){return smoothstep(a,b,x);}\nvec4 adapter_smoothstep(float "
         "a,float b,vec4 x){return smoothstep(a,b,x);}\nvec2 "
         "adapter_smoothstep(vec2 a,vec2 b,vec2 x){return "
         "smoothstep(a,b,x);}\nvec3 adapter_smoothstep(vec3 a,vec3 b,vec3 "
         "x){return smoothstep(a,b,x);}\nvec4 adapter_smoothstep(vec4 a,vec4 "
         "b,vec4 x){return smoothstep(a,b,x);}\n"
         "vec4 adapter_read(int k,vec2 p){if(k>=16){k-=16;p=fract(p);}" +
         reads +
         "return vec4(0.);}\nvec4 adapter_pixel(int k,ivec2 "
         "p){k=k&15;p.y=int(RENDERSIZE.y)-1-p.y;" +
         pixels +
         "return vec4(0.);}\n"
         "vec4 adapter_texture(int k,vec2 p){return adapter_read(k,p);}\nvec4 "
         "adapter_texture(int k,vec2 p,float b){return "
         "adapter_read(k,p);}\nvec4 adapter_textureLod(int k,vec2 p,float "
         "l){return adapter_read(k,p);}\nvec4 adapter_textureGrad(int k,vec2 "
         "p,vec2 a,vec2 b){return adapter_read(k,p);}\n"
         "vec4 adapter_textureOffset(int k,vec2 p,ivec2 o){return "
         "adapter_read(k,p+vec2(o)/RENDERSIZE);}\nvec4 "
         "adapter_textureLodOffset(int k,vec2 p,float l,ivec2 o){return "
         "adapter_read(k,p+vec2(o)/RENDERSIZE);}\n"
         "vec4 adapter_texture(int k,vec3 p){return vec4(0.);}\nvec4 "
         "adapter_texture(int k,vec3 p,float b){return vec4(0.);}\nvec4 "
         "adapter_textureLod(int k,vec3 p,float l){return vec4(0.);}\n"
         "vec4 adapter_texelFetch(int k,ivec2 p,int l){return "
         "adapter_pixel(k,p);}\nvec4 adapter_texelFetchOffset(int k,ivec2 "
         "p,int l,ivec2 o){return adapter_pixel(k,p+o);}\nivec2 "
         "adapter_textureSize(int k,int l){return ivec2(RENDERSIZE);}\n"
         "#undef TIME\n#undef texture\n#undef textureLod\n#undef "
         "textureSize\n#undef isf_fetch\n#define texture "
         "adapter_texture\n#define textureLod adapter_textureLod\n#define "
         "textureGrad adapter_textureGrad\n#define textureOffset "
         "adapter_textureOffset\n#define textureLodOffset "
         "adapter_textureLodOffset\n#define texelFetchOffset "
         "adapter_texelFetchOffset\n#define textureSize "
         "adapter_textureSize\n#define sampler2D int\n#define sampler3D "
         "int\n#define samplerCube int\n#define sampler "
         "adapter_sampler\n#define smoothstep adapter_smoothstep\n" +
         first + (apart ? "" : "\n// ---- Common ----\n" + common) + body +
         "\n" + last +
         "#undef texture\n#undef textureLod\n#undef sampler2D\n#define "
         "texture(i, c) textureLod(i, isf_up(c) * frameRect.zw + frameRect.xy, "
         "0.0)\n"
         "void main(){adapter_given();vec4 adapter_out=vec4(0.,0.,0.,1.);" +
         run + "gl_FragColor=PASSINDEX==" + std::to_string(tabs.size() - 1) +
         "?vec4(adapter_out.rgb,1.):adapter_out;}\n";
}
