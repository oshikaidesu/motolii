#include "document/scripts/expressions.h"

#include <algorithm>
#include <cstddef>
#include <filesystem>
#include <map>
#include <string>
#include <vector>

#include "community/isf/isf.h"
#include "community/quickjs/script.h"
#include "document/evaluate/fx_list.h"
#include "document/kinds.h"
#include "document/evaluate/relations.h"
#include "document/scripts/scripts.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "stage/render/render_stage.h"

bool doc_expression(Doc& d, const std::string& file) {
    if (std::filesystem::path(fx_source(file)).extension() != ".js") return false;
    const DocScript* sc = doc_script_of(d, file);
    return sc && sc->run && sc->run->lays();
}

std::vector<std::string> doc_fx_drawn(Doc& d, std::vector<std::string> list) {
    std::erase_if(list, [&](const std::string& w) { return doc_expression(d, w); });
    return list;
}

std::vector<DocScript*> doc_expressions_fx(Doc& d, int layer) {
    std::vector<DocScript*> all;
    if (layer != 0)
        for (const std::string& file : doc_fx_list(d, layer))
            if (doc_expression(d, file)) if (DocScript* sc = doc_script_of(d, file); sc->run->ok()) all.push_back(sc);
    return all;
}

std::vector<DocScript*> doc_expressions_on(Doc& d, int layer) {
    std::vector<DocScript*> all;
    if (DocScript* sc = doc_script_of(d, doc_literal_word(d, layer, "script")); sc && sc->run && sc->run->ok()) all.push_back(sc);
    for (DocScript* sc : doc_expressions_fx(d, layer)) all.push_back(sc);
    return all;
}

std::string doc_macro_adds(Doc& d, int layer, const char* name, double at, double* adds) {
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

std::string doc_macro_over(Doc& d, int layer, const char* name, double at, double* is) {
    double adds = 0;
    const std::string by = doc_macro_adds(d, layer, name, at, &adds);
    return *is += adds, by;
}

double doc_macro_own(Doc& d, int layer, const char* name, double at, double is) {
    double adds = 0;
    return doc_macro_adds(d, layer, name, at, &adds), is - adds;
}

namespace {
// Composes copy `o` onto copy `c`. This is how a layer's own placement applies to its script's
// copy (doc_place): positions and rotations add, sizes, scales and opacity multiply, and a color
// set by `o` replaces the color of `c`.
void doc_expression_over(ScriptCopy& c, const ScriptCopy& o) {
    c.x += o.x, c.y += o.y, c.z += o.z, c.rotate += o.rotate, c.rotate_x += o.rotate_x, c.rotate_y += o.rotate_y;
    c.size *= o.size, c.scale_x *= o.scale_x, c.scale_y *= o.scale_y, c.scale_z *= o.scale_z, c.opacity *= o.opacity;
    if (o.colour >= 0) c.colour = o.colour;
}
}  // namespace

std::vector<ScriptCopy> doc_expressions_lay(Doc& d, int layer, const std::vector<DocScript*>& scs, int n, double said, double clock, double gone) {
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

std::string doc_expressions_said(Doc& d, int layer) {
    std::string all = doc_literal_word(d, layer, "script");
    for (const std::string& file : doc_fx_list(d, layer)) all += " " + file;
    return all;
}
