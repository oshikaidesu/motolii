// AviUtl2's scripts (.anm2 effects, .obj2 objects: Lua with pixel shaders in HLSL kept in its comments, as KENくん's
// lua.txt says them) dropped in a thing's fx run as they are on its picture (aviutl_fx.h). Here what needs no picture:
// the file read (one script of an @ file, "@Stylize_K.anm2#Mosaic"), its head's parameters, and each shader made WGSL by
// glslang's own HLSL front end and Tint, as isf.cpp makes an ISF file's (built apart: aviutl.cpp, its headers heavy).
#pragma once
#include "community/quickjs/script.h"
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

bool aviutl_is(const std::string& file);
inline std::string aviutl_path(const std::string& file) { return file.substr(0, file.find('#', file.rfind('/') + 1)); }   // (the file of "@x.anm2#name")
// A script's name as a word of an effect list: the list is split at spaces (script_files) and the file taken to the last
// "/" (aviutl_path), so those two of a name are written as a URL's fragment writes them (RFC 3986 2.1): 20 of the 355
// bundled scripts have one, [Shader]Chromatic Aberration among them. A name shown is the name; only the word is coded.
inline const std::pair<const char*, const char*> aviutl_coded[] = {{" ", "%20"}, {"/", "%2F"}};
inline std::string aviutl_word(std::string name) {
    for (const auto& [plain, coded] : aviutl_coded) for (size_t at; (at = name.find(plain)) != std::string::npos;) name.replace(at, 1, coded);
    return name;
}
inline std::string aviutl_unword(std::string word) {
    for (const auto& [plain, coded] : aviutl_coded) for (size_t at; (at = word.find(coded)) != std::string::npos;) word.replace(at, 3, plain);
    return word;
}
// The script's own text (the file, or its part from "@name" to the next) and the whole file's (any part's shaders are its).
bool aviutl_text(const std::string& file, std::string& own, std::string& all, std::string& why);
// A variable its head says (--track@, --check@, --color@, --select@, --value@; the old --track0: and --check0: as obj's),
// and the parameters Motolii shows for them: a colour three tracks (0..255, and an on/off when it may be nil), a choice a
// track of its choices' order.
struct AviutlVar { std::string var, kind, expr, label; double usual = 0, step = 1; bool truth = false, unset = false, named = false; std::vector<double> values; std::vector<std::string> choices; };   // (named: --track@name, a variable of its own; else --track0, obj.track0; label: its name shown, obj.effect's for it; step: a track's 移動単位)
std::vector<AviutlVar> aviutl_vars(const std::string& text);
std::vector<ScriptParameter> aviutl_parameters(const std::string& file);
// One embedded pixel shader made WGSL in the interop's manner (screen_interop.h: tN at binding 2N, sN at 2N+1, b0 after them,
// its entry `main`), `clip`: each sample transparent past the picture (the sampler "clip"). Its constants as Lua gives
// them (floats in HLSL's cbuffer packing) moved where WGSL lays them: `count` floats from byte `from` to byte `to`.
struct AviutlShader {
    std::string wgsl, why;
    int textureCount = 1;
    uint32_t bytes = 0;
    std::vector<uint32_t> from, to, count;
};
const AviutlShader& aviutl_shader(const std::string& hlsl, const std::string& entry, bool clip);
