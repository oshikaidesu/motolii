// Implements video_flash_check, which finds the flashes and patterns in a
// video that may cause seizures. It uses EA's IRIS (iris.sh): it calls IRIS's
// AnalyseVideo and has it write its JSON result, the way IRIS's example app
// does, using IRIS's own settings in config/appsettings.json.
#include "media/video_flash_check.h"

#include <filesystem>
#include <mutex>
#include <string>

#include "iris/Configuration.h"
#include "iris/Log.h"
#include "iris/VideoAnalyser.h"
#include "shelf/shelf_folders.h"

namespace motolii {

const char* video_flash_check(const char* film, const char* folder) {
  static thread_local std::string out;
  out.clear();
  // The settings are in the engine's own folder, found as doc_folders finds
  // the library's own.
  const auto settings = doc_engine("third_party/iris/IRIS/config") / "";
  if (!film || !folder || !std::filesystem::is_regular_file(film) ||
      !std::filesystem::is_regular_file(settings / "appsettings.json"))
    return out.c_str();
  // IRIS's loggers and OpenCV's threads belong to the whole process, so analyse
  // one video at a time.
  static std::mutex one;
  std::lock_guard<std::mutex> held(one);
  static std::once_flag logs;
  // Log neither to the console nor to a file.
  std::call_once(logs, [] { iris::Log::Init(false, false); });
  // IRIS's JSON reader throws on a setting it cannot read. The exception is
  // ignored and nothing is reported.
  try {
    iris::Configuration settled;
    settled.Init(settings.generic_string().c_str());
    settled.SetResultsPath(
        (std::filesystem::path(folder) / "").generic_string());
    iris::VideoAnalyser looks(&settled);
    looks.AnalyseVideo(true, film);
    if (std::filesystem::is_regular_file(looks.GetResultJsonPath()))
      out = looks.GetResultJsonPath();
  } catch (...) {
  }
  return out.c_str();
}

}  // namespace motolii
