// Converts ISF effect files into WGSL effect files. ISF is Vidvox's Interactive Shader Format: a
// GLSL fragment shader with a JSON header that describes its parameters. A converted file in an
// effects folder works like a .wgsl file.
//
// The GLSL is compiled to SPIR-V with glslang and converted to WGSL with Tint, both already part of
// the Filament build. The JSON header is read with rapidjson. The shader's own lines are kept. ISF
// built-ins (IMG_NORM_PIXEL, IMG_THIS_PIXEL, isf_FragNormCoord, TIME, RENDERSIZE, ...) are defined
// as plain GLSL macros. Each image is split into a texture and a sampler. The parameters are
// gathered into one uniform struct and declared in the output header as "// --track@..." lines,
// and the passes as "// --pass@..." lines. engine/community/quickjs/script.h reads them.
//
// The result is cached in ~/Library/Caches/Motolii/isf/<hash>.wgsl, named by a hash of the file's
// path, modification time and size. Extra image inputs are bound to the images of other layers (see
// engine/stage/effects/screen_fx.h), and audio inputs to the sound of other layers. A custom vertex
// shader is evaluated at each pixel.
#include "community/isf/isf.h"
#include "community/sites/adapter.h"
#include "community/three/three_isf.h"
#include <sys/stat.h>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <map>
#include <mutex>
#include <regex>
#include <sstream>
#include <vector>
#include "rapidjson/document.h"
#include <sqlite3.h>
#include "glslang/Public/ShaderLang.h"
#include "SPIRV/GlslangToSpv.h"
#include "sca/builtinResource.h"
#include "src/tint/lang/core/ir/module.h"
#include "src/tint/lang/wgsl/program/program.h"
#include "src/tint/lang/spirv/reader/reader.h"
#include "src/tint/lang/wgsl/writer/writer.h"

