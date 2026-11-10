// easings_put.h: removing a keyframe and setting the easing from a keyframe to the next.
// Included by doc.h; not self-contained.

// Removes the keyframe of a property at time "at". If it was the last keyframe, the property
// keeps the value that keyframe held. Returns false and sets d.error on failure.
static bool doc_unkey(Doc& d, int layer, const char* name, double at) {
    if (!doc_knows(d, layer, name)) return false;
    if (!doc_keys(d, layer, name) || !doc_keys(d, layer, name, at)) return d.error = std::string(name) + " has no key at that moment", false;
    // Last keyframe: the property stays at the value the keyframe held.
    if (doc_keys(d, layer, name) == 1) return doc_set(d, layer, name, doc_number(d, layer, name, at, 0));
    return doc_change(d, sqlite3_mprintf("delete from keyframe where layer = %d and name = %Q and at = %!.17g", layer, name, at));
}
// Returns the text listing every easing the user may name: the nine built-in kinds with the
// names of their numbers, the named easings, and the easings defined in this document.
static std::string doc_easings(Doc& d) {
    std::string all;
    for (const auto& kind : interp_kinds) all += std::string(all.empty() ? "" : ", ") + kind.name + (kind.numbers ? std::string(" (") + kind.names + ")" : "");
    all += "; by name:";
    for (const auto& one : named_ways) all += std::string(" ") + one.name;
    doc_rows(d, sqlite3_mprintf("select name from easing order by name"), [&](sqlite3_stmt* row) { all += std::string("; defined here: ") + (const char*)sqlite3_column_text(row, 0); });
    return all;
}
// Sets the easing of the segment that starts at the keyframe at time "at". "easing" is one of
// the nine built-in kinds, alone or with all its numbers such as "Random 3 0.25 0.5 0.8 0.5",
// or the name of an easing defined in this document with up to four numbers. Returns false and
// sets d.error if the keyframe does not exist or the easing is not valid.
static bool doc_easing(Doc& d, int layer, const char* name, double at, const char* easing) {
    if (!doc_knows(d, layer, name, nullptr, nullptr, true)) return false;
    if (!doc_keys(d, layer, name, at)) return d.error = std::string(name) + " has no key at that moment: a stretch begins at a key", false;
    Interp kind;
    std::istringstream said(easing);
    std::string named, more;
    double p = 0;
    int numbers = 0;
    const int of_the_nine = interp_said(easing, &kind, &d.error);
    if (of_the_nine == 1) return false;
    said >> named;
    while (said >> p) ++numbers;
    said.clear();
    if (of_the_nine < 0 && !doc_easing_named(d, named)) return d.error = "an easing is one of: " + doc_easings(d), false;
    if (of_the_nine < 0 && (said >> more || numbers > 4)) return d.error = "an easing defined here is its name and up to four numbers", false;
    return doc_change(d, sqlite3_mprintf("update keyframe set easing = %Q where layer = %d and name = %Q and at = %!.17g", easing, layer, name, at));
}
// Defines or replaces the easing "name" as an SQLite expression. The name must not be one of
// the nine built-in kinds. The expression is tried on two segments and is accepted only if it
// starts at the first keyframe's value and ends at the second's. Returns false and sets
// d.error otherwise.
static bool doc_define(Doc& d, const char* name, const char* expression) {
    Interp kind;
    if (interp_said(name, &kind) >= 0) return d.error = std::string(name) + " is one of the nine kinds already", false;
    sqlite3_stmt* statement = doc_expression_statement(d, expression);
    if (!statement) return false;
    const double p[4] = {1, 1, 1, 1}, tried[2][3] = {{0, 1, 1}, {2, -5, 3}};
    // Each trial is {a, b, seconds}: a segment from value a to value b lasting that long.
    for (const auto& s : tried) {
        const double from = doc_went(statement, 0, 0, s[2], s[0], s[1], p), to = doc_went(statement, 1, s[2], s[2], s[0], s[1], p);
        char why[160];
        if (std::isfinite(from) && std::isfinite(to) && std::fabs(from - s[0]) < 1e-6 && std::fabs(to - s[1]) < 1e-6) continue;
        std::snprintf(why, sizeof why, "an easing begins at the one key's value and ends at the other's: from %g to %g this one begins at %g and ends at %g", s[0], s[1], from, to);
        return d.error = why, false;
    }
    return doc_change(d, sqlite3_mprintf("insert into easing values(%Q, %Q) on conflict do update set expression = excluded.expression", name, expression));
}
