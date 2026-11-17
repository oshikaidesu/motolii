#ifndef RUNNER_LIVE_TEXTURE_H_
#define RUNNER_LIVE_TEXTURE_H_

#include <flutter/flutter_engine.h>

// The engine's pictures as Flutter textures, as macos/Runner/MainFlutterWindow.swift gives them on the Mac
// (channel "motolii/stage"; "motolii/glass" and "motolii/sampler" answer that they are not here).
void AttachLiveTextures(flutter::FlutterEngine* engine);

#endif  // RUNNER_LIVE_TEXTURE_H_