// Converts the text of an ISF file into WGSL. `name` is used in the output header and `vertex` is
// the source of an optional custom vertex shader. Returns the WGSL, or "" with the reason in `why`.
static std::string isf_wgsl(const std::string& text, const std::string& name, std::string& why, std::string vertex = "") {
    const size_t open = text.find("/*"), close = text.find("*/");
    rapidjson::Document head;
    if (open == std::string::npos || close == std::string::npos || head.Parse(text.c_str() + open + 2, close - open - 2).HasParseError() || !head.IsObject())
        return why = "no ISF head (a JSON comment at the top)", "";
    std::string body = text.substr(close + 2);
    const auto str = [](const rapidjson::Value& o, const char* k, std::string fallback = "") { return o.IsObject() && o.HasMember(k) && o[k].IsString() ? std::string(o[k].GetString()) : fallback; };
    const auto num = [](const rapidjson::Value& v, double fallback) { return v.IsNumber() ? v.GetDouble() : v.IsBool() ? (double)v.GetBool() : fallback; };

    // Passes are drawn in turn, each into an image of its own, except the last, which is drawn to
    // the output. A pass image keeps its contents from frame to frame when PERSISTENT is set and
    // uses a float format when FLOAT is set. Its size is a share of the frame size or a number of
    // pixels.
    //
    // Reads one side of a pass size (`k` is WIDTH or HEIGHT; `side` names the frame side it may
    // refer to) and stores it in `said`. The result is "s<share>" for a share of the frame side or
    // "a<pixels>" for an absolute size. Returns false if the size cannot be expressed.
    const auto size = [&](const rapidjson::Value& p, const char* k, const char* side, std::string& said) {
        std::string e = p.HasMember(k) ? (p[k].IsString() ? p[k].GetString() : std::to_string((int)num(p[k], 0))) : std::string("$") + side;
        e.erase(std::remove(e.begin(), e.end(), ' '), e.end());
        std::smatch m;
        char out[32];
        if (std::regex_match(e, m, std::regex(std::string(R"((?:floor\()?\$)") + side + R"((?:/([\d.]+))?(?:\*([\d.]+))?\)?)")))
            return std::snprintf(out, sizeof out, "s%g", (m[1].matched ? 1 / std::stod(m[1]) : 1) * (m[2].matched ? std::stod(m[2]) : 1)), said = out, true;
        if (std::regex_match(e, std::regex(R"([\d.]+)"))) return said = "a" + std::to_string((int)std::stod(e)), true;
        // Any other expression is evaluated by SQLite with $WIDTH and $HEIGHT bound as parameters,
        // using 1000 pixels as the frame size. If it reads the frame size, the result is a share of
        // the frame value / 1000. If it reads no parameter, the result is a number of pixels. An
        // expression with any other parameter is rejected.
        sqlite3* db = nullptr;
        sqlite3_stmt* q = nullptr;
        double v = -1;
        if (sqlite3_open(":memory:", &db) == SQLITE_OK && sqlite3_prepare_v2(db, ("SELECT " + e).c_str(), -1, &q, nullptr) == SQLITE_OK) {
            bool known = true;
            for (int i = 1; i <= sqlite3_bind_parameter_count(q); ++i) {
                const std::string n = sqlite3_bind_parameter_name(q, i) ? sqlite3_bind_parameter_name(q, i) : "";
                if (n == "$WIDTH" || n == "$HEIGHT") sqlite3_bind_double(q, i, 1000);
                else known = false;
            }
            if (known && sqlite3_step(q) == SQLITE_ROW && sqlite3_column_type(q, 0) != SQLITE_NULL) v = sqlite3_column_double(q, 0);
        }
        sqlite3_finalize(q);
        sqlite3_close(db);
        if (v <= 0) return false;
        if (e.find('$') != std::string::npos) return std::snprintf(out, sizeof out, "s%g", v / 1000), said = out, true;
        return said = "a" + std::to_string((int)v), true;
    };
    std::vector<std::string> targets, passLines;
    // For each pass target: whether its width and its height are absolute sizes rather than a share
    // of the frame.
    std::map<std::string, std::pair<bool, bool>> setSize;
    if (head.HasMember("PASSES") && head["PASSES"].IsArray())
        for (const auto& p : head["PASSES"].GetArray()) {
            const std::string t = str(p, "TARGET");
            std::string w, h;
            if (!size(p, "WIDTH", "WIDTH", w) || !size(p, "HEIGHT", "HEIGHT", h)) return why = "a pass's size it cannot say", "";
            if (!t.empty() && std::find(targets.begin(), targets.end(), t) == targets.end()) targets.push_back(t);
            if (!t.empty()) setSize[t] = {w.rfind("a", 0) == 0, h.rfind("a", 0) == 0};
            const bool persistent = p.HasMember("PERSISTENT") && num(p["PERSISTENT"], 0), fine = p.HasMember("FLOAT") && num(p["FLOAT"], 0);
            passLines.push_back("// --pass@" + t + ":" + (persistent ? "1" : "0") + "," + (fine ? "1" : "0") + "," + w + "," + h);
        }

    const rapidjson::Value none(rapidjson::kArrayType);
    const rapidjson::Value& inputs = head.HasMember("INPUTS") && head["INPUTS"].IsArray() ? head["INPUTS"] : none;
    std::vector<std::string> imageNames;
    for (const auto& i : inputs.GetArray()) if (str(i, "TYPE") == "image") imageNames.push_back(str(i, "NAME"));
    // An ISF file without image inputs is a generator (ISF_Spec distinguishes sources, filters and
    // transitions). On a layer it paints only where the layer is, like After Effects' Preserve
    // Underlying Transparency. The layer's own image is still bound at binding 0, as the interop
    // expects.
    const std::string inputName = imageNames.empty() ? "inputImage" : std::find(imageNames.begin(), imageNames.end(), "inputImage") != imageNames.end() ? "inputImage" : imageNames[0];
    // Other image inputs: each is the image of another layer, chosen on the effect card, and is
    // bound after the images of the passes.
    std::vector<std::string> others;
    for (const std::string& other : imageNames) if (other != inputName) others.push_back(other);
    // Audio inputs are images as the spec says, bound after the other images.
    for (const auto& i : inputs.GetArray()) if (str(i, "TYPE") == "audio" || str(i, "TYPE") == "audioFFT") others.push_back(str(i, "NAME"));

    const std::map<std::string, std::string> kinds = {{"float", "float"}, {"bool", "int"}, {"long", "int"}, {"event", "int"}, {"point2D", "vec2"}, {"color", "vec4"}};
    std::string glsl = "#version 450\n";
    // Each image becomes a texture and a sampler named after it. The names are put in front of
    // ISF's macros by pasting. A name that the shader also uses for a variable of its own is left
    // alone. Only the input image can also be used by its bare name.
    std::vector<std::string> read = {inputName};
    read.insert(read.end(), targets.begin(), targets.end());
    for (size_t k = 0; k < read.size(); ++k)
        glsl += "layout(set = 0, binding = " + std::to_string(2 * k) + ") uniform texture2D isf_tex_" + read[k] + ";\nlayout(set = 0, binding = " + std::to_string(2 * k + 1) + ") uniform sampler isf_smp_" + read[k] + ";\n";
    for (size_t k = 0; k < others.size(); ++k)
        glsl += "layout(set = 0, binding = " + std::to_string(2 * (read.size() + k)) + ") uniform texture2D isf_tex_" + others[k] + ";\nlayout(set = 0, binding = " + std::to_string(2 * (read.size() + k) + 1) + ") uniform sampler isf_smp_" + others[k] + ";\n";
    // The parameter struct also holds the values of the layer: clip_time is the seconds into the
    // layer and clip_length is how long it lasts (engine/document/moment_fx.h). The frame has
    // neither.
    glsl += "layout(set = 0, binding = " + std::to_string(2 * (read.size() + others.size())) + ") uniform Parameters {\n  float time;\n  vec2 resolution;\n  float frame;\n  float isf_rate;\n  float passindex;\n  float clip_time;\n  float clip_length;\n  vec4 frameRect;\n  vec4 passRect;\n";
    // On/off parameters. They are stored as int because WGSL keeps no bool in a uniform. Uses of
    // the name in the shader are rewritten to read as a bool, except where the name is a member of
    // a color such as .r.
    std::vector<std::string> switches;
    std::string lines;
    for (const auto& k : inputs.GetArray()) {
        const std::string t = str(k, "TYPE"), n = str(k, "NAME");
        if (!kinds.count(t)) continue;
        const bool onoff = t == "bool" || t == "event";
        glsl += "  " + kinds.at(t) + " " + n + (onoff ? "_on" : "") + ";\n";
        if (onoff) switches.push_back(n);
        std::string label = str(k, "LABEL", n);
        std::replace(label.begin(), label.end(), ',', ' ');
        const auto at = [&](const char* key, int i, double fallback) {
            if (!k.HasMember(key)) return fallback;
            const rapidjson::Value& v = k[key];
            return v.IsArray() ? (i < (int)v.Size() ? num(v[(rapidjson::SizeType)i], fallback) : fallback) : num(v, fallback);
        };
        char line[256];
        if (onoff) std::snprintf(line, sizeof line, "// --check@%s_on:%s,%d\n", n.c_str(), label.c_str(), (int)at("DEFAULT", 0, 0)), lines += line;
        else if (t == "float" || t == "long")
        {
        // The choices of a long are its VALUES (ISF_Spec). Its range runs from the smallest to the
        // largest of them.
            double lo = at("MIN", 0, 0), hi = at("MAX", 0, 1);
            if (t == "long" && k.HasMember("VALUES") && k["VALUES"].IsArray() && !k["VALUES"].Empty()) {
                lo = hi = num(k["VALUES"][0], 0);
                for (const auto& v : k["VALUES"].GetArray()) lo = std::min(lo, num(v, lo)), hi = std::max(hi, num(v, hi));
            }
            std::snprintf(line, sizeof line, "// --track@%s:%s,%g,%g,%g,%g\n", n.c_str(), label.c_str(), lo, hi, at("DEFAULT", 0, 0), t == "long" ? 1.0 : 0.001), lines += line;
        }
        else
            for (int i = 0; i < (t == "point2D" ? 2 : 4); ++i)
                std::snprintf(line, sizeof line, "// --track@%s_%c:%s %c,%g,%g,%g,0.001\n", n.c_str(), "xyzw"[i], label.c_str(), (t == "point2D" ? "xyzw" : "rgba")[i], at("MIN", i, 0), at("MAX", i, 1), at("DEFAULT", i, 0)), lines += line;
    }
    for (const std::string& n : others) glsl += "  vec4 isf_other_" + n + ";\n";
    glsl += "};\n";
    for (const std::string& n : switches)
        for (std::string* t : {&body, &vertex}) *t = std::regex_replace(*t, std::regex("(^|[^.\\w])" + n + "\\b"), "$1(" + n + "_on != 0)");
    // ISF coordinates run up from the bottom left, as WebGL's do (ISF_Spec). WebGPU coordinates run
    // down from the top left. The coordinate, the pixel's own and every image read are flipped
    // alike, so an image read at a location stays as it was.
    glsl += "layout(location = 0) in vec2 isf_FragNormCoord_down;\nlayout(location = 0) out vec4 isf_FragColor;\n";
    // Coordinates and reads are relative to the frame: 0 to 1 over the layer, continuing beyond it
    // where the image is larger. This follows After Effects, which separates width and height from
    // its buffer, and which gives points in the layer's own space (PF_InData). Cutting what the
    // effect draws beyond the frame is the host's job, as with SkImageFilters::Crop after each
    // effect.
    glsl += "#define isf_here ((isf_FragNormCoord_down - passRect.xy) / passRect.zw)\n#define isf_FragNormCoord vec2(isf_here.x, 1.0 - isf_here.y)\n#define isf_up(c) vec2((c).x, 1.0 - (c).y)\n";
    glsl += "#define isf_in(r, i, c) textureLod(i, isf_up(c) * (r).zw + (r).xy, 0.0)\n#define isf_in_pixel(r, i, c) isf_in(r, i, (c) / RENDERSIZE)\n#define isf_in_here(r, i) isf_in(r, i, isf_FragNormCoord)\n";
    for (const std::string& n : others) {
        std::string label = n;
        // For an audio input: its kind and how many values it wants (MAX; when absent, as many as
        // are read).
        std::string sound;
        for (const auto& i : inputs.GetArray())
            if (str(i, "NAME") == n) label = str(i, "LABEL", n), sound = str(i, "TYPE") == "audioFFT" ? ",fft," : str(i, "TYPE") == "audio" ? ",wave," : "", sound += sound.empty() ? "" : std::to_string((int)(i.HasMember("MAX") ? num(i["MAX"], 0) : 0));
        std::replace(label.begin(), label.end(), ',', ' ');
        lines += (sound.empty() ? "// --picture@" : "// --sound@") + n + ":" + label + sound + "\n";
        // Read through ISF's macros like the other images.
        read.push_back(n);
    }
    for (const std::string& n : others) glsl += "#define " + n + " sampler2D(isf_tex_" + n + ", isf_smp_" + n + ")\n";
    glsl += "#define " + inputName + " sampler2D(isf_tex_" + inputName + ", isf_smp_" + inputName + ")\n";
    // ISF_Spec defines DATE.w as the seconds of the day. Here it is the project's own time, a clock
    // that runs as the video does like Alight Motion's Timecode.
    glsl += "#define TIME time\n#define RENDERSIZE resolution\n#define TIMEDELTA (1.0 / isf_rate)\n#define FRAMEINDEX int(frame)\n#define PASSINDEX int(passindex)\n#define DATE vec4(0.0, 0.0, 0.0, TIME)\n";
    // VVISF's names for the rect and size of an image. Each is as large as the frame here.
    for (const std::string& n : read) glsl += "#define isf_img_" + n + " sampler2D(isf_tex_" + n + ", isf_smp_" + n + ")\n#define _" + n + "_imgRect vec4(0.0, 0.0, RENDERSIZE)\n#define _" + n + "_imgSize RENDERSIZE\n#define _" + n + "_flip false\n";
    // ISF 1's name for isf_FragNormCoord, which VVISF still accepts.
    glsl += "#define vv_FragNormCoord isf_FragNormCoord\n";
    glsl += "#define IMG_NORM_PIXEL(i, c) texture(i, c)\n#define IMG_PIXEL(i, c) texture(i, (c) / RENDERSIZE)\n";
    glsl += "#define IMG_THIS_NORM_PIXEL(i) texture(i, isf_FragNormCoord)\n#define IMG_THIS_PIXEL(i) texture(i, isf_FragNormCoord)\n#define IMG_SIZE(i) RENDERSIZE\n";
    body = std::regex_replace(body, std::regex(R"((\bIMG_(?:NORM_PIXEL|PIXEL|THIS_PIXEL|THIS_NORM_PIXEL|SIZE)\s*\(\s*)(\w+))"), "$1isf_img_$2");
    glsl += "#define gl_FragColor isf_FragColor\n#define texture2D texture\n#define varying //\n";
    glsl += "#define texture(i, c) textureLod(i, isf_up(c) * frameRect.zw + frameRect.xy, 0.0)\n#define gl_FragCoord vec4(isf_here.x * RENDERSIZE.x, (1.0 - isf_here.y) * RENDERSIZE.y, gl_FragCoord.zw)\n";
    // textureSize and texelFetch address the frame part of an image too. WGSL samples with
    // derivatives only where every pixel takes the same path, so these read the top level anywhere.
    glsl += "#define textureSize(i, l) ivec2(vec2(textureSize(i, l)) * frameRect.zw + 0.5)\n#define isf_fetch(i, p, l) texelFetch(i, ivec2(p) + ivec2(frameRect.xy * RENDERSIZE / passRect.zw + 0.5), l)\n";
    // A custom vertex shader: what it passes on, mostly neighbouring coordinates, is computed at
    // each pixel before the pixel's own work. The result is the same because the coordinates are
    // linear across the frame.
    if (!vertex.empty()) {
        const std::regex said(R"(^[ \t]*(?:varying|out|in)[ \t]+(\w+)[ \t]+(\w+)([ \t]*\[[^\]]*\])?[ \t]*;)", std::regex::multiline);
        // Each varying by name: its type, and the array size when it is an array.
        std::map<std::string, std::string> handed;
        for (const std::string* t : {&vertex, &body})
            for (std::sregex_iterator m(t->begin(), t->end(), said), end; m != end; ++m) handed[(*m)[2].str() + (*m)[3].str()] = (*m)[1];
        vertex = std::regex_replace(std::regex_replace(vertex, said, ""), std::regex(R"(\bvoid\s+main\s*\()"), "void isf_vs_main(");
        body = std::regex_replace(std::regex_replace(body, said, ""), std::regex(R"(\bvoid\s+main\s*\()"), "void isf_fs_main(");
        glsl += "#define isf_vertShaderInit()\nvec4 isf_vs_position;\n#define gl_Position isf_vs_position\n";
        for (const auto& [n, type] : handed) glsl += type + " " + n + ";\n";
        vertex = std::regex_replace(vertex, std::regex(R"(\b(IMG_(?:NORM_PIXEL|PIXEL|THIS_PIXEL|THIS_NORM_PIXEL|SIZE)\s*\(\s*)(\w+))"), "$1isf_img_$2");
        body = std::regex_replace(vertex, std::regex(R"(^[ \t]*#version.*$)"), "") + "\n" + body + "\nvoid main() { isf_vs_main(); isf_fs_main(); }\n";
    }
    // Some files (for example Sashimono's) define their own flip of a pixel number. That definition
    // is kept and its reads go through the frame.
    const std::regex flipped(R"(#define\s+texelFetch\s*\(\s*t\s*,\s*p\s*,\s*l\s*\)\s*texelFetch\b)");
    const bool turns = std::regex_search(body, flipped);
    body = std::regex_replace(std::regex_replace(body, flipped, "#define isf_turned(t, p, l) isf_fetch"), std::regex(R"(\btexelFetch\s*\()"), turns ? "isf_turned(" : "isf_fetch(");
    // Images that are not the frame: the other inputs, each at the rect given by its uniform, and
    // targets with an absolute size, whose absolute sides cover the whole image.
    std::map<std::string, std::string> apart;
    for (const std::string& n : others) apart[n] = "isf_other_" + n;
    for (const auto& [n, set] : setSize)
        if (set.first || set.second) apart[n] = std::string("vec4(") + (set.first ? "0.0" : "frameRect.x") + ", " + (set.second ? "0.0" : "frameRect.y") + ", " + (set.first ? "1.0" : "frameRect.z") + ", " + (set.second ? "1.0" : "frameRect.w") + ")";
    for (const auto& [n, r] : apart) {
        body = std::regex_replace(body, std::regex(R"(\bIMG_NORM_PIXEL\s*\(\s*isf_img_)" + n + R"(\b)"), "isf_in(" + r + ", isf_img_" + n);
        body = std::regex_replace(body, std::regex(R"(\bIMG_PIXEL\s*\(\s*isf_img_)" + n + R"(\b)"), "isf_in_pixel(" + r + ", isf_img_" + n);
        body = std::regex_replace(body, std::regex(R"(\bIMG_THIS(?:_NORM)?_PIXEL\s*\(\s*isf_img_)" + n + R"(\b)"), "isf_in_here(" + r + ", isf_img_" + n);
        body = std::regex_replace(body, std::regex(R"(\btexture(?:2D)?\s*\(\s*(?:isf_img_)?)" + n + R"(\b)"), "isf_in(" + r + ", isf_img_" + n);
    }
    // A generator: its last pass is as transparent as the layer under it (Preserve Underlying
    // Transparency).
    if (imageNames.empty())
        body = std::regex_replace(body, std::regex(R"(\bvoid\s+main\s*\()"), "void isf_source_main(") + "\nvoid main() { isf_source_main(); if (PASSINDEX == " + std::to_string(std::max<int>((int)passLines.size() - 1, 0)) + ") isf_FragColor.a *= texture(" + inputName + ", isf_FragNormCoord).a; }\n";
    glsl += "#line 1\n" + std::regex_replace(body, std::regex(R"(^[ \t]*#version.*$)"), "");

    static std::once_flag once;
    std::call_once(once, [] { glslang::InitializeProcess(); });
    glslang::TShader sh(EShLangFragment);
    const char* src = glsl.c_str();
    sh.setStrings(&src, 1);
    // WebGPU is treated like GLSL ES, as WebGL is, where the compiler defines GL_ES itself. This
    // leaves out the #ifndef GL_ES parts of an ISF file, as Vidvox's ISF-JS-Renderer does.
    sh.setPreamble("#define GL_ES 1\n");
    sh.setEnvInput(glslang::EShSourceGlsl, EShLangFragment, glslang::EShClientVulkan, 100);
    sh.setEnvClient(glslang::EShClientVulkan, glslang::EShTargetVulkan_1_1);
    sh.setEnvTarget(glslang::EShTargetSpv, glslang::EShTargetSpv_1_3);
    const EShMessages msg = EShMessages(EShMsgSpvRules | EShMsgVulkanRules);
    if (!sh.parse(&DefaultTBuiltInResource, 450, false, msg)) return why = std::string("GLSL: ") + sh.getInfoLog(), "";
    glslang::TProgram program;
    program.addShader(&sh);
    if (!program.link(msg)) return why = std::string("GLSL: ") + program.getInfoLog(), "";
    std::vector<uint32_t> spv;
    glslang::GlslangToSpv(*program.getIntermediate(EShLangFragment), spv);
    auto ir = tint::spirv::reader::ReadIR(spv);
    if (ir != tint::Success) return why = "SPIR-V: " + ir.Failure().reason, "";
    tint::wgsl::writer::Options o;
    o.allow_non_uniform_derivatives = true;
    auto built = tint::wgsl::writer::ProgramFromIR(ir.Get(), o);
    if (built != tint::Success) return why = "WGSL: " + built.Failure().reason, "";
    auto wgsl = tint::wgsl::writer::Generate(built.Get(), o);
    if (wgsl != tint::Success) return why = "WGSL: " + wgsl.Failure().reason, "";

    const std::string credit = str(head, "CREDIT");
    std::string top = "// " + name + ": " + name + ".fs, ISF" + (credit.empty() ? "" : ", " + credit) + ", made WGSL in Motolii (glslang, Tint)\n";
    // Shelf: uses the shelf's own category names where the ISF categories say the same thing.
    if (head.HasMember("CATEGORIES") && head["CATEGORIES"].IsArray() && !head["CATEGORIES"].Empty() && head["CATEGORIES"][0].IsString()) {
        std::string all, shelf = head["CATEGORIES"][0].GetString();
        for (const auto& c : head["CATEGORIES"].GetArray()) if (c.IsString()) all += std::string(c.GetString()) + " ";
        for (const char* own : {"Glitch", "Distort", "Color", "Film", "Light", "Time", "Stylize"}) if (all.find(own) != std::string::npos) { shelf = own; break; }
        // Vidvox names such as "Geometry Adjustment" and "Halftone Effect" are shortened to
        // "Geometry" and "Halftone", like the other names. The shelf mapping above already turns
        // "Distortion Effect" into Distort. Tabs are removed so that each kind is one chip.
        shelf.erase(0, shelf.find_first_not_of(" \t")), shelf.erase(shelf.find_last_not_of(" \t") + 1);
        for (const std::string tail : {" Effect", " Adjustment"})
            if (shelf.size() > tail.size() && shelf.compare(shelf.size() - tail.size(), tail.size(), tail) == 0) shelf.resize(shelf.size() - tail.size());
        // A transition (ISF_Spec: it has startImage, endImage and progress) goes on one shelf
        // whatever its wipe or dissolve style, as After Effects keeps its transitions under
        // Transition. Once applied, it runs from the playhead (doc_fx_file).
        if (std::find(imageNames.begin(), imageNames.end(), "startImage") != imageNames.end() && std::find(imageNames.begin(), imageNames.end(), "endImage") != imageNames.end() &&
            std::any_of(inputs.GetArray().begin(), inputs.GetArray().end(), [&](const rapidjson::Value& i) { return str(i, "NAME") == "progress"; }))
            shelf = "Transition";
        top += "// --label:" + shelf + "\n";
    }
    // The description is kept so that the shelf can find the effect by it.
    if (std::string about = str(head, "DESCRIPTION"); !about.empty()) {
        std::replace(about.begin(), about.end(), '\n', ' ');
        top += "// --about:" + about + "\n";
    }
    for (const std::string& p : passLines) lines += p + "\n";
    return top + lines + "\n" + wgsl->wgsl;
}

