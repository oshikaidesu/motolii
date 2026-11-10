// Layer expressions: scripts that place the copies of a layer. Included by doc.h; not
// self-contained.
//
// An expression is a .js file that defines each(i, n, t, k). For copy i of n it returns where the
// copy lies, how it is rotated, how large it is and how opaque. This is the Repeater of After
// Effects, its Grid, Ring and Stagger, and the Animators of Cavalry. See
// docs/internal/notes/CREATE_PROGRAM.md.
//
// A layer holds any number of expressions in its effect list and treats them like effects: they
// can be added, turned off, reordered and removed the same way. They run in list order after the
// layer's own script, which still places its copies as before. Each expression is told where the
// copies laid by the ones before it lie.
// Returns whether `file` is an expression: a .js file whose script lays copies.
static bool doc_expression(Doc& d, const std::string& file) {
    if (std::filesystem::path(fx_source(file)).extension() != ".js") return false;
    const DocScript* sc = doc_script_of(d, file);
    return sc && sc->run && sc->run->lays();
}
// Returns `list` without its expressions. Expressions lay copies and draw nothing themselves, and
// a .js file left in the drawn list would be read as a three.js effect (isf.cpp).
static std::vector<std::string> doc_fx_drawn(Doc& d, std::vector<std::string> list) {
    std::erase_if(list, [&](const std::string& w) { return doc_expression(d, w); });
    return list;
}
// Returns the layer's expressions that are turned on, in the order of its effect list.
static std::vector<DocScript*> doc_expressions_fx(Doc& d, int layer) {
    std::vector<DocScript*> all;
    if (layer != 0)
        for (const std::string& file : doc_fx_list(d, layer))
            if (doc_expression(d, file)) if (DocScript* sc = doc_script_of(d, file); sc->run->ok()) all.push_back(sc);
    return all;
}
// Returns everything that lays the layer's copies, in running order: first the layer's own
// script, as it always did, which may be a Cavalry distribution run whole, then its expressions.
static std::vector<DocScript*> doc_expressions_on(Doc& d, int layer) {
    std::vector<DocScript*> all;
    if (DocScript* sc = doc_script_of(d, doc_literal_word(d, layer, "script")); sc && sc->run && sc->run->ok()) all.push_back(sc);
    for (DocScript* sc : doc_expressions_fx(d, layer)) all.push_back(sc);
    return all;
}
// Finds the macro that turns the parameter `name` of an expression (declared in script.h with
// "// --macro@") and returns the macro's label, or "" when no macro turns it.
//
// *adds receives what the macro adds to the parameter's own value at time `at`. That is
// (high - low) * (macro - macro default), where low and high are the range the macro maps to
// (Min + (Max - Min) * macro) and the default is the macro's value in the script as it comes. At
// the default the parameter keeps its own value. This follows After Effects, where the
// expression adds to the value the user set.
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
// Adds the macro's contribution to *is, which holds the parameter's own value on entry and the
// value the script sees on return. Returns the macro's label, or "" when no macro turns it.
static std::string doc_macro_over(Doc& d, int layer, const char* name, double at, double* is) {
    double adds = 0;
    const std::string by = doc_macro_adds(d, layer, name, at, &adds);
    return *is += adds, by;
}
// Converts a value the user edited, which includes the macro's contribution as shown by
// doc_macro_over, back to the parameter's own value by subtracting that contribution.
static double doc_macro_own(Doc& d, int layer, const char* name, double at, double is) {
    double adds = 0;
    return doc_macro_adds(d, layer, name, at, &adds), is - adds;
}
// Composes copy `o` onto copy `c`. This is how a layer's own placement applies to its script's
// copy (doc_place): positions and rotations add, sizes, scales and opacity multiply, and a color
// set by `o` replaces the color of `c`.
static void doc_expression_over(ScriptCopy& c, const ScriptCopy& o) {
    c.x += o.x, c.y += o.y, c.z += o.z, c.rotate += o.rotate, c.rotate_x += o.rotate_x, c.rotate_y += o.rotate_y;
    c.size *= o.size, c.scale_x *= o.scale_x, c.scale_y *= o.scale_y, c.scale_z *= o.scale_z, c.opacity *= o.opacity;
    if (o.colour >= 0) c.colour = o.colour;
}
// Runs each script in `scs` in turn for n copies at time `said` and returns the composed copies.
// Every parameter is read once per script. A select parameter with no value set takes the first
// word of its list.
//
// `clock` is the time passed to each script. `gone` is how much earlier the layer ends because of
// an Out, so the duration given to the script ends before the layer does.
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
        // A macro adds to the parameters it turns: Min + (Max - Min) * macro, minus the macro's
        // value at its default. See doc_macro_adds.
        for (size_t i = 0; i < sc->parameters.size(); ++i) {
            const double v = doc_number(d, layer, sc->names[i].c_str(), said, sc->parameters[i].usual);
            for (const ScriptParameter::Turned& t : sc->parameters[i].turns) numbers[t.name] += (t.high - t.low) * (v - sc->parameters[i].usual);
        }
        // How long the layer lasts. An Out ends it earlier, hence `gone`.
        numbers["duration"] = doc_literal(d, layer, "duration", 0, -1) + (doc_literal(d, layer, "duration", 0, -1) > 0.0 ? gone : 0.0);
        // How long the project runs, so that a flow goes round a whole number of times in it.
        numbers["round"] = d.round;
        // The fourth argument is the size of one project pixel in stage units at the layer's
        // depth. The last argument is the copies laid by the earlier scripts, the fifth argument
        // of each(); see script.h.
        const std::vector<ScriptCopy> made = sc->run->copies(n, clock, numbers, words, (double)d.stage->h / std::max(1.0, doc_number(d, 0, "high", 0, 1080) * doc_point(d, layer, said)), all);
        if (all.empty()) all = made;
        else for (size_t i = 0; i < all.size() && i < made.size(); ++i) doc_expression_over(all[i], made[i]);
    }
    return all;
}
// Returns the files that lay the layer's copies as one space-separated string. The caller
// compares it with the previous string to see whether the result it cached is still valid.
static std::string doc_expressions_said(Doc& d, int layer) {
    std::string all = doc_literal_word(d, layer, "script");
    for (const std::string& file : doc_fx_list(d, layer)) all += " " + file;
    return all;
}
