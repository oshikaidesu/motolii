#include "document/match/match_look.h"

#include <string>

#include "document/card_table.h"
#include "document/cards.h"
#include "document/document.h"
#include "document/evaluate/shown.h"
#include "document/evaluate/value_at.h"
#include "document/match.h"

namespace motolii {

bool doc_lit(Doc& d, int layer) {
  const std::string space = doc_word(d, layer, "space");
  if (!doc_among("video text image shape",
                 doc_word(d, layer, "kind").c_str()) ||
      (space != "3d" && space != "2.5d" && !doc_on(d, layer, "scale_z")))
    return false;
  if (doc_on(d, layer, "metallic")) return true;
  for (const int t : doc_layers(d))
    if (doc_word(d, t, "kind") == "light") return true;
  return false;
}

int doc_bevel(Doc& d, int layer) {
  const std::string way = doc_word(d, layer, "bevel");
  const char* const ways[] = {"angular", "convex", "concave", "ogee", "step"};
  for (int k = 0; k < 5; k++)
    if (way == ways[k] && doc_on(d, layer, "scale_z")) return k + 1;
  return 0;
}

}  // namespace motolii