// Returns the tags of an ISF file, read from its header and body. See isf.h.
std::string isf_tags(const std::string& file) {
    std::ifstream in(file);
    const std::string text = adapter_isf(std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>()));
    const size_t open = text.find("/*"), close = text.find("*/");
    rapidjson::Document head;
    if (open == std::string::npos || close == std::string::npos || head.Parse(text.c_str() + open + 2, close - open - 2).HasParseError() || !head.IsObject()) return "";
    const auto str = [](const rapidjson::Value& o, const char* k) { return o.IsObject() && o.HasMember(k) && o[k].IsString() ? std::string(o[k].GetString()) : std::string(); };
    const rapidjson::Value none(rapidjson::kArrayType);
    const rapidjson::Value& inputs = head.HasMember("INPUTS") && head["INPUTS"].IsArray() ? head["INPUTS"] : none;
    const rapidjson::Value& passes = head.HasMember("PASSES") && head["PASSES"].IsArray() ? head["PASSES"] : none;
    std::vector<std::string> imageNames;
    bool sound = false, progress = false;
    for (const auto& i : inputs.GetArray()) {
        if (str(i, "TYPE") == "image") imageNames.push_back(str(i, "NAME"));
        // Shadertoy's Sound Input.
        sound = sound || str(i, "TYPE") == "audio" || str(i, "TYPE") == "audioFFT";
        progress = progress || str(i, "NAME") == "progress";
    }
    const auto has = [&](const char* n) { return std::find(imageNames.begin(), imageNames.end(), n) != imageNames.end(); };
    // ISF_Spec's transitions, as the label in isf_wgsl reads them.
    const bool transition = has("startImage") && has("endImage") && progress;
    // A pass kept from frame to frame: PERSISTENT in ISF_Spec, called Feedback by Vidvox.
    bool feedback = false;
    for (const auto& p : passes.GetArray()) feedback = feedback || (p.IsObject() && p.HasMember("PERSISTENT") && (p["PERSISTENT"].IsBool() ? p["PERSISTENT"].GetBool() : p["PERSISTENT"].IsNumber() && p["PERSISTENT"].GetDouble() != 0));
    const std::string body = text.substr(close + 2);
    // The uniforms of ISF_Spec's clock: a shader that reads them moves by itself.
    static const std::regex clock(R"(\b(TIME|TIMEDELTA|FRAMEINDEX|DATE)\b)");
    std::string tags;
    const auto tag = [&](bool on, const char* word) { if (on) tags += (tags.empty() ? "" : " ") + std::string(word); };
    tag(transition, "transition");
    // No image input: ISF_Spec's sources.
    tag(imageNames.empty(), "generator");
    tag(sound, "sound");
    // Shadertoy's Multipass.
    tag(passes.Size() > 1, "multipass");
    tag(feedback, "feedback");
    // The regex runs only where one of its words is present. See doc_wgsl_tags.
    tag((body.find("TIME") != std::string::npos || body.find("FRAMEINDEX") != std::string::npos || body.find("DATE") != std::string::npos) && std::regex_search(body, clock), "time");
    // Another layer's image as input besides its own, like Shadertoy's Webcam, an image from
    // outside.
    tag(!transition && imageNames.size() > 1, "image");
    return tags;
}

