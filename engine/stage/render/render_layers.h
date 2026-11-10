#ifndef MOTOLII_STAGE_RENDER_RENDER_LAYERS_H_
#define MOTOLII_STAGE_RENDER_RENDER_LAYERS_H_
// Layer helpers for the stage: glass and other materials, mattes, drawing a frame, and removing
// meshes.
#include <cstdint>
#include <string>
#include <vector>

#include <filament/Camera.h>
#include <filament/MaterialInstance.h>
#include <filament/Texture.h>
#include <math/mat4.h>
#include <math/vec3.h>

#include "stage/render/render_stage.h"

// Adds a solid with one of the renderer's own materials, chosen by name in `wears`. See
// doc_material in doc.h for the Material group in the Create tab. Returns the material instance, or
// nullptr if the name is unknown or the build failed.
// "filament_glass": glass from own_glass above. ior is the refraction index, split how far the
// colours part, swim how far the faces lean, vivid the strength of the thin-film rainbow, and dark
// how deep the colour is.
// "lacquer": blade.mat, a hard clear coat over a colour that is dark at the root and as given at
// the tip. metal is 0 for lacquer and 1 for steel.
// "bubble": bubble.mat. vivid is the brightness of its rim.
// tone: the colour of the material.
filament::MaterialInstance* solid_wear(Stage& s, Mesh* m, std::vector<filament::math::mat4f> places, const std::string& wears, filament::math::float3 tone, float ior, float split, float swim, float dark, float vivid, float metal);

// Adds glass seen through both of its sides (thick_glass.mat): the mesh at each of its places,
// drawn three times.
// 1. The far faces are drawn into an image of their own with the direction they face and their
//    distance (far_side.mat). Nothing else is in that image.
// 2. The far faces are also drawn as seen from inside, over the image of the scene without the
//    glass (far_look.mat).
// 3. The near faces, drawn on the screen, bend the view ray in, look up the far face there, and
//    bend the ray out again to the scene.
// The first call creates the far-side image. The caller has nothing else to set up. Returns the
// material instance of the near faces, or nullptr on failure.
filament::MaterialInstance* thick_glass(Stage& s, Mesh* m, std::vector<filament::math::mat4f> places);

// Adds a matte as After Effects has them: a shape that is not itself visible and that cuts other
// layers. Any mesh can be one: a solid, or a sheet with an image on it from ThorVG. The sheet cuts
// by how opaque the image is, or by its brightness, like the After Effects luma matte. It is an
// entity like any other, so `move` moves it.
// on: where the matte is.
// nullptr: in the project camera's image, as a window on the screen. It cuts by where its shape is
//   seen from the project camera, whatever lies between, and stays in the image while layers move
//   behind it.
// A mesh on the stage: a sticker on that mesh. It rides on the mesh, using Filament's parent and
//   child transforms, and cuts by where its shape lies on the mesh, seen along the mesh's own z
//   axis.
// strength: the most it covers. 0.5 is a half-transparent matte.
// into: an existing matte that this shape joins. A negative value creates a new matte.
// Returns the index of the matte, or -1 on failure.
// Each matte is an image of its own, rendered before everything else (see `draw`) by its own
// camera. That is the project camera, or one riding on the mesh. Only the matte's shapes are in it.
// The layers it cuts look themselves up in it through that camera (matte.glsl), so they are cut the
// same whichever camera views the stage.
int matte(Stage& s, Mesh* m, std::vector<filament::math::mat4f> places, filament::Texture* frameTexture = nullptr, bool byLight = false, float strength = 1.f, int into = -1, const Mesh* on = nullptr);

// Cuts the layer with material instance `look` by matte number `matte`. The layer is visible only
// inside the matte, or only outside it when `inside` is false.
// soft: how far the edge is blurred, in screen pixels, or in pixels of the matte's own image if the
// matte is on a mesh. 0 is as sharp as the matte.
// Up to four mattes can cut one layer, by calling again. Only what all of them leave is visible.
// Returns false if the material cannot be cut because it does not read mattes (see matte.glsl), or
// if four mattes already cut it.
bool matted(Stage& s, filament::MaterialInstance* look, int matte, bool inside = true, float soft = 0.f);

// Switches the stage between the project camera and a second, free camera. When `on` is true the
// stage is viewed through the free camera (`camera`), like standing beside a set and watching. The
// project camera (`film`) keeps rendering the mattes that are in its image. When `on` is false the
// project camera is used again. Returns the camera now in use.
filament::Camera* god_view(Stage& s, bool on);

// Sets the stage's time to `seconds`. Everything that advances by itself is moved to that time for
// the next frame drawn.
void time_is(Stage& s, double seconds);

// Begins a frame (Filament's beginFrame). Returns false if this frame is to be skipped.
// Filament uploads material parameters when a frame begins, so the view-projection matrix of each
// matte's camera is set just before. Nothing else is passed.
bool begins(Stage& s);

// Renders all the images of one frame, the helper images first. This runs between Filament's
// beginFrame and endFrame. Every way of drawing the stage goes through here.
void textures_of(Stage& s);

// Draws one frame of the stage, the helper images first. If `pic` is given, the image is read back
// into it as RGBA bytes. If `wait` is true, returns only after the GPU has finished.
void draw(Stage& s, std::vector<uint8_t>* pic = nullptr, bool wait = true);

// Removes from the stage for good every entity made from mesh `m`.
void take_off(Stage& s, const Mesh* m);

#endif  // MOTOLII_STAGE_RENDER_RENDER_LAYERS_H_
