#include "document/evaluate/evaluate_lights.h"

#include <filament/Engine.h>
#include <filament/LightManager.h>
#include <filament/Scene.h>
#include <filament/View.h>
#include <math/mat4.h>
#include <math/vec3.h>
#include <math/vec4.h>
#include <utils/Entity.h>

#include <vector>

#include "document/document.h"
#include "document/evaluate/evaluate.h"
#include "document/evaluate/evaluation.h"
#include "document/evaluate/moment_fx.h"
#include "document/evaluate/place.h"
#include "document/evaluate/value_at.h"
#include "stage/layer_effects/layer_fx.h"
#include "stage/render/render_stage.h"

using namespace filament;

namespace motolii {

// Soft shadows, Filament's PCSS, are used on the stage's own view while any
// light that is on asks for them. Otherwise crisp shadows are used.
void evaluate_shadow_type(const Evaluation& evaluation) {
  Doc& d = evaluation.d;
  Stage& s = evaluation.s;
  const std::vector<EvaluatedLayer>& lies = evaluation.lies;
  bool soft = false;
  for (const EvaluatedLayer& one : lies)
    soft = soft || (one.on && !one.shown->light.isNull() &&
                    doc_number(d, one.layer, "shadow_softness", 0, 0) > 0.0);
  s.view->setShadowType(soft ? View::ShadowType::PCSS : View::ShadowType::PCF);
}

// The lights. Each is in every scene of the stage while it is on, where it
// is, shining in the direction it is turned, as strong as it is now. An
// intensity of 1 is as bright as the stage's own light.
void evaluate_lights(const Evaluation& evaluation) {
  Doc& d = evaluation.d;
  Stage& s = evaluation.s;
  const double now = evaluation.now;
  const std::vector<EvaluatedLayer>& lies = evaluation.lies;
  for (const EvaluatedLayer& one : lies) {
    const utils::Entity e = one.shown->light;
    if (e.isNull()) continue;
    std::vector<Scene*> all{s.scene};
    // Also the effects scenes of groups with effects of their own, so their
    // layers are lit as on the stage.
    for (const auto& [layer, e] : d.effects.layerFx)
      if (e.view && doc_holds_fx(d, layer)) all.push_back(e.view->getScene());
    for (Scene* sc : all)
      one.on ? (sc->hasEntity(e) ? void() : sc->addEntity(e)) : sc->remove(e);
    if (!one.on) continue;
    auto& lights = s.engine->getLightManager();
    const auto it = lights.getInstance(e);
    const math::mat4 place = doc_place(d, one.layer, now);
    lights.setPosition(it,
                       math::float3((place * math::double4{0, 0, 0, 1}).xyz));
    lights.setDirection(
        it, normalize(math::float3((place * math::double4{0, 0, -1, 0}).xyz)));
    const float strong = (float)doc_number(d, one.layer, "intensity", now, 1);
    // A sun light is in lux, like the stage's own light. Other lights are in
    // candela, chosen so that at six units, where the stage's own camera
    // stands, they are as bright as that light.
    if (lights.getType(it) == LightManager::Type::SUN)
      lights.setIntensity(it, 60000.f * strong);
    else
      lights.setIntensityCandela(it, 60000.f * 36.f * strong);
    if (lights.getType(it) == LightManager::Type::SUN)
      lights.setSunAngularRadius(
          it, (float)doc_number(d, one.layer, "sun_size", now, 1.09) / 2.f),
          lights.setSunHaloSize(
              it, (float)doc_number(d, one.layer, "sun_halo", now, 10));
    if (lights.getType(it) == LightManager::Type::FOCUSED_SPOT) {
      const float cone = (float)(doc_number(d, one.layer, "cone", now, 30) *
                                 (double)TAU / 360.0);
      lights.setSpotLightCone(it, 0.8f * cone, cone);
    }
  }
}

}  // namespace motolii
