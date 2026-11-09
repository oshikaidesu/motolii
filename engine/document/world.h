// world.h: part of doc.h (relations written as files, and the world those that push share). Read only through doc.h.

// Whether a kept solve has had its 5 ms of this picture, as React's Scheduler yields: a window shows the frames it has
// till they are made again; a film, a still, a picture kept and Bake wait for all of it (DocExact).
static bool doc_spent(const Doc& d) { return d.live && !d.exact && !d.writing && std::chrono::steady_clock::now() - d.slice > std::chrono::milliseconds(5); }
struct DocKeptTells { Doc& d; Doc::RelatedKept& k; ~DocKeptTells() { if (d.reading) d.reading->insert(k.reads.begin(), k.reads.end()); } };
// Whether what is kept stands for this moment. A step that touches nothing it reads leaves it be (SQLite's changeset,
// doc_note; what it reads as a build system's dynamic dependencies are found, by watching); any other goes on only from
// the first frame told otherwise, as GGPO's rollback goes back to the input that differed and runs on.
static bool doc_kept_stands(Doc& d, Doc::RelatedKept& k, double t) {
    const long changes = d.file ? (long)sqlite3_total_changes(d.file) : 0;
    const bool same = k.changes == changes && k.made == doc_scripts_made(d) && k.seen == d.touched.size();
    if (k.at == t && same && d.held.layer < 0 && (!k.behind || doc_spent(d))) { d.behind = d.behind || k.behind; return true; }
    if (k.made != doc_scripts_made(d)) k.frames.clear(), k.told.clear(), k.sure = k.fresh = 0;
    if (!same) k.solves = -1;
    for (; k.seen < d.touched.size(); ++k.seen) if (d.touched[k.seen] < 0 || k.reads.count(d.touched[k.seen])) k.sure = 0;
    k.at = t, k.changes = changes, k.made = doc_scripts_made(d), k.behind = false;
    return false;
}
// From the start of the stage a frame at a time at p5_stand.h's 60, each kept so going back asks nothing: tell(f) says
// what the frame is told, make(said, f) works it out, only if it was told otherwise. False if nothing can be shown.
template <class Tell, class Make> static bool doc_kept_walk(Doc& d, Doc::RelatedKept& k, double t, Tell tell, Make make) {
    const size_t frame = (size_t)std::max(0.0, std::round(t * 60.0));
    while (k.sure <= frame) {
        if (doc_spent(d)) { k.behind = d.behind = true; break; }
        const std::string js = tell(k.sure);
        const size_t heard = std::hash<std::string>{}(js);
        if (k.sure < k.fresh && k.told[k.sure] == heard) { ++k.sure; continue; }
        std::vector<double> next = make(js, k.sure);
        if (next.empty()) return false;
        k.frames.resize(std::max(k.frames.size(), k.sure + 1)), k.told.resize(k.frames.size());
        k.frames[k.sure] = std::move(next), k.told[k.sure] = heard;
        k.fresh = ++k.sure;
    }
    return !k.frames.empty();
}
static std::string doc_relate_parameters(Doc& d, int by, const DocScript& sc, double at) {
    std::ostringstream js;
    js.precision(12);
    js << '{';
    for (size_t i = 0; i < sc.parameters.size(); ++i) {
        js << sc.parameters[i].name << ':';
        if (sc.parameters[i].kind != "select") { js << doc_number(d, by, sc.names[i].c_str(), at, sc.parameters[i].usual) << ','; continue; }
        const std::string w = doc_word(d, by, sc.names[i].c_str());
        js << '"' << (w.empty() ? sc.parameters[i].words.substr(0, sc.parameters[i].words.find(' ')) : w) << "\",";
    }
    js << '}';
    return js.str();
}
// What a relation written as a file says of all its layers at a moment. Its relate() is told them all at once, as a Python
// Effector in Cinema 4D's Full Control is, not one value at a time as the kinds in relations.h: each one's place can
// hang on all the others. For each layer, doc_relate_names in turn. Empty: no file, or it failed (what is under it shows,
// and it says why). One whose relate() takes a fourth argument remembers, as Cavalry's Value Solver and Context's
// saveObject: told what it said the frame before, null at the first. It sleeps while its Strength is 0, as Houdini's
// Activation: what is under it shows, and it wakes where those layers are then. Held by hand, it waits.
static const std::vector<double>& doc_related_all(Doc& d, int by, double t) {
    Doc::RelatedKept& k = d.relatedKept[by];
    DocKeptTells tells{d, k};
    if (doc_kept_stands(d, k, t)) return k.values;
    k.values.clear();
    DocScript* sc = doc_script_of(d, doc_word(d, by, "script"));
    if (!sc || !sc->run || !sc->run->ok()) return k.values;
    if (k.solves < 0) { const std::vector<double> takes = sc->run->numbers("Float64Array.of(relate.length)"); k.solves = !takes.empty() && takes[0] > 3; }
    const Doc::Relation& rel = doc_relation_of(d, by);
    constexpr size_t many = std::size(doc_relate_names);
    const auto tell = [&](double at, size_t frame) {
        std::ostringstream js;
        js.precision(12);
        js << "__relates([";
        for (size_t i = 0; i < rel.members.size(); ++i) {
            const int layer = rel.members[i];
            if (!layer) continue;
            const int was = rel.under.empty() ? 0 : rel.under[i];
            js << '[';
            double size = 1;
            math::double3 place{0.0};
            for (const char* name : doc_relate_names) {
                const double own = doc_number(d, layer, name, at, !strcmp(name, "size") || !strcmp(name, "opacity") ? 1 : 0), is = was ? doc_related(d, was, layer, name, at, own) : own;
                if (!strcmp(name, "size")) size = is;
                if (name[0] >= 'x' && !name[1]) place[name[0] - 'x'] = is;
                js << is << ',';
            }
            float2 half{0.f};
            doc_half(d, layer, &half);
            js << 2.0 * half.x * size << ',' << 2.0 * half.y * size << ',' << layer << ',' << doc_falloff_at(d, by, place, at) << "],";
        }
        js << "]," << at << ',' << doc_relate_parameters(d, by, *sc, at) << ',' << by << ',' << frame << ',' << (!k.solves || doc_number(d, by, "strength", at, 1) > 0 ? "true" : "false") << ')';
        return js.str();
    };
    const auto told = [&](double at, size_t frame) {   // (watching what it reads, at the first)
        std::set<int>* const outer = d.reading;
        if (!frame) k.reads.clear(), d.reading = &k.reads;
        const std::string js = tell(at, frame);
        d.reading = outer;
        return js;
    };
    if (k.solves && !doc_kept_walk(d, k, t, [&](size_t f) { return told((double)f / 60.0, f); }, [&](const std::string& js, size_t) { return sc->run->numbers(js); })) return k.values;
    const std::vector<double> said = k.solves ? k.frames[std::min((size_t)std::max(0.0, std::round(t * 60.0)), k.frames.size() - 1)] : sc->run->numbers(told(t, 0));
    if (said.size() != many * (rel.members.size() - (size_t)std::count(rel.members.begin(), rel.members.end(), 0))) return k.values;
    k.values.assign(many * rel.members.size(), 0.0);
    for (size_t i = 0, in = 0; i < rel.members.size(); ++i)
        if (rel.members[i]) { if (many * (in + 1) <= said.size()) std::copy_n(said.begin() + (long)(many * in), many, k.values.begin() + (long)(many * i)); ++in; }
    return k.values;
}

