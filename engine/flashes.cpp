// motolii_flashes: a film's flashes and patterns that may cause seizures, as EA's IRIS tells them (iris.sh): its own
// AnalyseVideo with its JSON written, as its example app runs it, by its own settings (config/appsettings.json).
#include "motolii.h"
#include "iris/Configuration.h"
#include "iris/Log.h"
#include "iris/VideoAnalyser.h"
#include <dlfcn.h>
#include <filesystem>
#include <mutex>
#include <string>

const char* motolii_flashes(const char* film, const char* folder) {
    static thread_local std::string out;
    out.clear();
    Dl_info lib{};
    dladdr((const void*)&motolii_flashes, &lib);   // (its settings beside the library, as doc_folders finds the library's own)
    std::error_code wrong;
    const auto settings = std::filesystem::weakly_canonical(lib.dli_fname ? lib.dli_fname : ".", wrong).parent_path().parent_path() / "third_party" / "iris" / "IRIS" / "config" / "";
    if (!film || !folder || !std::filesystem::is_regular_file(film) || !std::filesystem::is_regular_file(settings / "appsettings.json")) return out.c_str();
    static std::mutex one;   // (its loggers and OpenCV's threads are the process's: one film at a time)
    std::lock_guard<std::mutex> held(one);
    static std::once_flag logs;
    std::call_once(logs, [] { iris::Log::Init(false, false); });   // (neither the console nor a file)
    try {
        iris::Configuration settled;
        settled.Init(settings.string().c_str());
        settled.SetResultsPath((std::filesystem::path(folder) / "").string());
        iris::VideoAnalyser looks(&settled);
        looks.AnalyseVideo(true, film);
        if (std::filesystem::is_regular_file(looks.GetResultJsonPath())) out = looks.GetResultJsonPath();
    } catch (...) {}   // (its JSON reader throws on a setting it cannot read: nothing said)
    return out.c_str();
}
