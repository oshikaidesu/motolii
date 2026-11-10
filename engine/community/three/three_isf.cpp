// Converts a three.js screen effect into ISF effect text, so isf.cpp can load it.
//
// A three.js effect is a module under examples/jsm/shaders/*.js. Its export holds
// a uniforms table and a GLSL fragmentShader that reads the input image tDiffuse
// at the coordinate vUv.
//
// The module is run unmodified in QuickJS, the same way splatfx.cpp runs a
// PlayCanvas effect. The module 'three' is replaced by a small module of stand-in
// classes for the types that uniform values are made of.
//
// The shader is adapted to ISF as described in the ISF primer
// (docs.isf.video, chapter 9). Uniforms become INPUTS and their declarations are
// removed. texture2D is left as it is. tDiffuse becomes ISF's inputImage, vUv
// becomes isf_FragNormCoord, and time becomes TIME.
//
// A parameter's range follows from_three.py. It runs from 0 (or from four times
// the default, if that is negative) up to four times the absolute default, and the
// maximum is at least 1.
//
// Not supported: three.js's own #include chunks in the shader.
#include "community/three/three_isf.h"
#include <quickjs.h>
#include <filesystem>
#include <fstream>
#include <regex>
#include <sstream>
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/document.h"
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/stringbuffer.h"
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/writer.h"

// Source of the stand-in 'three' module: just enough of Vector2/3/4, Color and
// Matrix3/4 for a shader module to build its uniform values. Vectors keep their
// components and Color converts a hex number to r, g, b in 0-1.
static const char* const three_stand_ins = R"(
export class Vector2 { constructor(x = 0, y = 0) { this.x = x; this.y = y; } }
export class Vector3 { constructor(x = 0, y = 0, z = 0) { this.x = x; this.y = y; this.z = z; } }
export class Vector4 { constructor(x = 0, y = 0, z = 0, w = 1) { this.x = x; this.y = y; this.z = z; this.w = w; } }
export class Color { constructor(r = 1, g, b) { if (g === undefined) { const h = typeof r === 'number' ? r : 0xffffff; this.r = ((h >> 16) & 255) / 255; this.g = ((h >> 8) & 255) / 255; this.b = (h & 255) / 255; } else { this.r = r; this.g = g; this.b = b; } } }
export class Matrix3 {} export class Matrix4 {}
)";

