// The calls about easings: putting one on a keyframe, defining one in the
// project, listing the project's easings and the numbers each kind takes, and
// drawing one.
#include "document/edit/easings_put.h"
#include "document/scripts/recipes.h"
#include "entry/calls.h"
#include "entry/on_render_thread.h"

using namespace motolii;

namespace motolii {

int easing_is(Motolii* m, int layer, const char* name, double at,
              const char* easing) {
  Doc& d = doc(m);
  bool here = false;
  doc_rows(d, sqlite3_mprintf("select 1 from easing where name = %Q", easing),
           [&](sqlite3_stmt*) { here = true; });
  const auto easings = doc_own_easings();
  const auto own = easings.find(easing);
  if (here || own == easings.end())
    return changes(m, (int)(doc_easing(d, layer, name, at, easing)));
  // The user's own easing: write it into the project and put it on the keyframe
  // in one undo step.
  doc_act(d);
  if (!doc_define(d, easing, own->second.c_str()) ||
      !doc_easing(d, layer, name, at, easing))
    d.act.ok = false;
  return changes(m, (int)doc_acted(d));
}

int define_is(Motolii* m, const char* easing, const char* expression) {
  Doc& d = doc(m);
  doc_act(d);
  // Write the user's own easings that the expression asks for through
  // way('name').
  for (const auto& [name, own] : doc_own_easings()) {
    if (!strstr(expression, ("way('" + name).c_str())) continue;
    bool here = false;
    doc_rows(
        d,
        sqlite3_mprintf("select 1 from easing where name = %Q", name.c_str()),
        [&](sqlite3_stmt*) { here = true; });
    if (!here && !doc_define(d, name.c_str(), own.c_str())) d.act.ok = false;
  }
  if (!doc_define(d, easing, expression)) d.act.ok = false;
  // Delete the easings that were composed or reversed, named with × or starting
  // with Reverse:, and that no keyframe uses and no other easing refers to any
  // more. The app makes one at each step of a drag.
  if (d.act.ok &&
      !doc_change(
          d, sqlite3_mprintf(
                 "delete from easing where (name glob '*×*' or name glob "
                 "'Reverse:*') and name <> %Q and name not in (select easing "
                 "from keyframe where easing is not null) and not exists "
                 "(select 1 from easing o where o.name <> easing.name and "
                 "o.expression like '%%''' || easing.name || '%%')",
                 easing)))
    d.act.ok = false;
  return changes(m, (int)doc_acted(d));
}

}  // namespace motolii

// Puts easing `easing` on the keyframe of property `name` at time `at`. Returns
// nonzero on success.
int motolii_easing(Motolii* m, int layer, const char* name, double at,
                   const char* easing) {
  return on_render_thread(
      m, [=] { return easing_is(m, layer, name, at, easing); });
}
// Returns the names of the easings that the project has, as text.
const char* motolii_easings(Motolii* m) {
  return by_look(m, [m] { return (m->listed = doc_easings(*m->d)).c_str(); });
}
// Returns the numbers that easing kind `kind` takes, as the app presents them:
// for each one its name, its lowest and its highest value, such as "seed 1 999
// grain 0 0.5". Returns "" for a kind with none. The kinds are built into the
// engine, so this does not wait for the render thread.
const char* motolii_easing_numbers(Motolii*, const char* kind) {
  static thread_local std::string said;
  said.clear();
  for (const auto& k : interp_kinds) {
    if (strcasecmp(k.name, kind)) continue;
    std::istringstream names(k.names);
    std::string name;
    char one[96];
    for (int j = 0; j < k.numbers && names >> name; ++j)
      std::snprintf(one, sizeof one, "%s%s %.9g %.9g", said.empty() ? "" : " ",
                    name.c_str(), k.lo[j], k.hi[j]),
          said += one;
  }
  return said.c_str();
}
// Returns the names of the easings that can be put on a keyframe, separated by
// spaces: the nine built-in kinds, then the easings defined in the project,
// then the user's own easings that the project does not have yet.
const char* motolii_easing_names(Motolii* m) {
  return by_look(m, [=] {
    said_word().clear();
    for (const auto& kind : interp_kinds)
      said_word() += std::string(said_word().empty() ? "" : " ") + kind.name;
    std::set<std::string> here;
    doc_rows(*m->d, sqlite3_mprintf("select name from easing order by name"),
             [&](sqlite3_stmt* row) {
               here.insert((const char*)sqlite3_column_text(row, 0));
               said_word() +=
                   std::string(" ") + (const char*)sqlite3_column_text(row, 0);
             });
    // Then the user's own easings that this project does not have yet.
    for (const auto& [name, expression] : doc_own_easings())
      if (!here.count(name)) said_word() += " " + name;
    return said_word().c_str();
  });
}
// Returns how far along easing `easing` is at progress `u`, from 0 at its
// beginning to 1 at its end. `easing` is a built-in kind or an easing defined
// in the project or in a file of the user.
double motolii_easing_at(Motolii* m, const char* easing, double u) {
  Interp kind;
  if (interp_said(easing, &kind) == 0) return interp_ease(kind, u);
  return by_look(m, [=] {
    bool here = false;
    doc_rows(*m->d,
             sqlite3_mprintf("select 1 from easing where name = %Q", easing),
             [&](sqlite3_stmt*) { here = true; });
    const auto easings = doc_own_easings();
    const auto own = easings.find(easing);
    // The user's own easing, not yet in this project: evaluate it as its file
    // says. The parameters are all 1.
    if (!here && own != easings.end()) {
      const double p[4] = {1, 1, 1, 1};
      sqlite3_stmt* expression = doc_expression_statement(*m->d, own->second);
      return expression ? doc_went(expression, u, u, 1.0, 0.0, 1.0, p) : u;
    }
    // An easing defined in the project, evaluated as between a keyframe of 0
    // and a keyframe of 1 that are one second apart.
    return doc_went_by(*m->d, easing, u, u, 1.0, 0.0, 1.0);
  });
}
// Returns the easing of the keyframe of property `name` at time `at`.
const char* motolii_easing_of(Motolii* m, int layer, const char* name,
                              double at) {
  return by_look(m, [=] {
    return (said_word() = doc_easing_of(*m->d, layer, name, at)).c_str();
  });
}
