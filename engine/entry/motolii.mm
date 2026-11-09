// motolii.mm: motolii.h's calls, each handed on to doc.h (the document) and kit.h (the stage). Nothing is worked out here.
// In parts, read in this order (each a piece of the one before it, none alone):
#include "entry/motolii_hand.h"
#include "entry/motolii_hand_loop.h"
#include "entry/motolii_window.h"
#include "third_party/rapidfuzz/rapidfuzz_amalgamated.hpp"   // (the shelves' search: motolii_find)
#include "entry/motolii_calls_find.h"   // (the shelves' search)
#include "qdtsne/qdtsne.hpp"   // (the shelves' maps: motolii_map)
#include "rectangular_lsap.h"   // (the shelves' maps on a grid: motolii_grid)
#include <onnxruntime_cxx_api.h>   // (how alike pictures look, for the shelves' maps: motolii_likeness)
#include "entry/motolii_calls_map.h"   // (the shelves' maps)
#include "entry/motolii_calls.h"
#include "entry/motolii_calls_sound.h"
#include "entry/motolii_calls_files.h"
#include "entry/motolii_calls_later.h"
#include "entry/motolii_calls_moment.h"
#include "entry/motolii_write.h"