// Whether a relation written as a file pushes: force(), not relate().
static bool doc_pushes(Doc& d, int by) {
    DocScript* sc = doc_script_of(d, doc_word(d, by, "script"));
    if (!sc || !sc->run || !sc->run->ok()) return false;
    if (sc->pushes < 0) { const std::vector<double> has = sc->run->numbers("Float64Array.of(typeof force == 'function' ? 1 : 0)"); sc->pushes = !has.empty() && has[0] > 0; }
    return sc->pushes > 0;
}
// The relations that push share one world, as Houdini's POP microsolvers share one stream of particles: each layer is
// one particle, where it is and how fast it goes, whichever of them are on it. All are told the frame as it stands and
// each adds to the speed, the contract of d3-force ("read the node's current position and then add to the node's
// velocity"), so d3's own forces run as they are. What each adds is weighed by its Strength and Falloff (Cavalry's: a
// multiplier on its Strength), added up as the POP Solver's microsolvers "accumulate forces", and the world moves each
// by its speed once, as d3-force's tick. So a rule changes without a jolt: the speed goes on, whoever gives it.
// A layer none is pushing shows what is under them all, and goes on from there with the speed that has, as a Houdini
// Bullet object follows its animation till it is made active; between, by how much is pushing, as Strength always
// weighed (a layer fading out of its only force goes home, no source for that but this file's own past: Houdini's would
// coast). A plain relation between two that push is passed over: the world stands on what is under the lowest.
static constexpr size_t doc_world_told = 11, doc_world_at = 8, doc_world_speed = 11, doc_world_home = 14, doc_world_kept = 17;   // (for each layer, told: doc_relate_names, then its speed; kept: the 8 it shows, where it is, its speed, where it would be left alone)
static void doc_world_made(Doc& d) {
    Doc::World w;
    std::vector<int> files;
    doc_rows(d, sqlite3_mprintf("select layer from keyframe where name = 'file' and value = 'relate' order by layer"), [&](sqlite3_stmt* q) { files.push_back(sqlite3_column_int(q, 0)); });
    for (const int by : files) {
        if (!doc_pushes(d, by)) continue;
        w.forces.push_back(by);
        const Doc::Relation& rel = doc_relation_of(d, by);
        for (size_t i = 0; i < rel.members.size(); ++i)
            if (const int t = rel.members[i]; t && w.slot.emplace(t, w.layers.size()).second) w.layers.push_back(t), w.below.push_back(rel.under.empty() ? 0 : rel.under[i]);
    }
    d.world = std::move(w);
}
static const std::vector<double>* doc_world(Doc& d, double t) {
    Doc::RelatedKept& k = d.relatedKept[0];
    DocKeptTells tells{d, k};
    const auto known = [&]() -> const std::vector<double>* { return k.frames.empty() ? nullptr : &k.frames[std::min((size_t)std::max(0.0, std::round(t * 60.0)), k.frames.size() - 1)]; };
    if (d.walking || doc_kept_stands(d, k, t)) return known();
    if (k.solves < 0) {
        const std::vector<int> was = d.world.layers;
        doc_world_made(d), k.solves = 1;
        if (d.world.layers != was) k.frames.clear(), k.told.clear(), k.sure = k.fresh = 0;   // (a frame kept lay them out otherwise)
    }
    struct Walking { Doc& d; explicit Walking(Doc& d) : d(d) { d.walking = true; } ~Walking() { d.walking = false; } } walking(d);
    const Doc::World& w = d.world;
    const size_t many = std::size(doc_relate_names), n = w.layers.size();
    struct Call { DocScript* sc; std::string js; std::vector<std::pair<size_t, double>> on; };   // (on: where each of its layers lies, and how much it counts)
    std::vector<Call> calls;
    std::vector<double> now, home;
    const auto tell = [&](size_t f) {
        const double at = (double)f / 60.0;
        std::set<int>* const outer = d.reading;
        if (!f) k.reads.clear(), d.reading = &k.reads;
        const double* const was = f ? k.frames[f - 1].data() : nullptr;
        now.assign(n * doc_world_told, 0.0), home.assign(n * (many + 2), 0.0);
        for (size_t s = 0; s < n; ++s) {
            double size = 1;
            for (size_t j = 0; j < many; ++j) {
                const char* name = doc_relate_names[j];
                const double own = doc_number(d, w.layers[s], name, at, !strcmp(name, "size") || !strcmp(name, "opacity") ? 1 : 0);
                const double is = home[s * (many + 2) + j] = w.below[s] ? doc_related(d, w.below[s], w.layers[s], name, at, own) : own;
                now[s * doc_world_told + j] = is;
                if (!strcmp(name, "size")) size = is;
            }
            float2 half{0.f};
            doc_half(d, w.layers[s], &half);
            home[s * (many + 2) + many] = 2.0 * half.x * size, home[s * (many + 2) + many + 1] = 2.0 * half.y * size;
            if (was) for (size_t j = 0; j < 3; ++j) now[s * doc_world_told + j] = was[s * doc_world_kept + doc_world_at + j], now[s * doc_world_told + many + j] = was[s * doc_world_kept + doc_world_speed + j];
        }
        calls.clear();
        std::string all;
        for (const int by : w.forces) {
            DocScript* sc = doc_script_of(d, doc_word(d, by, "script"));
            if (!sc || !sc->run) continue;
            const Doc::Relation& rel = doc_relation_of(d, by);
            const double strength = doc_number(d, by, "strength", at, 1), weight = f && doc_number(d, by, "visible", 0, 1) > 0.5 ? std::clamp(strength, 0.0, 2.0) : 0.0;   // (nothing at the first: where each starts)
            std::ostringstream js;
            js.precision(12);
            if (f && weight <= 0.0) {   // (asleep: it forgets what it wrote, as it wakes anew; at the first it is told all the same, to find what it reads)
                js << "__asleep(" << by << ',' << f << ')';
                all += js.str(), calls.push_back(Call{sc, js.str(), {}});
                continue;
            }
            js << "__forces([";
            Call call{sc, "", {}};
            for (const int layer : rel.members) {
                if (!layer) continue;
                const size_t s = w.slot.at(layer);
                const double* const is = &now[s * doc_world_told], * const stands = &home[s * (many + 2)];
                const double near = doc_falloff_at(d, by, {is[0], is[1], is[2]}, at);
                js << '[';
                for (size_t j = 0; j < doc_world_told; ++j) js << is[j] << ',';
                js << stands[many] << ',' << stands[many + 1] << ',' << layer << ',' << near << ',' << stands[0] << ',' << stands[1] << ',' << stands[2] << "],";
                call.on.emplace_back(s, weight * near);
            }
            js << "]," << at << ',' << doc_relate_parameters(d, by, *sc, at) << ',' << by << ',' << f << ',' << (weight > 0.0 ? "true" : "false") << ')';
            call.js = js.str();
            all += call.js;
            calls.push_back(std::move(call));
        }
        d.reading = outer;
        return all;
    };
    const auto make = [&](const std::string&, size_t f) {
        std::vector<double> sum = now, pushed(n, 0.0), next(n * doc_world_kept);
        for (const Call& call : calls) {
            const std::vector<double> said = call.sc->run->numbers(call.js);
            if (said.size() != call.on.size() * doc_world_told) continue;   // (it failed, and says why: what the others say stands)
            for (size_t in = 0; in < call.on.size(); ++in) {
                const auto [s, weight] = call.on[in];
                pushed[s] += weight;
                for (size_t j = 0; j < doc_world_told; ++j) sum[s * doc_world_told + j] += weight * (said[in * doc_world_told + j] - now[s * doc_world_told + j]);
            }
        }
        for (size_t s = 0; s < n; ++s) {
            const double share = std::min(1.0, pushed[s]), * const stands = &home[s * (many + 2)], * const sums = &sum[s * doc_world_told];
            double* const out = &next[s * doc_world_kept];
            std::copy_n(sums + 3, many - 3, out + 3);
            for (size_t j = 0; j < 3; ++j) {
                const double speed = share > 0.0 ? sums[many + j] : f ? stands[j] - k.frames[f - 1][s * doc_world_kept + doc_world_home + j] : 0.0;
                out[doc_world_at + j] = share > 0.0 ? sums[j] + speed : stands[j], out[doc_world_speed + j] = speed, out[doc_world_home + j] = stands[j];
                out[j] = stands[j] + (out[doc_world_at + j] - stands[j]) * share;
            }
        }
        return next;
    };
    doc_kept_walk(d, k, t, tell, make);
    return known();
}
static double doc_world_value(Doc& d, int layer, size_t name, double t, double otherwise) {
    const std::vector<double>* const all = doc_world(d, t);
    const auto at = d.world.slot.find(layer);
    return !all || at == d.world.slot.end() || (at->second + 1) * doc_world_kept > all->size() ? otherwise : (*all)[at->second * doc_world_kept + name];
}
