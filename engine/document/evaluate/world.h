#ifndef MOTOLII_DOCUMENT_EVALUATE_WORLD_H_
#define MOTOLII_DOCUMENT_EVALUATE_WORLD_H_
// Evaluates relations that are written as script files, and the shared
// simulated world that the relations which push layers act on.

#include <chrono>
#include <cstddef>
#include <map>
#include <set>
#include <vector>

namespace motolii {

struct Doc;

// The relations whose result is worked out frame after frame and kept: a
// relation written as a file, and the world of the relations that push.
struct DocSolver {
  // Where doc_keys_of records each layer it reads while a caching relation is
  // evaluated.
  std::set<int>* reading = nullptr;
  // live: a window is drawing. A caching relation then gets a time slice of
  // each frame, starting at slice, and sets behind if it did not finish in time
  // (see relations.h). exact: the result must be right rather than quick.
  bool live = false, exact = false, behind = false;
  // Start of the time slice.
  std::chrono::steady_clock::time_point slice;
  // The cached result of a relation written as a file. frames: a solver's
  // frames, each computed from the one before, as Motolii's p5 keeps its own.
  // told: what each frame was told. sure: this many frames are known good since
  // the project last changed. fresh: frames past this count are left from
  // before and shown until they are made again. reads: the layers its input
  // comes from. seen: how far into touched it has looked.
  struct RelatedKept {
    double at = -1;
    long changes = -1;
    int made = -1, solves = -1;
    size_t sure = 0, fresh = 0, seen = 0;
    bool behind = false;
    std::vector<double> values;
    std::vector<std::vector<double>> frames;
    std::vector<size_t> told;
    std::set<int> reads;
  };
  // What a relation written as a file last said about all its layers. Key 0
  // holds the whole world (see world.h).
  std::map<int, RelatedKept> relatedKept;
  // The relations that act on layers together. forces: the relations that push,
  // oldest first. layers: every layer any of them acts on. below: what each
  // layer stands on, under all of them. slot: where each layer lies in a frame.
  // See world.h.
  struct World {
    std::vector<int> forces, layers, below;
    std::map<int, size_t> slot;
  };
  World world;
  // Set while the world is being worked out. What it asks of itself then comes
  // from the frames it already has.
  bool walking = false;
};

// Returns the values that relation `by`, written as a script file, gives all
// its layers at time `t`. For each layer the values are those named in
// doc_relate_names, in order. The script's relate() receives all layers at
// once, as a Python Effector in Cinema 4D's Full Control does, rather than one
// value at a time as the kinds in relations.h do, so each layer's result can
// depend on all the others.
// Returns an empty vector if there is no script or it failed; the layers
// underneath then show unchanged, and the script's error is reported. If
// relate() takes a fourth argument, the script keeps state, as Cavalry's Value
// Solver and Context's saveObject do: it receives its own result from the
// previous frame, and null at the first frame. While Strength is 0 the relation
// sleeps, as Houdini's Activation does, and the layers underneath show; when it
// wakes it continues from where those layers are then. While the user is
// dragging a value it waits.
const std::vector<double>& doc_related_all(Doc& d, int by, double t);
// Returns true if the script of relation `by` defines force(), meaning it
// pushes layers, rather than relate().
bool doc_pushes(Doc& d, int by);
// Returns value number `name` (an offset within the doc_world_kept values) of
// `layer` in the shared world at time `t`, or `otherwise` if the layer is not
// in the world.
double doc_world_value(Doc& d, int layer, size_t name, double t,
                       double otherwise);

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_EVALUATE_WORLD_H_
