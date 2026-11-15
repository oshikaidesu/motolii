#ifndef MOTOLII_BASE_FILE_READ_H_
#define MOTOLII_BASE_FILE_READ_H_

// Read a text file's contents into a std::string in one call. The one
// engine-wide copy of the "open ifstream, stringstream, rdbuf, str()" pattern
// so every effect dialect, every adapter and every cache spells the read the
// same way.
//
// A file that cannot be opened returns an empty string. Callers that need to
// tell "empty file" from "missing" check std::filesystem::exists first, as
// they do today.
//
// For binary blobs (ktx, filamat, gltf) see engine/stage/render/render_stage.h
// load_file, which returns std::vector<uint8_t>.

#include <fstream>
#include <sstream>
#include <string>
#include <string_view>

namespace motolii {

inline std::string read_text(const std::string& path) {
  std::ifstream in(path);
  if (!in) return {};
  std::stringstream text;
  text << in.rdbuf();
  return text.str();
}

inline std::string read_text(const char* path) {
  return read_text(std::string(path));
}

}  // namespace motolii

#endif  // MOTOLII_BASE_FILE_READ_H_
