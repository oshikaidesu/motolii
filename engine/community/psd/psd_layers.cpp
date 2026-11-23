// Thin adapter over MolecularMatters/psd_sdk (BSD 2-Clause) + stb_image_write.
#include "community/psd/psd_layers.h"

#define STB_IMAGE_WRITE_STATIC
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <stb_image_write.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "Psd/Psd.h"
#include "Psd/PsdChannel.h"
#include "Psd/PsdChannelType.h"
#include "Psd/PsdColorMode.h"
#include "Psd/PsdDocument.h"
#include "Psd/PsdLayer.h"
#include "Psd/PsdLayerMask.h"
#include "Psd/PsdLayerMaskSection.h"
#include "Psd/PsdLayerType.h"
#include "Psd/PsdMallocAllocator.h"
#include "Psd/PsdMemoryFile.h"
#include "Psd/PsdParseDocument.h"
#include "Psd/PsdParseLayerMaskSection.h"

namespace motolii {

namespace {

std::string utf16_to_utf8(const uint16_t* s) {
  std::string out;
  if (!s) return out;
  for (size_t i = 0; s[i] != 0; ++i) {
    uint32_t cp = s[i];
    if (cp >= 0xD800 && cp <= 0xDBFF && s[i + 1] >= 0xDC00 &&
        s[i + 1] <= 0xDFFF) {
      cp = 0x10000 + (((cp - 0xD800) << 10) | (s[++i] - 0xDC00));
    }
    if (cp <= 0x7F) {
      out.push_back((char)cp);
    } else if (cp <= 0x7FF) {
      out.push_back((char)(0xC0 | (cp >> 6)));
      out.push_back((char)(0x80 | (cp & 0x3F)));
    } else if (cp <= 0xFFFF) {
      out.push_back((char)(0xE0 | (cp >> 12)));
      out.push_back((char)(0x80 | ((cp >> 6) & 0x3F)));
      out.push_back((char)(0x80 | (cp & 0x3F)));
    } else {
      out.push_back((char)(0xF0 | (cp >> 18)));
      out.push_back((char)(0x80 | ((cp >> 12) & 0x3F)));
      out.push_back((char)(0x80 | ((cp >> 6) & 0x3F)));
      out.push_back((char)(0x80 | (cp & 0x3F)));
    }
  }
  return out;
}

std::string layer_name_utf8(const psd::Layer* lay, size_t index) {
  if (lay->utf16Name && lay->utf16Name[0] != 0) {
    std::string u = utf16_to_utf8(lay->utf16Name);
    if (!u.empty()) return u;
  }
  if (lay->name.GetLength() > 0) return std::string(lay->name.c_str());
  return "Layer " + std::to_string(index + 1);
}

std::string safe_filename_part(const std::string& s) {
  std::string out;
  for (unsigned char c : s) {
    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
        (c >= '0' && c <= '9') || c == '-' || c == '_') {
      out.push_back((char)c);
    }
    if (out.size() >= 24) break;
  }
  return out.empty() ? "part" : out;
}

uint8_t sample_u8(const void* data, unsigned int bits, size_t idx) {
  if (!data) return 0;
  if (bits == 8) return static_cast<const uint8_t*>(data)[idx];
  if (bits == 16) return (uint8_t)(static_cast<const uint16_t*>(data)[idx] >> 8);
  if (bits == 32) {
    float v = static_cast<const float*>(data)[idx];
    v = std::clamp(v, 0.0f, 1.0f);
    return (uint8_t)std::lround(v * 255.0f);
  }
  return 0;
}

const psd::Channel* find_channel(const psd::Layer* lay, int16_t type) {
  for (unsigned int i = 0; i < lay->channelCount; ++i) {
    if (lay->channels[i].type == type && lay->channels[i].data)
      return &lay->channels[i];
  }
  return nullptr;
}

bool layer_tree_visible(const psd::Layer* lay) {
  for (const psd::Layer* p = lay; p; p = p->parent) {
    if (!p->isVisible) return false;
  }
  return true;
}

}  // namespace

