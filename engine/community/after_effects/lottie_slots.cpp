#include "community/after_effects/lottie_slots.h"

#include <algorithm>
#include <cmath>
#include <fstream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

#include "base/json.h"
#include "community/quickjs/script.h"

std::vector<ScriptParameter> lottie_parameters(const std::string& file) {
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

std::string lottie_slots_json(const std::vector<ScriptParameter>& parameters, const std::vector<double>& values) {
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
