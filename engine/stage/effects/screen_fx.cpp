#include "stage/effects/screen_fx.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <functional>
#include <map>
#include <regex>
#include <sstream>
#include <string>
#include <system_error>
#include <vector>

#include <backend/DriverEnums.h>
#include <backend/PixelBufferDescriptor.h>
#include <filament/Engine.h>
#include <filament/RenderTarget.h>
#include <filament/Texture.h>
#include <filament/View.h>
#include <math/half.h>
#include <thorvg.h>

#include "community/isf/isf.h"
#include "community/quickjs/script.h"
#include "gpu/screen_interop.h"
#include "shelf/shelf_folders.h"
#include "stage/render/render_stage.h"

using namespace filament;
using namespace filament::math;

std::filesystem::file_time_type screen_stamp(const std::string& file) {
    std::error_code wrong;
    return std::filesystem::last_write_time(fx_source(file), wrong);
}

namespace {
// Rewrites the WGSL in `code` in place for a shader that does not know layerRect, so that it is
// told the layer's frame as an ISF effect is (see community/isf/isf.cpp): its uv and pixel
// coordinates are relative to the frame, and what it reads is read through the frame. The
// shader's own lines are kept and only names are changed, so a file written for a whole image
// works on a layer. Does nothing for a shader that reads a texture array or has no uniform
// struct or fragment entry point.
void screen_framed(std::string& code) {
    std::smatch parameters, way;
    if (code.find("texture_2d_array") != std::string::npos || !std::regex_search(code, parameters, std::regex(R"(var<uniform>\s+(\w+)\s*:\s*(\w+)\s*;)"))) return;
    if (!std::regex_search(code, way, std::regex(R"(@fragment\s+fn\s+\w+\s*\([^)]*@location\(0\)\s+(\w+)\s*:\s*vec2(?:f|<f32>)[^)]*\)[^{]*\{)"))) return;
    const std::string k = parameters[1], built = parameters[2], uv = way[1];
    std::string head = way.str();
    const bool pixel = std::regex_search(head, std::regex(R"(@builtin\(position\)\s+frag\s*:)"));
    head = std::regex_replace(std::regex_replace(head, std::regex("\\b" + uv + "(\\s*:)"), uv + "_on$1"), std::regex(R"(\bfrag(\s*:))"), "frag_on$1");
    head += "\n    let " + uv + " = (" + uv + "_on - " + k + ".frameRect.xy) / " + k + ".frameRect.zw;\n";
    if (pixel) head += "    let frag = vec4f(" + uv + " * " + k + ".resolution, frag_on.zw);\n";
    const size_t at = (size_t)way.position(), end = at + (size_t)way.length();
    std::string out = code.substr(0, at) + head + code.substr(end);
    out = std::regex_replace(std::regex_replace(out, std::regex(R"(\btextureSampleLevel\s*\()"), "frame_level("), std::regex(R"(\btextureSample\s*\()"), "frame_sample(");
    out = std::regex_replace(out, std::regex("struct\\s+" + built + "\\s*\\{"), "struct " + built + " {\n    frameRect: vec4f,");
    std::smatch line;
    std::regex_search(out, line, std::regex(R"(var<uniform>[^;]*;)"));
    const std::string reads = "\nfn frame_level(t: texture_2d<f32>, s: sampler, c: vec2f, l: f32) -> vec4f { return textureSampleLevel(t, s, c * " + k + ".frameRect.zw + " + k + ".frameRect.xy, l); }\nfn frame_sample(t: texture_2d<f32>, s: sampler, c: vec2f) -> vec4f { return textureSample(t, s, c * " + k + ".frameRect.zw + " + k + ".frameRect.xy); }\n";
    code = out.substr(0, (size_t)line.position() + (size_t)line.length()) + reads + out.substr((size_t)line.position() + (size_t)line.length());
}
}  // namespace

