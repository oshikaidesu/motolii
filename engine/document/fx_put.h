// Putting effects on a layer, reordering them in its list and taking them off. Included by doc.h;
// not self-contained.
//
// One entry of the table below. The built-in effects of ThorVG are turned on by setting a
// property.
//   name   the name shown on the Effects shelf
//   value  the property that turns the effect on
//   on     what the property is set to when the effect is put on: a number, a word, or keyframes
//          written "keys t0 v0 t1 v1", which key value v0 at time t0 and v1 at time t1, counted
//          from the time the effect is put on. "keys 0 1 1 0" is 1 now and 0 a second later,
//          which draws Trim Paths on, the way it is mostly used in After Effects.
//   word   whether `on` is a word instead of a number
//   label  what the effect is for, as the --label: line of an effect file says
//   with   other properties set with the effect, written "name=number name:word". They are the
//          values the stage draws when the properties are unset, so the effect's card shows what
//          the stage does.
//   about  what the effect does, in words that the shelf search reads
struct DocEffect { const char* name; const char* value; const char* on; bool word; const char* label; const char* with = ""; const char* about = ""; };
static const DocEffect doc_effects[] = {
    {"Gaussian Blur", "blur", "12", false, "Light"},
    {"Drop Shadow", "shadow", "000000", true, "Light", "shadow_distance=10 shadow_angle=135 shadow_blur=10 shadow_opacity=0.5"},
    // Kept for projects that have it. The Glow on the shelf is the file am_lightglow.wgsl.
    {"Glow", "glow", "on", true, "", "glow_opacity=1"},
    {"Trim Paths", "trim", "keys 0 1 1 0", false, "Path"},
    // Lays one copy of the layer along the outline of the layer under it, as copies 1 with a
    // stagger lay one on an outline; see doc_place.
    {"Move Along Path", "copy_on_offset", "keys 0 0 1 1", false, "Path", "stagger=0.01", "Goes along the outline of the layer under it, end to end in a second. Alight Motion's Move Along Path"},
    {"Datamosh", "mosh", "1", false, "Glitch", "mosh_at=1"},
    {"Duotone", "tint", "1", false, "Color", "tint_black:1b1f5c tint_white:ff8a65"},
    {"Gradient Map", "tritone", "1", false, "Color", "tritone_shadow:1b1f5c tritone_midtone:c44569 tritone_highlight:ffd166"},
    // The fill of the layer is whatever is behind it, so the effects on the layer work on the
    // background in the layer's shape. The layer still blends with what is under it as its blend
    // mode says. This is the Adjustment Layer of After Effects, as one more effect.
    {"Background Copy", "fill", "behind", true, "Utility", "", "Its fill is what is behind it: the effects on it work on the background in its shape. After Effects' Adjustment Layer"},
};
// Returns the effects of the shelf, one per line, each line holding these fields separated by
// tabs:
//   name, value, label, picture, two empty fields, about
// `picture` is thing_<value>.png in the library's effects/ folder, or "" when there is none.
// `about` is what the effect does; it is the 7th field of the result of motolii_effects.
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
// Sets the layer's effect list to `list`. An empty list unsets it. Returns false and sets d.error
// when the layer is a camera and `list` holds anything other than a .am motion.
static bool doc_fx_say(Doc& d, int layer, const std::vector<std::string>& list) {
    // A camera has no canvas to lay an effect on. It takes only the motions of AbsentMotion, which
    // move its place, as the camera of AbsentMotion is placed by its own motions. See
    // LayerView in camera.cpp and OwnAt, ApplyMotion in styles.cpp, both in
    // engine/third_party/AbsentMotion/app/src/main/cpp/.
    if (doc_word(d, layer, "kind") == "camera")
        for (const std::string& w : list)
            if (std::filesystem::path(w).extension() != ".am") return d.error = "a camera takes motions only (it has no picture of its own): " + doc_fx_title(w) + " is an effect", false;
    if (!list.empty()) return doc_say(d, layer, "fx", doc_fx_join(list).c_str());
    return !doc_knows(d, layer, "fx") || doc_word(d, layer, "fx").empty() || doc_change(d, sqlite3_mprintf("delete from keyframe where layer = %d and name = 'fx'", layer));
}
// Puts an effect file at the end of the layer's effect list, or takes it out if it is already in
// the list. This is one undo step.
//
// Taking an effect out also deletes the keyframes and values of its parameters, as deleting an
// effect does in After Effects and Alight Motion, so that putting it on again starts fresh.
// Turning the effect off with its eye, fx_off, keeps them, as in Alight Motion.
//
// `now` is the time at which a transition is put on, or NAN when there is none. A transition runs
// from that time: its progress is keyed 0 then and 1 a second later, so the layer goes away and
// what is under it shows. This is how the transition effects of After Effects take a layer away,
// with Transition Completion from 0 to 100%, and how its transition presets lay keys from the
// current time. A second is the default length of a transition in editors such as Premiere Pro
// and Final Cut Pro, which uses 30 frames. The user can make it longer or shorter by moving the
// keys.
//
// A transition is an ISF effect, see ISF_Spec. It has a progress input and an endImage input
// for the image it goes to.
static bool doc_fx_file(Doc& d, int layer, const char* file, double now = NAN) {
    std::vector<std::string> list = doc_fx_list(d, layer, true);
    const auto at = std::find(list.begin(), list.end(), file);
    const bool out = at != list.end();
    if (out) list.erase(at);
    else list.push_back(file);
    doc_act(d);
    if (!doc_fx_say(d, layer, list)) d.act_ok = false;
    if (const DocScript* sc = out ? doc_script_of(d, file) : nullptr)
        for (const std::string& n : sc->names)
            if (!doc_change(d, sqlite3_mprintf("delete from keyframe where layer = %d and name = %Q", layer, n.c_str()))) d.act_ok = false;
    // A transition put on at the layer's own start comes in instead of going out: its progress
    // runs from 1 to 0, and what is under the layer gives way to it. Premiere Pro does the same:
    // a transition on the head edge of a clip brings the clip in, and one on its tail edge takes
    // it out.
    // "At the start" means within half a frame at the stage's 60 frames per second; see RATE in
    // entry/render_thread.h.
    const bool in = !std::isnan(now) && std::fabs(now - doc_number(d, layer, "start", 0, 0)) < 0.5 / 60.0;
    if (const DocScript* sc = !out && !std::isnan(now) ? doc_script_of(d, file) : nullptr)
        if (std::any_of(sc->parameters.begin(), sc->parameters.end(), [](const ScriptParameter& k) { return k.name == "endImage"; }))
            for (size_t i = 0; i < sc->parameters.size(); ++i)
                if (sc->parameters[i].name == "progress" && !(doc_key(d, layer, sc->names[i].c_str(), now, in ? 1.0 : 0.0) && doc_key(d, layer, sc->names[i].c_str(), now + 1.0, in ? 0.0 : 1.0))) d.act_ok = false;
    return doc_acted(d);
}
// Moves one of the layer's effects by `by` places in its list, like dragging an effect up or down
// the stack in After Effects. The effect is a file, or a built-in ThorVG effect named by its
// property, or either one named by its card title. This is one undo step.
static bool doc_fx_move(Doc& d, int layer, const char* name, int by) {
    std::vector<std::string> list = doc_fx_list(d, layer, true);
    auto at = std::find(list.begin(), list.end(), name);
    if (at == list.end()) at = std::find_if(list.begin(), list.end(), [&](const std::string& w) { return doc_fx_title(w) == name; });
    if (at == list.end()) return d.error = std::string(name) + " is not among its effects", false;
    const int from = (int)(at - list.begin()), to = std::clamp(from + by, 0, (int)list.size() - 1);
    if (from == to) return true;
    const std::string one = list[(size_t)from];
    list.erase(list.begin() + from);
    list.insert(list.begin() + to, one);
    doc_act(d);
    if (!doc_fx_say(d, layer, list)) d.act_ok = false;
    return doc_acted(d);
}
// Puts the shelf effect `name` on the layer at time `at`, or takes it off if it is already on.
// Taking it off unsets its property and its keyframes. This is one undo step.
static bool doc_effect(Doc& d, int layer, const char* name, double at) {
    for (const DocEffect& e : doc_effects) {
        if (strcmp(e.name, name)) continue;
        // For the fill effect, "on" means that the fill is this one.
        const bool on = !strcmp(e.value, "fill") ? doc_word(d, layer, "fill") == e.on : doc_on(d, layer, e.value);
        // A built-in effect is added at the end of the layer's list, as After Effects does, or
        // removed from it.
        std::vector<std::string> list = doc_fx_list(d, layer, true);
        doc_act(d);
        bool ok;
        // Taking it off unsets the property, which restores the state before it was put on.
        if (on) ok = doc_knows(d, layer, e.value) && doc_change(d, sqlite3_mprintf("delete from keyframe where layer = %d and name = %Q", layer, e.value));
        else if (!strncmp(e.on, "keys ", 5)) {
            double a0 = 0, v0 = 0, a1 = 0, v1 = 0;
            ok = std::sscanf(e.on + 5, "%lf %lf %lf %lf", &a0, &v0, &a1, &v1) == 4 && doc_key(d, layer, e.value, at + a0, v0) && doc_key(d, layer, e.value, at + a1, v1);
        } else ok = e.word ? doc_say(d, layer, e.value, e.on) : doc_set(d, layer, e.value, std::atof(e.on));
        std::istringstream with(e.with);
        // Set the other properties of the effect to the values the stage draws when they are unset.
        for (std::string one; !on && ok && with >> one;) {
            const size_t at_ = one.find_first_of("=:");
            if (at_ == std::string::npos) continue;
            const std::string n = one.substr(0, at_), v = one.substr(at_ + 1);
            const bool said = one[at_] == '=' ? !std::isnan(doc_number(d, layer, n.c_str(), at, NAN)) : !doc_word(d, layer, n.c_str()).empty();
            // A property that is already set, by the user or earlier, is left as it is.
            if (!said) ok = one[at_] == '=' ? doc_set(d, layer, n.c_str(), std::atof(v.c_str())) : doc_say(d, layer, n.c_str(), v.c_str());
        }
        // Move Along Path copies the layer immediately beneath it, as in Alight Motion. Taking
        // the effect off clears that.
        if (ok && !strcmp(e.value, "copy_on_offset")) {
            const std::vector<int> lie = doc_laid(d);
            const auto at_ = std::find(lie.begin(), lie.end(), layer);
            if (on) ok = doc_change(d, sqlite3_mprintf("delete from keyframe where layer = %d and name in ('copy_on', 'stagger')", layer));
            else if (at_ != lie.begin() && at_ != lie.end()) ok = doc_set(d, layer, "copy_on", *(at_ - 1));
        }
        if (ok && doc_thor_letter(e.value)) {
            if (const auto had = std::find(list.begin(), list.end(), e.value); had != list.end()) list.erase(had);
            if (!on) list.push_back(e.value);
            ok = doc_fx_say(d, layer, list);
        }
        if (!ok) d.act_ok = false;
        return doc_acted(d);
    }
    d.error = std::string("no effect is called ") + name;
    return false;
}
// Turns one of the layer's effects off, or back on, like the eye on an effect in Alight Motion.
// The effect is named by its card title. Its values are kept.
static bool doc_fx_eye(Doc& d, int layer, const char* title) {
    const std::vector<std::string> list = doc_fx_list(d, layer, true);
    if (std::none_of(list.begin(), list.end(), [&](const std::string& w) { return doc_fx_title(w) == title; })) return d.error = std::string(title) + " is not among its effects", false;
    const bool was = (";" + doc_word(d, layer, "fx_off") + ";").find(";" + std::string(title) + ";") != std::string::npos;
    std::vector<std::string> off;
    std::istringstream said(doc_word(d, layer, "fx_off"));
    for (std::string one; std::getline(said, one, ';');) if (!one.empty() && one != title) off.push_back(one);
    if (!was) off.push_back(title);
    std::string all;
    for (const std::string& one : off) all += (all.empty() ? "" : ";") + one;
    return doc_say(d, layer, "fx_off", all.c_str());
}
// Takes one of the layer's effects off, named by its card title or its own name. This is what the
// shelf does when the effect is pressed again, and what Delete does on an effect card in Alight
// Motion. An effect file is removed from the list, see doc_fx_file. A built-in ThorVG effect is
// unset, see doc_effect. This is one undo step.
static bool doc_fx_out(Doc& d, int layer, const char* name) {
    const std::vector<std::string> list = doc_fx_list(d, layer, true);
    auto at = std::find(list.begin(), list.end(), name);
    if (at == list.end()) at = std::find_if(list.begin(), list.end(), [&](const std::string& w) { return doc_fx_title(w) == name; });
    if (at == list.end()) return d.error = std::string(name) + " is not among its effects", false;
    if (!doc_thor_letter(*at)) return doc_fx_file(d, layer, at->c_str());
    for (const DocEffect& e : doc_effects) if (*at == e.value) return doc_effect(d, layer, e.name, 0.0);
    return d.error = *at + " is put on by no effect", false;
}
