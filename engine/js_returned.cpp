// js_returned.cpp: what an expression's each() returns, read from its code as it is written, as places in it: each
// property of the object it returns, where its value is, and where the numbers in that value are. A card draws its rows
// from these and a hand changes the code there and nowhere else (Processing's Tweak Mode, as sketch_marked reaches a
// sketch's numbers; Bret Victor's Learnable Programming), so the code stays the one thing kept. Read by tree-sitter and
// its JavaScript grammar (tree_sitter.sh, MIT): it gives each part of the code its bytes, and a tree even for code half
// typed. QuickJS, which runs the code, makes no tree to ask (it writes bytecode as it reads).
#include "motolii.h"
#include <tree_sitter/api.h>
#include <cstring>
#include <string>

extern "C" const TSLanguage* tree_sitter_javascript(void);

namespace {
std::string text(const char* src, TSNode n) { return std::string(src + ts_node_start_byte(n), ts_node_end_byte(n) - ts_node_start_byte(n)); }
bool is(TSNode n, const char* type) { return !ts_node_is_null(n) && !strcmp(ts_node_type(n), type); }
bool function_like(TSNode n) {
    for (const char* t : {"function_declaration", "function_expression", "arrow_function", "method_definition", "generator_function", "generator_function_declaration", "class_declaration", "class"})
        if (is(n, t)) return true;
    return false;
}
// each(): function each(...) {...}, or const each = function / (...) => {...}; its body
TSNode each_body(const char* src, TSNode n) {
    if (is(n, "function_declaration") && text(src, ts_node_child_by_field_name(n, "name", 4)) == "each") return ts_node_child_by_field_name(n, "body", 4);
    if (is(n, "variable_declarator") && text(src, ts_node_child_by_field_name(n, "name", 4)) == "each") {
        const TSNode f = ts_node_child_by_field_name(n, "value", 5);
        if (is(f, "function_expression") || is(f, "arrow_function")) return ts_node_child_by_field_name(f, "body", 4);
    }
    for (uint32_t i = 0; i < ts_node_named_child_count(n); ++i)
        if (const TSNode b = each_body(src, ts_node_named_child(n, i)); !ts_node_is_null(b)) return b;
    return TSNode{};
}
void numbers(TSNode n, std::string& out) {
    if (is(n, "number")) out += (out.empty() ? "" : " ") + std::to_string(ts_node_start_byte(n)) + ":" + std::to_string(ts_node_end_byte(n));
    for (uint32_t i = 0; i < ts_node_named_child_count(n); ++i) numbers(ts_node_named_child(n, i), out);
}
void row(std::string& out, const std::string& name, TSNode value) {
    std::string at;
    numbers(value, at);
    out += name + "\t" + std::to_string(ts_node_start_byte(value)) + "\t" + std::to_string(ts_node_end_byte(value)) + "\t" + at + "\n";
}
void object(const char* src, TSNode o, std::string& out) {
    for (uint32_t i = 0; i < ts_node_named_child_count(o); ++i) {
        const TSNode p = ts_node_named_child(o, i);
        if (is(p, "pair")) {
            std::string name = text(src, ts_node_child_by_field_name(p, "key", 3));
            if (name.size() >= 2 && (name[0] == '"' || name[0] == '\'')) name = name.substr(1, name.size() - 2);
            row(out, name, ts_node_child_by_field_name(p, "value", 5));
        } else if (is(p, "shorthand_property_identifier")) row(out, text(src, p), p);   // ({ x }: its value is the name x)
    }
}
// the returns of each()'s own body (not those of a function inside it), each returning an object
void returns(const char* src, TSNode n, std::string& out) {
    for (uint32_t i = 0; i < ts_node_named_child_count(n); ++i) {
        TSNode c = ts_node_named_child(n, i);
        if (function_like(c)) continue;
        if (is(c, "return_statement") && ts_node_named_child_count(c) > 0) {
            TSNode v = ts_node_named_child(c, 0);
            while (is(v, "parenthesized_expression") && ts_node_named_child_count(v) > 0) v = ts_node_named_child(v, 0);
            if (is(v, "object")) object(src, v, out);
        } else returns(src, c, out);
    }
}
}

const char* motolii_js_returned(const char* src) {
    thread_local std::string said;
    said.clear();
    if (!src) return said.c_str();
    TSParser* parser = ts_parser_new();
    ts_parser_set_language(parser, tree_sitter_javascript());
    TSTree* tree = ts_parser_parse_string(parser, nullptr, src, (uint32_t)strlen(src));
    const TSNode body = each_body(src, ts_tree_root_node(tree));
    if (!ts_node_is_null(body)) {
        TSNode b = body;
        while (is(b, "parenthesized_expression") && ts_node_named_child_count(b) > 0) b = ts_node_named_child(b, 0);
        if (is(b, "object")) object(src, b, said);   // (an arrow's body that is the object: (i) => ({ x: i }))
        else returns(src, body, said);
    }
    ts_tree_delete(tree);
    ts_parser_delete(parser);
    return said.c_str();
}
