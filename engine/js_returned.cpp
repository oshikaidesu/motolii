// js_returned.cpp: what an expression's each() returns, read from its code as it is written, as places in it: each
// property of the object it returns, where its value is, and where the numbers and knobs that make it are. A card draws
// its rows from these and a hand changes the code there and nowhere else (Processing's Tweak Mode, as sketch_marked
// reaches a sketch's numbers; Bret Victor's Learnable Programming), so the code stays the one thing kept. A value that
// is a name is followed to what each() says of that name (const/let/var x = …, x = …, x += …), and on through the names
// in those, each once; a knob is k.Name or k["Name"], k being each()'s fourth parameter. What cannot be followed is left
// out, never refused. Read by tree-sitter and its JavaScript grammar (tree_sitter.sh, MIT): it gives each part of the
// code its bytes, and a tree even for code half typed. QuickJS, which runs the code, makes no tree to ask.
#include "motolii.h"
#include <tree_sitter/api.h>
#include <algorithm>
#include <cstring>
#include <map>
#include <set>
#include <string>
#include <tuple>
#include <vector>

extern "C" const TSLanguage* tree_sitter_javascript(void);

namespace {
std::string text(const char* src, TSNode n) { return ts_node_is_null(n) ? std::string() : std::string(src + ts_node_start_byte(n), ts_node_end_byte(n) - ts_node_start_byte(n)); }
bool is(TSNode n, const char* type) { return !ts_node_is_null(n) && !strcmp(ts_node_type(n), type); }
TSNode field(TSNode n, const char* name) { return ts_node_child_by_field_name(n, name, (uint32_t)strlen(name)); }
bool function_like(TSNode n) {
    for (const char* t : {"function_declaration", "function_expression", "arrow_function", "method_definition", "generator_function", "generator_function_declaration", "class_declaration", "class"})
        if (is(n, t)) return true;
    return false;
}
TSNode bare(TSNode n) { while (is(n, "parenthesized_expression") && ts_node_named_child_count(n) > 0) n = ts_node_named_child(n, 0); return n; }

// each(): function each(...) {...}, or const each = function / (...) => ...; the function itself
TSNode each_of(const char* src, TSNode n) {
    if (is(n, "function_declaration") && text(src, field(n, "name")) == "each") return n;
    if (is(n, "variable_declarator") && text(src, field(n, "name")) == "each") {
        const TSNode f = bare(field(n, "value"));
        if (is(f, "function_expression") || is(f, "arrow_function")) return f;
    }
    for (uint32_t i = 0; i < ts_node_named_child_count(n); ++i)
        if (const TSNode f = each_of(src, ts_node_named_child(n, i)); !ts_node_is_null(f)) return f;
    return TSNode{};
}

struct Reading {
    const char* src;
    std::string knobs = "k";                       // (each()'s fourth parameter's name)
    std::map<std::string, std::vector<TSNode>> said;   // (what each() says of a name: the values given it, in order)
    std::vector<std::tuple<uint32_t, uint32_t, std::string>> found;   // (start, end, "n" or "k:Name"), for one property
    std::set<std::string> followed;

