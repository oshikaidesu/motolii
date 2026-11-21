#ifndef MOTOLII_COMMUNITY_AFTER_EFFECTS_PLUGIN_AE_PLUGIN_H_
#define MOTOLII_COMMUNITY_AFTER_EFFECTS_PLUGIN_AE_PLUGIN_H_
// Discovers and probes native After Effects plugins (.plugin on macOS, .aex on
// Windows) via the isolated motolii_ae_worker process (potistudio/aexlo, MIT).

#include <cstdint>
#include <string>
#include <vector>

#include "community/quickjs/script.h"

namespace motolii {

struct AePluginParam {
  uint32_t index = 0;
  // One of: float, fixed, slider, angle, check, popup, point, point3d, color,
  // layer.
  std::string kind;
  std::string name;   // sanitized parameter stem for Motolii keys
  std::string label;  // display label from the plugin
  std::string group;
  double low = 0, high = 1, usual = 0;
  double x = 0, y = 0, z = 0;
  uint8_t rgba[4] = {255, 255, 255, 255};
  std::vector<std::string> choices;
};

struct AePluginInfo {
  bool ok = false;
  std::string about;
  bool gpu = false, smart = false, d8 = false, d16 = false, d32 = false;
  bool has_layer = false;
  std::string tags;
  std::vector<AePluginParam> params;
  std::vector<ScriptParameter> script_params;
};

// Returns true if `path` (with or without an instance-ID prefix) names an
// After Effects plugin bundle (.plugin) or binary (.aex).
bool ae_plugin_is(const std::string& path);

// Returns the path to the isolated worker binary beside libmotolii.
std::string ae_plugin_worker();

// Returns a clean display title derived from the plugin's file name.
std::string ae_plugin_title(const std::string& path);

// Probes `path` via the worker (cached in memory and on disk by mtime).
// Returns ok=false on timeout, crash, or unsupported plugin without throwing.
AePluginInfo ae_plugin_probe(const std::string& path);

// Converts the plugin's declared parameters into Motolii's ScriptParameter list.
std::vector<ScriptParameter> ae_plugin_parameters(const std::string& path);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_AFTER_EFFECTS_PLUGIN_AE_PLUGIN_H_
