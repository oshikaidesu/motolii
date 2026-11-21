#ifndef MOTOLII_COMMUNITY_AFTER_EFFECTS_PLUGIN_AE_PLUGIN_FX_H_
#define MOTOLII_COMMUNITY_AFTER_EFFECTS_PLUGIN_AE_PLUGIN_FX_H_
// Runs a native After Effects plugin as one step of a layer's or stage's effect
// stack through an isolated persistent motolii_ae_worker process.

#include <filament/RenderTarget.h>
#include <filament/Texture.h>

#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "community/after_effects_plugin/ae_plugin.h"
#include "community/after_effects_plugin/ae_worker_proc.h"
#include "stage/effects/screen_fx.h"
#include "stage/render/render_stage.h"

namespace motolii {

struct AePluginRun {
  std::string file, instance_id, trouble;
  AePluginInfo info;

  // Persistent isolated worker process (POSIX + Windows).
  AeWorkerProc proc;

  // Reusable staging buffers on the Filament side to avoid per-frame allocs.
  Stage* stage = nullptr;
  filament::Texture* read_tex = nullptr;
  filament::RenderTarget* read_rt = nullptr;
  uint32_t read_w = 0, read_h = 0;

  filament::Texture* out_tex = nullptr;
  uint32_t out_w = 0, out_h = 0;

  // Last parameter signature that timed out or crashed; skipped until changed.
  std::optional<std::string> stuck;
  bool reported = false;

  std::string numbers_key() const {
    return instance_id.empty() ? file : instance_id + ":" + file;
  }

  ~AePluginRun();
};

std::shared_ptr<AePluginRun> ae_plugin_open(Stage& s, const std::string& entry);

void ae_plugin_draw_step(Stage& s, AePluginRun& r, filament::Texture* from,
                         filament::RenderTarget* to,
                         const ScreenNumbers& numbers,
                         const ScreenTextures& textures, uint32_t w,
                         uint32_t h);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_AFTER_EFFECTS_PLUGIN_AE_PLUGIN_FX_H_
