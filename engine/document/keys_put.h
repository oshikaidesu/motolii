// Keyframes on a property, and changing a property the way a user edit does. Included by doc.h;
// not self-contained.
//
// A property either stays or is keyed. A property that stays has one row at time 0 with no
// easing, which is what `set` writes. A keyed property has keyframes. A keyframe is a keyframe
// even when it is the only one. The first keyframe of a property takes the place of the value
// that stayed. A keyframe at time 0 is marked by its easing, which is Linear until the user
// changes it.
static int doc_keys(Doc& d, int layer, const char* name, double at);
// Sets a keyframe of a property at time `at` to the value `is`. Returns false and sets d.error if
// `at` is out of range or the property rejects the value.
static bool doc_key(Doc& d, int layer, const char* name, double at, double is) {
    if (!(at >= 0.0 && at <= 1e6)) return d.error = "a key is at a moment of the stage: from 0 to 1000000 seconds", false;
    if (!doc_knows(d, layer, name, &is, nullptr, true)) return false;
    // The value that stayed is deleted, since the keyframe now holds its place.
    const bool stayed = !doc_keys(d, layer, name, -1.0) && at != 0.0;
    return doc_change(d, sqlite3_mprintf("%z insert into keyframe(layer, name, at, value, easing) values(%d, %Q, %!.17g, %!.17g, %s) on conflict do update set value = excluded.value, easing = coalesce(easing, excluded.easing)",
                                         stayed ? sqlite3_mprintf("delete from keyframe where layer = %d and name = %Q;", layer, name) : sqlite3_mprintf(""), layer, name, at, is, at == 0.0 ? "'Linear'" : "null"), true);
}
// Sets many keyframes of one property at once: n keyframes at times at[i] with values is[i]. The
// rule is the one of doc_key, applied once for all keyframes, so the value that stayed is deleted
// when keyframes arrive. One prepared statement is reused for every keyframe. The whole call is
// one act, and the stage is rebuilt once at its end.
//
// `easing`, when not null, is the easing of every keyframe. A MIDI import uses Hold.
static bool doc_key_many(Doc& d, int layer, const char* name, int n, const double* at, const double* is, const char* easing = nullptr) {
    for (int i = 0; i < n; ++i) {
        double v = is[i];
        if (!(at[i] >= 0.0 && at[i] <= 1e6)) return d.error = "a key is at a moment of the stage: from 0 to 1000000 seconds", false;
        if (!doc_knows(d, layer, name, &v, nullptr, true)) return false;
    }
    if (n <= 0) return true;
    doc_act(d);
    const bool stayed = !doc_keys(d, layer, name, -1.0) && std::any_of(at, at + n, [](double a) { return a != 0.0; });
    if (stayed) doc_change(d, sqlite3_mprintf("delete from keyframe where layer = %d and name = %Q", layer, name), true);
    sqlite3_stmt* put = nullptr;
    bool ok = d.act_ok && sqlite3_prepare_v2(d.file, "insert into keyframe(layer, name, at, value, easing) values(?, ?, ?, ?, ?) on conflict do update set value = excluded.value, easing = coalesce(easing, excluded.easing)", -1, &put, nullptr) == SQLITE_OK;
    for (int i = 0; ok && i < n; ++i) {
        sqlite3_reset(put);
        sqlite3_bind_int(put, 1, layer), sqlite3_bind_text(put, 2, name, -1, SQLITE_STATIC), sqlite3_bind_double(put, 3, at[i]), sqlite3_bind_double(put, 4, is[i]);
        if (easing) sqlite3_bind_text(put, 5, easing, -1, SQLITE_STATIC);
        else if (at[i] == 0.0) sqlite3_bind_text(put, 5, "Linear", -1, SQLITE_STATIC);
        else sqlite3_bind_null(put, 5);
        ok = sqlite3_step(put) == SQLITE_DONE;
    }
    if (!ok) d.error = sqlite3_errmsg(d.file), d.act_ok = false;
    sqlite3_finalize(put);
    // The stage is rebuilt once, when the act ends.
    d.act_unmatched = true;
    return doc_acted(d) && ok;
}
// Returns the number of keyframes of a property. With `at` of 0 or more, returns instead whether
// the property has a keyframe at exactly that time, as 1 or 0.
static int doc_keys(Doc& d, int layer, const char* name, double at = -1.0) {
    int n = 0;
    doc_rows(d, at < 0.0 ? sqlite3_mprintf("select count(*) from keyframe where layer = %d and name = %Q and " DOC_KEYED, layer, name, layer, name)
                         : sqlite3_mprintf("select count(*) from keyframe where layer = %d and name = %Q and at = %!.17g", layer, name, at), [&](sqlite3_stmt* row) { n = sqlite3_column_int(row, 0); });
    return n;
}
// The operations the app calls to change a property at a time, following the document's own
// rules so that the app does not work them out.
//   put      Change the value there. If every change is being keyed, d.keying, add a keyframe
//            there, as the Auto-keyframe mode of After Effects does. If it is the property's
//            first keyframe and later than the time when keying began, the old value is also
//            kept as a keyframe at that earlier time, as in a Jitter animation's bar. If changes
//            are not being keyed, a property that has keyframes gets a keyframe there, as After
//            Effects does for any property with keyframes wherever it is changed. A property
//            without keyframes stays a single value.
//   key_here Add a keyframe at that time holding the value the property has there. Does nothing
//            if it already has one there.
//   raise    Bring a layer nearer or further back among the layers.
//   stay     Remove the property's keyframes. It stays at the value it has at that time.
//   keyed    0 if the property has no keyframes, 1 if it has keyframes but none at that time,
//            2 if it has a keyframe at that time.
//   moving   The names of the properties of a layer that can take keyframes.
static double doc_usual(Doc& d, const char* name);
static double doc_usual_on(Doc& d, int layer, const char* name);
static bool doc_set(Doc& d, int layer, const char* name, double is);
// Changes a property to `is` at time `at`, following the rules of After Effects. See the list
// above. Returns false when the property rejects the value.
static bool doc_put(Doc& d, int layer, const char* name, double at, double is) {
    if (!doc_knows(d, layer, name, &is)) return false;
    // A property with keyframes gets a keyframe there and only there. So does any property
    // changed while every change is keyed, at or before the time keying began. After Effects'
    // Auto-keyframe keys a property at the current time, and so does the diamond of Alight
    // Motion at the playhead.
    if (doc_keys(d, layer, name) > 0 || (d.keying && at <= d.keying_from)) return doc_key(d, layer, name, at, is);
    if (!d.keying) return doc_set(d, layer, name, is);
    // This is the first change after keying began and it is later than the start. The old value
    // stays as a keyframe at the start, so that the property goes from there to here in one
    // step. Jitter does the same: an animation goes from the state before it to its end value
    // along its bar; see the Jitter Help Center, "Understand operations vs keyframes". A bar runs
    // forward only, so a change earlier than the start was handled above and keys only itself.
    const double was = doc_number(d, layer, name, d.keying_from, doc_usual_on(d, layer, name));
    doc_act(d);
    doc_key(d, layer, name, d.keying_from, was);
    doc_key(d, layer, name, at, is);
    return doc_acted(d);
}
