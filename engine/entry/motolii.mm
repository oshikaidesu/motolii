// motolii.mm: the engine's one translation unit. It implements the calls of motolii.h by handing
// each on to doc.h (the project) or render.h (the preview). No real work happens here.
// The parts below are included in this order. Each depends on the ones before it, and none
// compiles alone.
#include "entry/render_thread.h"
#include "entry/render_thread_loop.h"
#include "entry/window.h"
// Fuzzy search for the shelves: motolii_find.
#include "third_party/rapidfuzz/rapidfuzz_amalgamated.hpp"
// Shelf search.
#include "entry/calls_find.h"
// Shelf maps: motolii_map.
#include "qdtsne/qdtsne.hpp"
// Shelf maps on a grid: motolii_grid.
#include "rectangular_lsap.h"
// How alike images look, for the shelf maps: motolii_likeness.
#include <onnxruntime_cxx_api.h>
// Shelf maps.
#include "entry/calls_map.h"
#include "entry/calls.h"
#include "entry/calls_sound.h"
#include "entry/calls_files.h"
#include "entry/calls_later.h"
#include "entry/calls_time.h"
#include "entry/export.h"
