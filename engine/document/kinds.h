#ifndef MOTOLII_DOCUMENT_KINDS_H_
#define MOTOLII_DOCUMENT_KINDS_H_
// Defines Doc, the in-memory state of an open project, and doc_values, the
// table of named values that layers can have.

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
// The kinds of layer.
inline const char* const doc_kinds =
    "video image text solid shape camera light";
// The kinds of layer that are seen.
inline const char* const doc_visible_kinds = "video image text solid shape";
// The kinds of relation. A group is the plainest: layers in an order and
// nothing else.
inline const char* const doc_relations = "around row follow push group relate";
// The built-in shapes a solid can have.
inline const char* const doc_shapes = "ring gem cube ball sketch";
// SQL condition for whether a value is keyed. See doc_key.
#define DOC_KEYED                                                         \
  "(select count(*) > 1 or max(at) <> 0 or max(easing) is not null from " \
  "keyframe where layer = %d and name = %Q)"
// A named value that a layer can have: its name, the kinds of layer that have
// it, a range from low to high or a list of allowed words, and whether it can
// move, that is take keyframes. open: low and high only say how far the control
// goes. A value typed beyond them is accepted, like After Effects' slider range
// and valid range (PF_FloatSliderDef).
struct DocValue {
  const char* name;
  const char* kinds;
  double low, high;
  bool moves;
  const char* words;
  bool open = false;
};
inline const DocValue doc_values[] = {
    // For a group, z is how far its layers are away when it is out.
    {"x", "video image text solid shape camera light behaviour", -1e4, 1e4,
     true, nullptr},
    {"y", "video image text solid shape camera light behaviour", -1e4, 1e4,
     true, nullptr},
    {"z", doc_kinds, -1e4, 1e4, true, nullptr},
    // For a relation, rotate is added to each of its layers in turn.
    {"rotate", "video image text solid shape camera light behaviour", -1e6, 1e6,
     true, nullptr},
    {"rotate_x", "video image text solid shape camera light behaviour", -1e6,
     1e6, true, nullptr},
    {"rotate_y", "video image text solid shape camera light behaviour", -1e6,
     1e6, true, nullptr},
    // Turns the layer the way it is going along its path, with its rotate
    // added. Like After
    // Effects' Auto-Orient.
    {"orient", "video image text solid shape", 0, 1, false, nullptr},
    // Scale along each axis as a multiple of the size, each on its own as After
    // Effects' Scale.
    // Below 0 flips the layer. A flat layer's scale_z is its thickness: if not
    // set, the layer is
    // flat. If set, its sheet becomes a box that its image is pushed through
    // (deep.glsl), like
    // After Effects' Extrusion Depth and Apple Motion's Depth on a flat text
    // solid. 0 closes it to
    // a sheet again.
    {"scale_x", doc_visible_kinds, -1e4, 1e4, true, nullptr},
    {"scale_y", doc_visible_kinds, -1e4, 1e4, true, nullptr},
    {"scale_z", "solid text shape image", -1e4, 1e4, true, nullptr},
    // physics: none, moves, or still. A layer that moves falls and strikes
    // others, and the world
    // takes it from its last keyframe on. A layer that is still is a wall where
    // the project puts
    // it. bounce is how much it bounces and friction how it rubs. gravity is
    // the stage's pull down,
    // in units of the stage per second per second.
    {"physics", doc_visible_kinds, 0, 0, false, "none moves still"},
    // script: a preset as code, a JavaScript file that gives the position of
    // each copy (script_runner.h).
    // The parameters in its header are values of the layer, named js_ plus the
    // parameter's name.
    // For the stage, script is a whole-screen effect: a .wgsl file
    // (screen_fx.h).
    {"script", "image text shape solid stage behaviour", 0, 0, false, ""},
    // fx: a layer's own effects, like After Effects' effects on a layer. They
    // are the whole-screen
    // effects' .wgsl files, one over another, applied to the layer as the
    // camera sees it. A
    // camera's fx are AbsentMotion's motions only, and they move its place as
    // AbsentMotion's camera
    // is moved (doc_fx_say).
    {"fx", "video image text shape solid camera", 0, 0, false, ""},
    // The effects that are turned off, as the titles of their cards separated
    // by ";". Like Alight
    // Motion's eye on an effect. Their values are kept.
    {"fx_off", "video image text shape solid camera", 0, 0, false, ""},
    {"bounce", doc_visible_kinds, 0, 1, false, nullptr},
    {"friction", doc_visible_kinds, 0, 2, false, nullptr},
    {"gravity", "stage", -100, 100, false, nullptr},
    // The layer that the stage's effects follow in place of a mouse. Their
    // pointer, center, mouse
    // or point parameters are where that layer is on the image. 0 means none.
    {"follow", "stage", 0, 1e9, false, nullptr},
    {"size", "video image text solid shape behaviour", 1e-3, 1e4, true,
     nullptr},
    {"anchor_x", doc_visible_kinds, -100, 100, true, nullptr},
    {"anchor_y", doc_visible_kinds, -100, 100, true, nullptr},
    {"anchor_z", doc_visible_kinds, -100, 100, true, nullptr},
    // distance and zoom: a camera looks at where it is, from around it as it is
    // turned, from so far
    // away or so near.
    {"distance", "camera", 0.01, 100, true, nullptr},
    {"zoom", "camera", 0.01, 100, true, nullptr},
    // The camera's lens: focus is how far from the camera layers are sharp, 0
    // being where it looks.
    // aperture is the f-number, and 0 means everything is sharp.
    // blur_level is After Effects' Blur Level: how many times the lens's own
    // blur.
    {"focus", "camera", 0, 1e4, true, nullptr},
    {"aperture", "camera", 0, 64, true, nullptr},
    {"blur_level", "camera", 0, 100, true, nullptr},
    {"opacity", "video image text shape behaviour", 0, 1, true, nullptr},
    {"clip", doc_visible_kinds, 0, 1, false, nullptr},
    // clip: the layer is clipped by the flat layer before it, with the render
    // code's matte.
    // clip_matte chooses whether the matte is how clear that layer is or how
    // light it is, like
    // After Effects' alpha and luma mattes. clip_invert does the opposite.
    // clip_feather softens the
    // edge, in points of the screen.
    // A group made to mask: its top layer is the shape that the others in it
    // are seen through, or
    // cut out by. Alight Motion's Group and Mask and Group and Exclude, see
    // docs/design/alight_motion_ui.md.
    {"group_mask", "shape", 0, 0, false, "none mask exclude"},
    // A solid is cut by a box, not a matte.
    {"clip_matte", "video image text shape", 0, 0, false, "alpha luma"},
    {"clip_invert", "video image text shape", 0, 1, false, nullptr},
    {"clip_feather", "video image text shape", 0, 500, false, nullptr},
    // After Effects' own: while any layer is solo only those layers are seen,
    // and a locked layer
    // cannot be changed.
    {"solo", doc_kinds, 0, 1, false, nullptr},
    {"lock", doc_kinds, 0, 1, false, nullptr},
    {"visible", "video image text solid shape camera light behaviour", 0, 1,
     false, nullptr},
    {"order", doc_kinds, -1e9, 1e9, false, nullptr},
    {"wide", "shape", 1e-3, 1e3, false, nullptr},
    {"shape", "shape", 0, 0, false,
     "rect circle solid polygon star line wave null ring arc arrow squircle "
     "cog path spiral chamfer"},
    // crop_left, crop_top, crop_right and crop_bottom cut a photo in from each
    // side, as a share of
    // its width or height, like Alight Motion's crop. points, inner and round
    // are a polygon's or
    // star's points, a star's inner points, and its rounded corners.
    {"points", "shape", 1, 360, false, nullptr},
    {"inner", "shape", 0.01, 1, false, nullptr},
    {"round", "shape image", 0, 0.5, true, nullptr},
    {"crop_left", "image", 0, 0.95, false, nullptr},
    {"crop_top", "image", 0, 0.95, false, nullptr},
    {"crop_right", "image", 0, 0.95, false, nullptr},
    {"crop_bottom", "image", 0, 0.95, false, nullptr},
    {"start", doc_kinds, 0, 1e6, false, nullptr},
    {"duration", doc_kinds, 1e-3, 1e6, false, nullptr},
    {"begin", "video image text shape", 0, 1e6, false, nullptr},
    {"speed", "video solid image text shape", -100, 100, false, nullptr},
    {"keyed", "video", 0, 1, false, nullptr},
    // time_remap: the seconds of its own that a program is at, keyed like After
    // Effects' Time Remap
    // (doc_own_time). time_remap_loop: what happens past its last keyframe,
    // like loopOut
    // (doc_keys_at).
    {"time_remap", "image text shape solid", 0, 1e6, true, nullptr},
    {"time_remap_loop", "image text shape solid", 0, 0, false,
     "none cycle pingpong offset"},
    // The time in seconds at which the project's own image is drawn. Below 0
    // means where the
    // playhead was left. Alight Motion's Set Project Thumbnail, see
    // motolii_poster.
    {"poster_at", "stage", -1, 1e6, false, nullptr},
    // How long a layer that is added lasts, in seconds. 0 means to the end of
    // the project.
    // AbsentMotion's New Layer Length, see doc_add.
    {"layer_length", "stage", 0, 3600, false, nullptr},
    // The project's tempo in beats per minute, 0 meaning none. The timeline's
    // grid goes by it, like
    // Live's Tempo field. Alight Motion has none.
    {"bpm", "stage", 0, 999, false, nullptr},
    // Where a bar begins, in seconds, like Live's Set 1.1.1 Here.
    {"bpm_from", "stage", 0, 1e6, false, nullptr},
    // For the stage, the project's frame rate: the whole project is seen only
    // at its frames
    // (time_is in render_layers.h). For a layer, its own frames per second,
    // with 0 meaning the
    // stage's (doc_stepped).
    {"frame_rate", "video image text solid shape stage", 0, 60, false, nullptr},
    // speed_hold: where the layer's Speed holds it in time, like After Effects'
    // Time Stretch: its
    // start, the playhead, or its end.
    {"speed_hold", "video solid image text shape", 0, 0, false,
     "start now end"},
    // How loud the layer's sound is heard and exported: 1 as it comes, 0 none,
    // 2 twice as loud.
    // Alight Motion's Volume, 0 to 200%.
    {"volume", "video", 0, 2, true, nullptr},
    // Where its sound strikes: the layer is louder by this many dB at once. 0
    // shows none.
    {"beats", "video", 0, 60, false, nullptr},
    {"blend", "video image text shape", 0, 0, false,
     "normal add multiply screen darken lighten overlay soft_light hard_light "
     "color_dodge color_burn difference exclusion hue saturation color "
     "luminosity linear_burn linear_light vivid_light pin_light darker_color "
     "lighter_color subtract divide"},
    {"file", "video image solid text", 0, 0, false, ""},
    {"shape", "solid", 0, 0, false, doc_shapes},
    {"text", "text", 0, 0, false, ""},
    {"fill", "text solid shape light", 0, 0, false, ""},
    {"fill_media", "shape", 0, 0, false, ""},
    // A level's: which of its drawings is shown, by the number in its file name
    // (doc_cel_file),
    // held from keyframe to keyframe as a timesheet holds it. -1 means none,
    // the cross of a
    // timesheet.
    {"cel", "image", -1, 1e6, true, nullptr},
    // An After Effects file's named stretch that it plays over and over. all
    // means the whole file.
    {"marker", "image", 0, 0, false, ""},
    // What the layer is called where layers are listed, behaviors included. If
    // not set, it is named
    // by its kind.
    {"name", "video image text solid shape camera light behaviour", 0, 0, false,
     ""},
    // Its color on the timeline, chosen from Ableton Live's clip colors in the
    // window's order. auto
    // picks one by the layer's number.
    {"label", doc_kinds, 0, 0, false,
     "auto rose orange yellow lime green mint aqua sky blue periwinkle orchid "
     "magenta red tangerine azure teal"},
    // The element the layer was put in from, linked. Its file is written as a
    // preset writes it,
    // {own}/elements/... See doc_element_add and Alight Motion's Element.
    {"element", doc_kinds, 0, 0, false, ""},
    // An element's re-timing (doc_element_clock).
    {"retime", doc_kinds, 0, 0, false,
     "freeze stretch loop loop_stretch blank"},
    {"retime_in", doc_kinds, 0, 1e6, false, nullptr},
    {"retime_out", doc_kinds, 0, 1e6, false, nullptr},
    {"element_length", doc_kinds, 0, 1e6, false, nullptr},
    // What an inserted element keeps of where it came from (doc_element_marks).
    {"element_at", doc_kinds, -1, 1e12, false, nullptr},
    {"element_part", doc_kinds, 0, 1e9, false, nullptr},
    {"element_text", "text", 0, 0, false, ""},
    // What an author wrote about the layer for whoever opens the project next:
    // After Effects' layer
    // comment.
    {"note", doc_kinds, 0, 0, false, ""},
    // For a 3D file: which of the file's own animations it plays, over and
    // over, at its speed, from
    // when the layer comes on.
    {"animation", "solid", 0, 0, false, ""},
    // A light, Filament's own, created as a sun, a point or a spot (its file).
    // intensity: how
    // strong it is, 1 being as bright as the stage's own light. falloff: how
    // far a point or spot
    // reaches, in units of the stage. cone: how wide a spot's cone is, in
    // degrees. shadows: whether
    // the solid layers it lights cast shadows. Its color is its fill. It shines
    // the way it is
    // turned, straight ahead of it.
    {"intensity", "light", 0, 100, true, nullptr},
    {"falloff", "light", 0.01, 1000, false, nullptr},
    {"cone", "light", 1, 89, true, nullptr},
    {"shadows", "light", 0, 1, false, nullptr},
    // How soft its shadows are, as from a larger lamp: Filament's PCSS. 0 is
    // crisp.
    {"shadow_softness", "light", 0, 1, false, nullptr},
    // Filament's contact shadows: the thin shadow where layers touch, which its
    // shadow map misses,
    // found on the image.
    {"contact_shadows", "light", 0, 1, false, nullptr},
    // A sun seen in the room behind it (behind set to room): Filament's own
    // disk. sun_size is its
    // size in degrees across and sun_halo is the glow around it.
    {"sun_size", "light", 0, 10, true, nullptr},
    {"sun_halo", "light", 0, 100, true, nullptr},
    // Filament's light channels: a light of group 1 to 7 lights only the solids
    // of that group. 0,
    // the default, lights the solids of group 0 and every other.
    {"light_group", "light solid", 0, 7, false, nullptr},
    {"parent", doc_kinds, 0, 1e9, false, nullptr},
    // How much of its parent's rotation and size it takes: 1 all, 0 none, 2
    // twice. Alight Motion's
    // Parenting Helper weights.
    {"parent_rotate", doc_kinds, 0, 2, true, nullptr},
    {"parent_size", doc_kinds, 0, 2, true, nullptr},
    // Alight Motion's Scale Assist, working on scale_x and scale_y: grown one
    // way alone, or wider
    // and as much thinner as a squashed ball keeps its bulk.
    {"scale_assist", doc_visible_kinds, 0, 0, false, "y x both"},
    {"scale_assist_amount", doc_visible_kinds, 0, 100, true, nullptr},
    {"scale_assist_damp", doc_visible_kinds, 1, 10, true, nullptr},
    // roll: turned like a wheel rolling as the layer goes along x or y. The
    // wheel's radius is half
    // its smaller side plus roll_radius.
    {"roll", doc_kinds, 0, 0, false, "x y"},
    {"roll_radius", doc_kinds, -1e3, 1e3, true, nullptr},
    // A point cloud's: dissolve throws its grains out, each its own way, this
    // far. grain is how
    // large they are drawn (point_cloud.h).
    {"dissolve", "solid", 0, 100, true, nullptr},
    {"grain", "solid", 0.05, 20, true, nullptr},
    // mosh: a real datamosh. From mosh_at, a time of its video, the other
    // layer's motion is poured
    // into its last image (video_datamosh.h). mosh_with: the layer it goes
    // with. It is moved,
    // turned and sized as that layer is, then as itself. 0 means none.
    {"mosh", "video", 0, 1, false, nullptr},
    {"mosh_with", "video", 0, 1e9, false, nullptr},
    {"mosh_at", "video", 0, 1e6, false, nullptr},
    // space: 2d is not in the world and lies by the order alone. 2.5d is a
    // sheet in the world, in
    // front or behind by depth, always facing the viewer. 3d is filmed as it
    // is, with the camera
    // turning round it, as a solid is.
    {"space", "video image text shape", 0, 0, false, "2d 2.5d 3d"},
    // How the lines of a text lie one under another, ThorVG's own: 0 at the
    // left, 0.5 about the
    // middle, 1 at the right.
    {"align", "text", 0, 1, false, nullptr},
    // ThorVG's own scene effects on a layer it draws: a blur, and a shadow with
    // a color, how far it
    // falls, which way, how soft and how much of it. Lengths are in points of
    // the image at size 1.
    {"blur", "video image text shape", 0, 1000, true, nullptr},
    {"blur_direction", "video image text shape", 0, 0, false,
     "both horizontal vertical"},
    {"shadow", "image text shape", 0, 0, false, ""},
    {"shadow_distance", "image text shape", 0, 1000, true, nullptr},
    {"shadow_angle", "image text shape", -1e6, 1e6, true, nullptr},
    {"shadow_blur", "image text shape", 0, 1000, true, nullptr},
    {"shadow_opacity", "image text shape", 0, 1, true, nullptr},
    {"glow", "image text shape", 0, 0, false, ""},
    {"glow_blur", "image text shape", 0, 1000, true, nullptr},
    {"glow_opacity", "image text shape", 0, 1, true, nullptr},
    // trim: how much of its path is cut off the end, like After Effects' Trim
    // Paths and ThorVG's
    // trimpath.
    {"trim", "shape", 0, 1, true, nullptr},
    // trim_begin cuts the same off the beginning. trim_offset slides the part
    // that is left along
    // the path, in turns.
    {"trim_begin", "shape", 0, 1, true, nullptr},
    {"trim_offset", "shape", -1e3, 1e3, true, nullptr},
    // The path bent, like After Effects' path operators and ThorVG's own. bloat
    // is pucker and
    // bloat: -1 in, 1 out. zigzag is its height as a share of the layer's
    // height, zigzag_ridges the
    // number of ridges a side, and zigzag_smooth chooses smooth or sharp.
    // offset offsets the path,
    // out or in, as a share of its height.
    {"bloat", "shape", -1, 1, true, nullptr},
    {"zigzag", "shape", -10, 10, true, nullptr},
    {"zigzag_ridges", "shape", 0, 100, true, nullptr},
    {"zigzag_smooth", "shape", 0, 1, true, nullptr},
    {"offset", "shape", -10, 10, true, nullptr},
    // The path warped as it is drawn, on the GPU, like After Effects' wave
    // warp. warp is the height
    // of the wave and warp_width its length, both as shares of the layer's
    // height. warp_angle is
    // the angle it runs at, in degrees. warp_speed is the number of waves per
    // second along it.
    {"warp", "shape", -10, 10, true, nullptr},
    {"warp_width", "shape", 0.001, 100, true, nullptr},
    {"warp_angle", "shape", -1e6, 1e6, true, nullptr},
    {"warp_speed", "shape", -1e3, 1e3, true, nullptr},
    // Points moved as the layer is drawn, on the GPU, for a shape of one color
    // only (flat_mesh).
    // bend is Cavalry's bend, in degrees round, across it or up it. twist is
    // After Effects' twist,
    // in degrees, most at the middle. pinch is Cavalry's pinch, in, or out when
    // less than 0. skew
    // is in degrees, along an axis turned by skew_axis. squash is squash and
    // stretch: taller and as
    // much narrower, keeping its area. wiggle is After Effects' wiggle paths:
    // how far as a share of
    // its height, wiggle_detail how fine, and wiggle_speed how fast.
    {"bend", "shape", -1e4, 1e4, true, nullptr},
    {"bend_direction", "shape", 0, 0, false, "horizontal vertical"},
    {"twist", "shape", -1e5, 1e5, true, nullptr},
    {"pinch", "shape", -1, 1, true, nullptr},
    {"skew", "shape", -89, 89, true, nullptr},
    {"skew_axis", "shape", -1e4, 1e4, true, nullptr},
    {"squash", "shape", -0.95, 10, true, nullptr},
    {"wiggle", "shape", -10, 10, true, nullptr},
    {"wiggle_detail", "shape", 0, 1000, true, nullptr},
    {"wiggle_speed", "shape", -1e3, 1e3, true, nullptr},
    // Cavalry's motion stretch: longer in the direction the layer moves, and
    // narrower, by this much
    // for each unit per second it goes.
    {"stretch", "shape", -10, 10, true, nullptr},
    // After Effects' corner pin: how far each corner is moved, as shares of the
    // layer's height, up
    // and right. Everything between follows.
    {"pin_tl_x", "shape", -10, 10, true, nullptr},
    {"pin_tl_y", "shape", -10, 10, true, nullptr},
    {"pin_tr_x", "shape", -10, 10, true, nullptr},
    {"pin_tr_y", "shape", -10, 10, true, nullptr},
    {"pin_bl_x", "shape", -10, 10, true, nullptr},
    {"pin_bl_y", "shape", -10, 10, true, nullptr},
    {"pin_br_x", "shape", -10, 10, true, nullptr},
    {"pin_br_y", "shape", -10, 10, true, nullptr},
    // copies: how many copies there are. Each copy is the one before moved,
    // turned about its anchor
    // and scaled by the same amount, like After Effects' Repeater. Where each
    // lies is up to its
    // script: shelves/create/repeats/repeater.js lays them in rows, turns,
    // scales and scatters
    // them.
    {"copies", "image text shape solid", 1, 1000, false, nullptr},
    // How much later the last copy moves than the first, in seconds. Each is as
    // late as its order
    // says.
    {"stagger", "image text shape solid", 0, 1e3, false, nullptr},
    // Which copy moves first: the first, the middle one, the last, or the outer
    // ones.
    {"stagger_from", "image text shape solid", 0, 0, false,
     "start centre end edges"},
    // Its copies colored from the first color to the last, in their order, as
    // six hex digits each.
    // One color colors all of them. none means the copies are not colored
    // individually.
    {"copy_fill", "image text shape", 0, 0, false, ""},
    // ramp goes from the first color to the last across all the copies. cycle
    // gives each copy one
    // color in turn, round and round.
    {"copy_fill_way", "image text shape", 0, 0, false, "ramp cycle"},
    // How many times as tall as it is, its anchor staying where it is: a bar
    // growing up from its
    // foot.
    {"tall", "image text shape", 0, 1e3, true, nullptr},
    // Its copies each so many times as tall again, in their order, going round:
    // numbers, such as
    // the data of a bar chart. none means all copies are equally tall.
    {"copy_tall", "image text shape solid", 0, 0, false, ""},
    // Where along copy_fill each copy's color is, given by a behavior
    // (copy_fill_at_by): 0 is the
    // first color, 1 the last. If not given, the copies' order decides.
    {"copy_fill_at", "image text shape", 0, 1, true, nullptr},
    // The last copy is as transparent as this and the first as the layer
    // itself. After Effects'
    // Repeater, End Opacity.
    {"copy_opacity_end", "image text shape", 0, 1, true, nullptr},
    // Its copies laid on another shape's outline, each turned the way the
    // outline goes, like
    // Cavalry's Duplicator on a shape. copy_on_offset slides them along it, as
    // a share of its
    // length.
    {"copy_on", "image text shape solid", 0, 1e9, false, nullptr},
    {"copy_on_offset", "image text shape solid", -1e4, 1e4, true, nullptr},
    // The layer whose copies its own copies join, one each from one to another:
    // lines between dots.
    // 0 means none.
    {"connect", "shape", 0, 1e9, false, nullptr},
    // Another layer: the nth copy of the first layer is joined to the nth copy
    // of this one, like
    // rungs between two strands. 0 means within the first layer.
    {"connect_to", "shape", 0, 1e9, false, nullptr},
    // Only copies nearer than this, in units of the stage, are joined: a
    // plexus. 0 joins each to
    // the next in their order.
    {"connect_reach", "shape", 0, 1e4, true, nullptr},
    // Put together with another shape, like Cavalry's Boolean: subtract is its
    // own less that one,
    // intersect is where both are, union is either, and exclude is either but
    // not both.
    {"boolean", "shape", 0, 0, false, "union subtract intersect exclude"},
    // The other shape, seen where it lies. 0 means none.
    {"boolean_with", "shape", 0, 1e9, false, nullptr},
    // Walks the outline again at this many points per outline, straight between
    // them, like
    // Cavalry's Resample Path: a circle becomes a polygon. 0 leaves it as made.
    {"resample", "shape", 0, 2048, true, nullptr},
    // Made of squares this large, as a share of its height, like Cavalry's
    // Voxelize. 0 leaves it as
    // it is.
    {"voxel", "shape", 0, 1, true, nullptr},
    // Roughened like Illustrator's Roughen. rough is how far points go out, as
    // a share of the
    // layer's height. rough_detail is how often a point is placed, in the same
    // units.
    {"rough", "shape", 0, 0.5, true, nullptr},
    {"rough_detail", "shape", 0.005, 1, true, nullptr},
    // How outlines that lie over each other are filled: filled, or a hole every
    // other time, as
    // SVG's and Cavalry's fill rule.
    {"fill_rule", "shape", 0, 0, false, "nonzero evenodd"},
    // A behavior, like Cavalry's: it gives each copy of what it is connected to
    // (`<name>_by` set to
    // it) a value, by the copy's number and the time. stagger gives values from
    // minimum to maximum
    // in the copies' order. oscillator waves, with frequency as times per
    // second, offset as a share
    // of a wave, and stagger as degrees of a wave between copies. noise is a
    // smooth noise. random
    // gives values at random by its seed.
    {"minimum", "behaviour", -1e6, 1e6, true, nullptr},
    {"maximum", "behaviour", -1e6, 1e6, true, nullptr},
    {"frequency", "behaviour", 0, 1000, true, nullptr},
    {"offset", "behaviour", -1e6, 1e6, true, nullptr},
    {"tilt", "behaviour", -1e6, 1e6, true, nullptr},
    {"stagger", "behaviour", -1e6, 1e6, true, nullptr},
    {"seed", "behaviour", 0, 1e9, false, nullptr},
    // What it gives is rounded to this many: 90 turns a quarter at a time. 0
    // means no rounding.
    {"step", "behaviour", 0, 1e6, true, nullptr},
    // Falloff, like Cavalry's: where the behavior works. Inside the shape named
    // by region, which
    // can be any shape, seen or not, moving or not, it works fully, and outside
    // it not at all.
    // Between the two it fades over falloff_soft units of the stage. With
    // falloff_invert it is the
    // other way round. Elsewhere the value is the layer's own.
    {"region", "behaviour", 0, 1e9, false, nullptr},
    {"falloff_soft", "behaviour", 0, 1e4, true, nullptr},
    {"falloff_invert", "behaviour", 0, 1, false, nullptr},
    // A relation is a behavior that sets its layers in relation to each other
    // or to one of them:
    // around a middle, in a row, following a leader, or pushed away by a leader
    // within radius. A
    // follower is so many seconds later each, with its own value as a step from
    // the leader's, and
    // is handed over to leader_b as hand goes from 0 to 1. strength is how much
    // of the relation
    // works: 0 is as if it were not there, so a relation can be put on and
    // taken off over time
    // without a jump.
    {"strength", "behaviour", 0, 1, true, nullptr},
    {"radius", "behaviour", 0, 1e4, true, nullptr},
    {"gap", "behaviour", -1e4, 1e4, true, nullptr},
    {"centre_x", "behaviour", -1e6, 1e6, true, nullptr},
    {"centre_y", "behaviour", -1e6, 1e6, true, nullptr},
    {"leader", "behaviour", 0, 1e9, false, nullptr},
    {"leader_b", "behaviour", 0, 1e9, false, nullptr},
    {"hand", "behaviour", 0, 1, true, nullptr},
    {"lag", "behaviour", 0, 60, true, nullptr},
    // A group's: its layers sit this many times as far from their middle as
    // they were put. 0 puts
    // all at the middle, 2 twice as far out.
    {"spread", "behaviour", -10, 10, true, nullptr},
    // A group's: each layer is moved this far away in its own fixed way, as a
    // seed scatters.
    {"scatter", "behaviour", -10, 10, true, nullptr},
    // A relation's layers in their order, by number, with "_" where one was
    // removed. Its place is
    // kept so that no other layer moves.
    {"members", "behaviour", 0, 0, false, ""},
    // For each member, the relation it was in before, 0 meaning none. This
    // relation starts from
    // what that one gives.
    {"under", "behaviour", 0, 0, false, ""},
    // For each member, x and y where it showed when it joined. An around or a
    // row adds only the
    // step from there to its place. A follow adds only how far its leader has
    // gone since.
    {"from", "behaviour", 0, 0, false, ""},
    // Turned into another shape by this much, like Cavalry's Morph: 0 is
    // itself, 1 is the other
    // shape where it lies.
    {"morph", "shape", 0, 1, true, nullptr},
    // The path follows another layer's track, like Cavalry's Trails: trail
    // names whose, and
    // trail_length over how many seconds back.
    {"trail", "shape", 0, 1e9, false, nullptr},
    {"trail_length", "shape", 0.001, 60, true, nullptr},
    {"morph_to", "shape", 0, 1e9, false, nullptr},
    // So many steps from the layer to its target, shown all at once as a blend.
    // 0 or 1 means none.
    {"morph_steps", "shape", 0, 64, false, nullptr},
    // Freehand strokes as they were drawn, separated by ";". Each has its tool
    // (0 pen, 1 brush, 2
    // fill, 3 eraser), its width, and then each point as x, y and pressure, in
    // the path's own
    // units. Made by AbsentMotion, see doc_brush.
    {"drawing", "shape", 0, 0, false, ""},
    // A path shape's own path, drawn with a pen: SVG path data, in units of its
    // height from its
    // middle, with y pointing down as in SVG.
    {"path", "shape", 0, 0, false, ""},
    // A field over the copies, like Cavalry's falloff: a round place on the
    // stage given by its
    // middle (field_x and field_y, in units of the stage) and how far it
    // reaches (field_radius). A
    // copy within it is made larger by field_size and turned by field_rotate,
    // most at its middle
    // and not at all at its edge.
    {"field_x", "image text shape", -1e4, 1e4, true, nullptr},
    {"field_y", "image text shape", -1e4, 1e4, true, nullptr},
    {"field_radius", "image text shape", 0, 1e4, true, nullptr},
    {"field_size", "image text shape", -1, 20, true, nullptr},
    {"field_rotate", "image text shape", -1e4, 1e4, true, nullptr},
    // The copy is also pushed this far away from the field's middle, in units
    // of the stage. Below 0
    // draws it in.
    {"field_push", "image text shape", -1e3, 1e3, true, nullptr},
    // A ring this wide, strongest at the radius from the middle and nothing
    // this far on either
    // side: a band of large dots going out. 0 gives a round place, strongest in
    // its middle.
    {"field_band", "image text shape", 0, 1e4, true, nullptr},
    // Where the field's middle is toward the viewer. The field is a ball, so
    // near and far are
    // measured too.
    {"field_z", "image text shape", -1e4, 1e4, true, nullptr},
    // Another seed gives another wiggle of the path (evaluate.h).
    {"seed", "shape", 0, 1e6, false, nullptr},
    // tint maps a layer's darks and lights to two colors by this much, like
    // ThorVG's tint. tritone
    // maps its darks, middle tones and lights to three colors, like ThorVG's
    // tritone.
    {"tint", "video image text shape", 0, 1, true, nullptr},
    {"tint_black", "video image text shape", 0, 0, false, ""},
    {"tint_white", "video image text shape", 0, 0, false, ""},
    {"tritone", "video image text shape", 0, 1, true, nullptr},
    {"tritone_shadow", "video image text shape", 0, 0, false, ""},
    {"tritone_midtone", "video image text shape", 0, 0, false, ""},
    {"tritone_highlight", "video image text shape", 0, 0, false, ""},
    // More edges, each outside the last: Alight Motion's Add Border,
    // Illustrator's Appearance.
    {"stroke_2", "text", 0, 0, false, ""},
    {"stroke_2_width", "text", 0, 1000, false, nullptr},
    {"stroke_3", "text", 0, 0, false, ""},
    {"stroke_3_width", "text", 0, 1000, false, nullptr},
    // Its edge: a color, and how wide it is in points of the image at size 1.
    {"stroke", "text shape image", 0, 0, false, ""},
    {"stroke_width", "text shape image", 0, 1000, false, nullptr},
    // ThorVG's own: a text's letters and lines spaced so many times as far
    // apart as the font sets
    // them, and its slant. Also an edge's ends and corners, and dashes along it
    // that long, with
    // gaps as long, begun so far along.
    // Its lines broken in a box that many times as wide as its letters are
    // high, using ThorVG's
    // layout and wrap. A text's size is the height of all its lines, so this
    // goes with the letters,
    // not the image.
    {"wrap", "text", 0, 0, false,
     "none character word smart ellipsis vertical"},
    {"wrap_at", "text", 0, 1000, false, nullptr},
    // One line split into its letters or its words, each a copy of its own.
    // They lie where they
    // are, and move, wave and are colored each in their order.
    {"split", "text", 0, 0, false, "none letters words"},
    {"letter_spacing", "text", 0, 10, false, nullptr},
    {"line_spacing", "text", 0, 10, false, nullptr},
    {"italic", "text", 0, 0.5, false, nullptr},
    // A fill of two colors or more: across (linear, ThorVG's linear gradient)
    // or from the middle
    // out (radial, ThorVG's radial gradient). gradient_angle turns it, in
    // degrees clockwise, 0
    // being from top to bottom. gradient_scale is its length as a share of how
    // far it reaches.
    // gradient_spread chooses what happens past its ends: padded, reflected or
    // repeated.
    {"gradient", "text shape", 0, 0, false, "linear radial"},
    {"gradient_angle", "text shape", -1e6, 1e6, false, nullptr},
    {"gradient_scale", "text shape", 0.01, 100, false, nullptr},
    {"gradient_spread", "text shape", 0, 0, false, "pad reflect repeat"},
    // How the colors between its stops are mixed: CSS Color 4's
    // color-interpolation-method
    // (canvas_renderables.h, ramp_of).
    {"gradient_blend", "text shape", 0, 0, false, "rgb oklab hue steps"},
    {"cap", "shape", 0, 0, false, "butt round square"},
    {"join", "shape", 0, 0, false, "miter round bevel"},
    // After Effects' Bevel Style and Depth. Ogee and Step are Easy
    // Typography's.
    {"bevel", "text shape image", 0, 0, false,
     "none angular convex concave ogee step"},
    {"bevel_depth", "text shape image", 0, 4096, true, nullptr},
    // A thick layer's other faces, like After Effects' Bevel, Side and Back
    // Color, each with its
    // own metallic and roughness. If not set, they are as its front.
    {"bevel_color", "text shape image", 0, 0, false, ""},
    {"bevel_metallic", "text shape image", 0, 1, false, nullptr},
    {"bevel_roughness", "text shape image", 0, 1, false, nullptr},
    {"side_color", "text shape image", 0, 0, false, ""},
    {"side_metallic", "text shape image", 0, 1, false, nullptr},
    {"side_roughness", "text shape image", 0, 1, false, nullptr},
    {"back_color", "text shape image", 0, 0, false, ""},
    {"back_metallic", "text shape image", 0, 1, false, nullptr},
    {"back_roughness", "text shape image", 0, 1, false, nullptr},
    // Arrow heads on the open ends of its edge, like Cavalry's basicArrowHead:
    // which ends, and the
    // head's size as a multiple of the edge's length.
    {"heads", "shape", 0, 0, false, "none end start both"},
    {"head_size", "shape", 0.5, 40, false, nullptr},
    {"head_shape", "shape", 0, 0, false,
     "arrow circle box chevron bar t_line square square_filled diamond "
     "diamond_filled arrow_hollow arrow_filled circle_hollow circle_filled "
     "teardrop_hollow teardrop_filled"},
    {"head_start", "shape", 0, 0, false,
     "arrow circle box chevron bar t_line square square_filled diamond "
     "diamond_filled arrow_hollow arrow_filled circle_hollow circle_filled "
     "teardrop_hollow teardrop_filled"},
    {"dash", "shape", 0, 1000, false, nullptr},
    {"dash_offset", "shape", -1e4, 1e4, false, nullptr},
    // Filament's own surface of a solid in a color: how metallic, how rough,
    // how much it reflects,
    // a clear coat over it and how rough that is, and how much it lights
    // itself. For emissive, 1 is
    // its color itself on the image and more is brighter still.
    {"metallic", "solid text shape image video", 0, 1, false, nullptr},
    {"roughness", "solid text shape image video", 0, 1, false, nullptr},
    {"reflectance", "solid text shape image video", 0, 1, false, nullptr},
    // A solid filled with glass, the render code's own: ior is how much it
    // bends light (index of
    // refraction), dispersion how far its colors part, swim how much what is
    // behind it swims, dark
    // how fast a long way through it goes dark, and vivid how vivid what is
    // seen through it is.
    {"ior", "video image text shape solid", 1, 3, false, nullptr},
    {"dispersion", "video image text shape solid", 0, 0.5, false, nullptr},
    {"swim", "video image text shape solid", 0, 1, false, nullptr},
    {"dark", "video image text shape solid", 0, 20, false, nullptr},
    {"vivid", "video image text shape solid", 0, 3, false, nullptr},
    {"clear_coat", "video image text shape solid", 0, 1, false, nullptr},
    {"clear_coat_roughness", "video image text shape solid", 0, 1, false,
     nullptr},
    {"emissive", "video image text shape solid", 0, 20, true, nullptr},
    // Filament's velvet sheen at its rim, in its own color.
    {"sheen", "video image text shape solid", 0, 1, false, nullptr},
    // The material the layer wears, for any layer that is seen (Create's
    // Material group,
    // doc_material). shading chooses among Filament's shading models: lit,
    // cloth (soft, no sharp
    // highlight) and subsurface (light goes in, as in skin or wax); the render
    // code's thick glass
    // (thick_glass.mat); Filament's own glass (own_glass.mat); lacquer
    // (blade.mat); and a bubble
    // (bubble.mat). thickness is how thick it is to the light going through.
    {"shading", "video image text shape solid", 0, 0, false,
     "lit cloth subsurface glass filament_glass lacquer bubble"},
    {"thickness", "video image text shape solid", 0, 1, false, nullptr},
    // Highlights drawn out as on brushed metal. A negative value draws them out
    // the other way.
    {"anisotropy", "video image text shape solid", -1, 1, false, nullptr},
    // A camera's lens, Filament's own: projection can be orthographic, drawn
    // without depth so that
    // far is as large as near, as in an axonometric drawing. shift_x and
    // shift_y shift the lens
    // across and up, in shares of the image. A shift lens keeps uprights
    // upright.
    {"projection", "camera", 0, 0, false, "perspective orthographic"},
    {"shift_x", "camera", -2, 2, true, nullptr},
    {"shift_y", "camera", -2, 2, true, nullptr},
    // The stage's own values, on layer 0: the whole image, Filament's own. The
    // grade applies to
    // every image laid: a tone mapper, an exposure in stops, contrast,
    // saturation, vibrance and
    // warmth. Also a glow round bright parts, a lens flare, a darkening at the
    // corners and a fog in
    // a color, on the stage's own view, the room's light (how bright and how
    // far turned), and the
    // color behind everything.
    {"tone_mapper", "stage", 0, 0, false, "linear aces filmic agx pbr_neutral"},
    {"exposure", "stage", -10, 10, false, nullptr},
    {"contrast", "stage", 0, 2, false, nullptr},
    {"saturation", "stage", 0, 2, false, nullptr},
    {"vibrance", "stage", 0, 2, false, nullptr},
    {"temperature", "stage", -1, 1, false, nullptr},
    {"bloom", "stage", 0, 1, false, nullptr},
    {"lens_flare", "stage", 0, 1, false, nullptr},
    {"vignette", "stage", 0, 1, false, nullptr},
    {"vignette_color", "stage", 0, 0, false, ""},
    // fog: the stage's, or that of the camera it is seen through, like Alight
    // Motion's camera has
    // its Fog. fog_near is how far from the camera the fog begins, in units of
    // the world, like
    // Filament's FogOptions distance. render_height, render_rate, render_mbps
    // and render_blur
    // describe how a video is exported: its height, frames per second, megabits
    // per second, and how
    // many times samples are laid on one another for motion blur. 0 means as it
    // was.
    {"fog", "stage camera", 0, 1, false, nullptr},
    {"fog_color", "stage camera", 0, 0, false, ""},
    {"fog_near", "stage camera", 0, 1e4, false, nullptr},
    {"fog_far", "stage camera", 0, 1e4, false, nullptr},
    {"render_height", "stage", 0, 8640, false, nullptr},
    {"render_rate", "stage", 0, 60, false, nullptr},
    {"render_mbps", "stage", 0, 500, false, nullptr},
    {"render_blur", "stage", 0, 64, false, nullptr},
    {"render_alpha", "stage", 0, 1, false, nullptr},
    // Filament's screen effects on solid layers: ambient_occlusion shades where
    // they meet and in
    // their folds (SSAO), and reflections mirrors what is near in them (SSR).
    {"ambient_occlusion", "stage", 0, 1, false, nullptr},
    {"reflections", "stage", 0, 1, false, nullptr},
    // Filament's ASC CDL grade, the same on red, green and blue: each color
    // times slope, plus
    // offset, to the power.
    {"slope", "stage", 0, 4, false, nullptr},
    {"offset", "stage", -1, 1, false, nullptr},
    {"power", "stage", 0.1, 4, false, nullptr},
    // Filament's shadows, midtones and highlights, each tinted with a color of
    // six hex digits. If
    // not set, white, which leaves them as they are.
    {"shadows_color", "stage", 0, 0, false, ""},
    {"midtones_color", "stage", 0, 0, false, ""},
    {"highlights_color", "stage", 0, 0, false, ""},
    // How its edges are smoothed: Filament's FXAA as it came, its temporal one,
    // which is steadier
    // on fine edges in motion, or none.
    {"anti_aliasing", "stage", 0, 0, false, "fxaa taa msaa none"},
    // Which room lights the stage: the rooms made ready in out/.
    {"room", "stage", 0, 0, false,
     "small_studio studio_small_02_2k lightroom venetian_crossroads_2k "
     "graffiti_shelter_2k parking_garage_2k pillars_2k"},
    {"environment", "stage", 0, 10, false, nullptr},
    {"environment_rotate", "stage", -1e6, 1e6, false, nullptr},
    {"background", "stage", 0, 0, false, ""},
    // What is behind everything: the background's color, or the room itself.
    {"behind", "stage", 0, 0, false, "colour room"}};