// The last WGSL made for each file, and why the file as it is now was not converted. A half-typed
// effect keeps drawing as it did before, as a half-typed script keeps what last ran in
// doc_script_of, and the effect card shows the reason through isf_trouble.
static std::mutex isf_lock;
static std::map<std::string, std::string> isf_good, isf_why;
// Records why the conversion failed and returns the last good output for the file, or "" if there
// is none.
static std::string isf_fallback(const std::string& file, const std::string& why) {
    isf_why[file] = why.empty() ? std::string("it could not be turned into WGSL") : why;
    const auto good = isf_good.find(file);
    return good == isf_good.end() ? "" : good->second;
}
// Records a successful conversion, forgets any earlier failure, and returns `out`.
static std::string isf_built(const std::string& file, const std::string& out) {
    isf_good[file] = out, isf_why.erase(file);
    return out;
}
// See isf.h.
std::string isf_trouble(const std::string& asked) {
    std::lock_guard<std::mutex> hold(isf_lock);
    const auto why = isf_why.find(fx_source(asked));
    return why == isf_why.end() ? "" : why->second;
}
// See isf.h. Conversions are cached by the file's path, modification time and size.
std::string isf_file(const std::string& asked) {
    // A duplicated effect such as Glow~2.fs reads the content of Glow.fs (engine/community/quickjs/
    // script.h).
    const std::string file = fx_source(asked);
    // A three.js effect is converted to ISF first (three_isf.cpp).
    if (std::filesystem::path(file).extension() != ".fs" && !three_is(file)) return file;
    struct stat st {};
    if (stat(file.c_str(), &st) != 0) return "";
    const std::string key = "isf 15|" + file + "|" + std::to_string(st.st_mtimespec.tv_sec) + "." + std::to_string(st.st_mtimespec.tv_nsec) + "|" + std::to_string(st.st_size);
    // What each file, as it is now, became: its last good output, or "" if it could not be made.
    static std::map<std::string, std::string> built;
    std::lock_guard<std::mutex> hold(isf_lock);
    if (auto m = built.find(key); m != built.end()) return m->second;
    uint64_t hash = 1469598103934665603ull;
    for (unsigned char c : key) hash = (hash ^ c) * 1099511628211ull;
    const char* home = std::getenv("HOME");
    const std::filesystem::path dir = std::filesystem::path(home ? home : "/tmp") / "Library/Caches/Motolii/isf";
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
            std::fprintf(stderr, "the three.js effect %s is not taken: %s\n", file.c_str(), why.substr(0, 600).c_str());
            return built[key] = isf_fallback(file, why);
        }
        text.str(isf);
    }
    const std::string stem = std::filesystem::path(file).stem().string();
    // The file's own vertex shader, if there is one beside it.
    std::stringstream vertex;
    if (std::ifstream vs(std::filesystem::path(file).replace_extension(".vs")); vs) vertex << vs.rdbuf();
    // Shadertoy and GLSL Sandbox shaders are accepted as they come (adapter.h).
    const std::string wgsl = isf_wgsl(adapter_isf(text.str()), stem, why, vertex.str());
    if (wgsl.empty()) {
        std::fprintf(stderr, "the ISF effect %s is not taken: %s\n", file.c_str(), why.substr(0, 600).c_str());
        return built[key] = isf_fallback(file, why);
    }
    std::filesystem::create_directories(dir, e);
    std::ofstream(out + ".part") << wgsl;
    std::filesystem::rename(out + ".part", out, e);
    return built[key] = isf_built(file, out);
}
