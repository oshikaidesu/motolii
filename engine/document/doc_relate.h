// doc_relate.h: part of doc.h (a thing put in a relation and taken out of it; a relation led, let go). Read only through doc.h.
// A thing taken out of a relation where it shows at that moment: no longer in it (what its values were connected to
// is what this one started from for it, or none; a relation that started from this one for it now starts from that),
// its place among the relation's members kept empty so no other moves, then each of its connected values moved (all
// its keys alike) by as much as it would otherwise jump. One step; nothing jumps.
static void doc_act(Doc& d);
static bool doc_acted(Doc& d);
static const char* doc_lasting(const std::string& name) {   // (a name made at run time, kept where doc_literal can know it again by its place: one place for each name, ever)
    static std::set<std::string> kept;
    return kept.insert(name).first->c_str();
}
static std::vector<std::pair<std::string, double>> doc_shown_now(Doc& d, int thing, double now) {   // (each connected value and where it shows now)
    std::vector<std::pair<std::string, double>> names;
    doc_rows(d, sqlite3_mprintf("select name from fact where thing = %d and name glob '*_by' and value <> 0", thing), [&](sqlite3_stmt* q) { names.push_back({(const char*)sqlite3_column_text(q, 0), 0.0}); });
    for (auto& [n, shown] : names) shown = doc_literal(d, thing, doc_lasting(n.substr(0, n.size() - 3)), now, 0.0);
    return names;
}
static bool doc_free(Doc& d, int thing, int by, double now, bool stay, const std::vector<std::pair<std::string, double>>* told) {
    const DocExact exact(d);
    const Doc::Relation rel = doc_relation_of(d, by);   // (a copy: what follows forgets it)
    const auto at = std::find(rel.members.begin(), rel.members.end(), thing);
    if (at == rel.members.end()) return d.trouble = "it is not in that relation", false;
    const size_t i = (size_t)(at - rel.members.begin());
    const int was = rel.under.empty() ? 0 : rel.under[i];
    const std::vector<std::pair<std::string, double>> names = told ? *told : doc_shown_now(d, thing, now);
    const auto word = [&](const char* name, int r, const std::function<std::string(size_t, const std::string&)>& each) {
        std::string all;
        std::istringstream said(doc_word(d, r, name));
        size_t k = 0;
        for (std::string one; said >> one; ++k) all += (all.empty() ? "" : " ") + each(k, one);
        return sqlite3_mprintf("update fact set value = %Q where thing = %d and name = %Q;", all.c_str(), r, name);
    };
    doc_act(d);
    char* change = word("members", by, [&](size_t k, const std::string& one) { return k == i ? std::string("_") : one; });
    for (const auto& [n, _] : names)   // (connected to this one: to what it started from)
        if ((int)doc_number(d, thing, n.c_str(), 0, 0) == by)
            change = was ? sqlite3_mprintf("%z update fact set value = %d where thing = %d and name = %Q;", change, was, thing, n.c_str()) : sqlite3_mprintf("%z delete from fact where thing = %d and name = %Q;", change, thing, n.c_str());
    for (const auto& [r, other] : d.relationsOf)   // (a relation that started from this one for it: from that one)
        if (r != by) {
            const auto there = std::find(other.members.begin(), other.members.end(), thing);
            if (there != other.members.end() && !other.under.empty() && other.under[(size_t)(there - other.members.begin())] == by)
                change = sqlite3_mprintf("%z %z", change, word("under", r, [&](size_t k, const std::string& one) { return k == (size_t)(there - other.members.begin()) ? std::to_string(was) : one; }));
        }
    bool ok = doc_change(d, change);
    doc_forget(d);
    for (const auto& [n, shown] : names) {   // (each value moved by what it would jump, when baked; else as the relation at strength 0 for good: back to the one under it, or its own value, so a morph by strength and a removal agree)
        if (!ok || !stay) break;
        const std::string base = n.substr(0, n.size() - 3);
        const double off = shown - doc_literal(d, thing, doc_lasting(base), now, 0.0);
        if (std::abs(off) < 1e-12) continue;
        ok = doc_change(d, sqlite3_mprintf("update fact set value = value + %!.17g where thing = %d and name = %Q; insert into fact(thing, name, at, value) select %d, %Q, 0.0, %!.17g where not exists (select 1 from fact where thing = %d and name = %Q);",
                                           off, thing, base.c_str(), thing, base.c_str(), off, thing, base.c_str()));
        doc_forget(d);
    }
    return doc_acted(d) && ok;
}
// Things put in a relation as they show now: in its order (round its middle, or from the left), each with the relation
// it was in before (this one starts from what that gives) and where it showed (this one adds only the step from there:
// nothing jumps when it comes in, and a hand still moves it); an around's or a row's middle and size where they stand, a
// follow's or a push's leader (the leftmost, the largest) if none is said. Then connected. One step.
static bool doc_relate(Doc& d, int by, const char* ids, double now) {
    const std::string type = doc_word(d, by, "file");
    if (doc_word(d, by, "kind") != "behaviour" || !doc_among(doc_relations, type)) return d.trouble = "that is no relation", false;
    std::vector<int> things;
    std::istringstream said(ids);
    for (std::string one; said >> one;) if (const int t = std::atoi(one.c_str()); t && t != by && doc_knows(d, t) && std::find(things.begin(), things.end(), t) == things.end()) things.push_back(t);
    if (things.empty()) return d.trouble = "no things to put in it", false;
    std::map<int, std::pair<double, double>> at;   // (where each settles: what follows and pushes now is not kept)
    d.settled = true;
    doc_forget(d);
    for (const int t : things) at[t] = {doc_literal(d, t, "x", now, 0.0), doc_literal(d, t, "y", now, 0.0)};
    d.settled = false;
    doc_forget(d);
    const auto has = [&](const char* name) { bool any = false; doc_rows(d, sqlite3_mprintf("select 1 from fact where thing = %d and name = %Q limit 1", by, name), [&](sqlite3_stmt*) { any = true; }); return any; };
    doc_act(d);
    bool ok = true;
    int leader = (int)doc_number(d, by, "leader", 0, 0);
    if (!leader && (type == "follow" || type == "push") && things.size() > 1) {
        leader = *std::min_element(things.begin(), things.end(), [&](int a, int b) { return type == "follow" ? at[a].first < at[b].first : doc_number(d, a, "size", now, 1) > doc_number(d, b, "size", now, 1); });
        ok = ok && doc_set(d, by, "leader", leader);
    }
    if (type == "follow" && !has("lag")) ok = ok && doc_set(d, by, "lag", 0.1);   // (said, so its card shows what it does: each a tenth of a second later)
    if (type == "push" && !has("radius")) ok = ok && doc_set(d, by, "radius", 0.5);
    std::vector<int> members;
    for (const int t : things) if (t != leader) members.push_back(t);
    double cx = 0, cy = 0;
    for (const int t : members) cx += at[t].first / members.size(), cy += at[t].second / members.size();
    if (type == "group")   // (in reading order: the top line first, each line from the left)
        std::sort(members.begin(), members.end(), [&](int a, int b) { return std::round(at[a].second * 10) != std::round(at[b].second * 10) ? at[a].second > at[b].second : at[a].first < at[b].first; });
    if (type == "around" || type == "row") {
        if (has("centre_x")) cx = doc_number(d, by, "centre_x", now, 0), cy = doc_number(d, by, "centre_y", now, 0);
        else ok = ok && doc_set(d, by, "centre_x", cx) && doc_set(d, by, "centre_y", cy);   // (its middle where they stand)
        std::sort(members.begin(), members.end(), [&](int a, int b) { return type == "around" ? std::atan2(at[a].first - cx, at[a].second - cy) < std::atan2(at[b].first - cx, at[b].second - cy) : at[a].first < at[b].first; });
        if (type == "around" && !has("radius")) {
            double r = 0;
            for (const int t : members) r += std::hypot(at[t].first - cx, at[t].second - cy) / members.size();
            ok = ok && doc_set(d, by, "radius", std::max(r, 0.2));
        }
        if (type == "row" && !has("gap") && members.size() > 1) {   // (as far apart as they stand, but never closer than the largest of them is wide)
            double wide = 0;
            for (const int t : members) wide = std::max(wide, doc_number(d, t, "size", now, 1) * std::max(1.0, doc_number(d, t, "wide", now, 1)));
            ok = ok && doc_set(d, by, "gap", std::max((at[members.back()].first - at[members.front()].first) / (members.size() - 1), wide * 1.6));
        }
    }
    std::string order, under, from;
    for (const int t : members) {
        const int before = doc_driven_by(d, t, "x");
        const bool related = before && doc_among(doc_relations, doc_word(d, before, "file"));
        order += (order.empty() ? "" : " ") + std::to_string(t);
        under += (under.empty() ? "" : " ") + std::to_string(related ? before : 0);
        const std::pair<double, double> came = type == "follow" ? std::make_pair(doc_literal(d, leader, "x", now, 0.0), doc_literal(d, leader, "y", now, 0.0)) : at[t];
        char buf[64];
        std::snprintf(buf, sizeof buf, "%.17g %.17g", came.first, came.second);
        from += (from.empty() ? "" : " ") + std::string(buf);
    }
    ok = ok && doc_say(d, by, "members", order.c_str()) && doc_say(d, by, "under", under.c_str()) && doc_say(d, by, "from", from.c_str());
    for (const int t : members) {
        ok = ok && doc_set(d, t, "x_by", by) && doc_set(d, t, "y_by", by) && (!doc_knows(d, t, "z") || doc_set(d, t, "z_by", by));   // (its depth too, where it has one: a ring tipped back, a leader in depth)
        if (type == "around" || type == "row" || type == "group" || type == "relate")   // (its turns, size and opacity too: the relation's own, given in turn)
            for (const char* n : {"rotate", "rotate_x", "rotate_y", "size", "opacity"}) ok = ok && (!doc_knows(d, t, n) || doc_set(d, t, (std::string(n) + "_by").c_str(), by));
    }
    return doc_acted(d) && ok;
}
// A relation led by another: the new leader out of its things if it was one, the old one in among them where it shows,
// a follow's start the new leader's settled place; then every thing it touches moved by as much as it would otherwise
// jump. One step; nothing jumps.
static bool doc_lead(Doc& d, int by, int leader, double now) {
    struct Leading { Leading() { doc_leading = true; } ~Leading() { doc_leading = false; } } leading;
    const std::string type = doc_word(d, by, "file");
    if (doc_word(d, by, "kind") != "behaviour" || !doc_among(doc_relations, type)) return d.trouble = "that is no relation", false;
    if (!doc_knows(d, leader) || leader == by) return d.trouble = "a leader is a thing that is there", false;
    const int was = (int)doc_number(d, by, "leader", 0, 0);
    if (was == leader) return true;
    std::vector<int> touched;
    for (const int t : doc_members_of(d, by)) if (t) touched.push_back(t);
    for (const int t : {was, leader}) if (t && std::find(touched.begin(), touched.end(), t) == touched.end()) touched.push_back(t);
    std::map<int, std::pair<double, double>> shown;
    for (const int t : touched) shown[t] = {doc_literal(d, t, "x", now, 0.0), doc_literal(d, t, "y", now, 0.0)};
    d.settled = true;
    doc_forget(d);
    const std::pair<double, double> settles = {doc_literal(d, leader, "x", now, 0.0), doc_literal(d, leader, "y", now, 0.0)};
    const std::pair<double, double> wasAt = was ? std::make_pair(doc_literal(d, was, "x", now, 0.0), doc_literal(d, was, "y", now, 0.0)) : settles;
    d.settled = false;
    doc_forget(d);
    doc_act(d);
    const std::vector<int>& in = doc_members_of(d, by);
    bool ok = std::find(in.begin(), in.end(), leader) == in.end() || doc_free(d, leader, by, now, true);   // (the leader is not one it moves)
    if ((type == "around" || type == "row") && ok)   // (its middle is its leader: the ring or the row goes round it, as planets round a sun)
        ok = doc_set(d, by, "centre_x", 0) && doc_set(d, by, "centre_y", 0);
    ok = ok && doc_set(d, by, "leader", leader);
    if (ok && was && type != "around" && type != "row") {   // (the old leader in among its things, where it shows; a ring's or a row's old middle stays out)
        const int under = doc_driven_by(d, was, "x");
        char add[96];
        std::snprintf(add, sizeof add, " %.17g %.17g", type == "follow" ? settles.first : wasAt.first, type == "follow" ? settles.second : wasAt.second);
        ok = doc_say(d, by, "members", (doc_word(d, by, "members") + " " + std::to_string(was)).c_str())
             && doc_say(d, by, "under", (doc_word(d, by, "under") + " " + std::to_string(under && doc_among(doc_relations, doc_word(d, under, "file")) ? under : 0)).c_str())
             && doc_say(d, by, "from", (doc_word(d, by, "from") + add).c_str()) && doc_set(d, was, "x_by", by) && doc_set(d, was, "y_by", by) && (!doc_knows(d, was, "z") || doc_set(d, was, "z_by", by));
    }
    if (ok && type == "follow") {   // (each starts from where the new leader settles)
        std::string from;
        char one[64];
        for (size_t k = 0, n = doc_members_of(d, by).size(); k < n; ++k) std::snprintf(one, sizeof one, "%s%.17g %.17g", k ? " " : "", settles.first, settles.second), from += one;
        ok = doc_say(d, by, "from", from.c_str());
    }
    doc_forget(d);
    for (const auto& [t, at] : shown) {   // (each moved by what it would jump; a ring or a row goes to its new middle)
        if (!ok || type == "around" || type == "row") break;
        const double ox = at.first - doc_literal(d, t, "x", now, 0.0), oy = at.second - doc_literal(d, t, "y", now, 0.0);
        for (const auto& [name, off] : {std::make_pair("x", ox), std::make_pair("y", oy)})
            if (std::abs(off) > 1e-12)
                ok = ok && doc_change(d, sqlite3_mprintf("update fact set value = value + %!.17g where thing = %d and name = %Q; insert into fact(thing, name, at, value) select %d, %Q, 0.0, %!.17g where not exists (select 1 from fact where thing = %d and name = %Q);", off, t, name, t, name, off, t, name));
        doc_forget(d);
    }
    return doc_acted(d) && ok;
}
// A relation let go: each of its things kept where it shows at that moment, the relation gone.
static bool doc_remove(Doc& d, int thing);
static bool doc_release(Doc& d, int by, double now) {
    const DocExact exact(d);
    if (doc_word(d, by, "kind") != "behaviour") return d.trouble = "that is no relation", false;
    const std::vector<int> all = doc_members_of(d, by);   // (a copy: freeing one forgets the list)
    std::map<int, std::vector<std::pair<std::string, double>>> shown;   // (all read before any goes: a relation written as a file says each one's place from all the others)
    for (const int t : all) if (t) shown[t] = doc_shown_now(d, t, now);
    doc_act(d);   // (one step: all of them freed and the relation gone, or none of it)
    bool ok = true;
    for (const int t : all) if (ok && t) ok = doc_free(d, t, by, now, true, &shown[t]);
    ok = ok && doc_remove(d, by);
    return doc_acted(d) && ok;
}