bool screen_read(ScreenFx& fx, std::string& code) {
    // An ISF effect is converted to WGSL first.
    const std::string file = isf_file(fx.file);
    fx.source = isf_tags(fx_source(fx.file)).find("generator") != std::string::npos;
    if (file.empty()) return fx.trouble = "the ISF effect could not be turned into WGSL: " + fx.file, false;
    std::ifstream in(file);
    if (!in) return fx.trouble = "there is no such file: " + fx.file, false;
    std::stringstream all;
    all << in.rdbuf();
    code = all.str();
    if (code.find("layerRect") == std::string::npos && code.find("frameRect") == std::string::npos) screen_framed(code);
    const std::regex bound(R"(@group\(\s*\d+u?\s*\)\s*@binding\(\s*\d+u?\s*\)\s*var(<\s*uniform\s*>)?\s+(\w+)\s*:\s*([A-Za-z_][\w<>]*))");
    // Number of images read. Image k is bound at 2k, sampler k at 2k+1, and the parameters
    // after them all.
    int reads = 0;
    // The declarations sorted below by the binding number written in the source, since Tint
    // may emit them in any order.
    std::vector<std::smatch> said;
    // Counts texture_2d and texture_2d_array alike.
    for (std::sregex_iterator m(code.begin(), code.end(), bound), end; m != end; ++m) said.push_back(*m), reads += (*m)[3].str().rfind("texture_2d", 0) == 0;
    const auto number = [](const std::smatch& m) { const std::string all = m[0]; return std::atoi(all.c_str() + all.find("@binding(") + 9); };
    std::vector<size_t> order(said.size());
    for (size_t i = 0; i < order.size(); ++i) order[i] = i;
    std::stable_sort(order.begin(), order.end(), [&](size_t a, size_t b) { return number(said[a]) < number(said[b]); });
    std::vector<int> given(said.size(), -1);
    std::string out, parametersType;
    int textureCount = 0, samplers = 0, uniforms = 0;
    for (size_t i : order) {
        const std::string type = said[i][3];
        int& binding = given[i];
        if (type.rfind("texture_2d_array", 0) == 0) fx.layered |= 1u << textureCount, binding = 2 * textureCount++;
        else if (type.rfind("texture_2d", 0) == 0) binding = 2 * textureCount++;
        else if (type == "sampler") binding = 2 * samplers++ + 1;
        else if (said[i][1].matched) binding = 2 * reads, ++uniforms, parametersType = type;
        if (binding < 0) return fx.trouble = "the effect has a binding of a kind it cannot be given: " + type, false;
    }
    auto at = code.cbegin();
    for (size_t i = 0; i < said.size(); ++i) {
        const std::smatch& m = said[i];
        const int binding = given[i];
        out.append(at, code.cbegin() + m.position());
        out += "@group(0) @binding(" + std::to_string(binding) + ") var" + (m[1].matched ? "<uniform>" : "") + " " + m[2].str() + ": " + m[3].str();
        at = code.cbegin() + m.position() + m.length();
    }
    out.append(at, code.cend());
    if (textureCount < 1 || samplers > textureCount || uniforms > 1) return fx.trouble = "an effect reads a texture or more, a sampler for each at most, and one struct of parameters at most", false;
    fx.textureCount = textureCount;
    // The passes, as declared in the leading comments: `//
    // --pass@target:persistent,fine,width,height`.
    std::istringstream lines(code);
    for (std::string line; std::getline(lines, line) && line.rfind("//", 0) == 0;) {
        // `// --history@frames:share`
        if (const size_t h = line.find("--history@"); h != std::string::npos) {
            fx.historyFrames = std::clamp(std::atoi(line.c_str() + h + 10), 2, 240);
            if (const size_t c = line.find(':', h); c != std::string::npos) fx.historyShare = std::clamp(std::atof(line.c_str() + c + 1), 0.05, 1.0);
            continue;
        }
        if (line.find("--spill") != std::string::npos) { fx.spill = true; continue; }
        if (line.find("--alpha") != std::string::npos) { fx.alpha = true; continue; }
        const size_t p = line.find("--pass@"), colon = line.find(':', p);
        if (p == std::string::npos || colon == std::string::npos) continue;
        const std::string name = line.substr(p + 7, colon - p - 7);
        std::vector<std::string> said;
        std::stringstream rest(line.substr(colon + 1));
        for (std::string one; std::getline(rest, one, ',');) said.push_back(one);
        if (said.size() < 4) return fx.trouble = "a pass said wrong: " + line, false;
        int target = -1;
        if (!name.empty()) {
            for (size_t k = 0; k < fx.targets.size(); ++k) if (fx.targets[k].name == name) target = (int)k;
            if (target < 0) {
                ScreenFx::Target t;
                t.name = name, t.persistent = said[0] == "1", t.fine = said[1] == "1";
                for (int side = 0; side < 2; ++side) {
                    const std::string& w = said[(size_t)side + 2];
                    if (!w.empty() && w[0] == 'a') t.points[side] = std::max(1, std::atoi(w.c_str() + 1)), t.share[side] = 0;
                    else t.share[side] = w.size() > 1 ? std::atof(w.c_str() + 1) : 1.0;
                }
                fx.targets.push_back(t);
                target = (int)fx.targets.size() - 1;
            }
        }
        fx.passes.push_back(target);
    }
    fx.others.clear();
    fx.sounds.clear();
    for (const ScriptParameter& k : script_parameters(file))
        if (k.kind == "picture" || k.kind == "sound") {
            fx.others.push_back(k.name), fx.sounds.push_back({});
            if (k.kind == "sound") fx.sounds.back() = {true, k.words.rfind("fft", 0) == 0, std::atoi(k.words.c_str() + k.words.find(' ') + 1)};
        }
    fx.images.assign(fx.others.size(), "");
    std::istringstream head(code);
    for (std::string line; std::getline(head, line) && line.rfind("//", 0) == 0;) {
        const size_t h = line.find("--image@"), colon = line.find(':', h);
        if (h == std::string::npos || colon == std::string::npos) continue;
        fx.others.push_back(line.substr(h + 8, colon - h - 8)), fx.sounds.push_back({});
        fx.images.push_back((std::filesystem::path(file).parent_path() / line.substr(colon + 1)).string());
    }
    if ((!fx.targets.empty() || !fx.others.empty()) && (int)fx.targets.size() + 1 + (int)__builtin_popcount(fx.layered) + (int)fx.others.size() != textureCount) return fx.trouble = "its passes' textures, its other images and the textures it reads do not agree", false;
    if (fx.layered && !fx.historyFrames) return fx.trouble = "it reads an array of past frames and its head does not ask for them (--history@frames:share)", false;
    code = std::regex_replace(out, std::regex(R"(\bfn\s+fs_main\s*\()"), "fn main(");
    // Computes each member's offset by WGSL's rule for a uniform: aligned to its size, with
    // a vec3 aligned as a vec4.
    if (!parametersType.empty()) {
        std::smatch body;
        if (!std::regex_search(code, body, std::regex("struct\\s+" + parametersType + "\\s*\\{([^}]*)\\}"))) return fx.trouble = "no struct " + parametersType, false;
        const std::regex field(R"((\w+)\s*:\s*([\w<>]+))");
        const std::string inside = body[1];
        uint32_t end = 0, most = 4;
        for (std::sregex_iterator f(inside.begin(), inside.end(), field), stop; f != stop; ++f) {
            const std::string t = (*f)[2];
            const uint32_t n = t == "f32" || t == "i32" || t == "u32" ? 1 : t.find("vec2") == 0 ? 2 : t.find("vec3") == 0 ? 3 : t.find("vec4") == 0 ? 4 : 0;
            if (!n) return fx.trouble = "a parameter of a kind an effect cannot be given: " + t, false;
            const uint32_t align = n == 1 ? 4 : n == 2 ? 8 : 16;
            end = (end + align - 1) / align * align;
            fx.fields.push_back({(*f)[1], end, n, t == "i32" || t == "u32"});
            end += 4 * n, most = std::max(most, align);
        }
        fx.bytes = (end + most - 1) / most * most;
    }
    fx.parameters = script_parameters(file);
    // Fill in the default values where the file's own declarations give none; see
    // shelves/effects/sources/fx_first.sh.
    script_first(fx.file, fx.parameters);
    return true;
}

