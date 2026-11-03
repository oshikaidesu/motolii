// motolii.mm: motolii.h's calls, each handed on to doc.h (the document) and kit.h (the stage). Nothing is worked out here.
// In parts, read in this order (each a piece of the one before it, none alone):
#include "motolii_hand.h"
#include "third_party/rapidfuzz/rapidfuzz_amalgamated.hpp"   // (the shelves' search: motolii_find)
#include "find.h"   // (the shelves' search)
#include "qdtsne/qdtsne.hpp"   // (the shelves' maps: motolii_map)
#include "look_map.h"   // (the shelves' maps)
#include "motolii_calls.h"
#include "motolii_write.h"
