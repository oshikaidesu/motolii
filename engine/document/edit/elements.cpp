// Elements: a layer kept as a file of its own, put into other projects and
// followed when the file changes (Alight Motion's My Elements). They are
// stored like presets (presets.cpp); this file is the keeping, the adding and
// the following.
#include <sqlite3.h>

#include "document/document.h"
#include "document/edit/presets.h"
#include "document/evaluate/shown.h"
#include "shelf/shelf_folders.h"
namespace motolii {

namespace {

// Returns when an element's file was last written, in seconds, or -1 if it
// cannot be read. An instance stores this value to know that the file has
// changed since.
double doc_element_written(const std::string& path) {
  std::error_code wrong;
  const auto at = std::filesystem::last_write_time(path, wrong);
  return wrong ? -1.0
               : std::chrono::duration<double>(at.time_since_epoch()).count();
}

// Returns SQL that records where each layer put in by an element came from. It
// is run with the paste, like the extra SQL that uses pasted_as. It stores
// which of the element's layers it is (element_part). For a text layer it
// stores the text as the element had it (element_text), so that words changed
// since are the user's own and are kept when the element changes, like an
// override on a Figma instance. On the first layer it stores when the file was
// written (element_at), its retime settings, and the length of the element
// (element_length).
std::string doc_element_marks(double written) {
  char* marks = sqlite3_mprintf(
      "insert or replace into keyframe(layer, name, at, value) select id, "
      "'element_part', 0, was from pasted_as where was != 1;"
      "insert or replace into keyframe(layer, name, at, value) select p.id, "
      "'element_text', 0, f.value from pasted_as as p join preset.keyframe as "
      "f on f.layer = p.was and f.name = 'text' and f.at = 0;"
      "insert or replace into keyframe(layer, name, at, value) select id, "
      "'element_at', 0, %!.17g from pasted_as where was = 1;"
      // Replace the first layer's retime settings and element_length
      // with those of the element.
      "delete from keyframe where layer = (select id from pasted_as where was "
      "= 1) and name in ('retime', 'retime_in', 'retime_out', "
      "'element_length');"
      "insert into keyframe(layer, name, at, value) select p.id, f.name, 0, "
      "f.value from pasted_as as p join preset.keyframe as f on f.layer = 1 "
      "and f.at = 0 and f.name in ('retime', 'retime_in', 'retime_out') where "
      "p.was = 1;"
      "insert into keyframe(layer, name, at, value) select p.id, "
      "'element_length', 0, f.value from pasted_as as p join preset.keyframe "
      "as f on f.layer = 1 and f.at = 0 and f.name = 'duration' where p.was = "
      "1;",
      written);
  std::string said = marks;
  sqlite3_free(marks);
  return said;
}

}  // namespace

bool doc_element_keep(Doc& d, int layer, const std::string& name) {
  if (name.empty() || name.find_first_of("/\\:") != std::string::npos)
    return d.error = "an element's name is a file's name", false;
  std::error_code wrong;
  const std::filesystem::path dir = doc_folders("elements").back();
  std::filesystem::create_directories(dir, wrong);
  return doc_preset_save(d, layer, (dir / (name + ".motolii")).string().c_str(),
                         true);
}

int doc_element_add(Doc& d, const char* path, double now) {
  const auto roots = doc_preset_roots();
  std::string word = path;
  // Store the path as a preset does, with the library's or the user's folder
  // replaced by its placeholder.
  for (const auto& [root, said] : {std::pair{roots.first, "{motolii}/"},
                                   std::pair{roots.second, "{own}/"}})
    if (word.rfind(root, 0) == 0) word = said + word.substr(root.size());
  char* also = sqlite3_mprintf(
      "delete from keyframe where layer = (select id from pasted_as where was "
      "= 1) and name in ('x', 'y', 'element');"
      "insert into keyframe(layer, name, at, value) select id, 'x', 0, 0 from "
      "pasted_as where was = 1 union all select id, 'y', 0, 0 from pasted_as "
      "where was = 1"
      " union all select id, 'element', 0, %Q from pasted_as where was = 1;%s",
      word.c_str(), doc_element_marks(doc_element_written(path)).c_str());
  const int made = doc_preset_paste(d, path, now, also);
  sqlite3_free(also);
  return made;
}

int doc_elements_follow(Doc& d) {
  const auto roots = doc_preset_roots();
  int n = 0;
  for (const int one : doc_layers(d)) {
    std::string path = doc_word(d, one, "element");
    if (path.empty()) continue;
    if (path.rfind("{motolii}/", 0) == 0)
      path = roots.first + path.substr(10);
    else if (path.rfind("{own}/", 0) == 0)
      path = roots.second + path.substr(6);
    const double written = doc_element_written(path);
    if (written < 0 || written == doc_number(d, one, "element_at", 0, -1))
      continue;
    // The element layer, the layers whose parent it is, and their children in
    // turn.
    std::vector<int> held{one};
    std::string gone, kept;
    for (size_t i = 0; i < held.size(); ++i)
      for (const int t : doc_layers(d))
        if (t != held[i] && (int)doc_number(d, t, "parent", 0, 0) == held[i] &&
            std::find(held.begin(), held.end(), t) == held.end()) {
          held.push_back(t);
          char* g =
              sqlite3_mprintf("delete from keyframe where layer = %d;", t);
          gone += g;
          sqlite3_free(g);
          const std::string words = doc_word(d, t, "text");
          const int part = (int)doc_number(d, t, "element_part", 0, 0);
          if (part && doc_word(d, t, "kind") == "text" &&
              words != doc_word(d, t, "element_text")) {
            char* k = sqlite3_mprintf(
                "update keyframe set value = %Q where layer = (select id from "
                "pasted_as where was = %d) and name = 'text' and at = 0;",
                words.c_str(), part);
            kept += k;
            sqlite3_free(k);
          }
        }
    const std::string also = doc_element_marks(written) + kept;
    n += doc_preset_paste(d, path.c_str(), doc_number(d, one, "start", 0, 0),
                          also.c_str(), one, gone.c_str()) == one;
  }
  return n;
}

}  // namespace motolii
