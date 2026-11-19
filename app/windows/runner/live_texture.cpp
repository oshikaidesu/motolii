// The present inside's stage (engine/out/libmotolii.dll, motolii.h) as Flutter textures, without a copy: the engine
// draws each frame into a D3D12 texture shared by a DXGI handle (engine/stage/live_shared_windows.cpp), and its last
// finished one is handed to Flutter, whose ANGLE opens the handle. The Mac's twin is StageTexture in
// macos/Runner/MainFlutterWindow.swift.
// Channel "motolii/stage", method "start" {lib, handle (the Motolii* as a number), and which picture: front and
// frames, the names of its two calls ("motolii_front" and "motolii_frames" unless told)} -> texture id, or -1.
#include "live_texture.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter_texture_registrar.h>
#include <windows.h>

#include <cstdint>
#include <cstdlib>
#include <map>
#include <memory>
#include <string>

namespace {

// As engine/entry/motolii.h declares it.
struct MotoliiSharedFrame {
  void* handle;
  unsigned int width, height;
};
using FrontFn = void* (*)(void*);
using FramesFn = unsigned long long (*)(void*);
using FinishedFn = void (*)(void*, void (*)(void*), void*);

// One picture of the engine, registered as a texture.
struct LiveTexture {
  FlutterDesktopTextureRegistrarRef textures = nullptr;
  FrontFn front = nullptr;
  void* inside = nullptr;
  int64_t id = -1;
  FlutterDesktopGpuSurfaceDescriptor told{};

  // Flutter's raster thread asks for the picture to draw.
  static const FlutterDesktopGpuSurfaceDescriptor* Picture(size_t, size_t, void* self) {
    auto* t = static_cast<LiveTexture*>(self);
    auto* frame = static_cast<MotoliiSharedFrame*>(t->front(t->inside));
    if (!frame) return nullptr;
    t->told.struct_size = sizeof(FlutterDesktopGpuSurfaceDescriptor);
    t->told.handle = frame->handle;
    t->told.width = t->told.visible_width = frame->width;
    t->told.height = t->told.visible_height = frame->height;
    t->told.format = kFlutterDesktopPixelFormatBGRA8888;
    t->told.release_callback = nullptr;
    std::free(frame);
    return &t->told;
  }
};

std::map<std::string, std::unique_ptr<LiveTexture>> shared;
FlutterDesktopTextureRegistrarRef textures = nullptr;

// The engine says a picture is finished, on its own thread: each texture is marked new (any thread may).
void Finished(void*) {
  for (auto& [_, t] : shared)
    if (t->id >= 0) FlutterDesktopTextureRegistrarMarkExternalTextureFrameAvailable(textures, t->id);
}

std::wstring Wide(const std::string& utf8) {
  std::wstring out(MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, out.data(), (int)out.size());
  out.resize(out.size() - 1);
  return out;
}

template <class T>
const T* Said(const flutter::EncodableMap& a, const char* name) {
  auto at = a.find(flutter::EncodableValue(name));
  return at == a.end() ? nullptr : std::get_if<T>(&at->second);
}

}  // namespace

void AttachLiveTextures(flutter::FlutterEngine* engine) {
  textures = FlutterDesktopRegistrarGetTextureRegistrar(engine->GetRegistrarForPlugin("MotoliiStage"));
  static flutter::MethodChannel<flutter::EncodableValue> stage(engine->messenger(), "motolii/stage",
                                                              &flutter::StandardMethodCodec::GetInstance());
  stage.SetMethodCallHandler([](const auto& call, auto result) {
    const auto* a = std::get_if<flutter::EncodableMap>(call.arguments());
    const std::string* lib = a ? Said<std::string>(*a, "lib") : nullptr;
    const flutter::EncodableValue* handle = nullptr;
    if (a) {
      auto at = a->find(flutter::EncodableValue("handle"));
      if (at != a->end()) handle = &at->second;
    }
    if (call.method_name() != "start" || !lib || !handle) return result->NotImplemented();
    const std::string* f = Said<std::string>(*a, "front");
    const std::string* n = Said<std::string>(*a, "frames");
    const std::string frontName = f ? *f : "motolii_front", framesName = n ? *n : "motolii_frames";
    if (auto old = shared.find(frontName); old != shared.end()) {
      FlutterDesktopTextureRegistrarUnregisterExternalTexture(textures, old->second->id, nullptr, nullptr);
      shared.erase(old);
    }
    // The library Dart opened (dart:ffi): the same module, already loaded.
    HMODULE h = LoadLibraryW(Wide(*lib).c_str());
    auto front = h ? (FrontFn)GetProcAddress(h, frontName.c_str()) : nullptr;
    auto frames = h ? (FramesFn)GetProcAddress(h, framesName.c_str()) : nullptr;
    if (!front || !frames) return result->Success(flutter::EncodableValue((int64_t)-1));
    auto t = std::make_unique<LiveTexture>();
    t->front = front;
    t->inside = (void*)(intptr_t)handle->LongValue();
    FlutterDesktopTextureInfo info{};
    info.type = kFlutterDesktopGpuSurfaceTexture;
    info.gpu_surface_config.struct_size = sizeof(FlutterDesktopGpuSurfaceTextureConfig);
    info.gpu_surface_config.type = kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle;
    info.gpu_surface_config.callback = &LiveTexture::Picture;
    info.gpu_surface_config.user_data = t.get();
    t->id = FlutterDesktopTextureRegistrarRegisterExternalTexture(textures, &info);
    const int64_t id = t->id;
    void* inside = t->inside;
    shared[frontName] = std::move(t);
    if (auto finished = (FinishedFn)GetProcAddress(h, "motolii_finished")) finished(inside, &Finished, nullptr);
    Finished(nullptr);  // (a picture finished before the listener above was set would otherwise wait for the next one)
    result->Success(flutter::EncodableValue(id));
  });
  // The live glass study and the screen's eyedropper are the Mac's alone so far.
  for (const char* name : {"motolii/glass", "motolii/sampler"}) {
    static std::map<std::string, std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>> others;
    others[name] = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        engine->messenger(), name, &flutter::StandardMethodCodec::GetInstance());
    others[name]->SetMethodCallHandler([](const auto&, auto result) { result->NotImplemented(); });
  }
}
