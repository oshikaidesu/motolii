#include "shelf/shelf_folders.h"

#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

#include <cstdlib>
#include <map>
#include <string>

namespace motolii {

std::atomic<int>& files_changed() {
  static std::atomic<int> n{0};
  return n;
}
// The file this library was loaded from.
static std::filesystem::path loaded_from() {
#ifdef _WIN32
  HMODULE self = nullptr;
  wchar_t name[MAX_PATH] = {};
  GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                         GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                     (LPCWSTR)&loaded_from, &self);
  return GetModuleFileNameW(self, name, MAX_PATH) ? std::filesystem::path(name)
                                                  : std::filesystem::path(".");
#else
  Dl_info lib{};
  dladdr((const void*)&loaded_from, &lib);
  return lib.dli_fname ? lib.dli_fname : ".";
#endif
}
std::filesystem::path doc_engine(const char* part) {
  std::error_code wrong;
  // The library is <engine>/out/libmotolii.dylib, but while the open app runs a
  // rebuilt engine it is <engine>/out/live/libmotolii-<time>.dylib, a hot-swapped
  // copy one folder deeper (motolii.dart _liveCopy). Anchor on the out/ folder so
  // either depth resolves to the same <engine>; without it the extra live/ folder
  // shifted the root and the shelves/ tree (effects, create) came back empty.
  std::filesystem::path dir =
      std::filesystem::weakly_canonical(loaded_from(), wrong).parent_path();
  for (std::filesystem::path p = dir; !p.empty() && p != p.parent_path();
       p = p.parent_path())
    if (p.filename() == "out") {
      dir = p;
      break;
    }
  return dir.parent_path() / part;
}
std::vector<std::filesystem::path> doc_folders(const char* folder) {
  static const std::map<std::string, const char*> before{
      {"create", "recipes"}, {"expressions", "animators"}, {"ease", "ways"}};
  static const std::map<std::string, const char*> engine_kept{
      {"words", "third_party/wordnet_ja"},
      {"fonts", "third_party/noto_sans_jp"}};
  const auto kept = engine_kept.find(folder);
  std::vector<std::filesystem::path> at{
      kept != engine_kept.end()
          ? doc_engine(kept->second)
          : (doc_engine("..") / "shelves" / folder).lexically_normal()};
  std::filesystem::path own;
  if (const char* o = std::getenv("MOTOLII_OWN"))
    own = o;
#ifdef _WIN32  // (the user's own folder: %APPDATA%/Motolii, the app's
               // engine_paths.dart)
  else if (const char* app = std::getenv("APPDATA"))
    own = std::filesystem::path(app) / "Motolii";
#endif
  else if (const char* home = std::getenv("HOME"))
    own = std::filesystem::path(home) / "Library" / "Application Support" /
          "Motolii";
  if (own.empty()) return at;
  if (const auto old = before.find(folder); old != before.end())
    at.push_back(own / old->second);
  at.push_back(own / folder);
  return at;
}
std::vector<std::filesystem::path> doc_folder_files(const char* folder,
                                                    const char* extension) {
  // `wrong` receives filesystem errors. A folder that does not exist yields no
  // files.
  std::map<std::string, std::filesystem::path> by;
  std::error_code wrong;
  const auto take = [&](const std::filesystem::path& p) {
    const std::string name = p.filename().generic_string();
    // Sidecar `.ui.js` files supply custom Inspector UI for their sibling
    // effect/expression and must never appear as standalone shelf items.
    if (name.size() > 6 && name.compare(name.size() - 6, 6, ".ui.js") == 0)
      return;
    if ((" " + std::string(extension) + " ")
                .find(" " + p.extension().generic_string() + " ") !=
            std::string::npos &&
        p.has_extension())
      by[name] = p;
  };
  // effects/ and create/ keep one subfolder per origin or purpose, such as
  // blur/ or shapes/, and are read recursively.
  for (const auto& dir : doc_folders(folder))
    if (std::string(folder) == "effects" || std::string(folder) == "create")
      for (const auto& e :
           std::filesystem::recursive_directory_iterator(dir, wrong))
        take(e.path());
    else
      for (const auto& e : std::filesystem::directory_iterator(dir, wrong))
        take(e.path());
  std::vector<std::filesystem::path> files;
  for (const auto& [_, f] : by) files.push_back(f);
  return files;
}
bool doc_folder_moved(int& seen) {
  if (seen == files_changed()) return false;
  seen = files_changed();
  return true;
}

}  // namespace motolii
