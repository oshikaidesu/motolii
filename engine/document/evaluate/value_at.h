#ifndef MOTOLII_DOCUMENT_EVALUATE_VALUE_AT_H_
#define MOTOLII_DOCUMENT_EVALUATE_VALUE_AT_H_
// Reads a property's value at a time: its keyframes and easings, plus the
// clocks of a nested element and of a script.

#include <sqlite3.h>

#include <algorithm>
#include <functional>
#include <string>
#include <vector>

#include "document/kinds.h"

// Runs the query `ask` on the project database and calls `each` once per result
// row. Takes ownership of `ask`, which must come from sqlite3_mprintf, and
// frees it. Returns false if SQLite rejects the query.
bool doc_rows(Doc& d, char* ask,
              const std::function<void(sqlite3_stmt*)>& each = nullptr);
// Drops every cached read of the document. Call it after the document changes.
void doc_forget(Doc& d);
// Returns the layers in stacking order, rearmost first. Layers with an `order`
// property are sorted by it; the others keep their creation order. The result
// is cached until doc_forget.
const std::vector<int>& doc_laid(Doc& d);
// Returns a prepared statement that evaluates an easing expression, cached by
// expression text. Returns nullptr if SQLite rejects the expression; d.error
// then holds the reason. The statement binds, in order: u, t, d, a, b, p1, p2,
// p3, p4.
sqlite3_stmt* doc_expression_statement(Doc& d, const std::string& expression);
// Runs an easing statement from doc_expression_statement. `u` is progress
// through the segment, `t` is seconds into it, `length` is its duration in
// seconds, `a` and `b` are the keyframe values at its ends, and `p` points to
// the four easing parameters. Returns the eased value, or `a` if the statement
// yields no row.
double doc_went(sqlite3_stmt* statement, double u, double t, double length,
                double a, double b, const double* p);
// Returns the prepared statement for the easing called `name`, or nullptr if
// there is none. The project's own easing table is searched first, then the
// built-in easings in easing_names.h. Results are cached by name.
sqlite3_stmt* doc_easing_named(Doc& d, const std::string& name);
// Evaluates a keyframe segment that uses an easing defined in the project.
// `own` is the easing name followed by up to four numeric parameters. `u` is
// progress through the segment, `t` is seconds into it, `length` is its
// duration in seconds, and `a` and `b` are the keyframe values at its ends.
// Returns `a` if no such easing exists.
double doc_went_by(Doc& d, const std::string& own, double u, double t,
                   double length, double a, double b);
// Returns the value of keyframes `k` at time `at`, or `otherwise` if there are
// no keyframes. Before the first keyframe and after the last, the end values
// are held. Between two keyframes the segment's easing applies; Linear when
// none is set. This is the calculation behind doc_number.
double doc_keys_at(Doc& d, const Doc::Keys& k, double at, double otherwise);
// Returns the keyframes of one property of a layer. They are read from the
// database once and cached until the document changes.
const Doc::Keys& doc_keys_of(Doc& d, int layer, const char* name);
// Returns the text value of a property, or an empty string if it is not set.
// A value being dragged by the user overrides the stored one.
std::string doc_word(Doc& d, int layer, const char* name);
// Returns the time `layer` sees at stage time `at`. If the layer is inside a
// nested element, the element's clock applies; otherwise the stage time is
// returned unchanged.
double doc_element_now(Doc& d, int layer, double at);
// Applies time quantization (Alight Motion's; After Effects' Posterize Time). A
// layer with a frame_rate is sampled only at its own frames, counted from its
// start, so an animated value is read at the frame that contains `at`. Without
// a frame_rate the time is as smooth as the stage. Inside a nested element the
// time is first mapped by doc_element_now. Returns the time to read the
// keyframes `k` at.
double doc_stepped(Doc& d, int layer, const Doc::Keys& k, double at);
// Returns the numeric property `name` of `layer` at time `at`, or `otherwise`
// if it is not set. A value being dragged by the user overrides the stored one.
double doc_number(Doc& d, int layer, const char* name, double at,
                  double otherwise);
// Returns the script's own time in seconds at stage time `at`. `by` is the time
// the script has reached on its own and is used when no time_remap is set. A
// script runs once, in order, and its frames are cached, so the keyed time only
// selects which cached frame is shown. Nothing is rewritten or rerun, and every
// easing between keys works. This matches After Effects' Time Remap, whose
// value is the layer's own time.
inline double doc_own_time(Doc& d, int layer, double at, double by) {
  return std::max(0.0, doc_number(d, layer, "time_remap", at, by));
}
// Returns the drawing number of a level at time `at`: the value of the last
// keyframe at or before `at`, held until the next one regardless of easing.
// Like the cells of a timesheet, a drawing is never between two numbers (see
// OpenToonz's xdtsio.cpp). Returns 1 if there are no keyframes.
double doc_cel(Doc& d, int layer, double at);
#endif  // MOTOLII_DOCUMENT_EVALUATE_VALUE_AT_H_
