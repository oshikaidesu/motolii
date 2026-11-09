// easings_put.h: part of doc.h (a key taken off, and the ways from a key to the next). Read only through doc.h.
static bool doc_unkey(Doc& d, int layer, const char* name, double at) {
    if (!doc_knows(d, layer, name)) return false;
    if (!doc_keys(d, layer, name) || !doc_keys(d, layer, name, at)) return d.error = std::string(name) + " has no key at that moment", false;
    if (doc_keys(d, layer, name) == 1) return doc_set(d, layer, name, doc_number(d, layer, name, at, 0));   // (its last key: it stays what the key held)
    return doc_change(d, sqlite3_mprintf("delete from keyframe where layer = %d and name = %Q and at = %!.17g", layer, name, at));
}
// How the stretch from a key to the next goes: one of the nine kinds, alone or with all its numbers (Random 3 0.25
// 0.5 0.8 0.5), or a way defined in this document with up to four numbers.
static std::string doc_easings(Doc& d) {
    std::string all;
    for (const auto& kind : interp_kinds) all += std::string(all.empty() ? "" : ", ") + kind.name + (kind.numbers ? std::string(" (") + kind.names + ")" : "");
    all += "; by name:";
    for (const auto& one : named_ways) all += std::string(" ") + one.name;
    doc_rows(d, sqlite3_mprintf("select name from easing order by name"), [&](sqlite3_stmt* row) { all += std::string("; defined here: ") + (const char*)sqlite3_column_text(row, 0); });
    return all;
}
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
static bool doc_define(Doc& d, const char* name, const char* expression) {
    Interp kind;
    if (interp_said(name, &kind) >= 0) return d.error = std::string(name) + " is one of the nine kinds already", false;
    sqlite3_stmt* statement = doc_expression_statement(d, expression);
    if (!statement) return false;
    const double p[4] = {1, 1, 1, 1}, tried[2][3] = {{0, 1, 1}, {2, -5, 3}};   // (two stretches to try it on: values a to b, over that many seconds)
    for (const auto& s : tried) {
        const double from = doc_went(statement, 0, 0, s[2], s[0], s[1], p), to = doc_went(statement, 1, s[2], s[2], s[0], s[1], p);
        char why[160];
        if (std::isfinite(from) && std::isfinite(to) && std::fabs(from - s[0]) < 1e-6 && std::fabs(to - s[1]) < 1e-6) continue;
        std::snprintf(why, sizeof why, "an easing begins at the one key's value and ends at the other's: from %g to %g this one begins at %g and ends at %g", s[0], s[1], from, to);
        return d.error = why, false;
    }
    return doc_change(d, sqlite3_mprintf("insert into easing values(%Q, %Q) on conflict do update set expression = excluded.expression", name, expression));
}
