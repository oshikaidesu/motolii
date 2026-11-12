#ifndef MOTOLII_COMMUNITY_JOLT_RIGID_BODIES_H_
#define MOTOLII_COMMUNITY_JOLT_RIGID_BODIES_H_

// Rigid bodies moved by Jolt Physics (third_party/physics/JoltPhysics, MIT) as
// it is: falling, touching, resting and piling up are Jolt's. This adapter
// only tells Jolt, before each step of 1/60 s, what every body was given
// (a force, a mass, where its layer puts it), and reads back where each body
// is. The bodies are boxes that move in one plane, as Jolt's own
// TwoDFunnelTest sample sets them up (EAllowedDOFs::Plane2D).
//
// Lengths are metres, angles radians, masses kilograms and forces newtons:
// Jolt works in SI units (Docs/Architecture.md, "Big Worlds").

#include <limits>
#include <memory>
#include <string>
#include <vector>

namespace motolii {

// What one body is told before a step. The names after the box are Jolt's
// own: BodyCreationSettings' mMassPropertiesOverride.mMass, mGravityFactor,
// mRestitution and mFriction, and BodyInterface::AddForce. A value that is
// NaN was not said and stays as Jolt has it.
struct RigidBodyTold {
  // False while the body's layer is not on: it touches nothing, and when it
  // comes back it starts from where it is told, at rest.
  bool present = false;
  // Half the size of its box, and where the box's middle lies from the body's
  // own point before it is turned.
  double half_wide = 0, half_high = 0, middle_x = 0, middle_y = 0;
  // Where its layer puts it. A body with mass 0 is moved there
  // (BodyInterface::MoveKinematic) and pushes what it meets; any other body
  // starts there.
  double x = 0, y = 0, turn = 0;
  double mass = 0;
  double gravity_factor = std::numeric_limits<double>::quiet_NaN(),
         restitution = std::numeric_limits<double>::quiet_NaN(),
         friction = std::numeric_limits<double>::quiet_NaN();
  double force_x = 0, force_y = 0;
};

// Where a body's own point is, and how far the body is turned.
struct RigidBodyPlace {
  double x = 0, y = 0, turn = 0;
};

// One Jolt PhysicsSystem and the bodies in it.
class RigidBodies {
 public:
  RigidBodies();
  ~RigidBodies();
  // Makes the bodies anew, each where it is told. Nothing has moved yet.
  void begin(const std::vector<RigidBodyTold>& told);
  // Tells every body, in the order of begin(), then steps 1/60 s.
  void step(const std::vector<RigidBodyTold>& told);
  std::vector<RigidBodyPlace> places() const;
  // Everything a later step depends on (PhysicsSystem::SaveState), and back.
  // After restore(state()) the steps that follow give the same result.
  std::string state() const;
  void restore(const std::string& state);

 private:
  struct Own;
  std::unique_ptr<Own> own;
};

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_JOLT_RIGID_BODIES_H_
