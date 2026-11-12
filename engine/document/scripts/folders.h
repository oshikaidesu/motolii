#ifndef MOTOLII_DOCUMENT_SCRIPTS_FOLDERS_H_
#define MOTOLII_DOCUMENT_SCRIPTS_FOLDERS_H_

// Recipe files. The folders they are read from are in shelf/shelf_folders.h.
//
// A recipe creates several layers in one call. It is what Cavalry's tutorials
// build from a shape, a duplicator and one or two behaviours, each named. Each
// recipe is one file in create/, either in the library's folder or in the
// user's own folder (see doc_folders). A file put there shows up on the shelf
// at once.
//
// The head of a recipe file is:
//   // Name: what it makes
//   // make kind file
// followed by the first layer's values, one per line:
//   set name number
//   say name words
//   key name seconds number
// and "then kind file" to add another layer. Parameters are written as script.h
// describes. Any code below the head is the first layer's script.

#include <string>
#include <vector>

namespace motolii {

// `program` is the program a closed pack was written for. Such a recipe is
// listed on the Code shelf instead of Create; it is "" for the recipes of
// Create.
struct DocRecipe {
  std::string name, what, path, program;
  std::vector<std::string> lines;
  bool code = false;
};
// Returns all recipes, rereading the files only when they have changed.
std::vector<DocRecipe> doc_recipes();

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_SCRIPTS_FOLDERS_H_
