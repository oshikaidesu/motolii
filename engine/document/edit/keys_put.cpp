#include "document/edit/keys_put.h"

#include <sqlite3.h>

#include <algorithm>

#include "document/edit/arrange.h"
#include "document/edit/layer_edit.h"
#include "document/evaluate/value_at.h"
#include "document/undo.h"

namespace motolii {

bool doc_key(Doc& d, int layer, const char* name, double at, double is) {
  if (!(at >= 0.0 && at <= 1e6))
    return d.error =
               "a key is at a moment of the stage: from 0 to 1000000 seconds",
           false;
  if (!doc_knows(d, layer, name, &is, nullptr, true)) return false;
  // The value that stayed is deleted, since the keyframe now holds its place.
  const bool stayed = !doc_keys(d, layer, name, -1.0) && at != 0.0;
  return doc_change(
      d,
      sqlite3_mprintf(
          "%z insert into keyframe(layer, name, at, value, easing) values(%d, "
          "%Q, %!.17g, %!.17g, %s) on conflict do update set value = "
          "excluded.value, easing = coalesce(easing, excluded.easing)",
          stayed ? sqlite3_mprintf(
                       "delete from keyframe where layer = %d and name = %Q;",
                       layer, name)
                 : sqlite3_mprintf(""),
          layer, name, at, is, at == 0.0 ? "'Linear'" : "null"),
      true);
}
bool doc_key_many(Doc& d, int layer, const char* name, int n, const double* at,
                  const double* is, const char* easing) {
  for (int i = 0; i < n; ++i) {
    double v = is[i];
    if (!(at[i] >= 0.0 && at[i] <= 1e6))
      return d.error =
                 "a key is at a moment of the stage: from 0 to 1000000 seconds",
             false;
    if (!doc_knows(d, layer, name, &v, nullptr, true)) return false;
  }
  if (n <= 0) return true;
  doc_act(d);
  const bool stayed =
      !doc_keys(d, layer, name, -1.0) &&
      std::any_of(at, at + n, [](double a) { return a != 0.0; });
  if (stayed)
    doc_change(
        d,
        sqlite3_mprintf("delete from keyframe where layer = %d and name = %Q",
                        layer, name),
        true);
  sqlite3_stmt* put = nullptr;
  bool ok = d.act_ok &&
            sqlite3_prepare_v2(
                d.file,
                "insert into keyframe(layer, name, at, value, easing) "
                "values(?, ?, ?, ?, ?) on conflict do update set value = "
                "excluded.value, easing = coalesce(easing, excluded.easing)",
                -1, &put, nullptr) == SQLITE_OK;
  for (int i = 0; ok && i < n; ++i) {
    sqlite3_reset(put);
    sqlite3_bind_int(put, 1, layer),
        sqlite3_bind_text(put, 2, name, -1, SQLITE_STATIC),
        sqlite3_bind_double(put, 3, at[i]), sqlite3_bind_double(put, 4, is[i]);
    if (easing)
      sqlite3_bind_text(put, 5, easing, -1, SQLITE_STATIC);
    else if (at[i] == 0.0)
      sqlite3_bind_text(put, 5, "Linear", -1, SQLITE_STATIC);
    else
      sqlite3_bind_null(put, 5);
    ok = sqlite3_step(put) == SQLITE_DONE;
  }
  if (!ok) d.error = sqlite3_errmsg(d.file), d.act_ok = false;
  sqlite3_finalize(put);
  // The stage is rebuilt once, when the act ends.
  d.act_unmatched = true;
  return doc_acted(d) && ok;
}
int doc_keys(Doc& d, int layer, const char* name, double at) {
  int n = 0;
  doc_rows(d,
           at < 0.0
               ? sqlite3_mprintf("select count(*) from keyframe where layer = "
                                 "%d and name = %Q and " DOC_KEYED,
                                 layer, name, layer, name)
               : sqlite3_mprintf("select count(*) from keyframe where layer = "
                                 "%d and name = %Q and at = %!.17g",
                                 layer, name, at),
           [&](sqlite3_stmt* row) { n = sqlite3_column_int(row, 0); });
  return n;
}
bool doc_put(Doc& d, int layer, const char* name, double at, double is) {
  if (!doc_knows(d, layer, name, &is)) return false;
  // A property with keyframes gets a keyframe there and only there. So does any
  // property changed while every change is keyed, at or before the time keying
  // began. After Effects' Auto-keyframe keys a property at the current time,
  // and so does the diamond of Alight Motion at the playhead.
  if (doc_keys(d, layer, name) > 0 || (d.keying && at <= d.keying_from))
    return doc_key(d, layer, name, at, is);
  if (!d.keying) return doc_set(d, layer, name, is);
  // This is the first change after keying began and it is later than the start.
  // The old value stays as a keyframe at the start, so that the property goes
  // from there to here in one step. Jitter does the same: an animation goes
  // from the state before it to its end value along its bar; see the Jitter
  // Help Center, "Understand operations vs keyframes". A bar runs forward only,
  // so a change earlier than the start was handled above and keys only itself.
  const double was =
      doc_number(d, layer, name, d.keying_from, doc_usual_on(d, layer, name));
  doc_act(d);
  doc_key(d, layer, name, d.keying_from, was);
  doc_key(d, layer, name, at, is);
  return doc_acted(d);
}

}  // namespace motolii
