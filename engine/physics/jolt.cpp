// Implements the adapter declared in physics.h on top of Jolt.
// Built as jolt_bench.cpp was: deterministic across platforms, single-threaded.
#include "physics/physics.h"
#include <Jolt/Jolt.h>
#include <Jolt/RegisterTypes.h>
#include <Jolt/Core/Factory.h>
#include <Jolt/Core/TempAllocator.h>
#include <Jolt/Core/JobSystemSingleThreaded.h>
#include <Jolt/Physics/PhysicsSettings.h>
#include <Jolt/Physics/PhysicsSystem.h>
#include <Jolt/Physics/Collision/Shape/BoxShape.h>
#include <Jolt/Physics/Collision/Shape/SphereShape.h>
#include <Jolt/Physics/Body/BodyCreationSettings.h>
#include <algorithm>
#include <mutex>
using namespace JPH;

namespace {
constexpr ObjectLayer STILL = 0, MOVING = 1;

// Collision filter: two bodies collide unless both are STILL.
struct Pairs final : ObjectLayerPairFilter { bool ShouldCollide(ObjectLayer a, ObjectLayer b) const override { return a == MOVING || b == MOVING; } };
// Maps each object layer to the broad-phase layer with the same number.
struct Broad final : BroadPhaseLayerInterface {
    uint GetNumBroadPhaseLayers() const override { return 2; }
    BroadPhaseLayer GetBroadPhaseLayer(ObjectLayer l) const override { return BroadPhaseLayer((BroadPhaseLayer::Type)l); }
#if defined(JPH_EXTERNAL_PROFILE) || defined(JPH_PROFILE_ENABLED)
    const char* GetBroadPhaseLayerName(BroadPhaseLayer) const override { return "layer"; }
#endif
};
// Broad-phase filter: an object layer is tested against a broad-phase layer unless both are
// STILL.
struct ObjectVsBroad final : ObjectVsBroadPhaseLayerFilter { bool ShouldCollide(ObjectLayer a, BroadPhaseLayer b) const override { return a == MOVING || (BroadPhaseLayer::Type)b == MOVING; } };
// Initializes Jolt's global state. Safe to call from any thread, any number of times.
void once() {
    static std::once_flag done;
    std::call_once(done, [] { RegisterDefaultAllocator(); Factory::sInstance = new Factory(); RegisterTypes(); });
}
// Returns the current pose of body `id`: center of mass position and rotation quaternion.
PhysPose read(BodyInterface& bi, BodyID id) {
    PhysPose p;
    const RVec3 at = bi.GetCenterOfMassPosition(id);
    const Quat q = bi.GetRotation(id);
    p.at[0] = (float)at.GetX(), p.at[1] = (float)at.GetY(), p.at[2] = (float)at.GetZ();
    p.turn[0] = q.GetX(), p.turn[1] = q.GetY(), p.turn[2] = q.GetZ(), p.turn[3] = q.GetW();
    return p;
}
}

// All state of a PhysWorld, hidden from physics.h so that it shows no Jolt types.
struct PhysWorld::Own {
    Pairs pairs; Broad broad; ObjectVsBroad ovb;
    TempAllocatorImpl temp{16 * 1024 * 1024};
    JobSystemSingleThreaded jobs{cMaxPhysicsJobs};
    PhysicsSystem ps;
    std::vector<PhysThing> things;
    std::vector<BodyID> bodies;
    // Per layer: true once the simulation has taken the layer over from its keyframes.
    std::vector<bool> handed;
    PhysKeyed keyed;
    // Cache of simulated poses, indexed by frame and then by layer.
    std::vector<std::vector<PhysPose>> poses;
};

// Creates one Jolt body per layer and caches the poses of frame 0.
// once() runs first so that Jolt is initialized before any Jolt object is created.
PhysWorld::PhysWorld(const std::vector<PhysThing>& things, float gravity, PhysKeyed keyed) : own((once(), new Own)) {
    Own& o = *own;
    o.things = things, o.keyed = std::move(keyed);
    o.ps.Init(4096, 0, 16384, 8192, o.broad, o.ovb, o.pairs);
    o.ps.SetGravity(Vec3(0, -gravity, 0));
    BodyInterface& bi = o.ps.GetBodyInterface();
    for (size_t i = 0; i < things.size(); ++i) {
        const PhysThing& t = things[i];
        const PhysPose p = o.keyed((int)i, 0.0);
        const Shape* shape = t.ball ? (Shape*)new SphereShape(std::max(t.half[0], 1e-3f))
                                    : (Shape*)new BoxShape(Vec3(std::max(t.half[0], 1e-3f), std::max(t.half[1], 1e-3f), std::max(t.half[2], 1e-3f)), std::min({0.05f, t.half[0], t.half[1], t.half[2]}));
        // A wall, or a layer still following its keyframes, is moved by the keyframes and is not
        // pushed by collisions.
        const bool keyedNow = t.still || t.until > 0.0;
        BodyCreationSettings s(shape, RVec3(p.at[0], p.at[1], p.at[2]), Quat(p.turn[0], p.turn[1], p.turn[2], p.turn[3]).Normalized(),
                               keyedNow ? EMotionType::Kinematic : EMotionType::Dynamic, MOVING);
        s.mRestitution = t.bounce, s.mFriction = t.friction;
        s.mAllowDynamicOrKinematic = true;
        if (t.flat) s.mAllowedDOFs = EAllowedDOFs::Plane2D;
        o.bodies.push_back(bi.CreateAndAddBody(s, EActivation::Activate));
        o.handed.push_back(!keyedNow);
    }
    o.poses.push_back({});
    for (BodyID id : o.bodies) o.poses.back().push_back(read(bi, id));
}
PhysWorld::~PhysWorld() = default;

// Steps the simulation forward until frame `frameIndex` is cached, then returns the pose of
// layer `index` at that frame. A negative frameIndex is treated as 0.
PhysPose PhysWorld::pose(int index, int frameIndex) {
    Own& o = *own;
    frameIndex = std::max(frameIndex, 0);
    if (index < 0 || index >= (int)o.bodies.size()) return {};
    BodyInterface& bi = o.ps.GetBodyInterface();
    const float dt = 1.f / 60.f;
    while ((int)o.poses.size() <= frameIndex) {
        // The time at which this step ends.
        const double at = (double)o.poses.size() / 60.0;
        for (size_t i = 0; i < o.bodies.size(); ++i) {
            const PhysThing& t = o.things[i];
            if (o.handed[i]) continue;
            if (!t.still && at > t.until) {
                // The last keyframe has passed. Switch the body to dynamic and give it the
                // velocity its keyframes had over the last step before `until`.
                const PhysPose a = o.keyed((int)i, t.until - dt), b = o.keyed((int)i, t.until);
                bi.SetMotionType(o.bodies[i], EMotionType::Dynamic, EActivation::Activate);
                bi.SetLinearVelocity(o.bodies[i], Vec3(b.at[0] - a.at[0], b.at[1] - a.at[1], b.at[2] - a.at[2]) / dt);
                o.handed[i] = true;
                continue;
            }
            const PhysPose p = o.keyed((int)i, at);
            bi.MoveKinematic(o.bodies[i], RVec3(p.at[0], p.at[1], p.at[2]), Quat(p.turn[0], p.turn[1], p.turn[2], p.turn[3]).Normalized(), dt);
        }
        o.ps.Update(dt, 1, &o.temp, &o.jobs);
        o.poses.push_back({});
        for (BodyID id : o.bodies) o.poses.back().push_back(read(bi, id));
    }
    return o.poses[(size_t)frameIndex][(size_t)index];
}
