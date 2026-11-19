// The engine's load as a meter shows it: how much of a frame's time the render thread and the GPU each took.

class EngineLoad {
  /// Milliseconds one frame has at the stage's 60 frames a second.
  static const beat = 1000 / 60;

  double _cpu = 0, _cpuMost = 0, _gpu = 0;
  int _frames = 0;

  /// One drawn frame's two times in milliseconds: the render thread's own and the GPU's.
  void add(double cpuMs, double gpuMs) {
    _cpu += cpuMs;
    if (cpuMs > _cpuMost) _cpuMost = cpuMs;
    _gpu = gpuMs;
    _frames++;
  }

  /// What the frames added since the last call took, as parts of [beat]: the render thread's mean and its most,
  /// and the GPU's latest (the engine's own median of its last frames). Null when no frame was drawn: at rest.
  ({double cpu, double cpuMost, double gpu})? take() {
    if (_frames == 0) return null;
    final taken = (
      cpu: _cpu / _frames / beat,
      cpuMost: _cpuMost / beat,
      gpu: _gpu / beat,
    );
    _cpu = _cpuMost = _gpu = 0;
    _frames = 0;
    return taken;
  }
}
