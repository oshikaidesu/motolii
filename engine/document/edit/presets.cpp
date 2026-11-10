#include "document/edit/presets.h"

#include <sqlite3.h>

#include <algorithm>
#include <chrono>
#include <filesystem>
#include <map>
#include <set>
#include <system_error>
#include <utility>
#include <vector>

#include "document/card_table.h"
#include "document/document.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/undo.h"
#include "shelf/shelf_folders.h"

namespace motolii {

namespace {

// The properties that say what a layer is. They are not copied into a preset:
// kind, file, text, a shape's own figure and drawn path, position, parent and
// element.
const char* const doc_preset_kept_out =
    "'kind','file','text','shape','path','x','y','z','parent','element'";

// Properties copied only when they are keyed: a pulse is a preset, a fixed size
// is not.
const char* const doc_preset_placed =
    "'size','scale_x','scale_y','rotate','rotate_x','rotate_y','orient'";

// Properties whose values are another layer's number; see kinds.h.
const char* const doc_preset_links =
    "'parent','mosh_with','copy_on','connect','connect_to','boolean_with','"
    "trail','morph_to'";

// Path of the upgraded temporary copy while it is attached. doc_preset_detach
// removes it.
std::string doc_preset_copy;

// Attaches the preset file at `path` as the database `preset`. With `read_only`
// the file is opened as it is and not written. A file in the old schema,
// recognised by its table `fact`, is read through a temporary copy that
// doc_upgrade brings up to date; a new file is created at version 1. Returns
// false and sets d.error on failure.
bool doc_preset_attach(Doc& d, const char* path, bool read_only) {
  std::string at = path, why;
  sqlite3* old = nullptr;
  if (read_only &&
      sqlite3_open_v2(path, &old, SQLITE_OPEN_READONLY, nullptr) == SQLITE_OK &&
      sqlite3_exec(old, "select 1 from fact limit 0", nullptr, nullptr,
                   nullptr) == SQLITE_OK) {
    std::error_code wrong;
    at = doc_preset_copy =
        (std::filesystem::temp_directory_path(wrong) /
         ("motolii_preset_" +
          std::to_string(
              std::chrono::steady_clock::now().time_since_epoch().count()) +
          ".motolii"))
            .string();
    std::filesystem::copy_file(
        path, at, std::filesystem::copy_options::overwrite_existing, wrong);
    read_only = false;
  }
  sqlite3_close(old);
  char* attach =
      read_only ? sqlite3_mprintf("attach database 'file:%q?mode=ro' as preset",
                                  at.c_str())
                : sqlite3_mprintf("attach database %Q as preset", at.c_str());
  const bool ok =
      sqlite3_exec(d.file, attach, nullptr, nullptr, nullptr) == SQLITE_OK;
  sqlite3_free(attach);
  if (!ok) return d.error = sqlite3_errmsg(d.file), false;
  if (!read_only && !doc_upgrade(d.file, "preset", why))
    return sqlite3_exec(d.file, "detach database preset", nullptr, nullptr,
                        nullptr),
           d.error = why, false;
  return true;
}

// Detaches the preset file and deletes the temporary copy, if there is one.
void doc_preset_detach(Doc& d) {
  sqlite3_exec(d.file, "detach database preset", nullptr, nullptr, nullptr);
  std::error_code wrong;
  if (!doc_preset_copy.empty())
    std::filesystem::remove(doc_preset_copy, wrong), doc_preset_copy.clear();
}

// Returns the library's folder and the user's own folder, each with a trailing
// slash, as the words {motolii}/ and {own}/ stand for them, in the order of
// doc_folders. If there is no second folder, the second string is "\x01", which
// matches no path.
std::pair<std::string, std::string> doc_preset_roots() {
  const auto at = doc_folders("looks");
  return {
      at[0].parent_path().string() + "/",
      at.size() > 1 ? at[1].parent_path().string() + "/" : std::string("\x01")};
}

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

bool doc_preset_save(Doc& d, int layer, const char* path, bool whole,
                     const std::string& only) {
  std::error_code wrong;
  std::filesystem::remove(path, wrong);
  bool ok = doc_preset_attach(d, path, false);
  if (!ok) return false;
  const auto roots = doc_preset_roots();
  char* copy = sqlite3_mprintf(
      "create table preset.keyframe(layer integer, name text, at numeric, "
      "value, easing text, primary key(layer, name, at)) without rowid;"
      "create table preset.easing(name text primary key, expression text) "
      "without rowid;"
      "create table preset.layer(id integer primary key autoincrement); insert "
      "into preset.layer(id) values(1);"
      "insert into preset.keyframe select 1, name, at, case typeof(value) when "
      "'text' then replace(replace(value, %Q, '{motolii}/'), %Q, '{own}/') "
      "else value end, easing from main.keyframe as f where layer = %d and "
      "name not in (%s)"
      " and not (name in (%s) and (select count(*) from main.keyframe where "
      "layer = f.layer and name = f.name) = 1)"
      " and (%Q = '' or instr(' ' || %Q || ' ', ' ' || name || ' ') > 0);"
      "insert into preset.easing select * from main.easing where name in "
      "(select easing from preset.keyframe);",
      roots.first.c_str(), roots.second.c_str(), layer,
      whole ? "'parent'" : doc_preset_kept_out,
      whole ? "''" : doc_preset_placed, only.c_str(), only.c_str());
  ok = sqlite3_exec(d.file, copy, nullptr, nullptr, nullptr) == SQLITE_OK;
  sqlite3_free(copy);
  if (!ok) d.error = sqlite3_errmsg(d.file);
  // The behaviours that move the layer (stagger, oscillator, noise, random) are
  // carried with it as layers 2, 3, and so on. A relation, which ties the layer
  // to others, is not carried: its _by links are left out. With `whole`, the
  // layers whose parent is this layer are carried too, as a group holds its
  // children, and so are their behaviours. Every link between carried layers is
  // renumbered to the numbers in the preset. Alight Motion copies a group with
  // what is in it, and AbsentMotion's group is a scene of its own that is
  // copied whole (ElementActions.kt, elementNodes). Maps a layer number in the
  // document to its number in the preset.
  std::map<int, int> here{{layer, 1}};
  // Layers still to visit, starting with the saved layer.
  std::vector<int> walk{layer};
  int next = 2;
  // Copies layer `was` into the preset under the next free number.
  const auto carry = [&](int was) {
    char* one = sqlite3_mprintf(
        "insert into preset.keyframe select %d, name, at, case typeof(value) "
        "when 'text' then replace(replace(value, %Q, '{motolii}/'), %Q, "
        "'{own}/') else value end, easing from main.keyframe where layer = %d;"
        "insert into preset.layer(id) values(%d);",
        next, roots.first.c_str(), roots.second.c_str(), was, next);
    ok =
        ok && sqlite3_exec(d.file, one, nullptr, nullptr, nullptr) == SQLITE_OK;
    sqlite3_free(one);
    here[was] = next++;
  };
  for (size_t i = 0; ok && i < walk.size(); ++i) {
    const int at = here[walk[i]];
    std::vector<int> by, held;
    doc_rows(d,
             sqlite3_mprintf(
                 "select distinct cast(value as integer) from preset.keyframe "
                 "where layer = %d and name like '%%\\_by' escape '\\'",
                 at),
             [&](sqlite3_stmt* q) { by.push_back(sqlite3_column_int(q, 0)); });
    for (const int b : by) {
      const bool carried =
          b && doc_word(d, b, "kind") == "behaviour" &&
          doc_among("stagger oscillator noise random", doc_word(d, b, "file"));
      if (carried && !here.count(b)) carry(b);
      char* gone = carried
                       ? nullptr
                       : sqlite3_mprintf(
                             "delete from preset.keyframe where layer = %d and "
                             "name like '%%\\_by' escape '\\' and value = %d;",
                             at, b);
      ok = ok && (!gone || sqlite3_exec(d.file, gone, nullptr, nullptr,
                                        nullptr) == SQLITE_OK);
      sqlite3_free(gone);
    }
    if (whole)
      doc_rows(
          d,
          sqlite3_mprintf(
              "select distinct layer from main.keyframe where name = 'parent' "
              "and cast(value as integer) = %d and layer != %d order by layer",
              walk[i], walk[i]),
          [&](sqlite3_stmt* q) { held.push_back(sqlite3_column_int(q, 0)); });
    for (const int h : held)
      if (!here.count(h)) carry(h), walk.push_back(h);
  }
  // Renumber each link between carried layers to the number it has in the
  // preset. A link from a child layer to a layer that was not carried is
  // deleted.
  if (ok && here.size() > 1) {
    std::string cases, carried;
    for (const auto& [was, at] : here)
      cases += " when " + std::to_string(was) + " then " + std::to_string(at),
          carried += (carried.empty() ? "" : ",") + std::to_string(was);
    char* told = sqlite3_mprintf(
        "delete from preset.keyframe where layer != 1 and name in (%s) and "
        "cast(value as integer) not in (%s);"
        "update preset.keyframe set value = case cast(value as integer)%s end "
        "where (name like '%%\\_by' escape '\\' or (layer != 1 and name in "
        "(%s))) and cast(value as integer) in (%s);",
        doc_preset_links, carried.c_str(), cases.c_str(), doc_preset_links,
        carried.c_str());
    ok = sqlite3_exec(d.file, told, nullptr, nullptr, nullptr) == SQLITE_OK;
    sqlite3_free(told);
  }
  doc_preset_detach(d);
  return ok;
}

bool doc_preset_put(Doc& d, int layer, const char* path) {
  // SQLite cannot attach a database inside a transaction.
  if (d.act)
    return d.error = "a preset is given by itself, not within another act",
           false;
  const auto roots = doc_preset_roots();
  if (!doc_preset_attach(d, path, true)) return false;
  // SQL that creates a new layer for each behaviour in the preset and points
  // the layer's _by links at it.
  std::string carried;
  sqlite3_stmt* q = nullptr;
  sqlite3_prepare_v2(
      d.file, "select distinct layer from preset.keyframe where layer != 1", -1,
      &q, nullptr);
  while (q && sqlite3_step(q) == SQLITE_ROW) {
    const int k = sqlite3_column_int(q, 0);
    char* one = sqlite3_mprintf(
        "insert into layer default values; insert into keyframe select "
        "last_insert_rowid(), name, at, value, easing from preset.keyframe "
        "where layer = %d;"
        "update keyframe set value = (select max(id) from layer) where layer = "
        "%d and name in (select name from preset.keyframe where layer = 1 and "
        "name like '%%\\_by' escape '\\' and value = %d);",
        k, layer, k);
    carried += one;
    sqlite3_free(one);
  }
  sqlite3_finalize(q);
  const bool ok = doc_change(
      d, sqlite3_mprintf(
             "delete from keyframe where layer = %d and name in (select name "
             "from preset.keyframe where layer = 1) and name not in (%s);"
             "insert or replace into keyframe select %d, name, at, case "
             "typeof(value) when 'text' then replace(replace(value, "
             "'{motolii}/', %Q), '{own}/', %Q) else value end, easing from "
             "preset.keyframe where layer = 1 and name not in (%s);"
             "insert or ignore into easing select * from preset.easing;%s",
             layer, doc_preset_kept_out, layer, roots.first.c_str(),
             roots.second.c_str(), doc_preset_kept_out, carried.c_str()));
  doc_preset_detach(d);
  return ok;
}

int doc_preset_paste(Doc& d, const char* path, double now, const char* also,
                     int into, const char* before) {
  // SQLite cannot attach a database inside a transaction.
  if (d.act)
    return d.error = "a copy is pasted by itself, not within another act", 0;
  const auto roots = doc_preset_roots();
  if (!doc_preset_attach(d, path, true)) return 0;
  double was = 0;
  bool kind = false;
  sqlite3_stmt* q = nullptr;
  sqlite3_prepare_v2(d.file,
                     "select name, value from preset.keyframe where layer = 1 "
                     "and name in ('start', 'kind') and at = 0",
                     -1, &q, nullptr);
  while (q && sqlite3_step(q) == SQLITE_ROW) {
    if (std::string((const char*)sqlite3_column_text(q, 0)) == "start")
      was = sqlite3_column_double(q, 1);
    else
      kind = true;
  }
  sqlite3_finalize(q);
  // SQL that creates one new layer for each layer in the copy and records the
  // old and the new number in pasted_as.
  std::string made_all;
  sqlite3_prepare_v2(
      d.file, "select distinct layer from preset.keyframe order by layer", -1,
      &q, nullptr);
  while (q && sqlite3_step(q) == SQLITE_ROW) {
    const int k = sqlite3_column_int(q, 0);
    char* one =
        into && k == 1
            ? sqlite3_mprintf("insert into pasted_as values(1, %d);", into)
            : sqlite3_mprintf(
                  "insert into layer default values; insert into pasted_as "
                  "values(%d, last_insert_rowid());",
                  k);
    made_all += one;
    sqlite3_free(one);
  }
  sqlite3_finalize(q);
  int made = 0;
  const double by = now - was;
  if (!kind)
    d.error = "that is no copy of a layer";
  else if (
      doc_change(
          d,
          sqlite3_mprintf(
              "create temp table if not exists pasted_as(was integer, id "
              "integer); delete from pasted_as;%s%s"
              "insert into keyframe select p.id, name, case when exists "
              "(select 1 from preset.keyframe as o where o.layer = f.layer and "
              "o.name = f.name and (o.at <> 0 or o.easing is not null)) then "
              "at + %!.17g else at end,"
              " case when name = 'start' then max(0, value + %!.17g) when "
              "typeof(value) = 'text' then replace(replace(value, "
              "'{motolii}/', %Q), '{own}/', %Q) else value end, easing from "
              "preset.keyframe as f join pasted_as as p on p.was = f.layer "
              "where p.id != %d;"
              // A layer without a stored start began at time 0: give it a start
              // so that it begins later by the same amount as the rest.
              "insert into keyframe(layer, name, at, value) select p.id, "
              "'start', 0, max(0, %!.17g) from pasted_as as p where %!.17g > 0 "
              "and p.id != %d"
              " and not exists (select 1 from preset.keyframe where layer = "
              "p.was and name = 'start') and (select value from "
              "preset.keyframe where layer = p.was and name = 'kind' and at = "
              "0) <> 'behaviour';"
              "update keyframe set value = (select id from pasted_as where was "
              "= cast(keyframe.value as integer)) where layer in (select id "
              "from pasted_as) and layer != %d"
              " and (name like '%%\\_by' escape '\\' or (layer != (select id "
              "from pasted_as where was = 1) and name in (%s))) and cast(value "
              "as integer) in (select was from pasted_as);"
              "insert or ignore into easing select * from preset.easing;%s",
              before, made_all.c_str(), by, by, roots.first.c_str(),
              roots.second.c_str(), into, by, by, into, into, doc_preset_links,
              also)))
    doc_rows(d, sqlite3_mprintf("select id from pasted_as where was = 1"),
             [&](sqlite3_stmt* row) { made = sqlite3_column_int(row, 0); });
  doc_preset_detach(d);
  return made;
}

bool doc_preset_keep(Doc& d, int layer, const std::string& name,
                     const std::string& only) {
  if (name.empty() || name.find_first_of("/\\:") != std::string::npos)
    return d.error = "a preset's name is a file's name", false;
  std::error_code wrong;
  const std::filesystem::path dir = doc_folders("looks").back();
  std::filesystem::create_directories(dir, wrong);
  // For an effect's card, append the first number that makes the name unused,
  // so that each save is another preset.
  std::string named = name;
  for (int n = 1;
       !only.empty() && (named.empty() || named == name ||
                         std::filesystem::exists(dir / (named + ".motolii")));
       ++n)
    named = name + " " + std::to_string(n);
  return doc_preset_save(
      d, layer, (dir / (named + ".motolii")).string().c_str(), false, only);
}

int doc_pack(Doc& d, const std::string& folder, const std::string& name) {
  std::error_code wrong;
  std::filesystem::create_directories(folder, wrong);
  const std::filesystem::path to =
      std::filesystem::path(folder) / (name + ".motolii");
  std::filesystem::remove(to, wrong);
  char* copy = sqlite3_mprintf("vacuum into %Q", to.string().c_str());
  const bool copied =
      sqlite3_exec(d.file, copy, nullptr, nullptr, nullptr) == SQLITE_OK;
  sqlite3_free(copy);
  if (!copied) return d.error = sqlite3_errmsg(d.file), -1;
  std::vector<std::string> files;
  doc_rows(d,
           sqlite3_mprintf("select distinct value from keyframe where name = "
                           "'file' and typeof(value) = 'text'"),
           [&](sqlite3_stmt* q) {
             files.push_back((const char*)sqlite3_column_text(q, 0));
           });
  const auto roots = doc_preset_roots();
  sqlite3* pack = nullptr;
  if (sqlite3_open(to.string().c_str(), &pack) != SQLITE_OK)
    return sqlite3_close(pack), d.error = "the package could not be opened", -1;
  int n = 0;
  std::set<std::string> taken;
  for (const std::string& word : files) {
    const std::filesystem::path was = std::filesystem::absolute(word, wrong);
    const std::string whole = was.string();
    // Skip values that are not files, such as the name of a built-in kind, and
    // files in the library's folders: there is nothing to copy.
    if (!std::filesystem::is_regular_file(was, wrong) ||
        whole.rfind(roots.first, 0) == 0 || whole.rfind(roots.second, 0) == 0)
      continue;
    std::string named = was.filename().string();
    // Rename when two files of the same name come from different folders.
    for (int k = 2; taken.count(named); ++k)
      named = was.stem().string() + " " + std::to_string(k) +
              was.extension().string();
    taken.insert(named);
    if (!std::filesystem::copy_file(
            was, std::filesystem::path(folder) / named,
            std::filesystem::copy_options::overwrite_existing, wrong))
      continue;
    char* told = sqlite3_mprintf(
        "update keyframe set value = %Q where name = 'file' and value = %Q",
        named.c_str(), word.c_str());
    sqlite3_exec(pack, told, nullptr, nullptr, nullptr);
    sqlite3_free(told);
    ++n;
  }
  sqlite3_close(pack);
  return n;
}

std::string doc_preset_names() {
  std::string all;
  std::error_code wrong;
  for (const char* kind : {"looks", "elements"})
    for (const auto& f : doc_folder_files(kind, ".motolii")) {
      const std::filesystem::path picture =
          std::filesystem::path(f).replace_extension(".png");
      all += (all.empty() ? "" : "\n") + f.stem().string() + "\t" + f.string() +
             (kind[0] == 'l' ? "\tLook\t" : "\tElement\t") +
             (std::filesystem::exists(picture, wrong) ? picture.string() : "");
    }
  return all;
}

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