    // what each()'s own body says of its names (not what a function inside it says of its own)
    void gather(TSNode n) {
        for (uint32_t i = 0; i < ts_node_named_child_count(n); ++i) {
            const TSNode c = ts_node_named_child(n, i);
            if (is(c, "variable_declarator") && is(field(c, "name"), "identifier") && !ts_node_is_null(field(c, "value")))
                said[text(src, field(c, "name"))].push_back(field(c, "value"));
            else if ((is(c, "assignment_expression") || is(c, "augmented_assignment_expression")) && is(field(c, "left"), "identifier"))
                said[text(src, field(c, "left"))].push_back(field(c, "right"));
            if (!function_like(c)) gather(c);
        }
    }
    void follow(const std::string& name) {
        if (!followed.insert(name).second) return;   // (each name once: x = x + 1 and the like end)
        if (const auto s = said.find(name); s != said.end()) for (const TSNode v : s->second) look(v);
    }
    std::string knob(TSNode n) {   // (k.Name, k["Name"], k['Name']: Name; else "")
        if (is(n, "member_expression") && text(src, field(n, "object")) == knobs) return text(src, field(n, "property"));
        if (is(n, "subscript_expression") && text(src, field(n, "object")) == knobs && is(field(n, "index"), "string")) {
            const std::string s = text(src, field(n, "index"));
            return s.size() >= 2 ? s.substr(1, s.size() - 2) : "";
        }
        return "";
    }
    void look(TSNode n) {
        if (ts_node_is_null(n)) return;
        if (is(n, "number")) { found.emplace_back(ts_node_start_byte(n), ts_node_end_byte(n), "n"); return; }
        if (const std::string k = knob(n); !k.empty()) { found.emplace_back(ts_node_start_byte(n), ts_node_end_byte(n), "k:" + k); return; }
        if (is(n, "identifier") || is(n, "shorthand_property_identifier")) { follow(text(src, n)); return; }
        for (uint32_t i = 0; i < ts_node_named_child_count(n); ++i) look(ts_node_named_child(n, i));
    }
    void row(std::string& out, const std::string& name, TSNode value) {
        found.clear(), followed.clear();
        look(value);
        std::sort(found.begin(), found.end()), found.erase(std::unique(found.begin(), found.end()), found.end());
        out += name + "\t" + std::to_string(ts_node_start_byte(value)) + "\t" + std::to_string(ts_node_end_byte(value)) + "\t";
        for (size_t i = 0; i < found.size(); ++i) {
            const auto& [a, b, what] = found[i];
            out += (i ? " " : "") + what + ":" + std::to_string(a) + ":" + std::to_string(b);
        }
        out += "\n";
    }
    void object(TSNode o, std::string& out) {
        for (uint32_t i = 0; i < ts_node_named_child_count(o); ++i) {
            const TSNode p = ts_node_named_child(o, i);
            if (is(p, "pair")) {
                std::string name = text(src, field(p, "key"));
                if (name.size() >= 2 && (name[0] == '"' || name[0] == '\'')) name = name.substr(1, name.size() - 2);
                row(out, name, field(p, "value"));
            } else if (is(p, "shorthand_property_identifier")) row(out, text(src, p), p);   // ({ x }: its value is the name x)
        }
    }
    // the returns of each()'s own body (not those of a function inside it), each returning an object
    void returns(TSNode n, std::string& out) {
        for (uint32_t i = 0; i < ts_node_named_child_count(n); ++i) {
            const TSNode c = ts_node_named_child(n, i);
            if (function_like(c)) continue;
            if (is(c, "return_statement") && ts_node_named_child_count(c) > 0) {
                if (const TSNode v = bare(ts_node_named_child(c, 0)); is(v, "object")) object(v, out);
            } else returns(c, out);
        }
    }
};
}

const char* motolii_js_returned(const char* src) {
    thread_local std::string said;
    said.clear();
    if (!src) return said.c_str();
    TSParser* parser = ts_parser_new();
    ts_parser_set_language(parser, tree_sitter_javascript());
    TSTree* tree = ts_parser_parse_string(parser, nullptr, src, (uint32_t)strlen(src));
    if (const TSNode each = each_of(src, ts_tree_root_node(tree)); !ts_node_is_null(each)) {
        Reading r{src};
        const TSNode ps = field(each, "parameters");
        if (ts_node_named_child_count(ps) >= 4 && is(ts_node_named_child(ps, 3), "identifier")) r.knobs = text(src, ts_node_named_child(ps, 3));
        const TSNode body = field(each, "body");
        r.gather(body);
        if (const TSNode b = bare(body); is(b, "object")) r.object(b, said);   // (an arrow's body that is the object: (i) => ({ x: i }))
        else r.returns(body, said);
    }
    ts_tree_delete(tree);
    ts_parser_delete(parser);
    return said.c_str();
}
