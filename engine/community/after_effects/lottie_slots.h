// Exposes the slots of a Lottie file as script parameters and converts parameter values back
// into slot JSON.
//
// A Lottie slot is a value that the file's author allows to be set from outside. Each slot is
// identified by its sid and has the form {"sid": {"p": {"a": 0, "k": value}}}. Slots become
// parameters on the layer's card. Edited values are passed back to ThorVG in the same JSON
// form (LottieAnimation::gen, then apply, as ThorVG's own test/testLottie.cpp does).
//
// A slot with one number is one parameter. Two numbers become parameters x and y. Three or four
// numbers are a color with components from 0 to 1. Lottie does not define a range, so a number
// gets one: from 0 (or four times the value, if it is negative) to four times its absolute
// value (at least 1). Text and image slots are not exposed as parameters.
#pragma once
#include "community/quickjs/script.h"
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/document.h"
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/stringbuffer.h"
#include "third_party/filament_src/third_party/libassimp/contrib/rapidjson/include/rapidjson/writer.h"
#include <cmath>
#include <fstream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

// Reads the file's slots and returns one parameter per number in each slot. Returns an empty
// list if the file cannot be parsed or has no slots. Each parameter's "words" field is
// "lottie <sid> <index of the number in the slot> <count of numbers in the slot>"; the
// function below uses it to rebuild the slot.
static std::vector<ScriptParameter> lottie_parameters(const std::string& file) {
    std::vector<ScriptParameter> parameters;
    std::ifstream in(file);
    std::stringstream text;
    text << in.rdbuf();
    rapidjson::Document doc;
    if (doc.Parse(text.str().c_str()).HasParseError() || !doc.IsObject() || !doc.HasMember("slots") || !doc["slots"].IsObject()) return parameters;
    for (auto& slot : doc["slots"].GetObject()) {
        if (!slot.value.IsObject() || !slot.value.HasMember("p") || !slot.value["p"].IsObject() || !slot.value["p"].HasMember("k")) continue;
        const rapidjson::Value* k = &slot.value["p"]["k"];
        const bool moves = slot.value["p"].HasMember("a") && slot.value["p"]["a"].IsNumber() && slot.value["p"]["a"].GetInt() == 1;
        // An animated slot has keyframes in the file; use the value of the first keyframe.
        if (moves && k->IsArray() && !k->Empty() && (*k)[0].IsObject() && (*k)[0].HasMember("s")) k = &(*k)[0]["s"];
        std::vector<double> v;
        if (k->IsNumber()) v.push_back(k->GetDouble());
        else if (k->IsArray()) for (auto& n : k->GetArray()) if (n.IsNumber()) v.push_back(n.GetDouble());
        if (v.empty() || v.size() > 4) continue;
        const std::string sid = slot.name.GetString();
        static const char* const xy[] = {"x", "y"}, *const rgba[] = {"r", "g", "b", "a"};
        for (size_t i = 0; i < v.size(); ++i) {
            ScriptParameter one;
            one.kind = "track";
            one.name = v.size() == 1 ? sid : sid + "_" + (v.size() == 2 ? xy[i] : rgba[i]);
            one.label = v.size() == 1 ? sid : sid + " " + (v.size() == 2 ? xy[i] : rgba[i]);
            one.usual = v[i];
            if (v.size() >= 3) one.low = 0, one.high = 1;
            else one.low = v[i] < 0 ? 4 * v[i] : 0, one.high = std::max(1.0, 4 * std::fabs(v[i]));
            one.step = 0.001;
            one.words = "lottie " + sid + " " + std::to_string(i) + " " + std::to_string(v.size());
            parameters.push_back(one);
        }
    }
    return parameters;
}
// Returns slot JSON of the form {"sid": {"p": {"a": 0, "k": ...}}} for the current values.
// values[i] is the value of parameters[i]. Only slots with at least one value different from the
// parameter's default (usual) are included; a slot left alone keeps animating as the file
// defines it. Returns an empty string if no slot was changed.
static std::string lottie_slots_json(const std::vector<ScriptParameter>& parameters, const std::vector<double>& values) {
    std::map<std::string, std::vector<double>> by;
    std::map<std::string, bool> touched;
    for (size_t i = 0; i < parameters.size() && i < values.size(); ++i) {
        std::istringstream w(parameters[i].words);
        std::string lottie, sid;
        if (w >> lottie >> sid && lottie == "lottie" && values[i] != parameters[i].usual) touched[sid] = true;
    }
    for (size_t i = 0; i < parameters.size() && i < values.size(); ++i) {
        std::istringstream w(parameters[i].words);
        std::string lottie, sid;
        size_t at = 0, count = 0;
        if (!(w >> lottie >> sid >> at >> count) || lottie != "lottie" || !touched.count(sid)) continue;
        std::vector<double>& v = by[sid];
        v.resize(count, 0.0);
        if (at < count) v[at] = values[i];
    }
    rapidjson::StringBuffer out;
    rapidjson::Writer<rapidjson::StringBuffer> w(out);
    w.StartObject();
    for (const auto& [sid, v] : by) {
        w.Key(sid.c_str()), w.StartObject(), w.Key("p"), w.StartObject(), w.Key("a"), w.Int(0), w.Key("k");
        if (v.size() == 1) w.Double(v[0]);
        else {
            w.StartArray();
            for (double n : v) w.Double(n);
            w.EndArray();
        }
        w.EndObject(), w.EndObject();
    }
    w.EndObject();
    return by.empty() ? std::string() : std::string(out.GetString());
}