namespace {
// Loads a picture file with ThorVG, draws it once at its own size, and returns it as a Filament
// texture. Returns nullptr when the file cannot be read or is larger than 4096 in either
// direction.
Texture* screen_image(Stage& s, const std::string& file) {
    float w = 0, h = 0;
    // Start ThorVG before loading: it skips reading a file when it is not started (see
    // TaskScheduler::request in tvgTaskScheduler.cpp).
    tvg::Initializer::init(0);
    tvg::Picture* p = tvg::Picture::gen();
    if (p->load(file.c_str()) != tvg::Result::Success || p->size(&w, &h) != tvg::Result::Success || w < 1 || h < 1 || w > 4096 || h > 4096) return delete p, nullptr;
    auto* pixels = new std::vector<uint32_t>((size_t)w * (size_t)h, 0);
    tvg::SwCanvas* canvas = tvg::SwCanvas::gen();
    const bool drew = canvas->target(pixels->data(), (uint32_t)w, (uint32_t)w, (uint32_t)h, tvg::ColorSpace::ABGR8888) == tvg::Result::Success && canvas->add(p) == tvg::Result::Success && canvas->draw(true) == tvg::Result::Success && canvas->sync() == tvg::Result::Success;
    delete canvas;
    if (!drew) return delete pixels, nullptr;
    Texture* t = Texture::Builder().width((uint32_t)w).height((uint32_t)h).levels(1).format(Texture::InternalFormat::RGBA8).build(*s.engine);
    t->setImage(*s.engine, 0, backend::PixelBufferDescriptor(pixels->data(), pixels->size() * 4, backend::PixelDataFormat::RGBA, backend::PixelDataType::UBYTE,
        [](void*, size_t, void* u) { delete (std::vector<uint32_t>*)u; }, pixels));
    return t;
}

// Builds the input textures of an effect for the current frame. Image files are loaded once.
// Audio inputs are rebuilt each frame from their current values and uploaded with Filament's
// setImage; the value buffer is freed by the PixelBufferDescriptor callback once it is sent.
void screen_sounds(Stage& s, ScreenStack& st, ScreenFx& fx) {
    fx.othersNow.resize(fx.others.size(), nullptr);
    fx.imagesBuilt.resize(fx.others.size(), nullptr);
    for (size_t k = 0; k < fx.images.size(); ++k) {
        if (fx.images[k].empty()) continue;
        if (!fx.imagesBuilt[k] && !(fx.imagesBuilt[k] = screen_image(s, fx.images[k]))) { fx.trouble = "its image " + fx.images[k] + " is not read", fx.images[k].clear(); continue; }
        fx.othersNow[k] = fx.imagesBuilt[k];
    }
    for (size_t k = 0; k < fx.sounds.size(); ++k) {
        ScreenFx::Sound& one = fx.sounds[k];
        if (!one.is) continue;
        std::vector<float> v = st.sounds ? st.sounds(fx.file, fx.others[k], one.fft, one.wide) : std::vector<float>();
        if (v.empty()) v.assign((size_t)std::max(one.wide, 1), one.fft ? 0.f : 0.5f);
        if (one.texture && one.texture->getWidth() != v.size()) s.engine->destroy(one.texture), one.texture = nullptr;
        if (!one.texture) one.texture = Texture::Builder().width((uint32_t)v.size()).height(1).levels(1).format(Texture::InternalFormat::R16F).build(*s.engine);
        auto* halves = new std::vector<math::half>(v.begin(), v.end());
        one.texture->setImage(*s.engine, 0, backend::PixelBufferDescriptor(halves->data(), halves->size() * sizeof(math::half), backend::PixelDataFormat::R, backend::PixelDataType::HALF,
            [](void*, size_t, void* user) { delete (std::vector<math::half>*)user; }, halves));
        fx.othersNow[k] = one.texture;
    }
}
}  // namespace

