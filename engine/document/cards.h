// cards.h: part of doc.h (a layer's values as a shell lists them: names, words, ranges, cards). Read only through doc.h.
static bool doc_stay(Doc& d, int layer, const char* name, double at) {   // (its keys go: it stays what it is at that moment)
    return doc_knows(d, layer, name) && (!doc_keys(d, layer, name) || doc_set(d, layer, name, doc_number(d, layer, name, at, doc_usual(d, name))));
}
// The words a value of a layer may be (a blend's, a solid's shape), with spaces between ("": any word, or not a word).
static const DocValue* doc_script_value(Doc& d, int layer, const char* name) {   // (a knob of the layer's script)
    if (strncmp(name, "js_", 3)) return nullptr;
    for (const DocScript* sc : doc_scripts_on(d, layer))
        for (const DocValue& one : sc->values) if (!strcmp(one.name, name)) return &one;
    return nullptr;
}
static std::string doc_words(Doc& d, int layer, const char* name) {
    if (const DocValue* v = doc_script_value(d, layer, name)) return v->words ? v->words : "";
    const std::string kind = doc_word(d, layer, "kind");
    if (!strcmp(name, "animation") && kind == "solid") {   // (its file's own movements, as gltfio reads them)
        std::string all;
        if (const auto t = d.shown.find(layer); t != d.shown.end() && t->second.solid)
            for (const std::string& m : t->second.solid->moves) all += (all.empty() ? "" : " ") + m;
        return all;
    }
    if (!strcmp(name, "marker") && kind == "image") {   // (the named stretches of its file, as ThorVG reads them; any: all of it)
        std::string all = "all";
        if (const auto t = d.shown.find(layer); t != d.shown.end() && t->second.drawn)
            for (const std::string& m : t->second.drawn->markers) all += " " + m;
        return all;
    }
    for (const DocValue& one : doc_values)
        if (!strcmp(one.name, name) && doc_among(one.kinds, kind)) return one.words ? one.words : "";
    return "";
}
// What a layer is called where layers are listed: a text by its words, a shape by what shape it is, a file by its name.
static std::string doc_name(Doc& d, int layer) {
    if (const std::string said = doc_word(d, layer, "name"); !said.empty()) return said;
    if (doc_word(d, layer, "kind") == "camera") return "Camera";
    std::string is = doc_word(d, layer, "text");
    if (is.empty()) is = doc_word(d, layer, "shape");
    if (is.empty() && doc_word(d, layer, "kind") == "behaviour") {   // (a behaviour by its kind, a second of a kind told apart by its number, as Blender's .001)
        const std::string file = doc_word(d, layer, "file");
        int nth = 0, all = 0;
        for (const int t : doc_layers(d))
            if (doc_word(d, t, "kind") == "behaviour" && doc_word(d, t, "file") == file && doc_word(d, t, "name").empty()) { ++all; if (t <= layer) ++nth; }
        return all > 1 && nth > 1 ? file + " " + std::to_string(nth) : file;
    }
    if (is.empty() && doc_word(d, layer, "kind") == "light") is = doc_word(d, layer, "file");   // (Sun, as the tile says it)
    if (is.empty()) return std::filesystem::path(doc_word(d, layer, "file")).filename().string();
    if (doc_word(d, layer, "kind") != "text") is[0] = (char)std::toupper((unsigned char)is[0]);
    std::replace(is.begin(), is.end(), '\n', ' ');   // (a text of lines is listed on one)
    return is;
}
static std::string doc_moving(Doc& d, int layer) {
    const std::string kind = doc_word(d, layer, "kind");
    std::string names;
    for (const DocValue& one : doc_values)
        if (one.moves && doc_among(one.kinds, kind)) names += std::string(names.empty() ? "" : " ") + one.name;
    if (doc_among("video image text shape solid stage camera behaviour", kind))   // (and its scripts' knobs that take keys, an effect's tracks, as doc_has lists them: golf_noise.md 44)
        for (const DocScript* sc : doc_scripts_on(d, layer))
            for (const DocValue& one : sc->values) if (one.moves) names += std::string(names.empty() ? "" : " ") + one.name;
    return names;
}
// The names of all the values a layer has (from the values table: those of its kind), and a number's range.
static std::string doc_has(Doc& d, int layer) {
    const std::string kind = doc_word(d, layer, "kind");
    std::string names;
    for (const DocValue& one : doc_values)
        if (doc_among(one.kinds, kind)) names += std::string(names.empty() ? "" : " ") + one.name;
    if (doc_among("video image text shape solid stage camera behaviour", kind))
        for (const DocScript* sc : doc_scripts_on(d, layer))
            for (const DocValue& one : sc->values) names += std::string(names.empty() ? "" : " ") + one.name;
    return names;
}
// The cards of a layer: "title: name name; title: name" (those of its values its kind has; a card with none, left out).
static bool doc_on(Doc& d, int layer, const char* name);
// An effect of a layer's list as its card is called: ThorVG's own by its card's title (Gaussian Blur...), a file by its
// name made a title (halftone -> Halftone).
static std::string doc_fx_title(const std::string& name) {
    if (const std::string source = fx_source(name); source != name) {   // (one put on again: its file's name and its number, "Glow 2", a card of its own)
        const std::string stem = std::filesystem::path(name).stem().string();
        return doc_fx_title(source) + " " + stem.substr(stem.rfind('~') + 1);
    }
    if (doc_thor_letter(name))
        for (const DocCard& card : doc_cards) if (card.when && card.is[0] == '+' && name == card.when) return card.title;
    static std::map<std::string, std::pair<int, std::string>> named;   // (as the shelf names it: its head's own name, its maker's (doc_folder_names); read again once a file has changed)
    if (auto& one = named[name]; one.first == files_changed() && !one.second.empty()) return one.second;
    else if (std::ifstream in(isf_file(name)); in) {
        std::string first;
        if (std::getline(in, first) && first.rfind("// ", 0) == 0 && first.find(':') != std::string::npos) return (one = {files_changed(), first.substr(3, first.find(':') - 3)}).second;
    }
    std::string t = std::filesystem::path(name).stem().string();
    for (char& c : t) if (c == '_') c = ' ';
    if (!t.empty()) t[0] = (char)std::toupper((unsigned char)t[0]);
    return t;
}
// An effect of the layer (by its card's title) put on it again right after it, its values as they are, keys and all:
// Alight Motion's effect card ⋮ Duplicate (AbsentMotion's EffectsPanel: a copy of the effect with its params). Its
// word the file's with ~n before its ending ("Glow~2.fs": read as the file, fx_source), so its values are its own
// (a value's name is its word's: doc_screen_knob). An ISF or a .wgsl file's, or an expression's. The new word ("" none).
static std::string doc_fx_duplicate(Doc& d, int layer, const std::string& title) {
    std::vector<std::string> list = script_files(doc_word(d, layer, "fx"));
    const auto at = std::find_if(list.begin(), list.end(), [&](const std::string& w) { return doc_fx_title(w) == title; });
    if (at == list.end()) return d.error = "no effect of that name is on it", "";
    const std::string word = *at;
    const std::filesystem::path source(fx_source(word));
    if (source.extension() != ".fs" && source.extension() != ".wgsl" && !doc_expression(d, word)) return d.error = "only an ISF or a .wgsl effect or an expression is put on again so far", "";
    std::string made;
    for (int n = 2; made.empty() || std::find(list.begin(), list.end(), made) != list.end(); ++n) made = (source.parent_path() / (source.stem().string() + "~" + std::to_string(n) + source.extension().string())).string();
    list.insert(at + 1, made);
    std::string fx;
    for (const std::string& w : list) fx += (fx.empty() ? "" : " ") + w;
    const DocScript* script = doc_script_of(d, word);
    doc_act(d);
    bool ok = doc_say(d, layer, "fx", fx.c_str());
    if (script)
        for (size_t i = 0; i < script->parameters.size(); ++i)   // (from what its values are called: an expression's first, js_<knob>)
            ok = ok && doc_change(d, sqlite3_mprintf("insert or replace into keyframe select layer, %Q, at, value, easing from keyframe where layer = %d and name = %Q", doc_screen_parameter(made, script->parameters[i].name).c_str(), layer, script->names[i].c_str()));
    return doc_acted(d) && ok ? made : "";
}
// The titles of a layer's effect cards in the order its effects are laid ("Halftone;Gaussian Blur").
static std::string doc_fx_titles(Doc& d, int layer) {
    std::string all;
    for (const std::string& w : doc_fx_list(d, layer, true)) all += (all.empty() ? "" : ";") + doc_fx_title(w);   // (those turned off too: their cards are there)
    return all;
}
// (more: those of the "added" rows not put on: what a maker may ask for, not shown unasked)
static std::string doc_cards_of(Doc& d, int layer, std::string* more = nullptr) {
    const std::string has = " " + doc_has(d, layer) + " ";
    // (its effects' cards come under its own (Text, Fill, Transform, Blending...), before the cards of what it may do
    //  besides, Copies and on, as Premiere Pro's Effect Controls lays the effects put on under Motion and Opacity: they
    //  were under ten unused cards, four screens down; golf (58))
    std::string all, besides;
    std::map<std::string, std::string> effects;   // (ThorVG's own effects' cards by the value that puts each on: laid out as its list lays them)
    const bool behaviour = doc_word(d, layer, "kind") == "behaviour";
    bool past = false;
    for (const DocCard& card : doc_cards) {
        past = past || !strcmp(card.title, "Field");
        if (behaviour && !(card.when && !strcmp(card.when, "file"))) continue;   // (a behaviour: only its own card, not those of layers that happen to share a name with its knobs)
        if (card.when && card.is[0] == '+') {   // (an effect's card while it is on: doc_on)
            if (!doc_on(d, layer, card.when)) continue;
        } else if (card.when && card.is[0] == '@') {   // (a material's card while it wears one of those: doc_material; a solid unsaid, or a flat layer in depth, Filament's lit surface)
            std::string m = doc_material(d, layer);
            const std::string sp = doc_word(d, layer, "space");
            if (m.empty() && (doc_word(d, layer, "kind") == "solid" || sp == "3d" || sp == "2.5d" || doc_on(d, layer, "scale_z"))) m = "lit";
            if (m.empty() || !doc_among(card.is + 1, m)) continue;
        } else if (card.when && card.is[0] == '~') {   // (a ramp's card while the fill has more colours than one)
            if (doc_word(d, layer, card.when).find(card.is + 1) == std::string::npos) continue;
        } else if (card.when) {   // (a card for one fill and not another, or while it is clipped)
            const std::string w = doc_word(d, layer, card.when), want = card.is[0] == '!' ? card.is + 1 : card.is;
            char* end = nullptr;
            const double n = std::strtod(w.c_str(), &end);
            const bool is = w == want || (w.empty() && want == "0") || (!w.empty() && !*end && n == std::atof(want.c_str()) && !want.empty() && isdigit((unsigned char)want[0]));   // (a number not said is 0: a parent not given)
            if (is == (card.is[0] == '!')) continue;
        }
        std::string names;
        // (not there unasked: what a maker sees of a layer is Alight Motion's tiles for its kind (AbsentMotion's LayerTools.kt:
        //  Color & Fill, Blending, Transform, its Edit, Effects; a video's Speed), the rest asked for by More. The stage's own
        //  are asked for as a whole, by Stage settings)
        const std::string kindNow = doc_word(d, layer, "kind");
        bool said = !card.added || layer == 0 || (!strcmp(card.title, "Play") && kindNow == "video");
        for (const char* at = card.names; *at;) {
            const size_t len = strcspn(at, " ");
            const std::string n(at, len);
            said = said || !doc_word(d, layer, n.c_str()).empty() || doc_keys(d, layer, n.c_str());
            const bool still = (n == "animation" || n == "speed") && doc_word(d, layer, "kind") == "solid" && doc_words(d, layer, "animation").empty();   // (a solid with no movement of its own has none to play)
            if (has.find(" " + n + " ") != std::string::npos && !still) names += (names.empty() ? "" : " ") + n;
            at += len + (at[len] ? 1 : 0);
        }
        if (!names.empty() && !said && more) *more += (more->empty() ? "" : "; ") + std::string(card.title) + ": " + names;
        if (names.empty() || !said) continue;
        if (card.when && card.is[0] == '+' && doc_thor_letter(card.when)) effects[card.when] = std::string(card.title) + ": " + names;
        else (past ? besides : all) += ((past ? besides : all).empty() ? "" : "; ") + std::string(card.title) + ": " + names;
    }
    // (how many copies: first on the first expression's card, as After Effects' Repeater has its Copies and Cavalry's
    //  Duplicator its Count; the n of its each(i, n, t, k))
    bool copies = has.find(" copies ") == std::string::npos;
    std::string copied;   // (and the copies' own values, folded at its end: doc_shown's "Copies")
    for (const char* n : {"stagger", "stagger_from", "copy_fill", "copy_fill_way", "copy_opacity_end", "tall", "copy_tall"})
        if (has.find(" " + std::string(n) + " ") != std::string::npos) copied += std::string(" ") + n;
    if (layer != 0)   // (its effects, a card each, in the order they are laid: ThorVG's own and the files' alike)
        for (const std::string& w : doc_fx_list(d, layer, true)) {   // (those turned off too: their values are kept)
            std::string card;
            if (doc_thor_letter(w)) { if (const auto at = effects.find(w); at != effects.end()) card = at->second; }
            else {   // (a file's, with its knobs or none: its card is where its eye, its bin and its code are reached)
                if (const DocScript* sc = doc_script_of(d, w))
                    for (const DocValue& one : sc->values) card += (card.empty() ? "" : " ") + std::string(one.name);
                if (!copies && doc_expression(d, w)) card = "copies" + std::string(card.empty() ? "" : " ") + card + copied, copies = true;
                card = doc_fx_title(w) + ": " + card;
            }
            if (!card.empty()) all += (all.empty() ? "" : "; ") + card;
        }
    if (!besides.empty()) all += (all.empty() ? "" : "; ") + besides;
    if (doc_among("image text shape solid stage behaviour", doc_word(d, layer, "kind")))   // (its script's own card: the knobs its head declares)
        if (const std::vector<DocScript*> scs = doc_scripts_on(d, layer); !scs.empty()) {
            std::string names = layer == 0 ? "script follow" : "script";
            bool script_copied = false;
            if (const DocScript* own = doc_script_of(d, doc_word(d, layer, "script")); !copies && own && own->run && !own->run->sketch()) names += " copies", copies = true, script_copied = true;   // (its script lays its copies, each() or a Canvalry distribution, said by a name too ("Repeater"): how many on its card; a sketch paints, it lays none)
            for (const DocScript* sc : scs)
                if (layer == 0 || sc == doc_script_of(d, doc_word(d, layer, "script")) || (std::filesystem::path(doc_word(d, layer, "file")).extension() == ".js" && sc == doc_script_of(d, doc_word(d, layer, "file"), false)))   // (a layer's effect files have cards of their own, above; a sketch's lines that draw are its picture's)
                for (const DocValue& one : sc->values)
                    if ((" " + names + " ").find(" " + std::string(one.name) + " ") == std::string::npos) names += std::string(" ") + one.name;   // (a knob two effects share is one)
            if (script_copied) names += copied;   // (at its end, after its own knobs)
            if (names != "script") all += (all.empty() ? "" : "; ") + std::string("Script: ") + names;   // (none of them with knobs: no card)
        }
    return all;
}
static bool doc_range(Doc& d, int layer, const char* name, double* low, double* high) {
    const std::string kind = doc_word(d, layer, "kind");
    for (const DocValue& one : doc_values)
        if (!strcmp(one.name, name) && doc_among(one.kinds, kind) && !one.words) return *low = one.low, *high = one.high, true;
    if (const DocValue* v = doc_script_value(d, layer, name); v && !v->words) return *low = v->low, *high = v->high, true;
    return false;
}
// Whether a value is on: keyed, or said and not nought (a colour said is on, black too).
static bool doc_on(Doc& d, int layer, const char* name) {
    if (doc_keys(d, layer, name)) return true;
    const std::string w = doc_word(d, layer, name);
    double low = 0, high = 0;
    return !w.empty() && (!doc_range(d, layer, name, &low, &high) || std::atof(w.c_str()) != 0);
}
