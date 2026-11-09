// expressions.h: part of doc.h (a layer's expressions). Read only through doc.h.
// An expression: a .js file with its own each(i, n, t, k) that says where each copy of a layer lies, how turned, how
// large, how clear (the Repeater, AE Grid/Ring/Stagger, Cavalry's Animators: docs/internal/notes/CREATE_PROGRAM.md). A layer holds
// any number among its effects (fx), as it holds effects: put on, turned off, moved, put on again and taken off the
// same way, laid in their order after its script (which still lays its copies as it did).
static bool doc_expression(Doc& d, const std::string& file) {
    if (std::filesystem::path(fx_source(file)).extension() != ".js") return false;
    const DocScript* sc = doc_script_of(d, file);
    return sc && sc->run && sc->run->lays();
}
// Its effects that are drawn: its expressions left out (they lay its copies, doc_laid: nothing of them is drawn, and
// a .js among the drawn ones is read as a three.js effect: isf.cpp).
static std::vector<std::string> doc_fx_drawn(Doc& d, std::vector<std::string> list) {
    std::erase_if(list, [&](const std::string& w) { return doc_expression(d, w); });
    return list;
}
// Its expressions that are on, in the order its effects list them.
static std::vector<DocScript*> doc_expressions_fx(Doc& d, int layer) {
    std::vector<DocScript*> all;
    if (layer != 0)
        for (const std::string& file : doc_fx_list(d, layer))
            if (doc_expression(d, file)) if (DocScript* sc = doc_script_of(d, file); sc->run->ok()) all.push_back(sc);
    return all;
}
// What lays its copies, in turn: its script as it always did (a Canvalry distribution run whole too), then its expressions.
static std::vector<DocScript*> doc_expressions_on(Doc& d, int layer) {
    std::vector<DocScript*> all;
    if (DocScript* sc = doc_script_of(d, doc_literal_word(d, layer, "script")); sc && sc->run && sc->run->ok()) all.push_back(sc);
    for (DocScript* sc : doc_expressions_fx(d, layer)) all.push_back(sc);
    return all;
}
// A knob a macro of its expression turns (script.h // --macro@): what the macro adds to the knob's own value at that
// moment, its Min + (Max - Min) x the macro less what it is at the macro's own place as it comes (there the knob is its
// own value; After Effects' "value + ...": the hand's value stands, the expression adds to it), and the macro's label;
// "" where none turns it.
static std::string doc_macro_adds(Doc& d, int layer, const char* name, double at, double* adds) {
    *adds = 0;
    for (DocScript* sc : doc_expressions_on(d, layer))
        for (size_t i = 0; i < sc->parameters.size(); ++i)
            if (sc->names[i] == name && !sc->parameters[i].by.empty())
                for (size_t j = 0; j < sc->parameters.size(); ++j)
                    if (sc->parameters[j].name == sc->parameters[i].by) {
                        const ScriptParameter& macro = sc->parameters[j];
                        const double v = doc_number(d, layer, sc->names[j].c_str(), at, macro.usual);
                        for (const ScriptParameter::Turned& t : macro.turns) if (t.name == sc->parameters[i].name) *adds = (t.high - t.low) * (v - macro.usual);
                        return macro.label;
                    }
    return "";
}
// A knob as the macro that turns it makes it (its own value and what the macro adds), and the macro's label ("" none).
static std::string doc_macro_over(Doc& d, int layer, const char* name, double at, double* is) {
    double adds = 0;
    const std::string by = doc_macro_adds(d, layer, name, at, &adds);
    return *is += adds, by;
}
// What a hand gives a knob a macro turns (the value it sees: doc_macro_over) made its own: less what the macro adds.
static double doc_macro_own(Doc& d, int layer, const char* name, double at, double is) {
    double adds = 0;
    return doc_macro_adds(d, layer, name, at, &adds), is - adds;
}
// A copy taken further by the next one, as the layer's own place takes its script's copy (doc_place: moved by it, then
// turned and sized by it): moved further, turned further, sized and made clear again; a colour the last one says.
static void doc_expression_over(ScriptCopy& c, const ScriptCopy& o) {
    c.x += o.x, c.y += o.y, c.z += o.z, c.rotate += o.rotate, c.rotate_x += o.rotate_x, c.rotate_y += o.rotate_y;
    c.size *= o.size, c.scale_x *= o.scale_x, c.scale_y *= o.scale_y, c.scale_z *= o.scale_z, c.opacity *= o.opacity;
    if (o.colour >= 0) c.colour = o.colour;
}
// Every copy of n at once by each of them in turn, each its knobs read once (a select by its word, not said: its first).
static std::vector<ScriptCopy> doc_expressions_lay(Doc& d, int layer, const std::vector<DocScript*>& scs, int n, double said, double clock, double gone) {
    std::vector<ScriptCopy> all;
    for (DocScript* sc : scs) {
        std::map<std::string, double> numbers;
        std::map<std::string, std::string> words;
        for (size_t i = 0; i < sc->parameters.size(); ++i) {
            if (sc->parameters[i].kind == "select") {
                const std::string w = doc_word(d, layer, sc->names[i].c_str());
                words[sc->parameters[i].name] = w.empty() ? sc->parameters[i].words.substr(0, sc->parameters[i].words.find(' ')) : w;
            }
            else numbers[sc->parameters[i].name] = doc_number(d, layer, sc->names[i].c_str(), said, sc->parameters[i].usual);
        }
        for (size_t i = 0; i < sc->parameters.size(); ++i) {   // (a macro adds to the knobs it turns, Ableton's Min + (Max - Min) x it, less where it comes: doc_macro_adds)
            const double v = doc_number(d, layer, sc->names[i].c_str(), said, sc->parameters[i].usual);
            for (const ScriptParameter::Turned& t : sc->parameters[i].turns) numbers[t.name] += (t.high - t.low) * (v - sc->parameters[i].usual);
        }
        numbers["duration"] = doc_literal(d, layer, "duration", 0, -1) + (doc_literal(d, layer, "duration", 0, -1) > 0.0 ? gone : 0.0);   // (how long the layer lasts: an Out ends before it)
        numbers["round"] = d.round;   // (how long the document runs: a flow goes round a whole number of times in it, as scatter's drift did)
        const std::vector<ScriptCopy> made = sc->run->copies(n, clock, numbers, words, (double)d.stage->h / std::max(1.0, doc_number(d, 0, "high", 0, 1080) * doc_point(d, layer, said)));   // (a pixel of the document, where the layer stands)
        if (all.empty()) all = made;
        else for (size_t i = 0; i < all.size() && i < made.size(); ++i) doc_expression_over(all[i], made[i]);
    }
    return all;
}
// The files that lay its copies, as one word: what they last laid is kept while it is the same.
static std::string doc_expressions_said(Doc& d, int layer) {
    std::string all = doc_literal_word(d, layer, "script");
    for (const std::string& file : doc_fx_list(d, layer)) all += " " + file;
    return all;
}