Texture* screen_texture(Stage& s) {
    return Texture::Builder().width((uint32_t)s.w).height((uint32_t)s.h).levels(1).format(Texture::InternalFormat::RGBA8)
        .usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE).build(*s.engine);
}

namespace {
// Fills the parameter uniform struct of `fx` for one pass and uploads it. Members with special
// names (time, frameRect, passRect, aspect, resolution and so on) are computed by the stage; every
// other member is read through `numbers`, a vector one component at a time as name_x, name_y and
// so on. `pass` is the pass index. pw and ph give the size of the image drawn into in pixels, or
// 0 for the stage size.
void screen_parameters(Stage& s, ScreenFx& fx, const ScreenNumbers& numbers, int pass = 0, double pw = 0, double ph = 0) {
    std::vector<float> at(fx.bytes / 4, 0.f);
    // An ISF effect declares frameRect and is told its frame's size. A WGSL effect reads its
    // layerRect, or the whole image.
    const bool framed = std::any_of(fx.fields.begin(), fx.fields.end(), [](const ScreenFx::Field& f) { return f.name == "frameRect"; });
    // The size in pixels of the image drawn into: ISF's RENDERSIZE, which each pass has of its own
    // (ISF spec, VVISF). The same rule as vgpu: a shader is told the size of its own target, as
    // gl_FragCoord and @builtin(position) count it.
    const double w = (pw > 0 ? pw : s.w) * (framed ? fx.pass[2] : 1.0), h = (ph > 0 ? ph : s.h) * (framed ? fx.pass[3] : 1.0);
    for (const ScreenFx::Field& f : fx.fields) {
        float v[4] = {0, 0, 0, 0};
        if (f.name == "time") v[0] = (float)s.now;
        else if (f.name == "frameRect" || f.name == "passRect") for (int i = 0; i < 4; ++i) v[i] = (float)(f.name == "passRect" ? fx.pass : fx.frame)[i];
        // Where one of the other inputs is read: the effect's own image by the frame,
        // another layer's image whole.
        else if (f.name.rfind("isf_other_", 0) == 0) {
            const size_t k = (size_t)(std::find(fx.others.begin(), fx.others.end(), f.name.substr(10)) - fx.others.begin());
            const bool own = k < fx.othersOwn.size() && fx.othersOwn[k];
            for (int i = 0; i < 4; ++i) v[i] = own ? (float)fx.frame[i] : i < 2 ? 0.f : 1.f;
        }
        else if (f.name == "aspect") v[0] = (float)(w / h);
        else if (f.name == "resolution") v[0] = (float)w, v[1] = (float)h;
        // AbsentMotion's effects.cpp defines screen as -area.left, -area.top, the
        // scene's width and height. This image is that scene, so a wave's reach is
        // magnitude * min(screen.z, screen.w) * 0.01.
        else if (f.name == "screen" && f.floats >= 4) v[2] = (float)w, v[3] = (float)h;
        else if ((f.name == "layer" && f.floats == 2) || (f.name == "duration" && f.floats == 1) ? std::none_of(fx.parameters.begin(), fx.parameters.end(), [&](const ScriptParameter& one) { return one.name.rfind(f.name, 0) == 0; }) : false) {
            // These come from AbsentMotion's effects.cpp, each only where the file has no parameter
            // of that name. `layer` is the layer's own width and height, at least 1: on a layer its
            // rectangle on its image (layerRect), on the whole image the image's. `duration` is the
            // layer's length in seconds (clip_length: the layer's, or the document's). Block
            // Noise's blocks are a share of `layer`.
            if (f.name == "duration") v[0] = (float)numbers(fx.file, "clip_length", 0);
            else v[0] = (float)std::max(1.0, numbers(fx.file, "layerRect_z", w)), v[1] = (float)std::max(1.0, numbers(fx.file, "layerRect_w", h));
        }
        else if ((f.name == "width" || f.name == "height") && std::none_of(fx.fields.begin(), fx.fields.end(), [](const ScreenFx::Field& g) { return g.name == "resolution"; }) && !(fx.file.ends_with(".fs") && std::any_of(fx.parameters.begin(), fx.parameters.end(), [&](const ScriptParameter& one) { return one.name == f.name; })))
            // The image size for three.js shaders: halftone.wgsl divides by width
            // and height. A shader that already has resolution, or an ISF parameter
            // of the same name, keeps the parameter the file declares.
            v[0] = (float)(f.name == "width" ? w : h);
        // ISF's FRAMEINDEX: the frame number (ISF spec).
        else if (f.name == "frame") v[0] = (float)std::lround(s.now * screen_rate(s));
        // The frame rate; ISF's TIMEDELTA is its reciprocal, the time since the last
        // frame (ISF spec).
        else if (f.name == "isf_rate") v[0] = (float)screen_rate(s);
        // ISF's PASSINDEX. The member is not called `pass` because that is a reserved word in WGSL.
        else if (f.name == "passindex") v[0] = (float)pass;
        else if (f.name == "history_head") v[0] = (float)std::max(0, fx.head);
        else if (f.name == "history_count") v[0] = (float)fx.historyFrames;
        else
            // Each component of a vector is a parameter of its own: name_x, name_y and so on.
            for (uint32_t i = 0; i < f.floats; ++i) {
                const std::string k = f.floats == 1 ? f.name : f.name + "_" + "xyzw"[i];
                double usual = 0;
                for (const ScriptParameter& one : fx.parameters) if (one.name == k) usual = one.usual;
                v[i] = (float)numbers(fx.file, k, usual);
            }
        for (uint32_t i = 0; i < f.floats; ++i) {
            if (f.whole) { const int32_t w = (int32_t)std::lround(v[i]); std::memcpy(&at[f.at / 4 + i], &w, 4); }
            else at[f.at / 4 + i] = v[i];
        }
    }
    if (!at.empty()) interop::parameters(s.engine, fx.interop, at.data(), (uint32_t)(at.size() * 4), pass);
}

// Creates the images an effect's passes draw into, when first drawn, at the size the stage
// gives. Each target has two textures: one is read while the other is drawn into, then they
// swap. A persistent target's read texture is the last frame's when read before it is drawn. If
// `drop` is true the textures are destroyed and not recreated. pw and ph give the size of the
// image drawn into, or 0 for the stage size.
void screen_targets(Stage& s, ScreenFx& fx, bool drop = false, uint32_t pw = 0, uint32_t ph = 0) {
    // Sizes are a share of the image drawn into, as the ISF PASSES say: a layer's box, or
    // the stage.
    const double W = pw ? pw : s.w, H = ph ? ph : s.h;
    for (ScreenFx::Target& t : fx.targets)
        for (int k = 0; k < 2; ++k) {
            const uint32_t w = t.points[0] ? (uint32_t)t.points[0] : (uint32_t)std::max(1L, std::lround(W * t.share[0]));
            const uint32_t h = t.points[1] ? (uint32_t)t.points[1] : (uint32_t)std::max(1L, std::lround(H * t.share[1]));
            // Destroyed when dropped, or when the image it serves has changed size;
            // it is then made again.
            if (drop || (t.textures[k] && (t.w != w || t.h != h))) {
                if (t.into[k]) s.engine->destroy(t.into[k]), t.into[k] = nullptr;
                if (t.textures[k]) s.engine->destroy(t.textures[k]), t.textures[k] = nullptr;
                if (drop) continue;
            }
            if (t.textures[k]) continue;
            t.w = w, t.h = h;
            t.textures[k] = Texture::Builder().width(t.w).height(t.h).levels(1).format(t.fine ? Texture::InternalFormat::RGBA16F : Texture::InternalFormat::RGBA8)
                               .usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE).build(*s.engine);
            t.into[k] = RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, t.textures[k]).build(*s.engine);
        }
}

