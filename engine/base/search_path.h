#ifndef MOTOLII_BASE_SEARCH_PATH_H_
#define MOTOLII_BASE_SEARCH_PATH_H_
// A program started from Finder gets PATH=/usr/bin:/bin, so `ffmpeg` (Homebrew's, or /usr/local's) is not found
// by the shell that popen and system start. The engine adds those two folders to its own PATH once, and its
// children (ffmpeg, ffprobe, the shell) inherit it.
#include <cstdlib>
#include <string>
#include <vector>

namespace motolii {

// The PATH value `path` with each of `more` appended as a last entry, unless it is already an entry (exact
// match; entries are separated by ':'). An empty `path` gives just `more`: never a leading ':', which would
// mean the current directory.
inline std::string path_with(const std::string& path,
                             const std::vector<std::string>& more = {
                                 "/opt/homebrew/bin", "/usr/local/bin"}) {
  std::string out = path;
  for (const std::string& dir : more) {
    bool have = false;
    for (size_t at = 0; at <= out.size() && !have;) {
      size_t end = out.find(':', at);
      if (end == std::string::npos) end = out.size();
      have = out.compare(at, end - at, dir) == 0 && end - at == dir.size();
      at = end + 1;
    }
    if (!have) out += (out.empty() ? "" : ":") + dir;
  }
  return out;
}

// `dir` placed first in the PATH value `path`, so a program in `dir` is found before one of the same name further on.
// Unchanged if `dir` is already first; an empty `path` gives just `dir` (never a trailing ':').
inline std::string path_first(const std::string& path, const std::string& dir) {
  if (path.empty()) return dir;
  if (path == dir || path.compare(0, dir.size() + 1, dir + ":") == 0) return path;
  return dir + ":" + path;
}

// Sets PATH to path_first(its present value, dir). An unset PATH counts as empty.
inline void add_first_to_path(const std::string& dir) {
  const char* now = std::getenv("PATH");
  setenv("PATH", path_first(now ? now : "", dir).c_str(), 1);
}

// Sets PATH to path_with(its present value, more). An unset PATH counts as empty.
inline void add_to_path(const std::vector<std::string>& more = {
                            "/opt/homebrew/bin", "/usr/local/bin"}) {
  const char* now = std::getenv("PATH");
  setenv("PATH", path_with(now ? now : "", more).c_str(), 1);
}

}  // namespace motolii

#endif  // MOTOLII_BASE_SEARCH_PATH_H_
