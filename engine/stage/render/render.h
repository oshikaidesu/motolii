// render.h: the stage (Filament's engine, one view, a headless screen), a way to put a mesh on it, the round-edged block,
// and the picture of what is behind the glass. Everything that draws is Filament as it is.
// In parts, read in this order (each a piece of the one before it, none alone):
#include "stage/render/render_stage.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_draw.h"