// Returns the effect that copies an image unchanged, creating it on first use.
interop::Screen* screen_copy(Stage& s, ScreenStack& st) {
    if (!st.copy) {
        static const char* const same = "@group(0) @binding(0) var source: texture_2d<f32>;\n@group(0) @binding(1) var near: sampler;\n"
                                        "@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f { return textureSampleLevel(source, near, uv, 0.0); }\n";
        st.copy = interop::screen(s.engine, "copy", same, 0);
    }
    return st.copy;
}
}  // namespace

void screen_place(Stage& s, Texture* from, RenderTarget* to, uint32_t w, uint32_t h, const int* at) {
    static std::map<Engine*, interop::Screen*> copies;
    interop::Screen*& copy = copies[s.engine];
    if (!copy) {
        static const char* const same = "@group(0) @binding(0) var source: texture_2d<f32>;\n@group(0) @binding(1) var near: sampler;\n"
                                        "@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f { return textureSampleLevel(source, near, uv, 0.0); }\n";
        copy = interop::screen(s.engine, "place", same, 0);
    }
    if (copy) interop::draw(s.engine, copy, from, to, w, h, at);
}

void screen_tone(Stage& s, Texture* from, RenderTarget* to, uint32_t w, uint32_t h, bool toSrgb) {
    static std::map<Engine*, interop::Screen*> interops[2];
    interop::Screen*& one = interops[toSrgb ? 1 : 0][s.engine];
    if (!one) {
        const std::string code = std::string("@group(0) @binding(0) var source: texture_2d<f32>;\n@group(0) @binding(1) var near: sampler;\n") +
            (toSrgb ? "fn tone(c: vec3f) -> vec3f { return select(1.055 * pow(c, vec3f(1.0 / 2.4)) - 0.055, c * 12.92, c <= vec3f(0.0031308)); }\n"
                    : "fn tone(c: vec3f) -> vec3f { return select(pow((c + 0.055) / 1.055, vec3f(2.4)), c / 12.92, c <= vec3f(0.04045)); }\n") +
            "@fragment fn main(@builtin(position) frag: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {\n"
            "  let p = textureSampleLevel(source, near, uv, 0.0);\n  if (p.a <= 0.0) { return vec4f(0.0); }\n"
            "  return vec4f(tone(clamp(p.rgb / p.a, vec3f(0.0), vec3f(1.0))) * p.a, p.a);\n}\n";
        one = interop::screen(s.engine, toSrgb ? "to sRGB" : "to linear", code.c_str(), 0);
    }
    if (one) interop::draw(s.engine, one, from, to, w, h, nullptr);
}

