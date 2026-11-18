#ifndef MOTOLII_BASE_JSON_PARTS_H_
#define MOTOLII_BASE_JSON_PARTS_H_

// A JSON object kept as parts, each with the version it last differed at, so
// that a reader who says which version it has is handed only what is newer.

#include <map>
#include <set>
#include <string>
#include <utility>

#include "base/json.h"

namespace motolii {

// One member of the object as JSON text ("null" once it is gone), and the
// version it last differed at.
struct JsonPart {
  long version = 0;
  std::string json;
};
using JsonParts = std::map<std::string, JsonPart>;

// Keeps the members of the JSON object `json` as parts. A member whose text
// differs from the part held takes version `v`; with `whole`, a part that
// `json` no longer has becomes "null". Returns whether any part differed.
inline bool json_parts_keep(JsonParts& parts, const std::string& json, long v,
                            bool whole) {
  rapidjson::Document read;
  read.Parse(json.c_str(), json.size());
  if (!read.IsObject()) return false;
  bool differed = false;
  std::set<std::string> seen;
  for (auto member = read.MemberBegin(); member != read.MemberEnd(); ++member) {
    rapidjson::StringBuffer out;
    rapidjson::Writer<rapidjson::StringBuffer> w(out);
    member->value.Accept(w);
    std::string now(out.GetString(), out.GetSize());
    const std::string key = member->name.GetString();
    seen.insert(key);
    JsonPart& part = parts[key];
    if (part.version && part.json == now) continue;
    part = {v, std::move(now)}, differed = true;
  }
  if (whole)
    for (auto& [key, part] : parts)
      if (!seen.count(key) && part.json != "null")
        part = {v, "null"}, differed = true;
  return differed;
}

// The parts newer than `since`, as the inside of a JSON object ("" for none).
// A key is written as it is: the keys are the plain names the engine gives.
inline std::string json_parts_newer(const JsonParts& parts, long since) {
  std::string said;
  for (const auto& [key, part] : parts)
    if (part.version > since)
      said += (said.empty() ? "\"" : ",\"") + key + "\":" + part.json;
  return said;
}

}  // namespace motolii

#endif  // MOTOLII_BASE_JSON_PARTS_H_