// The cards a user sees a layer's values on, besides where the layer is and its
// fill: a title and the values on it, in the order shown. A layer is shown
// those of them its kind has. A value that the window has no other place for
// goes here. The card is shown only while the value named by `when` is `is`. A
// leading "!" means is not, and a leading "~" means has it in it. added: the
// card is shown only once one of its values is set or keyed, or the user asked
// for it with More. It is not one of the tiles Alight Motion shows for the kind
// (doc_cards_of).
struct DocCard {
  const char* title;
  const char* names;
  const char* when = nullptr;
  const char* is = nullptr;
  bool added = false;
};
// How a value is shown to the user. The app draws its control from this and has
// nothing of its own. look is one of: count (a whole number), onoff, angle,
// stage (a length of the stage, shown in points of the image), down (a length
// up the stage, shown downward as the image counts), share (0 to 1, shown in
// hundredths), colour, colours and numbers (words of those), words (any text,
// typed), file (a file, given from a shelf), layer (another layer), seed, or
// none (as its range specifies). unit is the unit the value is read in. label
// is a name in plain words. low and high are the span the control covers; the
// value itself may go further, as its range specifies. fold is the name of the
// fold it lies in on its card if it is folded away, named by what the fold
// holds. A card's first row holds at most eight, as on Ableton's Push.
struct DocShown {
  const char* name;
  const char* look;
  const char* unit;
  const char* label;
  double low, high;
  const char* fold;
  bool open = false;
};

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_KINDS_H_