void screen_draw(Stage& s, ScreenStack& st, ScreenFx& fx, Texture* from, RenderTarget* to, const ScreenNumbers& numbers, uint32_t w, uint32_t h, bool over) {
    if (!w) w = (uint32_t)s.w, h = (uint32_t)s.h;
    std::copy(fx.source ? st.own : st.frame, (fx.source ? st.own : st.frame) + 4, fx.frame);
    const auto passing = [&](int t) {
        for (int i = 0; i < 2; ++i) {
            const bool set = t >= 0 && fx.targets[(size_t)t].points[i];
            fx.pass[i] = set ? 0.0 : fx.frame[i], fx.pass[2 + i] = set ? 1.0 : fx.frame[2 + i];
        }
    };
    screen_targets(s, fx, false, w, h);
    // Write this frame into the next layer of the history before it is read.
    if (fx.historyFrames) {
        // The size of the image it keeps.
        const uint32_t hw = (uint32_t)std::max(2L, std::lround(w * fx.historyShare)), hh = (uint32_t)std::max(2L, std::lround(h * fx.historyShare));
        // The image has a new size: the history starts again.
        if (fx.history && (fx.hw != hw || fx.hh != hh)) {
            for (RenderTarget* r : fx.historyInto) s.engine->destroy(r);
            fx.historyInto.clear();
            s.engine->destroy(fx.history), fx.history = nullptr;
        }
        if (!fx.history) {
            fx.hw = hw, fx.hh = hh;
            fx.history = Texture::Builder().width(fx.hw).height(fx.hh).depth((uint32_t)fx.historyFrames).levels(1).sampler(Texture::Sampler::SAMPLER_2D_ARRAY)
                             .format(Texture::InternalFormat::RGBA8).usage(Texture::Usage::COLOR_ATTACHMENT | Texture::Usage::SAMPLEABLE).build(*s.engine);
            for (int k = 0; k < fx.historyFrames; ++k)
                fx.historyInto.push_back(RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, fx.history).layer(RenderTarget::AttachmentPoint::COLOR, (uint32_t)k).build(*s.engine));
        }
        fx.head = (fx.head + 1) % fx.historyFrames;
        interop::draw(s.engine, screen_copy(s, st), from, fx.historyInto[(size_t)fx.head], fx.hw, fx.hh);
    }
    screen_sounds(s, st, fx);
    std::vector<Texture*> read((size_t)fx.textureCount, from);
    const auto gather = [&] {
        size_t target = 0;
        const size_t own = read.size() - fx.others.size();
        for (size_t k = 1; k < own; ++k)
            read[k] = (fx.layered >> k) & 1u ? fx.history : target < fx.targets.size() ? fx.targets[target].textures[fx.targets[target].front] : from, target += !((fx.layered >> k) & 1u);
        // Another layer's image. When none is chosen yet, use the effect's own, except
        // for a transition's end image, which is empty (ISF spec, endImage).
        for (size_t k = own; k < read.size(); ++k) {
            // What is behind the layer: the stage's image without it
            // (render_layers.h); AbsentMotion's backdrop.
            if (fx.others[k - own] == "backdrop" && s.behind) { read[k] = s.behind; continue; }
            const bool end = fx.others[k - own] == "endImage";
            if (end && !st.clear) {
                st.clear = Texture::Builder().width(1).height(1).levels(1).format(Texture::InternalFormat::RGBA8).build(*s.engine);
                st.clear->setImage(*s.engine, 0, backend::PixelBufferDescriptor(new uint32_t(0), 4, backend::PixelDataFormat::RGBA, backend::PixelDataType::UBYTE, [](void* p, size_t, void*) { delete (uint32_t*)p; }));
            }
            read[k] = k - own < fx.othersNow.size() && fx.othersNow[k - own] ? fx.othersNow[k - own] : end ? st.clear : from;
            fx.othersOwn.resize(fx.others.size()), fx.othersOwn[k - own] = read[k] == from;
        }
    };
    if (fx.passes.empty()) {
        gather();
        passing(-1);
        screen_parameters(s, fx, numbers, 0, w, h);
        interop::draw(s.engine, fx.interop, read.data(), to, w, h, 0, nullptr, over);
        return;
    }
    for (size_t p = 0; p < fx.passes.size(); ++p) {
        gather();
        const int t = fx.passes[p];
        passing(t);
        screen_parameters(s, fx, numbers, (int)p, t < 0 ? w : fx.targets[(size_t)t].w, t < 0 ? h : fx.targets[(size_t)t].h);
        if (t < 0) { interop::draw(s.engine, fx.interop, read.data(), to, w, h, (int)p, nullptr, over); continue; }
        ScreenFx::Target& into = fx.targets[(size_t)t];
        const int back = 1 - into.front;
        interop::draw(s.engine, fx.interop, read.data(), into.into[back], into.w, into.h, (int)p);
        into.front = back;
    }
    // The last pass drew into its own target, so that is what the effect shows.
    if (fx.passes.back() >= 0) {
        const ScreenFx::Target& last = fx.targets[(size_t)fx.passes.back()];
        interop::draw(s.engine, screen_copy(s, st), &last.textures[last.front], to, w, h, 0, nullptr, over);
    }
}