bool psd_extract_layers(const std::string& psd_path, const std::string& out_dir,
                        PsdDocOut& out, std::string& why) {
  out = PsdDocOut{};
  std::ifstream in(psd_path, std::ios::binary | std::ios::ate);
  if (!in) {
    why = "could not open PSD file";
    return false;
  }
  const std::streamsize size = in.tellg();
  if (size <= 0) {
    why = "PSD file is empty";
    return false;
  }
  std::vector<uint8_t> bytes((size_t)size);
  in.seekg(0);
  if (!in.read(reinterpret_cast<char*>(bytes.data()), size)) {
    why = "could not read PSD file";
    return false;
  }

  psd::MallocAllocator alloc;
  psd::MemoryFile file(&alloc);
  if (!file.Open(bytes.data(), (uint64_t)bytes.size())) {
    why = "could not open PSD memory buffer";
    return false;
  }

  psd::Document* doc = psd::CreateDocument(&file, &alloc);
  if (!doc) {
    why = "invalid PSD header";
    file.Close();
    return false;
  }

  out.canvas_w = (int)doc->width;
  out.canvas_h = (int)doc->height;
  const unsigned int bits = doc->bitsPerChannel;
  const bool is_gray = doc->colorMode == psd::colorMode::GRAYSCALE;
  if (doc->colorMode != psd::colorMode::RGB && !is_gray) {
    why = "unsupported PSD color mode (RGB or Grayscale required)";
    psd::DestroyDocument(doc, &alloc);
    file.Close();
    return false;
  }

  psd::LayerMaskSection* lms = psd::ParseLayerMaskSection(doc, &file, &alloc);
  if (!lms) {
    why = "PSD has no layers";
    psd::DestroyDocument(doc, &alloc);
    file.Close();
    return false;
  }

  std::error_code ec;
  std::filesystem::create_directories(out_dir, ec);
  if (ec) {
    why = "could not create output directory for PSD layers";
    psd::DestroyLayerMaskSection(lms, &alloc);
    psd::DestroyDocument(doc, &alloc);
    file.Close();
    return false;
  }

  for (unsigned int i = 0; i < lms->layerCount; ++i) {
    psd::Layer* lay = &lms->layers[i];
    if (lay->type != psd::layerType::ANY) continue;
    const int w = lay->right - lay->left;
    const int h = lay->bottom - lay->top;
    if (w <= 0 || h <= 0) continue;

    psd::ExtractLayer(doc, &file, &alloc, lay);
    const psd::Channel* chR = find_channel(lay, psd::channelType::R);
    const psd::Channel* chG = find_channel(lay, psd::channelType::G);
    const psd::Channel* chB = find_channel(lay, psd::channelType::B);
    const psd::Channel* chA =
        find_channel(lay, psd::channelType::TRANSPARENCY_MASK);
    if (!chR) continue;

    const size_t pixels = (size_t)w * (size_t)h;
    std::vector<uint8_t> rgba(pixels * 4, 0);
    bool anyOpaque = false;
    for (size_t p = 0; p < pixels; ++p) {
      const uint8_t r = sample_u8(chR->data, bits, p);
      const uint8_t g = is_gray ? r : (chG ? sample_u8(chG->data, bits, p) : 0);
      const uint8_t b = is_gray ? r : (chB ? sample_u8(chB->data, bits, p) : 0);
      uint8_t a = chA ? sample_u8(chA->data, bits, p) : 255;
      if (a > 0) anyOpaque = true;
      rgba[p * 4 + 0] = r;
      rgba[p * 4 + 1] = g;
      rgba[p * 4 + 2] = b;
      rgba[p * 4 + 3] = a;
    }

    // Apply user layer mask alpha if present.
    if (lay->layerMask && lay->layerMask->data) {
      const auto* mask = lay->layerMask;
      const int mw = mask->right - mask->left;
      const int mh = mask->bottom - mask->top;
      const uint8_t defVal = mask->defaultColor;
      anyOpaque = false;
      for (int y = 0; y < h; ++y) {
        const int cy = lay->top + y;
        for (int x = 0; x < w; ++x) {
          const int cx = lay->left + x;
          uint8_t mv = defVal;
          if (mw > 0 && mh > 0 && cx >= mask->left && cx < mask->right &&
              cy >= mask->top && cy < mask->bottom) {
            const size_t mi = (size_t)(cy - mask->top) * (size_t)mw +
                              (size_t)(cx - mask->left);
            mv = sample_u8(mask->data, bits, mi);
          }
          const size_t idx = ((size_t)y * (size_t)w + (size_t)x) * 4 + 3;
          rgba[idx] = (uint8_t)(((unsigned)rgba[idx] * (unsigned)mv) / 255u);
          if (rgba[idx] > 0) anyOpaque = true;
        }
      }
    }

    if (!anyOpaque) continue;

    const std::string displayName = layer_name_utf8(lay, out.layers.size());
    char fname[96];
    std::snprintf(fname, sizeof fname, "%03u_%s.png",
                  (unsigned)(out.layers.size() + 1),
                  safe_filename_part(displayName).c_str());
    const std::string pngPath =
        (std::filesystem::path(out_dir) / fname).generic_string();
    if (!stbi_write_png(pngPath.c_str(), w, h, 4, rgba.data(), w * 4)) {
      continue;
    }

    PsdLayerOut item;
    item.name = displayName;
    item.png_path = pngPath;
    item.left = lay->left;
    item.top = lay->top;
    item.width = w;
    item.height = h;
    item.opacity = (double)lay->opacity / 255.0;
    item.visible = layer_tree_visible(lay);
    item.clipping = lay->clipping != 0;
    out.layers.push_back(std::move(item));
  }

  psd::DestroyLayerMaskSection(lms, &alloc);
  psd::DestroyDocument(doc, &alloc);
  file.Close();

  if (out.layers.empty()) {
    why = "no non-empty pixel layers found in PSD";
    return false;
  }
  return true;
}

}  // namespace motolii
