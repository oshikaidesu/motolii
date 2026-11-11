#include "document/match/match_light.h"

#include <filament/Color.h>
#include <filament/Engine.h>
#include <filament/LightManager.h>
#include <math/vec3.h>
#include <utils/Entity.h>
#include <utils/EntityManager.h>

#include <string>

#include "document/card_table.h"
#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/value_at.h"
#include "document/match/rebuild.h"
#include "stage/render/render_stage.h"

namespace motolii {

using filament::LightManager;
using filament::math::float3;

void match_light(LayerBuild& build) {
  Stage& s = build.s;
  DocShownLayer& made = build.made;
  const std::string &file = build.file, &fill = build.fill;
  const float3 colour = build.colour;
  std::string& why = build.why;
  const LightManager::Type type = file == "sun" ? LightManager::Type::SUN
                                  : file == "spot"
                                      ? LightManager::Type::FOCUSED_SPOT
                                      : LightManager::Type::POINT;
  if (!doc_among("sun point spot", file.c_str()))
    why = "a light is a sun, a point or a spot";
  else {
    made.light = utils::EntityManager::get().create();
    // Use a finer shadow map than the default so the edge is not stepped,
    // and a bulb as large as the softness says.
    LightManager::ShadowOptions shade;
    shade.mapSize = 2048;
    const float soft = (float)build.number("shadow_softness", 0);
    shade.screenSpaceContactShadows =
        build.number("contact_shadows", 0) > 0.5;
    if (soft > 0.f)
      shade.shadowBulbRadius =
          type == LightManager::Type::SUN ? 0.05f * soft : 0.5f * soft;
    LightManager::Builder(type)
        .color(filament::Color::toLinear<filament::ACCURATE>(
            filament::sRGBColor{fill.empty() ? float3{1.f} : colour}))
        .falloff((float)build.number("falloff", 10))
        .castShadows(build.number("shadows", 0) > 0.5)
        .shadowOptions(shade)
        .build(*s.engine, made.light);
    if (const int group = (int)build.number("light_group", 0);
        group > 0) {
      auto& lights = s.engine->getLightManager();
      lights.setLightChannel(lights.getInstance(made.light), 0, false),
          lights.setLightChannel(lights.getInstance(made.light),
                                 (unsigned)group, true);
    }
    // The light enters the scenes only when it is on.
    made.in = false;
  }
}

}  // namespace motolii
