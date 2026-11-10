#ifndef MOTOLII_COMMUNITY_AVIUTL_AVIUTL_H_
#define MOTOLII_COMMUNITY_AVIUTL_AVIUTL_H_
// Reads AviUtl2 scripts (.anm2 effects and .obj2 objects) apart from drawing them.
//
// An AviUtl2 script is a Lua file whose pixel shaders are HLSL stored in Lua comments, as described
// in AviUtl2's lua.txt (by KEN). A script in a layer's effect list runs as written on the layer's
// image; that part is in aviutl_fx.h. This file declares the parts that need no image: reading a
// script file (one script of an "@" file, as in "@Stylize_K.anm2#Mosaic"), reading the parameters
// declared in the script's header, and converting each shader from HLSL to WGSL with glslang's HLSL
// front end and Tint, the same way isf.cpp converts the shaders of an ISF file. The implementation
// is in aviutl.cpp, a separate translation unit because its headers are heavy.
#include "community/quickjs/script.h"
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

// Returns true if `file` names an AviUtl2 script: a path ending in .anm2 or .obj2, optionally
// followed by "#" and the name of one script.
bool aviutl_is(const std::string& file);
// Returns the file part of a script name such as "@x.anm2#name", without the "#" suffix.
inline std::string aviutl_path(const std::string& file) { return file.substr(0, file.find('#', file.rfind('/') + 1)); }
// Escapes for the characters of a script name that cannot appear inside one word of an effect list.
// The list is split at spaces (script_files) and a file name ends at the last "/" (aviutl_path), so
// a space and a slash in a script name are written as in a URL fragment (RFC 3986 section 2.1).
// Some bundled scripts have such names, for example "[Shader]Chromatic Aberration". The name shown
// to the user is unchanged; only the word stored in the list is encoded.
inline const std::pair<const char*, const char*> aviutl_coded[] = {{" ", "%20"}, {"/", "%2F"}};
// Returns `name` encoded for use as one word of an effect list.
inline std::string aviutl_word(std::string name) {
    for (const auto& [plain, coded] : aviutl_coded) for (size_t at; (at = name.find(plain)) != std::string::npos;) name.replace(at, 1, coded);
    return name;
}
// Reverses aviutl_word.
inline std::string aviutl_unword(std::string word) {
    for (const auto& [plain, coded] : aviutl_coded) for (size_t at; (at = word.find(coded)) != std::string::npos;) word.replace(at, 3, plain);
    return word;
}
// Reads the script named by `file`. `own` receives the text of that script: the whole file or, for
// an "@" file, the part from "@name" to the next script. `all` receives the whole file, because the
// shaders of every script in a file are shared by all of them. Returns false and sets `why` if the
// file or the named script cannot be found.
bool aviutl_text(const std::string& file, std::string& own, std::string& all, std::string& why);
// A variable declared in the comment lines at the head of a script: --track@, --check@, --color@,
// --select@ and --value@, or the older numbered forms --track0: and --check0: used by .obj scripts.
// It also holds how Motolii shows the variable: a color becomes three tracks (0..255), plus an
// on/off check when it may be nil, and a select becomes a track over the order of its choices.
//
// Fields:
//   var      Name of the Lua variable.
//   kind     "track", "check", "color", "select" or "value".
//   expr     Lua source of the value, for kind "value".
//   label    Name shown to the user.
//   usual    Default value.
//   step     Smallest change of a track (the "unit of movement" in lua.txt).
//   truth    True if a check is written as true/false rather than 0/1.
//   unset    True if a color may be nil, meaning "not set".
//   named    True for --track@name, a variable with a name of its own. False for the numbered
//            forms such as --track0, which are read as obj.track0.
//   values   For a select, the value of each choice.
//   choices  For a select, the name of each choice.
struct AviutlVar { std::string var, kind, expr, label; double usual = 0, step = 1; bool truth = false, unset = false, named = false; std::vector<double> values; std::vector<std::string> choices; };
// Parses the header lines of the script text `text` and returns the variables they declare.
std::vector<AviutlVar> aviutl_vars(const std::string& text);
// Returns the parameters Motolii shows for the script `file`, in the order they are declared.
std::vector<ScriptParameter> aviutl_parameters(const std::string& file);
// One embedded pixel shader converted to WGSL for the interop layout (screen_interop.h): image N
// is bound at 2N and its sampler at 2N+1, the constants buffer (b0) follows the images, and the
// entry point is named `main`. If `clip` was requested, each sample is transparent outside the
// image (the "clip" sampler).
//
// The constants as Lua passes them (floats in HLSL cbuffer packing) must be moved to where WGSL
// expects them. Each entry i copies `count[i]` floats from byte offset `from[i]` to byte offset
// `to[i]`.
struct AviutlShader {
    // The WGSL source, or empty on failure, in which case `why` gives the reason.
    std::string wgsl, why;
    // Number of images the shader reads.
    int textureCount = 1;
    // Size in bytes of the constants buffer in the WGSL layout.
    uint32_t bytes = 0;
    std::vector<uint32_t> from, to, count;
};
// Returns the WGSL for the HLSL shader `hlsl` with entry point `entry`, converting it on first
// use and caching the result. On failure the result's `wgsl` is empty and `why` says why.
const AviutlShader& aviutl_shader(const std::string& hlsl, const std::string& entry, bool clip);

#endif  // MOTOLII_COMMUNITY_AVIUTL_AVIUTL_H_
