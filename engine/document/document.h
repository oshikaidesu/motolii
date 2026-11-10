#ifndef MOTOLII_DOCUMENT_DOCUMENT_H_
#define MOTOLII_DOCUMENT_DOCUMENT_H_
// Defines Doc, the in-memory state of an open project.

#include <filament/MaterialInstance.h>
#include <filament/RenderTarget.h>
#include <filament/Scene.h>
#include <filament/Skybox.h>
#include <filament/Texture.h>
#include <math/mat4.h>
#include <math/vec2.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <sqlite3.h>
#include <utils/Entity.h>

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <string_view>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>

#include "community/absent_motion/absent_motion.h"
#include "community/playcanvas/splatfx.h"
#include "community/quickjs/script.h"
#include "media/video_layer.h"
#include "motion/easing_curves.h"
#include "motion/lottie_motion.h"
#include "physics/physics.h"
#include "stage/canvas/canvas_cache.h"
#include "stage/effects/screen_fx.h"
#include "stage/layer_effects/layer_fx.h"
#include "stage/render/gltf_model.h"
#include "stage/render/render_stage.h"

namespace motolii {

struct DocScript;
// Doc is an open project: the SQLite database plus the caches built from it.
// Most members are caches that are cleared at every change to the project.
struct Doc {
  // Held by whoever reads or changes the project. It lets the app read the
  // project while a frame is being drawn (see motolii.mm).
  std::recursive_timed_mutex lock;
  sqlite3* file = nullptr;
  Stage* stage = nullptr;
  // Why the last call that did not succeed was refused.
  std::string error;
  // The layers in stacking order, the one furthest back first. Read on first
  // use and cleared at every change.
  std::vector<int> laid;
  // The stage's grade as last applied by doc_look. It is applied again only
  // when the grade changes.
  std::string graded;
  // The values changed since the app last asked (motolii_changes), as (layer,
  // name) pairs taken from each undo step's changeset.
  std::set<std::pair<int, std::string>> changed;
  // Every layer changed by an undo step, in order. -1 means that any layer may
  // have changed. A relation that caches its result checks this to see whether
  // a layer it reads has changed.
  std::vector<int> touched;
  // Where doc_keys_of records each layer it reads while a caching relation is
  // evaluated.
  std::set<int>* reading = nullptr;
  // live: a window is drawing. A caching relation then gets a time slice of
  // each frame, starting at slice, and sets behind if it did not finish in time
  // (see relations.h). exact: the result must be right rather than quick.
  bool live = false, exact = false, behind = false;
  // Start of the time slice.
  std::chrono::steady_clock::time_point slice;
  // Whether a layer was added or removed since the app last asked.
  bool layers_changed = false;
  // Per-copy materials, keyed by the copy's entity: the layer's material
  // duplicated while its copies are colored individually. copyEdges holds the
  // same for the edge, the second part of a copy.
  std::map<uint32_t, filament::MaterialInstance*> copyLooks, copyEdges;
  // Each value's behavior (`<name>_by`), by layer and name. Found once and
  // cleared at every change.
  std::map<std::pair<int, std::string>, int> drivers;
  // Whether a layer has any value connected to a behavior. Computed on first
  // use and cleared at every change.
  std::unordered_map<int, bool> connects;
  // One relation's layers. members: the layers in order, with 0 where one was
  // removed. under: for each member, the relation it was in before; that
  // relation's result is this member's start. from: for each member, where it
  // showed when it joined, as x and y.
  struct Relation {
    std::vector<int> members, under;
    std::vector<double> from;
  };
  // Relation data by layer. Found once and cleared at every change.
  std::unordered_map<int, Relation> relationsOf;
  // Set while working out where layers settle. Relations that change with time,
  // follow and push, give nothing then, so a relation made while one is pushing
  // does not keep the push.
  bool settled = false;
  // Which copy, out of ctxN copies, doc_place is placing now. What a behavior
  // gives is for that copy.
  int ctxCopy = 0, ctxN = 1;
  // Where that copy lies on the stage once laid out, valid when ctxHasAt is
  // true. A behavior's falloff weighs it.
  bool ctxHasAt = false;
  filament::math::double3 ctxAt{0.0};
  // The room's own light, as it was when the stage was opened.
  float roomLight = 0.f;
  // Which room lights the stage now (see doc_look).
  std::string roomIs;
  // The room behind everything, once one is set.
  filament::Skybox* sky = nullptr;
  // The color behind everything: a flat color as large as the stage, drawn
  // before everything else in the stage's own view.
  Canvas2D* backdrop = nullptr;
  // The color the backdrop was made in.
  std::string backdropIs;
  // When true, every value a caller changes gets a keyframe at the current
  // time. This is the app's animate-all mode.
  bool keying = false;
  // The stage time at which keying was turned on. The first keyframe of a value
  // that is later than this time interpolates from this time.
  double keying_from = 0.0;
  // An act groups changes. The changes made from its beginning to its end are
  // one undo step, and if one of them is refused none is applied. Acts can
  // nest, and the outermost one is the undo step. How many acts are open,
  // nested one within another.
  int act = 0;
  // True while no change of the open act has been refused.
  bool act_ok = true;
  // A change inside a larger act has not been shown yet. The stage is matched
  // to the project once, when the act ends.
  bool act_unmatched = false;
  // True when the outermost act is motolii_together's. Every change inside it
  // is matched once, when it ends, as a keyframe is.
  bool act_together = false;
  // The layers that fall and collide (Jolt). Built on first use and rebuilt
  // when what it is built from changes.
  std::unique_ptr<PhysWorld> phys;
  // Which layer each of its bodies belongs to.
  std::vector<int> phys_of;
  // Which copy each body belongs to, for example a letter of split text. -1
  // means the layer as a whole.
  std::vector<int> phys_copy;
  // Until what time each body is driven by its keyframes.
  std::vector<double> phys_until;
  // phys_stale: the project changed since the world was last examined.
  // phys_any: some layer has physics.
  bool phys_stale = true, phys_any = false;
  // Everything the world was built from, as the project described it then. The
  // world is rebuilt only when this changes.
  std::string phys_made;
  // Copies laid out by a layer's script, per layer. from: the files that laid
  // them out, see doc_expressions_said.
  struct Scripted {
    double at = -1, own = -1;
    int made = -1;
    std::string from;
    std::vector<ScriptCopy> copies;
  };
  // Each layer's copies as its script placed them at one time. Worked out once
  // per frame.
  std::map<int, Scripted> scripted;
  // Copies laid out by AbsentMotion effects.
  struct AbsentKept {
    double at = -1;
    long changes = -1;
    int seen = -1;
    std::vector<AbsentCopy> copies;
  };
  // Each layer's copies as AbsentMotion's repeat effects lay them at the time
  // last asked, see doc_absent_copies.
  std::map<int, AbsentKept> absentKept;
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
  // Each freehand stroke's outline as AbsentMotion's drawing effects last made
  // it, together with what it was made from. See doc_evaluate.
  std::map<int, std::pair<std::string, std::string>> drawingKept;
  // The project's scripts, each run as its file specifies (see scripts.h).
  std::shared_ptr<struct DocScripts> scripts;
  // The layers that have effects of their own (layer_fx.h). Each is drawn alone
  // with its effects applied and is laid where the layer lies.
  std::map<int, ThingFx> layerFx;
  // A layer that reads what is under it: seen is its image of what is below,
  // into is the target that image is drawn to.
  struct Read {
    filament::Texture* seen = nullptr;
    filament::RenderTarget* into = nullptr;
  };
  // The layers that read what is under them, each with its image of it (see
  // doc_layers_read).
  std::map<int, Read> reads;
  // Which layer each of the stage's `before` entries belongs to.
  std::vector<int> beforeOf;
  // The stage's whole-screen effects: its script .wgsl files, one over another
  // (screen_fx.h).
  ScreenStack screen;
  // When true, positions are read from the layers' keyframes rather than from
  // the physics world.
  bool phys_keyed = false;
  // True while the project is being exported as a video. It can be read but not
  // changed until the export is done.
  bool writing = false;
  // The window looks through its working camera, like After Effects' working 3D
  // views and Alight Motion's view without the camera. Never saved in the
  // project.
  bool viewCameraAsked = false;
  // The working camera's position around the middle of the world, as three
  // numbers: about, over and how far, the last being a camera's distance.
  double viewCameraIs[3] = {0.0, 0.0, 1.0};
  // True when the stage is seen through the working camera at this time: a
  // camera is on and no video is being exported.
  bool working = false;
  // The time of the project at which the video being exported begins, which is
  // the start of its work area.
  double written_from = 0.0;
  // The camera the stage is seen through now. 0 means the stage's own camera
  // (see doc_evaluate).
  int looking = 0;
  // The length of the project as last shown. Waves, noise and drifts go round
  // in it a whole number of times, so that an exported video loops.
  double round = 8.0;
  // SQLite's own record of what the open act changes.
  sqlite3_session* acting = nullptr;
  // A layer being dragged (see doc_hold). What is carried shows at once but is
  // not yet in the project. layer is -1 when nothing is held; 0 is the stage,
  // which a caller can hold through a value of its own. said holds a carried
  // word or the moved points of a path.
  struct Held {
    int layer = -1;
    std::map<std::string, double> from, tried;
    std::map<std::string, std::string> said;
  } held;
  // The keyframes of one value. at, value and interp: the time, value and
  // easing of each keyframe. own: an easing defined in the project, used where
  // the segment is not one of the nine built-in kinds. loop: how the keys are
  // gone through again past the last.
  struct Keys {
    std::vector<double> at, value;
    std::vector<Interp> interp;
    std::vector<std::string> own;
    std::string loop;
  };
  // Hash that lets a map be searched with a std::string_view without building a
  // std::string.
  struct NameHash {
    using is_transparent = void;
    size_t operator()(std::string_view n) const {
      return std::hash<std::string_view>{}(n);
    }
  };
  // Each value's keyframes and the easing of the segment after each, by layer
  // and name. Read from the keyframes on first use and cleared at every change.
  std::unordered_map<
      int, std::unordered_map<std::string, Keys, NameHash, std::equal_to<>>>
      moving;
  struct HeardWordHash {
    size_t operator()(const std::pair<int, const char*>& k) const {
      return std::hash<int>{}(k.first) * 31u ^
             std::hash<const void*>{}(k.second);
    }
  };
  // Words of values, cached the same way as moving.
  std::unordered_map<std::pair<int, const char*>, std::string, HeardWordHash>
      heardWords;
  // Where doc_place's own values have their keyframes, by layer and the place
  // of the name in the program. A literal never names another value. Found once
  // and cleared at every change.
  std::unordered_map<std::pair<int, const char*>, const Keys*, HeardWordHash>
      literals;
  // A layer's copy_tall as numbers.
  std::unordered_map<int, std::vector<double>> talls;
  struct Placing {
    bool laid = false;
    std::vector<DocScript*> scs;
    std::string from;
    double absentAt = -1e300;
    std::vector<AbsentEffect> absent;
  };
  // What doc_place asks of a layer's effects, which is the same for each of its
  // copies. Asked once per layer while a time is being evaluated, as for talls.
  std::unordered_map<int, Placing> placing;
  bool evaluating = false;
  // A layer's half size and depth (doc_half). Worked out once per time, because
  // all its copies ask for it.
  std::map<int, std::pair<filament::math::float2, float>> halves;
  // Each value's word, cached the same way as moving.
  std::map<std::pair<int, std::string>, std::string> words;
  // The times of each value's keyframes, cached the same way as moving.
  std::map<std::pair<int, std::string>, std::vector<double>> keyed;
  // Prepared SQLite statements for an easing by its name and by its expression.
  // Each is prepared once and then evaluated by SQLite.
  std::map<std::string, sqlite3_stmt*> named, expression_statements;
  // One layer as it is on the stage, and what it was made of.
  struct Shown {
    std::string of;
    Video* video = nullptr;
    Canvas2D* drawn = nullptr;
    Solid* solid = nullptr;
    Mesh* shape = nullptr;
    bool in = true, clipped = false, camera = false, drivenLooks = false,
         behaviour = false, grains = false;
    std::shared_ptr<SplatEffect> splatFx;
    std::string splatFxFile;
    filament::MaterialInstance* splatPlain = nullptr;
    bool splatDone = false;
    int run = -1, lies = -1;
    // sketch: a p5.js sketch's mesh and what it was last made from (see
    // sketch.h).
    bool sketch = false;
    int sketchFrame = -1;
    int sketchMade = -1;
    filament::math::float3 sketchEye{};
    std::map<int, float> sketchStrong;
    std::vector<SketchShape> sketchShapes;
    std::vector<Canvas2D*> sketchPics;
    std::vector<SketchPaint> sketchPaints;
    size_t sketchParts = 1;
    // The layer's Filament light, if it is a light. It is in every scene of the
    // stage while the light is on.
    utils::Entity light;
    // For a flat layer: points of the image per unit of the stage as it was
    // made. Its effects are counted in this unit.
    double units = 1.0;
    // How the layer is placed: 2 is a flat layer on the camera, 25 is one in
    // the world, 3 is a solid layer or a camera.
    int space = 3;
    // A text's words as made, and whether AbsentMotion's text effects change
    // them as time goes (see doc_text_shown).
    std::string words;
    bool wordsMove = false;
    // A level's drawing as made, and whether its keyframes change it as time
    // goes.
    double cel = -2;
    bool celMove = false;
    // The scene the layer is in and its channel there. If none is set, the
    // stage's own scene, where the layer was made.
    filament::Scene* scene = nullptr;
    int channel = -1;
    // A solid's own material, made by the render code. A matte cuts it.
    filament::MaterialInstance* look = nullptr;
    // A 3D layer of an After Effects image: a sheet of its own, placed where
    // the layer is.
    struct Deep {
      uint32_t id;
      Canvas2D* sheet;
      filament::math::float4 box;
    };
    std::vector<Deep> deep;
    // motion: the same file, read for its poses only. They give the position of
    // each part.
    std::shared_ptr<Motion> motion;
  };
  // The camera of the current time, against the stage's own camera, which is 6
  // units in front and 30 degrees high. rig is how the world is moved for the
  // camera, and a 2D layer moves with it. facing is only how the world is
  // turned, and a 2.5D layer keeps its own angle.
  filament::math::mat4 rig, facing;
  // True if the lens blurs what is off its focus. Applies to solid layers and
  // layers in the world only.
  bool blurred = false;
  // A layer clipped by the flat layer before it. matte: the render code's matte
  // that cuts it, its own. from: the layer whose image cuts it. look: the
  // material of the layer that the matte was told about. how: how it was last
  // cut: by transparency or by brightness, inverted or not, and how soft.
  struct Cut {
    int matte = -1, from = 0;
    const Canvas2D* by = nullptr;
    filament::MaterialInstance* look = nullptr;
    std::string how;
  };
  std::map<int, Cut> cuts;
  // The layers as they are on the stage, and what each was made of.
  std::map<int, Shown> shown;
  // A layer's copies laid along another layer's outline: where, worked out once
  // per time.
  struct Along {
    double at = -1.0, key = 0.0;
    const void* of = nullptr;
    std::vector<float> each;
  };
  std::map<int, Along> along;
  // Where a layer was at a tick of a trail's own grid. Worked out once and
  // cleared at every change.
  std::map<std::tuple<int, double, long long>, filament::math::double3> tracks;
};

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_DOCUMENT_H_