// QuickJS module loader. Compiles the stand-in source for the name "three" and
// the file at `name` for any other module, without running it. Returns null if
// the module does not compile.
static JSModuleDef* three_load(JSContext* cx, const char* name, void*) {
    std::string src;
    if (std::string(name) == "three") src = three_stand_ins;
    else { std::ifstream in(name); std::stringstream all; all << in.rdbuf(); src = all.str(); }
    JSValue built = JS_Eval(cx, src.c_str(), src.size(), name, JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
    if (JS_IsException(built)) return nullptr;
    auto* m = (JSModuleDef*)JS_VALUE_GET_PTR(built);
    JS_FreeValue(cx, built);
    return m;
}

// See three_isf.h.
bool three_is(const std::string& file) {
    if (std::filesystem::path(file).extension() != ".js") return false;
    std::ifstream in(file);
    std::stringstream all;
    all << in.rdbuf();
    return all.str().find("fragmentShader") != std::string::npos;
}

// Runs the module `file` and returns the export that has a fragmentShader as JSON:
// {"frag": shader, "d": {defines}, "u": {uniform name: value}}. A Vector2 value is
// serialized as {x, y} and a Color as {r, g, b}. On failure returns an empty
// string and sets `why`.
static std::string three_said(const std::string& file, std::string& why) {
    JSRuntime* rt = JS_NewRuntime();
    JSContext* cx = JS_NewContext(rt);
    JS_SetModuleLoaderFunc(rt, nullptr, three_load, nullptr);
    const std::string wrap = "import * as m from '" + std::filesystem::absolute(file).string() + "';\n"
        "const S = Object.values(m).find(v => v && typeof v === 'object' && typeof v.fragmentShader === 'string');\n"
        "globalThis.__said = S ? JSON.stringify({ frag: S.fragmentShader, d: S.defines || {}, u: Object.fromEntries(Object.entries(S.uniforms || {}).map(([k, v]) => [k, v ? v.value : null])) }) : '';\n";
    std::string out;
    JSValue ran = JS_Eval(cx, wrap.c_str(), wrap.size(), "<three effect>", JS_EVAL_TYPE_MODULE);
    if (JS_IsException(ran)) {
        JSValue e = JS_GetException(cx);
        const char* s = JS_ToCString(cx, e);
        why = std::string("the three.js module: ") + (s ? s : "?");
        JS_FreeCString(cx, s), JS_FreeValue(cx, e);
    } else {
        for (JSContext* job; JS_ExecutePendingJob(rt, &job) > 0;) {}
        JSValue g = JS_GetGlobalObject(cx), s = JS_GetPropertyStr(cx, g, "__said");
        if (const char* c = JS_ToCString(cx, s)) out = c, JS_FreeCString(cx, c);
        JS_FreeValue(cx, s), JS_FreeValue(cx, g);
        if (out.empty()) why = "no export says a fragmentShader";
    }
    JS_FreeValue(cx, ran);
    JS_FreeContext(cx), JS_FreeRuntime(rt);
    return out;
}

// See three_isf.h. The result is a JSON header comment (CREDIT, ISFVSN, INPUTS),
// followed by #define lines and the adapted shader body.
std::string three_isf(const std::string& file, std::string& why) {
    const std::string said = three_said(file, why);
    rapidjson::Document d;
    if (said.empty() || d.Parse(said.c_str()).HasParseError() || !d.HasMember("frag") || !d["frag"].IsString()) return why.empty() ? why = "its export does not read" : why, "";
    std::string frag = d["frag"].GetString();
    if (std::regex_search(frag, std::regex(R"(^\s*#include\s*<)", std::regex::multiline))) return why = "it names three's own #include pieces", "";
    const rapidjson::Value none(rapidjson::kObjectType);
    const rapidjson::Value& u = d.HasMember("u") && d["u"].IsObject() ? d["u"] : none;
    // Returns the default for uniform `n` from the module's uniform values. `field`
    // selects a component of an object value, and `i` is that component's index.
    // A plain number counts only for component 0. Returns `otherwise` if the
    // value is missing or unusable. A "_three" suffix, added below when a name
    // would clash with an ISF built-in, is ignored.
    const auto value = [&](const std::string& n, const char* field, int i, double otherwise) {
        const std::string k = n.size() > 6 && n.compare(n.size() - 6, 6, "_three") == 0 ? n.substr(0, n.size() - 6) : n;
        if (!u.HasMember(k.c_str())) return otherwise;
        const rapidjson::Value& v = u[k.c_str()];
        if (v.IsNumber()) return i == 0 ? v.GetDouble() : otherwise;
        if (v.IsBool()) return (double)v.GetBool();
        if (v.IsObject() && v.HasMember(field) && v[field].IsNumber()) return v[field].GetDouble();
        return otherwise;
    };
    rapidjson::StringBuffer head;
    rapidjson::Writer<rapidjson::StringBuffer> w(head);
    w.StartObject();
    w.Key("CREDIT"), w.String(("three.js (MIT, github.com/mrdoob/three.js): " + std::filesystem::path(file).filename().string()).c_str());
    w.Key("ISFVSN"), w.String("2");
    w.Key("INPUTS"), w.StartArray();
    std::string defines;
    bool first = true;
    // The module's defines are emitted before the shader, as three.js's
    // ShaderMaterial does.
    if (d.HasMember("d") && d["d"].IsObject())
        for (auto& one : d["d"].GetObject())
            defines += "#define " + std::string(one.name.GetString()) + " " + (one.value.IsString() ? std::string(one.value.GetString()) : one.value.IsNumber() ? std::to_string(one.value.GetDouble()) : one.value.IsBool() ? std::string(one.value.GetBool() ? "1" : "0") : std::string()) + "\n";
    const std::regex uniform(R"(^[ \t]*uniform[ \t]+(\w+)[ \t]+(\w+)[ \t]*;[ \t]*(//.*)?$)", std::regex::multiline);
    for (std::sregex_iterator m(frag.begin(), frag.end(), uniform), end; m != end; ++m) {
        const std::string type = (*m)[1], own = (*m)[2];
        // These names are already used by built-in ISF parameters in isf.cpp, so the
        // shader's own uniform is renamed with a "_three" suffix.
        const bool taken = own == "resolution" || own == "frame" || own == "passindex";
        const std::string n = taken ? own + "_three" : own;
        if (taken) defines += "#define " + own + " " + n + "\n";
        const auto range = [&](double v) { w.Key("MIN"), w.Double(v < 0 ? 4 * v : 0), w.Key("MAX"), w.Double(std::max(1.0, 4 * std::fabs(v))); };
        if (n == "time" && type == "float") { defines += "#define time TIME\n"; continue; }
        // width and height are the image size, which three.js passes set themselves
        // (see HalftonePass.setSize), so they map to RENDERSIZE.
        if ((n == "width" || n == "height") && type == "float") { defines += "#define " + n + " RENDERSIZE." + (n == "width" ? "x" : "y") + "\n"; continue; }
        if (type != "vec3") w.StartObject();
        // The first sampler is the input image. Any other sampler is an image
        // input from another layer.
        if (type == "sampler2D") {
            const std::string as = first ? "inputImage" : n;
            if (as != n) defines += "#define " + n + " " + as + "\n";
            w.Key("NAME"), w.String(as.c_str()), w.Key("TYPE"), w.String("image");
            first = false;
        } else if (type == "float" || type == "int") {
            const double v = value(n, "", 0, 0);
            w.Key("NAME"), w.String(n.c_str()), w.Key("TYPE"), w.String(type == "int" ? "long" : "float"), w.Key("DEFAULT"), w.Double(v), range(v);
        } else if (type == "bool") {
            w.Key("NAME"), w.String(n.c_str()), w.Key("TYPE"), w.String("bool"), w.Key("DEFAULT"), w.Bool(value(n, "", 0, 0) != 0);
        } else if (type == "vec2") {
            const double x = value(n, "x", 0, 0), y = value(n, "y", 1, 0);
            w.Key("NAME"), w.String(n.c_str()), w.Key("TYPE"), w.String("point2D"), w.Key("DEFAULT"), w.StartArray(), w.Double(x), w.Double(y), w.EndArray();
            w.Key("MIN"), w.StartArray(), w.Double(std::min(0.0, 4 * x)), w.Double(std::min(0.0, 4 * y)), w.EndArray();
            w.Key("MAX"), w.StartArray(), w.Double(std::max(1.0, 4 * std::fabs(x))), w.Double(std::max(1.0, 4 * std::fabs(y))), w.EndArray();
        } else if (type == "vec4") {
            w.Key("NAME"), w.String(n.c_str()), w.Key("TYPE"), w.String("color"), w.Key("DEFAULT"), w.StartArray();
            for (const char* f : {"x", "y", "z", "w"}) w.Double(value(n, f, 1, 0));
            w.EndArray();
        } else if (type == "vec3") {
            // ISF has no three-component type, so a vec3 becomes three float inputs.
            // A #define rebuilds the shader's own name from them.
            const bool colour = u.HasMember(n.c_str()) && u[n.c_str()].IsObject() && u[n.c_str()].HasMember("r");
            const char* const fields[] = {colour ? "r" : "x", colour ? "g" : "y", colour ? "b" : "z"};
            for (int i = 0; i < 3; ++i) {
                const double v = value(n, fields[i], i, 0);
                w.StartObject(), w.Key("NAME"), w.String((n + "_" + fields[i]).c_str()), w.Key("TYPE"), w.String("float"), w.Key("DEFAULT"), w.Double(v);
                if (colour) w.Key("MIN"), w.Double(0), w.Key("MAX"), w.Double(1);
                else range(v);
                if (i < 2) w.EndObject();
            }
            // The last object is closed by the w.EndObject() after this chain, as for
            // every other type.
            defines += "#define " + n + " vec3(" + n + "_" + fields[0] + ", " + n + "_" + fields[1] + ", " + n + "_" + fields[2] + ")\n";
        } else { w.EndObject(), w.EndArray(), w.EndObject(); return why = "a uniform of a kind ISF has no parameter for: " + type + " " + n, ""; }
        w.EndObject();
    }
    if (first) return why = "it reads no image: not an effect", "";
    w.EndArray(), w.EndObject();
    frag = std::regex_replace(frag, uniform, "");
    std::smatch at;
    // The varying vec2 is the position in the image, three.js's vUv under whatever
    // name the shader uses. It maps to isf_FragNormCoord.
    if (std::regex_search(frag, at, std::regex(R"(^[ \t]*varying[ \t]+vec2[ \t]+(\w+)[ \t]*;[ \t]*$)", std::regex::multiline)))
        defines += "#define " + at[1].str() + " isf_FragNormCoord\n", frag = std::regex_replace(frag, std::regex(R"(^[ \t]*varying[ \t]+\w+[ \t]+\w+[ \t]*;[ \t]*$)", std::regex::multiline), "");
    // three.js prepends a luminance() function to every shader (see
    // getLuminanceFunction in WebGLProgram.js), so add it if the shader uses it
    // without defining it.
    if (frag.find("luminance(") != std::string::npos && frag.find("float luminance") == std::string::npos)
        defines += "float luminance(vec3 rgb) { return dot(vec3(0.2126, 0.7152, 0.0722), rgb); }\n";
    return "/*" + std::string(head.GetString()) + "*/\n" + defines + frag;
}
