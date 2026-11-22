#include "document/scripts/folders.h"

#include <mutex>

#include "document/scripts/recipes.h"
#include "shelf/shelf_folders.h"

namespace motolii {

std::vector<DocRecipe> doc_recipes() {
  static std::mutex lock;
  std::lock_guard<std::mutex> hold(lock);
  static std::vector<DocRecipe> all;
  static int seen = -1;
  if (doc_folder_moved(seen)) all = doc_recipes_read();
  return all;
}

}  // namespace motolii
