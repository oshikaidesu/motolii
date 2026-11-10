#ifndef MOTOLII_PHYSICS_PHYSICS_H_
#define MOTOLII_PHYSICS_PHYSICS_H_

// Rigid-body physics for layers: layers fall and collide with each other.
// The simulation uses Jolt, chosen by physics_bench, behind an adapter that
// exposes none of Jolt's types.
//
// The simulation advances in fixed steps of 1/60 s starting at the beginning of
// the project. Each frame's result is cached once computed, so seeking backward
// reads the cache and the same project always produces the same motion.

#include <functional>
#include <memory>
#include <vector>

namespace motolii {

// One simulated layer.
struct PhysThing {
  // True for a wall: the project places it, and only its keyframes move it.
  bool still = false;
  // True if the layer is constrained to its own plane and can only rotate about
  // the camera's viewing axis (Jolt's Plane2D).
  bool flat = false;
  // True for a ball of radius half[0]; false for a box with half extents half.
  bool ball = false;
  float half[3] = {0.5f, 0.5f, 0.5f};
  float bounce = 0.3f, friction = 0.5f;
  // Time in seconds. Before this time the layer follows its keyframes. From
  // this time on the simulation moves it, starting with the velocity the
  // keyframes gave it.
  double until = 0.0;
};

// Position and rotation of a layer's center.
// at is the position as x, y, z. turn is the rotation quaternion as x, y, z, w.
struct PhysPose {
  float at[3] = {0, 0, 0}, turn[4] = {0, 0, 0, 1};
};

// Returns the pose the project's keyframes give layer `index` at time `at` in
// seconds.
using PhysKeyed = std::function<PhysPose(int index, double at)>;

// A physics simulation over a fixed set of layers.
class PhysWorld {
 public:
  PhysWorld(const std::vector<PhysThing>& things, float gravity,
            PhysKeyed keyed);
  ~PhysWorld();
  // Returns the pose of layer `index` at frame `frameIndex`, which is time
  // frameIndex / 60 s from the beginning of the project. Simulates up to that
  // frame on the first request and caches every frame on the way. Returns a
  // default pose if `index` is out of range.
  PhysPose pose(int index, int frameIndex);

 private:
  struct Own;
  std::unique_ptr<Own> own;
};

}  // namespace motolii

#endif  // MOTOLII_PHYSICS_PHYSICS_H_
