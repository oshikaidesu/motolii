// fx_put.h: part of doc.h (effects put on a thing, moved in its list, taken off). Read only through doc.h.
// The effects a thing may be given (the Effects shelf; their cards are doc_cards' "+" rows): a name, the value that puts
// it on (ThorVG's own), and what it is told then: a number, a word, or keys from that moment ("keys 0 1 1 0": 1 now,
// 0 a second on: Trim Paths drawn on, as After Effects' is mostly used). [with]: the card's other values said with it, as
// it is drawn when they are not said (doc_moment's own), so its card shows what the stage does ("name=number name:word").
struct DocEffect { const char* name; const char* value; const char* on; bool word; const char* label; const char* with = ""; const char* about = ""; };   // (label: what it is for, as an effect file's --label: says; about: what it does, in words the shelf's search reads)
static const DocEffect doc_effects[] = {
    {"Gaussian Blur", "blur", "12", false, "Light"},
    {"Drop Shadow", "shadow", "000000", true, "Light", "shadow_distance=10 shadow_angle=135 shadow_blur=10 shadow_opacity=0.5"},
    {"Glow", "glow", "on", true, "", "glow_opacity=1"},   // (a document that has it; the shelf's Glow is the file am_lightglow.wgsl: golf (79))
    {"Trim Paths", "trim", "keys 0 1 1 0", false, "Path"},
    {"Move Along Path", "copy_on_offset", "keys 0 0 1 1", false, "Path", "stagger=0.01", "Goes along the outline of the layer under it, end to end in a second. Alight Motion's Move Along Path"},   // (one copy of itself, as copies 1 and a stagger lay one on an outline: doc_place)
    {"Datamosh", "mosh", "1", false, "Glitch", "mosh_at=1"},
    {"Duotone", "tint", "1", false, "Color", "tint_black:1b1f5c tint_white:ff8a65"},
    {"Gradient Map", "tritone", "1", false, "Color", "tritone_shadow:1b1f5c tritone_midtone:c44569 tritone_highlight:ffd166"},
    {"Background Copy", "fill", "behind", true, "Utility", "", "Its fill is what is behind it: the effects on it work on the background in its shape. After Effects' Adjustment Layer"},   // (its fill what is behind it: the effects on it then work on the background in its shape, and it still lies on what is under as its blend says; After Effects' adjustment layer as one more effect)
};
// The shelf's effects, "name\tvalue\tlabel\tpicture\t\t\tabout" one to a line (picture: thing_<value>.png in the library's effects/, "" none;
// about: what it does, as a file's description is the 7th of motolii_effects').
static std::string doc_effect_names() {
    std::string all;
    std::error_code wrong;
    for (const DocEffect& e : doc_effects) {
        if (!*e.label) continue;
        const std::filesystem::path picture = script_shelf_file((doc_folders("effects").front() / ("thing_" + std::string(e.value) + ".png")).string());
        all += (all.empty() ? "" : "\n") + std::string(e.name) + "\t" + e.value + "\t" + e.label + "\t" + (std::filesystem::exists(picture, wrong) ? picture.string() : "") + "\t\t\t" + e.about;
    }
    return all;
}
// An effect put on a thing at a moment, or taken off it if it is on (unsaid, its keys too), one step.
// A thing's list of effects said as it now is (none: unsaid).
static bool doc_fx_say(Doc& d, int thing, const std::vector<std::string>& list) {
    // (a camera has no picture to lay an effect on: it takes AbsentMotion's motions, which move its place, as
    //  AbsentMotion's camera is placed by its own motions (camera.cpp LayerView, styles.cpp OwnAt: ApplyMotion); golf ㊴)
    if (doc_word(d, thing, "kind") == "camera")
        for (const std::string& w : list)
            if (std::filesystem::path(w).extension() != ".am") return d.trouble = "a camera takes motions only (it has no picture of its own): " + doc_fx_title(w) + " is an effect", false;
    if (!list.empty()) return doc_say(d, thing, "fx", doc_fx_join(list).c_str());
    return !doc_knows(d, thing, "fx") || doc_word(d, thing, "fx").empty() || doc_change(d, sqlite3_mprintf("delete from fact where thing = %d and name = 'fx'", thing));
}
// An effect file put at the end of a thing's effects, or taken out if it is among them (one step). Taken out, its knobs'
// values and keys go with it, as After Effects' and Alight Motion's effect deleted takes its keyframes (golf P15,
// golf_noise.md (67): put on again, the old keys came back); its eye (fx_off) keeps them, as Alight Motion's does.
// A transition put on at a moment (`now`; NAN: none said) runs there: its progress keyed 0 then and 1 a second after, so
// the thing goes and what is under it shows, as After Effects' transition effects take a layer away (Transition
// Completion 0 to 100%) and its transition presets lay their keys from the current time; a second, the editors' own
// length of a transition (Premiere Pro's default, Final Cut Pro's 30 frames), pulled longer or shorter by its keys.
// A transition is ISF's (ISF_Spec): its progress, and the endImage it goes to (golf (65): two keys a value by hand).
static bool doc_fx_file(Doc& d, int thing, const char* file, double now = NAN) {
    std::vector<std::string> list = doc_fx_list(d, thing, true);
    const auto at = std::find(list.begin(), list.end(), file);
    const bool out = at != list.end();
    if (out) list.erase(at);
    else list.push_back(file);
    doc_act(d);
    if (!doc_fx_say(d, thing, list)) d.act_ok = false;
    if (const DocScript* sc = out ? doc_script_of(d, file) : nullptr)
        for (const std::string& n : sc->names)
            if (!doc_change(d, sqlite3_mprintf("delete from fact where thing = %d and name = %Q", thing, n.c_str()))) d.act_ok = false;
    // (put on at the thing's own start, it comes in instead: 1 to 0, what is under it giving way to it, as Premiere Pro's
    //  transition on a clip's head edge brings the clip in and one on its tail takes it out: P16, the next scene wiped in)
    const bool in = !std::isnan(now) && std::fabs(now - doc_number(d, thing, "start", 0, 0)) < 0.5 / 60.0;   // (within half a frame of the stage's 60, entry/render_thread.h RATE)
    if (const DocScript* sc = !out && !std::isnan(now) ? doc_script_of(d, file) : nullptr)
        if (std::any_of(sc->knobs.begin(), sc->knobs.end(), [](const ScriptKnob& k) { return k.name == "endImage"; }))
            for (size_t i = 0; i < sc->knobs.size(); ++i)
                if (sc->knobs[i].name == "progress" && !(doc_key(d, thing, sc->names[i].c_str(), now, in ? 1.0 : 0.0) && doc_key(d, thing, sc->names[i].c_str(), now + 1.0, in ? 0.0 : 1.0))) d.act_ok = false;
    return doc_acted(d);
}
// One of a thing's effects (a file, or ThorVG's own by its value's name) moved `by` places in its list, After Effects'
// dragging an effect up or down its stack (one step).
static bool doc_fx_move(Doc& d, int thing, const char* name, int by) {
    std::vector<std::string> list = doc_fx_list(d, thing, true);
    auto at = std::find(list.begin(), list.end(), name);
    if (at == list.end()) at = std::find_if(list.begin(), list.end(), [&](const std::string& w) { return doc_fx_title(w) == name; });   // (or by its card's title)
    if (at == list.end()) return d.trouble = std::string(name) + " is not among its effects", false;
    const int from = (int)(at - list.begin()), to = std::clamp(from + by, 0, (int)list.size() - 1);
    if (from == to) return true;
    const std::string one = list[(size_t)from];
    list.erase(list.begin() + from);
    list.insert(list.begin() + to, one);
    doc_act(d);
    if (!doc_fx_say(d, thing, list)) d.act_ok = false;
    return doc_acted(d);
}
static bool doc_effect(Doc& d, int thing, const char* name, double at) {
    for (const DocEffect& e : doc_effects) {
        if (strcmp(e.name, name)) continue;
        const bool on = !strcmp(e.value, "fill") ? doc_word(d, thing, "fill") == e.on : doc_on(d, thing, e.value);   // (a fill: on when it is this one)
        std::vector<std::string> list = doc_fx_list(d, thing, true);   // (ThorVG's own in the thing's list: put on at its end, as After Effects does, or out)
        doc_act(d);
        bool ok;
        if (on) ok = doc_knows(d, thing, e.value) && doc_change(d, sqlite3_mprintf("delete from fact where thing = %d and name = %Q", thing, e.value));   // (unsaid: as it was before it was put on)
        else if (!strncmp(e.on, "keys ", 5)) {
            double a0 = 0, v0 = 0, a1 = 0, v1 = 0;
            ok = std::sscanf(e.on + 5, "%lf %lf %lf %lf", &a0, &v0, &a1, &v1) == 4 && doc_key(d, thing, e.value, at + a0, v0) && doc_key(d, thing, e.value, at + a1, v1);
        } else ok = e.word ? doc_say(d, thing, e.value, e.on) : doc_set(d, thing, e.value, std::atof(e.on));
        std::istringstream with(e.with);
        for (std::string one; !on && ok && with >> one;) {   // (its other values, as they are drawn unsaid)
            const size_t at_ = one.find_first_of("=:");
            if (at_ == std::string::npos) continue;
            const std::string n = one.substr(0, at_), v = one.substr(at_ + 1);
            const bool said = one[at_] == '=' ? !std::isnan(doc_number(d, thing, n.c_str(), at, NAN)) : !doc_word(d, thing, n.c_str()).empty();
            if (!said) ok = one[at_] == '=' ? doc_set(d, thing, n.c_str(), std::atof(v.c_str())) : doc_say(d, thing, n.c_str(), v.c_str());   // (one said already, by a hand or before, is left as it is)
        }
        if (ok && !strcmp(e.value, "copy_on_offset")) {   // (on the layer immediately beneath it, Alight Motion's; off, as it was)
            const std::vector<int> lie = doc_laid(d);
            const auto at_ = std::find(lie.begin(), lie.end(), thing);
            if (on) ok = doc_change(d, sqlite3_mprintf("delete from fact where thing = %d and name in ('copy_on', 'stagger')", thing));
            else if (at_ != lie.begin() && at_ != lie.end()) ok = doc_set(d, thing, "copy_on", *(at_ - 1));
        }
        if (ok && doc_thor_letter(e.value)) {
            if (const auto had = std::find(list.begin(), list.end(), e.value); had != list.end()) list.erase(had);
            if (!on) list.push_back(e.value);
            ok = doc_fx_say(d, thing, list);
        }
        if (!ok) d.act_ok = false;
        return doc_acted(d);
    }
    d.trouble = std::string("no effect is called ") + name;
    return false;
}
// One of a thing's effects (by its card's title, or its own name) taken off, as the shelf takes it off when pressed
// again: an effect file out of its list (doc_fx_file), one of ThorVG's own unsaid (doc_effect). Alight Motion's
// Delete on an effect's card (one step).
// One of its effects turned off, or on again (Alight Motion's eye on an effect): by its card's title, its values kept.
static bool doc_fx_eye(Doc& d, int thing, const char* title) {
    const std::vector<std::string> list = doc_fx_list(d, thing, true);
    if (std::none_of(list.begin(), list.end(), [&](const std::string& w) { return doc_fx_title(w) == title; })) return d.trouble = std::string(title) + " is not among its effects", false;
    const bool was = (";" + doc_word(d, thing, "fx_off") + ";").find(";" + std::string(title) + ";") != std::string::npos;
    std::vector<std::string> off;
    std::istringstream said(doc_word(d, thing, "fx_off"));
    for (std::string one; std::getline(said, one, ';');) if (!one.empty() && one != title) off.push_back(one);
    if (!was) off.push_back(title);
    std::string all;
    for (const std::string& one : off) all += (all.empty() ? "" : ";") + one;
    return doc_say(d, thing, "fx_off", all.c_str());
}
static bool doc_fx_out(Doc& d, int thing, const char* name) {
    const std::vector<std::string> list = doc_fx_list(d, thing, true);
    auto at = std::find(list.begin(), list.end(), name);
    if (at == list.end()) at = std::find_if(list.begin(), list.end(), [&](const std::string& w) { return doc_fx_title(w) == name; });
    if (at == list.end()) return d.trouble = std::string(name) + " is not among its effects", false;
    if (!doc_thor_letter(*at)) return doc_fx_file(d, thing, at->c_str());
    for (const DocEffect& e : doc_effects) if (*at == e.value) return doc_effect(d, thing, e.name, 0.0);
    return d.trouble = *at + " is put on by no effect", false;
}
