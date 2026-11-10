// Fetches things from the net for the adapters in adapter.h. Downloads use curl, started directly
// with no shell in between.
// Also reads works from OpenProcessing. A work named by its address is fetched through the site's
// public API (openprocessing.org/api: its tabs, libraries, files and license) and laid out in a
// folder the way a saved page is, so the adapter reads it like any other page. The site allows 40
// requests a minute. A work takes 3 requests plus one for each of its files.
#pragma once
#include <glib.h>
#include "base/json.h"
#include <filesystem>
#include <fstream>
#include <regex>
#include <sstream>
#include <string>

// Downloads `url` to the file `to` with curl. Redirects are followed only over http and https, and
// the download stops after 60 seconds. Returns true on success.
inline bool adapter_fetch(const std::string& url, const std::filesystem::path& to) {
    const std::string file = to.string();
    const char* line[] = {"curl", "-fsSL", "--proto", "=http,https", "--proto-redir", "=http,https", "-m", "60", "-o", file.c_str(), "--url", url.c_str(), nullptr};
    gint status = 1;
    return g_spawn_sync(nullptr, (gchar**)line, nullptr, (GSpawnFlags)(G_SPAWN_SEARCH_PATH | G_SPAWN_STDOUT_TO_DEV_NULL | G_SPAWN_STDERR_TO_DEV_NULL), nullptr, nullptr, nullptr, nullptr, &status, nullptr) && status == 0;
}

// Returns the number of the work if `word` is the address of an OpenProcessing sketch, or "" if it
// is not.
inline std::string adapter_site_work(const std::string& word) {
    static const std::regex address(R"(^\s*(?:https?://)?(?:www\.)?openprocessing\.org/sketch/(\d+)[^\s]*\s*$)");
    std::smatch said;
    return word.size() < 200 && std::regex_match(word, said, address) ? said[1].str() : "";
}

// Downloads the OpenProcessing work `id` into the directory `at`, with its code tabs and files, and
// returns the path of the HTML page that loads them. On failure returns an empty path and sets
// `why` to the reason.
inline std::filesystem::path adapter_openprocessing(const std::string& id, const std::filesystem::path& at, std::string& why) {
    const std::string api = "https://openprocessing.org/api/sketch/" + id;
    std::error_code wrong;
    std::filesystem::create_directories(at, wrong);
    // Downloads `url` into the file `name` and parses it as JSON into `out`. Returns false on
    // failure.
    const auto asked = [&](const std::string& url, const char* name, rapidjson::Document& out) {
        if (!adapter_fetch(url, at / name)) return false;
        std::ifstream in(at / name);
        std::stringstream all;
        all << in.rdbuf();
        return !out.Parse(all.str().c_str()).HasParseError();
    };
    // Returns member `k` of `v` as a string, or "" if it is missing or not a string.
    const auto word = [](const rapidjson::Value& v, const char* k) { return v.IsObject() && v.HasMember(k) && v[k].IsString() ? std::string(v[k].GetString()) : std::string(); };
    rapidjson::Document about, tabs, files;
    if (!asked(api, "about.json", about) || !about.IsObject() || !asked(api + "/code", "code.json", tabs) || !tabs.IsArray() || !asked(api + "/files", "files.json", files) || !files.IsArray())
        return why = "OpenProcessing gave nothing for the work " + id + ": it may be private, or asked too often (40 a minute)", std::filesystem::path{};
    // Replaces characters that are unsafe in a file name with underscores.
    const auto safe = [](const std::string& name) { return std::regex_replace(name, std::regex(R"([^A-Za-z0-9._\-])"), "_"); };
    std::vector<std::string> scripts;
    bool page = false;
    // Write each tab as a file named after its title. A tab named index.html is the page itself.
    // The others are loaded by script tags, except the default sketch file and style sheets.
    for (const auto& tab : tabs.GetArray()) {
        std::string name = safe(word(tab, "title"));
        if (name.empty()) continue;
        if (name.find('.') == std::string::npos) name += ".js";
        std::ofstream(at / name) << word(tab, "code");
        if (name == "index.html") page = true;
        else if (name != "mySketch.js" && name.find(".css") == std::string::npos) scripts.push_back(name);
    }
    // Download the work's images and other files.
    for (const auto& one : files.GetArray()) {
        const std::string url = word(one, "url"), name = safe(word(one, "name"));
        if (!url.empty() && !name.empty() && !adapter_fetch(url, at / name)) return why = "OpenProcessing did not give the file " + name, std::filesystem::path{};
    }
    if (page) return at / "index.html";
    if (std::filesystem::exists(at / "mySketch.js", wrong)) scripts.push_back("mySketch.js");
    std::string head = std::regex_replace(word(about, "title") + " by " + word(about, "username") + ", " + word(about, "license") + ", openprocessing.org/sketch/" + id, std::regex(R"([<>\n\r])"), " ");
    std::ofstream out(at / "index.html");
    // The first line of the saved page says what the work is and whose it is.
    out << "<script>// " << head << "</script>\n";
    if (about.HasMember("libraries") && about["libraries"].IsArray())
        for (const auto& lib : about["libraries"].GetArray()) if (const std::string url = word(lib, "url"); !url.empty()) out << "<script src=\"" << url << "\"></script>\n";
    for (const std::string& name : scripts) out << "<script src=\"" << name << "\"></script>\n";
    return at / "index.html";
}
