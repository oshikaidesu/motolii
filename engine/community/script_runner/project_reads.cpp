// project_reads.h: the native functions a script reads the project with.
#include "community/script_runner/project_reads.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

namespace motolii {

namespace {

// Each native is handed, in `data`, the address of what answers it.
JSValue layer_value(JSContext* cx, JSValueConst, int argc, JSValueConst* a, int,
                    JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* reads = (const Script::LayerReader*)at;
  double layer = 0, t = 0, otherwise = 0, copy = -1;
  const char* name = argc >= 3 ? JS_ToCString(cx, a[1]) : nullptr;
  if (argc >= 3) JS_ToFloat64(cx, &layer, a[0]), JS_ToFloat64(cx, &t, a[2]);
  if (argc >= 4) JS_ToFloat64(cx, &otherwise, a[3]);
  if (argc >= 5) JS_ToFloat64(cx, &copy, a[4]);
  const double v = name && *reads
                       ? (*reads)((int)layer, name, t, otherwise, (int)copy)
                       : std::nan("");
  if (name) JS_FreeCString(cx, name);
  return JS_NewFloat64(cx, v);
}

JSValue layer_keys(JSContext* cx, JSValueConst, int argc, JSValueConst* a, int,
                   JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* reads = (const Script::KeyReader*)at;
  double layer = 0;
  const char* name = argc >= 2 ? JS_ToCString(cx, a[1]) : nullptr;
  if (argc >= 2) JS_ToFloat64(cx, &layer, a[0]);
  const std::vector<double> keys =
      name && *reads ? (*reads)((int)layer, name) : std::vector<double>{};
  if (name) JS_FreeCString(cx, name);
  JSValue out = JS_NewArray(cx);
  for (size_t i = 0; i < keys.size(); ++i)
    JS_SetPropertyUint32(cx, out, (uint32_t)i, JS_NewFloat64(cx, keys[i]));
  return out;
}

JSValue layer_named(JSContext* cx, JSValueConst, int argc, JSValueConst* a, int,
                    JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* finds = (const Script::LayerFinder*)at;
  const char* name = argc >= 1 ? JS_ToCString(cx, a[0]) : nullptr;
  const int layer = name && *finds ? (*finds)(name) : 0;
  if (name) JS_FreeCString(cx, name);
  return JS_NewInt32(cx, layer);
}

// Reads up to `n` numbers of a JavaScript array into `to`; a single number is
// taken for each of them. What is not a number leaves `to` as it came.
void numbers_of(JSContext* cx, JSValueConst from, double* to, int n) {
  if (JS_IsNumber(from)) {
    double all = 0;
    JS_ToFloat64(cx, &all, from);
    std::fill(to, to + n, all);
  }
  if (!JS_IsObject(from)) return;
  for (int i = 0; i < n; ++i) {
    JSValue v = JS_GetPropertyUint32(cx, from, (uint32_t)i);
    if (JS_IsNumber(v)) JS_ToFloat64(cx, &to[i], v);
    JS_FreeValue(cx, v);
  }
}
template <size_t N>
JSValue array_of(JSContext* cx, const std::array<double, N>& all) {
  JSValue out = JS_NewArray(cx);
  for (uint32_t i = 0; i < N; ++i)
    JS_SetPropertyUint32(cx, out, i, JS_NewFloat64(cx, all[i]));
  return out;
}
JSValue sample_image(JSContext* cx, JSValueConst, int argc, JSValueConst* a,
                     int, JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* sample = (const Script::ImageSampler*)at;
  // The defaults are After Effects': a radius of half a pixel, after effects.
  double layer = 0, point[2] = {0, 0}, radius[2] = {0.5, 0.5}, t = 0;
  bool post_effect = true;
  if (argc >= 1) JS_ToFloat64(cx, &layer, a[0]);
  if (argc >= 2) numbers_of(cx, a[1], point, 2);
  if (argc >= 3) numbers_of(cx, a[2], radius, 2);
  if (argc >= 4 && !JS_IsUndefined(a[3])) post_effect = JS_ToBool(cx, a[3]) > 0;
  if (argc >= 5) JS_ToFloat64(cx, &t, a[4]);
  return array_of(cx, *sample ? (*sample)((int)layer, point[0], point[1],
                                          radius[0], radius[1], post_effect, t)
                              : std::array<double, 4>{0, 0, 0, 0});
}
JSValue from_world(JSContext* cx, JSValueConst, int argc, JSValueConst* a, int,
                   JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* point = (const Script::PointMapper*)at;
  double layer = 0, p[3] = {0, 0, 0}, t = 0;
  if (argc >= 1) JS_ToFloat64(cx, &layer, a[0]);
  if (argc >= 2) numbers_of(cx, a[1], p, 3);
  if (argc >= 3) JS_ToFloat64(cx, &t, a[2]);
  return array_of(cx, *point
                          ? (*point)((int)layer, p[0], p[1], p[2], t)
                          : std::array<double, 2>{std::nan(""), std::nan("")});
}

// getByteFrequencyData (`what` 0), getFloatTimeDomainData (1) and
// getFloatFrequencyData (2): fills the typed array a[1] as the Web's
// AnalyserNode does. An array shorter than what there is takes its first part;
// a longer one keeps the rest of what it held (W3C Web Audio API,
// section 1.8.4). What is not the kind of array the method takes is a
// TypeError, as on the Web.
JSValue sound_data(JSContext* cx, JSValueConst, int argc, JSValueConst* a,
                   int what, JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* sound = (const Script::SoundReader*)at;
  double layer = 0, t = 0;
  if (argc >= 1) JS_ToFloat64(cx, &layer, a[0]);
  if (argc >= 3) JS_ToFloat64(cx, &t, a[2]);
  size_t from = 0, bytes = 0, each = 0, all = 0;
  JSValue held = argc >= 2
                     ? JS_GetTypedArrayBuffer(cx, a[1], &from, &bytes, &each)
                     : JS_ThrowTypeError(cx, "an array is needed");
  if (JS_IsException(held)) return held;
  uint8_t* to = JS_GetArrayBuffer(cx, &all, held);
  JS_FreeValue(cx, held);
  const int kind = JS_GetTypedArrayType(a[1]);
  if (!to || kind != (what ? JS_TYPED_ARRAY_FLOAT32 : JS_TYPED_ARRAY_UINT8))
    return JS_ThrowTypeError(
        cx, what ? "a Float32Array is needed" : "a Uint8Array is needed");
  const std::vector<float> v =
      *sound ? (*sound)((int)layer, what != 1, t) : std::vector<float>();
  const size_t n = std::min(bytes / each, v.size());
  if (what)
    std::memcpy(to + from, v.data(), n * sizeof(float));
  else
    // 1.8.6: the byte is 255 / (maxDecibels - minDecibels) x (dB - minDecibels)
    // cut to 0..255, with the -100 and -30 an AnalyserNode starts with.
    for (size_t i = 0; i < n; ++i) {
      const double byte = std::floor(255.0 / 70.0 * ((double)v[i] + 100.0));
      to[from + i] = (uint8_t)(byte > 0.0 ? std::min(byte, 255.0) : 0.0);
    }
  // No sound: silence, as an AnalyserNode nothing is connected to gives it:
  // no samples, bytes of 0, and minus infinity decibels.
  if (v.empty()) {
    std::memset(to + from, 0, bytes);
    if (what == 2)
      for (size_t i = 0; i < bytes / each; ++i) {
        const float none = -INFINITY;
        std::memcpy(to + from + i * sizeof(float), &none, sizeof(float));
      }
  }
  return JS_UNDEFINED;
}

JSValue layer_word(JSContext* cx, JSValueConst, int argc, JSValueConst* a, int,
                   JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* host = (const Script::HostReads*)at;
  double layer = 0;
  const char* name = argc >= 2 ? JS_ToCString(cx, a[1]) : nullptr;
  if (argc >= 1) JS_ToFloat64(cx, &layer, a[0]);
  const std::string s =
      name && host->word ? host->word((int)layer, name) : std::string{};
  if (name) JS_FreeCString(cx, name);
  return JS_NewStringLen(cx, s.data(), s.size());
}

JSValue layer_bounds(JSContext* cx, JSValueConst, int argc, JSValueConst* a,
                     int, JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* host = (const Script::HostReads*)at;
  double layer = 0, t = 0;
  if (argc >= 1) JS_ToFloat64(cx, &layer, a[0]);
  if (argc >= 2) JS_ToFloat64(cx, &t, a[1]);
  if (!host->bounds) return JS_NULL;
  const std::array<double, 8> b = host->bounds((int)layer, t);
  if (std::isnan(b[2]) || std::isnan(b[3])) return JS_NULL;
  JSValue out = JS_NewObject(cx);
  JS_SetPropertyStr(cx, out, "x", JS_NewFloat64(cx, b[0]));
  JS_SetPropertyStr(cx, out, "y", JS_NewFloat64(cx, b[1]));
  JS_SetPropertyStr(cx, out, "width", JS_NewFloat64(cx, b[2]));
  JS_SetPropertyStr(cx, out, "height", JS_NewFloat64(cx, b[3]));
  JS_SetPropertyStr(cx, out, "left", JS_NewFloat64(cx, b[0] - b[2] * 0.5));
  JS_SetPropertyStr(cx, out, "top", JS_NewFloat64(cx, b[1] - b[3] * 0.5));
  JS_SetPropertyStr(cx, out, "rotate", JS_NewFloat64(cx, b[4]));
  JS_SetPropertyStr(cx, out, "halfX", JS_NewFloat64(cx, b[5]));
  JS_SetPropertyStr(cx, out, "halfY", JS_NewFloat64(cx, b[6]));
  JS_SetPropertyStr(cx, out, "px", JS_NewFloat64(cx, b[7]));
  return out;
}

JSValue to_world(JSContext* cx, JSValueConst, int argc, JSValueConst* a, int,
                 JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* host = (const Script::HostReads*)at;
  double layer = 0, p[3] = {0, 0, 0}, t = 0;
  if (argc >= 1) JS_ToFloat64(cx, &layer, a[0]);
  if (argc >= 2) numbers_of(cx, a[1], p, 3);
  if (argc >= 3) JS_ToFloat64(cx, &t, a[2]);
  return array_of(cx, host->to_world
                          ? host->to_world((int)layer, p[0], p[1], p[2], t)
                          : std::array<double, 3>{std::nan(""), std::nan(""),
                                                  std::nan("")});
}

JSValue to_screen(JSContext* cx, JSValueConst, int argc, JSValueConst* a, int,
                  JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* host = (const Script::HostReads*)at;
  double p[3] = {0, 0, 0}, t = 0;
  if (argc >= 1) numbers_of(cx, a[0], p, 3);
  if (argc >= 2) JS_ToFloat64(cx, &t, a[1]);
  return array_of(cx, host->to_screen
                          ? host->to_screen(p[0], p[1], p[2], t)
                          : std::array<double, 2>{std::nan(""), std::nan("")});
}

JSValue int_array(JSContext* cx, const std::vector<int>& items) {
  JSValue out = JS_NewArray(cx);
  for (size_t i = 0; i < items.size(); ++i)
    JS_SetPropertyUint32(cx, out, (uint32_t)i, JS_NewInt32(cx, items[i]));
  return out;
}

JSValue all_layers(JSContext* cx, JSValueConst, int, JSValueConst*, int,
                   JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* host = (const Script::HostReads*)at;
  return int_array(cx, host->layers ? host->layers() : std::vector<int>{});
}

JSValue layer_children(JSContext* cx, JSValueConst, int argc, JSValueConst* a,
                       int, JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* host = (const Script::HostReads*)at;
  double parent = 0;
  if (argc >= 1) JS_ToFloat64(cx, &parent, a[0]);
  return int_array(
      cx, host->children ? host->children((int)parent) : std::vector<int>{});
}

JSValue camera_info(JSContext* cx, JSValueConst, int argc, JSValueConst* a, int,
                    JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* host = (const Script::HostReads*)at;
  double t = 0;
  if (argc >= 1) JS_ToFloat64(cx, &t, a[0]);
  const std::array<double, 12> c =
      host->camera
          ? host->camera(t)
          : std::array<double, 12>{0, 0, 6, 0, 0, 0, 0, 1, 0, 30, 1, 0};
  JSValue out = JS_NewObject(cx);
  JS_SetPropertyStr(cx, out, "eye", array_of<3>(cx, {c[0], c[1], c[2]}));
  JS_SetPropertyStr(cx, out, "look", array_of<3>(cx, {c[3], c[4], c[5]}));
  JS_SetPropertyStr(cx, out, "up", array_of<3>(cx, {c[6], c[7], c[8]}));
  JS_SetPropertyStr(cx, out, "fov", JS_NewFloat64(cx, c[9]));
  JS_SetPropertyStr(cx, out, "distance", JS_NewFloat64(cx, c[10]));
  JS_SetPropertyStr(cx, out, "id", JS_NewInt32(cx, (int)c[11]));
  return out;
}

JSValue audio_bands(JSContext* cx, JSValueConst, int argc, JSValueConst* a, int,
                    JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* host = (const Script::HostReads*)at;
  double layer = 0, t = 0;
  if (argc >= 1) JS_ToFloat64(cx, &layer, a[0]);
  if (argc >= 2) JS_ToFloat64(cx, &t, a[1]);
  return array_of<5>(cx, host->audio_bands
                             ? host->audio_bands((int)layer, t)
                             : std::array<double, 5>{0, 0, 0, 0, 0});
}

JSValue midi_info(JSContext* cx, JSValueConst, int argc, JSValueConst* a, int,
                  JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* host = (const Script::HostReads*)at;
  double current_layer = 0, channel = -1, t = 0;
  const char* src = nullptr;
  if (argc >= 1) JS_ToFloat64(cx, &current_layer, a[0]);
  if (argc >= 2 && !JS_IsUndefined(a[1]) && !JS_IsNull(a[1]))
    src = JS_ToCString(cx, a[1]);
  if (argc >= 3 && !JS_IsUndefined(a[2])) JS_ToFloat64(cx, &channel, a[2]);
  if (argc >= 4) JS_ToFloat64(cx, &t, a[3]);
  const std::array<double, 4> m =
      host->midi
          ? host->midi((int)current_layer, src ? src : "", (int)channel, t)
          : std::array<double, 4>{0, 0, 0, 120};
  if (src) JS_FreeCString(cx, src);
  JSValue out = JS_NewObject(cx);
  JS_SetPropertyStr(cx, out, "vel", JS_NewFloat64(cx, m[0]));
  JS_SetPropertyStr(cx, out, "pitch", JS_NewFloat64(cx, m[1]));
  JS_SetPropertyStr(cx, out, "gate", JS_NewFloat64(cx, m[2]));
  JS_SetPropertyStr(cx, out, "bpm", JS_NewFloat64(cx, m[3]));
  return out;
}

JSValue layer_effect(JSContext* cx, JSValueConst, int argc, JSValueConst* a,
                     int, JSValueConst* data) {
  int64_t at = 0;
  JS_ToInt64(cx, &at, data[0]);
  const auto* host = (const Script::HostReads*)at;
  double layer = 0, t = 0;
  if (argc >= 1) JS_ToFloat64(cx, &layer, a[0]);
  const char* effect = argc >= 2 ? JS_ToCString(cx, a[1]) : nullptr;
  const char* param = argc >= 3 ? JS_ToCString(cx, a[2]) : nullptr;
  if (argc >= 4) JS_ToFloat64(cx, &t, a[3]);
  const double v = effect && param && host->effect_param
                       ? host->effect_param((int)layer, effect, param, t)
                       : std::nan("");
  if (effect) JS_FreeCString(cx, effect);
  if (param) JS_FreeCString(cx, param);
  return JS_NewFloat64(cx, v);
}

}  // namespace

bool project_reads_give(JSContext* cx, const std::string& src,
                        ProjectReads* answers) {
  JSValue g = JS_GetGlobalObject(cx);
  bool named = false;
  const auto give = [&](const char* name, JSCFunctionData* asks, int takes,
                        void* answer, int magic = 0) {
    JSValue to = JS_NewInt64(cx, (int64_t)(intptr_t)answer);
    JS_SetPropertyStr(cx, g, name,
                      JS_NewCFunctionData(cx, asks, takes, magic, 1, &to));
    JS_FreeValue(cx, to);
    named = named || src.find(name) != std::string::npos;
  };
  give("layerValue", layer_value, 3, &answers->value);
  give("layerKeys", layer_keys, 2, &answers->keys);
  give("layerNamed", layer_named, 1, &answers->named);
  give("sampleImage", sample_image, 5, &answers->sample);
  give("fromWorld", from_world, 3, &answers->point);
  give("getByteFrequencyData", sound_data, 3, &answers->sound, 0);
  give("getFloatTimeDomainData", sound_data, 3, &answers->sound, 1);
  give("getFloatFrequencyData", sound_data, 3, &answers->sound, 2);
  give("layerWord", layer_word, 2, &answers->host);
  give("layerBounds", layer_bounds, 2, &answers->host);
  give("toWorld", to_world, 3, &answers->host);
  give("toScreen", to_screen, 2, &answers->host);
  give("layers", all_layers, 0, &answers->host);
  give("layerChildren", layer_children, 1, &answers->host);
  give("cameraInfo", camera_info, 1, &answers->host);
  give("audioBands", audio_bands, 2, &answers->host);
  give("midiInfo", midi_info, 4, &answers->host);
  give("layerEffect", layer_effect, 4, &answers->host);
  // High-level JS host helpers and AE expressions also call the project reads
  // above indirectly; keep them on the document-owning thread.
  for (const char* wrapper : {"layer(", "stage.", "audio", "midi", "AE.",
                              "thisComp", "thisLayer", "sourceRectAtTime"})
    named = named || src.find(wrapper) != std::string::npos;
  JS_FreeValue(cx, g);
  return named;
}

}  // namespace motolii
