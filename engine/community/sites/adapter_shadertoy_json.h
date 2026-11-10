// Reads a Shadertoy shader as the site stores it, with all its tabs, into adapter_tabs_isf
// (adapter_shadertoy.h). Follows rust_ae's isf_from_shadertoy_project and uses the JSON's own field
// names.
#pragma once
#include "base/json.h"
#include "community/sites/adapter.h"

// Converts the JSON of a Shadertoy shader, as given by the site's API or its Export, with all its
// tabs, into one ISF text. Returns "" and sets `why` if it cannot be converted.
// A sound tab is left out, as VVISF leaves it out. A cubemap tab draws something nothing here can
// read, so it is an error.
inline std::string adapter_shadertoy(const std::string& json, std::string& why) {
    rapidjson::Document all;
    if (all.Parse(json.c_str()).HasParseError()) return why = "this Shadertoy file does not read as JSON", "";
    const rapidjson::Value* root = &all;
    if (root->IsArray() && !root->Empty()) root = &(*root)[0];
    if (root->IsObject() && root->HasMember("Shader")) root = &(*root)["Shader"];
    if (!root->IsObject() || !root->HasMember("renderpass") || !(*root)["renderpass"].IsArray()) return why = "this Shadertoy file has no renderpass", "";
    // Returns string member `k` of `v`, or "" if it is missing or not a string.
    const auto text = [](const rapidjson::Value& v, const char* k) { return v.IsObject() && v.HasMember(k) && v[k].IsString() ? std::string(v[k].GetString()) : std::string(); };
    // Returns the type of a pass or input, falling back to the older field `ctype`.
    const auto kind = [&](const rapidjson::Value& v) { const std::string t = text(v, "type"); return t.empty() ? text(v, "ctype") : t; };
    // Returns the id as a string, whether the JSON stores it as a string or a number.
    const auto id = [](const rapidjson::Value& v) { return !v.IsObject() || !v.HasMember("id") ? std::string() : v["id"].IsString() ? std::string(v["id"].GetString()) : v["id"].IsNumber() ? std::to_string(v["id"].GetInt64()) : std::string(); };
    std::vector<const rapidjson::Value*> passes;
    std::string common;
    const rapidjson::Value* image = nullptr;
    for (const auto& pass : (*root)["renderpass"].GetArray()) {
        const std::string type = kind(pass);
        if (type == "common") common += adapter_toy_clean(text(pass, "code")) + "\n";
        else if (type == "image") image = &pass;
        else if (type == "buffer") passes.push_back(&pass);
        else if (type == "cubemap") return why = "the tab " + text(pass, "name") + " draws a cube, which Motolii does not take yet", "";
    }
    if (!image) return why = "this Shadertoy file has no Image tab", "";
    // Buffers are drawn in name order, A to D, as the site draws them.
    std::sort(passes.begin(), passes.end(), [&](const rapidjson::Value* a, const rapidjson::Value* b) { return text(*a, "name") < text(*b, "name"); });
    // Maps a buffer to its 1-based number. It is found either by the id of its output, or by the
    // placeholder image that stood for it in the API's older format, such as
    // /media/previz/buffer00.png.
    std::map<std::string, int> bufferIndex;
    for (size_t k = 0; k < passes.size(); ++k) {
        const rapidjson::Value& out = (*passes[k])["outputs"];
        if (out.IsArray()) for (const auto& o : out.GetArray()) bufferIndex[id(o)] = (int)k + 1;
        bufferIndex["buffer0" + std::to_string(k)] = (int)k + 1;
    }
    passes.push_back(image);
    bool film = false;
    std::vector<AdapterTab> tabs;
    for (size_t k = 0; k < passes.size(); ++k) {
        AdapterTab tab;
        tab.name = text(*passes[k], "name"), tab.code = adapter_toy_clean(text(*passes[k], "code"));
        if (k + 1 < passes.size()) tab.target = "buffer" + std::string(1, (char)('A' + k));
        if (passes[k]->HasMember("inputs") && (*passes[k])["inputs"].IsArray())
            for (const auto& in : (*passes[k])["inputs"].GetArray()) {
                const int n = in.HasMember("channel") && in["channel"].IsInt() ? in["channel"].GetInt() : -1;
                if (n < 0 || n > 3) continue;
                const std::string type = kind(in), src = text(in, "src").empty() ? text(in, "filepath") : text(in, "src");
                const size_t at = src.find("buffer0");
                int read = -1;
                // A buffer input reads another tab's output. A texture, video or webcam input reads
                // the image the effect is applied to, which is index 0 and may be a video.
                if (type == "buffer") {
                    auto found = bufferIndex.find(id(in));
                    if (found == bufferIndex.end() && at != std::string::npos) found = bufferIndex.find(src.substr(at, 8));
                    if (found != bufferIndex.end()) read = found->second;
                } else if (type == "texture" || type == "video" || type == "webcam") film = true, read = 0;
                const bool repeats = in.HasMember("sampler") && text(in["sampler"], "wrap") == "repeat";
                tab.channel[n] = read + (read >= 0 && repeats ? 16 : 0);
            }
        tabs.push_back(tab);
    }
    // Returns the shader's info field `k`, with characters that are unsafe in an ISF header
    // replaced by spaces. Used for the name and the author.
    const auto word = [&](const char* k) {
        const std::string said = root->HasMember("info") ? text((*root)["info"], k) : "";
        return std::regex_replace(said, std::regex(R"(["\\\n\r\t])"), " ");
    };
    return adapter_tabs_isf(common, tabs, film, word("name").empty() ? "Shadertoy" : word("name"), word("username"));
}
