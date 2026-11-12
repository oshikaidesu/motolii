// Tests of RigidBodies written from rigid_bodies.h alone and from physics that
// can be looked up. Each test names the outside fact it checks.

#include "community/jolt/rigid_bodies.h"

#include <cstddef>
#include <string>
#include <vector>

#include <gtest/gtest.h>

namespace motolii {
namespace {

// Jolt's default gravity is (0, -9.81, 0) m/s^2 (PhysicsSystem.h), and the
// header fixes one step at 1/60 s.
constexpr double kGravity = 9.81;
constexpr double kStepSeconds = 1.0 / 60.0;
// Every falling box in these tests is 1 m x 1 m.
constexpr double kHalf = 0.5;
// The floor is 20 m x 1 m around the origin, so its top edge is at y = 0.5.
constexpr double kFloorTop = 0.5;
// Jolt lets resting bodies sink into each other by its penetration slop
// (PhysicsSettings::mPenetrationSlop, 0.02 m), so "touching" is within this.
constexpr double kTouching = 0.05;

RigidBodyTold Box(double x, double y, double mass) {
  RigidBodyTold told;
  told.present = true;
  told.half_wide = kHalf;
  told.half_high = kHalf;
  told.x = x;
  told.y = y;
  told.mass = mass;
  return told;
}

// Mass 0: it stays where it is told and does not fall.
RigidBodyTold Floor() {
  RigidBodyTold told = Box(0, 0, 0);
  told.half_wide = 10;
  return told;
}

// A floor and three boxes above one another. The top one is still in the air
// after one second, so the pile is still forming then.
std::vector<RigidBodyTold> Pile() {
  return {Floor(), Box(0, 2, 1), Box(0, 5, 1), Box(0, 9, 1)};
}

// The pile with a small sideways force on the top box that depends on the
// step, so that "the same inputs" means something.
std::vector<RigidBodyTold> PileAt(int step) {
  std::vector<RigidBodyTold> told = Pile();
  told[3].force_x = step % 2 == 0 ? 1.0 : -1.0;
  return told;
}

void Step(RigidBodies* bodies, const std::vector<RigidBodyTold>& told,
          int count) {
  for (int i = 0; i < count; ++i) bodies->step(told);
}

// The places, one for each body told. Fails, but stays safe to index, when
// the count is not the one expected.
std::vector<RigidBodyPlace> Places(const RigidBodies& bodies,
                                   std::size_t count) {
  std::vector<RigidBodyPlace> places = bodies.places();
  EXPECT_EQ(places.size(), count);
  places.resize(count);
  return places;
}

// Outside fact: a body falling freely from rest drops (1/2) g t^2.
TEST(RigidBodies, FreeFall) {
  const std::vector<RigidBodyTold> told = {Box(3, 100, 1)};
  const int steps = 60;
  const double t = steps * kStepSeconds;
  const double drop = 0.5 * kGravity * t * t;
  RigidBodies bodies;
  bodies.begin(told);
  Step(&bodies, told, steps);
  const RigidBodyPlace place = Places(bodies, 1)[0];
  EXPECT_NEAR(100 - place.y, drop, 0.05 * drop);
  EXPECT_NEAR(place.x, 3, 1e-6);
  EXPECT_NEAR(place.turn, 0, 1e-6);
}

// Outside fact: with restitution 0 (Jolt's default) a dropped box does not
// bounce for ever; it comes to rest touching what holds it up. A body that
// is moved kinematically is not pushed by what lands on it.
TEST(RigidBodies, RestsOnFloor) {
  const std::vector<RigidBodyTold> told = {Floor(), Box(0, 1.5, 1)};
  RigidBodies bodies;
  bodies.begin(told);
  Step(&bodies, told, 150);
  const double y_before = Places(bodies, 2)[1].y;
  Step(&bodies, told, 30);
  const std::vector<RigidBodyPlace> places = Places(bodies, 2);
  EXPECT_NEAR(places[1].y - kHalf, kFloorTop, kTouching);
  EXPECT_NEAR(places[1].y, y_before, 1e-3);
  EXPECT_EQ(places[0].x, 0);
  EXPECT_EQ(places[0].y, 0);
  EXPECT_EQ(places[0].turn, 0);
}

// Outside fact: solid bodies do not pass through each other, so boxes dropped
// one above another end as a pile, each one box height above the one below.
TEST(RigidBodies, Piles) {
  const std::vector<RigidBodyTold> told = Pile();
  RigidBodies bodies;
  bodies.begin(told);
  Step(&bodies, told, 300);
  const std::vector<RigidBodyPlace> places = Places(bodies, 4);
  EXPECT_NEAR(places[1].y - kHalf, kFloorTop, kTouching);
  for (int i = 2; i <= 3; ++i) {
    EXPECT_GT(places[i].y, places[i - 1].y) << "box " << i;
    EXPECT_NEAR(places[i].y - places[i - 1].y, 2 * kHalf, kTouching)
        << "box " << i;
  }
}

// Outside fact: Newton's second law. A steady force F on a mass m at rest
// moves it (1/2) (F / m) t^2, and does nothing across its own direction.
TEST(RigidBodies, ForceMovesAsNewtonSays) {
  RigidBodyTold body = Box(0, 0, 2);
  body.gravity_factor = 0;
  body.force_x = 10;
  const std::vector<RigidBodyTold> told = {body};
  const int steps = 60;
  const double t = steps * kStepSeconds;
  const double moved = 0.5 * (body.force_x / body.mass) * t * t;
  RigidBodies bodies;
  bodies.begin(told);
  Step(&bodies, told, steps);
  const RigidBodyPlace place = Places(bodies, 1)[0];
  EXPECT_NEAR(place.x, moved, 0.05 * moved);
  EXPECT_NEAR(place.y, 0, 1e-6);
}

// Outside fact: BodyInterface::MoveKinematic gives a body the velocity that
// brings it to the target by the end of the step.
TEST(RigidBodies, MassZeroFollowsWhereItIsTold) {
  std::vector<RigidBodyTold> told = {Box(0, 0, 0)};
  RigidBodies bodies;
  bodies.begin(told);
  for (int i = 1; i <= 60; ++i) {
    told[0].x = 0.1 * i;
    bodies.step(told);
    const RigidBodyPlace place = Places(bodies, 1)[0];
    EXPECT_NEAR(place.x, told[0].x, 1e-3) << "step " << i;
    EXPECT_NEAR(place.y, 0, 1e-3) << "step " << i;
  }
}

// Outside fact: gravity does not move a kinematic body, and does move a
// dynamic one: (1/2) g t^2 is 1.23 m in half a second.
TEST(RigidBodies, LetGoFalls) {
  std::vector<RigidBodyTold> told = {Box(0, 10, 0)};
  RigidBodies bodies;
  bodies.begin(told);
  Step(&bodies, told, 30);
  EXPECT_NEAR(Places(bodies, 1)[0].y, 10, 1e-3);
  told[0].mass = 1;
  Step(&bodies, told, 30);
  EXPECT_LT(Places(bodies, 1)[0].y, 10 - 1.0);
}

// Outside fact: a body that is not in the world touches nothing, so a box
// above it falls freely, (1/2) g t^2, and ends below where it would be.
TEST(RigidBodies, NotPresentHoldsNothingUp) {
  RigidBodyTold absent = Floor();
  absent.present = false;
  const std::vector<RigidBodyTold> told = {absent, Box(0, 2, 1)};
  const int steps = 120;
  const double t = steps * kStepSeconds;
  const double drop = 0.5 * kGravity * t * t;
  RigidBodies bodies;
  bodies.begin(told);
  Step(&bodies, told, steps);
  const RigidBodyPlace box = Places(bodies, 2)[1];
  EXPECT_LT(box.y + kHalf, absent.y - absent.half_high);
  EXPECT_NEAR(2 - box.y, drop, 0.05 * drop);
}

// Outside fact: Jolt is deterministic, and a state saved with
// PhysicsSystem::SaveState and restored replays the same steps bit for bit
// (Docs/Architecture.md, "Deterministic Simulation" and "Saving the
// Simulation State").
TEST(RigidBodies, SameInputSameOutput) {
  RigidBodies a;
  a.begin(Pile());
  for (int i = 1; i <= 120; ++i) a.step(PileAt(i));

  RigidBodies b;
  b.begin(Pile());
  for (int i = 1; i <= 60; ++i) b.step(PileAt(i));
  const std::string saved = b.state();
  const double top_when_saved = Places(b, 4)[3].y;
  for (int i = 61; i <= 90; ++i) b.step(PileAt(i));
  // The steps to be undone did move something.
  EXPECT_NE(Places(b, 4)[3].y, top_when_saved);
  b.restore(saved);
  for (int i = 61; i <= 120; ++i) b.step(PileAt(i));

  const std::vector<RigidBodyPlace> places_a = Places(a, 4);
  const std::vector<RigidBodyPlace> places_b = Places(b, 4);
  for (int i = 0; i < 4; ++i) {
    EXPECT_EQ(places_b[i].x, places_a[i].x) << "body " << i;
    EXPECT_EQ(places_b[i].y, places_a[i].y) << "body " << i;
    EXPECT_EQ(places_b[i].turn, places_a[i].turn) << "body " << i;
  }
}

// Outside fact: it is the box that rests on the floor, not the body's own
// point. With the box's middle half a box above the point, the box's bottom
// edge is at the point, so the point itself ends at the floor's top edge.
TEST(RigidBodies, BoxMiddleAwayFromOwnPoint) {
  RigidBodyTold body = Box(0, 1.0, 1);
  body.middle_y = kHalf;
  const std::vector<RigidBodyTold> told = {Floor(), body};
  RigidBodies bodies;
  bodies.begin(told);
  Step(&bodies, told, 180);
  EXPECT_NEAR(Places(bodies, 2)[1].y, kFloorTop, kTouching);
}

}  // namespace
}  // namespace motolii
