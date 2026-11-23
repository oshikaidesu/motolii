// Thin Motolii adapter over MolecularMatters/psd_sdk: extracts PSD/PSB layers
// with UTF-8 names, exact canvas bounds, visibility, opacity, and RGBA PNGs.
#ifndef MOTOLII_COMMUNITY_PSD_PSD_LAYERS_H_
#define MOTOLII_COMMUNITY_PSD_PSD_LAYERS_H_

#include <string>
#include <vector>

namespace motolii {

struct PsdLayerOut {
  std::string name;
  std::string png_path;
  int left = 0, top = 0, width = 0, height = 0;
  double opacity = 1.0;
  bool visible = true;
  bool clipping = false;
};

struct PsdDocOut {
  int canvas_w = 0, canvas_h = 0;
  // Ordered bottom-to-top (Photoshop's native stack order).
  std::vector<PsdLayerOut> layers;
};

// Extracts every pixel layer in `psd_path` to cropped RGBA PNGs in `out_dir`.
// Returns false and fills `why` on failure.
bool psd_extract_layers(const std::string& psd_path, const std::string& out_dir,
                        PsdDocOut& out, std::string& why);

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_PSD_PSD_LAYERS_H_
