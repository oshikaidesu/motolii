#include "community/jolt/rigid_bodies.h"

#include <Jolt/Jolt.h>

#include <Jolt/Core/Factory.h>
#include <Jolt/Core/JobSystemSingleThreaded.h>
#include <Jolt/Core/TempAllocator.h>
#include <Jolt/Physics/Body/BodyCreationSettings.h>
#include <Jolt/Physics/Body/BodyInterface.h>
#include <Jolt/Physics/Body/BodyLock.h>
#include <Jolt/Physics/Collision/BroadPhase/BroadPhaseLayerInterfaceTable.h>
#include <Jolt/Physics/Collision/BroadPhase/ObjectVsBroadPhaseLayerFilterTable.h>
#include <Jolt/Physics/Collision/ObjectLayerPairFilterTable.h>
#include <Jolt/Physics/Collision/Shape/BoxShape.h>
#include <Jolt/Physics/Collision/Shape/RotatedTranslatedShape.h>
#include <Jolt/Physics/PhysicsSystem.h>
#include <Jolt/Physics/StateRecorderImpl.h>
#include <Jolt/RegisterTypes.h>

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <mutex>

namespace motolii {

namespace {
// The two kinds of body Jolt is told of (its object layers): one that touches
// the others of its kind, and one whose layer is not on, which touches
// nothing.
constexpr JPH::ObjectLayer kOn = 0, kOff = 1;
constexpr float kStep = 1.f / 60.f;

JPH::Quat turned(double turn) {
  return JPH::Quat::sRotation(JPH::Vec3::sAxisZ(), (float)turn);
}
JPH::RVec3 at(const RigidBodyTold& t) {
  return JPH::RVec3((float)t.x, (float)t.y, 0);
}
}  // namespace

struct RigidBodies::Own {
  // What Jolt's HelloWorld sets up before a PhysicsSystem, in its order.
  std::unique_ptr<JPH::TempAllocatorImpl> temp;
  std::unique_ptr<JPH::JobSystemSingleThreaded> jobs;
  std::unique_ptr<JPH::BroadPhaseLayerInterfaceTable> broad;
  std::unique_ptr<JPH::ObjectLayerPairFilterTable> pairs;
  std::unique_ptr<JPH::ObjectVsBroadPhaseLayerFilterTable> object_broad;
  std::unique_ptr<JPH::PhysicsSystem> system;
  std::vector<JPH::BodyID> ids;
  // Whether each body's layer was on at the last step. Kept with the state.
  std::string present;
};

RigidBodies::RigidBodies() : own(new Own) {
  static std::once_flag once;
  std::call_once(once, [] {
    // The library and this file must have been compiled with the same Jolt
    // switches (deps/jolt.sh); Jolt's own check.
    if (!JPH::VerifyJoltVersionID()) std::abort();
    JPH::RegisterDefaultAllocator();
    JPH::Factory::sInstance = new JPH::Factory();
    JPH::RegisterTypes();
  });
  // 10 MB for a step's temporary memory, as HelloWorld.cpp.
  own->temp = std::make_unique<JPH::TempAllocatorImpl>(10 * 1024 * 1024);
  own->jobs =
      std::make_unique<JPH::JobSystemSingleThreaded>(JPH::cMaxPhysicsJobs);
  own->broad = std::make_unique<JPH::BroadPhaseLayerInterfaceTable>(2, 2);
  own->broad->MapObjectToBroadPhaseLayer(kOn, JPH::BroadPhaseLayer(0));
  own->broad->MapObjectToBroadPhaseLayer(kOff, JPH::BroadPhaseLayer(1));
  own->pairs = std::make_unique<JPH::ObjectLayerPairFilterTable>(2);
  own->pairs->EnableCollision(kOn, kOn);
  own->object_broad = std::make_unique<JPH::ObjectVsBroadPhaseLayerFilterTable>(
      *own->broad, 2, *own->pairs, 2);
}

RigidBodies::~RigidBodies() = default;

void RigidBodies::begin(const std::vector<RigidBodyTold>& told) {
  own->system = std::make_unique<JPH::PhysicsSystem>();
  // The counts HelloWorld.cpp names for a real project: 65536 bodies, 65536
  // body pairs, 10240 contact constraints; 0 mutexes is Jolt's default count.
  own->system->Init(65536, 0, 65536, 10240, *own->broad, *own->object_broad,
                    *own->pairs);
  JPH::BodyInterface& bodies = own->system->GetBodyInterface();
  own->ids.clear(), own->present.clear();
  for (const RigidBodyTold& t : told) {
    // The box is as deep as TwoDFunnelTest's walls (1 m each way): depth does
    // not show in a plane, and the mass is told, not worked out from it.
    const JPH::Vec3 half((float)std::max(t.half_wide, 1e-3),
                         (float)std::max(t.half_high, 1e-3), 1.f);
    JPH::BodyCreationSettings made(
        new JPH::RotatedTranslatedShape(
            JPH::Vec3((float)t.middle_x, (float)t.middle_y, 0),
            JPH::Quat::sIdentity(), new JPH::BoxShape(half)),
        at(t), turned(t.turn),
        t.mass > 0 ? JPH::EMotionType::Dynamic : JPH::EMotionType::Kinematic,
        t.present ? kOn : kOff);
    made.mAllowedDOFs = JPH::EAllowedDOFs::Plane2D;
    made.mOverrideMassProperties =
        JPH::EOverrideMassProperties::CalculateInertia;
    // A body that only follows its layer for now still needs a mass to be
    // worked out with; it is scaled to the one told when it is let go.
    made.mMassPropertiesOverride.mMass = t.mass > 0 ? (float)t.mass : 1.f;
    if (!std::isnan(t.gravity_factor))
      made.mGravityFactor = (float)t.gravity_factor;
    if (!std::isnan(t.restitution)) made.mRestitution = (float)t.restitution;
    if (!std::isnan(t.friction)) made.mFriction = (float)t.friction;
    own->ids.push_back(
        bodies.CreateAndAddBody(made, JPH::EActivation::Activate));
    own->present.push_back(t.present ? 1 : 0);
  }
}

void RigidBodies::step(const std::vector<RigidBodyTold>& told) {
  if (!own->system) return;
  JPH::BodyInterface& bodies = own->system->GetBodyInterface();
  const size_t n = std::min(told.size(), own->ids.size());
  for (size_t i = 0; i < n; ++i) {
    const RigidBodyTold& t = told[i];
    const JPH::BodyID id = own->ids[i];
    const bool was = own->present[i] != 0;
    own->present[i] = t.present ? 1 : 0;
    if (bodies.GetObjectLayer(id) != (t.present ? kOn : kOff))
      bodies.SetObjectLayer(id, t.present ? kOn : kOff);
    // A body whose layer is not on, or has just come on, is put where it is
    // told, at rest.
    if (!t.present || !was)
      bodies.SetPositionRotationAndVelocity(id, at(t), turned(t.turn),
                                            JPH::Vec3::sZero(),
                                            JPH::Vec3::sZero());
    const JPH::EMotionType type =
        t.present && t.mass > 0 ? JPH::EMotionType::Dynamic
                                : JPH::EMotionType::Kinematic;
    if (bodies.GetMotionType(id) != type)
      bodies.SetMotionType(id, type, JPH::EActivation::Activate);
    if (!t.present) continue;
    if (!std::isnan(t.gravity_factor))
      bodies.SetGravityFactor(id, (float)t.gravity_factor);
    if (!std::isnan(t.restitution))
      bodies.SetRestitution(id, (float)t.restitution);
    if (!std::isnan(t.friction)) bodies.SetFriction(id, (float)t.friction);
    if (t.mass <= 0) {
      bodies.MoveKinematic(id, at(t), turned(t.turn), kStep);
      continue;
    }
    {
      JPH::BodyLockWrite lock(own->system->GetBodyLockInterface(), id);
      if (lock.Succeeded()) {
        JPH::MotionProperties* moves = lock.GetBody().GetMotionProperties();
        const float inverse = moves->GetInverseMassUnchecked();
        if (inverse <= 0 ||
            std::fabs(1.f / inverse - (float)t.mass) > 1e-6f * (float)t.mass)
          moves->ScaleToMass((float)t.mass);
      }
    }
    if (t.force_x != 0 || t.force_y != 0)
      bodies.AddForce(id, JPH::Vec3((float)t.force_x, (float)t.force_y, 0));
  }
  // One collision step in a step of 1/60 s, as HelloWorld.cpp.
  own->system->Update(kStep, 1, own->temp.get(), own->jobs.get());
}

std::vector<RigidBodyPlace> RigidBodies::places() const {
  std::vector<RigidBodyPlace> all;
  if (!own->system) return all;
  const JPH::BodyInterface& bodies = own->system->GetBodyInterface();
  for (const JPH::BodyID id : own->ids) {
    JPH::RVec3 p;
    JPH::Quat q;
    bodies.GetPositionAndRotation(id, p, q);
    // The bodies turn about z alone.
    all.push_back({(double)p.GetX(), (double)p.GetY(),
                   2.0 * std::atan2((double)q.GetZ(), (double)q.GetW())});
  }
  return all;
}

std::string RigidBodies::state() const {
  if (!own->system) return "";
  JPH::StateRecorderImpl kept;
  own->system->SaveState(kept);
  return own->present + kept.GetData();
}

void RigidBodies::restore(const std::string& state) {
  const size_t n = own->ids.size();
  if (!own->system || state.size() < n) return;
  own->present = state.substr(0, n);
  JPH::StateRecorderImpl kept;
  kept.WriteBytes(state.data() + n, state.size() - n);
  own->system->RestoreState(kept);
}

}  // namespace motolii
