#include "document/undo.h"

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <vector>

#include "community/quickjs/script.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/value_at.h"
#include "document/match.h"
#include "document/scripts/recipes.h"
#include "motion/easing_curves.h"
#include "shelf/shelf_folders.h"

namespace motolii {

namespace {

// Records what an undo step changed, so that the app can be told. Each property
// (layer, name) that the changeset touches goes in d.changed, and each touched
// layer goes in d.touched. d.layers_changed is set when a layer came or went,
// that is when its kind was written or removed. The changeset is SQLite's own
// record of the step, so no change is missed.
void doc_note(Doc& d, int size, void* changeset) {
  sqlite3_changeset_iter* it = nullptr;
  if (sqlite3changeset_start(&it, size, changeset) != SQLITE_OK) return;
  int last = -1;
  while (sqlite3changeset_next(it) == SQLITE_ROW) {
    const char* table = nullptr;
    int columns = 0, op = 0, indirect = 0;
    sqlite3changeset_op(it, &table, &columns, &op, &indirect);
    // A change to any table other than keyframe sets layers_changed. A change
    // to the easing table can alter any layer, so -1 is recorded, which means
    // every layer.
    if (!table || strcmp(table, "keyframe")) {
      d.layers_changed = true;
      if (table && !strcmp(table, "easing")) d.touched.push_back(-1);
      continue;
    }
    // Columns 0 and 1 of a keyframe row are the layer and the name. An insert
    // has them in the new row and any other change in the old row.
    sqlite3_value *layer = nullptr, *name = nullptr;
    (op == SQLITE_INSERT ? sqlite3changeset_new : sqlite3changeset_old)(it, 0,
                                                                        &layer);
    (op == SQLITE_INSERT ? sqlite3changeset_new : sqlite3changeset_old)(it, 1,
                                                                        &name);
    if (!layer || !name) continue;
    const std::string n = (const char*)sqlite3_value_text(name);
    d.changed.insert({sqlite3_value_int(layer), n});
    if (sqlite3_value_int(layer) != last)
      d.touched.push_back(last = sqlite3_value_int(layer));
    // A kind written or removed means that a layer came or went.
    if (n == "kind" && op != SQLITE_UPDATE) d.layers_changed = true;
  }
  sqlite3changeset_finalize(it);
}

}  // namespace

bool doc_upgrade(sqlite3* file, const std::string& schema, std::string& why) {
  // Runs `sql` and returns the first integer of the first row, or -1 if it
  // fails or has no row.
  const auto count = [&](const std::string& sql) {
    int n = -1;
    sqlite3_stmt* q = nullptr;
    if (sqlite3_prepare_v2(file, sql.c_str(), -1, &q, nullptr) == SQLITE_OK &&
        sqlite3_step(q) == SQLITE_ROW)
      n = sqlite3_column_int(q, 0);
    sqlite3_finalize(q);
    return n;
  };
  const int version = count("pragma " + schema + ".user_version");
  if (version > 1)
    return why = "the document was made by a newer Motolii (version " +
                 std::to_string(version) + ")",
           false;
  if (version == 1) return true;
  // True if `table` exists in the schema.
  const auto has = [&](const char* table) {
    return count("select count(*) from " + schema +
                 ".sqlite_master where type = 'table' and name = '" + table +
                 "'") > 0;
  };
  const std::string at = schema + ".";
  std::string sql = "begin;";
  // Only a file that still has the old tables needs renaming.
  if (has("fact")) {
    // Create the tables if they are missing so that the renames below cannot
    // fail.
    sql += "create table if not exists " + at +
           "thing(id integer primary key autoincrement);"
           "create table if not exists " +
           at + "way(name text primary key, goes text) without rowid;";
    // The oldest files have no easing column. Add it before renaming.
    if (count("select count(*) from pragma_table_info('fact', '" + schema +
              "') where name = 'way'") == 0)
      sql += "alter table " + at + "fact add column way text;";
    // Rename tables and columns to their current names, then rewrite the kind
    // values 'film' to 'video' and 'picture' to 'image'.
    sql +=
        "alter table " + at +
        "thing rename to layer;"
        "alter table " +
        at +
        "fact rename to keyframe;"
        "alter table " +
        at +
        "keyframe rename column thing to layer;"
        "alter table " +
        at +
        "keyframe rename column way to easing;"
        "alter table " +
        at +
        "way rename to easing;"
        "alter table " +
        at +
        "easing rename column goes to expression;"
        "update " +
        at +
        "keyframe set value = 'video' where name = 'kind' and value = 'film';"
        "update " +
        at +
        "keyframe set value = 'image' where name = 'kind' and value = "
        "'picture';";
    // Clear the changesets of old undo steps, for the reason given above this
    // function.
    if (has("step"))
      sql += "alter table " + at + "step rename to undo_step; update " + at +
             "undo_step set change = null;";
  }
  sql += "pragma " + at + "user_version = 1; commit;";
  if (sqlite3_exec(file, sql.c_str(), nullptr, nullptr, nullptr) == SQLITE_OK)
    return true;
  why = std::string("the document could not be brought up to date: ") +
        sqlite3_errmsg(file);
  sqlite3_exec(file, "rollback", nullptr, nullptr, nullptr);
  return false;
}
Doc* doc_open(Stage& s, const char* path) {
  Doc* d = new Doc;
  if (sqlite3_open(path, &d->file) != SQLITE_OK) return nullptr;
  // SQL function bezier(u, x1, y1, x2, y2): how far a cubic Bezier easing with
  // handles (x1, y1) and (x2, y2) has gone at u. It is the same function the
  // built-in Bezier easing uses, and an easing defined in the project can call
  // it.
  sqlite3_create_function(
      d->file, "bezier", 5, SQLITE_UTF8 | SQLITE_DETERMINISTIC, nullptr,
      [](sqlite3_context* c, int, sqlite3_value** v) {
        sqlite3_result_double(
            c, interp_bezier(interp_clamp(sqlite3_value_double(v[1]), 0.0, 1.0),
                             sqlite3_value_double(v[2]),
                             interp_clamp(sqlite3_value_double(v[3]), 0.0, 1.0),
                             sqlite3_value_double(v[4]),
                             sqlite3_value_double(v[0])));
      },
      nullptr, nullptr);
  // SQL function anime(text, u): how far an anime.js easing has gone at u,
  // written as anime.js writes it, for example anime('outElastic(1, .3)', u).
  // Implemented in script.h. An invalid easing raises an SQL error.
  sqlite3_create_function(
      d->file, "anime", 2, SQLITE_UTF8 | SQLITE_DETERMINISTIC, nullptr,
      [](sqlite3_context* c, int, sqlite3_value** v) {
        static const std::string bundle =
            (doc_engine("third_party/anime") / "anime.umd.min.js").string();
        std::string error;
        const double went =
            anime_ease(bundle, (const char*)sqlite3_value_text(v[0]),
                       sqlite3_value_double(v[1]), &error);
        if (error.empty())
          sqlite3_result_double(c, went);
        else
          sqlite3_result_error(c, error.c_str(), -1);
      },
      nullptr, nullptr);
  // SQL functions easing(text, u) and way(text, u): how far the easing named by
  // `text` has gone at u, for example easing('Cyclic', u) or easing('Bezier .2
  // 0 0 1', u). Easings can therefore be layered over one another: one through
  // another, multiplied or added, as GSAP's CustomWiggle does with timingEase
  // and amplitudeEase and as Blender's F-Curve modifier stack and Noise do.
  // Each easing begins at its first keyframe and ends at the next, so what they
  // make does too. `way` is the old name of `easing`. It stays registered
  // because projects and shelves/ease/*.way written before the rename call it
  // (rename_words.md section 3).
  static void (*const ease_by)(sqlite3_context*, int, sqlite3_value**) =
      [](sqlite3_context* c, int, sqlite3_value** v) {
        const char* text = (const char*)sqlite3_value_text(v[0]);
        const std::string said = text ? text : "";
        const double u = sqlite3_value_double(v[1]);
        Interp kind;
        // Outside the open interval (0, 1) the value is returned as it is, so
        // an overshoot beyond the ends stays an overshoot.
        sqlite3_result_double(c, u <= 0.0 || u >= 1.0 ? u
                                 : interp_said(said, &kind) == 0
                                     ? interp_ease(kind, u)
                                     : doc_went_by(*(Doc*)sqlite3_user_data(c),
                                                   said, u, u, 1.0, 0.0, 1.0));
      };
  for (const char* name : {"easing", "way"})
    sqlite3_create_function(d->file, name, 2,
                            SQLITE_UTF8 | SQLITE_DETERMINISTIC, d, ease_by,
                            nullptr, nullptr);
  // Wait up to 2 seconds if another program has the project file locked.
  sqlite3_busy_timeout(d->file, 2000);
  if (std::string why; !doc_upgrade(d->file, "main", why))
    return std::fprintf(stderr, "%s: %s\n", path, why.c_str()), nullptr;
  // In the keyframe table, `easing` is the easing used from that keyframe to
  // the next. The easing table holds the easings defined in this project. The
  // layer table only hands out layer numbers. Because it is autoincrement, a
  // number is never given again. The last statement fills it from the highest
  // layer number in a file that has none. The setting table holds the app's
  // choices for this project. They are not undo steps (see doc_setting).
  if (sqlite3_exec(
          d->file,
          "create table if not exists keyframe(layer integer, name text, at "
          "numeric, value, easing text, primary key(layer, name, at)) without "
          "rowid;"
          "create table if not exists easing(name text primary key, expression "
          "text) without rowid;"
          "create table if not exists undo_step(n integer primary key, change "
          "blob, undone integer default 0);"
          "create table if not exists layer(id integer primary key "
          "autoincrement);"
          "create table if not exists setting(name text primary key, value "
          "text) without rowid;"
          "insert into layer(id) select max(layer) from keyframe where (select "
          "count(*) from layer) = 0 having max(layer) is not null",
          nullptr, nullptr, nullptr) != SQLITE_OK)
    return nullptr;
  // Files from before easings existed have no easing column.
  if (sqlite3_exec(d->file, "select easing from keyframe limit 0", nullptr,
                   nullptr, nullptr) != SQLITE_OK)
    sqlite3_exec(d->file, "alter table keyframe add column easing text",
                 nullptr, nullptr, nullptr);
  // Files from before undo steps recorded their time have no `made` column.
  if (sqlite3_exec(d->file, "select made from undo_step limit 0", nullptr,
                   nullptr, nullptr) != SQLITE_OK)
    sqlite3_exec(d->file, "alter table undo_step add column made real", nullptr,
                 nullptr, nullptr);
  // Files from before `at` became numeric have it as REAL. With a REAL time,
  // SQLite's session extension records a keyframe that is inserted and then
  // changed in one undo step as two changes if its time is a whole number, and
  // such a step cannot be undone. Rebuild the table once with a numeric column.
  bool real = false;
  doc_rows(*d,
           sqlite3_mprintf("select 1 from pragma_table_info('keyframe') where "
                           "name = 'at' and type = 'REAL'"),
           [&](sqlite3_stmt*) { real = true; });
  if (real)
    sqlite3_exec(d->file,
                 "begin; create table keyframe_numeric(layer integer, name "
                 "text, at numeric, value, easing text, primary key(layer, "
                 "name, at)) without rowid;"
                 "insert into keyframe_numeric select layer, name, at, value, "
                 "easing from keyframe; drop table keyframe; alter table "
                 "keyframe_numeric rename to keyframe; commit",
                 nullptr, nullptr, nullptr);
  // Files from before the copy and scatter properties were taken out, when the
  // Repeater recipe started to provide them. A layer that has any of the old
  // properties and no script of its own is given the Repeater script, and its
  // properties are renamed to the Repeater's js_ names with their keyframes and
  // easings kept. The `<name>_by` properties that used to drive them are
  // deleted because nothing drives those names now.
  // A layer that had no copy_x gets js_StepX = 0, because the recipe's own
  // default is 0.3. The old `seed` becomes js_Seed for a layer with scatter
  // properties. A layer with another script keeps its old rows, which nothing
  // reads.
  if (const std::string repeater = doc_recipe_code_path("Repeater");
      !repeater.empty()) {
    // Pairs of an old property name and the Repeater parameter that replaces
    // it.
    static const char* const moved[][2] = {
        {"copy_x", "js_StepX"},
        {"copy_y", "js_StepY"},
        {"copy_z", "js_StepZ"},
        {"copy_columns", "js_Columns"},
        {"copy_turn", "js_Turn"},
        {"copy_rotate", "js_Rotate"},
        {"copy_rotate_x", "js_RotateX"},
        {"copy_rotate_y", "js_RotateY"},
        {"copy_size", "js_Size"},
        {"copy_wide", "js_Wide"},
        {"scatter_x", "js_ScatterX"},
        {"scatter_y", "js_ScatterY"},
        {"scatter_z", "js_ScatterZ"},
        {"scatter_rotate", "js_ScatterRotate"},
        {"scatter_size", "js_ScatterSize"},
        {"drift_x", "js_DriftX"},
        {"drift_y", "js_DriftY"}};
    std::string names, by, rename;
    // Build the SQL lists: the old names, their `_by` names, and the CASE
    // branches that rename them.
    for (const auto& m : moved) {
      names += std::string(names.empty() ? "" : ",") + "'" + m[0] + "'",
          by += std::string(by.empty() ? "" : ",") + "'" + m[0] + "_by'";
      rename += std::string(" when '") + m[0] + "' then '" + m[1] + "'";
    }
    char* sql = sqlite3_mprintf(
        "begin;"
        "create temp table if not exists old_layers(layer integer primary "
        "key); delete from old_layers;"
        "insert into old_layers select distinct layer from keyframe where name "
        "in (%s) and layer not in (select layer from keyframe where name = "
        "'script' and value not in ('', 'none'));"
        "insert or ignore into keyframe(layer, name, at, value) select "
        "f.layer, 'js_Seed', 0.0, s.value from (select distinct layer from "
        "keyframe where name in ('scatter_x', 'scatter_y', 'scatter_z', "
        "'scatter_rotate', 'scatter_size') and layer in (select layer from "
        "old_layers)) f join keyframe s on s.layer = f.layer and s.name = "
        "'seed' and s.at = 0;"
        "insert or ignore into keyframe(layer, name, at, value) select layer, "
        "'js_StepX', 0.0, 0.0 from old_layers where layer not in (select layer "
        "from keyframe where name = 'copy_x');"
        "update keyframe set name = case name%s end where layer in (select "
        "layer from old_layers) and name in (%s);"
        "delete from keyframe where name in (%s);"
        "delete from keyframe where layer in (select layer from old_layers) "
        "and name = 'script';"
        "insert into keyframe(layer, name, at, value) select layer, 'script', "
        "0.0, %Q from old_layers;"
        "drop table old_things; commit;",
        names.c_str(), rename.c_str(), names.c_str(), by.c_str(),
        repeater.c_str());
    if (sqlite3_exec(d->file, sql, nullptr, nullptr, nullptr) != SQLITE_OK)
      sqlite3_exec(d->file, "rollback", nullptr, nullptr, nullptr);
    sqlite3_free(sql);
  }
  d->stage = &s;
  // Evaluate the project on every frame while it plays.
  s.playing[d] = [d](double now) { doc_evaluate(*d, now); };
  // Build the stage from the project. A failure is printed but the project
  // opens.
  if (!doc_match(*d)) std::printf("%s\n", d->error.c_str());
  return d;
}

void doc_act(Doc& d) {
  if (d.act++) return;
  sqlite3_exec(d.file, "begin", nullptr, nullptr, nullptr);
  sqlite3session_create(d.file, "main", &d.acting);
  sqlite3session_attach(d.acting, "keyframe");
  sqlite3session_attach(d.acting, "easing");
  d.act_ok = true;
}
bool doc_acted(Doc& d) {
  // Show the changes that were put off on the stage once, all together. If the
  // stage cannot show them, none of them is made.
  if (d.act == 1 && d.act_unmatched) {
    d.act_unmatched = false;
    doc_forget(d);
    if (d.act_ok && !doc_match(d)) d.act_ok = false;
  }
  if (--d.act) return d.act_ok;
  int size = 0;
  void* changed = nullptr;
  sqlite3session_changeset(d.acting, &size, &changed);
  sqlite3session_delete(d.acting);
  d.acting = nullptr;
  // Record the touched properties even for a step that is given up, because the
  // stage showed them changed and must now show them as they were.
  if (size) doc_note(d, size, changed);
  // A new step discards the steps that were undone and not redone, so history
  // stays a single line.
  if (d.act_ok && size) {
    sqlite3_exec(d.file, "delete from undo_step where undone", nullptr, nullptr,
                 nullptr);
    sqlite3_stmt* keep = nullptr;
    // Store the step with the time it was made, in seconds since 1970.
    // doc_edited reads it.
    sqlite3_prepare_v2(d.file,
                       "insert into undo_step(change, made) values(?, "
                       "(julianday('now') - 2440587.5) * 86400.0)",
                       -1, &keep, nullptr);
    sqlite3_bind_blob(keep, 1, changed, size, SQLITE_TRANSIENT);
    sqlite3_step(keep);
    sqlite3_finalize(keep);
  }
  sqlite3_free(changed);
  sqlite3_exec(d.file, d.act_ok ? "commit" : "rollback", nullptr, nullptr,
               nullptr);
  // After a rollback, rebuild the stage from the restored project and keep the
  // error.
  if (!d.act_ok) {
    doc_forget(d);
    const std::string why = d.error;
    doc_match(d);
    d.error = why;
  }
  return d.act_ok;
}
bool doc_change(Doc& d, char* change, bool later) {
  doc_act(d);
  // If an earlier change in this step was refused, d.error still says why.
  bool ok = d.act_ok;
  // The project cannot be changed while it is being exported.
  if (ok && d.writing)
    ok = false, d.error =
                    "the document is being written as a film: it is not "
                    "changed until that is done";
  if (ok && !(ok = sqlite3_exec(d.file, change, nullptr, nullptr, nullptr) ==
                   SQLITE_OK))
    d.error = sqlite3_errmsg(d.file);
  sqlite3_free(change);
  // Within a larger step, rebuild the stage once when the step ends instead of
  // after each change if `later` is set, as for one key of a thousand, or if
  // the step was started by motolii_together.
  if (ok && (later || d.act_together) && d.act > 1)
    d.act_unmatched = true;
  else if (ok) {
    doc_forget(d);
    ok = doc_match(d);
  }
  if (!ok) d.act_ok = false;
  return doc_acted(d) && ok;
}

double doc_edited(Doc& d) {
  double all = 0.0, was = -1.0;
  doc_rows(d,
           sqlite3_mprintf(
               "select made from undo_step where made is not null order by n"),
           [&](sqlite3_stmt* row) {
             const double at = sqlite3_column_double(row, 0);
             if (was >= 0.0 && at > was && at - was < 900.0) all += at - was;
             was = at;
           });
  return all;
}
bool doc_undo_step(Doc& d, bool back) {
  int n = 0;
  std::vector<uint8_t> change;
  doc_rows(
      d,
      sqlite3_mprintf(back ? "select n, change from undo_step where not undone "
                             "and change is not null order by n desc limit 1"
                           : "select n, change from undo_step where undone "
                             "order by n limit 1"),
      [&](sqlite3_stmt* row) {
        n = sqlite3_column_int(row, 0);
        change.assign((const uint8_t*)sqlite3_column_blob(row, 1),
                      (const uint8_t*)sqlite3_column_blob(row, 1) +
                          sqlite3_column_bytes(row, 1));
      });
  // Steps whose changeset doc_upgrade cleared are skipped by the query, so undo
  // stops at the upgrade.
  if (!n)
    return d.error = back ? "nothing to undo" : "nothing to do again", false;
  int size = (int)change.size();
  void* apply = change.data();
  // Undo applies the inverse of the changeset. Redo applies it as stored.
  if (back)
    sqlite3changeset_invert((int)change.size(), change.data(), &size, &apply);
  // Any conflict aborts the whole apply.
  const bool ok = sqlite3changeset_apply(
                      d.file, size, apply, nullptr,
                      [](void*, int, sqlite3_changeset_iter*) {
                        return (int)SQLITE_CHANGESET_ABORT;
                      },
                      nullptr) == SQLITE_OK;
  if (ok) doc_note(d, size, apply);
  if (back) sqlite3_free(apply);
  if (!ok)
    return d.error = "the step does not fit the document as it is", false;
  doc_rows(d, sqlite3_mprintf("update undo_step set undone = %d where n = %d",
                              back ? 1 : 0, n));
  doc_forget(d);
  return doc_match(d);
}
std::string doc_easing_of(Doc& d, int layer, const char* name, double at) {
  std::string said;
  doc_rows(
      d,
      sqlite3_mprintf("select coalesce(easing, 'Linear') from keyframe where "
                      "layer = %d and name = %Q and at = %!.17g and " DOC_KEYED,
                      layer, name, at, layer, name),
      [&](sqlite3_stmt* row) {
        said = (const char*)sqlite3_column_text(row, 0);
      });
  Interp kind;
  return !said.empty() && interp_said(said, &kind) == 0 ? interp_words(kind)
                                                        : said;
}

}  // namespace motolii
