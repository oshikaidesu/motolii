#ifndef MOTOLII_DOCUMENT_EDIT_ELEMENTS_H_
#define MOTOLII_DOCUMENT_EDIT_ELEMENTS_H_

// Elements: a layer kept as a file of its own, put into other projects and
// followed when the file changes. They are
// stored like presets (presets.cpp); this file is the keeping, the adding and
// the following.

#include <string>

namespace motolii {

struct Doc;

// Saves `layer` as an element file named `name` in the elements folder. The
// name must be a valid file name (no slashes, backslashes or colons). Returns
// true on success.
bool doc_element_keep(Doc& d, int layer, const std::string& name);

// Adds an element from the file at `path` to the project at time `now`.
// Returns the layer that holds the element, or 0 on failure.
int doc_element_add(Doc& d, const char* path, double now);

// Checks every element instance in the project against its file. When the
// file has been written since the instance was placed, the instance is
// replaced with the file's current contents. Returns how many instances were
// updated.
int doc_elements_follow(Doc& d);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EDIT_ELEMENTS_H_