void screen_fresh(Stage& s, ScreenFx& fx) {
    if (fx.seen == files_changed()) return;
    fx.seen = files_changed();
    const auto stamp = screen_stamp(fx.file);
    if (stamp == fx.stamp) return;
    fx.stamp = stamp;
    ScreenFx again;
    again.file = fx.file;
    std::string code;
    if (!screen_read(again, code)) { std::fprintf(stderr, "%s\n", again.trouble.c_str()); return; }
    interop::Screen* built = interop::screen(s.engine, fx.file.c_str(), code.c_str(), again.bytes, &again.trouble, again.textureCount, again.layered);
    if (!built) { std::fprintf(stderr, "the effect %s as written now is not taken (the one before stays): %s\n", fx.file.c_str(), again.trouble.c_str()); return; }
    interop::drop(s.engine, fx.interop);
    screen_targets(s, fx, true);
    fx.parameters = again.parameters, fx.fields = again.fields, fx.bytes = again.bytes, fx.interop = built;
    // The history frames are kept as they are while their count stays the same.
    fx.textureCount = again.textureCount, fx.targets = again.targets, fx.passes = again.passes, fx.layered = again.layered, fx.spill = again.spill, fx.alpha = again.alpha;
}

bool screen_moved(const ScreenStack& st) {
    for (const ScreenFx* fx : st.fx) if (fx->seen != files_changed() && screen_stamp(fx->file) != fx->stamp) return true;
    return false;
}

