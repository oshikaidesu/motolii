// doc_expressions.h: part of doc.h (a thing's expressions). Read only through doc.h.
// An expression: a .js file with its own each(i, n, t, k) that says where each copy of a thing lies, how turned, how
// large, how clear (the Repeater, AE Grid/Ring/Stagger, Cavalry's Animators: docs/notes/CREATE_PROGRAM.md). A thing holds
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
static std::vector<DocScript*> doc_expressions_fx(Doc& d, int thing) {
    std::vector<DocScript*> all;
    if (thing != 0)
        for (const std::string& file : doc_fx_list(d, thing))
            if (doc_expression(d, file)) if (DocScript* sc = doc_script_of(d, file); sc->run->ok()) all.push_back(sc);
    return all;
}
// What lays its copies, in turn: its script as it always did (a Canvalry distribution run whole too), then its expressions.
static std::vector<DocScript*> doc_expressions_on(Doc& d, int thing) {
    std::vector<DocScript*> all;
    if (DocScript* sc = doc_script_of(d, doc_literal_word(d, thing, "script")); sc && sc->run && sc->run->ok()) all.push_back(sc);
    for (DocScript* sc : doc_expressions_fx(d, thing)) all.push_back(sc);
    return all;
}
// A copy taken further by the next one, as the thing's own place takes its script's copy (doc_place: moved by it, then
// turned and sized by it): moved further, turned further, sized and made clear again; a colour the last one says.
static void doc_expression_over(ScriptCopy& c, const ScriptCopy& o) {
    c.x += o.x, c.y += o.y, c.z += o.z, c.rotate += o.rotate, c.rotate_x += o.rotate_x, c.rotate_y += o.rotate_y;
    c.size *= o.size, c.scale_x *= o.scale_x, c.scale_y *= o.scale_y, c.scale_z *= o.scale_z, c.opacity *= o.opacity;
    if (o.colour >= 0) c.colour = o.colour;
}
// Every copy of n at once by each of them in turn, each its knobs read once (a select by its word, not said: its first).
static std::vector<ScriptCopy> doc_expressions_lay(Doc& d, int thing, const std::vector<DocScript*>& scs, int n, double said, double clock, double gone) {
    std::vector<ScriptCopy> all;
    for (DocScript* sc : scs) {
        std::map<std::string, double> numbers;
        std::map<std::string, std::string> words;
        for (size_t i = 0; i < sc->knobs.size(); ++i) {
            if (sc->knobs[i].kind == "select") {
                const std::string w = doc_word(d, thing, sc->names[i].c_str());
                words[sc->knobs[i].name] = w.empty() ? sc->knobs[i].words.substr(0, sc->knobs[i].words.find(' ')) : w;
            }
            else numbers[sc->knobs[i].name] = doc_number(d, thing, sc->names[i].c_str(), said, sc->knobs[i].usual);
        }
        numbers["duration"] = doc_literal(d, thing, "duration", 0, -1) + (doc_literal(d, thing, "duration", 0, -1) > 0.0 ? gone : 0.0);   // (how long the thing lasts: an Out ends before it)
        numbers["round"] = d.round;   // (how long the document runs: a flow goes round a whole number of times in it, as scatter's drift did)
        const std::vector<ScriptCopy> made = sc->run->copies(n, clock, numbers, words, (double)d.stage->h / std::max(1.0, doc_number(d, 0, "high", 0, 1080) * doc_point(d, thing, said)));   // (a pixel of the document, where the thing stands)
        if (all.empty()) all = made;
        else for (size_t i = 0; i < all.size() && i < made.size(); ++i) doc_expression_over(all[i], made[i]);
    }
    return all;
}
// The files that lay its copies, as one word: what they last laid is kept while it is the same.
static std::string doc_expressions_said(Doc& d, int thing) {
    std::string all = doc_literal_word(d, thing, "script");
    for (const std::string& file : doc_fx_list(d, thing)) all += " " + file;
    return all;
}
