// calls_sound.h: part of motolii.mm. Read only through motolii.mm. A film's sound: how loud it is (read once a file), over a stretch, ducked under the others (Audacity's Auto Duck), and where it strikes.
// A film's sound: how loud it is, 100 times a second of its own (read once a file, as fast as it decodes), and the
// moments of the document it strikes (grows `rise` dB louder at once), where its film shows them.
static const std::vector<float>* loudness_of(const std::string& file, bool read_it = true) {   // (not read_it: only if read already)
    static std::map<std::string, std::vector<float>> read;
    static std::mutex one;
    std::lock_guard<std::mutex> hold(one);
    auto found = read.find(file);
    if (found == read.end()) {
        if (!read_it) return nullptr;
        found = read.emplace(file, sound_loudness(file.c_str(), 100.0)).first;
    }
    return &found->second;
}
int motolii_loudness(Motolii* m, int thing, float* db, int room) {
    const std::string file = by_look(m, [=] { return doc_knows(doc(m), thing) && doc_word(*m->d, thing, "kind") == "video" ? doc_word(*m->d, thing, "file") : std::string(); });
    if (file.empty()) return 0;
    const std::vector<float>& all = *loudness_of(file);
    for (int i = 0; i < room && i < (int)all.size(); ++i) db[i] = all[(size_t)i];
    return (int)all.size();
}
// How loud a film's sound is at n moments of the document from `from` to before `to`, where its film shows them (dB;
// -100 where it is silent or not shown). -1: its sound is not read yet (motolii_loudness reads it), 0: no sound.
int motolii_loudness_over(Motolii* m, int thing, double from, double to, int n, float* db) {
    const std::string file = by_look(m, [=] { return doc_knows(doc(m), thing) && doc_word(*m->d, thing, "kind") == "video" ? doc_word(*m->d, thing, "file") : std::string(); });
    if (file.empty()) return 0;
    const std::vector<float>* all = loudness_of(file, false);
    if (!all) return -1;
    if (all->empty()) return 0;
    return by_look(m, [&] {   // (the document's moment to the film's own: from its start, from where it begins, at its speed)
        Doc& d = *m->d;
        const double start = doc_number(d, thing, "start", 0, 0), begin = doc_number(d, thing, "begin", 0, 0), speed = doc_number(d, thing, "speed", 0, 1), lasts = doc_number(d, thing, "duration", 0, -1);
        for (int i = 0; i < n; ++i) {
            const double s = from + (to - from) * i / n, own = begin + (s - start) * speed;
            const long k = std::lround(own * 100.0);
            db[i] = s < start || (lasts > 0.0 && s >= start + lasts) || k < 0 || k >= (long)all->size() ? -100.f : (*all)[(size_t)k];
        }
        return n;
    });
}
// Audacity's Auto Duck (its manual): a film's volume keyed down 12 dB while any other film's sound is louder than -30 dB,
// fading down over the half second before and up over the half second after, a pause shorter than a second not let up.
// One step. Refused while another's sound is not read yet (motolii_loudness reads it) or its volume has keys already.
static bool duck(Motolii* m, int thing) {
    Doc& d = *m->d;
    if (!doc_knows(d, thing) || doc_word(d, thing, "kind") != "video") return d.error = "a film or a sound is ducked", false;
    if (doc_keys(d, thing, "volume")) return d.error = "its volume has keys already", false;
    const double rate = 100.0, from = doc_number(d, thing, "start", 0, 0), lasts = doc_number(d, thing, "duration", 0, -1), to = lasts > 0.0 ? from + lasts : doc_seconds(d);
    std::vector<char> loud((size_t)std::max(0.0, std::ceil((to - from) * rate)), 0);
    bool any = false;
    for (const int t : doc_layers(d)) {
        if (t == thing || doc_word(d, t, "kind") != "video") continue;
        const std::vector<float>* all = loudness_of(doc_word(d, t, "file"), false);
        if (!all) return d.error = "the other sounds are not read yet", false;
        const double start = doc_number(d, t, "start", 0, 0), begin = doc_number(d, t, "begin", 0, 0), speed = doc_number(d, t, "speed", 0, 1), its = doc_number(d, t, "duration", 0, -1);
        for (size_t i = 0; i < loud.size(); ++i) {   // (the document's moment to the film's own, as motolii_loudness_over)
            const double s = from + (double)i / rate;
            const long k = std::lround((begin + (s - start) * speed) * 100.0);
            if (s >= start && (its <= 0.0 || s < start + its) && k >= 0 && k < (long)all->size() && (*all)[(size_t)k] > -30.f) loud[i] = any = true;
        }
    }
    if (!any) return d.error = "no other sound is louder than -30 dB while it plays", false;
    std::vector<std::pair<double, double>> runs;
    for (size_t i = 0; i < loud.size();) {
        if (!loud[i]) { ++i; continue; }
        size_t j = i;
        while (j < loud.size() && loud[j]) ++j;
        const double a = from + (double)i / rate, b = from + (double)j / rate;
        if (!runs.empty() && a - runs.back().second < 1.0) runs.back().second = b;   // (its Maximum Pause)
        else runs.push_back({a, b});
        i = j;
    }
    const double was = doc_number(d, thing, "volume", 0, 1), low = was * std::pow(10.0, -12.0 / 20.0);
    doc_act(d);
    for (const auto& [a, b] : runs)
        if (!(doc_key(d, thing, "volume", std::max(from, a - 0.5), was) && doc_key(d, thing, "volume", a, low) && doc_key(d, thing, "volume", b, low) && doc_key(d, thing, "volume", std::min(to, b + 0.5), was))) d.act_ok = false;
    return doc_acted(d);
}
int motolii_strikes(Motolii* m, int thing, double rise, int own, double* at, int room) {
    const std::string file = by_look(m, [=] { return doc_knows(doc(m), thing) && doc_word(*m->d, thing, "kind") == "video" ? doc_word(*m->d, thing, "file") : std::string(); });
    if (file.empty()) return 0;
    const std::vector<double> struck = sound_strikes(*loudness_of(file), 100.0, rise);
    if (own) {   // (in the film's own seconds, as its loudness is counted)
        for (int i = 0; i < room && i < (int)struck.size(); ++i) at[i] = struck[(size_t)i];
        return (int)struck.size();
    }
    return by_look(m, [&] {   // (the film's own seconds to the document's: from its start, from where it begins, at its speed, while it lasts)
        Doc& d = *m->d;
        const double start = doc_number(d, thing, "start", 0, 0), begin = doc_number(d, thing, "begin", 0, 0), speed = doc_number(d, thing, "speed", 0, 1), lasts = doc_number(d, thing, "duration", 0, -1);
        int n = 0;
        for (const double t : struck) {
            const double when = speed == 0.0 ? -1.0 : start + (t - begin) / speed;
            if (when < start || (lasts > 0.0 && when >= start + lasts)) continue;
            if (n < room) at[n] = when;
            ++n;
        }
        return n;
    });
}