void screen_effects(Stage& s, ScreenStack& st, const std::string& files, ScreenNumbers numbers) {
    if (st.files == files) return;
    st.files = files;
    // Release what was there: the stage draws to the screen again.
    s.over = nullptr;
    s.drawTarget = nullptr;
    s.view->setRenderTarget(nullptr);
    st.fx.clear();
    for (const std::string& file : script_files(files)) {
        // Filament's own settings files are laid on the view, not drawn; see viewer_settings.h.
        if (file == "none" || std::filesystem::path(file).extension() == ".json") continue;
        ScreenFx*& built = st.built[file];
        if (!built) {
            built = new ScreenFx;
            built->file = file;
            std::string code;
            // Keep the effect marked as not built, so that it is not read again each time.
            if (!screen_read(*built, code)) { std::fprintf(stderr, "%s\n", built->trouble.c_str()); continue; }
            built->interop = interop::screen(s.engine, file.c_str(), code.c_str(), built->bytes, &built->trouble, built->textureCount, built->layered);
            if (!built->interop) std::fprintf(stderr, "the effect %s is not taken: %s\n", file.c_str(), built->trouble.c_str());
            built->stamp = screen_stamp(file);
        }
        if (built->interop) st.fx.push_back(built);
    }
    if (st.fx.empty()) return;
    // The intermediate images are made once and kept while the stage is.
    if (!st.shot) {
        st.shot = screen_texture(s);
        st.depth = Texture::Builder().width((uint32_t)s.w).height((uint32_t)s.h).levels(1).usage(Texture::Usage::DEPTH_ATTACHMENT).format(Texture::InternalFormat::DEPTH24).build(*s.engine);
        st.target = RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, st.shot).texture(RenderTarget::AttachmentPoint::DEPTH, st.depth).build(*s.engine);
    }
    for (int k = 0; k < 2 && st.fx.size() > 1; ++k)
        if (!st.between[k]) st.between[k] = screen_texture(s), st.betweenTarget[k] = RenderTarget::Builder().texture(RenderTarget::AttachmentPoint::COLOR, st.between[k]).build(*s.engine);
    s.view->setRenderTarget(st.target);
    // What lies under an image that reads it is copied from here.
    s.drawTarget = st.shot;
    s.over = [&s, &st, numbers] {
        for (size_t i = 0; i < st.fx.size(); ++i) {
            screen_fresh(s, *st.fx[i]);
            Texture* from = i == 0 ? st.shot : st.between[(i - 1) % 2];
            // The last effect draws where the stage's image goes: the screen, or the
            // window's live image.
            RenderTarget* to = i + 1 == st.fx.size() ? s.out : st.betweenTarget[i % 2];
            screen_draw(s, st, *st.fx[i], from, to, numbers);
        }
    };
}
