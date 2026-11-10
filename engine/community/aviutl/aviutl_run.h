#ifndef MOTOLII_COMMUNITY_AVIUTL_AVIUTL_RUN_H_
#define MOTOLII_COMMUNITY_AVIUTL_AVIUTL_RUN_H_
// Runs an AviUtl2 script on a layer: creates the Lua state once per script file
// and executes one frame of the script on the layer's image.
#include <filament/RenderTarget.h>
#include <filament/Texture.h>

#include <cstdint>
#include <lua.hpp>
#include <memory>
#include <string>

#include "community/aviutl/aviutl_fx.h"
#include "stage/effects/screen_fx.h"
#include "stage/render/render_stage.h"

namespace motolii {

// Opens a script file once: creates its Lua state, the obj table, the first
// values of its parameters, and builds each of its pixel shaders. The Lua state
// keeps the libraries that AviUtl2's lua.txt allows, and require searches the
// script's own folder first. If `with` is not null, that Lua state is reused
// instead of creating a new one; this is used for the layers after the first on
// the same layer stack. Failures are printed to stderr and stored in
// AviutlRun::trouble. A shader that cannot be built is reported as "not yet"
// when the script uses it.
std::shared_ptr<AviutlRun> aviutl_open(Stage& s, const std::string& file,
                                       lua_State* with = nullptr);

// Runs one frame of the script. `from` (w x h) becomes the script's object, the
// parameter values and the obj fields are set, and the script is executed. The
// result is drawn into `to`. The result is the frame buffer if the script drew
// into it, otherwise the object placed according to the final obj fields. If
// the script fails, `from` is copied to `to` unchanged and the reason is
// printed to stderr once.
void aviutl_draw_step(Stage& s, AviutlRun& r, filament::Texture* from,
                      filament::RenderTarget* to, const ScreenNumbers& numbers,
                      uint32_t w, uint32_t h);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_AVIUTL_AVIUTL_RUN_H_
