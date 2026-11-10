// Implements motolii_flashes, which finds the flashes and patterns in a video that may cause
// seizures. It uses EA's IRIS (iris.sh): it calls IRIS's AnalyseVideo and has it write its JSON
// result, the way IRIS's example app does, using IRIS's own settings in
// config/appsettings.json.
#include "entry/motolii.h"

#include <dlfcn.h>
#include <filesystem>
#include <mutex>
#include <string>

#include "iris/Configuration.h"
#include "iris/Log.h"
#include "iris/VideoAnalyser.h"

// Analyses `film` and writes the results into `folder`. Returns the path of the result JSON, or
// an empty string if the inputs are not regular files, the settings are missing, or the
// analysis fails. The returned pointer stays valid until the next call on the same thread.
const char* motolii_flashes(const char* film, const char* folder) {
    static thread_local std::string out;
    out.clear();
    Dl_info lib{};
    // The settings are found beside the library, the same way doc_folders finds the library's own.
    dladdr((const void*)&motolii_flashes, &lib);
    std::error_code wrong;
    const auto settings = std::filesystem::weakly_canonical(lib.dli_fname ? lib.dli_fname : ".", wrong).parent_path().parent_path() / "third_party" / "iris" / "IRIS" / "config" / "";
    if (!film || !folder || !std::filesystem::is_regular_file(film) || !std::filesystem::is_regular_file(settings / "appsettings.json")) return out.c_str();
    // IRIS's loggers and OpenCV's threads belong to the whole process, so analyse one video at a time.
    static std::mutex one;
    std::lock_guard<std::mutex> held(one);
    static std::once_flag logs;
    // Log neither to the console nor to a file.
    std::call_once(logs, [] { iris::Log::Init(false, false); });
    // IRIS's JSON reader throws on a setting it cannot read. The exception is ignored and
    // nothing is reported.
    try {
        iris::Configuration settled;
        settled.Init(settings.string().c_str());
        settled.SetResultsPath((std::filesystem::path(folder) / "").string());
        iris::VideoAnalyser looks(&settled);
        looks.AnalyseVideo(true, film);
        if (std::filesystem::is_regular_file(looks.GetResultJsonPath())) out = looks.GetResultJsonPath();
    } catch (...) {}
    return out.c_str();
}
