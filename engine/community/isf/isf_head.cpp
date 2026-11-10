// Reading the JSON head of an ISF file: its strings and numbers, the size of a
// pass, and the shelf an effect goes on.
#include <sqlite3.h>

#include <regex>

#include "community/isf/isf_translate.h"

namespace motolii {

std::string isf_str(const rapidjson::Value& o, const char* k,
                    std::string fallback) {
  return o.IsObject() && o.HasMember(k) && o[k].IsString()
             ? std::string(o[k].GetString())
             : fallback;
}

double isf_num(const rapidjson::Value& v, double fallback) {
  return v.IsNumber() ? v.GetDouble()
         : v.IsBool() ? (double)v.GetBool()
                      : fallback;
}

// Passes are drawn in turn, each into an image of its own, except the last,
// which is drawn to the output. A pass image keeps its contents from frame to
// frame when PERSISTENT is set and uses a float format when FLOAT is set. Its
// size is a share of the frame size or a number of pixels.
//
// Reads one side of a pass size (`k` is WIDTH or HEIGHT; `side` names the
// frame side it may refer to) and stores it in `said`. The result is
// "s<share>" for a share of the frame side or "a<pixels>" for an absolute
// size. Returns false if the size cannot be expressed.
bool isf_pass_size(const rapidjson::Value& p, const char* k, const char* side,
                   std::string& said) {
  std::string e =
      p.HasMember(k) ? (p[k].IsString() ? p[k].GetString()
                                        : std::to_string((int)isf_num(p[k], 0)))
                     : std::string("$") + side;
  e.erase(std::remove(e.begin(), e.end(), ' '), e.end());
  std::smatch m;
  char out[32];
  if (std::regex_match(e, m,
                       std::regex(std::string(R"((?:floor\()?\$)") + side +
                                  R"((?:/([\d.]+))?(?:\*([\d.]+))?\)?)")))
    return std::snprintf(out, sizeof out, "s%g",
                         (m[1].matched ? 1 / std::stod(m[1]) : 1) *
                             (m[2].matched ? std::stod(m[2]) : 1)),
           said = out, true;
  if (std::regex_match(e, std::regex(R"([\d.]+)")))
    return said = "a" + std::to_string((int)std::stod(e)), true;
  // Any other expression is evaluated by SQLite with $WIDTH and $HEIGHT bound
  // as parameters, using 1000 pixels as the frame size. If it reads the frame
  // size, the result is a share of the frame value / 1000. If it reads no
  // parameter, the result is a number of pixels. An expression with any other
  // parameter is rejected.
  sqlite3* db = nullptr;
  sqlite3_stmt* q = nullptr;
  double v = -1;
  if (sqlite3_open(":memory:", &db) == SQLITE_OK &&
      sqlite3_prepare_v2(db, ("SELECT " + e).c_str(), -1, &q, nullptr) ==
          SQLITE_OK) {
    bool known = true;
    for (int i = 1; i <= sqlite3_bind_parameter_count(q); ++i) {
      const std::string n = sqlite3_bind_parameter_name(q, i)
                                ? sqlite3_bind_parameter_name(q, i)
                                : "";
      if (n == "$WIDTH" || n == "$HEIGHT")
        sqlite3_bind_double(q, i, 1000);
      else
        known = false;
    }
    if (known && sqlite3_step(q) == SQLITE_ROW &&
        sqlite3_column_type(q, 0) != SQLITE_NULL)
      v = sqlite3_column_double(q, 0);
  }
  sqlite3_finalize(q);
  sqlite3_close(db);
  if (v <= 0) return false;
  if (e.find('$') != std::string::npos)
    return std::snprintf(out, sizeof out, "s%g", v / 1000), said = out, true;
  return said = "a" + std::to_string((int)v), true;
}

std::optional<std::string> isf_shelf(const rapidjson::Value& head,
                                     const std::vector<std::string>& imageNames,
                                     const rapidjson::Value& inputs) {
  // Shelf: uses the shelf's own category names where the ISF categories say the
  // same thing.
  if (head.HasMember("CATEGORIES") && head["CATEGORIES"].IsArray() &&
      !head["CATEGORIES"].Empty() && head["CATEGORIES"][0].IsString()) {
    std::string all, shelf = head["CATEGORIES"][0].GetString();
    for (const auto& c : head["CATEGORIES"].GetArray())
      if (c.IsString()) all += std::string(c.GetString()) + " ";
    for (const char* own :
         {"Glitch", "Distort", "Color", "Film", "Light", "Time", "Stylize"})
      if (all.find(own) != std::string::npos) {
        shelf = own;
        break;
      }
    // Vidvox names such as "Geometry Adjustment" and "Halftone Effect" are
    // shortened to "Geometry" and "Halftone", like the other names. The shelf
    // mapping above already turns "Distortion Effect" into Distort. Tabs are
    // removed so that each kind is one chip.
    shelf.erase(0, shelf.find_first_not_of(" \t")),
        shelf.erase(shelf.find_last_not_of(" \t") + 1);
    for (const std::string tail : {" Effect", " Adjustment"})
      if (shelf.size() > tail.size() &&
          shelf.compare(shelf.size() - tail.size(), tail.size(), tail) == 0)
        shelf.resize(shelf.size() - tail.size());
    // A transition (ISF_Spec: it has startImage, endImage and progress) goes on
    // one shelf whatever its wipe or dissolve style, as After Effects keeps its
    // transitions under Transition. Once applied, it runs from the playhead
    // (doc_fx_file).
    if (std::find(imageNames.begin(), imageNames.end(), "startImage") !=
            imageNames.end() &&
        std::find(imageNames.begin(), imageNames.end(), "endImage") !=
            imageNames.end() &&
        std::any_of(inputs.GetArray().begin(), inputs.GetArray().end(),
                    [&](const rapidjson::Value& i) {
                      return isf_str(i, "NAME") == "progress";
                    }))
      shelf = "Transition";
    return shelf;
  }
  return std::nullopt;
}

}  // namespace motolii
