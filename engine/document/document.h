#ifndef MOTOLII_DOCUMENT_DOCUMENT_H_
#define MOTOLII_DOCUMENT_DOCUMENT_H_
// Defines Doc, an open project. Each part of its state is a struct of its own,
// defined in the header of the code that owns it.

#include <memory>
#include <mutex>
#include <string>

#include "document/edit/hold.h"
#include "document/edit/keys_put.h"
#include "document/evaluate/camera.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/moment_fx.h"
#include "document/evaluate/place.h"
#include "document/evaluate/relations.h"
#include "document/evaluate/value_at.h"
#include "document/evaluate/world.h"
#include "document/undo.h"

struct sqlite3;

namespace motolii {

struct DocScripts;
struct Stage;

// The export of the project as a video (entry/export.cpp).
struct DocExport {
  // True while the project is being exported as a video. It can be read but not
  // changed until the export is done.
  bool writing = false;
  // The time of the project at which the video being exported begins, which is
  // the start of its work area.
  double written_from = 0.0;
};

// Doc is an open project: the SQLite database, and the state built from it,
// one member for each part. Most of that state is caches that are cleared at
// every change to the project.
struct Doc {
  // Held by whoever reads or changes the project. It lets the app read the
  // project while a frame is being drawn (see motolii.mm).
  std::recursive_timed_mutex lock;
  // The project's file, an SQLite database.
  sqlite3* file = nullptr;
  // The stage the project is shown on.
  Stage* stage = nullptr;
  // Why the last call that did not succeed was refused.
  std::string error;

  // The parts, each defined in the header named beside it. Their order is the
  // order they are made in and, reversed, destroyed in.
  // The video being exported, while one is.
  DocExport video_export;
  // What was read from the keyframes (evaluate/value_at.h).
  DocValueCache value_cache;
  // The grade, the room and the backdrop of the stage (evaluate/camera.h).
  DocLook look;
  // What the undo steps changed (undo.h).
  DocChanges changes;
  // The relations worked out frame after frame (evaluate/world.h).
  DocSolver solver;
  // The materials of copies colored one by one (evaluate/evaluate.h).
  DocCopyMaterials copy_materials;
  // The behaviors and relations (evaluate/relations.h).
  DocRelations relations;
  // The copy being placed now (evaluate/place.h).
  DocCopyContext copy_context;
  // The animate-all mode (edit/keys_put.h).
  DocKeying keying;
  // The open undo step (undo.h).
  DocAct act;
  // The layers that fall and collide (evaluate/relations.h).
  DocPhysics physics;
  // What placing the layers has worked out (evaluate/place.h).
  DocPlaceCache place_cache;
  // The project's scripts, each run as its file specifies (scripts/scripts.h).
  std::shared_ptr<DocScripts> scripts;
  // The layers' effects and the whole-screen effects (evaluate/moment_fx.h).
  DocEffects effects;
  // The window's working camera (evaluate/camera.h).
  DocWorkingCamera working_camera;
  // The camera of the current time (evaluate/camera.h).
  DocCamera camera;
  // The layer being dragged (edit/hold.h).
  DocHeld held;
  // The layers as they are on the stage (evaluate/evaluate.h).
  DocOnStage on_stage;
};

}  // namespace motolii

#endif  // MOTOLII_DOCUMENT_DOCUMENT_H_
