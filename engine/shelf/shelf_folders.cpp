#include "shelf/shelf_folders.h"

#include <dlfcn.h>

#include <cstdlib>
#include <map>
#include <string>

std::atomic<int>& files_changed() {
  static std::atomic<int> n{0};
  return n;
}
std::filesystem::path doc_engine(const char* part) {
  Dl_info lib{};
  dladdr((const void*)&doc_engine, &lib);
  std::error_code wrong;
  return std::filesystem::weakly_canonical(lib.dli_fname ? lib.dli_fname : ".",
                                           wrong)
             .parent_path()
             .parent_path() /
         part;
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
  else if (const char* app = std::getenv("APPDATA"))
    own = std::filesystem::path(app) / "Motolii";
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
    if ((" " + std::string(extension) + " ")
                .find(" " + p.extension().string() + " ") !=
            std::string::npos &&
        p.has_extension())
      by[p.filename().string()] = p;
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
