#ifndef MOTOLII_BASE_FILE_READ_H_
#define MOTOLII_BASE_FILE_READ_H_

// Read a file's contents in one call. The one engine-wide copy of the
// "open ifstream, stringstream, rdbuf, str()" pattern so every effect
// dialect, every adapter and every cache spells the read the same way.
//
// read_text reads a text file into a std::string.
// read_bytes reads a binary blob (ktx, filamat, gltf, png, ttf) into a
// std::vector<uint8_t>. A file that cannot be opened returns an empty
// value. Callers that need to tell "empty file" from "missing" check
// std::filesystem::exists first, as they do today.

#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <sstream>
#include <string>
#include <vector>

namespace motolii {

inline std::string read_text(const std::filesystem::path& path) {
  std::ifstream in(path);
  if (!in) return {};
  std::stringstream text;
  text << in.rdbuf();
  return text.str();
}

inline std::string read_text(const std::string& path) {
  return read_text(std::filesystem::path(path));
}

inline std::string read_text(const char* path) {
  return read_text(std::filesystem::path(path));
}

inline std::vector<uint8_t> read_bytes(const std::filesystem::path& path) {
  std::ifstream in(path, std::ios::binary);
  if (!in) return {};
  return std::vector<uint8_t>(std::istreambuf_iterator<char>(in),
                              std::istreambuf_iterator<char>());
}

inline std::vector<uint8_t> read_bytes(const std::string& path) {
  return read_bytes(std::filesystem::path(path));
}

inline std::vector<uint8_t> read_bytes(const char* path) {
  return read_bytes(std::filesystem::path(path));
}

}  // namespace motolii

#endif  // MOTOLII_BASE_FILE_READ_H_
