#ifndef MOTOLII_BASE_CACHE_FOLDER_H_
#define MOTOLII_BASE_CACHE_FOLDER_H_

// A folder under ~/Library/Caches/Motolii/<name>, or /tmp/Library/Caches/Motolii/<name>
// when HOME is not set. The one engine-wide copy of the "getenv HOME, fall
// back to /tmp, append Library/Caches/Motolii/<name>" pattern.
// macOS only. Windows/Linux need a different caller-side rule and this helper
// is not it (shelf_folders.cpp has the APPDATA variant for the user-writable
// side).

#include <cstdlib>
#include <filesystem>
#include <string>
#include <string_view>

namespace motolii {

inline std::filesystem::path cache_folder(std::string_view name) {
  const char* home = std::getenv("HOME");
  return std::filesystem::path(home ? home : "/tmp") /
         "Library/Caches/Motolii" / std::string(name);
}

}  // namespace motolii

#endif  // MOTOLII_BASE_CACHE_FOLDER_H_
