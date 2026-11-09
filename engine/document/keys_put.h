// keys_put.h: part of doc.h (keys put on a value, and a value changed as a hand changes it). Read only through doc.h.
// A value either stays (one keyframe, at 0, with no way: what `set` writes) or is keyed: a key is a key even alone, and
// a value's first key takes the place of the value that stayed (a key at 0 is marked by its way, Linear until told).
static int doc_keys(Doc& d, int layer, const char* name, double at);
static bool doc_key(Doc& d, int layer, const char* name, double at, double is) {
    if (!(at >= 0.0 && at <= 1e6)) return d.error = "a key is at a moment of the stage: from 0 to 1000000 seconds", false;
    if (!doc_knows(d, layer, name, &is, nullptr, true)) return false;
    const bool stayed = !doc_keys(d, layer, name, -1.0) && at != 0.0;   // (the value that stayed goes: the key holds the place now)
    return doc_change(d, sqlite3_mprintf("%z insert into keyframe(layer, name, at, value, easing) values(%d, %Q, %!.17g, %!.17g, %s) on conflict do update set value = excluded.value, easing = coalesce(easing, excluded.easing)",
                                         stayed ? sqlite3_mprintf("delete from keyframe where layer = %d and name = %Q;", layer, name) : sqlite3_mprintf(""), layer, name, at, is, at == 0.0 ? "'Linear'" : "null"), true);
}
// Many keys of one value at once (doc_key's rule, asked once: the value that stayed goes when keys come), one statement
// made ready and said again for each; one act, the stage made again at its end.
static bool doc_key_many(Doc& d, int layer, const char* name, int n, const double* at, const double* is, const char* easing = nullptr) {   // (easing: each key's, as a MIDI file's are Hold)
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
    d.act_unmatched = true;   // (matched once, when the act ends)
    return doc_acted(d) && ok;
}
static int doc_keys(Doc& d, int layer, const char* name, double at = -1.0) {   // (how many keys a value has; or whether it has one at a moment)
    int n = 0;
    doc_rows(d, at < 0.0 ? sqlite3_mprintf("select count(*) from keyframe where layer = %d and name = %Q and " DOC_KEYED, layer, name, layer, name)
                         : sqlite3_mprintf("select count(*) from keyframe where layer = %d and name = %Q and at = %!.17g", layer, name, at), [&](sqlite3_stmt* row) { n = sqlite3_column_int(row, 0); });
    return n;
}
// What a hand does to a value at a moment, as the document's own rules (a shell does not work them out):
// put: the value changed there. Every change is being keyed (d.keying): a key there (After Effects' Auto-keyframe), and
//      if it is the value's first and later than the keying began, what it was stays as a key there (a Jitter
//      animation's bar). Not being keyed: a value with keys gets a key there (as After Effects keys a property that has
//      keyframes, wherever it is changed), a value without is the value that stays.
// key_here: a key at that moment holding what the value is there (nothing, if it has one there).
// raise: brought nearer or further back among the layers.
// stay: its keys are taken away, and it stays what it is at that moment.
// keyed: 0 the value has no keys, 1 it has keys but none at that moment, 2 it has a key at that moment.
// moving: the names of the values of a layer that can take keys.
static double doc_usual(Doc& d, const char* name);
static double doc_usual_on(Doc& d, int layer, const char* name);
static bool doc_set(Doc& d, int layer, const char* name, double is);
static bool doc_put(Doc& d, int layer, const char* name, double at, double is) {   // (After Effects' rule)
    if (!doc_knows(d, layer, name, &is)) return false;
    // (a value with keys, keyed or not, and any changed while every change is keyed at or before the moment that began:
    //  a key there and only there, as After Effects' Auto-keyframe keys a property at the current time and Alight
    //  Motion's diamond keys it at the playhead)
    if (doc_keys(d, layer, name) > 0 || (d.keying && at <= d.keying_from)) return doc_key(d, layer, name, at, is);
    if (!d.keying) return doc_set(d, layer, name, is);
    // (its first change later than the keying began: what it was stays as a key there, so it travels from there to here
    //  in one step, as a Jitter animation goes from the state before it to its end value along its bar (Jitter's Help
    //  Center, Understand operations vs keyframes). A bar runs forward only, so a change before that moment keys there
    //  alone, above: golf (62), a key after it that brought the value back, as the past repository's place_checked did)
    const double was = doc_number(d, layer, name, d.keying_from, doc_usual_on(d, layer, name));
    doc_act(d);
    doc_key(d, layer, name, d.keying_from, was);
    doc_key(d, layer, name, at, is);
    return doc_acted(d);
}
