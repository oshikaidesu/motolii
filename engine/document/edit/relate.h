#ifndef MOTOLII_DOCUMENT_EDIT_RELATE_H_
#define MOTOLII_DOCUMENT_EDIT_RELATE_H_

// Puts layers into a relation, takes them out, and changes a relation's leader.

#include <string>
#include <utility>
#include <vector>

namespace motolii {

struct Doc;

// Returns a copy of the name that stays valid for the life of the program, so
// doc_literal can recognize it again by its address. There is one address per
// name, ever.
const char* doc_lasting(const std::string& name);
// Takes a layer out of the relation `by`, keeping the layer where it shows at
// time `now`. The layer's connected values go back to what they were connected
// to before, or are removed if there was nothing. A relation that started from
// `by` for this layer now starts from that earlier one. The layer's place among
// the relation's members is left empty so no other member moves. If `stay` is
// true, each connected value is also moved, all its keyframes alike, by the
// amount it would otherwise jump. One undo step; nothing jumps. `told` is the
// result of doc_shown_now for the layer if the caller already has it, otherwise
// it is read here.
bool doc_free(
    Doc& d, int layer, int by, double now, bool stay,
    const std::vector<std::pair<std::string, double>>* told = nullptr);
// Puts layers into the relation `by` as they show now. The members are in the
// order given, without the leader the script picks, if one is set. Each records
// the relation it was in before, which the new relation starts from, and where
// it showed (the script's `from`), so the script can add only the step from
// there. Then the layers are connected. One undo step.
bool doc_relate(Doc& d, int by, const char* ids, double now);
// Returns whether the script of the relation `by` picks `layer` in one of its
// picture parameters, such as its leader.
bool doc_picks(Doc& d, int by, int layer);
// Changes the leader of the relation `by` (its script's parameter `leader`) to
// `leader`. The new leader is taken out of the relation's layers if it was one
// of them. Then every layer touched is moved by the amount it would otherwise
// jump. One undo step; nothing jumps.
bool doc_lead(Doc& d, int by, int leader, double now);
// Releases the relation `by`. Each of its layers stays where it shows at time
// `now`, and the relation is removed, in one undo step.
bool doc_release(Doc& d, int by, double now);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EDIT_RELATE_H_
