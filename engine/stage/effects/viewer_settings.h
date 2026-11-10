// Filament's own settings file as a whole-screen effect on the shelf.
//
// The file is the JSON of Filament's libs/viewer, as saved and read by gltf_viewer:
// {"view": {"colorGrading": {...}, "bloom": {...}, "fog": {...}, ...}} (see viewer/Settings.h).
// Its numbers and on/off switches become parameters on the effect's card, as the slots of an
// After Effects file do (see community/after_effects/lottie_slots.h, whose rule for a range is
// used when none is given). The current values are written back into the file's text, read by
// Filament's JsonSerializer, and laid on the stage's view over the values the stage itself sets
// (see doc_look in document/camera.h). A part the file does not mention keeps the stage's values.
// Words such as enum names (a tone mapping, a custom LUT) are not parameters; they stay as the
// file says them.
#pragma once
#include "community/quickjs/script.h"
#include "base/json.h"
#include <viewer/Settings.h>
#include <cmath>
#include <fstream>
#include <functional>
#include <map>
#include <sstream>
#include <string>
#include <vector>

// Returns the text of the settings file. It is read again only after the window reports that a
// file changed (see files_changed).
static const std::string& viewer_text(const std::string& file) {
    struct CachedSettings { int seen = -1; std::string text; };
    static std::map<std::string, CachedSettings> cache;
    CachedSettings& one = cache[file];
    if (one.seen != files_changed()) {
        std::ifstream in(file);
        std::stringstream text;
        text << in.rdbuf();
        one.text = text.str(), one.seen = files_changed();
    }
    return one.text;
}
// Parses `text` into `doc`. Returns true if it is a viewer settings file: a JSON object with a
// "view" object and no "layers" (an After Effects file has layers).
//
// The text is first adjusted to what Filament's own writer produces and its reader accepts (jsmn,
// not strict, numbers by strtof): a comma before a closing brace (its agxToneMapper), none after
// a list (its cascadeSplitPositions), a color space written bare ("colorspace": Rec709-sRGB-D65),
// and a fog that never ends written as inf (writeJson in Settings.cpp).
static bool viewer_read(std::string text, rapidjson::Document& doc) {
    // Replaces every occurrence of `was` in the text with `as`.
    const auto say = [&](const std::string& was, const std::string& as) {
        for (size_t at = text.find(was); at != std::string::npos; at = text.find(was, at + as.size())) text.replace(at, was.size(), as);
    };
    for (const char* bare : {"Rec709-sRGB-D65", "Rec709-Linear-D65"}) say(std::string(": ") + bare, std::string(": \"") + bare + "\"");
    say(": inf", ": Infinity"), say(": -inf", ": -Infinity"), say("]\n\"", "],\n\"");
    constexpr unsigned loose = rapidjson::kParseTrailingCommasFlag | rapidjson::kParseNanAndInfFlag;
    return !doc.Parse<loose>(text.c_str()).HasParseError() && doc.IsObject() && doc.HasMember("view") && doc["view"].IsObject() && !doc.HasMember("layers");
}
// Returns true if the file is a viewer settings file.
static bool viewer_is(const std::string& file) {
    rapidjson::Document doc;
    return viewer_read(viewer_text(file), doc);
}

// Appends to `parameters` one parameter for each boolean, number, or array of up to four numbers
// found under `v`, descending through objects. `at` is the JSON Pointer of `v` in the file,
// starting with "/view". Each parameter's `words` is
// "viewer <JSON Pointer> <index of the number in its array, or -1 for a single value>".
// Other values, such as strings and longer arrays, are skipped.
static void viewer_walk(const rapidjson::Value& v, const std::string& at, std::vector<ScriptParameter>& parameters) {
    if (v.IsObject()) {
        for (auto& m : v.GetObject()) viewer_walk(m.value, at + "/" + m.name.GetString(), parameters);
        return;
    }
    // Drop the leading "/view/" from the name.
    std::string name = at.substr(6), label = name;
    for (char& c : name) if (c == '/') c = '_';
    for (char& c : label) if (c == '/') c = ' ';
    if (v.IsBool()) {
        ScriptParameter one;
        one.kind = "check", one.name = name, one.label = label, one.usual = v.GetBool() ? 1 : 0, one.words = "viewer " + at + " -1";
        parameters.push_back(one);
        return;
    }
    std::vector<double> n;
    if (v.IsNumber() && std::isfinite(v.GetDouble())) n.push_back(v.GetDouble());
    else if (v.IsArray() && v.Size() <= 4) for (auto& e : v.GetArray()) { if (!e.IsNumber() || !std::isfinite(e.GetDouble())) return; n.push_back(e.GetDouble()); }
    static const char* const xyzw[] = {"x", "y", "z", "w"};
    for (size_t i = 0; i < n.size(); ++i) {
        ScriptParameter one;
        one.kind = "track";
        one.name = v.IsArray() ? name + "_" + xyzw[i] : name;
        one.label = v.IsArray() ? label + " " + xyzw[i] : label;
        one.usual = n[i];
        // The range follows the rule of lottie_slots.h for a value with no stated range.
        one.low = n[i] < 0 ? 4 * n[i] : 0, one.high = std::max(1.0, 4 * std::fabs(n[i]));
        one.step = 0.001;
        one.words = "viewer " + at + " " + std::to_string(v.IsArray() ? (int)i : -1);
        parameters.push_back(one);
    }
}
// Returns the parameters for all the numbers and switches under "view" in the file; empty if
// the file is not a viewer settings file.
static std::vector<ScriptParameter> viewer_parameters(const std::string& file) {
    std::vector<ScriptParameter> parameters;
    rapidjson::Document doc;
    if (viewer_read(viewer_text(file), doc)) viewer_walk(doc["view"], "/view", parameters);
    return parameters;
}

// Returns the file's text with each parameter's current value written into its place, in the
// form Filament's JsonSerializer reads, or "" if the file cannot be read. `now(k)` returns the
// current value of parameter k.
static std::string viewer_said(const std::string& file, const std::vector<ScriptParameter>& parameters, const std::function<double(size_t)>& now) {
    rapidjson::Document doc;
    if (!viewer_read(viewer_text(file), doc)) return "";
    for (size_t k = 0; k < parameters.size(); ++k) {
        std::istringstream words(parameters[k].words);
        std::string viewer, at;
        int i = -1;
        words >> viewer >> at >> i;
        rapidjson::Value* v = rapidjson::Pointer(at.c_str()).Get(doc);
        if (!v) continue;
        if (v->IsBool()) v->SetBool(now(k) > 0.5);
        else if (v->IsNumber() && i < 0) v->SetDouble(now(k));
        else if (v->IsArray() && i >= 0 && i < (int)v->Size()) (*v)[i].SetDouble(now(k));
    }
    rapidjson::StringBuffer out;
    // Infinity is written as such, because strtof reads it.
    rapidjson::Writer<rapidjson::StringBuffer, rapidjson::UTF8<>, rapidjson::UTF8<>, rapidjson::CrtAllocator, rapidjson::kWriteNanAndInfFlag> write(out);
    doc.Accept(write);
    return out.GetString();
}
