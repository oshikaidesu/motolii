// Includes the parts of the renderer. Together they define the stage: Filament's engine, one
// view and a headless screen; a way to add a mesh to it; the round-edged block; and the image
// of what is behind the glass. All drawing is done by Filament as it is.
// Each part uses the ones before it and is not usable alone, so keep this order.
#include "stage/render/render_stage.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_draw.h"
