#include "document/scripts/folders.h"

#include "document/scripts/recipes.h"
#include "shelf/shelf_folders.h"

std::vector<DocRecipe> doc_recipes() {
  static std::vector<DocRecipe> all;
  static int seen = -1;
  if (doc_folder_moved(seen)) all = doc_recipes_read();
  return all;
}
