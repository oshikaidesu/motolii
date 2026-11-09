// motolii.mm: motolii.h's calls, each handed on to doc.h (the document) and kit.h (the stage). Nothing is worked out here.
// In parts, read in this order (each a piece of the one before it, none alone):
#include "entry/render_thread.h"
#include "entry/render_thread_loop.h"
#include "entry/window.h"
#include "third_party/rapidfuzz/rapidfuzz_amalgamated.hpp"   // (the shelves' search: motolii_find)
#include "entry/calls_find.h"   // (the shelves' search)
#include "qdtsne/qdtsne.hpp"   // (the shelves' maps: motolii_map)
#include "rectangular_lsap.h"   // (the shelves' maps on a grid: motolii_grid)
#include <onnxruntime_cxx_api.h>   // (how alike pictures look, for the shelves' maps: motolii_likeness)
#include "entry/calls_map.h"   // (the shelves' maps)
#include "entry/calls.h"
#include "entry/calls_sound.h"
#include "entry/calls_files.h"
#include "entry/calls_later.h"
#include "entry/calls_time.h"
#include "entry/export.h"
