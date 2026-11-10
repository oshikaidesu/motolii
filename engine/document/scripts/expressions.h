#ifndef MOTOLII_DOCUMENT_SCRIPTS_EXPRESSIONS_H_
#define MOTOLII_DOCUMENT_SCRIPTS_EXPRESSIONS_H_
// Layer expressions: scripts that place the copies of a layer.
//
// An expression is a .js file that defines each(i, n, t, k). For copy i of n it
// returns where the copy lies, how it is rotated, how large it is and how
// opaque. This is the Repeater of After Effects, its Grid, Ring and Stagger,
// and the Animators of Cavalry. See docs/design/create_and_program_shelves.md.
//
// A layer holds any number of expressions in its effect list and treats them
// like effects: they can be added, turned off, reordered and removed the same
// way. They run in list order after the layer's own script, which still places
// its copies as before. Each expression is told where the copies laid by the
// ones before it lie.

#include <string>
#include <vector>

#include "community/quickjs/script.h"
#include "document/document.h"
#include "document/scripts/scripts.h"

namespace motolii {

// Returns whether `file` is an expression: a .js file whose script lays copies.
bool doc_expression(Doc& d, const std::string& file);
// Returns `list` without its expressions. Expressions lay copies and draw
// nothing themselves, and a .js file left in the drawn list would be read as a
// three.js effect (isf.cpp).
std::vector<std::string> doc_fx_drawn(Doc& d, std::vector<std::string> list);
// Returns the layer's expressions that are turned on, in the order of its
// effect list.
std::vector<DocScript*> doc_expressions_fx(Doc& d, int layer);
// Returns everything that lays the layer's copies, in running order: first the
// layer's own script, as it always did, which may be a Cavalry distribution run
// whole, then its expressions.
std::vector<DocScript*> doc_expressions_on(Doc& d, int layer);
// Finds the macro that turns the parameter `name` of an expression (declared in
// script.h with
// "// --macro@") and returns the macro's label, or "" when no macro turns it.
//
// *adds receives what the macro adds to the parameter's own value at time `at`.
// That is (high - low) * (macro - macro default), where low and high are the
// range the macro maps to (Min + (Max - Min) * macro) and the default is the
// macro's value in the script as it comes. At the default the parameter keeps
// its own value. This follows After Effects, where the expression adds to the
// value the user set.
std::string doc_macro_adds(Doc& d, int layer, const char* name, double at,
                           double* adds);
// Adds the macro's contribution to *is, which holds the parameter's own value
// on entry and the value the script sees on return. Returns the macro's label,
// or "" when no macro turns it.
std::string doc_macro_over(Doc& d, int layer, const char* name, double at,
                           double* is);
// Converts a value the user edited, which includes the macro's contribution as
// shown by doc_macro_over, back to the parameter's own value by subtracting
// that contribution.
double doc_macro_own(Doc& d, int layer, const char* name, double at, double is);
// Runs each script in `scs` in turn for n copies at time `said` and returns the
// composed copies. Every parameter is read once per script. A select parameter
// with no value set takes the first word of its list.
//
// `clock` is the time passed to each script. `gone` is how much earlier the
// layer ends because of an Out, so the duration given to the script ends before
// the layer does.
std::vector<ScriptCopy> doc_expressions_lay(Doc& d, int layer,
                                            const std::vector<DocScript*>& scs,
                                            int n, double said, double clock,
                                            double gone);
// Returns the files that lay the layer's copies as one space-separated string.
// The caller compares it with the previous string to see whether the result it
// cached is still valid.
std::string doc_expressions_said(Doc& d, int layer);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_SCRIPTS_EXPRESSIONS_H_
