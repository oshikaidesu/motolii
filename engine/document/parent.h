// parent.h: part of doc.h (a thing given a parent; what a group holds; a thing raised among the things). Read only through doc.h.
// A thing given another to go with (0: none) without moving on the stage, as the sample's Parent seat promises and
// After Effects does: where it is, how far it is turned about the eye's line and how large are said again as the new
// parent sees them (a value with keys is moved whole, by the rule of doc_put; a keyed size is left as it is). A parent
// that leans, turned about x or y, is not undone in the turn: only where the thing is takes it in.
static std::vector<double> doc_key_moments(Doc& d, int thing, const char* name);
static bool doc_parent(Doc& d, int thing, double to) {
    if (!doc_knows(d, thing, "parent", &to)) return false;
    for (int up = (int)to, n = 0; up && n < 64; up = (int)doc_number(d, up, "parent", 0, 0), ++n)   // (a ring of things each going with the next goes nowhere)
        if (up == thing) return d.trouble = "it would go with itself (that one goes with it already)", false;
    const double now = d.stage->now;
    const auto chain = [&](int up, double* turn, double* size) {   // (how far the parents turn it, and how large they make it)
        *turn = 0.0, *size = 1.0;
        for (int n = 0; up && n < 64 && d.shown.count(up); up = (int)doc_number(d, up, "parent", 0, 0), ++n) *turn += doc_number(d, up, "rotate", now, 0), *size *= doc_number(d, up, "size", now, 1);
    };
    double turnWas, sizeWas, turnTo, sizeTo;
    chain((int)doc_number(d, thing, "parent", 0, 0), &turnWas, &sizeWas);
    chain((int)to, &turnTo, &sizeTo);
    // (where it stands at each of its place's keys, and now: every one of them taken over as the hand sees it now, as
    //  After Effects moves a layer's keys whole when it is parented; none is added)
    const char* const xyz[] = {"x", "y", "z"};
    std::map<double, math::double4> stood;
    stood[now] = {doc_number(d, thing, "x", now, 0), doc_number(d, thing, "y", now, 0), doc_number(d, thing, "z", now, 0), 1.0};
    for (const char* name : xyz)
        for (const double at : doc_key_moments(d, thing, name)) stood[at] = {doc_number(d, thing, "x", at, 0), doc_number(d, thing, "y", at, 0), doc_number(d, thing, "z", at, 0), 1.0};
    const math::mat4 was = doc_above(d, thing, now);
    const double size = doc_number(d, thing, "size", now, 1);
    doc_act(d);
    bool ok = doc_change(d, sqlite3_mprintf("insert into fact(thing, name, at, value) values(%d, 'parent', 0.0, %!.17g) on conflict do update set value = excluded.value", thing, to));
    doc_forget(d);   // (the parent read again as now written, not as kept from the last picture: as doc_unrelate reads after its change)
    const math::mat4 into = inverse(doc_above(d, thing, now)) * was;
    for (int k = 0; ok && k < 3; ++k) {
        const std::vector<double> keys = doc_key_moments(d, thing, xyz[k]);
        if (keys.empty()) ok = doc_set(d, thing, xyz[k], (into * stood[now])[k]);
        for (const double at : keys) ok = ok && doc_change(d, sqlite3_mprintf("update fact set value = %!.17g where thing = %d and name = %Q and at = %!.17g", (into * stood[at])[k], thing, xyz[k], at));
    }
    const double turnBy = turnWas - turnTo;
    if (ok && turnBy != 0.0) ok = doc_keys(d, thing, "rotate") ? doc_change(d, sqlite3_mprintf("update fact set value = value + %!.17g where thing = %d and name = 'rotate'", turnBy, thing))
                                                               : doc_set(d, thing, "rotate", doc_number(d, thing, "rotate", now, 0) + turnBy);
    // (a thing with no size, a camera, keeps none: its parent is its Target's layer in the inspector, and was refused for a
    //  size it has not, "a camera has no size": golf P08, golf_noise.md (68); as relations.h skips what a thing has not)
    if (ok && doc_knows(d, thing, "size") && !doc_keys(d, thing, "size")) ok = doc_set(d, thing, "size", std::clamp(size * sizeWas / sizeTo, 1e-3, 1e4));
    return doc_acted(d) && ok;
}
static double doc_lasts(Doc& d, int thing);
static bool doc_key_here(Doc& d, int thing, const char* name, double at) {
    if (!doc_knows(d, thing, name, nullptr, nullptr, true)) return false;
    if (!strcmp(name, "time_remap") && !doc_keys(d, thing, name)) {   // (After Effects' Enable Time Remapping: a key at its start and one at its end, each its own time there; so one step)
        const double gone = doc_number(d, thing, "begin", 0, 0), start = doc_number(d, thing, "start", 0, 0), lasts = doc_lasts(d, thing) > 0.0 ? doc_lasts(d, thing) : std::max(1e-3, doc_seconds(d) - start);
        doc_act(d);
        const bool ok = doc_key(d, thing, name, start, gone) && doc_key(d, thing, name, start + lasts, gone + lasts) && (at <= start || at >= start + lasts || doc_key(d, thing, name, at, gone + at - start));
        if (!ok) d.act_ok = false;
        return doc_acted(d) && ok;
    }
    return doc_keys(d, thing, name, at) && doc_keys(d, thing, name) ? true : doc_key(d, thing, name, at, doc_number(d, thing, name, at, doc_usual_on(d, thing, name)));
}
// What a group holds, however deep: the things under a Null (a thing's parent that is not a Null holds nothing: After
// Effects' parenting moves a child, it does not take it in).
static std::vector<int> doc_under(Doc& d, int group) {
    std::vector<int> all;
    if (doc_word(d, group, "shape") != "null") return all;
    for (const int t : doc_laid(d)) {
        int up = (int)doc_number(d, t, "parent", 0, 0);
        for (int n = 0; up > 0 && up != group && n < 64; ++n) up = (int)doc_number(d, up, "parent", 0, 0);
        if (up == group) all.push_back(t);
    }
    return all;
}
// raise: a thing brought `places` places nearer among the things (below 0: further back): each thing is told where it
// lies now, as one change. A group goes with what it holds, one place among the things (a precomposed layer is one).
static bool doc_raise(Doc& d, int thing, int places) {
    if (!doc_knows(d, thing)) return false;
    doc_forget(d);   // (the order as the document has it now, a thing just added in the same act too: as doc_relate forgets before it reads)
    std::vector<int> lie = doc_laid(d), going = doc_under(d, thing);
    going.push_back(thing);
    const long from = std::find(lie.begin(), lie.end(), going.front()) - lie.begin();
    lie.erase(std::remove_if(lie.begin(), lie.end(), [&](int t) { return std::find(going.begin(), going.end(), t) != going.end(); }), lie.end());
    const long to = std::clamp(from + (long)places, 0L, (long)lie.size());
    if (to == from) return d.trouble = places > 0 ? "it is the nearest already" : "it is the furthest back already", false;
    lie.insert(lie.begin() + to, going.begin(), going.end());
    char* all = sqlite3_mprintf("");
    for (size_t i = 0; i < lie.size(); ++i)
        all = sqlite3_mprintf("%zinsert into fact(thing, name, at, value) values(%d, 'order', 0.0, %d) on conflict do update set value = excluded.value;", all, lie[i], (int)i + 1);
    return doc_change(d, all);
}
