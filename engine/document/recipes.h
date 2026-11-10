#ifndef MOTOLII_DOCUMENT_RECIPES_H_
#define MOTOLII_DOCUMENT_RECIPES_H_

// Reads the files on the shelves (recipes, effects, scripts, easings) and applies recipes.

#include <atomic>
#include <map>
#include <string>
#include <vector>

#include "document/folders.h"
#include "document/kinds.h"

// Returns every recipe found in the create folders. A recipe is a .js file whose leading comment
// lines give its name and description, followed by command lines such as "make ...". A p5.js sketch
// posted as it is has no such head, so it gets a default recipe.
std::vector<DocRecipe> doc_recipes_read();
// Returns one line per recipe: "name\tdescription". A recipe from another program's pack also gets
// "\tprogram\tpath".
std::string doc_recipe_names();
// Returns true when a file that the project's images are made from, such as the stage's effects or
// the layers' scripts, was written over since it was last read. A stage that is not redrawing is
// woken by this, so a saved file shows at once.
bool doc_files_moved(Doc& d);
// Returns one line per file of a kind in the shelf folders (doc_folders), in the form
// "name\tpath\tlabel\timage\thome\tsame\tabout\ttags", where image, home and same come from
// doc_tile. This covers the screen effects (effects/*.wgsl) and the motions a layer may be given
// (expressions/*.js). The name is the file's first line, before the colon. The label says what the
// effect is for and is the shelf's category. It comes from a head line such as "--label:Distort",
// as in AviUtl's --label: for its script menu. The image is the .png beside the file, if there is
// one. The result is cached and rebuilt only when doc_folder_moved reports a change.
std::string doc_folder_names(const char* folder, const char* extension);
// Returns one line per AviUtl2 script, in the same form as doc_folder_names. Scripts stay in their
// packages as their authors published them, one folder per package
// (aviutl_scripts/<author>__<package>/). They are left unchanged because a script's require reads
// files beside it. The packages are searched to any depth in the library's aviutl_scripts/ and in
// the user's own folder (doc_folders). Each .anm2 and .obj2 file gives one line. Each script inside
// an @ file ("file#name") gives its own line. The label is the script's --label: line. A file is
// reread only when it was written over.
std::string doc_aviutl_names();
// Counts how many times the files read differed from the previous read. The app redraws its preview
// when this changes (entry/render_thread.h).
std::atomic<int>& doc_own_easings_made();
// Returns the user's own easings together with the few the library ships, as a map from name to
// expression. Each is a file in ease/ of the user's folder (doc_folders) or of the library. A file
// put in either shows as a tile in the Ease tool panel at once. The first comment line gives the
// name, before the colon. The rest is how far along the easing is, in the form used by an easing
// defined in a project (doc_define: a, b, u, p1..p4, bezier(u, x1, y1, x2, y2), way('Cyclic', u)).
// When applied to a keyframe the expression is written into the project, so the project plays the
// same wherever it is opened. The user's easing of a name takes precedence over the library's.
//
// There is one cache for the whole program. It is read by every project's render thread and by
// every app request, so a mutex guards it and callers get a copy.
std::map<std::string, std::string> doc_own_easings();
// Returns the file path of the script recipe with that name, or an empty string if there is none.
std::string doc_recipe_code_path(const std::string& name);
// Applies the recipe of that name at the stage's current time as one undo step. Returns the first
// layer it made, or 0 when nothing was made, in which case d.error says why.
int doc_make(Doc& d, const char* name);

#endif  // MOTOLII_DOCUMENT_RECIPES_H_
