// time_edit.h: part of doc.h (a layer's time edited: keys moved, cut, taken out, laid in turn, stretched; reset, undo). Read only through doc.h.
// A layer's keys moved by so many seconds, every value's that has keys (as After Effects moves a layer's).
static bool doc_keys_by(Doc& d, int layer, double by) {
    return doc_change(d, sqlite3_mprintf("update keyframe set at = at + %!.17g where layer = %d and name in (select name from keyframe where layer = %d group by name having count(*) > 1 or max(at) <> 0 or max(easing) is not null);"
                                         "update keyframe set at = at - 1e7 where layer = %d and at >= 5e6", 1e7 + by, layer, layer, layer));   // (by way of far off: no key lands on one not yet moved)
}
static double doc_lasts(Doc& d, int layer);
// What was made again laid just above what it came from: a copy is made on top of all (After Effects' Duplicate and
// Split Layer; AbsentMotion's duplicateSelected, addAbove).
static bool doc_lay_above(Doc& d, int made, int layer) {
    doc_forget(d);
    const std::vector<int> lie = doc_laid(d);
    const long from = std::find(lie.begin(), lie.end(), made) - lie.begin(), under = std::find(lie.begin(), lie.end(), layer) - lie.begin();
    return from == under + 1 || doc_raise(d, made, (int)(under + (from > under ? 1 : 0) - from));
}
static int doc_copy_above(Doc& d, int layer) {
    doc_act(d);
    const int made = doc_duplicate(d, layer);
    const bool ok = made && doc_lay_above(d, made, layer);
    return doc_acted(d) && ok ? made : 0;
}
// A layer cut in two at a moment (Ableton Live's Split, Cmd+E; AbsentMotion's Scene.splitAt): it ends there, and a copy
// of it (every keyframe, its keys staying where they are on the stage) begins there, a film's copy as far on in the film as
// the head's trim takes it (above), lying just above it. One step to undo; the answer is the copy, as duplicate's.
static int doc_split(Doc& d, int layer, double at) {
    if (doc_knows(d, layer) && doc_number(d, layer, "lock", 0, 0) > 0.5) return d.error = "it is locked", 0;
    const double start = doc_number(d, layer, "start", 0, 0), lasts = doc_number(d, layer, "duration", 0, -1), end = lasts > 0.0 ? start + lasts : doc_seconds(d);
    if (!(at > start + 1e-3 && at < end - 1e-3)) return d.error = "the moment is not inside it", 0;
    doc_act(d);
    const int made = doc_duplicate(d, layer);
    bool ok = made && doc_set(d, layer, "duration", at - start) && doc_set(d, made, "start", at) && doc_set(d, made, "duration", end - at);
    if (const double on = doc_own_clock(d, layer, at - start); ok && on != 0.0) ok = doc_set(d, made, "begin", doc_number(d, layer, "begin", 0, 0) + on);
    ok = ok && doc_lay_above(d, made, layer);   // (the part after lies just above the part before, as After Effects' Split Layer puts the new layer)
    return doc_acted(d) && ok ? made : 0;
}
// The work area taken out and the gap closed (After Effects' Edit > Extract Work Area; Premiere Pro's Extract, DaVinci
// Resolve's Ripple Delete): every layer across one of its edges cut there (doc_split, a film's part after as far on in
// the film), the parts within it taken away, and all after it brought back by its length, their keys with them; the
// marks within it taken away and those after it brought back too, as Premiere Pro's Extract does with Ripple Sequence
// Markers on (its markers after an edit move with the ripple; from 25.3 those in the part extracted are cleared). One
// step (golf (72), P18: 20 seconds made 15 by taking 5 out of the middle, the hits' marks kept on their hits).
static bool doc_extract(Doc& d) {
    double in = 0.0, out = 0.0;
    doc_work(d, &in, &out);
    const double gap = out - in, all = doc_seconds(d);
    if (!(gap > 1e-3) || (in < 1e-3 && out > all - 1e-3)) return d.error = "the work area is all of it: set it to the part to take out", false;
    std::vector<int> layers;
    doc_rows(d, sqlite3_mprintf("select layer from keyframe where layer <> 0 and name = 'kind' and value <> 'behaviour' order by layer"), [&](sqlite3_stmt* row) { layers.push_back(sqlite3_column_int(row, 0)); });   // (a relation has no time of its own)
    doc_act(d);
    bool ok = true;
    for (const int t : layers) {
        const double s = doc_number(d, t, "start", 0, 0), lasts = doc_number(d, t, "duration", 0, -1), e = lasts > 0.0 ? s + lasts : all;
        int after = s >= out - 1e-3 ? t : 0;   // (the part after the work area, brought back)
        if (!after && e > out + 1e-3) ok = ok && (after = doc_split(d, t, out)) != 0;
        if (s < in - 1e-3 && e > in + 1e-3) { const int within = doc_split(d, t, in); ok = ok && within && doc_remove(d, within); }
        else if (s >= in - 1e-3 && s < out - 1e-3) ok = ok && doc_remove(d, t);
        if (after) ok = ok && doc_set(d, after, "start", doc_number(d, after, "start", 0, 0) - gap) && doc_keys_by(d, after, -gap);
        if (!ok) break;
    }
    ok = ok && doc_change(d, sqlite3_mprintf("delete from keyframe where layer = 0 and name in ('mark', 'mark_colour') and at >= %!.17g and at < %!.17g;"
                                             "update keyframe set at = at + %!.17g where layer = 0 and name in ('mark', 'mark_colour') and at >= %!.17g;"
                                             "update keyframe set at = at - 1e7 where layer = 0 and name in ('mark', 'mark_colour') and at >= 5e6", in - 1e-9, out - 1e-9, 1e7 - gap, out - 1e-9));   // (by way of far off, as doc_keys_by: none lands on one not yet moved)
    if (!ok) d.act_ok = false;
    return doc_acted(d);
}
static bool doc_let_go(Doc& d, bool keep) {
    const Doc::Held h = d.held;
    d.held = Doc::Held{};
    if (h.layer < 0) return d.error = "nothing is held", false;
    if (!keep || (h.tried.empty() && h.said.empty())) return doc_match(d), doc_evaluate(d, d.stage->now), true;   // (made again as the document has it)
    doc_act(d);   // (all that was carried is one step: a value that takes keys by the rule of a value changed at a moment, any other as the value it is)
    for (const auto& [name, is] : h.tried) {
        bool moves = false;
        for (const DocValue& one : doc_values) moves = moves || (one.moves && name == one.name);
        if (!moves && name.rfind("js_", 0) == 0)   // (a knob of one of its scripts, an effect's, as doc_knows finds it: one that takes keys as its file says, a track;
            //  else it was set, unkeyed, every key it had taken away: golf_noise.md 44)
            for (const DocScript* sc : doc_scripts_on(d, h.layer))
                for (const DocValue& one : sc->values) moves = moves || (one.moves && name == one.name);
        if (!(moves ? doc_put(d, h.layer, name.c_str(), d.stage->now, is) : doc_set(d, h.layer, name.c_str(), is))) break;
    }
    for (const auto& [name, is] : h.said) if (name[0] != ' ' && !doc_say(d, h.layer, name.c_str(), is.c_str())) break;   // (' path': what it was, kept with the hold)
    const auto bar = h.from.find(" bar"), start = h.tried.find("start");
    if (bar != h.from.end() && start != h.tried.end() && start->second != h.from.at("start")) {
        const double by = start->second - h.from.at("start");
        doc_keys_by(d, h.layer, by);
        for (const int t : doc_under(d, h.layer)) {   // (a group's bar slid: what it holds goes with it, as a precomposed layer's inside goes with its bar)
            doc_set(d, t, "start", std::max(0.0, doc_number(d, t, "start", 0, 0) + by));
            doc_keys_by(d, t, by);
        }
    }
    return doc_acted(d);
}
// Sequence Layers (After Effects' Keyframe Assistant): the layers that have a length and stand on their own (shown,
// not locked, going with no other, not a camera or a light), from the front of the stack, each beginning where the
// one before ends less `overlap` seconds, on a frame of `rate`, never before the one before; the first where it is.
// Each moved whole, its keys with it. One step.
static bool doc_sequence(Doc& d, double overlap, double rate) {
    std::vector<int> order;
    const std::vector<int> laid = doc_laid(d);
    for (auto t = laid.rbegin(); t != laid.rend(); ++t) {
        const std::string kind = doc_word(d, *t, "kind");
        if (kind != "camera" && kind != "light" && doc_number(d, *t, "visible", 0, 1) > 0.5 && doc_number(d, *t, "lock", 0, 0) <= 0.5 && doc_number(d, *t, "parent", 0, 0) == 0.0 && doc_lasts(d, *t) > 0.0) order.push_back(*t);
    }
    if (order.size() < 2) return d.error = "two layers that have a length are needed to follow one another", false;
    const auto frame = [&](double s) { return std::round(s * rate) / rate; };
    double at = frame(doc_number(d, order[0], "start", 0, 0));
    doc_act(d);
    bool ok = true;
    for (const int t : order) {
        const double was = doc_number(d, t, "start", 0, 0), lasts = doc_lasts(d, t);
        if (std::fabs(at - was) > 1e-9) ok = ok && doc_set(d, t, "start", at) && doc_keys_by(d, t, at - was);
        at = std::max(at, frame(at + lasts - overlap));
    }
    if (!ok) d.act_ok = false;
    return doc_acted(d) && ok;
}
// The picked layers lined up in time (Alight Motion's timing: Extend Start, Move to Playhead, Align Left, Stagger,
// Align Right): starts to the earliest; ends to the latest; each to begin at the playhead; one after another in the
// order picked; or its start brought to the playhead either way, its end staying (Final Cut Pro's Extend Edit; a film from as far in it as the head's
// trim takes it). A layer moved takes its keys with it, as Sequence moves them. One step.
static bool doc_time_align(Doc& d, const std::vector<int>& layers, const std::string& how, double now) {
    if (layers.empty()) return d.error = "nothing to line up", false;
    const double whole = doc_seconds(d);
    const auto lasting = [&](int t) { return doc_lasts(d, t) > 0.0 ? doc_lasts(d, t) : std::max(1e-3, whole - doc_number(d, t, "start", 0, 0)); };   // (no length said, as a layer drawn in the window has: to the document's end, as doc_time_stretch reads it)
    double first = 1e18, last = -1e18;
    for (const int t : layers) first = std::min(first, doc_number(d, t, "start", 0, 0)), last = std::max(last, doc_number(d, t, "start", 0, 0) + lasting(t));
    doc_act(d);
    bool ok = true;
    double after = doc_number(d, layers[0], "start", 0, 0);
    for (const int t : layers) {
        if (!ok) break;
        const double was = doc_number(d, t, "start", 0, 0), lasts = lasting(t);
        double to = was;
        if (how == "start") to = first;
        else if (how == "end") to = last - lasts;
        else if (how == "playhead") to = now;
        else if (how == "playhead_end") to = now - lasts;
        else if (how == "stagger") to = after, after += lasts;
        else if (how == "extend") {
            if (now >= was + lasts - 1e-3) continue;   // (the playhead past its end: nothing to draw out to)
            ok = doc_set(d, t, "start", std::max(0.0, now)) && doc_set(d, t, "duration", was + lasts - std::max(0.0, now));
            if (const double on = doc_own_clock(d, t, std::max(0.0, now) - was); ok && on != 0.0) ok = doc_set(d, t, "begin", std::max(0.0, doc_number(d, t, "begin", 0, 0) + on));
            continue;
        } else if (how == "trim_end") {   // (Final Cut Pro's Trim End: its end to the playhead, the playhead inside it)
            if (now > was + 1e-3 && now < was + lasts - 1e-3) ok = doc_set(d, t, "duration", now - was);
            continue;
        } else { ok = false, d.error = "lined up by start, end, playhead, playhead_end, stagger, extend or trim_end"; break; }
        to = std::max(0.0, to);
        if (std::fabs(to - was) > 1e-9) ok = doc_set(d, t, "start", to) && doc_keys_by(d, t, to - was);
    }
    if (!ok) d.act_ok = false;
    return doc_acted(d) && ok;
}
// A layer made to go at another speed, held in place at its start, at a moment, or at its end (After Effects' Time
// Stretch: Hold in place Layer In-point, Current Frame, Layer Out-point; Pinnacle Studio's speed anchor): it lasts as
// much longer as it goes slower, and its keys are stretched with it round that place; a film plays the same stretch of
// itself. One step.
static bool doc_time_stretch(Doc& d, int layer, double speed, const std::string& hold, double now) {
    const double was = std::fabs(doc_number(d, layer, "speed", 0, 1)), to = std::fabs(speed);
    if (to < 1e-3) return d.error = "a speed of nothing goes nowhere", false;
    if (hold != "start" && hold != "now" && hold != "end") return d.error = "held at start, now or end", false;
    const double start = doc_number(d, layer, "start", 0, 0), lasts = doc_lasts(d, layer) > 0.0 ? doc_lasts(d, layer) : std::max(1e-3, doc_seconds(d) - start), f = was / to;   // (no length said: to the document's end, as doc_split counts it)
    const double at = hold == "start" ? start : hold == "end" ? start + lasts : std::clamp(now, start, start + lasts);
    doc_act(d);
    bool ok = doc_set(d, layer, "speed", speed) && doc_set(d, layer, "start", std::max(0.0, at + (start - at) * f)) && doc_set(d, layer, "duration", lasts * f)
           && doc_change(d, sqlite3_mprintf("update keyframe set at = 1e7 + %!.17g + (at - %!.17g) * %!.17g where layer = %d and name in (select name from keyframe where layer = %d group by name having count(*) > 1 or max(at) <> 0 or max(easing) is not null);"
                                            "update keyframe set at = at - 1e7 where layer = %d and at >= 5e6", at, at, f, layer, layer, layer));   // (by way of far off, as doc_keys_by: no key lands on one not yet moved)
    if (!ok) d.act_ok = false;
    return doc_acted(d) && ok;
}
// A layer's named values as they come (After Effects' Reset on a group of values): what was said of them and their keys
// forgotten; one step.
static bool doc_reset(Doc& d, int layer, const std::string& names) {
    doc_act(d);
    bool ok = true;
    std::istringstream said(names);
    for (std::string n; ok && said >> n;) ok = doc_knows(d, layer, n.c_str()) && doc_change(d, sqlite3_mprintf("delete from keyframe where layer = %d and name in (%Q, %Q)", layer, n.c_str(), (n + "_loop").c_str()));
    if (!ok) d.act_ok = false;
    return doc_acted(d) && ok;
}
static bool doc_undo(Doc& d) { return doc_undo_step(d, true); }
static bool doc_redo(Doc& d) { return doc_undo_step(d, false); }
